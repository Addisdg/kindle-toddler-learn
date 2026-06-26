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

    end)

end)
