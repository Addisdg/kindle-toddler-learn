# Release Checklist

Use this checklist for every Toddler Learn release. Automated success does not
replace physical Kindle and family testing.

## Automated checks

- [ ] Run `python3 -m py_compile generate_assets.py`
- [ ] Run `python3 generate_assets.py` and confirm no source asset is missing
- [ ] Run `./run-tests.sh` with all content, state, and screen smoke tests green
- [ ] Run `git diff --check`
- [ ] Confirm `git status --short` contains only intended release changes
- [ ] Confirm Learn, Puzzle, and Draw constructors load in the KOReader harness
- [ ] Confirm content and puzzle validators find every referenced PNG

## Desktop emulator

- [ ] Open the Toddler Learn mode chooser
- [ ] Enter Learn, answer correctly and incorrectly, then return with Modes
- [ ] Enter Puzzles, solve, reset, leave, resume, and verify the set counter
- [ ] Confirm three- and four-piece puzzles keep Modes/Next visible at 600 x 800
- [ ] Complete one Level 3 pattern and one Level 4 odd-one-out puzzle
- [ ] Enter Draw, test tap dots and continuous strokes at all brush widths
- [ ] Cycle all 19 Free, writing, shape, completion, and Mirror templates
- [ ] Trace A, F, 0, and 5 from their start dots and check finger tracking
- [ ] Confirm Eraser removes marks and Undo restores its last pass
- [ ] Confirm Undo, Redo, and two-tap Clear work
- [ ] Switch modes repeatedly and verify unfinished Puzzle and Draw state remains
- [ ] Confirm two-finger hold requires parent code `1234`
- [ ] Open Parent Setup and Progress and check all text fits

## Physical Kindle PW3

- [ ] Verify all controls fit at 1072 x 1448 without overlap
- [ ] Confirm puzzle pieces and Learn tiles are comfortable toddler touch targets
- [ ] Measure drawing latency and confirm strokes follow the finger acceptably
- [ ] Check drawing ghosting during strokes and after leaving Draw
- [ ] Draw continuously for ten minutes and check responsiveness and memory
- [ ] Confirm regional refresh does not produce missing stroke segments
- [ ] Verify the parent-code keyboard and masked input work
- [ ] Suspend and resume KOReader in each mode
- [ ] Confirm progress remains isolated among all three child profiles
- [ ] Check battery and screen behavior during a normal play session

## Child and caregiver validation

- [ ] Ask two adults to name every new picture without seeing its answer
- [ ] Observe at least three children choosing modes without coaching
- [ ] Record confusion, accidental taps, fatigue, and preferred activities
- [ ] Confirm mistakes are recoverable without adult intervention
- [ ] Review dashboard wording with caregivers for clarity
- [ ] Confirm grown-up-guided sound activities are understood as shared practice
- [ ] Feed observations back into content, layout, and difficulty before release
