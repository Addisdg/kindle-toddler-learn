# Project Plan — Toddler Learn

A phased roadmap so this stays manageable as a side project. Each phase
has a small, testable "done when" goal — don't move to the next phase
until the current one runs cleanly in the emulator.

Status note: the first on-device MVP is complete. The post-MVP upgrade
work has added polished layout, categorized content, difficulty selection,
parent setup, rewards, expanded generated assets, caption-free reading rounds,
large resettable spelling controls, and content validation. The latest UI
revision has been smoke-tested successfully on the Kindle.
Adaptive review now stores per-round correct and incorrect counts locally.

---

## Phase 0 — Environment setup
**Goal:** Be able to run KOReader's desktop emulator and see your plugin
folder recognized.

- [ ] Jailbreak the Kindle with LanguageBreak (firmware 5.16.2.1.1)
- [ ] Install KUAL on the device
- [ ] Install KOReader on the device, confirm it launches via KUAL
- [ ] Clone `koreader/koreader`, run `./kodev fetch-thirdparty && ./kodev build`
- [ ] `./kodev run` opens the emulator window successfully
- [ ] Symlink `toddlerlearn.koplugin` into the emulator's `plugins/` dir

**Done when:** emulator boots without errors related to the new plugin
folder (it's fine if the menu entry doesn't exist yet).

---

## Phase 1 — Plugin loads & shows a menu entry
**Goal:** "Toddler Learn" appears in the KOReader menu and tapping it
shows *something* (even a blank screen) that can be closed.

- [ ] `_meta.lua` is read correctly (plugin shows up with the right name)
- [ ] `main.lua` registers a menu item without Lua errors
- [ ] Tapping the menu item opens `gamescreen.lua`'s widget
- [ ] Two-finger tap (or your chosen gesture) closes it and returns to
      the menu without crashing

**Done when:** you can open and close the game screen repeatedly with no
errors in the terminal.

**Likely debugging needed:** widget require paths, constructor argument
names (`Geom`, `GestureRange`, `FrameContainer`, etc.) — KOReader's API
has shifted over versions. Fix based on the actual error text; the
KOReader source tree (`frontend/ui/widget/`) is the ground truth.

---

## Phase 2 — Static round renders
**Goal:** The first round from `content.lua` renders: a prompt at the top
and 3 image tiles below, using placeholder images.

- [ ] Add 3 placeholder PNGs (any images) to `assets/animals/`
- [ ] `gamescreen.lua` builds the layout from `content.lua` round 1
- [ ] Prompt text and tiles are visible and roughly centered
- [ ] Tile sizes look reasonable on the emulator's screen size

**Done when:** the layout looks like a usable game screen, even with
placeholder art.

---

## Phase 3 — Tap detection & round progression
**Goal:** Tapping the correct tile advances to the next round; tapping a
wrong tile does nothing harmful.

- [ ] Each tile registers a tap gesture
- [ ] Correct tile → `loadRound()` advances to the next round
- [ ] Wrong tile → no crash, round stays the same
- [ ] Rounds shuffle order at the start of a session
- [ ] After the last round, it loops back to the first (re-shuffled)

**Done when:** you can play through all rounds in `content.lua` using
only taps, in the emulator.

---

## Phase 4 — Real content
**Goal:** Replace placeholders with real images for the categories you
care about.

- [ ] Decide which categories to start with (suggest: animals + fruit)
- [ ] Source/create images per `CONTENT_GUIDE.md` specs
- [ ] Add corresponding entries to `content.lua`
- [ ] Spot-check each round in the emulator

**Done when:** every round in `content.lua` has real, correctly-sized
images and reads/looks right for a toddler.

---

## Phase 5 — E-ink polish
**Goal:** Make it pleasant on the actual e-ink screen, not just the
emulator.

- [ ] Use partial refresh for tile taps, full refresh once per round
- [ ] Add simple "correct!" feedback (e.g. a checkmark overlay, brief
      invert) before advancing
- [ ] Confirm touch targets are big enough for small fingers
- [ ] Lock down KOReader gestures while the game is active (menu/back)
- [ ] Decide on and implement the exit gesture/PIN

**Done when:** a non-technical adult could hand the Kindle to a toddler
and they could play without getting lost in KOReader's UI.

---

## Phase 6 — Deploy & real-world test
**Goal:** Running on the actual Kindle, used by an actual toddler.

- [ ] Copy plugin + real assets to the Kindle's `koreader/plugins/`
- [ ] Confirm menu entry and gameplay work on-device
- [ ] Check battery drain / screen behavior over a real play session
- [ ] Note any UX issues observed and feed back into `content.lua` /
      `gamescreen.lua`

---

## Backlog / ideas for later

- Persistent parent preferences across app launches
- A hidden in-game parent gesture that opens setup without returning to
  KOReader's menu
- Audio via a USB-attached speaker hack (probably not worth it on PW3)
- Tracking simple stats (rounds completed) shown only in a debug menu
- Letter-tracing mode using touch-path drawing instead of tap-to-select
