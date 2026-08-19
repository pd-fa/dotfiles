# macOS input and window management

Replaces two GUI apps whose state this repo could not track.

| Was | Now | Why it moved |
| --- | --- | --- |
| Mos | Hammerspoon | Mos kept state in a binary plist under `~/Library/Preferences` |
| BetterTouchTool | Hammerspoon + AeroSpace | BTT kept state in an opaque sqlite blob |

```
~/.config/aerospace/aerospace.toml    tiling, workspaces, keyboard bindings
~/.config/hammerspoon/init.lua        scroll direction + thumb buttons
~/.config/macos/defaults.sh           the one system default AeroSpace requires
```

AeroSpace is read straight from `~/.config`, which **is** this repo, so it needs no
symlink. Hammerspoon reads `~/.hammerspoon`, so `init.lua` is the one input file the
bootstrap links. `~/.hammerspoon` itself stays a real directory — Spoons and Hammerspoon's
own state live there and are not ours.

## Why not yabai

yabai's useful half — moving windows between Spaces, driving Mission Control — needs a
scripting addition injected into `Dock.app`, which requires partially disabling SIP. This
machine is Jamf/Intune-enrolled and runs Defender, FortiClient and Admin By Request, with
`csrutil` reporting SIP enabled. AeroSpace needs no SIP change because it emulates its own
workspaces instead of driving native Spaces.

## Why not Karabiner

Karabiner-Elements is the better tool for this and was the original choice: it manipulates
the HID event stream directly and can scope rules to a specific device by vendor and
product ID. It is unusable here.

Its `org.pqrs.Karabiner-DriverKit-VirtualHIDDevice` extension installs fine and reaches
`[activated waiting for user]`, but the approval requires **System Settings → General →
Login Items & Extensions**, and that row is inert on this machine. Ruled out as causes:

- `com.apple.systempreferences` `DisabledPreferencePanes` does **not** list the pane
  (only Family, Game Center, Siri, Startup Disk, Time Machine, Wallet).
- `com.apple.system-extension-policy` sets `AllowUserOverrides = true`, so the MDM
  allowlist is pre-approval rather than restriction.
- The account is in `admin`, and a clean System Settings restart does not help.

Without that click the extension never loads, so every Karabiner rule silently no-ops.
Hammerspoon needs only an Accessibility grant and no system extension at all.

If IT ever adds team ID `G43BCU2T37` to the `AllowedSystemExtensions` payload — as they
already do for OneDrive (`UBF8T346G9`) and Cisco (`DE8Y96K9QP`) — Karabiner becomes viable
and is worth reconsidering.

## Scroll direction without device identification

macOS has exactly one scroll-direction setting, `com.apple.swipescrolldirection`, applied
to every pointing device at once. There is no per-device toggle to `defaults write`, which
is why Mos existed.

Hammerspoon cannot see which device sent an event, so it distinguishes them by event shape
instead. Trackpads emit pixel-precise **continuous** scroll events with momentum phases; a
notched wheel emits **discrete** ticks. Inverting only the discrete ones leaves the
trackpad natural:

```lua
if event:getProperty(props.scrollWheelEventIsContinuous) ~= 0 then return false end
```

This is a heuristic about the event, not a fact about the device. A Magic Mouse or any
other free-spinning wheel scrolls continuously and would be treated as a trackpad. For a
notched wheel it is exact.

## Gotchas

- **Event taps are garbage collected.** `hs.eventtap` objects stop firing the moment
  nothing references them, with no error. They must be held in module-level locals, never
  in a function scope.
- **A running Hammerspoon is not a working one.** Without Accessibility the taps start and
  then never fire. `require("hs.ipc")` exposes `hs -c "hs.accessibilityState()"`, which is
  what `bootstrap.sh` checks instead of merely testing for the process.
- **Thumb buttons are zero-based.** The buttons sold as "mouse4"/"mouse5" report button
  numbers 3 and 4.
- **Swallow the button release too.** Passing an `otherMouseUp` whose matching down was
  consumed leaves apps that track drag state confused.
- **The config watcher must watch the repo, not `hs.configdir`.** `init.lua` is a symlink
  into this repo, and FSEvents on `~/.hammerspoon` never fires for writes to the target.
- **`spans-displays` needs a logout.** `killall` does not apply it.
- **AeroSpace tiles everything the moment it launches.** Write config before first run.
- **Keep `persistent-workspaces` short.** `workspace next|prev` walks every workspace on
  the monitor in alphabetical order, and the thumb buttons drive exactly that command. The
  upstream default of 31 workspaces makes the binding unusable. Note that a workspace
  outside the list still exists while it holds windows.

## Manual steps

Not scriptable — TCC grants are user-gated by design, which is the entire point of TCC:

1. Grant **Hammerspoon** Accessibility (System Settings → Privacy & Security).
2. Grant **AeroSpace** Accessibility.
3. Log out and back in for `spans-displays`.
