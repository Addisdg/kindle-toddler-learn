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
local EDGE_MARGIN = 36
local PROMPT_HEIGHT = 150
local TILE_GAP = 26
local TILE_PADDING = 14
local TILE_BORDER = 5
local SELECTED_TILE_BORDER = 9
local WRONG_FEEDBACK_SECONDS = 0.35

--------------------------------------------------------------------------
-- GameScreen
--------------------------------------------------------------------------

local GameScreen = InputContainer:extend{
    assets_dir = nil,
    active_category = "mixed",
    difficulty = "normal",
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
            ges = "two_finger_hold",
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
    self:resetRoundOrder()

    self:loadRound()
end

function GameScreen:shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

function GameScreen:resetRoundOrder()
    self.rounds = Content.getRounds(self.active_category)
    self.round_order = {}
    for i = 1, #self.rounds do
        table.insert(self.round_order, i)
    end
    self:shuffle(self.round_order)
    self.round_pos = 0
end

function GameScreen:setCategory(category)
    self.active_category = category or "mixed"
    self:resetRoundOrder()
    self:loadRound()
end

function GameScreen:setDifficulty(difficulty)
    self.difficulty = difficulty or "normal"
    self:loadRound()
end

function GameScreen:getChoiceLimit()
    if self.difficulty == "easy" then
        return 2
    end
    if self.difficulty == "hard" then
        return 4
    end
    return 3
end

function GameScreen:buildChoices(round)
    local choice_limit = self:getChoiceLimit()
    local choices = {{
        path = round.answer,
        correct = true,
    }}
    local seen = {
        [round.answer] = true,
    }

    for _, path in ipairs(round.distractors) do
        if #choices >= choice_limit then
            break
        end
        if not seen[path] then
            table.insert(choices, {
                path = path,
                correct = false,
            })
            seen[path] = true
        end
    end

    for _, candidate in ipairs(self.rounds or {}) do
        if #choices >= choice_limit then
            break
        end
        if candidate.category == round.category and not seen[candidate.answer] then
            table.insert(choices, {
                path = candidate.answer,
                correct = false,
            })
            seen[candidate.answer] = true
        end
    end

    return choices
end

function GameScreen:getLayout(choice_count)
    local sw = Screen:getWidth()
    local sh = Screen:getHeight()
    local usable_w = sw - EDGE_MARGIN * 2
    local tile_w = math.floor((usable_w - (choice_count - 1) * TILE_GAP) / choice_count)
    local max_tile_h = sh - PROMPT_HEIGHT - EDGE_MARGIN * 3
    local tile_h = math.min(math.floor(tile_w * 1.12), max_tile_h)

    return {
        screen_w = sw,
        screen_h = sh,
        usable_w = usable_w,
        prompt_h = PROMPT_HEIGHT,
        tile_w = tile_w,
        tile_h = tile_h,
        tile_gap = TILE_GAP,
        tile_padding = TILE_PADDING,
        tile_border = TILE_BORDER,
    }
end

function GameScreen:getTileStyle(layout, choice_index)
    local is_selected = self.feedback and self.feedback.choice_index == choice_index
    local tile_border = is_selected and SELECTED_TILE_BORDER or layout.tile_border
    local tile_padding = is_selected
        and math.max(4, layout.tile_padding - (SELECTED_TILE_BORDER - layout.tile_border))
        or layout.tile_padding

    return {
        border = tile_border,
        padding = tile_padding,
        selected = is_selected or false,
    }
end

function GameScreen:loadRound()
    self.round_pos = self.round_pos + 1
    if self.round_pos > #self.round_order then
        self.round_pos = 1
        self:shuffle(self.round_order)
    end

    self.current_round = self.rounds[self.round_order[self.round_pos]]
    self.feedback = nil
    local round = self.current_round
    logger.warn("ToddlerLearn: loading round", round.prompt)

    local choices = self:buildChoices(round)
    self:shuffle(choices)
    self.current_choices = choices

    self:renderRound()
end

function GameScreen:renderRound()
    local round = self.current_round
    local choices = self.current_choices
    if not round or not choices then
        return
    end

    local layout = self:getLayout(#choices)

    -- Prompt text
    local prompt_widget = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{
                w = layout.usable_w,
                h = layout.prompt_h
            },
            TextWidget:new{
                text = round.prompt,
                face = Font:getFace("tfont", 64)
            }
        }
    }

    -- Tiles
    local n = #choices
    local tiles_group = HorizontalGroup:new{
        align = "center"
    }

    for i, choice in ipairs(choices) do
        local img_path = self.assets_dir .. choice.path
        logger.warn("ToddlerLearn: loading image", img_path)
        local tile_style = self:getTileStyle(layout, i)

        local tile = FrameContainer:new{
            width = layout.tile_w,
            height = layout.tile_h,
            bordersize = tile_style.border,
            padding = tile_style.padding,
            margin = 0,
            ImageWidget:new{
                file = img_path,
                width = layout.tile_w - (tile_style.padding + tile_style.border) * 2,
                height = layout.tile_h - (tile_style.padding + tile_style.border) * 2,
                scale_factor = 0
            }
        }

        -- Wrap in InputContainer for tap detection
        local is_correct = choice.correct
        local tappable = InputContainer:new{
            dimen = Geom:new{
                x = 0,
                y = 0,
                w = layout.tile_w,
                h = layout.tile_h
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
            self:onAnswer(is_correct, i)
            return true
        end

        table.insert(tiles_group, tappable)

        if i < n then
            table.insert(tiles_group, FrameContainer:new{
                bordersize = 0,
                padding = 0,
                dimen = Geom:new{
                    w = layout.tile_gap,
                    h = layout.tile_h
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
            FrameContainer:new{
                bordersize = 0,
                padding = 0,
                dimen = Geom:new{
                    w = layout.usable_w,
                    h = EDGE_MARGIN
                },
                TextWidget:new{
                    text = "",
                    face = Font:getFace("cfont", 10)
                }
            },
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

function GameScreen:onAnswer(is_correct, choice_index)
    if is_correct then
        self.feedback = {
            kind = "correct",
            choice_index = choice_index
        }
        self:showCorrectFeedback()
    else
        self:showWrongFeedback(choice_index)
    end
    return true
end

function GameScreen:showWrongFeedback(choice_index)
    if not self.dimen then
        UIManager:setDirty(self, "fast")
        return
    end

    self.feedback = {
        kind = "wrong",
        choice_index = choice_index
    }
    self:renderRound()

    UIManager:scheduleIn(WRONG_FEEDBACK_SECONDS, function()
        self.feedback = nil
        self:renderRound()
    end)
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
