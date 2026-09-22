#!/usr/bin/env bash
# Claude Code Notification hook -> Hammerspoon -> clickable banner that focuses
# the Ghostty window this session is running in.
#
# The Ghostty instance is found by walking this process's own ancestry
# (hook -> claude -> shell -> login -> ghostty), so there is no session-state
# file to write or clean up.
set -euo pipefail

# Silence every banner from this hook: `touch ~/.claude/notify-muted`, and `rm`
# it to restore. An `if` rather than `[ ... ] && exit 0` because under `set -e` a
# failing test at the head of an && list makes the whole list return non-zero and
# kills the hook.
if [ -e "${HOME}/.claude/notify-muted" ]; then exit 0; fi

payload="$(cat)"

pid=$$
ghostty_pid=""
while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
  case "$(ps -o comm= -p "$pid" 2>/dev/null || true)" in
    *Ghostty.app/Contents/MacOS/ghostty) ghostty_pid="$pid"; break ;;
  esac
  pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
done
[ -n "$ghostty_pid" ] || exit 0   # not running under Ghostty; nothing to focus

meta="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print(str(d.get("session_id") or "")[:64])
print(str(d.get("notification_type") or ""))
')"
session="$(printf '%s' "$meta" | sed -n 1p)"
kind="$(printf '%s' "$meta" | sed -n 2p)"

case "$session" in ""|*/*|..*) session="" ;; esac   # never escape the state dir

# ---------------------------------------------------------------------------
# Rate limiting.
#
# A session waiting at its prompt emits a fresh idle_prompt roughly every 80
# seconds, forever. Dismissing a banner therefore buys you 80 seconds, which is
# the real complaint behind "the notification keeps coming back". Over a
# 17-hour capture here: 60 idle_prompt against 4 permission_prompt, with
# agent_completed and agent_needs_input never firing at all.
#
# So a session is announced once and then stays quiet until you actually type
# into it (notify-dedupe-reset.sh clears the marker on UserPromptSubmit).
#
# The marker alone is not enough. UserPromptSubmit also fires for prompts no
# human typed -- a background task completing, for instance, delivers into the
# session and runs the same hook -- so the marker gets cleared by ordinary
# machinery and the banner returns on the next tick. The time floor below is
# never cleared by the reset, so it holds regardless of why the marker went
# away.
#
# Blocking types are exempt from both: a session stopped until a human answers
# must not be masked by an earlier "finished a turn" banner for the same
# session. Matched in full, not by glob -- `*elicitation*` would also catch
# elicitation_complete and elicitation_response, and `*auth*` would catch
# auth_success, and all three are after-the-fact notices where nothing waits.
# ---------------------------------------------------------------------------
blocking=0
case "$kind" in
  permission_prompt|agent_needs_input|elicitation_dialog|elicitation_url_dialog) blocking=1 ;;
esac

if [ -n "$session" ] && [ "$blocking" = "0" ]; then
  state_dir="${GHOSTTY_FOCUS_STATE_DIR:-${HOME}/.claude/notify-state}"
  mkdir -p "$state_dir"
  # Nothing else prunes this directory; without it you accumulate one file per
  # session forever.
  find "$state_dir" -type f -mtime +7 -delete 2>/dev/null || true

  marker="${state_dir}/${session}"
  floor="${state_dir}/.lastsent-${session}"

  cooldown="${GHOSTTY_FOCUS_COOLDOWN:-600}"
  if [ -e "$floor" ]; then
    last="$(stat -f %m "$floor" 2>/dev/null || echo 0)"
    if [ "$(( $(date +%s) - last ))" -lt "$cooldown" ]; then exit 0; fi
  fi

  if [ -e "$marker" ]; then exit 0; fi   # already announced this episode
  : > "$marker"
  : > "$floor"
fi

# Python emits the complete Lua call. Building it in shell split multi-word
# messages across arguments, because `read` splits on whitespace.
cmd="$(printf '%s' "$payload" | GHOSTTY_PID="$ghostty_pid" NOTIFY_KIND="$kind" python3 -c '
import json, os, sys

def lua_str(v):
    return "'"'"'" + v.replace("\\", "\\\\").replace("'"'"'", "\\'"'"'") + "'"'"'"

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
body = (d.get("message") or d.get("notification_type") or "Session needs you")
body = " ".join(body.split())[:180]
session = (d.get("session_id") or "default")[:16]
sys.stdout.write("ghostty_focus.notify(%s, %s, %s, %s)" % (
    os.environ["GHOSTTY_PID"], lua_str(body), lua_str(session),
    lua_str(os.environ.get("NOTIFY_KIND", ""))))
')"

if [ "${GHOSTTY_FOCUS_DRYRUN:-0}" = "1" ]; then
  printf '%s\n' "$cmd"
  exit 0
fi

"${HS_BIN:-/opt/homebrew/bin/hs}" -c "$cmd" >/dev/null 2>&1 || true
