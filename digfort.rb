# designate an area based on a '.csv' plan
=begin

digfort
=======
A script to designate an area for digging according to a plan in csv format.

This script, inspired from quickfort, can designate an area for digging.
Your plan should be stored in a .csv file like this::

    # this is a comment
    d;d;u;d;d;skip this tile;d
    d;d;d;i

Available tile shapes are named after the 'dig' menu shortcuts:
``d`` for dig, ``u`` for upstairs, ``j`` downstairs, ``i`` updown,
``h`` channel, ``r`` upward ramp, ``x`` remove designation.
Unrecognized characters are ignored (eg the 'skip this tile' in the sample).

Empty lines and data after a ``#`` are ignored as comments.
To skip a row in your design, use a single ``;``.

One comment in the file may contain the phrase ``start(3,5)``. It is interpreted
as an offset for the pattern: instead of starting at the cursor, it will start
3 tiles left and 5 tiles up from the cursor.

additionally a comment can have a < for a rise in z level and a > for drop in z.

The script takes the plan filename, starting from the root df folder (where
``Dwarf Fortress.exe`` is found).

=end

fname = $script_args[0].to_s
map = df.world.map
x_soft_limit = map.x_count - 1
y_soft_limit = map.y_count - 1
x_soft_limit_exceeded = false
y_soft_limit_exceeded = false
if not $script_args[0] then
    puts "  Usage: digfort <plan filename>"
    throw :script_finished
end
if not fname[-4..-1] == ".csv" then
    puts "  The plan file must be in .csv format."
    throw :script_finished
end
if not File.file?(fname) then
    puts "  The specified file does not exist."
    throw :script_finished
end

planfile = File.read(fname)

if df.cursor.x == -30000
    puts "place the game cursor to the top-left corner of the design and retry"
    throw :script_finished
end

offset = [0, 0]
tiles = []
max_x = 0
max_y = 0
y = 0
planfile.each_line { |l|
    if l =~ /#.*start\s*\(\s*(-?\d+)\s*[,;]\s*(-?\d+)/
        raise "Error: multiple start() comments" if offset != [0, 0]
        offset = [$1.to_i, $2.to_i]
    end
    if l.chomp == '#<'
        l = '<'
        y = 0
    end

    if l.chomp == '#>'
        l = '>'
        y = 0
    end

    l = l.chomp.sub(/#.*/, '')
    next if l == ''
    x = 0
    tiles << l.split(/[;,]/).map { |t|
        t = t.strip
        if x < x_soft_limit then
            x += 1
        else
            x = x_soft_limit
            x_soft_limit_exceeded = true
        end
        max_x = x if x > max_x and not t.empty?
        (t[0] == '"') ? t[1..-2] : t
    }
    if y < y_soft_limit then
        y += 1
    else
        y = y_soft_limit
        y_soft_limit_exceeded = true
    end

}

x = df.cursor.x - offset[0]
y = df.cursor.y - offset[1]
z = df.cursor.z
starty = y - 1

if x < 0 or y < 0 or x+max_x >= map.x_count or y+max_y >= map.y_count
    max_x = max_x + x + 1
    max_y = max_y + y + 1
    raise "Position would designate outside map limits. Selected limits are from (#{x+1}, #{y+1}) to (#{max_x},#{max_y})"
end

tiles.each { |line|
    next if line.empty? or line == ['']
    line.each { |tile|
        if tile.empty?
            if x < x_soft_limit then
                x += 1
            else
                x = x_soft_limit
                x_soft_limit_exceeded = true
            end
            next
        end
        t = df.map_tile_at(x, y, z)
        s = t.shape_basic
        case tile
        when 'd'; t.dig(:Default) if s == :Wall
        when 'u'; t.dig(:UpStair) if s == :Wall
        when 'j'; t.dig(:DownStair) if s == :Wall or s == :Floor
        when 'i'; t.dig(:UpDownStair) if s == :Wall
        when 'h'; t.dig(:Channel) if s == :Wall or s == :Floor
        when 'r'; t.dig(:Ramp) if s == :Wall
        when 'x'; t.dig(:No)
        when '<'; y=starty; z += 1
        when '>'; y=starty; z -= 1
        end
        if x < x_soft_limit then
            x += 1
        else
            x = x_soft_limit
            x_soft_limit_exceeded = true
        end
    }
    x = df.cursor.x - offset[0]
    if y < y_soft_limit then
        y += 1
    else
        y = y_soft_limit
        y_soft_limit_exceeded = true
    end
}

if x_soft_limit_exceeded or y_soft_limit_exceeded then
  puts 'Warning: ' + (x_soft_limit_exceeded ? 'the columns': '') + (x_soft_limit_exceeded and y_soft_limit_exceeded ? ' and ': '') + (y_soft_limit_exceeded ? 'the rows' : '') + ' of the blueprint that overflow the designable area of the Dwarf Fortress embark have been ignored'
  puts '         if your blueprint X or Y dimension is close to that of the embark map, this warning is probably a false positive due to faulty logic in this script'
end

puts '  done'
