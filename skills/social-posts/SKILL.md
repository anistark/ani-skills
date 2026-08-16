---
name: social-posts
description: >
  Draft platform-native social posts for an announcement, release, feature
  launch, blog, or milestone. Asks what the post is about and which targets to
  write for (X/Twitter, LinkedIn, Fediverse/Mastodon, Bluesky, Threads), then
  writes a per-platform draft to a markdown file. Applies each platform's own
  format and reach rules: X thread with a link-free first post over a cover
  image, single cohesive LinkedIn post, hashtag-driven Fediverse, etc. Plain
  text, no em or en dashes.
allowed-tools: AskUserQuestion Bash Read Grep Glob WebFetch
---

# Social Posts

Turn one subject into ready-to-publish drafts, shaped to each platform's norms
rather than the same text pasted everywhere. Every post has to earn its place:
one idea per post, valuable on its own.

## Steps

### 1. Ask what the post is about

Ask the user for the subject and any context. Offer common types but accept
free text:

- **Release announcement** (a tagged version)
- **Feature launch** (one capability)
- **Blog / writeup** (link to a longer piece)
- **Milestone** (stars, downloads, adoption)
- **Event** (talk, stream, meetup)
- **Other** (whatever the user describes)

If it is a **release announcement**, gather source material before drafting.
Pull the notes and commit range so the highlights are accurate, not guessed:

```bash
gh release view <tag> --json body,tagName,name 2>/dev/null
git log --oneline <prev-tag>..<tag>
```

Or fetch the release page with WebFetch if `gh` is unavailable. Pick the
strongest three to five items. Drop routine churn (dependency bumps, formatting,
internal refactors) from the posts, but list what you left out at the end of the
file so the user can pull any back in.

### 2. Ask where to post

Ask which targets to write for. Multi-select, the user can add their own:

- **X / Twitter**
- **LinkedIn**
- **Fediverse / Mastodon**
- **Bluesky**
- **Threads**
- **Other** (name the platform)

Only write sections for the platforms chosen.

### 3. Draft per platform

Follow the platform playbook below for each target. Then apply the universal
content rules to all of them.

### 4. Write the file

Pick the output directory in this order:

1. `plan/posts/` if it exists
2. `plan/` if it exists
3. the current working directory

Name it after the subject: `v1.15.0-announcement.md`, `<feature-slug>-posts.md`,
`<topic>-posts.md`. Open with a short header (subject, relevant links, codename
or tag, and the rules followed), then one section per chosen platform. Delimit
each X post clearly and mark where images or a cover go with a `> Image:` line.
Do not invent screenshots; leave placeholders for the user to attach.

---

## Platform playbook

### X / Twitter

A **thread** of standalone posts, roughly 280 characters each.

- **First post: no link.** Links in the opening post suppress reach. Lead with a
  hook, an insight, or the problem being solved, not a plain "we built X"
  intro. Pair it with a cover image.
- **Every later post covers exactly one thing** and reads on its own. These can
  carry links and images.
- Put the primary link (release notes or docs) on the most relevant feature
  post, not buried in the middle.
- **Final post is the CTA:** the install command, and for open source a nudge to
  star the repo with its link.
- Emojis sparingly. Hashtags minimal, zero to two, at the very end.

### LinkedIn

A **single cohesive post**, not a thread.

- Hook line, then short paragraphs, then a scannable bullet list of highlights,
  then a CTA.
- More context than X is fine here. Restating what the product is helps a
  broader professional audience.
- Links work inline, but reach improves if the main link goes in the first
  comment. Note both options so the user picks.
- Three to five hashtags at the end.

### Fediverse / Mastodon

Posts cap around **500 characters** (instance-dependent). Thread via replies; a
content warning is optional.

- No engagement algorithm, so links are fine anywhere, including the first post.
- **Hashtags are the main discovery mechanism.** Use a few descriptive ones in
  CamelCase for readability (`#OpenSource`, `#RustLang`).
- The community values substance over hype. Skip growth-hacky phrasing.

### Bluesky

Posts cap at **300 characters**. Thread via replies.

- Links get rich embeds automatically, just paste the URL.
- Hashtags are clickable; one to three.
- Norms resemble early Twitter: casual, links fine, threads welcome.

### Threads

Posts cap around **500 characters**. Single posts or chains.

- Links allowed. Visual-first platform, keep copy light.
- One topical hashtag is the norm, not a pile.

---

## Universal content rules

- **One idea per post.** Each must be valuable standalone, not a fragment of the
  one before it.
- **Concrete over adjective.** Say what changed and why it matters, not "huge
  improvements".
- **Lead with the problem or the insight**, not "excited to announce".
- **CTA:** install or try command, and for open source a star-the-repo ask with
  the link.
- **Ground the highlights** in the actual release notes and commits. Do not
  inflate minor changes into headline features.

## Style

Write in plain text. No em dashes, no en dashes, and no hyphenated compounds in
prose: "open source" not "open-source", "source level" not "source-level",
"Rust based" not "Rust-based". This matches the house voice across the repo.
