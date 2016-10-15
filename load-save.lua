-- load a save non-interactively - intended to be run on startup
--[====[

load-save
=========

When run on the title screen or "load game" screen, loads the save with the
given folder name without requiring interaction.

Example: ``load-save region``

This can also be run when starting DFHack from the command line::

    ./dfhack +load-game region1

(This is currently untested on Windows)

]====]

local gui = require 'gui'

local args = {...}
local folder_name = args[1] or qerror("No folder name given")
local start_mode = nil
start_modes = {f = 0, a = 1, l = 2}
if args[2] then
    if args[2] == 'start' then
        if args[3] then
            local mode = start_modes[args[3]:sub(1, 1)]
            if mode ~= nil then
                start_mode = mode
            end
        else
            qerror('Invalid start mode: use f(ortress)|a(dventurer)|l(egends)')
        end
    else
        qerror('Unrecognized subcommand: ' .. args[2])
    end
end


local loadgame_screen = dfhack.gui.getViewscreenByType(df.viewscreen_loadgamest, 0)
if not loadgame_screen then
    local title_screen = dfhack.gui.getViewscreenByType(df.viewscreen_titlest, 0)
    if not title_screen then
        qerror("Can't find title or load game screen")
    end
    local found = false
    for idx, item in pairs(title_screen.menu_line_id) do
        if item == df.viewscreen_titlest.T_menu_line_id.Continue then
            found = true
            title_screen.sel_menu_line = idx
            break
        end
    end
    if not found then
        qerror("Can't find 'Continue Playing' option")
    end
    gui.simulateInput(title_screen, 'SELECT')
end

loadgame_screen = dfhack.gui.getViewscreenByType(df.viewscreen_loadgamest, 0) or
    qerror("Can't find load game screen")

local found = false
for idx, save in pairs(loadgame_screen.saves) do
    if save.folder_name == folder_name then
        found = true
        loadgame_screen.sel_idx = idx
        break
    end
end
if not found then
    qerror("Can't find save: " .. folder_name)
end

--[[
If gui/load-screen is active, it will be inserted later this frame and prevent
the viewscreen_loadgamest from working. To work around this, SELECT is fed to
the screen one frame later.
]]
function triggerLoad(loadgame_screen)
    -- Get rid of child screens (e.g. gui/load-screen)
    if loadgame_screen.child then
        local child = loadgame_screen.child
        while child.child do
            child = child.child
        end
        while child ~= loadgame_screen do
            child = child.parent
            dfhack.screen.dismiss(child.child)
        end
    end

    gui.simulateInput(loadgame_screen, 'SELECT')
end

dfhack.timeout(1, 'frames', function() triggerLoad(loadgame_screen) end)
