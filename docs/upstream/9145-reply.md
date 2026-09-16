<!-- Draft reply to nckre on https://github.com/ghostty-org/ghostty/issues/9145
     Addresses both halves of their comment: knowing which window is which, and the
     click taking you there. Does NOT diagnose why clicks fail upstream; untested here. -->

@nckre same setup, five or six Ghostty windows, one per model.

Knowing which window is which came first. Each profile gets a colored stripe down the
window edge, which is readable in Mission Control at thumbnail scale where the text
isn't, so blue is Opus, green is Sonnet and so on. The window title stays free to carry
the session subject, which matters once several windows share a profile. That half works
on Linux too.

Then the click. On macOS I stopped waiting for it and had Hammerspoon post the
notification instead. It answers its own click and activates the originating process by
pid, so it doesn't matter how many Ghostty instances are running. The banner carries the
window's own title, so it arrives already saying which session wants you.

Both halves live in the same repo, https://github.com/speckofthecosmos/ghostty-profiles

One thing that bit me: Claude Code posts its own banner too, so you get two until you set
`preferredNotifChannel` to `terminal_bell`, which keeps the bell and drops the banner.

The notification half is macOS only, `hs.application` is the whole trick and there's no
Linux equivalent in it.

AI disclosure per AI_POLICY.md: built with Claude Code. I directed it and can explain
what it does.
