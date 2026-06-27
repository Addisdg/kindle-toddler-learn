local PuzzleContent = {}

local function picturePieces(id)
    local pieces = {}
    for position = 1, 4 do
        table.insert(pieces, {
            id = id .. "_" .. tostring(position),
            image = "puzzles/" .. id .. "_" .. tostring(position) .. ".png",
            target = position,
        })
    end
    return pieces
end

local function pictureHalves(id)
    return {
        {id = id .. "_half_1", image = "puzzles/" .. id .. "_half_1.png", target = 1},
        {id = id .. "_half_2", image = "puzzles/" .. id .. "_half_2.png", target = 2},
    }
end

PuzzleContent.puzzles = {
    {id = "cat_halves", kind = "picture", prompt = "Build the cat", level = 1, skill = "picture_assembly", pieces = pictureHalves("cat")},
    {id = "apple_halves", kind = "picture", prompt = "Build the apple", level = 1, skill = "picture_assembly", pieces = pictureHalves("apple")},
    {
        id = "number_order_1", kind = "sequence", prompt = "Put numbers in order",
        level = 1, skill = "number_sequence",
        pieces = {{id = "n1", text = "1", target = 1}, {id = "n2", text = "2", target = 2}, {id = "n3", text = "3", target = 3}},
    },
    {
        id = "number_order_2", kind = "sequence", prompt = "Put numbers in order",
        level = 2, skill = "number_sequence",
        pieces = {{id = "n4", text = "4", target = 1}, {id = "n5", text = "5", target = 2}, {id = "n6", text = "6", target = 3}, {id = "n7", text = "7", target = 4}},
    },
    {
        id = "word_cat", kind = "word", prompt = "Build cat", level = 1,
        skill = "word_assembly", adult_guided = false,
        pieces = {{id = "cat_c", text = "c", target = 1}, {id = "cat_at", text = "at", target = 2}},
    },
    {
        id = "word_dog", kind = "word", prompt = "Build dog", level = 1,
        skill = "word_assembly", adult_guided = false,
        pieces = {{id = "dog_d", text = "d", target = 1}, {id = "dog_og", text = "og", target = 2}},
    },
    {
        id = "pattern_shapes", kind = "pattern", prompt = "Finish the pattern",
        level = 1, skill = "pattern_completion",
        fixed = {"circle", "square", "circle"},
        pieces = {{id = "pattern_square", text = "square", target = 1}, {id = "pattern_circle", text = "circle", target = 2}},
        answer_target = 1,
    },
    {id = "cat_picture", kind = "picture", prompt = "Build the cat", level = 2, skill = "picture_assembly", pieces = picturePieces("cat")},
    {id = "apple_picture", kind = "picture", prompt = "Build the apple", level = 2, skill = "picture_assembly", pieces = picturePieces("apple")},
    {id = "bus_picture", kind = "picture", prompt = "Build the bus", level = 2, skill = "picture_assembly", pieces = picturePieces("bus")},
    {id = "ball_picture", kind = "picture", prompt = "Build the ball", level = 2, skill = "picture_assembly", pieces = picturePieces("ball")},
    {
        id = "number_bond_5", kind = "number_bond", prompt = "2 + ? = 5",
        level = 2, skill = "compose_decompose",
        pieces = {{id = "bond_2", text = "2", target = 2}, {id = "bond_3", text = "3", target = 1}, {id = "bond_4", text = "4", target = 3}},
        answer_target = 1,
    },
}

table.sort(PuzzleContent.puzzles, function(first, second)
    if first.level == second.level then return first.id < second.id end
    return first.level < second.level
end)

local function pathExists(path)
    local file = io.open(path, "rb")
    if not file then return false end
    file:close()
    return true
end

function PuzzleContent.validate(asset_dir)
    local errors = {}
    local ids = {}
    for index, puzzle in ipairs(PuzzleContent.puzzles) do
        local name = "puzzle " .. tostring(index)
        if not puzzle.id or ids[puzzle.id] then
            table.insert(errors, name .. " has missing or duplicate id")
        end
        ids[puzzle.id] = true
        if not puzzle.prompt or #puzzle.prompt > 24 then
            table.insert(errors, name .. " has invalid prompt")
        end
        if not puzzle.skill or type(puzzle.level) ~= "number" then
            table.insert(errors, name .. " has invalid curriculum metadata")
        end
        if not puzzle.pieces or #puzzle.pieces < 2 or #puzzle.pieces > 4 then
            table.insert(errors, name .. " needs 2 to 4 pieces")
        else
            local piece_ids = {}
            local targets = {}
            for _, piece in ipairs(puzzle.pieces) do
                if not piece.id or piece_ids[piece.id] then
                    table.insert(errors, name .. " has duplicate piece id")
                end
                piece_ids[piece.id] = true
                if type(piece.target) ~= "number" then
                    table.insert(errors, name .. " has a piece without a target")
                end
                targets[piece.target] = true
                if not piece.text and not piece.image then
                    table.insert(errors, name .. " has a piece without content")
                elseif piece.image and asset_dir and not pathExists(asset_dir .. piece.image) then
                    table.insert(errors, name .. " is missing " .. piece.image)
                end
            end
            if puzzle.kind ~= "pattern" and puzzle.kind ~= "number_bond" then
                for target = 1, #puzzle.pieces do
                    if not targets[target] then
                        table.insert(errors, name .. " has a missing target")
                    end
                end
            elseif not puzzle.answer_target or not targets[puzzle.answer_target] then
                table.insert(errors, name .. " has an invalid answer target")
            end
        end
    end
    return #errors == 0, errors
end

return PuzzleContent
