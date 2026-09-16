# Keybindings

Bind a key once you know from the launcher list which profile you want, not before. A key with nothing to look at only works for the profiles you already have memorized, which is why this is an appendix.

## Linux

```ini
# Hyprland
bind = SUPER, O, exec, /path/to/ghostty-profiles/bin/ghostty-session -p opus claude --model opus
```

```ini
# sway / i3
bindsym $mod+o exec /path/to/ghostty-profiles/bin/ghostty-session -p opus claude --model opus
```

```
# sxhkd (bspwm)
super + o
    /path/to/ghostty-profiles/bin/ghostty-session -p opus claude --model opus
```

GNOME and KDE both take the same command through their custom keyboard shortcut settings.

If you generated `.desktop` entries, most launchers can also bind a key to an existing entry rather than to a raw command, which keeps the command in one place.

## macOS

Raycast assigns a hotkey to any script command, so generate the Raycast entries and bind from there. Skhd and Karabiner work too and take the command directly:

```
# skhd
cmd + shift - o : /path/to/ghostty-profiles/bin/ghostty-session -p opus claude --model opus
```

## Picking chords

Direct mnemonics beat category ones. `O` for Opus is easier to keep than `T` for terminal, and you'll have several of these.

Global chords are expensive because the binding captures the key everywhere and the focused app never sees it. Check what you're taking before you take it.
