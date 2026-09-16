# Upstream recon: ghostty-org/ghostty (2026-09-16)

## Hard constraints found

**A vouch is required, and you don't have one.** `CONTRIBUTING.md` documents a vouch
system: open a discussion in the **Vouch Request** category, a maintainer comments
`!vouch`, and only then can you submit PRs. Unvouched PRs are closed automatically.
`speckofthecosmos` does not appear in `.github/VOUCHED.td`. There is also a public
**denouncement list** for repeat low-quality contributors, shared with other projects.

**The vouch request has to be written by you, not drafted here.** `CONTRIBUTING.md`,
verbatim: *"Write in your own voice, don't have an AI write this."* So there is no
draft of it in this folder on purpose.

**All AI usage must be disclosed.** `AI_POLICY.md` requires stating the tool and the
extent of assistance, requires a human who can explain the work without AI help, and
requires that AI-generated text be reviewed *and edited* down before submission,
because "AI is very good at being overly verbose." No AI-generated images at all.

## Duplicate search (the part that changed the plan)

| Thread | State | What it means |
|---|---|---|
| [#9145](https://github.com/ghostty-org/ghostty/issues/9145) notification click-to-focus | **closed, completed**, milestone 1.3.0 | Fixed by [#9146](https://github.com/ghostty-org/ghostty/pull/9146) `gtk: fix clicking on desktop notifications`, i.e. Linux only |
| [#10444](https://github.com/ghostty-org/ghostty/issues/10444) macOS: click opens a new window instead of focusing the pane | **closed, completed** | The macOS case was reported and closed as fixed |
| [#13301](https://github.com/ghostty-org/ghostty/issues/13301) notification withdrawal only fires for first split | closed, not planned | Related, declined |
| [#4109](https://github.com/ghostty-org/ghostty/discussions/4109) "Profiles?" | **closed**, answered by mitchellh: *"There are so many other requests for this. Please search."* | Do not post here |
| [#6053](https://github.com/ghostty-org/ghostty/discussions/6053) new windows without many instances | closed, answered, Q&A | Do not post here |
| [#4817](https://github.com/ghostty-org/ghostty/discussions/4817) per-tab and -window themes | **open, 20 upvotes, 6 comments** | The venue |

I spent this session describing #9145 as open and unimplemented. It is neither. Both
notification issues are closed as completed.

## Why #4817 is the right venue

The thread is the same problem in other people's words:

- **SidShaytay:** *"It's easy to get lost between 4-8 terminals, I like color coding work
  to streamline context switching... Which of these 6 black [terminals]"* — and they
  posted a GNOME-shortcuts workaround with a screenshot, which is the same shape as the
  launcher here, hand-rolled for one desktop.
- **mikepk:** *"having color is a super high-bandwidth way to switch between contexts...
  this terminal is red, it's connected to a production host."*
- **geoffbeier:** *"on Mac, anyway... the work-around using the launcher is fine for me on
  Linux... losing track of my windows in Ghostty is the last thing that sends me to iTerm."*

So the additive contribution is a generalized, cross-platform version of a workaround the
thread already has in one-desktop form, plus the macOS side geoffbeier says is missing,
plus the two traps. A discussion comment needs no vouch.

## Open question blocking the notification post

There is no publishable notification post yet, because the premise isn't established.
Both upstream issues are closed as fixed, yet clicking did nothing on 1.3.1 here. The
likely difference is the six concurrent Ghostty processes sharing
`com.mitchellh.ghostty`, which would make click routing ambiguous in a way a
single-instance test never shows. That would be a genuinely unreported bug and a good
contribution.

It needs one test that requires a human click:

1. Set `preferredNotifChannel` back to `ghostty` temporarily.
2. Quit every Ghostty instance but one. Emit `printf '\e]9;test\a'`, click the banner,
   note whether the window focuses.
3. Relaunch the other instances. Repeat from a non-frontmost one.

If it works at step 2 and fails at step 3, that is the report. If it fails at both, it is
a different bug and the report says so instead.
