# ghostty-profiles

Color-coded Ghostty windows with searchable launcher entries, generated from one table.

## The problem

I run five or six Ghostty windows at once, each holding a different AI coding session. Opus in one, Sonnet in another, Gemini in a third, plus a couple of shells. Every window is chrome-less and black, because that's what an XDR display wants. So they're identical, and ⌘Tab says "Ghostty" for all of them.

Ghostty has no profiles. You can point it at a different config file per invocation, which gets you different colors, but nothing ties that to a way of launching, and nothing helps you find it later.

This is what I ended up with after a year of running it.

## What it does

One table, `profiles/palette.tsv`, holds a label, an icon, a badge color, a theme, a cursor color, and a command for each profile. Everything else is generated from it:

- **Ghostty configs.** One `config-<profile>` per row, sharing a common base.
- **Window badges.** A thin vertical bar of solid color at the window edge. Readable in Mission Control at thumbnail scale, where the text isn't.
- **Launcher entries.** `.desktop` files on Linux, Raycast script commands on macOS. Labeled, icon'd, searchable.
- **Launcher icons.** The same hue as the window badge, so the color code is taught at the moment of choosing rather than after the window exists.

```sh
git clone https://github.com/YOURNAME/ghostty-profiles
cd ghostty-profiles
python3 bin/generate-badges                      # stripes and launcher icons
python3 bin/generate-configs                     # config-<profile> into ~/.config/ghostty
python3 bin/generate-launcher-entries desktop    # or: raycast
bin/ghostty-session -p opus claude --model opus  # try it
```

Nothing generated is committed, since it embeds absolute paths. Run those three after cloning and again after editing the table.

## The visual language

The stripe carries the variant, the title carries the session. Those are separate channels and it's worth not spending both on the same bit.

Ghostty's `title` config looks harmless when you've turned off window decorations, since there's nowhere for a title to render. It isn't harmless. The title is still the window's accessibility title, which is what Mission Control prints under the thumbnail, what yabai returns, what Raycast's window switcher lists, and what sketchybar can read. Set it per variant and you've overwritten the one channel carrying *which session this is*, which is the thing you actually need once five windows share a variant. Leave `title` unset and Claude Code's own session title flows through.

**The badge is a stripe, not a background tint,** and that's a display constraint rather than taste. On a mini-LED XDR panel, background color and full-screen images eat overdrive headroom and cut peak brightness, which you notice the moment you take the laptop outside. A 15px bar at the window edge claims about 3% of the area, stays out of your gaze during focused work, and still reads as a colored edge in a Mission Control thumbnail. Tinting below `#0a0a0a` doesn't work either: those values collapse into the same backlight-dimmed zone and the hue is imperceptible, indoors or out.

**Badge hue and cursor color are separate columns** because they answer different questions. The badge answers "which window is that?" from across the screen. The cursor answers "where am I typing?" from six inches away. They can match, and often the theme has a better cursor color than the badge hue would be. Sonnet pairs a green badge with Gruvbox's amber cursor.

Adding a hue is a row in the table and a rerun of `bin/generate-badges`, which writes both the stripe and the launcher icon. Pick one that isn't already taken; at seven profiles the distinct-at-thumbnail-scale hues start running out faster than you'd expect.

## Launcher entries

The entry point is a searchable labeled list. You should be able to find a profile without already knowing it exists, which is the part a keybinding can't do.

On Linux that means `.desktop` files. Every launcher reads them, so one generator covers GNOME Activities, KDE's menu, `rofi -show drun`, wofi, fuzzel, Ulauncher, Vicinae and Walker with no per-launcher adapter:

```sh
python3 bin/generate-launcher-entries desktop --out ~/.local/share/applications
```

On macOS there's no `.desktop` equivalent, so Raycast script commands do the same job:

```sh
python3 bin/generate-launcher-entries raycast --out ~/.config/raycast/scripts
```

**"Why not just bind a key?"** You can, and it's in `docs/keybindings.md`. But a keybinding has nothing to look at, so you have to remember that Super+O means Opus, and remembering which invisible key opens which invisible window is the problem this repo exists to solve. Bind keys to the two profiles you open twenty times a day, after you've learned them from the list.

## Shell aliases

Separate from launching windows, these run a model in the shell you're already in:

```fish
# ~/.config/fish/functions/opus.fish
function opus --description "Claude CLI with Opus"
    claude --model opus $argv
end
```

```bash
# ~/.bashrc or ~/.zshrc
opus()   { claude --model opus   "$@"; }
sonnet() { claude --model sonnet "$@"; }
fable()  { claude --model fable  "$@"; }
```

I run mine with `--permission-mode auto --allow-dangerously-skip-permissions`, which skips the permission prompts. That's the right default for my own workspace and it may not be for yours, so it isn't in the snippet above. Read what those flags do before adding them.

## Platform notes

`bin/ghostty-session` is POSIX sh and resolves the binary with `command -v ghostty`, falling back to the macOS app bundle path. It works on both platforms for different reasons.

On macOS, passing `--config-file` spawns a separate GUI instance, which is what gives each profile its own colors. That also means several processes share the bundle id `com.mitchellh.ghostty`, and anything routing by bundle id (AppleScript, notification clicks) becomes ambiguous.

On Linux, GTK single-instance mode would normally hand a second launch to the existing process and ignore your config. Ghostty disables single-instance automatically when any CLI argument is passed, and this script always passes at least two, so each profile gets its own process there as well.

## Traps

`docs/traps.md` covers the ones that cost me real time: `--working-directory` silently losing to `window-inherit-working-directory`, the `title` problem above, and inherited environment markers that make a fresh Claude Code session stop saving its transcript.

## License

MIT.
