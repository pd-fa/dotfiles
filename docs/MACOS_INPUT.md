# macOS input and window management

Replaces two GUI apps that could not be tracked in this repo.

| Was | Now | Why it moved |
| --- | --- | --- |
| Mos | Karabiner-Elements | Mos kept state in a binary plist under `~/Library/Preferences` |
| BetterTouchTool | Karabiner-Elements + AeroSpace | BTT kept state in an opaque sqlite blob |

Both replacements read plain text from `~/.config`, which **is** this repo — so neither
needs a bootstrap symlink. That is the whole reason they were chosen over alternatives.

```
~/.config/karabiner/karabiner.json    mouse scroll flip + thumb buttons
~/.config/aerospace/aerospace.toml    tiling, workspaces, keyboard bindings
~/.config/macos/defaults.sh           the one system default AeroSpace requires
```

## Why AeroSpace and not yabai

yabai's useful half — moving windows between Spaces, driving Mission Control — needs a
scripting addition injected into `Dock.app`, which requires partially disabling SIP. This
machine is Jamf-enrolled and runs Defender, FortiClient and Admin By Request, with
`csrutil` reporting SIP enabled. AeroSpace needs no SIP change because it emulates its own
workspaces rather than driving native Spaces.

## Scroll direction

macOS has exactly one scroll-direction setting, `com.apple.swipescrolldirection`, applied
to every pointing device at once. There is no per-device toggle to `defaults write`, which
is why Mos existed. Karabiner solves it below that layer, on the HID event stream:

```json
{ "type": "mouse_basic", "flip": ["vertical_wheel"], "conditions": [ ... ] }
```

The trackpad is untouched and keeps natural scrolling, simultaneously — not toggled on
device connect.

## Device identifiers

Rules are scoped by **both** `vendor_id` and `product_id`:

| Device | vendor_id | product_id |
| --- | --- | --- |
| Logitech G502 HERO SE (mouse) | 1133 | 49291 |
| Logitech G915 TKL (keyboard) | 1133 | 49987 |
| Apple Internal Keyboard / Trackpad | 1452 | 33028 |

Scoping by `vendor_id` alone — as most recipes online do, including Karabiner's own docs
example — would match the keyboard too, because both Logitech devices share vendor 1133.

To read these on a new machine, without needing Karabiner installed:

```bash
ioreg -r -c IOHIDDevice -d 1 | grep -E '"(Product|VendorID|ProductID)"'
```

## Gotchas

- **Never symlink `karabiner.json`.** Karabiner's file watcher stops reloading if it is a
  symlink. Not an issue here — `~/.config` is the repo, so the file is real and tracked.
- **Karabiner ignores pointing devices by default.** The `devices[]` entry with
  `"ignore": false` is what enables the mouse. Without it every rule silently no-ops, and
  the GUI's Devices tab is the only other way to set it.
- **`shell_command` runs with a near-empty environment** — `$HOME`, `$USER`, `$UID` and
  little else. `aerospace` must be called by absolute path (`/opt/homebrew/bin/aerospace`).
  Same class of failure as MCP servers not seeing the shell's aliases. The documented
  alternative, a root-owned `/Library/Application Support/org.pqrs/config/karabiner_environment`,
  lives outside the repo and is therefore unmanageable.
- **`spans-displays` needs a logout.** `killall` does not apply it.
- **AeroSpace tiles everything the moment it launches.** Write config before first run.
- **Keep `persistent-workspaces` short.** `workspace next|prev` walks every workspace on the
  monitor in alphabetical order including empty ones, and the thumb buttons drive exactly
  that command. The upstream default of 31 workspaces makes the mouse binding unusable.

## Manual steps

Not scriptable — TCC and system extension approvals are deliberately user-gated:

1. Approve the DriverKit extension: **System Settings → General → Login Items & Extensions
   → Driver Extensions** → `Karabiner-DriverKit-VirtualHIDDevice`.
2. Grant Karabiner **Input Monitoring** and **Accessibility**.
3. Grant AeroSpace **Accessibility**.
4. Log out and back in for `spans-displays`.

MDM permits all of this: `com.apple.system-extension-policy` sets `AllowUserOverrides = true`,
so its allowlist is pre-approval rather than a restriction. Were that `false`, step 1 would
be impossible at any privilege level and the scroll problem would have no answer here.
