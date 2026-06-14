# Content Guide

How to add or change learning rounds (prompt + images).

## Image specs

- **Format:** PNG
- **Color:** grayscale or simple flat-color art (it will be dithered to
  16 grayscale levels on the Kindle anyway — high-contrast, simple shapes
  work best)
- **Size:** roughly square, ~600×600 px is plenty for a 1072×1448 px
  screen split into 3–4 tiles. Larger files just slow down loading.
- **Naming:** lowercase, no spaces, e.g. `cat.png`, `red.png`, `1.png`

## Folder layout

Images live under `plugins/toddlerlearn.koplugin/assets/<category>/`.
Current categories: `animals/`, `fruit/`, `colors/`, `numbers/`,
`letters/`. Add new folders as needed for new categories (e.g.
`shapes/`, `vehicles/`).

## Adding a round

Each entry in `content.lua` is one round:

```lua
{
    prompt = "Cat",                              -- text shown at the top
    answer = "animals/cat.png",                  -- correct image
    distractors = {                              -- wrong images shown alongside
        "animals/dog.png",
        "animals/cow.png",
    },
},
```

Guidelines:

- **2 distractors** (3 tiles total) is a good starting point for
  toddlers; increase to 3–4 distractors later for older/more advanced
  kids (Phase 5 in `PROJECT_PLAN.md`).
- Pick distractors from the *same category* as the answer so the round
  is a meaningful choice (e.g. don't pair "Cat" with a number and a
  color — pair it with other animals).
- Keep `prompt` short — it's rendered in large text at a fixed size.

## Where to get images

- Draw simple shapes yourself (flat-color SVGs exported as PNG work
  great and dither cleanly).
- Open-licensed icon sets (e.g. simple line-art icon packs) are a good
  source of consistent, high-contrast images.
- Your own photos work too, but simplify/crop them — busy photographic
  backgrounds look noisy on e-ink and can confuse a toddler.

## Quick checklist when adding a new category

- [ ] Create `assets/<category>/` folder
- [ ] Add at least 3–4 images (1 answer + distractors per round, reused
      across rounds)
- [ ] Add 1+ rounds to `content.lua` using those images
- [ ] Test in the emulator (Phase 2/3 of `PROJECT_PLAN.md`)
