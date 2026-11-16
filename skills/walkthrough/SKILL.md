---
name: walkthrough
description: Walk someone through what is on their screen, section by section, drawing on it with Arin. Marks each part, writes a note beside it, says what to look for and what to show a team, then moves on when they scroll. Use for "walk me through this", "explain this page on my screen", or rehearsing a demo or presentation. Requires Arin on macOS.
argument-hint: "[what is open, such as a page, dashboard or doc] [optional: who it will be shown to]"
---

# /walkthrough

Take someone through what is already open on their screen, one part at a time, the way a colleague would stand beside them and point.

The screen does the showing. The chat carries the fuller explanation. Neither repeats the other in full: a note on screen is one or two sentences, and the chat says why it matters and what to do with it.

---

## 0. Requires Arin

Arin is what draws on the screen. Without it this skill is just a long message, so check before anything else.

Run these in order and stop at the first failure:

```sh
command -v arin        # installed?
arin status            # daemon reachable?
```

Then check that the session has Arin's tools, named like `mcp__arin__highlight`. They may be deferred, so search for them before deciding they are missing.

Do not run an install or change a login item yourself. Tell the user what is missing and give them the one command that fixes it. Then stop until they say it is done.

| What failed | Tell the user to run | Then |
|---|---|---|
| `arin` not found | `brew install anistark/tools/arin && arin service enable && claude mcp add --scope user arin -- arin mcp` | Allow Screen Recording when macOS asks, then start a new session |
| `arin status` cannot reach the daemon | `arin service enable` starts it now and at every login. `arin -d` runs it only while that terminal stays open | Check again |
| No Arin tools in the session | `claude mcp add --scope user arin -- arin mcp` | Start a new session, because tools load at session start |

Screen Recording does not block this skill. Arin uses it to follow content that moves and to pick a colour that shows up. If marks are hard to see or do not follow a scroll, have the user run `arin permissions --open` and turn it on for Arin. Do not rely on `arin permissions` to check it while the daemon is running, because it cannot answer for the daemon then and the daemon's log at `~/Library/Logs/Arin/arin.log` has the real result.

Arin needs macOS 14 or newer. On anything else, say so and offer a plain written walkthrough instead. Other install routes are at https://arin.anirudha.dev/docs/install/.

---

## 1. Find the screen

Arin draws but cannot see, so you need a way to look at the screen too. Use whatever capture tool the session has, such as a computer-use screenshot of one app window.

1. Work out which app and window holds the thing. If several windows could, look at each one and release any that are not it. Other windows may be private, so do not describe them.
2. Note the window's bounds and which display it is on.
3. Run `arin displays` for the id to pass as `display`. Omitting it draws on the primary display, which may be the wrong screen.
4. If the source is available, such as a page you built or a file in the repo, read it as well. A screenshot shows what is there. The source tells you what it means and whether it is right.

Before the first mark, tell the user in one line that they can say "next" to move on.

---

## 2. Aim

Arin takes logical points measured from the top-left of the display, or percentages of a whole-display screenshot. A window screenshot is neither, so convert:

```
x = shot_x * (window_width  / shot_width)  + window_x - display_x
y = shot_y * (window_height / shot_height) + window_y - display_y
```

Results report `display_scale`, `display_width` and `display_height`, so use the first good result to confirm the display is the size you assumed.

Take a fresh screenshot at every new position. Coordinates from an earlier screen are worthless, and so are coordinates from before anything moved the layout, such as a banner appearing.

---

## 3. Draw, one thing at a time

The order on every screen is: draw one mark, write its note, pause about 2 seconds, draw the next.

- **Separate calls.** Mark first, then its note in a later call. Marks sent together land together, and that is hard to follow.
- **The pause is the gap between calls**, which is usually long enough. Do not add a wait that goes through the app being marked. It can disturb the page.
- **Number everything.** The label is `1 Short claim`, and the note starts `1:`. The chat uses the same number.
- **Put the note right beside its mark.** Never stack notes in one spare corner, because the reader then cannot tell which note belongs to which mark. Look for empty space next to the mark first, including empty space inside the same card.
- **If nothing beside it is empty**, cover the least useful thing next to it and say in the chat what the note is hiding. For a mark that spans the full width, use the nearest gap above or below it.
- **Keep notes short.** One or two sentences, about 110 characters, plain words. A label is under six words.
- **Keep earlier marks up.** Do not clear anything while the screen stays put. People read at their own speed, and a mark that vanishes when the next arrives was gone before they finished it.

Prefer `highlight` for an area, `point_at` for one control, and `annotate` for the note. Use an arrow only when the link between two places is the point. Aim for three to six marks per screen. If there is more than that, pick what matters and leave the rest to the chat.

---

## 4. What to say in the chat

Send this once the marks for the screen are drawn. Keep it short and in plain language, and give each term a meaning the first time it appears.

```
## Screen N: <what this part is called>

<One or two sentences: what this part is for.>

**Where to look, in order:**
1. <Thing>: what it shows and why it matters. Numbers match the marks.

**What to show your team:** <the one thing to click or play, and what happens>

**The line to land:** <the single sentence to leave people with>

**Before you present:** <only if something here is wrong, stale, confusing or missing>
```

Leave out "What to show your team" and "The line to land" if the user is learning for themselves rather than presenting. If they named an audience, write for that audience.

End with exactly what to do next, such as "Scroll to X and say next."

---

## 5. Move on

Arin never scrolls, and that is deliberate. By default the user scrolls and says "next".

On "next":

1. Clear the marks.
2. Take a fresh screenshot.
3. If the screen has not moved, say so and ask them to scroll, or ask how they want to handle it. Do not redraw on a screen you already covered.
4. Otherwise find where they are, and repeat from section 2.

If the user wants you to scroll, you need a tool that controls the app. Computer-use access to a browser is usually view-only, and that limit is not to be worked around. Say what you cannot do and offer what you can, such as opening the same page in a browser tab you control. Scrolling that way can bring up a debugging banner that shifts the page, so wait until it clears, take a fresh screenshot, and only then draw.

If a request lands mid-walkthrough, such as a question about what is on screen, answer it first and leave the marks alone.

---

## 6. Be straight about it

- **Check what you say.** Numbers come from the screen or the source, not from memory. If you state a cause, confirm it.
- **Flag what you find.** A number that is out of date, a chart that renders wrong or a claim that no longer holds goes under "Before you present". Do not fix it without asking.
- **You cannot see your own marks.** Screenshots of an app window leave out Arin's overlay. Never say a mark looks right. If placement matters, ask the user whether it landed.
- **Say what you did not cover.** That includes sections skipped, notes that hide something, and anything left unverified.

---

## 7. Finish

At the end of the last screen:

1. Clear the marks if the user is done with them.
2. Close any tab you opened and release any window you held.
3. Give a short running order for the whole thing: each screen in one line, the one demo worth doing, and any open "Before you present" items.

---

## Things that go wrong

| What you see | What it means | What to do |
|---|---|---|
| A draw call fails with `data must have required property 'gone'` | Arin 0.7.0 drew the mark but its reply failed a check | Treat it as drawn. Do not draw it again |
| Result lists a mark as gone with reason `scroll` | The content moved under it | Take a fresh screenshot. If the user scrolled, this is expected |
| Marks are consistently off by the same amount | Something shifted the layout, often a banner | Wait for it to settle, take a fresh screenshot, redraw |
| The mark is on the wrong screen | Wrong `display`, or two displays of the same size | Match the id from `arin displays` to where the window is |
| All marks disappear at once | The Arin session ended | Redraw from a fresh screenshot |
