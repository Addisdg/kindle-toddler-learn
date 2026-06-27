# Learning and Product Design

Toddler Learn is a local, distraction-free early-learning environment for an
e-ink Kindle. Its primary goal is to help a young child move from playful
picture recognition toward early reading and number sense without timers,
advertising, streak pressure, or an internet account.

The app complements, rather than replaces, conversation and shared reading
with an adult. The Paperwhite 3 has no speaker, so activities that depend on
hearing speech sounds must be marked as **grown-up guided**. Visual decoding,
spelling, connected-text reading, puzzles, drawing, and most maths activities
can be completed independently.

## Product model

The first screen is a simple mode chooser with three large choices:

1. **Learn** - the existing reading and maths activities.
2. **Puzzles** - visual, word, sequence, shape, and number puzzles.
3. **Draw** - free drawing plus optional tracing and completion activities.

Every mode must expose the same large **Modes** control. It opens the chooser
without leaving the plugin, so a child can switch activity at any time. Each
mode preserves its current state while another mode is open. Exiting to
KOReader remains a separate parent-only action protected by the parent code.

The chooser should use a clear icon and short label for each mode. It must not
look like a settings screen, contain nested menus, or require reading a
paragraph before choosing an activity.

## Teaching principles

- Teach in a deliberate sequence, but permit child-led exploration.
- Model one new idea at a time, then provide guided and independent practice.
- Prefer active recall over passive exposure: the child chooses, builds,
  spells, draws, or solves instead of only viewing an answer.
- Revisit learning over time. Mix mastered material lightly with newer or
  difficult material instead of treating one correct answer as mastery.
- Use immediate, calm, specific feedback. A wrong answer remains recoverable
  and never removes earned progress.
- Reduce prompts and hints as competence grows.
- Avoid speed scoring, countdowns, lives, punishment, and manipulative reward
  loops. Reward effort and completed practice at quiet intervals.
- Keep sessions child-paced and unlimited, while the parent dashboard reports
  useful progress without ranking children.
- Use familiar objects, inclusive names and pictures, and unambiguous prompts.
- Keep every interaction usable in grayscale with large touch targets.

These principles combine the Kindle-native restraint and local review model of
KAnki and KOReader Vocabulary Builder, the letter manipulation of Kindle's
Every Word, and the progressive phonics-to-story structure seen in Poio.

## Reading pathway

The guided curriculum should progress through these stages:

1. **Language and print awareness** - picture vocabulary, left-to-right order,
   and matching spoken words to objects with an adult.
2. **Sound awareness (grown-up guided)** - rhyme, syllables, first and final
   sounds, then identifying and blending individual sounds.
3. **Letter-sound links** - lowercase and uppercase matching, with emphasis on
   the sound represented by each letter rather than letter-name drilling alone.
4. **Decoding** - blend regular CVC words, then common digraphs and increasingly
   complex regular words in an explicit sequence.
5. **Encoding** - build and spell the same word patterns being decoded.
6. **Connected text** - read short decodable sentences and mini-stories every
   session, then answer literal picture-supported questions.
7. **Vocabulary and comprehension** - add naming, categories, sequence,
   prediction, and simple inference after the text itself is readable.

Words in spelling, sentences, and stories must only use sound-spelling patterns
already introduced by Guided Learning, apart from a small documented set of
explicitly taught irregular words. Reading and spelling should reinforce the
same pattern during a learning stage.

## Early maths pathway

Maths should move from concrete pictures to structured representations and
finally numerals or equations:

1. One-to-one counting and cardinality.
2. Recognizing small quantities without recounting and using five/ten frames.
3. Numeral-to-quantity matching, comparison, and ordering through ten.
4. Composing and decomposing numbers with number bonds.
5. Visual addition and subtraction through ten, followed by simple story
   problems using familiar objects.
6. Repeating and growing patterns, sorting, and classification.
7. 2-D shapes, spatial language, symmetry, position, and simple transformations.
8. Informal measurement and comparison of length, size, and capacity.

Prompts should encourage mathematical thinking such as "How many now?",
"Which has fewer?", and "What part is missing?" rather than only asking for a
symbol. Puzzle and drawing modes should reinforce spatial reasoning, patterns,
shape composition, and numeral formation.

## Puzzle mode

Dragging is unreliable on e-ink, so the primary interaction is **tap a piece,
then tap its destination**. Selected pieces receive a strong border. Initial
puzzles use two or four large pieces and progress only after reliable success.

Planned puzzle families, in suggested order:

- Picture halves and 2x2 picture assembly.
- Object-to-silhouette and related-picture matching.
- Put three story pictures or numbers in order.
- Complete a repeating shape or quantity pattern.
- Build a familiar word from letter chunks.
- Compose shapes and ten-frame or number-bond puzzles.
- Optional 3x3 picture puzzles after 2x2 mastery.

Each puzzle needs a deterministic solved state, a reset control, no timer, and
a maximum piece count appropriate to toddler-sized touch targets. Puzzle
progress is stored per child profile and participates in adaptive review.

## Drawing mode

Drawing has two distinct experiences:

- **Free Draw** is open-ended and never scored.
- **Practice Draw** offers optional paths for letters, numerals, shapes, and
  finish-the-picture activities. Guidance is encouraging rather than a strict
  handwriting grade.

The first version should provide a full-screen white canvas, one black brush,
three brush widths, undo, clear with confirmation, and return to Modes. Later
versions may add an eraser, save a small local gallery, tracing overlays, and
symmetry drawing. Controls remain fixed so canvas refreshes cannot move them.

Touch paths should be sampled and simplified before drawing. Refresh only the
changed canvas region during a stroke, then perform a cleaner refresh when the
stroke ends. Device testing must measure latency, ghosting, accidental palm
marks, memory use, and whether continuous touch events are available reliably.

## Adaptive learning and progress

Store progress separately for each child and activity. A useful record includes
attempts, independent correct answers, answers completed with hints, recent
errors, and last-practiced time. Mastery requires successful recall on more than
one occasion; hints do not count the same as independent answers.

Guided Learning should select mostly current-stage material, some targeted
review, and a small amount of mastered review. The parent dashboard should show
plain-language strengths, current focus, and suggested adult-guided activities,
not only an aggregate percentage.

## Architecture direction

Keep activity logic separate from the shared app shell:

- `main.lua` registers the plugin and parent tools.
- `appscreen.lua` owns the mode chooser, shared mode button, active
  child profile, parent-code exit, and state restoration.
- `gamescreen.lua` remains responsible for Learn mode.
- `puzzlescreen.lua` owns puzzle interaction and puzzle state.
- `drawscreen.lua` owns the canvas, stroke model, and drawing tools.
- `content.lua` remains declarative learning content; puzzle definitions should
  move to `puzzle_content.lua` once their schema stabilizes.
- Shared progress storage should use versioned records and provide migration
  from the current per-profile settings keys.

Do not combine all three modes into one growing screen class. Shared controls,
progress storage, and e-ink refresh helpers should be extracted only when two
implemented modes genuinely need them.

## Quality gates

Every new activity must pass automated content/state tests and a PW3 device
smoke test. Before release, verify:

- The child can enter and switch modes without adult help.
- The parent-code exit remains inaccessible without the code.
- Text, tiles, puzzle pieces, and tools do not overlap at PW3 dimensions.
- No activity depends on color, animation, sound, or precise dragging.
- All mistakes are recoverable and no activity traps the child.
- Progress remains isolated between profiles and survives an upgrade.
- Drawing remains responsive for at least ten minutes without memory growth.
- A caregiver can understand what the child is learning from the dashboard.

## Evidence base

- [IES Foundational Skills practice guide](https://ies.ed.gov/ncee/WWC/PracticeGuide/21/Published)
- [IES phonological-awareness teaching sequence](https://ies.ed.gov/learn/blog/phonological-awareness-sounds-reading)
- [NAEYC early-childhood mathematics position statement](https://www.naeyc.org/sites/default/files/globally-shared/downloads/PDFs/resources/position-statements/psmath.pdf)
- [NAEYC developmentally appropriate practice](https://www.naeyc.org/resources/position-statements/dap/statement-position)
- [Harvard Center on the Developing Child: brain-building through play](https://developingchild.harvard.edu/resources/handouts-tools/brainbuildingthroughplay/)
- [Head Start school-readiness domains](https://headstart.gov/school-readiness/article/head-start-approach-school-readiness-overview)
