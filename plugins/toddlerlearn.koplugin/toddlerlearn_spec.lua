describe("ToddlerLearn", function()
    local GameScreen
    local Content

    setup(function()
        require("commonrequire")
        disable_plugins()
        load_plugin("toddlerlearn.koplugin")
        Content    = require("content")
        GameScreen = require("gamescreen")
    end)

    describe("content.lua", function()

        it("has at least one round", function()
            assert.is_true(#Content >= 1)
        end)

        it("every round has a prompt string", function()
            for i, round in ipairs(Content) do
                assert.is_string(round.prompt, "round " .. i .. " missing prompt")
                assert.is_true(#round.prompt > 0, "round " .. i .. " has empty prompt")
            end
        end)

        it("every picture round has an answer .png path", function()
            for i, round in ipairs(Content) do
                if round.kind ~= "text_choice" then
                    assert.is_string(round.answer, "round " .. i .. " missing answer")
                    assert.is_true(round.answer:match("%.png$") ~= nil,
                        "round " .. i .. " answer is not a .png")
                end
            end
        end)

        it("every multiple-choice round has at least 2 distractors", function()
            for i, round in ipairs(Content) do
                if round.kind ~= "spelling" and round.kind ~= "text_choice" then
                    assert.is_table(round.distractors, "round " .. i .. " missing distractors")
                    assert.is_true(#round.distractors >= 2,
                        "round " .. i .. " needs at least 2 distractors")
                end
            end
        end)

        it("answer not duplicated in distractors", function()
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
                letters = true,
                letter_pairs = true,
                letter_words = true,
                beginning_sounds = true,
                reading_words = true,
                cvc_words = true,
                word_families = true,
                spelling_words = true,
                sentences = true,
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
            local ok, errors = Content.validate("./plugins/toddlerlearn.koplugin/assets/")
            assert.is_true(ok, table.concat(errors, "\n"))
        end)

    end)

    describe("GameScreen.shuffle", function()

        it("keeps all elements", function()
            local gs = { shuffle = GameScreen.shuffle }
            local list = {1, 2, 3, 4, 5}
            local copy = {table.unpack(list)}
            gs:shuffle(list)
            assert.are_equal(#copy, #list)
            table.sort(list)
            table.sort(copy)
            for i = 1, #list do
                assert.are_equal(copy[i], list[i])
            end
        end)

        it("produces different order over many runs", function()
            local gs = { shuffle = GameScreen.shuffle }
            local list = {1, 2, 3, 4, 5, 6, 7, 8}
            local original = table.concat(list, ",")
            local same = 0
            for _ = 1, 20 do
                gs:shuffle(list)
                if table.concat(list, ",") == original then same = same + 1 end
            end
            assert.is_true(same <= 2, "shuffle never reorders")
        end)

    end)

    describe("GameScreen layout", function()

        it("keeps three-choice tiles large enough for toddler taps", function()
            local layout = GameScreen:getLayout(3)
            assert.is_true(layout.tile_w >= math.floor(layout.screen_w * 0.25),
                "three-choice tile width should stay proportional to screen width")
            assert.is_true(layout.tile_h >= layout.tile_w,
                "three-choice tile height should be at least as large as width")
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

        it("cycles session length through 5 10 and 15 rounds", function()
            local gs = setmetatable({selected_session_length = 5}, {__index = GameScreen})

            assert.are_equal(10, gs:cycleSessionLength())
            assert.are_equal(15, gs:cycleSessionLength())
            assert.are_equal(5, gs:cycleSessionLength())
        end)

        it("labels parent menu choices clearly", function()
            local gs = setmetatable({}, { __index = GameScreen })

            assert.are_equal("Mixed Review", gs:getCategoryLabel("mixed"))
            assert.are_equal("Easy: 2 choices", gs:getDifficultyLabel("easy"))
            assert.are_equal("Hard: 4 choices", gs:getDifficultyLabel("hard"))
        end)

    end)

    describe("GameScreen round logic", function()

        local function make_gs()
            local gs = setmetatable({
                round_order = {1, 2, 3},
                round_pos   = 0,
                shuffle     = GameScreen.shuffle,
                onAnswer    = GameScreen.onAnswer,
            }, { __index = GameScreen })
            -- patch loadRound to skip rendering
            gs.loadRound = function(self)
                self.round_pos = self.round_pos + 1
                if self.round_pos > #self.round_order then
                    self.round_pos = 1
                    self:shuffle(self.round_order)
                end
            end
            return gs
        end

        it("correct answer advances round_pos", function()
            local gs = make_gs()
            gs:onAnswer(true)
            assert.are_equal(1, gs.round_pos)
            gs:onAnswer(true)
            assert.are_equal(2, gs.round_pos)
        end)

        it("wrong answer does not advance round_pos", function()
            local gs = make_gs()
            gs.round_pos = 1
            gs:onAnswer(false)
            assert.are_equal(1, gs.round_pos)
        end)

        it("wraps back to round 1 after last round", function()
            local gs = make_gs()
            gs:onAnswer(true)  -- 1
            gs:onAnswer(true)  -- 2
            gs:onAnswer(true)  -- 3
            gs:onAnswer(true)  -- wraps to 1
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
                    assert.are_equal("toddlerlearn_progress", key)
                    saved = value
                end,
                flush = function() end,
            }
            local round = Content.getRounds("animals")[1]
            local gs = setmetatable({
                current_round = round,
                progress = {},
                settings = settings,
            }, {__index = GameScreen})

            gs:recordRoundResult(false)
            gs:recordRoundResult(true)

            local result = saved[gs:getRoundKey(round)]
            assert.are_equal(1, result.correct)
            assert.are_equal(1, result.wrong)
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

        it("finishes after the selected number of completed rounds", function()
            local loaded = false
            local gs = setmetatable({
                session_length = 2,
                session_completed = 1,
                loadRound = function()
                    loaded = true
                end,
            }, {__index = GameScreen})

            gs:recordCorrectAnswer()
            gs:advanceAfterFeedback()

            assert.is_true(gs.session_finished)
            assert.is_false(loaded)
            assert.are_equal(2, gs.session_completed)
        end)

    end)

end)
