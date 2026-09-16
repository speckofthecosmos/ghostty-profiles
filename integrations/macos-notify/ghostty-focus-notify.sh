#!/usr/bin/env bash
# Claude Code Notification hook -> Hammerspoon -> clickable banner that focuses
# the Ghostty window this session is running in.
#
# The Ghostty instance is found by walking this process's own ancestry
# (hook -> claude -> shell -> login -> ghostty), so there is no session-state
# file to write or clean up.
set -euo pipefail

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

# Python emits the complete Lua call. Building it in shell split multi-word
# messages across arguments, because `read` splits on whitespace.
cmd="$(printf '%s' "$payload" | GHOSTTY_PID="$ghostty_pid" python3 -c '
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
sys.stdout.write("ghostty_focus.notify(%s, %s, %s)" % (
    os.environ["GHOSTTY_PID"], lua_str(body), lua_str(session)))
')"

if [ "${GHOSTTY_FOCUS_DRYRUN:-0}" = "1" ]; then
  printf '%s\n' "$cmd"
  exit 0
fi

"${HS_BIN:-/opt/homebrew/bin/hs}" -c "$cmd" >/dev/null 2>&1 || true
