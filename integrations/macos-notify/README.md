# Clickable Ghostty notifications on macOS

**Symptom:** you click a Ghostty desktop notification and nothing happens. No window
comes forward. You are running several Ghostty windows, likely one per AI coding
session, and you cannot tell which one wanted you.

**Second symptom:** a notification keeps coming back after you dismiss it. That one is
not a bug in the click handling — a Claude Code session waiting at its prompt emits a
*fresh* `idle_prompt` roughly every 80 seconds, indefinitely, so dismissing one buys you
80 seconds. See [Rate limiting](#rate-limiting).

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
cp ghostty-focus-notify.sh notify-dedupe-reset.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/ghostty-focus-notify.sh ~/.claude/hooks/notify-dedupe-reset.sh
```

On Apple Silicon the `hs` binary is not installed by `hs.ipc.cliInstall()`. Symlink it:

```sh
ln -sf /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs /opt/homebrew/bin/hs
```

Then register the hook in `~/.claude/settings.json`:

```json
"Notification": [{
  "matcher": "permission_prompt|idle_prompt|auth_success|elicitation_dialog|elicitation_url_dialog|elicitation_complete|elicitation_response|agent_needs_input|agent_completed|quota_auto_resume_fired|quota_auto_resume_stale|quota_auto_resume_disabled",
  "hooks": [{"type": "command", "command": "/Users/YOU/.claude/hooks/ghostty-focus-notify.sh"}]
}],
"UserPromptSubmit": [{
  "hooks": [{"type": "command", "command": "/Users/YOU/.claude/hooks/notify-dedupe-reset.sh"}]
}]
```

The matcher lists every notification type Claude Code defines. A shorter matcher works,
but the types you leave out never reach the hook — so their durations below do nothing.

`UserPromptSubmit` is what lets a session announce itself again after you engage with it.
Skip it and each session gets one banner per cooldown window and no more.

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

### Banner duration is per notification type

One duration for everything is too blunt. Nearly all notifications are `idle_prompt` —
"I am waiting", nothing is stuck — and those do not deserve the same screen time as a
permission prompt holding a session halted. `ghostty_focus.durations`:

| seconds | types |
|---|---|
| 4 | `idle_prompt`, `auth_success`, `elicitation_complete`, `elicitation_response` |
| 8 | `agent_completed`, `quota_auto_resume_fired` |
| 30 | `quota_auto_resume_stale`, `quota_auto_resume_disabled` |
| 60 | `permission_prompt`, `agent_needs_input`, `elicitation_dialog`, `elicitation_url_dialog` |

A type not in the table falls back to `ghostty_focus.withdrawAfter` (20s). Nothing uses
`0`: `hs.notify` reads `0` as *never withdraw*, not "use the default" — it only
substitutes its own 5s when the key is absent entirely. That mistake is why this
integration's banners used to pile up in Notification Center.

Change one live with `hs -c "ghostty_focus.durations.idle_prompt = 6"`, or edit the file
to persist.

### Rate limiting

A session sitting at its prompt re-notifies about every 80 seconds for as long as it
waits. So a session is announced **once**, then stays quiet until you actually type into
it, which is what the `UserPromptSubmit` hook detects.

That marker alone is not sufficient, and the reason is worth knowing if you build
something similar: `UserPromptSubmit` also fires for prompts **no human typed** — a
background task completing delivers into the session and runs the same hook. State keyed
on "the user came back" is therefore cleared by ordinary machinery, and the banner
returns on the next tick. So there is also a time floor, which the reset hook never
touches: a session cannot be re-announced within `GHOSTTY_FOCUS_COOLDOWN` (default 600
seconds) however the marker went away.

The four types that leave a session **blocked until a human answers** —
`permission_prompt`, `agent_needs_input`, `elicitation_dialog`, `elicitation_url_dialog`
— bypass both checks. They are matched in full rather than by glob on purpose: a
`*elicitation*` pattern also catches `elicitation_complete` and `elicitation_response`,
and `*auth*` catches `auth_success`, and all three are after-the-fact notices where
nothing is waiting on you.

State lives in `~/.claude/notify-state` (override with `GHOSTTY_FOCUS_STATE_DIR`); files
older than 7 days are pruned on each run.

### Muting

`touch ~/.claude/notify-muted` silences every banner from this hook; `rm` it to restore.

## Not portable to Linux

`hs.application` is macOS only. The Linux equivalent would be a notification daemon that
supports actions plus `hyprctl` / `swaymsg` / `wmctrl` to focus, which is untested here.
