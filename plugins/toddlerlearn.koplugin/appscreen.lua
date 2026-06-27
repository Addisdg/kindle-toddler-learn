local InputContainer = require("ui/widget/container/inputcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local TextWidget = require("ui/widget/textwidget")
local InputDialog = require("ui/widget/inputdialog")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")

local EDGE_MARGIN = 36
local BUTTON_HEIGHT = 170
local EXIT_CODE = "1234"
local MODES = {"learn", "puzzles", "draw"}
local MODE_LABELS = {learn = "Learn", puzzles = "Puzzles", draw = "Draw"}

local AppScreen = InputContainer:extend{
    assets_dir = nil,
    profile_id = "child1",
}

function AppScreen:init()
    self.dimen = Geom:new{x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight()}
    self.mode_screens = self.mode_screens or {}
    self.ges_events = {
        Close = {GestureRange:new{ges = "two_finger_hold", range = self.dimen}},
        SwipeNoop = {GestureRange:new{ges = "swipe", range = self.dimen}},
    }
    self:renderModeChooser()
end

function AppScreen:getModes()
    return MODES
end

function AppScreen:getModeLabel(mode)
    return MODE_LABELS[mode]
end

function AppScreen:makeButton(text, callback)
    local width = self.dimen.w - EDGE_MARGIN * 2
    local button = InputContainer:new{
        dimen = Geom:new{x = 0, y = 0, w = width, h = BUTTON_HEIGHT},
    }
    button.ges_events = {Tap = {GestureRange:new{ges = "tap", range = button.dimen}}}
    button[1] = FrameContainer:new{
        width = width,
        height = BUTTON_HEIGHT,
        bordersize = 6,
        padding = 12,
        CenterContainer:new{
            dimen = Geom:new{w = width - 36, h = BUTTON_HEIGHT - 36},
            TextWidget:new{text = text, face = Font:getFace("tfont", 58)},
        },
    }
    button.onTap = function()
        callback()
        return true
    end
    return button
end

function AppScreen:renderModeChooser()
    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 180},
                TextWidget:new{text = "Toddler Learn", face = Font:getFace("tfont", 64)},
            },
            self:makeButton("Learn", function() self:openMode("learn") end),
            self:makeButton("Puzzles", function() self:openMode("puzzles") end),
            self:makeButton("Draw", function() self:openMode("draw") end),
        }
    }
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        content,
    }
    UIManager:setDirty(self, "full")
end

function AppScreen:createModeScreen(mode)
    local common = {
        assets_dir = self.assets_dir,
        profile_id = self.profile_id,
        mode_callback = function(screen) self:returnToModes(screen) end,
    }
    if mode == "learn" then
        return require("gamescreen"):new(common)
    end

    local module_name = mode == "puzzles" and "puzzlescreen" or "drawscreen"
    local ok, screen_module = pcall(require, module_name)
    if ok then
        return screen_module:new(common)
    end
    return self:createComingSoonScreen(mode)
end

function AppScreen:createComingSoonScreen(mode)
    local screen = InputContainer:new{}
    screen.dimen = self.dimen
    screen[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        CenterContainer:new{
            dimen = self.dimen,
            VerticalGroup:new{
                align = "center",
                TextWidget:new{text = MODE_LABELS[mode], face = Font:getFace("tfont", 64)},
                self:makeButton("Modes", function() self:returnToModes(screen) end),
            }
        },
    }
    return screen
end

function AppScreen:openMode(mode)
    if not MODE_LABELS[mode] then
        return false
    end
    local screen = self.mode_screens[mode] or self:createModeScreen(mode)
    self.mode_screens[mode] = screen
    self.active_mode = mode
    UIManager:close(self)
    UIManager:show(screen)
    return true
end

function AppScreen:returnToModes(screen)
    if screen then
        UIManager:close(screen)
    end
    self.active_mode = nil
    self:renderModeChooser()
    UIManager:show(self)
end

function AppScreen:verifyExitCode(code)
    return tostring(code or "") == EXIT_CODE
end

function AppScreen:closeExitDialog()
    if self.exit_dialog then
        UIManager:close(self.exit_dialog)
        self.exit_dialog = nil
    end
end

function AppScreen:showExitDialog(title)
    if self.exit_dialog then return end
    local dialog
    dialog = InputDialog:new{
        title = title or "Parent code",
        input_hint = "Enter code",
        input_type = "number",
        text_type = "password",
        buttons = {{
            {text = "Cancel", id = "close", callback = function() self:closeExitDialog() end},
            {text = "Exit", is_enter_default = true, callback = function()
                local code = dialog:getInputText()
                self:closeExitDialog()
                if self:verifyExitCode(code) then
                    UIManager:close(self)
                else
                    self:showExitDialog("Incorrect code")
                end
            end},
        }},
    }
    self.exit_dialog = dialog
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function AppScreen:onClose()
    self:showExitDialog()
    return true
end

function AppScreen:onSwipeNoop()
    return true
end

return AppScreen
