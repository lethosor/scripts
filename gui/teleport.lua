-- A front-end for the teleport script

--[====[

gui/teleport
============

A front-end for the `teleport` script that allows choosing a unit and destination
using the in-game cursor.

]====]

guidm = require 'gui.dwarfmode'
teleport = reqscript 'teleport'
widgets = require 'gui.widgets'

function uiMultipleUnits()
    return #df.global.ui_sidebar_menus.unit_cursor.list > 1
end

function getUnitName(unit)
    return dfhack.TranslateName(dfhack.units.getVisibleName(unit))
end

TeleportSidebar = defclass(TeleportSidebar, guidm.MenuOverlay)

function TeleportSidebar:init()
    self:addviews{
        widgets.Pages{
            view_id = 'pages',
            frame = {t=0, l=0},
            subviews = {
                SelectUnitPanel{parent = self, view_id = 'unit_single'},
                SelectMultipleUnitPanel{parent = self, view_id = 'unit_multiple'},
            },
        },
        widgets.Label{
            view_id = 'main_controls',
            frame = {b=1, l=1},
            text = {
                -- {key = 'UNITJOB_ZOOM_CRE',
                --     text = ': Zoom to unit, ',
                --     on_activate = self:callback('zoom_unit'),
                --     enabled = function() return self.unit end},
                -- {key = 'UNITVIEW_NEXT', text = ': Next',
                --     on_activate = self:callback('next_unit'),
                --     enabled = uiMultipleUnits},
                -- NEWLINE,
                -- NEWLINE,
                -- {key = 'SELECT', text = ': Choose, ', on_activate = self:callback('choose')},
                -- {key = 'LEAVESCREEN', text = ': Back', on_activate = self:callback('back')},
                -- NEWLINE,
                {key = 'LEAVESCREEN_ALL', text = ': Exit to map', on_activate = self:callback('dismiss')},
            },
        },
    }
    self.subviews.pages.frame.b = self.subviews.main_controls.frame.h + 1
    for _, page in ipairs(self.subviews.pages.subviews) do
        page.screen = self
    end
end

function TeleportSidebar:onAboutToShow(parent)
    TeleportSidebar.super.onAboutToShow(self, parent)

    self.old_mode = df.global.ui.main.mode
    if df.global.ui.main.mode == df.ui_sidebar_mode.Default then
        parent:feed_key(df.interface_key.D_VIEWUNIT)
    end

    local mode = df.global.ui.main.mode
    if mode ~= df.ui_sidebar_mode.ViewUnits then
        qerror(("Use '%s' to select a unit"):format(
            dfhack.screen.getKeyDisplay(df.interface_key.D_VIEWUNIT)
        ))
    end
end

function TeleportSidebar:onInput(keys)
    TeleportSidebar.super.onInput(self, keys)
    TeleportSidebar.super.propagateMoveKeys(self, keys)
end

function TeleportSidebar:onIdle()
    local page = self.subviews.pages:getSelectedPage()
    if page.onIdle then
        page:onIdle()
    end
end

function TeleportSidebar:onDismiss()
    df.global.ui.main.mode = self.old_mode
end

function TeleportSidebar:onGetSelectedUnit()
    return self.subviews.pages:getSelectedPage().unit
end

function TeleportSidebar:change_unit_mode()
    if self.subviews.pages:getSelectedPage().view_id == 'unit_single' then
        self.subviews.pages:setSelected('unit_multiple')
    else
        self.subviews.pages:setSelected('unit_single')
    end
end

function TeleportSidebar:select_unit()
    self.subviews.pages:setSelected('destination')
end

function TeleportSidebar:zoom_to(pos)
    df.global.cursor:assign(xyz2pos(pos2xyz(pos)))
    self:getViewport():centerOn(pos):set()
    self:sendInputToParent('CURSOR_DOWN_Z')
    self:sendInputToParent('CURSOR_UP_Z')
end

function TeleportSidebar:rect_select()

end

-- function TeleportSidebar:choose()
--     if not self.in_pick_pos then
--         self.in_pick_pos = true
--         df.global.ui.main.mode = df.ui_sidebar_mode.LookAround
--     else
--         teleport.teleport(self.unit, xyz2pos(pos2xyz(df.global.cursor)))
--         self:dismiss()
--     end
-- end

-- function TeleportSidebar:back()
--     if self.in_pick_pos then
--         self.in_pick_pos = false
--         df.global.ui.main.mode = self.old_mode
--     else
--         self:dismiss()
--     end
-- end

SelectUnitPanel = defclass(SelectUnitPanel, widgets.Panel)

function SelectUnitPanel:init(args)
    self.parent = args.parent
    self:addviews{
        -- widgets.Label{
        --     frame = {t=1, l=1},
        --     text = 'Select unit:',
        -- },
        -- widgets.Label{
        --     view_id = 'unit_name',
        --     frame = {t=3, l=1, h=2},
        --     auto_height = false,
        --     text = '',
        --     onRenderBody = print,
        --     -- text = {
        --     --     'name', 'a',NEWLINE,'b',
        --     --     -- name ~= '' and NEWLINE or '',
        --     --     -- {text = dfhack.units.getProfessionName(self.unit),
        --     --     --     pen = dfhack.units.getProfessionColor(self.unit)}
        --     -- }
        -- },
        widgets.Label{
            frame = {b=0, l=1},
            text = {
                {key = 'UNITJOB_ZOOM_CRE',
                    text = ': Zoom to unit, ',
                    on_activate = self:callback('zoom_unit'),
                    enabled = function() return self.unit end},
                {key = 'UNITVIEW_NEXT', text = ': Next',
                    on_activate = self:callback('next_unit'),
                    enabled = uiMultipleUnits},
                NEWLINE,
                {key = 'CHANGETAB', text = ': Select multiple',
                    on_activate = self.parent:callback('change_unit_mode')},
                NEWLINE,
                NEWLINE,
                {key = 'SELECT', text = ': Select, ',
                    on_activate = self.parent:callback('select_unit')},
                {key = 'LEAVESCREEN', text = ': Back',
                    on_activate = self.parent:callback('dismiss')},
            },
        },
    }
end

function SelectUnitPanel:onRenderBody(p)
    -- p:fill(0,0,100,100,{bg=COLOR_RED})
    p:seek(1, 1):pen(COLOR_WHITE)
    self.unit = dfhack.gui.getAnyUnit(dfhack.gui.getViewscreenByType(df.viewscreen_dwarfmodest, 0))
    p:string('Select unit:'):newline(1):newline(1)
    if self.unit then
        local name = getUnitName(self.unit)
        p:string(name)
        if name ~= '' then p:newline(1) end
        p:string(dfhack.units.getProfessionName(self.unit), dfhack.units.getProfessionColor(self.unit))
        p:newline(1)
    else
        p:string('No unit selected', COLOR_LIGHTRED)
    end
end

function SelectUnitPanel:zoom_unit()
    self.parent:zoom_to(self.unit.pos)
end

function SelectUnitPanel:next_unit()
    self.parent:sendInputToParent('UNITVIEW_NEXT')
end

SelectMultipleUnitPanel = defclass(SelectMultipleUnitPanel, widgets.Panel)

SelectMultipleUnitPanel.selected_ids = {}

function SelectMultipleUnitPanel:init(args)
    self.parent = args.parent
    local map = df.global.world.map

    local unit_choices = {}
    local index = 1
    for _, u in ipairs(df.global.world.units.active) do
        if dfhack.units.isVisible(u) then
            table.insert(unit_choices, {
                unit = u,
                selected = self.selected_ids[u.id] or false,
                text = {{
                    text = self:callback('get_unit_name', u),
                    pen = self:callback('get_unit_pen', u, index),
                }},
            })
            index = index + 1
        end
    end

    self:addviews{
        widgets.List{
            view_id = 'units',
            frame = {t=1, l=0, r=1},
            choices = unit_choices,
            scroll_keys = widgets.SECONDSCROLL,
        },
        widgets.Label{
            view_id = 'controls',
            frame = {b=0, l=1},
            text = {
                {key = 'UNITJOB_ZOOM_CRE', text = ': Zoom to unit',
                    on_activate = self:callback('zoom_unit')},
                NEWLINE,
                {key = 'CUSTOM_R', text = ': Select from rect',
                    on_activate = self.parent:callback('rect_select')},
                NEWLINE,
                {key = 'CHANGETAB', text = ': Select one unit',
                    on_activate = self.parent:callback('change_unit_mode')},
                NEWLINE,
                NEWLINE,
                {key = 'BUILDING_ADVANCE_STAGE', text = ': Done selecting'},
                NEWLINE,
                {key = 'SELECT', text = ': Toggle, ',
                    on_activate = self:callback('toggle_unit')},
                {key = 'LEAVESCREEN', text = ': Back',
                    on_activate = self.parent:callback('dismiss')},
                NEWLINE,
                {key = 'SEC_SELECT', text = ': Toggle all',
                    on_activate = self:callback('toggle_all')},
            },
        },
    }

    self.subviews.units.frame.b = self.subviews.controls.frame.h + 1
end

function SelectMultipleUnitPanel:get_unit_name(unit)
    local name = self.selected_ids[unit.id] and string.char(251) or ' '
    name = name .. getUnitName(unit)
    if name ~= '' then
        name = name .. ', '
    end
    name = name .. dfhack.units.getProfessionName(unit)
    return name
end

function SelectMultipleUnitPanel:get_unit_pen(unit, index)
    return {
        fg = self.selected_ids[unit.id] and COLOR_GREEN or COLOR_RED,
        bold = self.subviews.units:getSelected() == index,
    }
end

function SelectMultipleUnitPanel:toggle_unit()
    local _, item = self.subviews.units:getSelected()
    self.selected_ids[item.unit.id] = not self.selected_ids[item.unit.id]
end

function SelectMultipleUnitPanel:toggle_all()
    local _, item = self.subviews.units:getSelected()
    local state = not self.selected_ids[item.unit.id]
    for _, choice in pairs(self.subviews.units:getChoices()) do
        self.selected_ids[choice.unit.id] = state
    end
end

function SelectMultipleUnitPanel:zoom_unit()
    local _, item = self.subviews.units:getSelected()
    self.parent:zoom_to(item.unit.pos)
end

TeleportSidebar():show()
