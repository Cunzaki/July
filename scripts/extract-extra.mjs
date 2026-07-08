import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT = path.join(process.env.LOCALAPPDATA || "", "Volt", "workspace", "place 16530963934 Game(2).rbxlx");
const input = process.argv[2] || DEFAULT;
const text = fs.readFileSync(input, "utf8");

const lootTypes = new Set();
const lootRe = /Name"><!\[CDATA\[lootType\]\]><\/string>[\s\S]*?Value"><!\[CDATA\[([^\]]+)\]\]>/g;
let m;
while ((m = lootRe.exec(text)) !== null) lootTypes.add(m[1].trim());

const tierAnchor = text.indexOf('type = "mythic"');
const tierStart = tierAnchor > 0 ? text.lastIndexOf("local t = {", tierAnchor) : -1;
const tierEnd = tierStart > 0 ? text.indexOf("\nlocal t2", tierStart) : -1;
const tierBlockText = tierStart > 0 && tierEnd > tierStart ? text.slice(tierStart, tierEnd) : "";

const tierColors = {};
if (tierBlockText) {
  const entryRe = /(\w+)\s*=\s*\{([^}]*)\}/g;
  let em;
  while ((em = entryRe.exec(tierBlockText)) !== null) {
    const body = em[2];
    const typeM = body.match(/type\s*=\s*"([^"]+)"/);
    const levelM = body.match(/tierLevel\s*=\s*(\d+)/);
    const colorM = body.match(/color\s*=\s*Color3\.fromRGB\((\d+),\s*(\d+),\s*(\d+)\)/);
    if (typeM && colorM) {
      tierColors[em[1]] = {
        type: typeM[1],
        level: levelM ? +levelM[1] : 1,
        r: +colorM[1],
        g: +colorM[2],
        b: +colorM[3],
      };
    }
  }
}

function brightenEsp(r, g, b) {
  const rf = r / 255;
  const gf = g / 255;
  const bf = b / 255;
  const max = Math.max(rf, gf, bf, 0.001);
  const target = 0.82;
  const scale = target / max;
  return [
    Math.min(rf * scale, 1).toFixed(3),
    Math.min(gf * scale, 1).toFixed(3),
    Math.min(bf * scale, 1).toFixed(3),
    "1",
  ];
}

const ESP_TIER = {};
for (const [key, val] of Object.entries(tierColors)) {
  ESP_TIER[key] = brightenEsp(val.r, val.g, val.b);
}

function parseItemsBlock(block) {
  const weaponTiers = {};
  let currentName = null;
  for (const line of block.split("\n")) {
    const quoted = line.match(/^\t\t\["((?:\\.|[^"\\])*)"\]\s*=\s*\{/);
    const ident = line.match(/^\t\t([A-Za-z0-9][A-Za-z0-9_\-.']*)\s*=\s*\{/);
    if (quoted) {
      currentName = quoted[1].replace(/\\'/g, "'").replace(/\\"/g, '"').replace(/\\\\/g, "\\");
    } else if (ident) {
      currentName = ident[1];
    }
    const tier = line.match(/tierColor\s*=\s*t\.(\w+)\.color/);
    if (tier && currentName) {
      weaponTiers[currentName] = tier[1];
      currentName = null;
    }
  }
  return weaponTiers;
}

const itemsStart = text.indexOf("items = {");
const itemsEnd = itemsStart > 0 ? text.indexOf("\n\tattachments = {", itemsStart + 10) : -1;
const itemsBlock = itemsStart > 0 && itemsEnd > itemsStart ? text.slice(itemsStart, itemsEnd) : "";
const weaponTiers = itemsBlock ? parseItemsBlock(itemsBlock) : {};

const keycards = [...text.matchAll(/Name"><!\[CDATA\[(FORTIS Level-\d keycard|Keycard holder[^\]]*)\]\]>/g)].map((x) => x[1]);
const keycardUnique = [...new Set(keycards)].sort();

const out = path.join(ROOT, "dump");
fs.mkdirSync(out, { recursive: true });
fs.writeFileSync(path.join(out, "loot_types_full.txt"), [...lootTypes].sort().join("\n"));
fs.writeFileSync(path.join(out, "keycards.txt"), keycardUnique.join("\n"));
fs.writeFileSync(path.join(out, "tier_colors.json"), JSON.stringify(tierColors, null, 2));
fs.writeFileSync(path.join(out, "weapon_tiers.json"), JSON.stringify(weaponTiers, null, 2));

const luaLines = [
  "-- Auto-generated from Havoc dump. Run: node scripts/extract-extra.mjs",
  "local M = {}",
  "",
  "M.TIER_GAME = {",
];
for (const [k, v] of Object.entries(tierColors).sort((a, b) => a[0].localeCompare(b[0]))) {
  luaLines.push(`    ${k} = { level = ${v.level}, type = "${v.type}", r = ${v.r}, g = ${v.g}, b = ${v.b} },`);
}
luaLines.push("}", "", "M.TIER_ESP = {");
for (const [k, v] of Object.entries(ESP_TIER).sort((a, b) => a[0].localeCompare(b[0]))) {
  luaLines.push(`    ${k} = { ${v.join(", ")} },`);
}
luaLines.push("}", "", "M.ITEM_TIER = {");
for (const [name, tier] of Object.entries(weaponTiers).sort((a, b) => a[0].localeCompare(b[0]))) {
  const safe = name.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  luaLines.push(`    ["${safe}"] = "${tier}",`);
}
luaLines.push("}", "", "M.KEYCARDS = {");
for (const k of keycardUnique) {
  const safe = k.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  luaLines.push(`    ["${safe}"] = true,`);
}
luaLines.push("}", "", "return M", "");

fs.writeFileSync(path.join(ROOT, "src", "game", "item_tiers.lua"), luaLines.join("\n"));

console.log("loot types:", lootTypes.size);
console.log("keycards:", keycardUnique.length);
console.log("tier defs:", Object.keys(tierColors).length);
console.log("weapon tiers:", Object.keys(weaponTiers).length);
