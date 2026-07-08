# July

**July** is a [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/) script for **Havoc** on Roblox (place `16530963934`).

NPC ESP, loot ESP, trap ESP, aimbot, silent aim, target gear viewer, and config save/load — all from one loadstring.

---

## Quick load

```lua
utility.load_url("https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/july.lua")
```

Menu: **Scripts → July**

---

## Features

| Category | What's included |
|----------|-----------------|
| **Aimbot** | NPC aimbot with FOV, target line, sticky lock |
| **Silent Aim** | Players + NPCs, wallbang, bullet TP, bullet manip, full filter/target options |
| **NPC Visuals** | Multi-select display options with per-type default colors |
| **Loot** | Multi-select loot types dropdown (33+ types) with themed colors |
| **Traps** | Multi-select trap types with default warning colors |
| **Target Gear** | Shows locked aimbot/silent target loadout with item icons |
| **Config** | Save/load to `C:/July_Config.txt` |

---

## Development

```bash
npm run build           # bundle src/ → july.lua
npm run extract-dump    # parse rbxlx → dump/
npm run download-missing # pull decal PNGs (rate-limited)
```

### Repo layout

| Path | Purpose |
|------|---------|
| `load.lua` | One-line loadstring |
| `july.lua` | Bundled runtime |
| `src/` | Modular source |
| `scripts/` | Bundle + dump/asset tools |
| `assets/decals/` | CDN images |
| `dump/` | Game reference (local, gitignored) |

---

## Disclaimer

For educational use. Not affiliated with Project Vector or Havoc.
