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
    {id = "dog_halves", kind = "picture", prompt = "Build the dog", level = 1, skill = "picture_assembly", pieces = pictureHalves("dog")},
    {id = "banana_halves", kind = "picture", prompt = "Build the banana", level = 1, skill = "picture_assembly", pieces = pictureHalves("banana")},
    {id = "bus_halves", kind = "picture", prompt = "Build the bus", level = 1, skill = "picture_assembly", pieces = pictureHalves("bus")},
    {id = "square_halves", kind = "shape", prompt = "Build the square", level = 1, skill = "shape_composition", pieces = pictureHalves("square")},
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
        id = "number_order_3", kind = "sequence", prompt = "Put numbers in order",
        level = 2, skill = "number_sequence",
        pieces = {{id = "n8", text = "8", target = 1}, {id = "n9", text = "9", target = 2}, {id = "n10", text = "10", target = 3}},
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
        id = "word_sun", kind = "word", prompt = "Build sun", level = 1,
        skill = "word_assembly", adult_guided = false,
        pieces = {{id = "sun_s", text = "s", target = 1}, {id = "sun_un", text = "un", target = 2}},
    },
    {
        id = "word_red", kind = "word", prompt = "Build red", level = 1,
        skill = "word_assembly", adult_guided = false,
        pieces = {{id = "red_r", text = "r", target = 1}, {id = "red_ed", text = "ed", target = 2}},
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
    {id = "dog_picture", kind = "picture", prompt = "Build the dog", level = 2, skill = "picture_assembly", pieces = picturePieces("dog")},
    {id = "banana_picture", kind = "picture", prompt = "Build the banana", level = 2, skill = "picture_assembly", pieces = picturePieces("banana")},
    {id = "train_picture", kind = "picture", prompt = "Build the train", level = 2, skill = "picture_assembly", pieces = picturePieces("train")},
    {id = "cup_picture", kind = "picture", prompt = "Build the cup", level = 2, skill = "picture_assembly", pieces = picturePieces("cup")},
    {
        id = "number_bond_5", kind = "number_bond", prompt = "2 + ? = 5",
        level = 2, skill = "compose_decompose",
        pieces = {{id = "bond_2", text = "2", target = 2}, {id = "bond_3", text = "3", target = 1}, {id = "bond_4", text = "4", target = 3}},
        answer_target = 1,
    },
    {
        id = "number_bond_7", kind = "number_bond", prompt = "3 + ? = 7",
        level = 2, skill = "compose_decompose",
        pieces = {{id = "bond7_3", text = "3", target = 2}, {id = "bond7_4", text = "4", target = 1}, {id = "bond7_5", text = "5", target = 3}},
        answer_target = 1,
    },
    {
        id = "number_bond_10", kind = "number_bond", prompt = "6 + ? = 10",
        level = 2, skill = "compose_decompose",
        pieces = {{id = "bond10_3", text = "3", target = 2}, {id = "bond10_4", text = "4", target = 1}, {id = "bond10_5", text = "5", target = 3}},
        answer_target = 1,
    },
    {
        id = "number_order_even", kind = "sequence", prompt = "Order the even numbers",
        level = 3, skill = "number_sequence",
        pieces = {{id = "even2", text = "2", target = 1}, {id = "even4", text = "4", target = 2}, {id = "even6", text = "6", target = 3}, {id = "even8", text = "8", target = 4}},
    },
    {
        id = "number_order_backward", kind = "sequence", prompt = "Count backward",
        level = 3, skill = "number_sequence",
        pieces = {{id = "back5", text = "5", target = 1}, {id = "back4", text = "4", target = 2}, {id = "back3", text = "3", target = 3}, {id = "back2", text = "2", target = 4}},
    },
    {
        id = "pattern_numbers", kind = "pattern", prompt = "Finish the pattern",
        level = 3, skill = "pattern_completion", fixed = {"1", "2", "1", "2"},
        pieces = {{id = "pattern_n1", text = "1", target = 1}, {id = "pattern_n2", text = "2", target = 2}, {id = "pattern_n3", text = "3", target = 3}},
        answer_target = 1,
    },
    {
        id = "pattern_growing", kind = "pattern", prompt = "What comes next?",
        level = 3, skill = "pattern_completion", fixed = {"1", "2", "3"},
        pieces = {{id = "grow2", text = "2", target = 2}, {id = "grow4", text = "4", target = 1}, {id = "grow5", text = "5", target = 3}},
        answer_target = 1,
    },
    {
        id = "pattern_shapes_2", kind = "pattern", prompt = "Finish the pattern",
        level = 3, skill = "pattern_completion", fixed = {"circle", "circle", "square", "circle", "circle"},
        pieces = {{id = "shape2_square", text = "square", target = 1}, {id = "shape2_circle", text = "circle", target = 2}, {id = "shape2_triangle", text = "triangle", target = 3}},
        answer_target = 1,
    },
    {
        id = "number_bond_9", kind = "number_bond", prompt = "5 + ? = 9",
        level = 3, skill = "compose_decompose",
        pieces = {{id = "bond9_3", text = "3", target = 2}, {id = "bond9_4", text = "4", target = 1}, {id = "bond9_5", text = "5", target = 3}},
        answer_target = 1,
    },
    {
        id = "odd_fruit", kind = "odd_one_out", prompt = "Which is different?",
        level = 4, skill = "classification", answer_target = 1,
        pieces = {
            {id = "odd_apple", image = "fruit/apple.png", target = 1},
            {id = "odd_cat", image = "animals/cat.png", target = 2},
            {id = "odd_dog", image = "animals/dog.png", target = 3},
            {id = "odd_cow", image = "animals/cow.png", target = 4},
        },
    },
    {
        id = "odd_animal", kind = "odd_one_out", prompt = "Which is different?",
        level = 4, skill = "classification", answer_target = 1,
        pieces = {
            {id = "odd2_cat", image = "animals/cat.png", target = 1},
            {id = "odd2_car", image = "vehicles/car.png", target = 2},
            {id = "odd2_bus", image = "vehicles/bus.png", target = 3},
            {id = "odd2_train", image = "vehicles/train.png", target = 4},
        },
    },
    {
        id = "odd_shape", kind = "odd_one_out", prompt = "Which is different?",
        level = 4, skill = "classification", answer_target = 1,
        pieces = {
            {id = "odd3_banana", image = "fruit/banana.png", target = 1},
            {id = "odd3_circle", image = "shapes/circle.png", target = 2},
            {id = "odd3_square", image = "shapes/square.png", target = 3},
            {id = "odd3_triangle", image = "shapes/triangle.png", target = 4},
        },
    },
    {
        id = "odd_number", kind = "odd_one_out", prompt = "Which is different?",
        level = 4, skill = "classification", answer_target = 1,
        pieces = {{id = "odd7", text = "7", target = 1}, {id = "odd2", text = "2", target = 2}, {id = "odd4", text = "4", target = 3}, {id = "odd6", text = "6", target = 4}},
    },
    {
        id = "largest_first", kind = "sequence", prompt = "Put biggest first",
        level = 4, skill = "ordering",
        pieces = {{id = "large9", text = "9", target = 1}, {id = "large7", text = "7", target = 2}, {id = "large5", text = "5", target = 3}, {id = "large3", text = "3", target = 4}},
    },
    {
        id = "missing_addend", kind = "number_bond", prompt = "? + 3 = 10",
        level = 4, skill = "compose_decompose",
        pieces = {{id = "add6", text = "6", target = 2}, {id = "add7", text = "7", target = 1}, {id = "add8", text = "8", target = 3}},
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
