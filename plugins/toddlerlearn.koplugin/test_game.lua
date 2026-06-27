-- test_game.lua
-- Run with: cd koreader && ./kodev test plugins/toddlerlearn.koplugin/test_game.lua

describe("ToddlerLearn", function()

    -- ----------------------------------------------------------------
    -- Minimal stubs so game logic runs without a real KOReader UI
    -- ----------------------------------------------------------------
    local function stub_modules()
        -- Stub Screen
        package.loaded["device"] = {
            screen = {
                getWidth  = function() return 540 end,
                getHeight = function() return 720 end,
            }
        }
        -- Stub UIManager (we don't want real rendering)
        package.loaded["ui/uimanager"] = {
            setDirty = function() end,
            close    = function() end,
            show     = function() end,
        }
        -- Stub Font
        package.loaded["ui/font"] = {
            getFace = function(name, size) return { name=name, size=size } end,
        }
        -- Stub Blitbuffer
        package.loaded["ffi/blitbuffer"] = { COLOR_WHITE = 0xFFFF }
        -- Stub logger
        package.loaded["logger"] = {
            warn = function(...) end,
            dbg  = function(...) end,
        }
        -- Stub gettext
        package.loaded["gettext"] = setmetatable({}, {
            __call = function(_, s) return s end
        })
        -- Stub all widget/container requires to return a simple table factory
        local widget_stub = {
            extend = function(self, t)
                t.__index = t
                return setmetatable(t, { __call = function(cls, args)
                    return setmetatable(args or {}, cls)
                end})
            end,
            new = function(self, t) return t end,
        }
        local widget_paths = {
            "ui/widget/container/inputcontainer",
            "ui/widget/container/framecontainer",
            "ui/widget/container/centercontainer",
            "ui/widget/container/widgetcontainer",
            "ui/widget/verticalgroup",
            "ui/widget/horizontalgroup",
            "ui/widget/imagewidget",
            "ui/widget/textwidget",
            "ui/geometry",
            "ui/gesturerange",
        }
        for _, path in ipairs(widget_paths) do
            package.loaded[path] = setmetatable({}, {
                __index = widget_stub,
                __call  = function(_, t) return t or {} end,
            })
        end
    end

    -- ----------------------------------------------------------------
    -- Load game module under test
    -- ----------------------------------------------------------------
    local GameScreen
    local Content

    setup(function()
        stub_modules()
        -- Point package path at our plugin
        package.path = "../plugins/toddlerlearn.koplugin/?.lua;" .. package.path
        Content    = require("content")
        GameScreen = require("gamescreen")
    end)

    -- ----------------------------------------------------------------
    -- Content tests
    -- ----------------------------------------------------------------
    describe("content.lua", function()

        it("has at least one round", function()
            assert.is_true(#Content >= 1)
        end)

        it("every round has a prompt string", function()
            for i, round in ipairs(Content) do
                assert.is_string(round.prompt,
                    "round " .. i .. " missing prompt")
                assert.is_true(#round.prompt > 0,
                    "round " .. i .. " has empty prompt")
            end
        end)

        it("every round has an answer image path", function()
            for i, round in ipairs(Content) do
                assert.is_string(round.answer,
                    "round " .. i .. " missing answer")
                assert.is_true(round.answer:match("%.png$") ~= nil,
                    "round " .. i .. " answer is not a .png: " .. round.answer)
            end
        end)

        it("every multiple-choice round has at least 2 distractors", function()
            for i, round in ipairs(Content) do
                if round.kind ~= "spelling" then
                    assert.is_table(round.distractors,
                        "round " .. i .. " missing distractors table")
                    assert.is_true(#round.distractors >= 2,
                        "round " .. i .. " needs at least 2 distractors")
                end
            end
        end)

        it("answer is not duplicated in distractors", function()
            for i, round in ipairs(Content) do
                for _, d in ipairs(round.distractors or {}) do
                    assert.are_not_equal(round.answer, d,
                        "round " .. i .. ": answer appears in distractors")
                end
            end
        end)

        it("exposes named learning categories", function()
            local expected_categories = {
                animals = true,
                fruit = true,
                numbers = true,
                letters = true,
                letter_words = true,
                reading_words = true,
                spelling_words = true,
                shapes = true,
                vehicles = true,
                body = true,
                household = true,
                emotions = true,
                counting = true,
            }
            assert.is_table(Content.categories)
            assert.is_table(Content.category_order)
            assert.is_true(#Content.category_order >= 13)
            assert.is_nil(Content.categories.colors)
            for _, category in ipairs(Content.category_order) do
                assert.is_true(expected_categories[category],
                    "unexpected or misspelled category " .. category)
                assert.is_table(Content.categories[category],
                    "missing category " .. category)
                assert.is_string(Content.categories[category].label)
                assert.is_true(#Content.categories[category].rounds >= 1,
                    "category has no rounds: " .. category)
            end
        end)

        it("can return category-only round pools", function()
            local animals = Content.getRounds("animals")
            assert.is_true(#animals >= 1)
            for _, round in ipairs(animals) do
                assert.are_equal("animals", round.category)
            end
            assert.are_equal(#Content, #Content.getRounds("mixed"))
        end)

        it("has reading rounds with visible word labels", function()
            local rounds = Content.getRounds("reading_words")
            assert.are_equal(#Content.word_bank, #rounds)
            for _, round in ipairs(rounds) do
                assert.is_true(round.show_labels)
                assert.is_table(round.labels)
                assert.is_string(round.labels[round.answer])
                for _, distractor in ipairs(round.distractors) do
                    assert.is_string(round.labels[distractor])
                end
            end
        end)

        it("has spelling rounds for the picture word bank", function()
            local rounds = Content.getRounds("spelling_words")
            assert.are_equal(#Content.word_bank, #rounds)
            for _, round in ipairs(rounds) do
                assert.are_equal("spelling", round.kind)
                assert.is_string(round.word)
                assert.is_true(round.word:match("^[a-z]+$") ~= nil)
                assert.is_nil(round.distractors)
            end
        end)

        it("at least doubles the original MVP content", function()
            assert.is_true(#Content >= 150, "expected at least twice the original content pool")
            assert.are_equal(26, #Content.getRounds("letters"))
        end)

        it("passes the content quality checklist", function()
            local ok, errors = Content.validate("plugins/toddlerlearn.koplugin/assets/")
            assert.is_true(ok, table.concat(errors, "\n"))
        end)

    end)

    -- ----------------------------------------------------------------
    -- Game logic tests
    -- ----------------------------------------------------------------
    describe("GameScreen shuffle", function()

        it("shuffle keeps all elements", function()
            local gs = { shuffle = GameScreen.shuffle }
            local list = {1, 2, 3, 4, 5}
            local original = {table.unpack(list)}
            gs:shuffle(list)
            assert.are_equal(#original, #list)
            table.sort(list)
            table.sort(original)
            for i = 1, #list do
                assert.are_equal(original[i], list[i])
            end
        end)

        it("shuffle produces different order over many runs", function()
            local gs = { shuffle = GameScreen.shuffle }
            local list = {1, 2, 3, 4, 5, 6, 7, 8}
            local original_str = table.concat(list, ",")
            local same_count = 0
            for _ = 1, 20 do
                gs:shuffle(list)
                if table.concat(list, ",") == original_str then
                    same_count = same_count + 1
                end
            end
            -- Allow up to 2 coincidental matches in 20 runs
            assert.is_true(same_count <= 2,
                "shuffle never reorders — possible bug")
        end)

    end)

    describe("GameScreen layout", function()

        it("keeps three-choice tiles large enough for toddler taps", function()
            local layout = GameScreen:getLayout(3)
            assert.is_true(layout.tile_w >= 145,
                "three-choice tile width should stay large in the stub screen")
            assert.is_true(layout.tile_h >= 145,
                "three-choice tile height should stay large in the stub screen")
            assert.are_equal(150, layout.prompt_h)
        end)

        it("emphasizes the tapped tile during feedback", function()
            local gs = setmetatable({
                feedback = {
                    kind = "wrong",
                    choice_index = 2,
                },
            }, { __index = GameScreen })
            local layout = GameScreen:getLayout(3)
            local normal = gs:getTileStyle(layout, 1)
            local selected = gs:getTileStyle(layout, 2)

            assert.is_false(normal.selected)
            assert.is_true(selected.selected)
            assert.is_true(selected.border > normal.border)
            assert.is_true(selected.padding < normal.padding)
        end)

    end)

    describe("GameScreen parent setup", function()

        it("cycles through mixed and content categories", function()
            local gs = setmetatable({
                selected_category = "mixed",
            }, { __index = GameScreen })

            local first = gs:cycleCategory()

            assert.are_equal(Content.category_order[1], first)
        end)

        it("cycles difficulty from normal to hard to easy", function()
            local gs = setmetatable({
                selected_difficulty = "normal",
            }, { __index = GameScreen })

            assert.are_equal("hard", gs:cycleDifficulty())
            assert.are_equal("easy", gs:cycleDifficulty())
            assert.are_equal("normal", gs:cycleDifficulty())
        end)

        it("labels parent menu choices clearly", function()
            local gs = setmetatable({}, { __index = GameScreen })

            assert.are_equal("Mixed Review", gs:getCategoryLabel("mixed"))
            assert.are_equal("Easy: 2 choices", gs:getDifficultyLabel("easy"))
            assert.are_equal("Hard: 4 choices", gs:getDifficultyLabel("hard"))
        end)

    end)

    describe("GameScreen round progression", function()

        it("round_pos advances on correct answer", function()
            -- Minimal fake game screen
            local gs = setmetatable({
                round_order = {1, 2, 3},
                round_pos   = 0,
                assets_dir  = "/fake/",
                shuffle     = GameScreen.shuffle,
                loadRound   = GameScreen.loadRound,
                onAnswer    = GameScreen.onAnswer,
            }, { __index = GameScreen })

            -- Patch loadRound to just increment without rendering
            gs.loadRound = function(self)
                self.round_pos = self.round_pos + 1
                if self.round_pos > #self.round_order then
                    self.round_pos = 1
                end
            end

            gs:onAnswer(true)   -- correct tap
            assert.are_equal(1, gs.round_pos)

            gs:onAnswer(true)
            assert.are_equal(2, gs.round_pos)
        end)

        it("wrong answer does not advance round", function()
            local gs = setmetatable({
                round_order = {1, 2, 3},
                round_pos   = 1,
                shuffle     = GameScreen.shuffle,
                onAnswer    = GameScreen.onAnswer,
            }, { __index = GameScreen })

            gs:onAnswer(false)  -- wrong tap
            assert.are_equal(1, gs.round_pos)  -- still on round 1
        end)

        it("wraps around after last round", function()
            local gs = setmetatable({
                round_order = {1, 2},
                round_pos   = 0,
                shuffle     = GameScreen.shuffle,
                loadRound   = GameScreen.loadRound,
                onAnswer    = GameScreen.onAnswer,
            }, { __index = GameScreen })

            gs.loadRound = function(self)
                self.round_pos = self.round_pos + 1
                if self.round_pos > #self.round_order then
                    self.round_pos = 1
                    self:shuffle(self.round_order)
                end
            end

            gs:onAnswer(true)  -- round 1
            gs:onAnswer(true)  -- round 2
            gs:onAnswer(true)  -- should wrap to round 1
            assert.are_equal(1, gs.round_pos)
        end)

        it("can build round order for a selected category", function()
            local gs = setmetatable({
                active_category = "animals",
                shuffle = GameScreen.shuffle,
            }, { __index = GameScreen })

            gs:resetRoundOrder()

            assert.are_equal(#Content.getRounds("animals"), #gs.round_order)
            assert.are_equal("animals", gs.rounds[gs.round_order[1]].category)
        end)

        it("builds fewer choices on easy difficulty", function()
            local gs = setmetatable({
                difficulty = "easy",
                rounds = Content.getRounds("animals"),
            }, { __index = GameScreen })

            local choices = gs:buildChoices(gs.rounds[1])

            assert.are_equal(2, #choices)
        end)

        it("builds the default three choices on normal difficulty", function()
            local gs = setmetatable({
                difficulty = "normal",
                rounds = Content.getRounds("animals"),
            }, { __index = GameScreen })

            local choices = gs:buildChoices(gs.rounds[1])

            assert.are_equal(3, #choices)
        end)

        it("derives a fourth same-category choice on hard difficulty", function()
            local gs = setmetatable({
                difficulty = "hard",
                rounds = Content.getRounds("animals"),
            }, { __index = GameScreen })

            local choices = gs:buildChoices(gs.rounds[1])

            assert.are_equal(4, #choices)
            for _, choice in ipairs(choices) do
                assert.is_true(choice.path:match("^animals/") ~= nil)
            end
        end)

        it("carries word labels into reading choices", function()
            local gs = setmetatable({
                difficulty = "normal",
                rounds = Content.getRounds("reading_words"),
            }, { __index = GameScreen })

            local choices = gs:buildChoices(gs.rounds[1])

            assert.are_equal("cat", choices[1].label)
            assert.is_true(#choices[2].label > 0)
            assert.is_true(#choices[3].label > 0)
        end)

        it("scrambles spelling letters while keeping the same letters", function()
            local gs = setmetatable({
                shuffle = function(_, list)
                    list[1], list[#list] = list[#list], list[1]
                end,
            }, { __index = GameScreen })

            local letters = gs:getScrambledLetters("cat")
            table.sort(letters)

            assert.are_equal("act", table.concat(letters, ""))
        end)

        it("advances after a correctly completed spelling word", function()
            local advanced = false
            local gs = setmetatable({
                current_round = {
                    kind = "spelling",
                    word = "cat",
                    answer = "animals/cat.png",
                },
                spelling = {
                    word = "cat",
                    letters = {"c", "a", "t"},
                    filled = {},
                    used = {},
                },
                recordCorrectAnswer = GameScreen.recordCorrectAnswer,
                showCorrectFeedback = function()
                    advanced = true
                end,
                showRewardFeedback = function()
                    advanced = true
                end,
            }, { __index = GameScreen })

            gs:onSpellingLetterTap(1)
            gs:onSpellingLetterTap(2)
            gs:onSpellingLetterTap(3)

            assert.is_true(advanced)
            assert.are_equal("cat", gs:getSpellingAnswer())
        end)

        it("resets an incorrect spelling attempt without advancing", function()
            local advanced = false
            local gs = setmetatable({
                spelling = {
                    word = "cat",
                    letters = {"t", "a", "c"},
                    filled = {},
                    used = {},
                },
                showCorrectFeedback = function()
                    advanced = true
                end,
                showRewardFeedback = function()
                    advanced = true
                end,
            }, { __index = GameScreen })

            gs:onSpellingLetterTap(1)
            gs:onSpellingLetterTap(2)
            gs:onSpellingLetterTap(3)

            assert.is_false(advanced)
            assert.are_equal("", gs:getSpellingAnswer())
        end)

        it("shows a reward every five correct answers", function()
            local gs = setmetatable({}, { __index = GameScreen })

            assert.is_false(gs:recordCorrectAnswer())
            assert.is_false(gs:recordCorrectAnswer())
            assert.is_false(gs:recordCorrectAnswer())
            assert.is_false(gs:recordCorrectAnswer())
            assert.is_true(gs:recordCorrectAnswer())
            assert.are_equal(5, gs.correct_count)
        end)

    end)

end)
