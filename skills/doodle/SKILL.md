---
name: doodle
description: Draw a source as a hand-drawn sketchnote. One canvas, marker lettering, doodles and arrows, read spatially rather than top to bottom. Turns a paper, a set of notes, or any dense argument into a single image whose layout carries the reasoning. Use when the user says doodle, sketchnote, sketch this, draw this out, visual explanation, or asks for a one-page visual summary of something.
argument-hint: "[paper, notes, link, or topic] [optional: --arc to see the beats before drawing]"
---

# /doodle

Turn one source into one canvas that a person can stand in front of and understand.

A sketchnote is not a prettier summary. It is a **different retrieval mechanism**. Prose is read in sequence and remembered as a gist. A sketchnote is read spatially and remembered as a picture, so putting two numbers next to each other under one highlighter swipe makes an argument land in about a second that a paragraph and a chart needed half a page for. That adjacency is the whole reason the format is worth the work.

It draws an understanding that already exists. Reading the source properly is a separate job, and `/doodle` makes one finding from that reading unforgettable. It never establishes anything new.

---

## 1. What this is not

| Not | Why |
|---|---|
| A summary of the source | A summary covers. A sketchnote **selects**. Five or six beats, and everything else is left out on purpose. |
| An infographic | Infographics decorate numbers. Here the layout is the argument, and a mark that carries no meaning is deleted. |
| A place for new claims | Every number on the canvas comes from the source or from notes already checked against it. `/doodle` draws, it does not conclude. |
| A diagram | Boxes, arrows and marker lettering with no drawing in them is a slide. If the canvas has no illustration on it, say why rather than shipping it. |
| An edit to anything else | It produces one image, and at most one embed line on the note it illustrates, see section 8. The reading it draws already lives somewhere. |

If the source has not been read properly yet, stop and say so. Drawing an unverified reading in marker pen makes it more memorable, not more true, which is the worst possible failure mode for this format.

Drawing from a first reading is allowed, because a canvas that waits for a full verification pass is a canvas most sources never get. What makes it safe is saying so: record what the canvas rests on (a first reading, a checked one) wherever it is filed, and expect to redraw it when the reading moves.

---

## 2. Find the arc first, before any geometry

This is the step that decides whether the canvas is good, and it is entirely a reading problem rather than a drawing one.

**Five to seven beats. No more.** A sketchnote with nine ideas has none.

### The paper arc

For a paper, a codebase, or anything reporting a result, in the order the eye should hit it:

1. **The setup.** What was broken, in one sentence a non-specialist gets.
2. **The mechanism.** The one structural move that defines the thing. Usually a boundary, an asymmetry, or a severed edge.
3. **The loop or the process.** How it actually runs, with the real numbers on it.
4. **The result.** The headline, drawn so the shape of it is visible.
5. **The twist.** The thing the reader does not expect. Often a subtraction, a reversal, or a number that lands somewhere suspicious.
6. **The catch.** What is unvalidated, unreleased, or untested. This is not optional. A sketchnote without its caveat is marketing.

### The book arc

**A book has no result, and forcing one produces a bad canvas.** Beats 3 and 4 above assume a measurement and a headline. A methods book, a textbook, or any source arguing a position has neither: no experiment ran, no artifact shipped, and its numbers are counts of its own machinery rather than findings. Written as a paper, the canvas ends up drawing section headings.

Use this instead:

1. **The trap.** What goes wrong for someone who does not have the idea. The failure the book was written against.
2. **The apparatus.** The named machinery it hands you, with the count on it. Three steps, five elements, ten criteria.
3. **The shape.** How that machinery is arranged, which is usually the part worth drawing. A nesting, a ladder, a two-part structure.
4. **The worked case.** The book's own demonstration, taken at its word and drawn as it stands.
5. **The twist.** The consequence the book does not draw itself, or the place its own example undercuts it.
6. **The catch.** For a book this is almost always the same shape, and it still has to be said: the claims rest on authority rather than evidence, and the edition may have been superseded.

Two things change beyond the beats.

**The numbers mean something different.** *Prefer the number to the adjective* still holds, but a book's numbers count its own parts rather than measuring the world. `5 elements` and `10 criteria` are worth putting on the canvas. They are not evidence and must not be drawn as though they were, so keep them out of the highlighter.

**Liveness is edition, not artifact.** A paper's catch asks whether the released code still exists. A book's asks which edition this is and whether a later one has landed, which is the same staleness question wearing different clothes.

Anything that is neither, an article, a standard, a transcript, takes whichever arc fits what it actually does: reports a result, or argues a position.

Beat 5 is the canvas. It gets the biggest type, the highlighter, and the empty space around it. Everything else is support. **If you cannot name beat 5, you do not have a sketchnote yet**, you have a poster of section headings, and the honest move is to say so rather than draw one anyway.

Offer the arc before drawing when the user passes `--arc`, or whenever the source is one you have not discussed with them in this session. It is cheap to redraw a beat and expensive to redraw a canvas.

---

## 3. The canvas contract

**1600 by 900, viewBox `0 0 1600 900`.** Landscape, because sketchnotes are read on a screen or a wall and never scrolled. A 20px hand-drawn frame sits inset at `M22,22 L1578,22 L1578,878 L22,878 Z`.

Divide it into named regions and **write the x-bounds down before placing a single element.** Something like:

```
header   x 46..1562   y 30..190
panel A  x 46..560    y 226..600
panel B  x 596..1085  y 226..620
panel C  x 1120..1560 y 226..600
panel D  x 46..1085   y 640..865
panel E  x 1108..1566 y 606..858     the night block
```

### The gutter rule

**SVG text does not wrap and it does not collide-detect. It runs straight under whatever is next to it and the browser reports nothing.** A text block running 32px under a dark panel is invisible until someone looks at the render.

So: before placing any `<text>`, estimate its width and check it against its region's right bound.

```
width ≈ characters × factor × font-size

Permanent Marker   0.62
Caveat 700         0.44
Shantell Sans 400  0.53
Shantell Sans 700  0.55
```

Worked example of the bug: `"the ReAct proposer, one change per turn, the"` is 44 characters at 18px Shantell Sans, so 44 × 0.53 × 18 = 420px. Placed at x=712 it ends at 1132, and the panel beside it started at 1108. Rewrapping to 39 characters at 17px gives 351px and ends at 1061, clearing by 47.

**Every string has two bounds, and they fail differently.** The **region** bound is the neighbouring panel, and breaching it puts text under someone else's fill. The **container** bound is the box the text sits inside, and breaching it puts text out in open paper looking like a mistake. Neither is visible in the source.

**Check both on every string.** A label inside a 290px box has maybe 260px of usable width once the 18px inset is taken off each side, which at 15px Shantell Sans is 32 characters. That is much less than it feels like when writing the string.

**Widen or wrap, and the surroundings decide which.** Look at what sits immediately right of the container first. If boxes end at x=336 with arrows leaving at 340 and a bin at 430, there is nothing to widen into and wrapping is the only move. Where a box does have room, growing it is the better fix because it keeps one line and one reading order.

**Wrapping means splitting into separate `<text>` elements**, since SVG has no line-breaking. Two shapes work:

- **Stacked**, a second line 22 to 24px below the first at the same x. Plain, and right for a continuing sentence.
- **Promoted**, where the emphatic half moves up onto the name line at a fixed x offset. This is usually better than stacking, because it puts the word that matters beside the thing it qualifies. `skills/  REVERTS on reject` on one line reads harder than the same words wrapped below.

**Emphasis colour is constrained by the fill under it.** Magenta on paper is about 4.9 to 1 and fine at 15px bold. The same magenta on the lime fill is 3.2 to 1 and fails, so on a lime box the emphasis goes navy. Check the pairing rather than assuming the accent works everywhere.

**Measure mechanically before publishing.** Reading coordinates back does not catch this, and neither does looking at the render, because a 4px overflow is invisible until it is not. Run every string through the formula against both bounds in one pass:

```python
F = {"sh400": 0.53, "sh700": 0.55, "cv": 0.44, "mk": 0.62}
def ends(text, size, face, x, anchor="start"):
    w = len(text) * F[face] * size
    return {"start": x + w, "middle": x + w / 2, "end": x}[anchor]
# assert ends(...) < container_right < region_right for every label
```

Two more traps in the same family:

- **`text-anchor="end"` measures leftward.** Check the left bound, not the right.
- **Rotated text runs along an axis you have to work out.** With `transform="rotate(-90 cx cy)"` and default anchor, the string runs from `cy` upward to `cy - width` at x = `cx`, and the glyph body sits at x from `cx - fontsize` to `cx`. Check both.

---

## 4. The visual system

Paste `assets/tokens.css` into the page's `<style>`. The whole palette and the three faces are in there. Summary:

**Single theme, always.** A sketchnote is ink on paper. Only the surround outside the sheet follows the viewer's theme, so the artwork holds on a dark or light host ground without flipping. This is a deliberate exception to the usual both-themes rule and it is the one case where it is right.

**Palette.** Paper `#FCFBF4`, ink navy `#22235C`, shout magenta `#EE1D66`, second periwinkle `#7C7FE8`, mark lime `#CBF25C`, soft blush `#F8CADB`, night `#16173C`, and mint `#3FD5A8` for organic flourishes only.

**Spend the magenta once.** It belongs to beat 5 and to reject-or-danger arrows. The moment it appears in four places the canvas has no focus and reads as noise. Same discipline as an accent colour anywhere else, just louder.

**Three faces, three jobs, never a fourth.**

| Face | Job | Sizes |
|---|---|---|
| Permanent Marker | Shouts. Title, panel headings, the big numbers. | 28 to 84 |
| Caveat 700 | Annotates. Arrow labels, asides, the punchline under a panel. | 22 to 30 |
| Shantell Sans | Is actually read. Box contents, data labels, the caveat list. | 14 to 21 |

All three are free Google Fonts, loaded with one `<link>` (see the top of `assets/doodle-sheet.html`). Nothing below 14px. A sketchnote that needs zooming has failed at its one job.

**Grain.** A `feTurbulence` rect at `opacity .055` with `mix-blend-mode: multiply` over everything, `pointer-events="none"`. Cheap, and it stops the canvas reading as vector clip art.

---

## 5. The linework

Everything is `<path>`. Boxes are `M/L/L/L/Z`, circles are two `A` arcs. **Never `<rect>`, `<circle>` or `<ellipse>`**, because `getTotalLength` is not guaranteed on them and the engine needs it.

Mark each path `data-sketch="2"` for the standard double-drawn look, or `"1"` for a single stroke on thin things like tick marks and short arrows. `data-amp` tunes the wobble, default 2.2, use 3 or 4 on long lines and 1.4 on small details.

Paste `assets/sketch.js` inline and call `sketchify('#note')` at the end. It is about 50 lines and it degrades honestly: if the script never runs the page still reads, in clean lines instead of drawn ones, which is exactly why the geometry lives in the markup rather than in JS.

Doodles come from `references/doodles.md` and `assets/doodle-sheet.html`, in two tiers. **Take the drawing that means the thing.** A doodle that is just a picture of the noun beside it is decoration, and decoration is the failure mode this whole format is most prone to.

| Tier | Box | Count | Per canvas |
|---|---|---|---|
| **Marks** | 100 by 100 | 26 | several. Symbols standing for a noun: `bin`, `gate`, `funnel`, `clock` |
| **Illustrations** | 240 by 160 | 12 | **one**. Scenes showing something happening: `the pile`, `confident and wrong`, `filing cabinet` |

**A canvas of marks and text reads as a diagram, which is the most common way this format fails.** Marks are labels. They sit beside a heading and confirm it, and a sheet made only of them is a slide with wobbly borders. An illustration carries a verb and an outcome, so it can hold a beat by itself, and it is what makes a sketchnote look drawn rather than assembled.

So: **one illustration per canvas, at `scale(1.2)` or larger, placed on a beat.** Usually beat 5, occasionally beat 1 where the trap is more vivid than the twist. Two illustrations compete rather than compound, and an illustration shrunk to mark size loses everything it was for. Marks fill in around it as normal.

---

## 6. Build order

1. **Read the source fully**, or your notes on it if they were checked against it. Not an abstract, not a summary. Every number that reaches the canvas is one you have seen in context.
2. **Write the arc.** Five or six beats, beat 5 named explicitly. Show it to the user if `--arc` or if this source has not been discussed.
3. **Write the region table** with x-bounds, before any element.
4. **Place structure**, so panels, boxes and arrows. Check bounds as you go.
5. **Place text**, running the width estimate on every string against both its container bound and its region bound.
6. **Place the one illustration first**, on its beat and at full size, then **add marks** around it, only where each carries meaning.
7. **Spend the magenta once**, on beat 5.
8. **Read every string back** against the source. A drawn number is harder to doubt than a written one, so it has to be right.
9. **Run the width pass** over every string, against its container bound and its region bound.
10. **Render it and look at it.** See section 8. Fix what only the picture shows, then re-render.
11. Save the WebP per section 8, and report which beat carries the canvas and what was left out.

Write the canvas as one standalone HTML file. If the harness can publish HTML pages (an artifact or page-publishing tool), publish it and hand back the link, keeping the same address across redeploys. If it cannot, the HTML file you wrote is the master: keep it beside the WebP so the canvas can be edited later.

---

## 7. Copy rules

The lettering is still writing, and these hold on every string.

- **No em dashes and no en dashes.** A full stop, a comma or a colon instead.
- **No semicolons** in prose. Code and CSS keep theirs.
- **No hard wraps** in the source of any prose. SVG `<text>` lines are separate elements, which is not the same thing as wrapping a paragraph.
- Lowercase reads as handwriting and uppercase reads as a shout. Use uppercase for headings and the odd emphasised word, never for a sentence.
- Prefer the number to the adjective. `+23.9` beats `much better`, and it is the kind of thing this format is best at carrying.

If the project has its own writing rules, they apply on top of these.

---

## 8. Provenance, saving, and rendering

**Mark what is the source's and what is yours.** A hand-drawn canvas is the easiest place in the world to lose track of where a claim came from.

Any reading that came from you or your notes rather than from the source carries a line saying so, in Caveat, near the thing it qualifies. For example: `we computed this across two of the paper's tables. the paper never says it.` That is an attribution on a specific claim and it stays, because without it the canvas silently presents your reading as the author's.

**No credit or provenance footer.** A bottom strip naming the source, the date and the reading depth reads as clutter on the artwork. The canvas identifies its source in the header pill and that is enough.

What this gives up is the freshness stamp, so nothing on a canvas says when its numbers were last true. That is a real cost only where a number rests on something that moves, such as a leaderboard reading or a current version. **Where a canvas carries a live number, date it inline beside the number** rather than in a footer, in the form `as of 2026-08`. A closed paper needs no date at all.

### Saving it

Save the rendered canvas as `doodle-<slug>.webp`, where `<slug>` is the slug of the note or source it draws. The `doodle-` prefix keeps the image from sharing a name with the note itself, which in a wiki-linked notes vault produces a link that looks right and resolves to the wrong file.

Where it goes is the project's call. In a notes vault, put it in the folder that holds generated images, kept apart from anything clipped from the source, since one is yours to redraw and the other is a record of what was published. With no project to file into, save it in the working directory and tell the user the path.

If it illustrates a note, embed it directly under the note's H1, above everything else, so it is the first thing on the page. If the note carries frontmatter, record the view so its staleness can be seen later:

```yaml
views:
  - kind: doodle
    file: doodle-<slug>.webp
    url: <published page> | null    # where the HTML master lives, if it was published
    rests_on: first reading | checked | re-checked
    made: YYYY-MM-DD
```

`rests_on` is the staleness mechanism. A view freezes the moment it is made while the note under it keeps being revised, and unlike prose it cannot be patched, only remade. Recording what it was drawn from is what lets the gap be seen. Never copy the note's current state in without checking, because a view claiming a reading it does not have is worse than one honestly marked `first reading`.

**Nothing is ever cited to a doodle.** It is a picture of a reading that already exists elsewhere, so a claim traces to the note and through it to the source. A canvas is also frozen at render time while the note under it keeps moving, which is the second reason.

**Remaking a doodle**, when a later reading moves what the canvas shows. Get the HTML master back, from the published page or from the file kept beside the WebP. Edit the strings or panels that changed, run the width pass over every changed string, re-render, look at the render, and republish to the same address if it was published. Then re-shoot the WebP over the old one and update `rests_on` and `made`. A remake is the same file at the same address, never a second canvas. If the master is gone, redraw from the source, which is what a view is anyway.

### Rendering

The canvas is SVG whose wobble is generated at runtime, so the file cannot simply be copied as an image. **WebP, not SVG**, and the reason is type rather than geometry: the three faces are web fonts and are normally not installed locally, so an SVG opened in another app falls back to a system cursive and the design collapses. WebP renders identically everywhere at roughly a seventh of the equivalent PNG.

Strip the surround chrome first, then shoot the canvas at 2x with headless Chrome or Chromium:

```sh
# from the canvas HTML, produce a render variant: body padding to 0, .sheet fixed at
# 1600x900 with no shadow, svg fixed at 1600x900, .meta hidden
#
# CHROME is the browser binary for your OS, for example:
#   macOS    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
#   Linux    google-chrome  or  chromium
#   Windows  "C:\Program Files\Google\Chrome\Application\chrome.exe"
"$CHROME" \
  --headless=new --disable-gpu --hide-scrollbars \
  --virtual-time-budget=10000 --force-device-scale-factor=2 \
  --window-size=1600,900 --screenshot=doodle.png "file://$PWD/render.html"

cwebp -q 88 -m 6 doodle.png -o doodle-<slug>.webp
```

`cwebp` comes with Google's `libwebp` (`brew install webp`, `apt install webp`). `--virtual-time-budget` matters. Without it Chrome shoots before the webfonts land and before `sketchify` has run, and the result is Comic Sans on clean lines with no warning that anything went wrong.

**Look at the render before saving it.** Not the source, the actual image. This is not optional and it is not the same check as section 3. The width formula catches a string overrunning a bound. It cannot catch an arrow drawn through a heading, a doodle that reads as the wrong object, or a wobble amplitude that turned a box into a scribble. Only the render shows those.

---

## 9. Files

```
doodle/
  SKILL.md
  assets/tokens.css          palette, the three faces, the sheet chrome
  assets/sketch.js           the wobble engine, paste inline
  assets/doodle-sheet.html   26 marks and 12 illustrations, canonical geometry. Open it in a browser to see them
  references/doodles.md      what each drawing means, the two tiers, and the arrow grammar
```

The visual system in sections 3 to 5 works for any subject. The arc in section 2 assumes there is a source with an argument to draw, and section 8 assumes there is somewhere to file the image, so both bend to whatever the project has.
