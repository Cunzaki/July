# July

**July** is a [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/) script for **Havoc** on Roblox.

NPC ESP, loot ESP, trap ESP, aimbot, weapon mods, and config save/load — all from one loadstring.

---

## Quick load

Paste this in Vector and execute:

```lua
utility.load_url("https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/july.lua")
```

Or run [`load.lua`](load.lua) from this repo.

Open the menu: **Scripts → July**

---

## Features

| Category | What's included |
|----------|-----------------|
| **Combat** | NPC aimbot (head/torso), FOV circle, target line, target lock |
| **NPC Visuals** | Box (corners/outline/3D), chams, skeleton, health, names, held item, type tags |
| **Loot** | Per-type toggles, distance, markers, locked/open filters |
| **Traps** | Tripmines, mines, alarms, airstrike, barrels, sentries, toxic gas |
| **Weapon Mods** | No recoil, no spread, no sway, fast bullet velocity |
| **Settings** | Config save/load to `C:/July_Config.txt` |

---

## Local install

**Option A — loadstring (recommended):** use the snippet above.

**Option B — run from disk:**

```bash
npm run build
```

Then load `july.lua` in Vector → **Execute Script**.

---

## Development

```bash
npm run build    # bundle src/ → july.lua
```

Edit files under `src/`, rebuild, and push `july.lua` to GitHub so the loadstring stays up to date.

### Repo layout

| Path | Purpose |
|------|---------|
| [`load.lua`](load.lua) | One-line loadstring |
| [`july.lua`](july.lua) | Bundled runtime script (what users load) |
| [`src/`](src/) | Modular source |
| [`scripts/`](scripts/) | Bundle tools |

**Local only (gitignored):** `dump/`, `references/`, `Script 1.lua`, `node_modules/`

---

## Requirements

- [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/) external
- Join a Havoc match before enabling combat features

---

## Debug

Set `July.debug = true` before or after load to print internal logs.

---

## Disclaimer

For educational use. Not affiliated with Project Vector or Havoc. Use at your own risk.
