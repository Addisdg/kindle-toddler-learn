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
local Blitbuffer = require("ffi/blitbuffer")

local PuzzleContent = require("puzzle_content")

local EDGE = 32
local TILE = 150
local GAP = 16

local PuzzleScreen = InputContainer:extend{
    assets_dir = nil,
    profile_id = "child1",
}

function PuzzleScreen:init()
    self.dimen = Geom:new{x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight()}
    self.ges_events = {
        Close = {GestureRange:new{ges = "two_finger_hold", range = self.dimen}},
        ModeChooser = {GestureRange:new{ges = "two_finger_tap", range = self.dimen}},
        SwipeNoop = {GestureRange:new{ges = "swipe", range = self.dimen}},
    }
    self.progress = self:loadProgress()
    self.puzzle_index = self.puzzle_index or 1
    self:loadPuzzle(self.puzzle_index)
end

function PuzzleScreen:getProgressKey()
    return "toddlerlearn_puzzle_progress_" .. (self.profile_id or "child1")
end

function PuzzleScreen:loadProgress()
    local settings = self.settings or rawget(_G, "G_reader_settings")
    if settings and settings.readSetting then
        local saved = settings:readSetting(self:getProgressKey(), {}) or {}
        return saved.rounds or saved
    end
    return {}
end

function PuzzleScreen:saveProgress()
    local settings = self.settings or rawget(_G, "G_reader_settings")
    if not settings or not settings.saveSetting then return end
    settings:saveSetting(self:getProgressKey(), {version = 1, rounds = self.progress or {}})
    if settings.flush then settings:flush() end
end

function PuzzleScreen:shuffle(list)
    for index = #list, 2, -1 do
        local other = math.random(index)
        list[index], list[other] = list[other], list[index]
    end
end

function PuzzleScreen:getSlotCount(puzzle)
    return puzzle.answer_target and 1 or #puzzle.pieces
end

function PuzzleScreen:loadPuzzle(index)
    self.puzzle_index = ((index - 1) % #PuzzleContent.puzzles) + 1
    self.current_puzzle = PuzzleContent.puzzles[self.puzzle_index]
    local choices = {}
    for piece_index, piece in ipairs(self.current_puzzle.pieces) do
        choices[piece_index] = piece
    end
    self:shuffle(choices)
    self.puzzle_state = {
        choices = choices,
        selected = nil,
        used = {},
        slots = {},
        correct = 0,
        wrong = 0,
        solved = false,
        feedback = "Tap a piece, then a box",
    }
    if self.dimen then self:renderPuzzle() end
end

function PuzzleScreen:resetPuzzle()
    self:loadPuzzle(self.puzzle_index)
    return true
end

function PuzzleScreen:selectPiece(index)
    if not self.puzzle_state or self.puzzle_state.used[index] or self.puzzle_state.solved then
        return false
    end
    self.puzzle_state.selected = index
    self.puzzle_state.feedback = "Now tap a box"
    if self.dimen then self:renderPuzzle() end
    return true
end

function PuzzleScreen:isCorrectPlacement(piece, slot)
    if self.current_puzzle.answer_target then
        return slot == 1 and piece.target == self.current_puzzle.answer_target
    end
    return piece.target == slot
end

function PuzzleScreen:placeSelected(slot)
    local state = self.puzzle_state
    if not state or not state.selected or state.slots[slot] or state.solved then
        return false
    end
    local choice_index = state.selected
    local piece = state.choices[choice_index]
    if not self:isCorrectPlacement(piece, slot) then
        state.wrong = state.wrong + 1
        state.feedback = "Try another box"
        state.selected = nil
        self:recordAttempt(false)
        if self.dimen then self:renderPuzzle() end
        return false
    end

    state.slots[slot] = piece
    state.used[choice_index] = true
    state.selected = nil
    state.correct = state.correct + 1
    state.feedback = "Good place"
    if state.correct == self:getSlotCount(self.current_puzzle) then
        state.solved = true
        state.feedback = "Puzzle complete!"
        self:recordAttempt(true)
    end
    if self.dimen then self:renderPuzzle() end
    return true
end

function PuzzleScreen:recordAttempt(solved)
    self.progress = self.progress or {}
    local id = self.current_puzzle.id
    local result = self.progress[id] or {solved = 0, wrong = 0}
    if solved then result.solved = result.solved + 1 else result.wrong = result.wrong + 1 end
    result.last_practiced = (self.clock and self.clock()) or os.time()
    self.progress[id] = result
    self:saveProgress()
end

function PuzzleScreen:makeSpacer(width, height)
    return FrameContainer:new{
        width = width, height = height, bordersize = 0, padding = 0,
        TextWidget:new{text = "", face = Font:getFace("cfont", 8)},
    }
end

function PuzzleScreen:makePieceContent(piece, size, hidden)
    if hidden or not piece then
        return TextWidget:new{text = "", face = Font:getFace("tfont", 40)}
    end
    if piece.image then
        return ImageWidget:new{
            file = self.assets_dir .. piece.image,
            width = size - 18,
            height = size - 18,
            scale_factor = 0,
        }
    end
    return TextWidget:new{text = piece.text, face = Font:getFace("tfont", 38)}
end

function PuzzleScreen:makeTile(piece, size, callback, selected, hidden)
    local button = InputContainer:new{dimen = Geom:new{x = 0, y = 0, w = size, h = size}}
    button.ges_events = {Tap = {GestureRange:new{ges = "tap", range = button.dimen}}}
    button[1] = FrameContainer:new{
        width = size,
        height = size,
        bordersize = selected and 9 or 4,
        padding = selected and 0 or 5,
        CenterContainer:new{
            dimen = Geom:new{w = size - 18, h = size - 18},
            self:makePieceContent(piece, size, hidden),
        },
    }
    button.onTap = function() callback() return true end
    return button
end

function PuzzleScreen:buildGrid(items, callbacks, selected, used)
    local group = VerticalGroup:new{align = "center"}
    local index = 1
    while index <= #items do
        local row = HorizontalGroup:new{align = "center"}
        for column = 1, 2 do
            if index <= #items then
                local item_index = index
                table.insert(row, self:makeTile(
                    items[item_index], TILE,
                    function() callbacks[item_index]() end,
                    selected == item_index,
                    used and used[item_index]
                ))
                index = index + 1
            else
                table.insert(row, self:makeSpacer(TILE, TILE))
            end
            if column == 1 then table.insert(row, self:makeSpacer(GAP, TILE)) end
        end
        table.insert(group, row)
        if index <= #items then table.insert(group, self:makeSpacer(TILE * 2 + GAP, GAP)) end
    end
    return group
end

function PuzzleScreen:makeActionButton(text, callback)
    local width = 220
    local button = InputContainer:new{dimen = Geom:new{x = 0, y = 0, w = width, h = 78}}
    button.ges_events = {Tap = {GestureRange:new{ges = "tap", range = button.dimen}}}
    button[1] = FrameContainer:new{
        width = width, height = 78, bordersize = 4, padding = 5,
        CenterContainer:new{
            dimen = Geom:new{w = width - 18, h = 60},
            TextWidget:new{text = text, face = Font:getFace("tfont", 30)},
        },
    }
    button.onTap = function() callback() return true end
    return button
end

function PuzzleScreen:renderPuzzle()
    local puzzle = self.current_puzzle
    local state = self.puzzle_state
    local slots = {}
    local slot_callbacks = {}
    for slot = 1, self:getSlotCount(puzzle) do
        local slot_index = slot
        slots[slot_index] = state.slots[slot_index]
        slot_callbacks[slot_index] = function() self:placeSelected(slot_index) end
    end
    local choice_callbacks = {}
    for index = 1, #state.choices do
        local choice_index = index
        choice_callbacks[choice_index] = function() self:selectPiece(choice_index) end
    end
    local controls = HorizontalGroup:new{align = "center"}
    table.insert(controls, self:makeActionButton("Modes", function() self:onModeChooser() end))
    table.insert(controls, self:makeSpacer(20, 78))
    table.insert(controls, self:makeActionButton(
        state.solved and "Next" or "Reset",
        state.solved and function() self:loadPuzzle(self.puzzle_index + 1) end
            or function() self:resetPuzzle() end
    ))
    local pattern = puzzle.fixed and (table.concat(puzzle.fixed, "  ") .. "  ?") or " "
    local content = CenterContainer:new{
        dimen = self.dimen,
        VerticalGroup:new{
            align = "center",
            controls,
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE * 2, h = 92},
                TextWidget:new{text = puzzle.prompt, face = Font:getFace("tfont", 46)},
            },
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE * 2, h = puzzle.fixed and 54 or 12},
                TextWidget:new{text = pattern, face = Font:getFace("tfont", 28)},
            },
            self:buildGrid(slots, slot_callbacks),
            self:makeSpacer(TILE * 2 + GAP, 20),
            self:buildGrid(state.choices, choice_callbacks, state.selected, state.used),
            CenterContainer:new{
                dimen = Geom:new{w = self.dimen.w - EDGE * 2, h = 64},
                TextWidget:new{text = state.feedback, face = Font:getFace("tfont", 28)},
            },
        }
    }
    self[1] = FrameContainer:new{
        width = self.dimen.w, height = self.dimen.h, bordersize = 0, padding = 0,
        background = Blitbuffer.COLOR_WHITE, content,
    }
    UIManager:setDirty(self, "full")
end

function PuzzleScreen:onModeChooser()
    if self.mode_callback then self.mode_callback(self) end
    return true
end

function PuzzleScreen:onClose()
    return self:onModeChooser()
end

function PuzzleScreen:onSwipeNoop()
    return true
end

return PuzzleScreen
