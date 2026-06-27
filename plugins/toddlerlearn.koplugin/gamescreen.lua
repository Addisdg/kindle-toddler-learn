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
local TEXT_CHOICE_FONT = 84
local GUIDED_CATEGORIES = {
    "letter_pairs",
    "beginning_sounds",
    "ending_sounds",
    "cvc_words",
    "word_blending",
    "word_families",
    "sentence_building",
    "sentences",
    "mini_stories",
}
local GUIDED_MASTERY_RATIO = 0.7

--------------------------------------------------------------------------
-- GameScreen
--------------------------------------------------------------------------

local GameScreen = InputContainer:extend{
    assets_dir = nil,
    active_category = "mixed",
    difficulty = "normal",
    session_length = 10,
    parent_mode = false,
    progress_mode = false,
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

    if self.progress_mode then
        self.progress = self.progress or self:loadProgress()
        self.selected_progress_category = self.selected_progress_category
            or Content.category_order[1]
        self:renderProgressScreen()
        return
    end

    if self.parent_mode then
        self.selected_category = self.selected_category or self.active_category or "mixed"
        self.selected_difficulty = self.selected_difficulty or self.difficulty or "normal"
        self.selected_session_length = self.selected_session_length or self.session_length or 10
        self:renderParentMenu()
        return
    end

    math.randomseed(os.time())
    self.progress = self.progress or self:loadProgress()
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
    local category = self.active_category
    if category == "guided" then
        category = self:getGuidedCategory()
        self.guided_category = category
    end
    self.rounds = Content.getRounds(category)
    self.round_order = self:buildAdaptiveRoundOrder(self.rounds)
    self:shuffle(self.round_order)
    self.round_pos = 0
end

function GameScreen:isRoundMastered(round)
    local result = (self.progress or {})[self:getRoundKey(round)]
    return result ~= nil
        and result.correct >= 2
        and result.correct > result.wrong
end

function GameScreen:getCategoryMastery(category)
    local rounds = Content.getRounds(category)
    if #rounds == 0 then
        return 0
    end
    local mastered = 0
    for _, round in ipairs(rounds) do
        if self:isRoundMastered(round) then
            mastered = mastered + 1
        end
    end
    return mastered / #rounds
end

function GameScreen:getGuidedCategory()
    for _, category in ipairs(GUIDED_CATEGORIES) do
        if self:getCategoryMastery(category) < GUIDED_MASTERY_RATIO then
            return category
        end
    end
    return GUIDED_CATEGORIES[#GUIDED_CATEGORIES]
end

function GameScreen:getRoundKey(round)
    local identity = round.word or round.sentence or round.answer_text or round.answer or round.count or round.prompt
    return (round.category or "unknown") .. ":" .. (round.kind or "picture") .. ":" .. tostring(identity)
end

function GameScreen:loadProgress()
    local settings = self.settings or rawget(_G, "G_reader_settings")
    if settings and settings.readSetting then
        return settings:readSetting("toddlerlearn_progress", {}) or {}
    end
    return {}
end

function GameScreen:saveProgress()
    local settings = self.settings or rawget(_G, "G_reader_settings")
    if not settings or not settings.saveSetting then
        return
    end
    settings:saveSetting("toddlerlearn_progress", self.progress or {})
    if settings.flush then
        settings:flush()
    end
end

function GameScreen:recordRoundResult(is_correct)
    if not self.current_round then
        return
    end
    self.progress = self.progress or {}
    local key = self:getRoundKey(self.current_round)
    local result = self.progress[key] or {correct = 0, wrong = 0}
    if is_correct then
        result.correct = result.correct + 1
    else
        result.wrong = result.wrong + 1
    end
    self.progress[key] = result
    self:saveProgress()
end

function GameScreen:buildAdaptiveRoundOrder(rounds)
    self.round_order = {}
    for i, round in ipairs(rounds or {}) do
        table.insert(self.round_order, i)
        local result = (self.progress or {})[self:getRoundKey(round)]
        if result and result.wrong > result.correct then
            table.insert(self.round_order, i)
            if result.wrong >= result.correct + 3 then
                table.insert(self.round_order, i)
            end
        end
    end
    return self.round_order
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
    local options = {"guided", "mixed"}
    for _, category in ipairs(Content.category_order) do
        table.insert(options, category)
    end
    return options
end

function GameScreen:getCategoryLabel(category)
    if category == "guided" then
        return "Guided Learning"
    end
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

function GameScreen:cycleSessionLength()
    local next_length = {
        [5] = 10,
        [10] = 15,
        [15] = 5,
    }
    self.selected_session_length = next_length[self.selected_session_length] or 10
    return self.selected_session_length
end

function GameScreen:getProgressSummary(category)
    local summary = {
        correct = 0,
        wrong = 0,
        attempts = 0,
        mastered = 0,
        total = 0,
        needs_practice = 0,
    }
    for _, round in ipairs(Content.getRounds(category)) do
        summary.total = summary.total + 1
        local result = (self.progress or {})[self:getRoundKey(round)]
        if result then
            summary.correct = summary.correct + (result.correct or 0)
            summary.wrong = summary.wrong + (result.wrong or 0)
            if (result.correct or 0) >= 2 and (result.correct or 0) > (result.wrong or 0) then
                summary.mastered = summary.mastered + 1
            end
            if (result.wrong or 0) > (result.correct or 0) then
                summary.needs_practice = summary.needs_practice + 1
            end
        end
    end
    summary.attempts = summary.correct + summary.wrong
    return summary
end

function GameScreen:getOverallProgressSummary()
    local summary = {correct = 0, wrong = 0, attempts = 0}
    for _, result in pairs(self.progress or {}) do
        summary.correct = summary.correct + (result.correct or 0)
        summary.wrong = summary.wrong + (result.wrong or 0)
    end
    summary.attempts = summary.correct + summary.wrong
    return summary
end

function GameScreen:cycleProgressCategory()
    local next_index = 1
    for i, category in ipairs(Content.category_order) do
        if category == self.selected_progress_category then
            next_index = i + 1
            break
        end
    end
    if next_index > #Content.category_order then
        next_index = 1
    end
    self.selected_progress_category = Content.category_order[next_index]
    self.reset_progress_armed = false
    return self.selected_progress_category
end

function GameScreen:resetProgress()
    self.progress = {}
    self.reset_progress_armed = false
    self:saveProgress()
    if self.dimen then
        self:renderProgressScreen()
    end
end

function GameScreen:renderProgressScreen()
    local category = self.selected_progress_category
    local category_summary = self:getProgressSummary(category)
    local overall = self:getOverallProgressSummary()
    local accuracy = overall.attempts > 0
        and math.floor((overall.correct / overall.attempts) * 100 + 0.5)
        or 0
    local reset_text = self.reset_progress_armed and "Tap again to reset" or "Reset Progress"
    local summary_text = table.concat({
        "Overall: " .. tostring(overall.correct) .. "/" .. tostring(overall.attempts)
            .. " correct (" .. tostring(accuracy) .. "%)",
        "Mastered: " .. tostring(category_summary.mastered) .. "/" .. tostring(category_summary.total),
        "Needs practice: " .. tostring(category_summary.needs_practice),
    }, "\n")
    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 110},
                TextWidget:new{text = "Learning Progress", face = Font:getFace("tfont", 48)},
            },
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 180},
                TextWidget:new{text = summary_text, face = Font:getFace("tfont", 32)},
            },
            self:renderParentButton("Category: " .. self:getCategoryLabel(category), function()
                self:cycleProgressCategory()
                self:renderProgressScreen()
            end),
            self:renderParentButton(reset_text, function()
                if self.reset_progress_armed then
                    self:resetProgress()
                else
                    self.reset_progress_armed = true
                    self:renderProgressScreen()
                end
            end),
            self:renderParentButton("Close", function()
                UIManager:close(self)
            end),
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
    local session_text = "Session: " .. tostring(self.selected_session_length) .. " rounds"
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
            self:renderParentButton(session_text, function()
                self:cycleSessionLength()
                self:renderParentMenu()
            end),
            self:renderParentButton(start_text, function()
                UIManager:close(self)
                UIManager:show(GameScreen:new{
                    assets_dir = self.assets_dir,
                    active_category = self.selected_category,
                    difficulty = self.selected_difficulty,
                    session_length = self.selected_session_length,
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
    if round.kind == "text_choice" then
        local choices = {{text = round.answer_text, correct = true}}
        local seen = {[round.answer_text] = true}

        for _, text in ipairs(round.distractors_text or {}) do
            if #choices >= choice_limit then
                break
            end
            if not seen[text] then
                table.insert(choices, {text = text, correct = false})
                seen[text] = true
            end
        end

        for _, candidate in ipairs(self.rounds or {}) do
            if #choices >= choice_limit then
                break
            end
            if candidate.category == round.category
                and candidate.answer_text
                and not seen[candidate.answer_text]
            then
                table.insert(choices, {text = candidate.answer_text, correct = false})
                seen[candidate.answer_text] = true
            end
        end
        return choices
    end

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
        if candidate.category == round.category
            and candidate.answer
            and not seen[candidate.answer]
        then
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

function GameScreen:getScrambledWords(words)
    local scrambled = {}
    for _, word in ipairs(words) do
        table.insert(scrambled, word)
    end
    self:shuffle(scrambled)
    if #scrambled > 2 and table.concat(scrambled, " ") == table.concat(words, " ") then
        scrambled[1], scrambled[#scrambled] = scrambled[#scrambled], scrambled[1]
    end
    return scrambled
end

function GameScreen:startSentenceBuildRound(round)
    self.current_choices = nil
    self.spelling = nil
    self.sentence_build = {
        answer_words = round.words,
        choices = self:getScrambledWords(round.words),
        filled = {},
        used = {},
        feedback = nil,
    }
    self:renderSentenceBuildRound()
end

function GameScreen:getSentenceAnswer()
    if not self.sentence_build then
        return ""
    end
    return table.concat(self.sentence_build.filled, " ")
end

function GameScreen:resetSentenceAttempt()
    if not self.sentence_build then
        return
    end
    self.sentence_build.filled = {}
    self.sentence_build.used = {}
    self.sentence_build.feedback = nil
    if self.dimen then
        self:renderSentenceBuildRound()
    end
end

function GameScreen:getSentenceLayout(word_count)
    local usable_w = Screen:getWidth() - EDGE_MARGIN * 2
    local gap = 10
    local available_w = math.floor((usable_w - (word_count - 1) * gap) / word_count)
    local word_w = math.min(220, math.max(1, available_w))
    return {
        usable_w = usable_w,
        word_w = word_w,
        word_h = 84,
        gap = gap,
        font_size = math.min(42, math.max(26, math.floor(word_w / 5))),
    }
end

function GameScreen:makeSentenceToken(text, layout, on_tap, used)
    local token = FrameContainer:new{
        width = layout.word_w,
        height = layout.word_h,
        bordersize = used and 1 or 4,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{w = layout.word_w, h = layout.word_h},
            TextWidget:new{
                text = used and "" or text,
                face = Font:getFace("tfont", layout.font_size),
            }
        }
    }
    local tappable = InputContainer:new{
        dimen = Geom:new{x = 0, y = 0, w = layout.word_w, h = layout.word_h},
    }
    tappable.ges_events = {
        Tap = {GestureRange:new{ges = "tap", range = tappable.dimen}}
    }
    tappable[1] = token
    tappable.onTap = function()
        on_tap()
        return true
    end
    return tappable
end

function GameScreen:buildSentenceRow(layout, answer_row)
    local row = HorizontalGroup:new{align = "center"}
    local words = answer_row and self.sentence_build.answer_words or self.sentence_build.choices
    for i, word in ipairs(words) do
        local index = i
        local text = answer_row and (self.sentence_build.filled[i] or "") or word
        local used = not answer_row and self.sentence_build.used[i]
        local on_tap = answer_row
            and function() self:resetSentenceAttempt() end
            or function() self:onSentenceWordTap(index) end
        table.insert(row, self:makeSentenceToken(text, layout, on_tap, used))
        if i < #words then
            table.insert(row, self:makeBlankSpacer(layout.gap, layout.word_h))
        end
    end
    return row
end

function GameScreen:renderSentenceBuildRound()
    if not self.current_round or not self.sentence_build then
        return
    end
    local layout = self:getSentenceLayout(#self.sentence_build.answer_words)
    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            self:makeBlankSpacer(layout.usable_w, EDGE_MARGIN),
            CenterContainer:new{
                dimen = Geom:new{w = layout.usable_w, h = 150},
                TextWidget:new{text = self.current_round.prompt, face = Font:getFace("tfont", 58)},
            },
            self:makeBlankSpacer(layout.usable_w, 80),
            self:buildSentenceRow(layout, true),
            self:makeBlankSpacer(layout.usable_w, 36),
            self:buildSentenceRow(layout, false),
            CenterContainer:new{
                dimen = Geom:new{w = layout.usable_w, h = 60},
                TextWidget:new{
                    text = self.sentence_build.feedback or " ",
                    face = Font:getFace("tfont", 30),
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
        content,
    }
    UIManager:setDirty(self, "full")
end

function GameScreen:startStoryRound(round)
    self.current_choices = nil
    self.spelling = nil
    self.sentence_build = nil
    self.story_page = 1
    self:renderStoryPage()
end

function GameScreen:startTapCountRound(round)
    self.current_choices = nil
    self.spelling = nil
    self.sentence_build = nil
    self.tap_count = {
        count = round.count,
        tapped = {},
        tapped_total = 0,
    }
    self:renderTapCountRound()
end

function GameScreen:makeCountObject(index)
    local size = 130
    local tapped = self.tap_count.tapped[index]
    local object = FrameContainer:new{
        width = size,
        height = size,
        bordersize = 4,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{w = size, h = size},
            TextWidget:new{
                text = tapped and "" or "*",
                face = Font:getFace("tfont", 86),
            }
        }
    }
    local tappable = InputContainer:new{
        dimen = Geom:new{x = 0, y = 0, w = size, h = size},
        object,
    }
    tappable.ges_events = {
        Tap = {GestureRange:new{ges = "tap", range = tappable.dimen}}
    }
    tappable.onTap = function()
        return self:onCountObjectTap(index)
    end
    return tappable
end

function GameScreen:buildCountRow(first, last)
    local row = HorizontalGroup:new{align = "center"}
    for index = first, last do
        table.insert(row, self:makeCountObject(index))
        if index < last then
            table.insert(row, self:makeBlankSpacer(24, 130))
        end
    end
    return row
end

function GameScreen:renderTapCountRound()
    if not self.current_round or not self.tap_count then
        return
    end
    local count = self.tap_count.count
    local first_row_end = math.min(4, count)
    local group = VerticalGroup:new{
        align = "center",
        CenterContainer:new{
            dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 150},
            TextWidget:new{text = self.current_round.prompt, face = Font:getFace("tfont", 58)},
        },
        self:buildCountRow(1, first_row_end),
    }
    if count > first_row_end then
        table.insert(group, self:makeBlankSpacer(self.dimen.w - EDGE_MARGIN * 2, 24))
        table.insert(group, self:buildCountRow(first_row_end + 1, count))
    end
    table.insert(group, CenterContainer:new{
        dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 90},
        TextWidget:new{
            text = tostring(self.tap_count.tapped_total) .. " / " .. tostring(count),
            face = Font:getFace("tfont", 42),
        }
    })
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        bordersize = 0,
        padding = 0,
        background = Blitbuffer.COLOR_WHITE,
        CenterContainer:new{dimen = self.dimen, group},
    }
    UIManager:setDirty(self, "full")
end

function GameScreen:onCountObjectTap(index)
    if not self.tap_count or self.tap_count.tapped[index] then
        return true
    end
    self.tap_count.tapped[index] = true
    self.tap_count.tapped_total = self.tap_count.tapped_total + 1
    if self.tap_count.tapped_total == self.tap_count.count then
        self:recordRoundResult(true)
        if self:recordCorrectAnswer() then
            self:showRewardFeedback()
        else
            self:showCorrectFeedback()
        end
    elseif self.dimen then
        self:renderTapCountRound()
    end
    return true
end

function GameScreen:renderStoryPage()
    local round = self.current_round
    if not round or not self.story_page then
        return
    end
    local next_button = self:renderParentButton(">", function()
        self:onStoryContinue()
    end)
    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 160},
                TextWidget:new{
                    text = "Story " .. tostring(self.story_page) .. "/" .. tostring(#round.pages),
                    face = Font:getFace("tfont", 34),
                }
            },
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE_MARGIN * 2, h = 420},
                TextWidget:new{
                    text = round.pages[self.story_page],
                    face = Font:getFace("tfont", 58),
                }
            },
            next_button,
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

function GameScreen:onStoryContinue()
    if not self.current_round or self.current_round.kind ~= "story" then
        return true
    end
    if self.story_page < #self.current_round.pages then
        self.story_page = self.story_page + 1
        self:renderStoryPage()
        return true
    end

    self.story_page = nil
    self.current_choices = self:buildChoices(self.current_round)
    self:shuffle(self.current_choices)
    self:renderRound()
    return true
end

function GameScreen:startSpellingRound(round)
    self.current_choices = nil
    self.spelling = {
        word = round.word,
        letters = self:getScrambledLetters(round.word),
        filled = {},
        used = {},
        feedback = nil,
        hint_count = self:getSpellingHintCount(round),
    }
    self:applySpellingHints()
    self:renderSpellingRound()
end

function GameScreen:getSpellingHintCount(round)
    local word_length = #(round.word or "")
    if word_length < 2 or self.difficulty == "hard" then
        return 0
    end
    if self.difficulty == "easy" then
        return math.min(word_length > 3 and 2 or 1, word_length - 1)
    end
    if round.level == 1 then
        return 1
    end
    return 0
end

function GameScreen:applySpellingHints()
    if not self.spelling then
        return
    end

    for position = 1, self.spelling.hint_count or 0 do
        local target = self.spelling.word:sub(position, position)
        for index, letter in ipairs(self.spelling.letters) do
            if not self.spelling.used[index] and letter == target then
                table.insert(self.spelling.filled, target)
                self.spelling.used[index] = true
                break
            end
        end
    end
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
    self:applySpellingHints()
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
    if round.kind == "sentence_build" then
        self:startSentenceBuildRound(round)
        return
    end
    if round.kind == "story" then
        self:startStoryRound(round)
        return
    end
    if round.kind == "tap_count" then
        self:startTapCountRound(round)
        return
    end

    self.spelling = nil
    self.sentence_build = nil
    self.story_page = nil
    self.tap_count = nil

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
        local tile_style = self:getTileStyle(layout, i)
        local image_height = layout.tile_h - (tile_style.padding + tile_style.border) * 2
        local tile_content
        if choice.text then
            tile_content = CenterContainer:new{
                dimen = Geom:new{
                    w = layout.tile_w - (tile_style.padding + tile_style.border) * 2,
                    h = image_height,
                },
                TextWidget:new{
                    text = choice.text,
                    face = Font:getFace("tfont", TEXT_CHOICE_FONT),
                }
            }
        else
            local img_path = self.assets_dir .. choice.path
            logger.warn("ToddlerLearn: loading image", img_path)
            tile_content = ImageWidget:new{
                file = img_path,
                width = layout.tile_w - (tile_style.padding + tile_style.border) * 2,
                height = image_height,
                scale_factor = 0
            }
        end

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
        self:recordRoundResult(true)
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
        self:recordRoundResult(false)
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
        self:recordRoundResult(true)
        if self:recordCorrectAnswer() then
            self:showRewardFeedback()
        else
            self:showCorrectFeedback()
        end
        return true
    end

    self.spelling.feedback = "Try again"
    self:recordRoundResult(false)
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

function GameScreen:onSentenceWordTap(word_index)
    if not self.sentence_build or self.sentence_build.used[word_index] then
        return true
    end
    table.insert(self.sentence_build.filled, self.sentence_build.choices[word_index])
    self.sentence_build.used[word_index] = true
    if #self.sentence_build.filled < #self.sentence_build.answer_words then
        if self.dimen then
            self:renderSentenceBuildRound()
        end
        return true
    end

    local expected = table.concat(self.sentence_build.answer_words, " ")
    if self:getSentenceAnswer() == expected then
        self:recordRoundResult(true)
        if self:recordCorrectAnswer() then
            self:showRewardFeedback()
        else
            self:showCorrectFeedback()
        end
    else
        self.sentence_build.feedback = "Try again"
        self:recordRoundResult(false)
        if self.dimen then
            self:renderSentenceBuildRound()
        end
    end
    return true
end

function GameScreen:recordCorrectAnswer()
    self.correct_count = (self.correct_count or 0) + 1
    self.session_completed = (self.session_completed or 0) + 1
    return self.correct_count % REWARD_EVERY == 0
end

function GameScreen:isSessionComplete()
    return self.session_length
        and (self.session_completed or 0) >= self.session_length
end

function GameScreen:advanceAfterFeedback()
    if self:isSessionComplete() then
        self:renderSessionComplete()
    else
        self:loadRound()
    end
end

function GameScreen:renderSessionComplete()
    self.session_finished = true
    if not self.dimen then
        return
    end

    self[1] = FrameContainer:new{
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
                    text = "All done!",
                    face = Font:getFace("tfont", 86),
                },
                TextWidget:new{
                    text = "* * * * *",
                    face = Font:getFace("tfont", 64),
                },
                TextWidget:new{
                    text = tostring(self.session_completed) .. " rounds",
                    face = Font:getFace("tfont", 42),
                }
            }
        }
    }
    UIManager:setDirty(self, "full")
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
        self:advanceAfterFeedback()
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
        self:advanceAfterFeedback()
    end)
end

function GameScreen:showRewardFeedback()
    if not self.dimen then
        self:advanceAfterFeedback()
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
        self:advanceAfterFeedback()
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
