# Migrating this machine to pauldolden/dotfiles

This machine's dotfiles are moving to `pauldolden/dotfiles`, a new personal,
multi-machine base. This repo assumed one work laptop and baked employer
specifics straight into tracked files. The new one assumes **N machines** (a
personal one and this work one) and pushes everything that differs between
them into untracked `.local` siblings.

The section above, *New machine runbook*, covers a bare macOS install on
either repo. This doc covers the other case: **this** machine, already
running this repo, moving to the new one without a reinstall.

## What changes

| Area | Here (pd-fa/dotfiles) | pauldolden/dotfiles |
| --- | --- | --- |
| Signing config | `gpg.format = ssh` + the `[gpg "ssh"]` block live in the **tracked** `git/config` | Signing method is per-machine, in **untracked** `git/config.local` — GPG on the personal machine, 1Password SSH agent on this one |
| `aerospace` / `hammerspoon` | Always on, no gating | Gated by `profile.toml` modules, **default `false`** — this machine needs `profile.local.toml` to turn them back on |
| Employer helpers | `dbp()` / `corev2()` committed straight into tracked `zsh/functions.zsh`; `proj` alias in tracked `zsh/aliases.zsh` | Both belong in untracked `zsh/functions.local.zsh` / `zsh/aliases.local.zsh` — the tracked files are employer-agnostic |
| Go toolchain | ~15 `go "..."` entries in the shared `Brewfile` | Moves to untracked `Brewfile.local` |
| Verification | None | `doctor.sh` — read-only, asserts config is actually *read*, not merely present |
| CI | None | `.github/workflows/verify.yml` |
| MDM / Jamf | Phase 1 of the runbook, mandatory | Not mentioned — out of scope for a personal machine, still applies to this one by other means |
| `gcloud` | Hardcoded `helix-*` cluster `get-credentials` calls in Phase 4 | Generic, "only if a project needs it" — cluster access becomes this machine's own concern to carry over |

## What's preserved

Same shape, same reasoning, unchanged by the move: the palette-driven theme
system (`theme/`), `mise`-managed runtimes, the git hooks and `betterleaks`
pre-commit scan, atuin history restore from a 1Password document, the
Firefox/Sidebery setup, `KEYBINDINGS.md`, and the two existing decision
records (`docs/BROWSER.md`, `docs/MACOS_INPUT.md`) — nothing in either
applies differently on the other side of this move.

## What's improved

- The `.local`-overlay pattern is systematic there — identity, signing,
  aliases, functions, secrets, completions, Brewfile, mise, palette and
  module selection all follow the same seed-from-`.example` mechanism instead
  of each having its own ad hoc convention like this repo does.
- `profile.toml` makes "what does this machine run" declarative instead of
  implicit in whichever tool configs happen to be tracked.
- `doctor.sh` closes the exact bug class it lists in its own header comment:
  a config file present, correct, and read by nothing.

## Runbook

`~/.config` **is** the live config on this machine — don't `git switch` or
reset it in place to move repos; the tree is restructured enough between the
two that half-updated dotfiles will break whatever's currently reading them
mid-way through.

### 1. Back up everything not tracked by git here

None of this exists in this repo's history, so losing it means retyping it
from memory:

```bash
mkdir -p ~/migration-backup
cp ~/.config/git/config.local ~/migration-backup/ 2>/dev/null
cp ~/.config/bootstrap.local ~/migration-backup/ 2>/dev/null
cp ~/.config/gh/hosts.yml ~/migration-backup/ 2>/dev/null
cp ~/.config/theme/palette.local.toml ~/migration-backup/ 2>/dev/null
cp ~/.config/zsh/secrets.zsh ~/migration-backup/ 2>/dev/null
```

Also note, don't copy — re-declare these by hand in step 3, since they're
moving from tracked files here to untracked ones there:

- `dbp()` and `corev2()` from `zsh/functions.zsh`
- `alias proj='cd ~/dev/work/'` from `zsh/aliases.zsh`
- the `go "..."` block from `Brewfile`

### 2. Clone beside this tree, then swap

```bash
git clone git@github.com:pauldolden/dotfiles.git ~/.config.new
mv ~/.config ~/.config.pd-fa.bak
mv ~/.config.new ~/.config
exec zsh -l    # will be noisy — nothing local exists yet
```

### 3. Recreate machine-local files

Run the new repo's bootstrap once to seed every `.local` file from its
tracked `.example` sibling, then fill each in:

```bash
~/.config/bootstrap.sh
```

| File | What to put in it |
| --- | --- |
| `git/config.local` | `user.name`, `user.email`, **and** the 1Password-SSH block from `git/config.local.example` — `signingKey`, `[gpg] format = ssh`, `[gpg "ssh"] program` / `allowedSignersFile`. This machine keeps signing the way it always did; the block just moved files. |
| `bootstrap.local` | Restore from `~/migration-backup/` |
| `profile.local.toml` | `[modules]` with `aerospace = true` and `hammerspoon = true` — both default off in the new repo |
| `zsh/functions.local.zsh` | `dbp()` and `corev2()`, verbatim |
| `zsh/aliases.local.zsh` | The `proj` alias — the new repo's convention is a flat `~/dev`, so drop the `/work` suffix unless you're keeping this machine's layout |
| `Brewfile.local` | The Go toolchain block dropped from this repo's shared `Brewfile` |
| `gh/hosts.yml` | Restore from backup, or `gh auth login` fresh |

### 4. Bootstrap and verify

```bash
exec zsh -l
~/.config/bootstrap.sh
~/.config/doctor.sh
```

Walk every `✗` `doctor.sh` reports before calling the move done — that's what
it's for. If it flags missing Brewfile packages:

```bash
cat ~/.config/Brewfile ~/.config/Brewfile.local | brew bundle --file=-
```

### 5. Confirm the parts doctor.sh doesn't check

- `gcloud` cluster contexts (`helix-*`) — no longer scripted by the new repo,
  re-run the `get-credentials` commands from this repo's Phase 4, or park
  them in `zsh/functions.local.zsh`.
- MDM-managed apps (Teams, Defender, FortiClient, LucidLink) arrive via Jamf,
  untouched by either repo.
- A signed test commit — `doctor.sh` only checks that a key is *configured*,
  not that signing actually succeeds.

### 6. Clean up

Once satisfied:

```bash
rm -rf ~/.config.pd-fa.bak
```

This repo's history stays on GitHub regardless. Whether it gets archived or
kept as a fallback afterwards is a call to make separately, not part of this
doc.

## Gotchas

- **Signing has no silent-failure mode, but it does have a silent-skip one.**
  `commit.gpgsign = true` is still tracked in the new repo, so an empty
  `config.local` fails loudly on the first commit. What's silent is
  `profile.local.toml` — bootstrapping before setting
  `aerospace`/`hammerspoon` to `true` leaves a config repo that looks
  complete while tiling and scroll remap are simply absent. Nothing errors;
  `doctor.sh` won't even check a module that's off.
- **Don't reset the live tree.** Cloning beside it and swapping directories
  avoids the half-checked-out state this repo's own README warns about under
  "Work on `main`".
- **Run `doctor.sh` from a fresh shell**, not the one bootstrap ran in — its
  PATH-ownership checks (`mise`, `claude`, `git`) read the current shell's
  resolution, and a shell that predates the bootstrap can pass or fail for
  the wrong reason.
- **The Karabiner/MDM reasoning in this README doesn't carry over verbatim.**
  The new repo's `docs/MACOS_INPUT.md` restates why AeroSpace and Hammerspoon
  were chosen without the Jamf-specific framing — the conclusion is the
  same, the justification is now machine-agnostic.
