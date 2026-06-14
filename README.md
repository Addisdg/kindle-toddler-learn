# Toddler Learn — Kindle Paperwhite KOReader Plugin

A simple, e-ink-friendly "tap the matching picture" learning game for
toddlers, built as a [KOReader](https://github.com/koreader/koreader)
plugin for a jailbroken Kindle Paperwhite (7th gen / PW3, firmware
5.16.2.1.1).

## How it works

- A word, letter, number, or color name is shown at the top of the screen.
- Several large images are shown below it.
- The child taps the image that matches the prompt.
- A correct tap loads the next round; an incorrect tap just waits for
  another try (no harsh feedback).
- Two-finger tap exits back to KOReader's file browser.

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
        ├── content.lua       <- list of prompts + image paths
        └── assets/           <- images, organized by category
            ├── animals/
            ├── fruit/
            ├── colors/
            ├── numbers/
            └── letters/
```

## Status

This is a **working scaffold**, not a tested, drop-in plugin. KOReader's
internal widget APIs vary a bit between versions, so expect to spend your
first session debugging against whatever error messages the emulator gives
you — that's normal for KOReader plugin development and is covered in
`PROJECT_PLAN.md` (Phase 1).

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
  inverted colors for a moment).
- Full-screen refreshes ("flashes") clear ghosting but are slow and
  visually jarring for a toddler — use them sparingly (e.g. once per
  round, not per tap).

## Safety / lock-down ideas (for later)

- Disable KOReader's normal swipe-to-menu gestures while the game is
  running, so a toddler can't wander into settings or the file browser.
- Consider a PIN-protected exit gesture instead of (or in addition to)
  two-finger tap.
