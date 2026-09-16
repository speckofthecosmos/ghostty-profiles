# Notes for coding agents

This repo is a set of generators over one table. Read `profiles/palette.tsv` first;
everything else is derived from it.

## Rules

- **The table is the source.** `config-<profile>` files, badge PNGs, launcher icons and
  launcher entries are all generated. Editing generated output gets overwritten. Add a
  row, rerun the `bin/generate-*` scripts.
- **Generated output is gitignored** because it embeds absolute paths from whoever ran
  the generators. After cloning, run them.
- **Never emit a `title` into a generated config.** It forces the window's accessibility
  title and destroys the only channel identifying which session a window holds. See
  `docs/traps.md`.
- **Always pass `--window-inherit-working-directory=false`** next to
  `--working-directory`, or the flag silently loses. See `docs/traps.md`.
- **Strip environment markers by prefix, not by an enumerated list.** A six-name denylist
  built from published docs still leaked `CLAUDE_CODE_SESSION_ATTENDED`.

## Verifying a change

```sh
python3 bin/generate-badges
python3 bin/generate-configs --out /tmp/gp-test
python3 bin/generate-launcher-entries desktop --out /tmp/gp-test/apps
for f in /tmp/gp-test/config-*; do
  case "$f" in *config-shared) continue;; esac
  ghostty +validate-config --config-file="$f" || echo "INVALID: $f"
done
bin/ghostty-session -n -p opus claude --model opus   # dry run, prints argv
```

Do not pass `--config-default-files=false` to `+validate-config`. It makes the command
exit 1 regardless of whether the config is valid, including on known-good files.
