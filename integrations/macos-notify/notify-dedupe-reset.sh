#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook, companion to ghostty-focus-notify.sh.
#
# Clears this session's notification marker, so the session announces itself
# once more the next time it needs attention. Without it the dedupe would be
# permanent: the first idle_prompt would be the only banner a session ever
# produced.
#
# Note this hook also fires for prompts no human typed -- a completing
# background task delivers into the session and runs it too. That is why
# ghostty-focus-notify.sh keeps a separate time floor that this script does not
# touch: the marker is best-effort, the floor is the guarantee.
set -euo pipefail

state_dir="${GHOSTTY_FOCUS_STATE_DIR:-${HOME}/.claude/notify-state}"
session="$(python3 -c '
import json, sys
try:
    print((json.load(sys.stdin).get("session_id") or "")[:64])
except Exception:
    print("")
' 2>/dev/null || true)"

[ -n "$session" ] || exit 0
case "$session" in */*|..*) exit 0 ;; esac   # never let a payload escape the dir

rm -f "${state_dir}/${session}" 2>/dev/null || true
exit 0
