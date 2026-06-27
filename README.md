# Toddler Learn — Kindle Paperwhite KOReader Plugin

A simple, e-ink-friendly "tap the matching picture" learning game for
toddlers, built as a [KOReader](https://github.com/koreader/koreader)
plugin for a jailbroken Kindle Paperwhite (7th gen / PW3, firmware
5.16.2.1.1).

## How it works

- A word, letter, or number is shown at the top of the screen.
- Several large images are shown below it.
- The child taps the image that matches the prompt.
- Reading rounds show only the target word above unlabeled pictures, so the
  child practices reading instead of matching duplicate captions.
- Uppercase rounds ask the child to choose the matching lowercase letter.
- Beginning-sound rounds show one letter and ask for the picture whose word
  starts with that letter.
- Ending-sound rounds show one letter and ask for a picture whose word ends
  with that letter.
- Short-word spelling begins with three-letter CVC words before introducing
  slightly harder four-letter words.
- Word-family rounds contrast matching endings such as `-at`, `-og`, `-un`,
  and `-ed` using large text choices.
- Word-blending rounds join visible chunks such as `c + at` into a complete
  decodable word.
- Simple sentence rounds ask the child to read a short sentence and choose
  the matching picture.
- Sentence-building rounds scramble three or four words for the child to tap
  into the correct order; tapping the answer row clears an attempt.
- Decodable mini-stories present three short pages followed by a picture
  comprehension question.
- Number recognition, counting, and numeral-to-quantity matching cover one
  through ten with high-contrast dot cards.
- Ten-frame rounds arrange quantities in a consistent two-by-five grid to
  build recognition without counting every dot.
- Number-bond rounds ask for a missing part and use ten-frame answers to make
  addition facts through ten concrete and visible.
- Early Maths combines more/fewer, biggest/smallest, number order, missing
  numbers, visual addition and subtraction to five, shape properties, and
  simple repeating patterns.
- Spelling rounds show a picture, large scrambled letter tiles, and large
  answer boxes. Tapping an answer box clears the attempt for another try.
- Spelling assistance scales with difficulty: starter letters appear for
  early learners and disappear as the level becomes harder.
- A correct tap shows calm feedback, advances the round, and every five
  correct answers shows a simple reward screen.
- An incorrect tap briefly emphasizes the selected tile and waits for
  another try.
- The normal menu entry starts mixed review immediately.
- The parent setup menu lets an adult pick a category and difficulty before
  starting, plus a focused session length of 5, 10, or 15 rounds.
- A completed session ends on a clear reward screen instead of looping
  indefinitely.
- Progress stays local on the Kindle; rounds with more mistakes return more
  often while mastered material remains in lighter review.
- Guided Learning follows a mastery-based path from letter pairs through
  sounds, short words, word families, and simple sentences.
- Two-finger hold exits back to KOReader's file browser.

Everything is local — no internet, no accounts, no ads, no sound (the
7th-gen Paperwhite has no speaker anyway).

## Project structure

```
kindle-toddler-learn/
├── README.md              <- this file
├── PROJECT_PLAN.md         <- phased roadmap + checklists
├── CONTENT_GUIDE.md         <- how to add new rounds / images
└── plugins/
    └── toddlerlearn.koplugin/
        ├── _meta.lua        <- plugin name/description (KOReader reads this)
        ├── main.lua         <- registers the plugin in KOReader's menu
        ├── gamescreen.lua    <- the actual game UI/logic
        ├── content.lua       <- categorized prompts + validation helpers
        └── assets/           <- images, organized by category
            ├── animals/
            ├── fruit/
            ├── numbers/
            ├── letters/
            ├── shapes/
            ├── vehicles/
            ├── body/
            ├── household/
            ├── emotions/
            └── counting/
```

## Status

The expanded build has been tested successfully on a Kindle. It includes
category sessions, difficulty levels, generated e-ink assets, caption-free
reading practice, large resettable spelling controls, parent setup, reward
milestones, and content validation tests. KOReader's internal widget APIs can
still vary between versions, so run `./run-tests.sh` and do a quick device
smoke test before handing a new build to a child.

## Development setup (on your computer)

1. **Clone KOReader and build the desktop emulator:**
   ```
   git clone https://github.com/koreader/koreader.git
   cd koreader
   ./kodev fetch-thirdparty
   ./kodev build
   ./kodev run
   ```
   This opens a window simulating the Kindle's screen with mouse-as-touch
   input — much faster to iterate on than copying files to the device
   every time.

2. **Link this plugin into your KOReader checkout** so the emulator picks
   it up:
   ```
   ln -s /path/to/kindle-toddler-learn/plugins/toddlerlearn.koplugin \
         /path/to/koreader/plugins/toddlerlearn.koplugin
   ```

3. **Run the emulator** (`./kodev run`). Open the main menu — you should
   see a "Toddler Learn" entry (once Phase 1 in `PROJECT_PLAN.md` is
   working). Read the terminal output for any Lua errors and fix them in
   `main.lua` / `gamescreen.lua`.

## Deploying to the Kindle

Once it runs correctly in the emulator:

1. Make sure your Kindle is jailbroken (LanguageBreak, firmware
   5.16.2.1.1) and KOReader is installed (extracted to the Kindle's root
   as a `koreader/` folder, launched via KUAL).
2. Copy the whole `toddlerlearn.koplugin` folder (including your real
   `assets/` images) into `koreader/plugins/` on the Kindle's USB storage.
3. Restart KOReader (or reboot the Kindle).
4. The "Toddler Learn" entry should appear in KOReader's menu.

## Notes for the e-ink screen

- The Paperwhite 3 (7th gen) screen is 1072 × 1448 px at 300 ppi, 16-level
  grayscale.
- Large touch targets matter — toddler fingers aren't precise. Aim for
  tiles that are at least a quarter of the screen each.
- Avoid relying on animation; e-ink can't do smooth motion. Feedback
  should be discrete (a checkmark image, a brief full-screen refresh,
  a clear border change for a moment).
- Full-screen refreshes ("flashes") clear ghosting but are slow and
  visually jarring for a toddler — use them sparingly (e.g. once per
  round, not per tap).
- Keep images simple: thick black outlines, white background, large
  silhouettes, and no tiny detail. The generator in `generate_assets.py`
  follows this style.

## Safety / lock-down ideas (for later)

- Disable KOReader's normal swipe-to-menu gestures while the game is
  running, so a toddler can't wander into settings or the file browser.
- Consider a PIN-protected exit gesture instead of (or in addition to)
  two-finger tap.
