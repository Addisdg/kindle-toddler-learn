local InputContainer = require("ui/widget/container/inputcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local ImageWidget = require("ui/widget/imagewidget")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local logger = require("logger")
local _ = require("gettext")

local Content = require("content")
local Blitbuffer = require("ffi/blitbuffer")

local MARGIN = 15

--------------------------------------------------------------------------
-- GameScreen
--------------------------------------------------------------------------

local GameScreen = InputContainer:extend{
    assets_dir = nil
}

function GameScreen:init()
    self.dimen = Geom:new{
        x = 0,
        y = 0,
        w = Screen:getWidth(),
        h = Screen:getHeight()
    }

    -- Close on two-finger tap
    self.ges_events = {
        Close = {GestureRange:new{
            ges = "two_finger_tap",
            range = self.dimen
        }}
    }

    -- Consume all common KOReader navigation gestures so a toddler
    -- can't swipe into menus or settings while the game is running.
    local swipe_range = GestureRange:new{
        ges = "swipe",
        range = self.dimen
    }
    local hold_range = GestureRange:new{
        ges = "hold",
        range = self.dimen
    }
    local pan_range = GestureRange:new{
        ges = "pan",
        range = self.dimen
    }

    self.ges_events.SwipeNoop = {swipe_range}
    self.ges_events.HoldNoop = {hold_range}
    self.ges_events.PanNoop = {pan_range}

    math.randomseed(os.time())
    self.round_order = {}
    for i = 1, #Content do
        table.insert(self.round_order, i)
    end
    self:shuffle(self.round_order)
    self.round_pos = 0

    self:loadRound()
end

function GameScreen:shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

function GameScreen:loadRound()
    self.round_pos = self.round_pos + 1
    if self.round_pos > #self.round_order then
        self.round_pos = 1
        self:shuffle(self.round_order)
    end

    local round = Content[self.round_order[self.round_pos]]
    logger.warn("ToddlerLearn: loading round", round.prompt)

    -- Build choices list and shuffle
    local choices = {{
        path = round.answer,
        correct = true
    }}
    for _, d in ipairs(round.distractors) do
        table.insert(choices, {
            path = d,
            correct = false
        })
    end
    self:shuffle(choices)

    local sw = Screen:getWidth()
    local sh = Screen:getHeight()

    -- Prompt text
    local prompt_widget = FrameContainer:new{
        bordersize = 0,
        padding = MARGIN,
        CenterContainer:new{
            dimen = Geom:new{
                w = sw - MARGIN * 2,
                h = 100
            },
            TextWidget:new{
                text = round.prompt,
                face = Font:getFace("tfont", 52)
            }
        }
    }

    -- Tiles
    local n = #choices
    local tile_w = math.floor((sw - (n + 1) * MARGIN) / n)
    local tile_h = math.floor(tile_w * 1.1)

    local tiles_group = HorizontalGroup:new{
        align = "center"
    }

    -- leading margin
    table.insert(tiles_group, FrameContainer:new{
        bordersize = 0,
        padding = 0,
        dimen = Geom:new{
            w = MARGIN,
            h = tile_h
        },
        TextWidget:new{
            text = "",
            face = Font:getFace("cfont", 10)
        }
    })

    for i, choice in ipairs(choices) do
        local img_path = self.assets_dir .. choice.path
        logger.warn("ToddlerLearn: loading image", img_path)

        local tile = FrameContainer:new{
            width = tile_w,
            height = tile_h,
            bordersize = 3,
            padding = 8,
            margin = 0,
            ImageWidget:new{
                file = img_path,
                width = tile_w - 22,
                height = tile_h - 22,
                scale_factor = 0
            }
        }

        -- Wrap in InputContainer for tap detection
        local is_correct = choice.correct
        local tappable = InputContainer:new{
            dimen = Geom:new{
                x = 0,
                y = 0,
                w = tile_w,
                h = tile_h
            }
        }
        tappable.ges_events = {
            Tap = {GestureRange:new{
                ges = "tap",
                range = tappable.dimen
            }}
        }
        tappable[1] = tile
        tappable.onTap = function()
            self:onAnswer(is_correct)
            return true
        end

        table.insert(tiles_group, tappable)

        if i < n then
            table.insert(tiles_group, FrameContainer:new{
                bordersize = 0,
                padding = 0,
                dimen = Geom:new{
                    w = MARGIN,
                    h = tile_h
                },
                TextWidget:new{
                    text = "",
                    face = Font:getFace("cfont", 10)
                }
            })
        end
    end

    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            prompt_widget,
            tiles_group
        }
    }

    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        content
    }

    UIManager:setDirty(self, "full")
end

function GameScreen:onAnswer(is_correct)
    if is_correct then
        self:showCorrectFeedback()
    else
        -- Wrong answer: subtle flash, stay on same round
        UIManager:setDirty(self, "fast")
    end
    return true
end

function GameScreen:showCorrectFeedback()
    -- In test environment dimen may not be set, skip UI and go straight to next round
    if not self.dimen then
        self:loadRound()
        return
    end

    local feedback = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        CenterContainer:new{
            dimen = self.dimen,
            TextWidget:new{
                text = "✓",
                face = Font:getFace("tfont", 160)
            }
        }
    }

    UIManager:show(feedback)
    UIManager:setDirty(feedback, "full")

    UIManager:scheduleIn(0.4, function()
        UIManager:close(feedback)
        self:loadRound()
    end)
end

function GameScreen:onClose()
    UIManager:close(self)
    return true
end
function GameScreen:onSwipeNoop()
    return true
end
function GameScreen:onHoldNoop()
    return true
end
function GameScreen:onPanNoop()
    return true
end

return GameScreen
