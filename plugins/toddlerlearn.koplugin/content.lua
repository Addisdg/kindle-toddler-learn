local Content = {}

Content.category_order = {
    "animals",
    "fruit",
    "numbers",
    "letters",
    "letter_pairs",
    "letter_words",
    "beginning_sounds",
    "reading_words",
    "cvc_words",
    "spelling_words",
    "shapes",
    "vehicles",
    "body",
    "household",
    "emotions",
    "counting",
}

Content.categories = {
    animals = {
        label = "Animals",
        rounds = {
            {
                prompt = "Cat",
                answer = "animals/cat.png",
                distractors = {"animals/dog.png", "animals/cow.png"},
            },
            {
                prompt = "Dog",
                answer = "animals/dog.png",
                distractors = {"animals/cat.png", "animals/bird.png"},
            },
            {
                prompt = "Bird",
                answer = "animals/bird.png",
                distractors = {"animals/fish.png", "animals/dog.png"},
            },
            {
                prompt = "Fish",
                answer = "animals/fish.png",
                distractors = {"animals/bird.png", "animals/cow.png"},
            },
            {
                prompt = "Cow",
                answer = "animals/cow.png",
                distractors = {"animals/cat.png", "animals/fish.png"},
            },
        },
    },
    fruit = {
        label = "Fruit",
        rounds = {
            {
                prompt = "Apple",
                answer = "fruit/apple.png",
                distractors = {"fruit/banana.png", "fruit/grapes.png"},
            },
            {
                prompt = "Banana",
                answer = "fruit/banana.png",
                distractors = {"fruit/apple.png", "fruit/orange.png"},
            },
            {
                prompt = "Grapes",
                answer = "fruit/grapes.png",
                distractors = {"fruit/strawberry.png", "fruit/banana.png"},
            },
            {
                prompt = "Strawberry",
                answer = "fruit/strawberry.png",
                distractors = {"fruit/grapes.png", "fruit/orange.png"},
            },
            {
                prompt = "Orange",
                answer = "fruit/orange.png",
                distractors = {"fruit/apple.png", "fruit/strawberry.png"},
            },
        },
    },
    numbers = {
        label = "Numbers",
        rounds = {
            {
                prompt = "1",
                answer = "numbers/1.png",
                distractors = {"numbers/2.png", "numbers/3.png"},
            },
            {
                prompt = "2",
                answer = "numbers/2.png",
                distractors = {"numbers/1.png", "numbers/4.png"},
            },
            {
                prompt = "3",
                answer = "numbers/3.png",
                distractors = {"numbers/2.png", "numbers/5.png"},
            },
            {
                prompt = "4",
                answer = "numbers/4.png",
                distractors = {"numbers/3.png", "numbers/5.png"},
            },
            {
                prompt = "5",
                answer = "numbers/5.png",
                distractors = {"numbers/4.png", "numbers/1.png"},
            },
        },
    },
    letters = {
        label = "Letters",
        rounds = {
            {
                prompt = "A",
                answer = "letters/a.png",
                distractors = {"letters/b.png", "letters/c.png"},
            },
            {
                prompt = "B",
                answer = "letters/b.png",
                distractors = {"letters/a.png", "letters/d.png"},
            },
            {
                prompt = "C",
                answer = "letters/c.png",
                distractors = {"letters/b.png", "letters/d.png"},
            },
            {
                prompt = "D",
                answer = "letters/d.png",
                distractors = {"letters/c.png", "letters/e.png"},
            },
            {
                prompt = "E",
                answer = "letters/e.png",
                distractors = {"letters/d.png", "letters/f.png"},
            },
            {
                prompt = "F",
                answer = "letters/f.png",
                distractors = {"letters/e.png", "letters/g.png"},
            },
            {
                prompt = "G",
                answer = "letters/g.png",
                distractors = {"letters/f.png", "letters/h.png"},
            },
            {
                prompt = "H",
                answer = "letters/h.png",
                distractors = {"letters/g.png", "letters/i.png"},
            },
            {
                prompt = "I",
                answer = "letters/i.png",
                distractors = {"letters/h.png", "letters/j.png"},
            },
            {
                prompt = "J",
                answer = "letters/j.png",
                distractors = {"letters/i.png", "letters/k.png"},
            },
            {
                prompt = "K",
                answer = "letters/k.png",
                distractors = {"letters/j.png", "letters/l.png"},
            },
            {
                prompt = "L",
                answer = "letters/l.png",
                distractors = {"letters/k.png", "letters/m.png"},
            },
            {
                prompt = "M",
                answer = "letters/m.png",
                distractors = {"letters/l.png", "letters/n.png"},
            },
            {
                prompt = "N",
                answer = "letters/n.png",
                distractors = {"letters/m.png", "letters/o.png"},
            },
            {
                prompt = "O",
                answer = "letters/o.png",
                distractors = {"letters/n.png", "letters/p.png"},
            },
            {
                prompt = "P",
                answer = "letters/p.png",
                distractors = {"letters/o.png", "letters/q.png"},
            },
            {
                prompt = "Q",
                answer = "letters/q.png",
                distractors = {"letters/p.png", "letters/r.png"},
            },
            {
                prompt = "R",
                answer = "letters/r.png",
                distractors = {"letters/q.png", "letters/s.png"},
            },
            {
                prompt = "S",
                answer = "letters/s.png",
                distractors = {"letters/r.png", "letters/t.png"},
            },
            {
                prompt = "T",
                answer = "letters/t.png",
                distractors = {"letters/s.png", "letters/u.png"},
            },
            {
                prompt = "U",
                answer = "letters/u.png",
                distractors = {"letters/t.png", "letters/v.png"},
            },
            {
                prompt = "V",
                answer = "letters/v.png",
                distractors = {"letters/u.png", "letters/w.png"},
            },
            {
                prompt = "W",
                answer = "letters/w.png",
                distractors = {"letters/v.png", "letters/x.png"},
            },
            {
                prompt = "X",
                answer = "letters/x.png",
                distractors = {"letters/w.png", "letters/y.png"},
            },
            {
                prompt = "Y",
                answer = "letters/y.png",
                distractors = {"letters/x.png", "letters/z.png"},
            },
            {
                prompt = "Z",
                answer = "letters/z.png",
                distractors = {"letters/y.png", "letters/a.png"},
            },
        },
    },
    letter_pairs = {
        label = "Big and Small Letters",
        rounds = {},
    },
    letter_words = {
        label = "Letter Words",
        rounds = {
            {
                prompt = "A Apple",
                answer = "fruit/apple.png",
                distractors = {"fruit/banana.png", "fruit/orange.png"},
            },
            {
                prompt = "B Bird",
                answer = "animals/bird.png",
                distractors = {"animals/cat.png", "animals/dog.png"},
            },
            {
                prompt = "C Cat",
                answer = "animals/cat.png",
                distractors = {"animals/cow.png", "animals/fish.png"},
            },
            {
                prompt = "D Dog",
                answer = "animals/dog.png",
                distractors = {"animals/bird.png", "animals/cow.png"},
            },
            {
                prompt = "F Fish",
                answer = "animals/fish.png",
                distractors = {"animals/cat.png", "animals/bird.png"},
            },
        },
    },
    beginning_sounds = {
        label = "Beginning Sounds",
        rounds = {},
    },
    reading_words = {
        label = "Reading Words",
        rounds = {},
    },
    cvc_words = {
        label = "Short Word Spelling",
        rounds = {
            {kind = "spelling", prompt = "Spell it", answer = "animals/cat.png", word = "cat", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "animals/dog.png", word = "dog", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "vehicles/bus.png", word = "bus", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "household/cup.png", word = "cup", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "household/bed.png", word = "bed", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "emotions/sad.png", word = "sad", level = 1},
            {kind = "spelling", prompt = "Spell it", answer = "animals/fish.png", word = "fish", level = 2},
            {kind = "spelling", prompt = "Spell it", answer = "body/hand.png", word = "hand", level = 2},
            {kind = "spelling", prompt = "Spell it", answer = "body/foot.png", word = "foot", level = 2},
            {kind = "spelling", prompt = "Spell it", answer = "vehicles/boat.png", word = "boat", level = 2},
        },
    },
    spelling_words = {
        label = "Spelling Words",
        rounds = {},
    },
    shapes = {
        label = "Shapes",
        rounds = {
            {
                prompt = "Circle",
                answer = "shapes/circle.png",
                distractors = {"shapes/square.png", "shapes/triangle.png"},
            },
            {
                prompt = "Square",
                answer = "shapes/square.png",
                distractors = {"shapes/circle.png", "shapes/star.png"},
            },
            {
                prompt = "Triangle",
                answer = "shapes/triangle.png",
                distractors = {"shapes/heart.png", "shapes/square.png"},
            },
            {
                prompt = "Star",
                answer = "shapes/star.png",
                distractors = {"shapes/circle.png", "shapes/heart.png"},
            },
            {
                prompt = "Heart",
                answer = "shapes/heart.png",
                distractors = {"shapes/star.png", "shapes/triangle.png"},
            },
        },
    },
    vehicles = {
        label = "Vehicles",
        rounds = {
            {
                prompt = "Car",
                answer = "vehicles/car.png",
                distractors = {"vehicles/bus.png", "vehicles/train.png"},
            },
            {
                prompt = "Bus",
                answer = "vehicles/bus.png",
                distractors = {"vehicles/car.png", "vehicles/boat.png"},
            },
            {
                prompt = "Train",
                answer = "vehicles/train.png",
                distractors = {"vehicles/bus.png", "vehicles/plane.png"},
            },
            {
                prompt = "Boat",
                answer = "vehicles/boat.png",
                distractors = {"vehicles/car.png", "vehicles/plane.png"},
            },
            {
                prompt = "Plane",
                answer = "vehicles/plane.png",
                distractors = {"vehicles/train.png", "vehicles/boat.png"},
            },
        },
    },
    body = {
        label = "Body",
        rounds = {
            {
                prompt = "Hand",
                answer = "body/hand.png",
                distractors = {"body/foot.png", "body/ear.png"},
            },
            {
                prompt = "Foot",
                answer = "body/foot.png",
                distractors = {"body/hand.png", "body/nose.png"},
            },
            {
                prompt = "Eye",
                answer = "body/eye.png",
                distractors = {"body/ear.png", "body/nose.png"},
            },
            {
                prompt = "Ear",
                answer = "body/ear.png",
                distractors = {"body/eye.png", "body/hand.png"},
            },
            {
                prompt = "Nose",
                answer = "body/nose.png",
                distractors = {"body/foot.png", "body/eye.png"},
            },
        },
    },
    household = {
        label = "Home",
        rounds = {
            {
                prompt = "Cup",
                answer = "household/cup.png",
                distractors = {"household/spoon.png", "household/bed.png"},
            },
            {
                prompt = "Spoon",
                answer = "household/spoon.png",
                distractors = {"household/cup.png", "household/ball.png"},
            },
            {
                prompt = "Bed",
                answer = "household/bed.png",
                distractors = {"household/chair.png", "household/cup.png"},
            },
            {
                prompt = "Chair",
                answer = "household/chair.png",
                distractors = {"household/bed.png", "household/ball.png"},
            },
            {
                prompt = "Ball",
                answer = "household/ball.png",
                distractors = {"household/spoon.png", "household/chair.png"},
            },
        },
    },
    emotions = {
        label = "Emotions",
        rounds = {
            {
                prompt = "Happy",
                answer = "emotions/happy.png",
                distractors = {"emotions/sad.png", "emotions/sleepy.png"},
            },
            {
                prompt = "Sad",
                answer = "emotions/sad.png",
                distractors = {"emotions/happy.png", "emotions/surprised.png"},
            },
            {
                prompt = "Sleepy",
                answer = "emotions/sleepy.png",
                distractors = {"emotions/happy.png", "emotions/surprised.png"},
            },
            {
                prompt = "Surprised",
                answer = "emotions/surprised.png",
                distractors = {"emotions/sad.png", "emotions/sleepy.png"},
            },
        },
    },
    counting = {
        label = "Counting",
        rounds = {
            {
                prompt = "1 dot",
                answer = "counting/1.png",
                distractors = {"counting/2.png", "counting/3.png"},
            },
            {
                prompt = "2 dots",
                answer = "counting/2.png",
                distractors = {"counting/1.png", "counting/4.png"},
            },
            {
                prompt = "3 dots",
                answer = "counting/3.png",
                distractors = {"counting/2.png", "counting/5.png"},
            },
            {
                prompt = "4 dots",
                answer = "counting/4.png",
                distractors = {"counting/3.png", "counting/5.png"},
            },
            {
                prompt = "5 dots",
                answer = "counting/5.png",
                distractors = {"counting/4.png", "counting/1.png"},
            },
        },
    },
}

Content.word_bank = {
    {word = "cat", path = "animals/cat.png"},
    {word = "dog", path = "animals/dog.png"},
    {word = "bird", path = "animals/bird.png"},
    {word = "fish", path = "animals/fish.png"},
    {word = "cow", path = "animals/cow.png"},
    {word = "apple", path = "fruit/apple.png"},
    {word = "banana", path = "fruit/banana.png"},
    {word = "grapes", path = "fruit/grapes.png"},
    {word = "strawberry", path = "fruit/strawberry.png"},
    {word = "orange", path = "fruit/orange.png"},
    {word = "one", path = "counting/1.png"},
    {word = "two", path = "counting/2.png"},
    {word = "three", path = "counting/3.png"},
    {word = "four", path = "counting/4.png"},
    {word = "five", path = "counting/5.png"},
    {word = "circle", path = "shapes/circle.png"},
    {word = "square", path = "shapes/square.png"},
    {word = "triangle", path = "shapes/triangle.png"},
    {word = "star", path = "shapes/star.png"},
    {word = "heart", path = "shapes/heart.png"},
    {word = "car", path = "vehicles/car.png"},
    {word = "bus", path = "vehicles/bus.png"},
    {word = "train", path = "vehicles/train.png"},
    {word = "boat", path = "vehicles/boat.png"},
    {word = "plane", path = "vehicles/plane.png"},
    {word = "hand", path = "body/hand.png"},
    {word = "foot", path = "body/foot.png"},
    {word = "eye", path = "body/eye.png"},
    {word = "ear", path = "body/ear.png"},
    {word = "nose", path = "body/nose.png"},
    {word = "cup", path = "household/cup.png"},
    {word = "spoon", path = "household/spoon.png"},
    {word = "bed", path = "household/bed.png"},
    {word = "chair", path = "household/chair.png"},
    {word = "ball", path = "household/ball.png"},
    {word = "happy", path = "emotions/happy.png"},
    {word = "sad", path = "emotions/sad.png"},
    {word = "sleepy", path = "emotions/sleepy.png"},
    {word = "surprised", path = "emotions/surprised.png"},
}

local function getWordBankItem(index)
    local count = #Content.word_bank
    return Content.word_bank[((index - 1) % count) + 1]
end

local function addLetterPairRounds()
    local letters = "abcdefghijklmnopqrstuvwxyz"
    for i = 1, #letters do
        local lower = letters:sub(i, i)
        local next_one = letters:sub((i % #letters) + 1, (i % #letters) + 1)
        local next_two_index = ((i + 1) % #letters) + 1
        local next_two = letters:sub(next_two_index, next_two_index)
        table.insert(Content.categories.letter_pairs.rounds, {
            kind = "text_choice",
            prompt = lower:upper(),
            answer_text = lower,
            distractors_text = {next_one, next_two},
        })
    end
end

local function addBeginningSoundRounds()
    local items = {
        {word = "apple", path = "fruit/apple.png"},
        {word = "ball", path = "household/ball.png"},
        {word = "cat", path = "animals/cat.png"},
        {word = "dog", path = "animals/dog.png"},
        {word = "eye", path = "body/eye.png"},
        {word = "fish", path = "animals/fish.png"},
        {word = "grapes", path = "fruit/grapes.png"},
        {word = "hand", path = "body/hand.png"},
        {word = "nose", path = "body/nose.png"},
        {word = "orange", path = "fruit/orange.png"},
        {word = "plane", path = "vehicles/plane.png"},
        {word = "spoon", path = "household/spoon.png"},
        {word = "train", path = "vehicles/train.png"},
    }

    for i, item in ipairs(items) do
        local next_one = items[(i % #items) + 1]
        local next_two = items[((i + 1) % #items) + 1]
        table.insert(Content.categories.beginning_sounds.rounds, {
            prompt = item.word:sub(1, 1):upper(),
            answer = item.path,
            distractors = {next_one.path, next_two.path},
            sound_word = item.word,
        })
    end
end

local function getWordDistractors(index)
    return {
        getWordBankItem(index + 1),
        getWordBankItem(index + 2),
    }
end

local function addReadingAndSpellingRounds()
    for i, item in ipairs(Content.word_bank) do
        local distractors = getWordDistractors(i)
        table.insert(Content.categories.reading_words.rounds, {
            prompt = item.word,
            answer = item.path,
            distractors = {distractors[1].path, distractors[2].path},
        })

        table.insert(Content.categories.spelling_words.rounds, {
            kind = "spelling",
            prompt = "Spell it",
            answer = item.path,
            word = item.word,
        })
    end
end

addLetterPairRounds()
addBeginningSoundRounds()
addReadingAndSpellingRounds()

function Content.getRounds(category)
    if not category or category == "mixed" then
        return Content
    end

    local category_data = Content.categories[category]
    if not category_data then
        return {}
    end

    return category_data.rounds
end

function Content.pathExists(path)
    local file = io.open(path, "rb")
    if not file then
        return false
    end
    file:close()
    return true
end

function Content.validate(asset_dir)
    local errors = {}
    local mixed_path_categories = {
        letter_words = true,
        beginning_sounds = true,
        reading_words = true,
        cvc_words = true,
        spelling_words = true,
    }

    local function add_error(message)
        table.insert(errors, message)
    end

    for _, category in ipairs(Content.category_order) do
        local category_data = Content.categories[category]
        if not category_data then
            add_error("missing category: " .. category)
        elseif not category_data.label or category_data.label == "" then
            add_error("missing category label: " .. category)
        elseif #category_data.rounds == 0 then
            add_error("category has no rounds: " .. category)
        else
            for i, round in ipairs(category_data.rounds) do
                local round_name = category .. " round " .. tostring(i)
                if not round.prompt or round.prompt == "" then
                    add_error(round_name .. " has no prompt")
                elseif #round.prompt > 24 then
                    add_error(round_name .. " prompt is too long: " .. round.prompt)
                end

                if round.kind == "text_choice" then
                    if not round.answer_text or round.answer_text == "" then
                        add_error(round_name .. " has no text answer")
                    end
                    if not round.distractors_text or #round.distractors_text < 2 then
                        add_error(round_name .. " needs at least 2 text distractors")
                    end
                else
                    if not round.answer or not round.answer:match("%.png$") then
                        add_error(round_name .. " answer is not a png")
                    elseif asset_dir and not Content.pathExists(asset_dir .. round.answer) then
                        add_error(round_name .. " missing answer asset: " .. round.answer)
                    end
                end

                if round.kind == "spelling" then
                    if not round.word or round.word == "" then
                        add_error(round_name .. " has no spelling word")
                    elseif round.word:match("[^a-z]") then
                        add_error(round_name .. " spelling word must use lowercase letters only: " .. round.word)
                    end
                elseif round.kind ~= "text_choice" then
                    local seen = {
                        [round.answer] = true,
                    }
                    if not round.distractors or #round.distractors < 2 then
                        add_error(round_name .. " needs at least 2 distractors")
                    else
                        for _, distractor in ipairs(round.distractors) do
                            if seen[distractor] then
                                add_error(round_name .. " has duplicate image: " .. distractor)
                            end
                            seen[distractor] = true

                            if not distractor:match("%.png$") then
                                add_error(round_name .. " distractor is not a png: " .. distractor)
                            elseif asset_dir and not Content.pathExists(asset_dir .. distractor) then
                                add_error(round_name .. " missing distractor asset: " .. distractor)
                            end
                        end
                    end
                end

                if round.kind ~= "text_choice" and not mixed_path_categories[category] then
                    local expected_prefix = category .. "/"
                    if round.answer and round.answer:sub(1, #expected_prefix) ~= expected_prefix then
                        add_error(round_name .. " answer is outside category: " .. round.answer)
                    end
                    for _, distractor in ipairs(round.distractors or {}) do
                        if distractor:sub(1, #expected_prefix) ~= expected_prefix then
                            add_error(round_name .. " distractor is outside category: " .. distractor)
                        end
                    end
                end

            end
        end
    end

    return #errors == 0, errors
end

for _, category in ipairs(Content.category_order) do
    for _, round in ipairs(Content.categories[category].rounds) do
        round.category = category
        table.insert(Content, round)
    end
end

return Content
