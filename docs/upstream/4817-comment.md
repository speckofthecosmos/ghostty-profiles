<!-- Draft comment for https://github.com/ghostty-org/ghostty/discussions/4817
     Venue chosen in RECON.md. Needs no vouch (discussion comment, not a PR).
     Repo is live. Check the AI disclosure line reads true to you before posting. -->

@SidShaytay's GNOME menu is the same thing I landed on. I generalized it and put it in a
repo, https://github.com/speckofthecosmos/ghostty-profiles

One TSV holds a label, an icon, a badge color, a theme and a cursor color per profile.
Generators turn that into `config-<profile>` files, a stripe image per window, and
launcher entries, `.desktop` on Linux and Raycast script commands on macOS. The launcher
script is POSIX sh and works on both.

Some of what's in it might be useful even if you don't want the repo.

`--working-directory` loses to `window-inherit-working-directory`, which defaults to
true, so a launcher opens in whatever directory the last-focused window was sitting in
rather than the one you asked for. It looks intermittent because it depends on what you
clicked last. Pass `--window-inherit-working-directory=false` alongside it.

Setting `title` per profile looks free when you've turned off decorations, since there's
nowhere for it to render. It isn't. The title is still the window's accessibility title,
which is what Mission Control prints under thumbnails and what yabai, sketchybar and
Raycast's window switcher read. Setting it per profile costs you the one channel that
says which session a window holds, which is what you need once several windows share a
profile. I ran it that way for months before working that out. Badge for the profile,
title for the session.

@geoffbeier, the macOS side is covered, that's the half I use daily.

AI disclosure per AI_POLICY.md: written with Claude Code. It did most of the scripting
and a first pass at the docs; I directed the design, and the two gotchas above are mine,
found the hard way. I've edited this comment down myself.
