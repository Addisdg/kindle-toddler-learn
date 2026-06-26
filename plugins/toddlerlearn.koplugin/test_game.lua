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

        it("every round has at least 2 distractors", function()
            for i, round in ipairs(Content) do
                assert.is_table(round.distractors,
                    "round " .. i .. " missing distractors table")
                assert.is_true(#round.distractors >= 2,
                    "round " .. i .. " needs at least 2 distractors")
            end
        end)

        it("answer is not duplicated in distractors", function()
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
                shapes = true,
                vehicles = true,
                body = true,
                household = true,
                emotions = true,
            }
            assert.is_table(Content.categories)
            assert.is_table(Content.category_order)
            assert.is_true(#Content.category_order >= 10)
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

    end)

end)
