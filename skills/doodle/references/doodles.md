# The doodle box

Twenty six marks and twelve illustrations. Canonical geometry lives in `assets/doodle-sheet.html`, which is the single source. Open it, find the drawing, copy its `<g>`, wrap it in `transform="translate(X,Y) scale(S)"`. Do not retype the paths from this file, there are none here on purpose. One geometry, one place.

**Two tiers, and they are not interchangeable.** A **mark** is a 100 by 100 symbol standing for a noun, and a canvas uses several. An **illustration** is a 240 by 160 scene showing something happening, and a canvas uses one. The marks table is first, the illustrations table follows it.

To see every drawing at once, open `assets/doodle-sheet.html` in a browser. It is the contact sheet.

Every doodle is drawn inside a **100 by 100 box** with its origin at the top left, so `scale(0.6)` gives you a 60px mark and the placement maths never needs thinking about. The one exception is `tug of war`, which is 200 by 100 because two figures and a rope do not fit in a square.

## What each one means

A doodle earns its place the same way a diagram does. It has to say something the label next to it does not already say. If the mark is just a picture of the noun in the label, delete it.

| Mark | Box | Reach for it when |
|---|---|---|
| `bin` | 100 | Something is discarded, rolled back, or thrown away. Pair with a dashed arrow into it. |
| `eye` | 100 | Visibility, observation, what a component can see. |
| `eye, crossed` | 100 | Access denied or information withheld. The single most useful mark in a systems sketchnote, because a severed edge is usually the interesting one. |
| `warning` | 100 | A caveat that should stop the reader. Use once per canvas at most. |
| `lightbulb` | 100 | The finding. Not "an idea" generically, the specific thing this note exists to deliver. |
| `brain` | 100 | A model, reasoning, or memory. Resist using it for every mention of an LLM. |
| `figure` | 100 | A person, a user, a human baseline. |
| `tug of war` | 200 | Two forces pulling on one thing. A contested claim, a tradeoff with named sides. |
| `balance` | 100 | A tradeoff being weighed, drawn tilted so the reader sees which way it fell. |
| `gate` | 100 | A filter, a check, an accept or reject decision. Ships with one arrow through and one bounced off. |
| `book` | 100 | Documentation, a wiki, a knowledge layer. |
| `papers` | 100 | A corpus, traces, raw material, a dataset. |
| `speech` | 100 | Something claimed or stated, usually by a named party. |
| `thought` | 100 | Something suspected but not established. Good for open questions. |
| `starburst` | 100 | Surprise. The moment the number does not do what the reader expects. |
| `magnifier` | 100 | Inspection, verification, a research pass. |
| `clock` | 100 | Time, horizon, duration, how long something ran. |
| `scissors` | 100 | A cut, a pruning, something deliberately removed. |
| `funnel` | 100 | Narrowing. Many in, few out. |
| `key` | 100 | The mechanism that makes the thing work. |
| `lock` | 100 | Closed, gated, unreleased, private. |
| `sprout` | 100 | Growth and compounding. |
| `tick and cross` | 100 | Pass and fail side by side. Split it if you only need one. |
| `potted plant` | 100 | Pure flourish for a dead corner. The only decorative mark in the box, and it stays that way. |
| `flag` | 100 | A milestone or a claim planted. |
| `mountain` | 100 | Difficulty, a peak, a hard benchmark. |
| `the four arrows` | 100 | Straight, curved, dashed and loop-back. Not a doodle, a reference for the four arrow styles and what each means. |
| `highlighter, underline` | 100 | The two emphasis techniques. Highlighter is a fat lime stroke behind text with `mix-blend-mode: multiply`. Underline is a thinner magenta stroke at reduced opacity. |
| `bars` | 100 | A three-value trend. Scale by hand, label every bar, keep the baseline. |

## The illustrations

Twelve larger drawings, same file, below the marks. Geometry in `assets/doodle-sheet.html`, copied the same way.

**A mark is a noun. An illustration is a situation.** That is the whole distinction and it decides which one a beat wants. `figure` is a person. `the pile` is a person losing to their own reading list. `magnifier` is inspection. `inspection` is a document with a fault found in it. The second of each pair carries a verb and an outcome, which is why it can hold a beat on its own and a mark cannot.

Every illustration is drawn in a **240 by 160 box**, wider than tall, because scenes need horizontal room. `scale(1)` gives you a 240px drawing, which is roughly a fifth of a canvas.

| Illustration | Reach for it when |
|---|---|
| `desk` | Work being done by a person. A human baseline, an author, the labour a method replaces. |
| `the pile` | Collection with no stopping rule. The data dump, an unbounded corpus, reading that will never finish. The size contrast is the argument, so do not shrink the stack. |
| `shrug` | Indifference, and it is sharper than it looks. Not confusion, which is `thought`. This is the reader who understood you and does not care. |
| `handoff` | One stage feeding the next. Delegation, a pipeline boundary, a model passing work to a tool. Label the arrow with what is handed over. |
| `robot` | The agent itself, where a canvas needs to distinguish the agent from the human or the environment. Resist using it wherever an LLM is merely mentioned. |
| `confident and wrong` | An agent reporting success beside the mess it made. Usually the most-used illustration in any set of notes on agents or automation, because false confidence is such a common finding. |
| `podium` | A leaderboard or a ranking, especially where the ranking is the thing being questioned. |
| `black box` | A component nobody has looked inside. An unaudited verifier, a closed model, a judge validated against itself. |
| `inspection` | An audit that found something. The fault inside the lens is the point, so if nothing was found, use the `magnifier` mark instead. |
| `the wall` | A hard boundary. A capability ceiling, a paywall, a refusal, work that cannot proceed. |
| `signpost` | A decision with two named options. Put the option names on the two arms. |
| `filing cabinet` | Filed rather than understood. Collected and stored with nothing drawn out of it, and the right mark for a source that was saved but never really read. |

### Using one

**One illustration per canvas.** It is the second-loudest thing on the sheet after the magenta, and two of them compete rather than compound. A canvas wanting two illustrations usually wants two canvases.

**Draw it big.** At least 280px wide on a 1600 canvas, which is `scale(1.2)` or more. An illustration shrunk to mark size reads as a cluttered mark and loses everything it was for.

**Put it on a beat, not in a corner.** It belongs beside beat 5 or beat 1, doing work the prose would otherwise do. An illustration parked in dead space to fill it is decoration, which is the failure mode this whole format is most prone to, and the fix is deleting it rather than moving it.

**Marks still do the rest.** An illustration plus three or four marks is a normal canvas. An illustration plus another illustration is usually a mistake.

## Arrow grammar

Four styles, four meanings, and mixing them up costs the reader more than a missing doodle would.

| Style | Means |
|---|---|
| Solid navy | Normal flow. A leads to B. |
| Curved navy | Same, where a straight line would cross something. |
| Dashed magenta | A path that is refused, reverted, or blocked. |
| Loop-back magenta | Something that returns to where it came from, or grows in place. |

Label every arrow that is not obvious from the two boxes it joins. `writes`, `reverts`, `polls every 30s`. An unlabelled arrow means "related somehow" and that is not worth ink.

## Adding to the box

New marks go in `assets/doodle-sheet.html` in a free cell, drawn in a 100 by 100 box, then listed in the marks table with what it means. New illustrations go in the band below, drawn in a 240 by 160 box, then listed in the illustrations table. Keep the sheet publishable, because a doodle you cannot see is a doodle nobody will use.

Draw with `M` and `L` for anything straight, `A` arcs for circles, and `C` for organic curves. Keep path data short. The wobble engine adds all the character, so a long hand-tuned path is wasted work and a sign the mark wants to be simpler.
