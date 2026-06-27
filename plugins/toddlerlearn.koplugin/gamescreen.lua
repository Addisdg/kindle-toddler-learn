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
local PARENT_ROW_HEIGHT = 120
local REWARD_EVERY = 5
local REWARD_SECONDS = 0.8
local SPELLING_GAP = 8
local SPELLING_LETTER_MAX = 88
local SPELLING_LETTER_HEIGHT = 84
local SPELLING_FONT_MAX = 56

--------------------------------------------------------------------------
-- GameScreen
--------------------------------------------------------------------------

local GameScreen = InputContainer:extend{
    assets_dir = nil,
    active_category = "mixed",
    difficulty = "normal",
    parent_mode = false,
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

    if self.parent_mode then
        self.selected_category = self.selected_category or self.active_category or "mixed"
        self.selected_difficulty = self.selected_difficulty or self.difficulty or "normal"
        self:renderParentMenu()
        return
    end

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

function GameScreen:getCategoryOptions()
    local options = {"mixed"}
    for _, category in ipairs(Content.category_order) do
        table.insert(options, category)
    end
    return options
end

function GameScreen:getCategoryLabel(category)
    if category == "mixed" then
        return "Mixed Review"
    end
    return Content.categories[category] and Content.categories[category].label or category
end

function GameScreen:getDifficultyLabel(difficulty)
    if difficulty == "easy" then
        return "Easy: 2 choices"
    end
    if difficulty == "hard" then
        return "Hard: 4 choices"
    end
    return "Normal: 3 choices"
end

function GameScreen:cycleCategory()
    local options = self:getCategoryOptions()
    local next_index = 1
    for i, category in ipairs(options) do
        if category == self.selected_category then
            next_index = i + 1
            break
        end
    end
    if next_index > #options then
        next_index = 1
    end
    self.selected_category = options[next_index]
    return self.selected_category
end

function GameScreen:cycleDifficulty()
    local next_by_difficulty = {
        easy = "normal",
        normal = "hard",
        hard = "easy",
    }
    self.selected_difficulty = next_by_difficulty[self.selected_difficulty] or "normal"
    return self.selected_difficulty
end

function GameScreen:renderParentButton(text, on_tap)
    local button = InputContainer:new{
        dimen = Geom:new{
            x = 0,
            y = 0,
            w = self.dimen.w - EDGE_MARGIN * 2,
            h = PARENT_ROW_HEIGHT,
        }
    }
    button.ges_events = {
        Tap = {GestureRange:new{
            ges = "tap",
            range = button.dimen,
        }}
    }
    button[1] = FrameContainer:new{
        width = self.dimen.w - EDGE_MARGIN * 2,
        height = PARENT_ROW_HEIGHT,
        bordersize = TILE_BORDER,
        padding = 12,
        CenterContainer:new{
            dimen = Geom:new{
                w = self.dimen.w - EDGE_MARGIN * 2 - 34,
                h = PARENT_ROW_HEIGHT - 34,
            },
            TextWidget:new{
                text = text,
                face = Font:getFace("tfont", 36),
            }
        }
    }
    button.onTap = function()
        on_tap()
        return true
    end
    return button
end

function GameScreen:renderParentMenu()
    local category_text = "Category: " .. self:getCategoryLabel(self.selected_category)
    local difficulty_text = "Difficulty: " .. self:getDifficultyLabel(self.selected_difficulty)
    local start_text = "Start"

    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            FrameContainer:new{
                bordersize = 0,
                padding = 0,
                CenterContainer:new{
                    dimen = Geom:new{
                        w = self.dimen.w - EDGE_MARGIN * 2,
                        h = 130,
                    },
                    TextWidget:new{
                        text = "Parent Setup",
                        face = Font:getFace("tfont", 52),
                    }
                }
            },
            self:renderParentButton(category_text, function()
                self:cycleCategory()
                self:renderParentMenu()
            end),
            self:renderParentButton(difficulty_text, function()
                self:cycleDifficulty()
                self:renderParentMenu()
            end),
            self:renderParentButton(start_text, function()
                UIManager:close(self)
                UIManager:show(GameScreen:new{
                    assets_dir = self.assets_dir,
                    active_category = self.selected_category,
                    difficulty = self.selected_difficulty,
                })
            end),
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

function GameScreen:getSpellingLetters(word)
    local letters = {}
    for i = 1, #word do
        table.insert(letters, word:sub(i, i))
    end
    return letters
end

function GameScreen:getScrambledLetters(word)
    local letters = self:getSpellingLetters(word)
    local original = table.concat(letters, "")
    self:shuffle(letters)

    if #letters > 2 and table.concat(letters, "") == original then
        letters[1], letters[#letters] = letters[#letters], letters[1]
    end

    return letters
end

function GameScreen:startSpellingRound(round)
    self.current_choices = nil
    self.spelling = {
        word = round.word,
        letters = self:getScrambledLetters(round.word),
        filled = {},
        used = {},
        feedback = nil,
    }
    self:renderSpellingRound()
end

function GameScreen:getSpellingAnswer()
    if not self.spelling then
        return ""
    end
    return table.concat(self.spelling.filled, "")
end

function GameScreen:isSpellingComplete()
    return self.spelling and #self.spelling.filled == #self.spelling.word
end

function GameScreen:isSpellingCorrect()
    return self:isSpellingComplete() and self:getSpellingAnswer() == self.spelling.word
end

function GameScreen:resetSpellingAttempt()
    if not self.spelling then
        return
    end

    self.spelling.filled = {}
    self.spelling.used = {}
    self.spelling.feedback = nil
    if self.dimen then
        self:renderSpellingRound()
    end
end

function GameScreen:getSpellingLayout(letter_count)
    local sw = Screen:getWidth()
    local sh = Screen:getHeight()
    local usable_w = sw - EDGE_MARGIN * 2
    local available_letter_w = math.floor((usable_w - (letter_count - 1) * SPELLING_GAP) / letter_count)
    local letter_w = math.min(SPELLING_LETTER_MAX, math.max(1, available_letter_w))
    local image_size = math.min(250, usable_w, math.floor(sh * 0.34))

    return {
        screen_w = sw,
        screen_h = sh,
        usable_w = usable_w,
        prompt_h = 90,
        image_size = image_size,
        letter_w = letter_w,
        letter_h = SPELLING_LETTER_HEIGHT,
        letter_font_size = math.min(SPELLING_FONT_MAX, math.max(30, letter_w - 16)),
        letter_gap = SPELLING_GAP,
    }
end

function GameScreen:makeBlankSpacer(width, height)
    return FrameContainer:new{
        bordersize = 0,
        padding = 0,
        dimen = Geom:new{
            w = width,
            h = height
        },
        TextWidget:new{
            text = "",
            face = Font:getFace("cfont", 10)
        }
    }
end

function GameScreen:buildSpellingBoxes(layout)
    local boxes = HorizontalGroup:new{
        align = "center"
    }

    for i = 1, #self.spelling.word do
        local letter = self.spelling.filled[i] or ""
        local box = FrameContainer:new{
            width = layout.letter_w,
            height = layout.letter_h,
            bordersize = 4,
            padding = 0,
            CenterContainer:new{
                dimen = Geom:new{
                    w = layout.letter_w,
                    h = layout.letter_h,
                },
                TextWidget:new{
                    text = letter,
                    face = Font:getFace("tfont", layout.letter_font_size)
                }
            }
        }

        local tappable = InputContainer:new{
            dimen = Geom:new{
                x = 0,
                y = 0,
                w = layout.letter_w,
                h = layout.letter_h,
            }
        }
        tappable.ges_events = {
            Tap = {GestureRange:new{
                ges = "tap",
                range = tappable.dimen,
            }}
        }
        tappable[1] = box
        tappable.onTap = function()
            self:onSpellingBoxesTap()
            return true
        end
        table.insert(boxes, tappable)

        if i < #self.spelling.word then
            table.insert(boxes, self:makeBlankSpacer(layout.letter_gap, layout.letter_h))
        end
    end

    return boxes
end

function GameScreen:buildSpellingLetters(layout)
    local letters = HorizontalGroup:new{
        align = "center"
    }

    for i, letter in ipairs(self.spelling.letters) do
        local letter_index = i
        local used = self.spelling.used[i]
        local letter_text = used and "" or letter
        local button = FrameContainer:new{
            width = layout.letter_w,
            height = layout.letter_h,
            bordersize = used and 1 or 4,
            padding = 0,
            CenterContainer:new{
                dimen = Geom:new{
                    w = layout.letter_w,
                    h = layout.letter_h,
                },
                TextWidget:new{
                    text = letter_text,
                    face = Font:getFace("tfont", layout.letter_font_size)
                }
            }
        }

        local tappable = InputContainer:new{
            dimen = Geom:new{
                x = 0,
                y = 0,
                w = layout.letter_w,
                h = layout.letter_h
            }
        }
        tappable.ges_events = {
            Tap = {GestureRange:new{
                ges = "tap",
                range = tappable.dimen
            }}
        }
        tappable[1] = button
        tappable.onTap = function()
            self:onSpellingLetterTap(letter_index)
            return true
        end

        table.insert(letters, tappable)

        if i < #self.spelling.letters then
            table.insert(letters, self:makeBlankSpacer(layout.letter_gap, layout.letter_h))
        end
    end

    return letters
end

function GameScreen:renderSpellingRound()
    local round = self.current_round
    if not round or not self.spelling then
        return
    end

    local layout = self:getSpellingLayout(#self.spelling.word)
    local img_path = self.assets_dir .. round.answer
    logger.warn("ToddlerLearn: loading spelling image", img_path)

    local feedback_text = self.spelling.feedback or " "

    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            self:makeBlankSpacer(layout.usable_w, EDGE_MARGIN),
            CenterContainer:new{
                dimen = Geom:new{
                    w = layout.usable_w,
                    h = layout.prompt_h,
                },
                TextWidget:new{
                    text = round.prompt,
                    face = Font:getFace("tfont", 58)
                }
            },
            ImageWidget:new{
                file = img_path,
                width = layout.image_size,
                height = layout.image_size,
                scale_factor = 0
            },
            self:makeBlankSpacer(layout.usable_w, 18),
            self:buildSpellingBoxes(layout),
            self:makeBlankSpacer(layout.usable_w, 16),
            self:buildSpellingLetters(layout),
            CenterContainer:new{
                dimen = Geom:new{
                    w = layout.usable_w,
                    h = 52,
                },
                TextWidget:new{
                    text = feedback_text,
                    face = Font:getFace("tfont", 30)
                }
            }
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

    if round.kind == "spelling" then
        self:startSpellingRound(round)
        return
    end

    self.spelling = nil

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
        local image_height = layout.tile_h - (tile_style.padding + tile_style.border) * 2
        local tile_content = ImageWidget:new{
            file = img_path,
            width = layout.tile_w - (tile_style.padding + tile_style.border) * 2,
            height = image_height,
            scale_factor = 0
        }

        local tile = FrameContainer:new{
            width = layout.tile_w,
            height = layout.tile_h,
            bordersize = tile_style.border,
            padding = tile_style.padding,
            margin = 0,
            tile_content
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
        if self:recordCorrectAnswer() then
            self:showRewardFeedback()
        else
            self:showCorrectFeedback()
        end
    else
        self:showWrongFeedback(choice_index)
    end
    return true
end

function GameScreen:onSpellingLetterTap(letter_index)
    if not self.spelling or self.spelling.used[letter_index] then
        return true
    end

    table.insert(self.spelling.filled, self.spelling.letters[letter_index])
    self.spelling.used[letter_index] = true

    if not self:isSpellingComplete() then
        if self.dimen then
            self:renderSpellingRound()
        end
        return true
    end

    if self:isSpellingCorrect() then
        if self:recordCorrectAnswer() then
            self:showRewardFeedback()
        else
            self:showCorrectFeedback()
        end
        return true
    end

    self.spelling.feedback = "Try again"
    if self.dimen then
        self:renderSpellingRound()
    end
    return true
end

function GameScreen:onSpellingBoxesTap()
    if self.spelling and #self.spelling.filled > 0 then
        self:resetSpellingAttempt()
    end
    return true
end

function GameScreen:recordCorrectAnswer()
    self.correct_count = (self.correct_count or 0) + 1
    return self.correct_count % REWARD_EVERY == 0
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

function GameScreen:showRewardFeedback()
    if not self.dimen then
        self:loadRound()
        return
    end

    local reward = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        CenterContainer:new{
            dimen = self.dimen,
            VerticalGroup:new{
                align = "center",
                TextWidget:new{
                    text = "Great!",
                    face = Font:getFace("tfont", 86)
                },
                TextWidget:new{
                    text = "* * * * *",
                    face = Font:getFace("tfont", 64)
                },
                TextWidget:new{
                    text = tostring(self.correct_count) .. " correct",
                    face = Font:getFace("tfont", 42)
                }
            }
        }
    }

    UIManager:show(reward)
    UIManager:setDirty(reward, "full")

    UIManager:scheduleIn(REWARD_SECONDS, function()
        UIManager:close(reward)
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
