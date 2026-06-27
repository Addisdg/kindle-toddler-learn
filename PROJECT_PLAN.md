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
Early reading and maths now follow structured categories through sentences,
quantities to ten, arithmetic to five, comparisons, ordering, and patterns.
Guided Learning turns the reading categories into a mastery-based curriculum.
The next product stage is defined in `LEARNING_DESIGN.md`: a shared child-facing
chooser for Learn, Puzzles, and Draw, backed by a more explicit reading and
maths curriculum. Planned features are not treated as complete until they pass
automated tests, emulator checks, and an on-device PW3 smoke test.

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
- [x] Two-finger hold opens a parent-code dialog and code `1234` returns to
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
- [x] Lock down KOReader gestures while the game is active (menu/back)
- [x] Protect two-finger-hold exit with a parent code

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

## Completed post-MVP foundations

- [x] Adaptive per-round practice and mastery-based Guided Learning
- [x] Decoding, spelling, sentence building, and decodable mini-stories
- [x] Counting, ten frames, number bonds, arithmetic, patterns, and shapes
- [x] Parent progress dashboard with category mastery and local-data reset
- [x] Three local child profiles with independent learning progress
- [x] Unlimited child-paced play and parent-code exit

---

## Phase 7 - Curriculum and progress model
**Goal:** Make the learning sequence explicit enough that new content cannot
silently introduce untaught reading or maths concepts.

- [ ] Add stable `skill`, `level`, and prerequisite metadata to every category
- [ ] Mark sound-dependent activities as `adult_guided`
- [ ] Define the taught phonics sequence and documented irregular-word set
- [ ] Validate sentence and story words against introduced patterns
- [ ] Align reading and spelling rounds at each guided stage
- [ ] Expand maths stages through visual addition/subtraction to ten, spatial
      reasoning, sorting, measurement, and simple story problems
- [ ] Track independent, hinted, and incorrect attempts separately
- [ ] Add last-practiced time and versioned progress migration
- [ ] Test stage unlocking, review selection, and content prerequisites

**Done when:** every Learn activity reports what it teaches, what comes before
it, and whether the child can use it without adult audio support.

---

## Phase 8 - Shared mode shell
**Goal:** Let a child switch among Learn, Puzzles, and Draw at any time without
leaving the plugin or entering an adult menu.

- [ ] Introduce `appscreen.lua` as the shared mode router
- [ ] Build a first-screen chooser with large Learn, Puzzles, and Draw choices
- [ ] Add the same large Modes control to every activity screen
- [ ] Preserve each mode's unfinished state while switching
- [ ] Keep profile selection, progress storage, and parent-code exit shared
- [ ] Show a clear "Coming soon" state until a planned mode is functional
- [ ] Test repeated mode switching, state restoration, and parent-code exit
- [ ] Verify the complete chooser and controls at PW3 resolution

**Done when:** a toddler can move between all implemented modes independently,
and cannot accidentally reach KOReader or parent settings.

---

## Phase 9 - Puzzle mode MVP
**Goal:** Deliver useful spatial and learning puzzles without relying on
e-ink-unfriendly dragging.

- [ ] Define and validate `puzzle_content.lua`
- [ ] Implement tap-piece, tap-destination placement with strong selection
- [ ] Add reset and recoverable incorrect-placement behavior
- [ ] Start with picture halves and 2x2 picture assembly
- [ ] Add three-step sequencing and repeating-pattern completion
- [ ] Add word-chunk, shape-composition, and number-bond puzzle families
- [ ] Progress from two pieces to four, then optional 3x3 puzzles
- [ ] Store mastery separately per puzzle, child, and hint level
- [ ] Test solved-state logic, duplicate taps, reset, and state restoration
- [ ] Device-test touch target size, ghosting, and refresh frequency

**Done when:** every puzzle can be solved, reset, left, and resumed using taps
alone, with no timer and no ambiguous piece placement.

---

## Phase 10 - Drawing feasibility and MVP
**Goal:** Prove responsive touch drawing on PW3 before expanding into tracing.

- [ ] Build a diagnostic screen for continuous touch coordinates and pressure
- [ ] Measure event rate, latency, ghosting, and memory use on the Kindle
- [ ] Define a stroke model with point sampling and path simplification
- [ ] Refresh only the changed canvas region during a stroke
- [ ] Implement a fixed full-screen canvas and one black brush
- [ ] Add three brush widths, undo, and confirm-before-clear
- [ ] Preserve the drawing while switching modes
- [ ] Run a ten-minute drawing and memory stability test on-device
- [ ] Add optional letter, numeral, and shape overlays only after free draw is
      responsive
- [ ] Keep Free Draw unscored; use gentle guidance rather than strict tracing
      grades

**Done when:** finger drawing feels immediate enough for a toddler, controls do
not shift, and extended drawing does not leak memory or leave severe ghosting.

---

## Phase 11 - Learning quality and family testing
**Goal:** Verify that the larger app is understandable, educational, and calm
for real children and caregivers.

- [ ] Add parent-dashboard explanations for current focus and suggested review
- [ ] Balance new, difficult, and mastered activities in Guided Learning
- [ ] Add optional child-friendly demonstrations before each new interaction
- [ ] Test naming agreement and cultural clarity for every picture
- [ ] Observe at least three children using the mode chooser without coaching
- [ ] Record confusion, accidental taps, fatigue, and preferred activities
- [ ] Review progress data with caregivers for clarity and usefulness
- [ ] Re-test parent-code safety and profile isolation after migrations
- [ ] Document a release checklist covering emulator and Kindle verification

**Done when:** children can choose and complete activities with minimal help,
and caregivers can accurately describe the skills being learned.

## Deferred ideas

- Persistent parent setup preferences across app launches
- A parent gesture that opens setup without returning to KOReader's menu
- A small local drawing gallery after storage and privacy behavior are tested
- External audio support only if a dependable PW3 hardware path is established
