local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local _ = require("gettext")

local ToddlerLearn = WidgetContainer:extend{
    name = "toddlerlearn",
    is_doc_only = false,
}

function ToddlerLearn:init()
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
end

function ToddlerLearn:addToMainMenu(menu_items)
    menu_items.toddler_learn = {
        text = _("Toddler Learn"),
        sorting_hint = "tools",
        callback = function()
            local AppScreen = require("appscreen")
            local screen = AppScreen:new{
                assets_dir = self.path .. "/assets/",
            }
            UIManager:show(screen)
        end,
    }
    menu_items.toddler_learn_parent = {
        text = _("Toddler Learn Parent Setup"),
        sorting_hint = "tools",
        callback = function()
            local GameScreen = require("gamescreen")
            local screen = GameScreen:new{
                assets_dir = self.path .. "/assets/",
                parent_mode = true,
            }
            UIManager:show(screen)
        end,
    }
    menu_items.toddler_learn_progress = {
        text = _("Toddler Learn Progress"),
        sorting_hint = "tools",
        callback = function()
            local GameScreen = require("gamescreen")
            local screen = GameScreen:new{
                assets_dir = self.path .. "/assets/",
                progress_mode = true,
            }
            UIManager:show(screen)
        end,
    }
end

return ToddlerLearn
