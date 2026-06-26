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

        it("every round has an answer .png path", function()
            for i, round in ipairs(Content) do
                assert.is_string(round.answer, "round " .. i .. " missing answer")
                assert.is_true(round.answer:match("%.png$") ~= nil,
                    "round " .. i .. " answer is not a .png")
            end
        end)

        it("every round has at least 2 distractors", function()
            for i, round in ipairs(Content) do
                assert.is_table(round.distractors, "round " .. i .. " missing distractors")
                assert.is_true(#round.distractors >= 2,
                    "round " .. i .. " needs at least 2 distractors")
            end
        end)

        it("answer not duplicated in distractors", function()
            for i, round in ipairs(Content) do
                for _, d in ipairs(round.distractors) do
                    assert.are_not_equal(round.answer, d,
                        "round " .. i .. ": answer appears in distractors")
                end
            end
        end)

        it("exposes named learning categories", function()
            local expected_categories = {
                animals = true,
                fruit = true,
                colors = true,
                numbers = true,
                letters = true,
                letter_words = true,
                shapes = true,
                vehicles = true,
                body = true,
                household = true,
                emotions = true,
                counting = true,
            }
            assert.is_table(Content.categories)
            assert.is_table(Content.category_order)
            assert.is_true(#Content.category_order >= 12)
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

    end)

end)
