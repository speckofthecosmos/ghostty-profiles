# Traps

These cost me real debugging time. None are documented anywhere I could find, and each is the kind of failure that looks like something else.

## `--working-directory` silently loses to `window-inherit-working-directory`

Ghostty's `window-inherit-working-directory` defaults to `true`, and per its own docs, new windows inherit the working directory of the previously focused window, with `working-directory` used only if no window was previously focused.

Some other Ghostty window is almost always open and focused, so the flag you passed gets overridden by whatever directory that unrelated window happened to be sitting in. The symptom is a launcher that opens in the right theme with the wrong directory, intermittently, depending on what you last clicked. I hit it as a fresh session landing in a network mount path for no visible reason.

```sh
ghostty --working-directory="$HOME/src" --window-inherit-working-directory=false ...
```

Both flags, always. Verify with `lsof -a -p <pid> -d cwd` against the *shell* process, not the Ghostty process. Ghostty's own cwd is whatever launched it and tells you nothing.

## `title` overwrites the accessibility title

Setting `title` in a config forces the window title permanently and makes Ghostty ignore title escape sequences from the running program.

With `window-decoration = none` and `macos-titlebar-style = hidden` there's nowhere for a title to render, so this looks like it does nothing. It isn't nothing. The title is still the window's accessibility title, and that is what Mission Control prints under thumbnails, what `yabai -m query --windows` returns, what Raycast's window switcher lists, and what sketchybar reads.

I had `title = "🔷 opus"` on every variant for months. It cost me the only channel carrying which session a window held, which is exactly what you need once five windows share a variant. The badge already says which variant it is. Leave `title` unset and let the program's own title through.

⌘Tab will still say "Ghostty" regardless. That's an app-level switcher and no title setting reaches it.

## `-c` is not fish's `-C`

fish's `-C` runs an init command and then stays interactive in the same shell. Neither bash nor zsh has that. Their `-c` runs the command and exits, which closes the window the moment your session ends.

The working equivalent chains an exec, and needs `-i` so the rc file gets sourced and shell functions resolve:

| Shell | Invocation |
|---|---|
| fish | `-e fish -C '<cmd>'` |
| bash | `-e bash -i -c '<cmd>; exec bash -i'` |
| zsh | `-e zsh -i -c '<cmd>; exec zsh -i'` |

Plain `bash -c 'myfunc'` fails with *command not found* for anything defined in `.bashrc`. Also note that bash and zsh source their rc twice here, once for the `-c` shell and once for the exec'd one, so rc files with unconditional side effects (appending to `PATH`, starting an agent) will double up. fish sources once.

If you test these outside a terminal you'll see `bash: no job control in this shell`. That's a non-tty artifact and doesn't appear in a real window.

## Inherited `CLAUDE_CODE_*` markers disable transcript saving

Claude Code sets several `CLAUDE_CODE_*` environment variables per session. One of them, `CLAUDE_CODE_CHILD_SESSION=1`, tells a nested `claude` that it's running inside another one and shouldn't write its own transcript.

Launch a new window from a shell descended from a running session and those variables come with it. The new session, a genuinely top-level one, reads the marker, concludes it's a child, and silently stops saving. You get *"Transcript saving is off, inherited CLAUDE_CODE_CHILD_SESSION marker"* on a session that isn't nested at all.

Strip by prefix, never by an enumerated list. I wrote the first version of this against six known variable names and `CLAUDE_CODE_SESSION_ATTENDED` still got through, because Anthropic adds markers across releases and a hand-written list goes stale without telling you:

```sh
for _v in $(env | sed -n 's/^\(CLAUDE_CODE_[A-Za-z0-9_]*\)=.*/\1/p'); do
  unset "$_v" || true
done
```

Long-running launchers make this worse rather than different. Raycast freezes whatever environment it started with for the life of the app, so relaunching it once from inside a session poisons every window it spawns afterward, until you quit and relaunch it. A shell function or a `.desktop` entry inherits per-launch instead, same symptom, easier to clear.

Verify with `ps eww -p <shell-pid>` on the new window's shell.
