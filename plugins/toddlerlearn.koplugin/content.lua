local Content = {}

Content.category_order = {
    "animals",
    "fruit",
    "colors",
    "numbers",
    "letters",
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
    colors = {
        label = "Colors",
        rounds = {
            {
                prompt = "Red",
                answer = "colors/red.png",
                distractors = {"colors/blue.png", "colors/yellow.png"},
            },
            {
                prompt = "Blue",
                answer = "colors/blue.png",
                distractors = {"colors/red.png", "colors/green.png"},
            },
            {
                prompt = "Green",
                answer = "colors/green.png",
                distractors = {"colors/yellow.png", "colors/blue.png"},
            },
            {
                prompt = "Yellow",
                answer = "colors/yellow.png",
                distractors = {"colors/red.png", "colors/white.png"},
            },
            {
                prompt = "White",
                answer = "colors/white.png",
                distractors = {"colors/green.png", "colors/blue.png"},
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
        },
    },
}

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

for _, category in ipairs(Content.category_order) do
    for _, round in ipairs(Content.categories[category].rounds) do
        round.category = category
        table.insert(Content, round)
    end
end

return Content
