# Clickable Ghostty notifications on macOS

**Symptom:** you click a Ghostty desktop notification and nothing happens. No window
comes forward. You are running several Ghostty windows, likely one per AI coding
session, and you cannot tell which one wanted you.

Upstream fixed notification click-to-focus for GTK in
[#9146](https://github.com/ghostty-org/ghostty/pull/9146) (Ghostty 1.3.0), and the macOS
split-pane case in [#10444](https://github.com/ghostty-org/ghostty/issues/10444). If
clicking still does nothing for you on macOS, the likely reason is that you run **several
Ghostty processes at once**, which is what per-profile configs give you. They all share
the bundle identifier `com.mitchellh.ghostty`, so a notification click has no unambiguous
process to route to.

This works around it by not routing through the bundle identifier at all.

## How it works

Hammerspoon posts the notification instead of Ghostty, and answers its own click by
activating the originating process **by pid**:

```lua
hs.application.applicationForPID(pid):activate(true)
```

The pid comes from the hook walking its own ancestry, `hook → claude → shell → login →
ghostty`, so there is no session-state file to write or go stale.

Hammerspoon is used because it is signed and notarized. A hand-built helper app cannot
do this job: on macOS Tahoe, `UNUserNotificationCenter` refuses to register an app that
is not Developer ID signed and notarized, and fails with
`UNErrorDomain Code=1 "Notifications are not allowed for this application"` with no
permission prompt at all. Ad-hoc and self-signed builds are rejected.

## Install

Requires [Hammerspoon](https://www.hammerspoon.org/) with `require("hs.ipc")` in your
`init.lua` and the `hs` CLI available.

```sh
cp ghostty_focus.lua ~/.hammerspoon/
echo 'ghostty_focus = require("ghostty_focus")' >> ~/.hammerspoon/init.lua
cp ghostty-focus-notify.sh ~/.claude/hooks/
```

On Apple Silicon the `hs` binary is not installed by `hs.ipc.cliInstall()`. Symlink it:

```sh
ln -sf /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs /opt/homebrew/bin/hs
```

Then register the hook in `~/.claude/settings.json`:

```json
"Notification": [{
  "matcher": "agent_completed|permission_prompt|idle_prompt|agent_needs_input",
  "hooks": [{"type": "command", "command": "/Users/YOU/.claude/hooks/ghostty-focus-notify.sh"}]
}]
```

Set `HS_BIN` if your `hs` lives somewhere else.

## Turn off the duplicate banner

Claude Code posts its own notification, so without this step you get two. Set
`preferredNotifChannel` to `terminal_bell`, which keeps the audible bell and drops the
banner. Valid values are `auto`, `iterm2`, `terminal_bell`, `iterm2_with_bell`, `kitty`,
`ghostty`, `notifications_disabled`.

Set it in **both** `~/.claude/settings.json` and `~/.claude.json`. They are separate
layers, `/config` writes the second one, and a hand edit lands in the first. Mine
disagreed for months (`iterm2_with_bell` against `ghostty`), which is how I ended up with
two banners and no obvious culprit.

## Behavior

The notification title is the originating window's own title, so with Claude Code that is
your session subject. A notification is suppressed when its target window is already
frontmost. A newer notification for the same session replaces the older rather than
stacking.

## Not portable to Linux

`hs.application` is macOS only. The Linux equivalent would be a notification daemon that
supports actions plus `hyprctl` / `swaymsg` / `wmctrl` to focus, which is untested here.
