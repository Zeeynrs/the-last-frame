# MCP Config Examples (Templates Only)

These are examples for MCP-capable agent CLIs, not an Orca-wide config. Check each CLI's current docs and use its actual configuration path.

## Pixelorama Integration Note

Pixelorama (https://github.com/Orama-Interactive/Pixelorama) operates as the primary GUI pixel-art editor for `.pxo` files and runtime PNG spritesheet generation. It does not require a dedicated Node MCP daemon; Argon manages `.pxo` source assets directly.

## Standard JSON shape — Godot AI Workbench

```json
{
  "mcpServers": {
    "godot-ai-workbench": {
      "command": "C:/Tools/godot-ai-workbench/bin/gaw.exe",
      "args": ["--tool-mode", "lite"]
    }
  }
}
```

Merge entries into the client configuration; do not replace an existing file wholesale. Replace paths with verified local paths. Do not commit local configs containing secrets. Configure Claude Code and Gemini CLI separately if both need the tools.
