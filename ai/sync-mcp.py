#!/usr/bin/env python3
"""Render tool-specific MCP configs from the canonical definitions.

Claude Code's ~/.claude.json is a mutable state file, so its mcpServers key is
merged in place rather than overwritten.
"""

import json
import pathlib
import sys

HOME = pathlib.Path.home()
CANONICAL = pathlib.Path(__file__).parent / "mcp-servers.json"
CLAUDE = HOME / ".claude.json"
COPILOT = HOME / ".copilot" / "mcp-config.json"

STDIO_KEYS = ("type", "command", "args", "env")
HTTP_KEYS = ("type", "url", "headers")


def shape(spec):
    keys = STDIO_KEYS if spec.get("type") == "stdio" else HTTP_KEYS
    return {k: spec[k] for k in keys if k in spec}


def selected(servers, target):
    return {n: s for n, s in servers.items() if target in s.get("targets", [])}


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def main():
    servers = json.loads(CANONICAL.read_text())["servers"]

    claude = json.loads(CLAUDE.read_text()) if CLAUDE.exists() else {}
    claude["mcpServers"] = {n: shape(s) for n, s in selected(servers, "claude").items()}
    write_json(CLAUDE, claude)

    copilot = {
        "mcpServers": {
            n: {"tools": ["*"], **shape(s)}
            for n, s in selected(servers, "copilot").items()
        }
    }
    write_json(COPILOT, copilot)

    print(f"claude  -> {sorted(claude['mcpServers'])}")
    print(f"copilot -> {sorted(copilot['mcpServers'])}")


if __name__ == "__main__":
    sys.exit(main())
