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
                getWidth  = function() return 1072 end,
                getHeight = function() return 1448 end,
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

        it("every picture round has an answer image path", function()
            for i, round in ipairs(Content) do
                if round.kind ~= "text_choice" and round.kind ~= "sentence_build"
                    and round.kind ~= "tap_count"
                then
                    assert.is_string(round.answer,
                        "round " .. i .. " missing answer")
                    assert.is_true(round.answer:match("%.png$") ~= nil,
                        "round " .. i .. " answer is not a .png: " .. round.answer)
                end
            end
        end)

        it("every multiple-choice round has at least 2 distractors", function()
            for i, round in ipairs(Content) do
                if round.kind ~= "spelling"
                    and round.kind ~= "text_choice"
                    and round.kind ~= "sentence_build"
                    and round.kind ~= "tap_count"
                then
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
                quantities = true,
                tenframes = true,
                number_bonds = true,
                tap_counting = true,
                letters = true,
                letter_pairs = true,
                letter_words = true,
                beginning_sounds = true,
                ending_sounds = true,
                reading_words = true,
                cvc_words = true,
                word_blending = true,
                word_families = true,
                spelling_words = true,
                sentence_building = true,
                sentences = true,
                mini_stories = true,
                shapes = true,
                vehicles = true,
                body = true,
                household = true,
                emotions = true,
                counting = true,
                early_math = true,
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

        it("has reading rounds with bare word prompts and no picture captions", function()
            local rounds = Content.getRounds("reading_words")
            assert.are_equal(#Content.word_bank, #rounds)
            for i, round in ipairs(rounds) do
                assert.are_equal(Content.word_bank[i].word, round.prompt)
                assert.is_nil(round.show_labels)
                assert.is_nil(round.labels)
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

        it("matches every uppercase letter to a lowercase text choice", function()
            local rounds = Content.getRounds("letter_pairs")
            assert.are_equal(26, #rounds)
            for _, round in ipairs(rounds) do
                assert.are_equal("text_choice", round.kind)
                assert.are_equal(round.prompt:lower(), round.answer_text)
                assert.are_equal(2, #round.distractors_text)
            end
        end)

        it("matches beginning letters to pictures with that sound", function()
            local rounds = Content.getRounds("beginning_sounds")
            assert.is_true(#rounds >= 10)
            for _, round in ipairs(rounds) do
                assert.are_equal(round.prompt:lower(), round.sound_word:sub(1, 1))
                assert.are_equal(1, #round.prompt)
            end
        end)

        it("matches ending letters to pictures with that sound", function()
            local rounds = Content.getRounds("ending_sounds")
            assert.is_true(#rounds >= 8)
            for _, round in ipairs(rounds) do
                assert.are_equal(round.prompt:lower(), round.sound_word:sub(-1))
                assert.are_equal(1, #round.prompt)
            end
        end)

        it("orders leveled short-word spelling from simple to harder words", function()
            local rounds = Content.getRounds("cvc_words")
            assert.is_true(#rounds >= 8)
            local previous_level = 1
            for _, round in ipairs(rounds) do
                assert.are_equal("spelling", round.kind)
                assert.is_true(round.level >= previous_level)
                if round.level == 1 then
                    assert.are_equal(3, #round.word)
                end
                previous_level = round.level
            end
        end)

        it("contrasts words by common ending families", function()
            local rounds = Content.getRounds("word_families")
            assert.are_equal(12, #rounds)
            for _, round in ipairs(rounds) do
                assert.are_equal(round.family, round.answer_text:sub(-#round.family))
                for _, distractor in ipairs(round.distractors_text) do
                    assert.are_not_equal(round.family, distractor:sub(-#round.family))
                end
            end
        end)

        it("blends onset and rime into complete words", function()
            local rounds = Content.getRounds("word_blending")
            assert.are_equal(12, #rounds)
            for _, round in ipairs(rounds) do
                assert.are_equal(round.onset .. round.rime, round.answer_text)
                assert.are_equal(round.onset .. " + " .. round.rime, round.prompt)
            end
        end)

        it("uses short complete sentences for picture comprehension", function()
            local rounds = Content.getRounds("sentences")
            assert.is_true(#rounds >= 10)
            for _, round in ipairs(rounds) do
                local _, spaces = round.prompt:gsub(" ", "")
                assert.is_true(spaces >= 2)
                assert.are_equal(".", round.prompt:sub(-1))
                assert.is_true(#round.prompt <= 24)
            end
        end)

        it("provides ordered words for sentence-building rounds", function()
            local rounds = Content.getRounds("sentence_building")
            assert.is_true(#rounds >= 8)
            for _, round in ipairs(rounds) do
                assert.are_equal("sentence_build", round.kind)
                assert.are_equal(round.sentence, table.concat(round.words, " "))
            end
        end)

        it("provides decodable mini-stories followed by picture questions", function()
            local rounds = Content.getRounds("mini_stories")
            assert.is_true(#rounds >= 4)
            for _, round in ipairs(rounds) do
                assert.are_equal("story", round.kind)
                assert.is_true(#round.pages >= 3 and #round.pages <= 5)
                assert.is_string(round.answer)
                assert.is_true(#round.distractors >= 2)
            end
        end)

        it("matches numerals and dot quantities from one through ten", function()
            assert.are_equal(10, #Content.getRounds("numbers"))
            assert.are_equal(10, #Content.getRounds("counting"))
            local quantities = Content.getRounds("quantities")
            assert.are_equal(10, #quantities)
            for number, round in ipairs(quantities) do
                assert.are_equal(tostring(number), round.prompt)
                assert.are_equal("counting/" .. tostring(number) .. ".png", round.answer)
            end
        end)

        it("represents one through ten with fixed ten frames", function()
            local rounds = Content.getRounds("tenframes")
            assert.are_equal(10, #rounds)
            for number, round in ipairs(rounds) do
                assert.are_equal(tostring(number), round.prompt)
                assert.are_equal("tenframes/" .. tostring(number) .. ".png", round.answer)
            end
        end)

        it("uses ten frames to complete number bonds within ten", function()
            local rounds = Content.getRounds("number_bonds")
            assert.are_equal(10, #rounds)
            for _, round in ipairs(rounds) do
                assert.are_equal(round.bond_total, round.bond_part + round.missing_part)
                assert.is_true(round.bond_total <= 10)
                assert.are_equal(
                    "tenframes/" .. tostring(round.missing_part) .. ".png",
                    round.answer
                )
            end
        end)

        it("provides distinct objects for tap-to-count rounds", function()
            local rounds = Content.getRounds("tap_counting")
            assert.are_equal(8, #rounds)
            for count, round in ipairs(rounds) do
                assert.are_equal("tap_count", round.kind)
                assert.are_equal(count, round.count)
            end
        end)

        it("covers all foundational early maths skills", function()
            local expected = {
                compare = true,
                size = true,
                order = true,
                missing = true,
                arithmetic = true,
                shape_pattern = true,
            }
            local seen = {}
            local rounds = Content.getRounds("early_math")
            assert.is_true(#rounds >= 24)
            for _, round in ipairs(rounds) do
                seen[round.math_skill] = true
                if round.equation_result then
                    assert.are_equal(
                        "counting/" .. tostring(round.equation_result) .. ".png",
                        round.answer
                    )
                end
            end
            for skill in pairs(expected) do
                assert.is_true(seen[skill], "missing maths skill: " .. skill)
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

        it("defines curriculum metadata and valid prerequisites for every round", function()
            for _, category in ipairs(Content.category_order) do
                local category_data = Content.categories[category]
                assert.is_string(category_data.domain)
                assert.is_string(category_data.skill)
                assert.is_number(category_data.level)
                assert.is_table(category_data.prerequisites)
                assert.is_boolean(category_data.adult_guided)
                for _, round in ipairs(category_data.rounds) do
                    assert.are_equal(category_data.domain, round.domain)
                    assert.is_string(round.skill)
                    assert.is_number(round.curriculum_level)
                    assert.is_boolean(round.adult_guided)
                end
            end
            assert.are_same({
                "letter_pairs", "beginning_sounds", "ending_sounds",
                "cvc_words", "word_blending", "word_families",
                "sentence_building", "sentences", "mini_stories",
            }, Content.getGuidedCategories("reading"))
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

        it("requires the parent code before exiting gameplay", function()
            local gs = setmetatable({}, {__index = GameScreen})

            assert.is_false(gs:verifyExitCode("0000"))
            assert.is_false(gs:verifyExitCode("123"))
            assert.is_true(gs:verifyExitCode("1234"))
        end)

        it("labels parent menu choices clearly", function()
            local gs = setmetatable({}, { __index = GameScreen })

            assert.are_equal("Mixed Review", gs:getCategoryLabel("mixed"))
            assert.are_equal("Easy: 2 choices", gs:getDifficultyLabel("easy"))
            assert.are_equal("Hard: 4 choices", gs:getDifficultyLabel("hard"))
        end)

        it("summarizes category mastery and practice needs", function()
            local rounds = Content.getRounds("animals")
            local gs = setmetatable({progress = {}}, {__index = GameScreen})
            gs.progress[gs:getRoundKey(rounds[1])] = {correct = 3, wrong = 1}
            gs.progress[gs:getRoundKey(rounds[2])] = {correct = 1, wrong = 3}

            local summary = gs:getProgressSummary("animals")
            assert.are_equal(4, summary.correct)
            assert.are_equal(4, summary.wrong)
            assert.are_equal(8, summary.attempts)
            assert.are_equal(1, summary.mastered)
            assert.are_equal(1, summary.needs_practice)
            assert.are_equal(#rounds, summary.total)
        end)

        it("cycles dashboard categories and resets saved progress", function()
            local saved
            local gs = setmetatable({
                selected_progress_category = Content.category_order[1],
                progress = {sample = {correct = 2, wrong = 0}},
                saveProgress = function(self) saved = self.progress end,
            }, {__index = GameScreen})

            assert.are_equal(Content.category_order[2], gs:cycleProgressCategory())
            gs:resetProgress()
            assert.are_equal(0, #saved)
            assert.is_nil(next(gs.progress))
        end)

        it("cycles three clearly labelled child profiles", function()
            local gs = setmetatable({selected_profile_id = "child1"}, {__index = GameScreen})

            assert.are_equal("Child 1", gs:getProfileLabel("child1"))
            assert.are_equal("child2", gs:cycleProfile())
            assert.are_equal("child3", gs:cycleProfile())
            assert.are_equal("child1", gs:cycleProfile())
        end)

        it("loads separate progress for each child and preserves legacy Child 1 data", function()
            local legacy = {old_round = {correct = 2, wrong = 0}}
            local child_two = {new_round = {correct = 1, wrong = 1}}
            local store = {toddlerlearn_progress = legacy, toddlerlearn_progress_child2 = child_two}
            local settings = {
                readSetting = function(_, key, default)
                    if store[key] == nil then return default end
                    return store[key]
                end,
            }
            local gs = setmetatable({settings = settings, profile_id = "child1"}, {__index = GameScreen})

            local migrated_legacy = gs:loadProgress()
            assert.are_equal(2, migrated_legacy.old_round.independent_correct)
            assert.are_equal(2, migrated_legacy.old_round.attempts)
            gs.profile_id = "child2"
            local migrated_child_two = gs:loadProgress()
            assert.are_equal(1, migrated_child_two.new_round.independent_correct)
            assert.are_equal(2, migrated_child_two.new_round.attempts)
            gs.profile_id = "child3"
            assert.is_nil(next(gs:loadProgress()))
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

        it("counts each tapped object once and completes on the last object", function()
            local completed = 0
            local gs = setmetatable({
                current_round = {category = "tap_counting", kind = "tap_count", count = 3},
                tap_count = {count = 3, tapped = {}, tapped_total = 0},
                progress = {},
                saveProgress = function() end,
                recordCorrectAnswer = function() completed = completed + 1 return false end,
                showCorrectFeedback = function() end,
            }, {__index = GameScreen})

            gs:onCountObjectTap(1)
            gs:onCountObjectTap(1)
            gs:onCountObjectTap(2)
            assert.are_equal(2, gs.tap_count.tapped_total)
            assert.are_equal(0, completed)
            gs:onCountObjectTap(3)
            assert.are_equal(3, gs.tap_count.tapped_total)
            assert.are_equal(1, completed)
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

        it("starts guided learning with letter pairs", function()
            local gs = setmetatable({progress = {}}, {__index = GameScreen})

            assert.are_equal("letter_pairs", gs:getGuidedCategory())
        end)

        it("unlocks beginning sounds after letter-pair mastery", function()
            local gs = setmetatable({progress = {}}, {__index = GameScreen})
            local rounds = Content.getRounds("letter_pairs")
            local required = math.ceil(#rounds * 0.7)
            for i = 1, required do
                gs.progress[gs:getRoundKey(rounds[i])] = {correct = 2, wrong = 0}
            end

            assert.is_true(gs:getCategoryMastery("letter_pairs") >= 0.7)
            assert.are_equal("beginning_sounds", gs:getGuidedCategory())
        end)

        it("builds guided sessions from the current learning stage", function()
            local gs = setmetatable({
                active_category = "guided",
                progress = {},
                shuffle = function() end,
            }, {__index = GameScreen})

            gs:resetRoundOrder()

            assert.are_equal("letter_pairs", gs.guided_category)
            assert.are_equal(#Content.getRounds("letter_pairs"), #gs.rounds)
        end)

        it("repeats difficult rounds in adaptive review", function()
            local rounds = Content.getRounds("animals")
            local gs = setmetatable({progress = {}}, {__index = GameScreen})
            local key = gs:getRoundKey(rounds[1])
            gs.progress[key] = {correct = 1, wrong = 4}

            local order = gs:buildAdaptiveRoundOrder(rounds)
            local first_count = 0
            for _, index in ipairs(order) do
                if index == 1 then
                    first_count = first_count + 1
                end
            end

            assert.are_equal(3, first_count)
            assert.are_equal(#rounds + 2, #order)
        end)

        it("persists correct and wrong results by stable round key", function()
            local saved
            local settings = {
                saveSetting = function(_, key, value)
                    assert.are_equal("toddlerlearn_progress_child1", key)
                    saved = value
                end,
                flush = function() end,
            }
            local round = Content.getRounds("animals")[1]
            local gs = setmetatable({
                current_round = round,
                progress = {},
                settings = settings,
                clock = function() return 42 end,
            }, {__index = GameScreen})

            gs:recordRoundResult(false)
            gs:recordRoundResult(true)

            assert.are_equal(2, saved.version)
            local result = saved.rounds[gs:getRoundKey(round)]
            assert.are_equal(1, result.correct)
            assert.are_equal(1, result.wrong)
            assert.are_equal(1, result.independent_correct)
            assert.are_equal(0, result.hinted_correct)
            assert.are_equal(2, result.attempts)
            assert.are_equal(42, result.last_practiced)
        end)

        it("does not count hinted answers as independent mastery", function()
            local round = Content.getRounds("cvc_words")[1]
            local gs = setmetatable({
                current_round = round,
                progress = {},
                clock = function() return 12345 end,
                saveProgress = function() end,
            }, {__index = GameScreen})

            gs:recordRoundResult(true, true)
            gs:recordRoundResult(true, true)
            local result = gs.progress[gs:getRoundKey(round)]
            assert.are_equal(2, result.hinted_correct)
            assert.are_equal(0, result.independent_correct)
            assert.are_equal(12345, result.last_practiced)
            assert.is_false(gs:isRoundMastered(round))

            gs:recordRoundResult(true, false)
            gs:recordRoundResult(true, false)
            assert.is_true(gs:isRoundMastered(round))
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

        it("keeps reading picture choices caption free", function()
            local gs = setmetatable({
                difficulty = "normal",
                rounds = Content.getRounds("reading_words"),
            }, { __index = GameScreen })

            local choices = gs:buildChoices(gs.rounds[1])

            for _, choice in ipairs(choices) do
                assert.is_nil(choice.label)
            end
        end)

        it("builds lowercase text choices for uppercase prompts", function()
            local rounds = Content.getRounds("letter_pairs")
            local gs = setmetatable({
                difficulty = "normal",
                rounds = rounds,
            }, { __index = GameScreen })

            local choices = gs:buildChoices(rounds[1])

            assert.are_equal(3, #choices)
            assert.are_equal("a", choices[1].text)
            assert.is_true(choices[1].correct)
            assert.is_nil(choices[1].path)
        end)

        it("builds hard-mode choices for mixed early maths formats", function()
            local rounds = Content.getRounds("early_math")
            local gs = setmetatable({
                difficulty = "hard",
                rounds = rounds,
            }, {__index = GameScreen})
            local picture_round
            local text_round
            for _, round in ipairs(rounds) do
                if round.kind == "text_choice" and not text_round then
                    text_round = round
                elseif round.kind ~= "text_choice" and not picture_round then
                    picture_round = round
                end
            end

            local picture_choices = gs:buildChoices(picture_round)
            local text_choices = gs:buildChoices(text_round)

            assert.are_equal(4, #picture_choices)
            assert.are_equal(4, #text_choices)
            for _, choice in ipairs(picture_choices) do
                assert.is_string(choice.path)
            end
            for _, choice in ipairs(text_choices) do
                assert.is_string(choice.text)
            end
        end)

        it("uses large spelling letter boxes and type", function()
            local gs = setmetatable({}, { __index = GameScreen })
            local layout = gs:getSpellingLayout(5)

            assert.is_true(layout.letter_h >= 80)
            assert.is_true(layout.letter_font_size >= 40)

            for _, item in ipairs(Content.word_bank) do
                local word_layout = gs:getSpellingLayout(#item.word)
                local row_width = #item.word * word_layout.letter_w
                    + (#item.word - 1) * word_layout.letter_gap
                assert.is_true(row_width <= word_layout.usable_w,
                    "spelling row is too wide for " .. item.word)
            end
        end)

        it("builds a sentence by tapping scrambled words in order", function()
            local advanced = false
            local round = Content.getRounds("sentence_building")[1]
            local gs = setmetatable({
                current_round = round,
                sentence_build = {
                    answer_words = {"The", "cat", "sleeps"},
                    choices = {"cat", "The", "sleeps"},
                    filled = {},
                    used = {},
                },
                progress = {},
                showCorrectFeedback = function() advanced = true end,
                showRewardFeedback = function() advanced = true end,
            }, {__index = GameScreen})

            gs:onSentenceWordTap(2)
            gs:onSentenceWordTap(1)
            gs:onSentenceWordTap(3)

            assert.are_equal("The cat sleeps", gs:getSentenceAnswer())
            assert.is_true(advanced)
        end)

        it("keeps an incorrect sentence available to reset", function()
            local round = Content.getRounds("sentence_building")[1]
            local gs = setmetatable({
                current_round = round,
                sentence_build = {
                    answer_words = {"The", "cat", "sleeps"},
                    choices = {"cat", "The", "sleeps"},
                    filled = {},
                    used = {},
                },
                progress = {},
            }, {__index = GameScreen})

            gs:onSentenceWordTap(1)
            gs:onSentenceWordTap(2)
            gs:onSentenceWordTap(3)
            assert.are_equal("Try again", gs.sentence_build.feedback)

            gs:resetSentenceAttempt()
            assert.are_equal("", gs:getSentenceAnswer())
        end)

        it("advances through story pages before building the question", function()
            local rendered_pages = 0
            local rendered_question = false
            local round = Content.getRounds("mini_stories")[1]
            local gs = setmetatable({
                current_round = round,
                story_page = 1,
                difficulty = "normal",
                rounds = {round},
                renderStoryPage = function() rendered_pages = rendered_pages + 1 end,
                renderRound = function() rendered_question = true end,
                shuffle = function() end,
            }, {__index = GameScreen})

            gs:onStoryContinue()
            gs:onStoryContinue()
            assert.are_equal(3, gs.story_page)
            assert.are_equal(2, rendered_pages)
            assert.is_false(rendered_question)

            gs:onStoryContinue()
            assert.is_nil(gs.story_page)
            assert.is_true(rendered_question)
            assert.are_equal(3, #gs.current_choices)
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

        it("reduces spelling help as difficulty increases", function()
            local round = {
                kind = "spelling",
                word = "cat",
                answer = "animals/cat.png",
                level = 1,
            }

            local easy = setmetatable({difficulty = "easy"}, {__index = GameScreen})
            local normal = setmetatable({difficulty = "normal"}, {__index = GameScreen})
            local hard = setmetatable({difficulty = "hard"}, {__index = GameScreen})

            assert.are_equal(1, easy:getSpellingHintCount(round))
            assert.are_equal(1, normal:getSpellingHintCount(round))
            assert.are_equal(0, hard:getSpellingHintCount(round))
            round.level = 2
            assert.are_equal(0, normal:getSpellingHintCount(round))
        end)

        it("prefills and preserves spelling hints when an attempt resets", function()
            local gs = setmetatable({
                spelling = {
                    word = "cat",
                    letters = {"t", "c", "a"},
                    filled = {},
                    used = {},
                    hint_count = 1,
                },
            }, {__index = GameScreen})

            gs:applySpellingHints()
            assert.are_equal("c", gs:getSpellingAnswer())
            assert.is_true(gs.spelling.used[2])

            gs:onSpellingLetterTap(3)
            gs:resetSpellingAttempt()

            assert.are_equal("c", gs:getSpellingAnswer())
            assert.is_true(gs.spelling.used[2])
            assert.is_nil(gs.spelling.used[3])
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

        it("keeps an incorrect spelling attempt until the answer boxes are tapped", function()
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
            assert.are_equal("tac", gs:getSpellingAnswer())
            assert.are_equal("Try again", gs.spelling.feedback)

            gs:onSpellingBoxesTap()

            assert.are_equal("", gs:getSpellingAnswer())
            assert.is_nil(gs.spelling.feedback)
        end)

        it("clears a partial spelling attempt when an answer box is tapped", function()
            local gs = setmetatable({
                spelling = {
                    word = "cat",
                    letters = {"c", "a", "t"},
                    filled = {},
                    used = {},
                },
            }, { __index = GameScreen })

            gs:onSpellingLetterTap(1)
            assert.are_equal("c", gs:getSpellingAnswer())
            assert.is_true(gs.spelling.used[1])

            local boxes = gs:buildSpellingBoxes(gs:getSpellingLayout(3))
            assert.is_function(boxes[1].onTap)
            boxes[1].onTap()

            assert.are_equal("", gs:getSpellingAnswer())
            assert.is_nil(gs.spelling.used[1])
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

        it("continues loading rounds without a session limit", function()
            local loaded = 0
            local gs = setmetatable({
                loadRound = function()
                    loaded = loaded + 1
                end,
            }, {__index = GameScreen})

            for _ = 1, 100 do
                gs:recordCorrectAnswer()
                gs:advanceAfterFeedback()
            end

            assert.are_equal(100, loaded)
            assert.are_equal(100, gs.session_completed)
        end)

    end)

end)
