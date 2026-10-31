---
name: one-pager
description: Write a source as a short editorial explainer, as one standalone HTML page. Layered prose that states each idea plainly and then precisely, with diagrams for the mechanisms and marked boxes wherever your notes disagree with the source. The readable companion to a doodle. Requires the imax-view skill. Use when the user says one-pager, explainer, write this up, explain this properly, summarise this for someone, or asks for a readable version of a paper.
argument-hint: "[paper, notes, link, or topic] [optional: --outline to see the sections before writing]"
---

# /one-pager

Turn one source into a page someone can read in five minutes and come back to in a year.

Sibling to `/doodle`, and the two are not interchangeable. A doodle is read spatially and remembered as a picture, so it carries **one** finding and makes it unforgettable. A one-pager is read linearly and returned to, so it carries the **whole argument** and makes it followable. A source can want both, either, or neither.

| | `/doodle` | `/one-pager` |
|---|---|---|
| Form | one canvas, an image | a scrolling document |
| Job | one finding, unforgettable | the whole argument, followable |
| Needs | a nameable surprise | a mechanism worth explaining |
| Fails when | there is no surprise | it restates the notes |

---

## 0. Requires `imax-view`

This skill has no visual system of its own on purpose. The page's frame, type, spacing, palette and accent discipline all come from the **`imax-view`** skill, and a second copy here would drift away from it.

**Before anything else, check that `imax-view` is available** in the session's skill list. If it is not:

1. Stop before writing any HTML.
2. Tell the user that `/one-pager` needs the `imax-view` skill, and suggest they install it into their skills folder (for Claude Code, `~/.claude/skills/imax-view/` or the project's `.claude/skills/`) and start a new session.
3. Offer to go ahead with the parts that do not need it: the outline and the plain sentences from section 5, steps 1 and 2. Write no page until the user either installs it or explicitly says to proceed without it. If they do, say on the finished page's report that it was built without the house style.

Never improvise a substitute palette or type scale to fill the gap. A page in an invented style looks finished and is wrong.

---

## 1. The register, which is the whole trick

The obvious way to write an explainer is to make it simpler. That is wrong here, because the value of careful notes is precision and a simplified page throws away the part worth keeping.

**Layer it instead.** Every section opens with one plain sentence that a non-specialist gets, set against an accent rule. The precise version follows underneath. Nothing is softened, it is approached twice.

```
The problem, in one move
  plain:    An agent tries something, it fails, so you undo it. The trouble is
            that undoing the change also undoes knowing why it failed.
  precise:  Methods that evolve agent skills from execution traces all run the
            same outer loop. What differs is what survives the throwing away.
  note:     We checked this and it is narrower than stated. Two of the three
            named baselines already persist something across iterations.
```

That third element is not decoration. **A marked box wherever your reading disagrees with the source** is what makes this a page of considered notes rather than a summary of a paper. Without it the page silently presents your reading as the author's.

---

## 2. What it is not

| Not | Why |
|---|---|
| A summary of the notes | Notes on a source are a **reference**, exhaustive and templated. This is an **explainer**, selective and argued. If the one-pager can only be written by restating the notes, do not write it. |
| A place for new claims | Every number already exists in the source or in notes checked against it. This explains, it does not conclude. |
| Long | Six sections is the ceiling. A five minute read. Past that it is competing with the source and losing. |

---

## 3. Shape

Six sections at most, in this order. Drop any that has nothing to say rather than padding it.

1. **Hero.** Title, a one-sentence thesis, and three numbers that frame the piece.
2. **The problem.** What was broken. Short.
3. **The mechanism.** The structural move that defines the thing. Almost always wants a diagram.
4. **The process.** How it runs, with the real numbers on it.
5. **The result and the twist.** The headline, then the thing the reader does not expect.
6. **The caveat.** What is unvalidated, unreleased, or untested. Never optional.

Then a closing block, **How to read this page**, separating what the source claims from what you concluded, and naming the source and any related notes. This is the piece's provenance and it is the reason the page can be sent to someone.

---

## 4. Visual system

**Follow `imax-view`** (see section 0). Do not restate its palette or type scale here and do not invent a second one. It owns the frame ratio, the monospace stack, the type roles, the spacing ramp, and the accent discipline. This skill owns only what is above and below it.

Three things this piece does inside that system:

- **A 1.43:1 hero**, then a free-height scrolling document on the 15 column grid. `imax-view` permits free ratio for long documents and this is one.
- **One signature, not three.** The perf rail down the left marking sections works well here because a one-pager genuinely has sections, so the rail encodes something true.
- **Spend the accent on the plain-language rules and one number.** A halation rule beside each opening sentence is what makes the layered register visible at a glance. If the accent also fills buttons and headings the layering stops reading.

**Diagrams.** A diagram earns its place when it shows a mechanism the prose has to assemble in the reader's head. Draw the boundary being crossed, the hop being added, the edge that disappears when a component is removed. Three diagrams is usually right for six sections, and a fourth is usually decoration. Draw them as inline SVG that inherits the `imax-view` tokens. If a diagramming skill is available, use it for the mechanics, with `imax-view` winning where they disagree.

**Charts.** If a data-visualisation skill is available, follow it. Either way, watch the axis: a truncated axis on bars is dishonest, and the fix is a dot plot rather than a note under the figure.

---

## 5. Build order

1. **Read the source fully**, or your notes on it if they were checked against it. Every number on the page is one you have seen in context.
2. **Write the section list**, with the plain sentence for each already drafted. Show it if `--outline`, or if this source has not been discussed in the session. The plain sentences are the piece, and they are cheap to redo now and expensive later.
3. **Confirm `imax-view` is loaded** (section 0), then load any diagramming or page-design skills the session has. `imax-view` wins where they disagree.
4. **Write the file as a complete standalone document**, never as a fragment: `<!doctype html>`, `<html lang="en">`, a `<head>` holding `<meta charset="utf-8">`, `<meta name="viewport" content="width=device-width, initial-scale=1">`, the `<title>`, any web font `<link>`, then a small reset as its own `<style>` block, then the page's own `<style>`, and a `<body>` closed by `</body></html>`. A reset that matches most page hosts: `:root{color-scheme:light}body{margin:0;padding:0;font:14px -apple-system,BlinkMacSystemFont,sans-serif;background:#faf9f5;color:#141413}img{max-width:100%}[hidden]:not([hidden=until-found]){display:none!important}`. Nothing in the page may depend on a hosting runtime, since the saved copy is opened with a double-click and has none. A fragment renders fine inside a host's wrapper and breaks only when opened from disk, and a page with non-ASCII characters and no `charset` makes the browser guess the encoding.
5. **Open the file from disk and look at it.** Headless Chrome or Chromium (`--headless=new --screenshot=page.png --window-size=1440,2400 "file://$PWD/<file>.html"`) is enough. This is the only check that catches the fragment and encoding faults above.
6. **Publish if the harness can.** If it has an artifact or page-publishing tool, publish the same full document and hand back the link. If not, the saved HTML file is the deliverable, so tell the user its path.
7. Save it per section 6.
8. Report what the piece argues and which sections were dropped.

---

## 6. Saving it

Save the page as `onepager-<slug>.html`, where `<slug>` is the slug of the note or source it explains. The `onepager-` prefix keeps the file from sharing a name with the note itself, which in a wiki-linked notes vault produces a link that looks right and resolves to the wrong file.

Where it goes is the project's call. In a notes vault, put it in the folder that holds generated views, kept apart from anything clipped from the source, since one is yours to rewrite and the other is a record of what was published. With no project to file into, save it in the working directory. The HTML file is its own master, so it is kept even when a published copy exists, because it is what makes the page regenerable when a link is gone.

If the note it explains carries frontmatter, record the view so its staleness can be seen later:

```yaml
views:
  - kind: one-pager
    file: onepager-<slug>.html
    url: <published page> | null    # the readable copy, if one was published
    rests_on: first reading | checked | re-checked
    made: YYYY-MM-DD
```

`rests_on` is the staleness mechanism. A page is frozen when it is written while the notes under it keep being revised, so recording what it was written from is what lets the gap be seen.

**Nothing is ever cited to a one-pager.** It explains claims that already live elsewhere, so a claim traces to the notes and through them to the source. It is also frozen at publish time while the notes keep moving.

**No embed under the note's H1.** That slot belongs to a doodle, which renders inline as an image. HTML usually does not render inline in a notes app, so link the one-pager from the note instead.

---

## 7. Copy rules

These apply in full, and the page is not an exception.

- **No em dashes and no en dashes.** A full stop, a comma, or a colon.
- **No semicolons** in prose. Code and CSS keep theirs.
- **No hard wraps.** A paragraph is one line in the source, and a title has no `<br>`: the stylesheet's `text-wrap: balance` splits it. Check mechanically before publishing, by scanning every `p`, `figcaption`, `li`, `h1` to `h3`, `td` and `th` for a newline inside its text and grepping for `<br` outside code.
- Prefer the number to the adjective. Date anything time-sensitive inline as `as of 2026-08`.
- Write for a technical reader returning in a year having forgotten the context. That is why this reads as a page of considered notes rather than a blog post.

If the project has its own writing rules, they apply on top of these.

---

## 8. Files

```
one-pager/
  SKILL.md
```

It carries no assets of its own on purpose. The visual system is `imax-view`'s, and duplicating it here would produce two palettes that drift apart. Sections 3 to 5 work for any source. Sections 1 and 6 assume you keep notes on what you read, and bend to whatever the project has.
