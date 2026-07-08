#!/usr/bin/env node
/**
 * Builds july.lua - the single Vector-executable script.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(ROOT, "july.lua");

const ORDER = [
  "core/constants.lua",
  "core/env.lua",
  "core/debug.lua",
  "core/settings.lua",
  "core/cache.lua",
  "core/session.lua",
  "core/feature_bind.lua",
  "core/menu_util.lua",
  "core/math_util.lua",
  "core/color_util.lua",
  "core/scan_yield.lua",
  "core/scan_async.lua",
  "core/draw_util.lua",
  "game/asset_urls.lua",
  "core/image_cache.lua",
  "core/world_vis.lua",
  "game/item_tiers.lua",
  "game/tier_util.lua",
  "game/hitparts.lua",
  "game/loot_catalog.lua",
  "game/trap_types.lua",
  "game/havoc_sync.lua",
  "game/havoc_item_catalog.lua",
  "game/havoc_icons.lua",
  "game/item_images.lua",
  "game/items.lua",
  "game/weapons.lua",
  "game/target_gear.lua",
  "game/combat_stats.lua",
  "game/combat_origin.lua",
  "game/npc_types.lua",
  "game/entity_scan.lua",
  "game/loot_scan.lua",
  "game/trap_scan.lua",
  "core/esp_scheduler.lua",
  "core/esp_render.lua",
  "features/combat/combat_menu.lua",
  "menu/menu_defs.lua",
  "features/utility/config.lua",
  "features/combat/targeting.lua",
  "features/combat/aimbot.lua",
  "features/visuals/npc_esp.lua",
  "features/visuals/loot_esp.lua",
  "features/visuals/trap_esp.lua",
  "features/visuals/aimbot_visuals.lua",
  "features/visuals/target_gear_viewer.lua",
  "menu/tabs.lua",
  "app.lua",
];

const header = `--[[
    July - Havoc for Project Vector
    https://github.com/Cunzaki/July
    Built: ${new Date().toISOString()}
]]

July = {
    version = "0.10.1",
    debug = false,
    _mods = {},
    bundled = true,
}

if menu and menu.add_tab then
    menu.add_tab("July", "J", "full")
end
July._menu_tab_ready = true

function July.require(path)
    local mod = July._mods[path]
    if mod == nil then
        error("[July] bundled module missing: " .. path)
    end
    return mod
end

`;

const footer = `
do
    July.require("menu.tabs").register_all()
end

July._init_ok = false

local ok, err = pcall(function()
    local debug = July.require("core.debug")
    local app = July.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false")
        return
    end

    July._init_ok = true

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
        return
    end

    print("[July] v" .. (July.version or "dev") .. " ready - open Scripts then July")
end)

if not ok then
    print("[July] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
end
`;

let body = "";
for (const rel of ORDER) {
  const full = path.join(SRC, rel);
  if (!fs.existsSync(full)) {
    console.error("Missing:", rel);
    process.exit(1);
  }
  const modPath = rel.replace(/\.lua$/, "").replace(/\//g, ".");
  const src = fs.readFileSync(full, "utf8");
  body += `\n-- ── ${rel} ──\n`;
  body += `July._mods["${modPath}"] = (function()\n${src}\nend)()\n`;
}

fs.writeFileSync(OUT, header + body + footer);
console.log("Built", path.relative(ROOT, OUT), `(${(fs.statSync(OUT).size / 1024).toFixed(1)} KB)`);
