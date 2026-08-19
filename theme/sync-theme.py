#!/usr/bin/env python3
"""Render every themed config in this repo from palette.toml.

Two strategies, chosen by which directory a file lives in:

  templates/<path>.tmpl  Files this repo authors. {{slot}} is substituted.
  upstream/<path>        Vendored theme files. Hex literals are rewritten
                         through palette [source]; everything else is left
                         byte-for-byte, so refreshing from upstream is a copy.

In both cases the path under the strategy directory IS the destination path
relative to ~/.config, so adding a file needs no registration here.

Contrast is asserted before anything is written. A retune that pushes chrome
below its floor fails the run rather than shipping an unreadable status bar.
"""

import pathlib
import re
import sys
import tomllib

ROOT = pathlib.Path(__file__).resolve().parent
CONFIG = ROOT.parent
TEMPLATES = ROOT / "templates"
UPSTREAM = ROOT / "upstream"

HEX = re.compile(r"#[0-9a-fA-F]{6}\b")
PLACEHOLDER = re.compile(r"\{\{\s*(\w+)(?::(\w+))?\s*\}\}")


def luminance(hex_colour):
    h = hex_colour.lstrip("#")
    channels = [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(fg, bg):
    a, b = luminance(fg), luminance(bg)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


def load_palette():
    palette = tomllib.loads((ROOT / "palette.toml").read_text(encoding="utf-8"))

    # This repo is shared, so palette.toml is the house theme. palette.local.toml
    # is untracked and overrides individual slots, letting one person retheme
    # their own machine without forking every template.
    local = ROOT / "palette.local.toml"
    if local.exists():
        override = tomllib.loads(local.read_text(encoding="utf-8"))
        palette["slots"].update(override.get("slots", {}))
        palette["source"].update(override.get("source", {}))
    if palette.get("schemaVersion") != 1:
        sys.exit(f"palette.toml: unsupported schemaVersion {palette.get('schemaVersion')!r}")

    slots = palette["slots"]
    bad = [f"{k} = {v!r}" for k, v in slots.items() if not HEX.fullmatch(v)]
    if bad:
        sys.exit("palette.toml: slots must be #rrggbb — " + ", ".join(bad))

    unknown = {s for s in palette["source"].values() if s not in slots}
    if unknown:
        sys.exit(f"palette.toml: [source] maps to undefined slots: {sorted(unknown)}")

    failures = []
    for rule in palette.get("contrast", []):
        ratio = contrast(slots[rule["fg"]], slots[rule["bg"]])
        if ratio < rule["min"]:
            failures.append(f"  {rule['fg']} on {rule['bg']}: {ratio:.2f}:1 < {rule['min']}")
    if failures:
        sys.exit("contrast floor breached:\n" + "\n".join(failures))

    return slots, {k.lower(): slots[v] for k, v in palette["source"].items()}


def render_template(text, slots, origin):
    missing = {m.group(1) for m in PLACEHOLDER.finditer(text)} - slots.keys()
    if missing:
        sys.exit(f"{origin}: unknown slots {sorted(missing)}")

    def substitute(match):
        slot, fmt = match.group(1), match.group(2)
        value = slots[slot]
        if fmt is None:
            return value
        if fmt == "rgb":
            # ANSI truecolor wants decimal triples; the 256-colour cube cannot
            # hit an arbitrary palette exactly, so escapes are built from these.
            h = value.lstrip("#")
            return ";".join(str(int(h[i : i + 2], 16)) for i in (0, 2, 4))
        sys.exit(f"{origin}: unknown format {fmt!r} on slot {slot!r}")

    return PLACEHOLDER.sub(substitute, text)


def render_upstream(text, source, unmapped):
    def swap(match):
        found = match.group(0).lower()
        if found in source:
            return source[found]
        unmapped[found] = unmapped.get(found, 0) + 1
        return match.group(0)

    return HEX.sub(swap, text)


def main():
    check = "--check" in sys.argv
    slots, source = load_palette()
    unmapped, drifted, written = {}, [], 0

    jobs = [(p, TEMPLATES, p.relative_to(TEMPLATES).with_suffix("")) for p in TEMPLATES.rglob("*.tmpl")]
    jobs += [(p, UPSTREAM, p.relative_to(UPSTREAM)) for p in UPSTREAM.rglob("*") if p.is_file()]

    for src, strategy, relative in jobs:
        text = src.read_text(encoding="utf-8")
        if strategy is TEMPLATES:
            rendered = render_template(text, slots, src)
        else:
            rendered = render_upstream(text, source, unmapped)

        target = CONFIG / relative
        if target.exists() and target.read_text(encoding="utf-8") == rendered:
            continue
        if check:
            drifted.append(str(relative))
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(rendered, encoding="utf-8")
        print(f"  rendered {relative}")
        written += 1

    if unmapped:
        print("\n  unmapped hexes (still upstream colours) — add to [source] to adopt:")
        for colour, count in sorted(unmapped.items(), key=lambda kv: -kv[1]):
            print(f"    {colour}  x{count}")

    if check and drifted:
        sys.exit("\nout of date, run sync-theme.py:\n" + "\n".join(f"  {d}" for d in drifted))
    print(f"\n{'in sync' if check else f'{written} file(s) written'} — palette '{slots['accent']}' accent")


if __name__ == "__main__":
    main()
