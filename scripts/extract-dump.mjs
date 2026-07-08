#!/usr/bin/env node
/**
 * Full workspace extraction from an RBXLX dump.
 *
 * Usage: node scripts/extract-dump.mjs [path-to.rbxlx]
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { extractFullDump } from "./extract-full-dump.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_DUMP = path.join(
  process.env.LOCALAPPDATA || "",
  "Volt",
  "workspace",
  "place 16530963934 Game(2).rbxlx"
);

const OUT_DIR = path.join(ROOT, "dump");

const input = process.argv[2] || DEFAULT_DUMP;

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function extractAll(text, pattern, group = 1) {
  const out = new Set();
  const re = new RegExp(pattern, "g");
  let m;
  while ((m = re.exec(text)) !== null) {
    out.add(m[group].trim());
  }
  return [...out].sort();
}

function extractClassCounts(text) {
  const counts = {};
  const re = /class="([^"]+)"/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    counts[m[1]] = (counts[m[1]] || 0) + 1;
  }
  return Object.fromEntries(
    Object.entries(counts).sort((a, b) => b[1] - a[1])
  );
}

function extractNames(text, className) {
  const names = new Set();
  const chunks = text.split(`class="${className}"`);
  for (let i = 1; i < chunks.length; i++) {
    const chunk = chunks[i].slice(0, 2500);
    const nameM = chunk.match(/Name"><!\[CDATA\[([^\]]+)\]\]>/);
    if (nameM) names.add(nameM[1].trim());
  }
  return [...names].sort();
}

function extractAssetIds(text) {
  const ids = new Set();
  const re = /rbxassetid:\/\/(\d+)/g;
  let m;
  while ((m = re.exec(text)) !== null) ids.add(m[1]);
  return [...ids].sort((a, b) => Number(a) - Number(b));
}

function extractLootTypes(text) {
  const types = new Set();
  const re = /Name"><!\[CDATA\[lootType\]\]><\/string>[\s\S]*?Value"><!\[CDATA\[([^\]]+)\]\]>/g;
  let m;
  while ((m = re.exec(text)) !== null) types.add(m[1].trim());
  return [...types].sort();
}

function extractLootModelNames(text) {
  const names = new Set();
  const re = /class="Model"[\s\S]{0,8000}?Name"><!\[CDATA\[lootType\]\]>/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const chunk = m[0];
    const nameM = chunk.match(/class="Model"[\s\S]*?Name"><!\[CDATA\[([^\]]+)\]\]>/);
    if (nameM) names.add(nameM[1].trim());
  }
  return [...names].sort();
}

function extractGunConfigKeys(text) {
  const keys = new Set();
  const blocks = text.match(/local t = \{[\s\S]*?\n\}/g) || [];
  for (const block of blocks) {
    if (!block.includes("recoil = {") || !block.includes("vPunchBase")) continue;
    const re = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=/gm;
    let m;
    while ((m = re.exec(block)) !== null) keys.add(m[1]);
    const recoilBlock = block.match(/recoil = \{([\s\S]*?)\n\t\}/);
    if (recoilBlock) {
      const recoilRe = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=/gm;
      let rm;
      while ((rm = recoilRe.exec(recoilBlock[1])) !== null) {
        keys.add(`recoil.${rm[1]}`);
      }
    }
  }
  return [...keys].sort();
}

function extractModulePaths(text) {
  const paths = new Set();
  const re = /require\(game\.ReplicatedStorage[^)]+\)/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const cleaned = m[0]
      .replace(/require\(game\.ReplicatedStorage:WaitForChild\("([^"]+)"\)/g, "$1/")
      .replace(/:WaitForChild\("([^"]+)"\)/g, "/$1")
      .replace(/require\(game\.ReplicatedStorage/, "ReplicatedStorage")
      .replace(/\)\(script\)$/, "")
      .replace(/\)$/, "");
    paths.add(cleaned);
  }
  return [...paths].sort();
}

function extractNpcNames(text) {
  const names = new Set();
  const patterns = [
    /\[Sniper\][A-Za-z0-9 _-]+/g,
    /Name"><!\[CDATA\[(Sentry|Reshala|Killa|Tagilla|Birdeye|Knight|Glukhar)[^\]]*\]\]>/g,
  ];
  for (const re of patterns) {
    let m;
    while ((m = re.exec(text)) !== null) {
      const val = m[1] || m[0];
      if (val) names.add(val.replace(/^Name"><!\[CDATA\[|\]\]>$/, "").trim());
    }
  }
  return [...names].sort();
}

function extractTrapKeywords(text) {
  const traps = new Set();
  const keywords = [
    "Tripmine", "TripMine", "Mine", "Alarm", "Airstrike", "ExplosiveBarrel",
    "Sentry", "Toxic", "Gas", "Claymore", "Grenade", "Trap",
  ];
  const nameRe = /Name"><!\[CDATA\[([^\]]+)\]\]>/g;
  let m;
  while ((m = nameRe.exec(text)) !== null) {
    const name = m[1];
    for (const kw of keywords) {
      if (name.toLowerCase().includes(kw.toLowerCase())) {
        traps.add(name);
        break;
      }
    }
  }
  return [...traps].sort();
}

function extractDecalIds(text) {
  const decals = new Map();
  const chunks = text.split('class="Decal"');
  for (let i = 1; i < chunks.length; i++) {
    const chunk = chunks[i].slice(0, 4000);
    const nameM = chunk.match(/Name"><!\[CDATA\[([^\]]+)\]\]>/);
    const texM = chunk.match(/(?:Texture|TextureID|Image)"><!\[CDATA\[(rbxassetid:\/\/\d+)\]\]>/)
      || chunk.match(/Content name="Texture"><!\[CDATA\[(rbxassetid:\/\/\d+)\]\]>/)
      || chunk.match(/(rbxassetid:\/\/\d+)/);
    if (texM) {
      const id = texM[1].replace("rbxassetid://", "");
      decals.set(id, nameM ? nameM[1] : `decal_${id}`);
    }
  }
  return decals;
}

function extractImageLabelIds(text) {
  const images = new Map();
  const chunks = text.split('class="ImageLabel"');
  for (let i = 1; i < chunks.length; i++) {
    const chunk = chunks[i].slice(0, 4000);
    const nameM = chunk.match(/Name"><!\[CDATA\[([^\]]+)\]\]>/);
    const imgM = chunk.match(/Image"><!\[CDATA\[(rbxassetid:\/\/\d+)\]\]>/)
      || chunk.match(/(rbxassetid:\/\/\d+)/);
    if (imgM) {
      const id = imgM[1].replace("rbxassetid://", "");
      images.set(id, nameM ? nameM[1] : `img_${id}`);
    }
  }
  return images;
}

function extractToolTextureIds(text) {
  const tools = new Map();
  const chunks = text.split('class="Tool"');
  for (let i = 1; i < chunks.length; i++) {
    const chunk = chunks[i].slice(0, 6000);
    const nameM = chunk.match(/Name"><!\[CDATA\[([^\]]+)\]\]>/);
    const texM = chunk.match(/TextureId"><!\[CDATA\[(rbxassetid:\/\/\d+)\]\]>/)
      || chunk.match(/(rbxassetid:\/\/\d+)/);
    if (texM && nameM) {
      const id = texM[1].replace("rbxassetid://", "");
      tools.set(id, { name: nameM[1], type: "tool_icon" });
    }
  }
  return tools;
}

function buildGameReference(data) {
  const lines = [
    "# Havoc — Full Game Reference",
    `# Place ID: ${data.placeId}`,
    `# Extracted: ${data.extractedAt}`,
    `# Source: ${data.sourceFile} (${(data.sourceSizeBytes / 1024 / 1024).toFixed(1)} MB)`,
    "",
    "## Summary",
    "",
    `- Asset IDs: ${data.counts.assetIds}`,
    `- Tools/Weapons: ${data.counts.tools}`,
    `- Loot types: ${data.counts.lootTypes}`,
    `- Loot model names: ${data.counts.lootModels}`,
    `- Decals/Images: ${data.counts.decals}`,
    `- Remote events: ${data.counts.remoteEvents}`,
    `- Remote functions: ${data.counts.remoteFunctions}`,
    `- Module scripts: ${data.counts.moduleScripts}`,
    `- Trap-related names: ${data.counts.traps}`,
    "",
    "## Workspace Layout",
    "",
    "Workspace/",
    "├── __viewmodel/",
    "├── Buildings/",
    "│   ├── Objects/",
    "│   ├── Loots/ (Ammo, Bodies, Objects, Doors, Interactable, Loots/Crates, Loots/Stashes)",
    "│   └── Glass/",
    "├── Ignored/",
    "└── [NPC folder] via GetGSync RemoteFunction",
    "",
    "## Loot Model Pattern",
    "",
    "Model → data/ (Configuration)",
    "  ├── lootType (StringValue)",
    "  ├── isOpen (BoolValue)",
    "  └── isLocked (BoolValue)",
    "",
    "## Combat / Guns",
    "",
    "- Client: ReplicatedStorage.Storage.Modules.Frameworks.Guns.Client",
    "- Grenades: ReplicatedStorage.Storage.Modules.Frameworks.Grenades.Client",
    "- Fire: Network:FireServer('fire', ...) + Events.server:Fire('damage', ...) for NPCs",
    "- Ray length: 1024 studs",
    "- Muzzle: MuzzleFX on weapon Handle, fallback Head",
    "- Team: Humanoid:GetAttribute('Team')",
    "- Boss: Character:GetAttribute('Boss')",
    "",
    "## GC Weapon Mod Keys (from gun configs)",
    "",
    ...data.gunConfigKeys.map((k) => `- ${k}`),
    "",
    "## NPC Discovery",
    "",
    "shared.charactersFolderName = ReplicatedStorage.Storage.Events.GetGSync:InvokeServer()",
    "",
  ];

  if (data.lootTypes.length) {
    lines.push("## Loot Types", "");
    for (const t of data.lootTypes) lines.push(`- ${t}`);
    lines.push("");
  }

  if (data.lootModels.length) {
    lines.push("## Loot Model Names (sample)", "");
    for (const t of data.lootModels.slice(0, 60)) lines.push(`- ${t}`);
    if (data.lootModels.length > 60) lines.push(`- ... and ${data.lootModels.length - 60} more`);
    lines.push("");
  }

  if (data.tools.length) {
    lines.push("## Weapons / Tools", "");
    for (const t of data.tools) lines.push(`- ${t}`);
    lines.push("");
  }

  if (data.traps.length) {
    lines.push("## Trap / Hazard Names", "");
    for (const t of data.traps.slice(0, 40)) lines.push(`- ${t}`);
    if (data.traps.length > 40) lines.push(`- ... and ${data.traps.length - 40} more`);
    lines.push("");
  }

  if (data.npcNames.length) {
    lines.push("## NPC Names Found", "");
    for (const t of data.npcNames) lines.push(`- ${t}`);
    lines.push("");
  }

  if (data.modulePaths.length) {
    lines.push("## Key Module Paths", "");
    for (const t of data.modulePaths.slice(0, 40)) lines.push(`- ${t}`);
    lines.push("");
  }

  if (data.remoteEvents.length) {
    lines.push("## Remote Events (sample)", "");
    for (const t of data.remoteEvents.slice(0, 50)) lines.push(`- ${t}`);
    if (data.remoteEvents.length > 50) lines.push(`- ... and ${data.remoteEvents.length - 50} more`);
    lines.push("");
  }

  lines.push("## Top Instance Classes", "");
  const topClasses = Object.entries(data.classCounts).slice(0, 25);
  for (const [cls, count] of topClasses) lines.push(`- ${cls}: ${count}`);
  lines.push("");

  return lines.join("\n");
}

async function main() {
  if (!fs.existsSync(input)) {
    console.error("Dump not found:", input);
    console.error("Usage: node scripts/extract-dump.mjs [path-to.rbxlx]");
    process.exit(1);
  }

  console.log("Reading dump:", input);
  const text = fs.readFileSync(input, "utf8");
  const stat = fs.statSync(input);

  const assetIds = extractAssetIds(text);
  const tools = extractNames(text, "Tool");
  const lootTypes = extractLootTypes(text);
  const lootModels = extractLootModelNames(text);
  const gunConfigKeys = extractGunConfigKeys(text);
  const modulePaths = extractModulePaths(text);
  const npcNames = extractNpcNames(text);
  const traps = extractTrapKeywords(text);
  const remoteEvents = extractNames(text, "RemoteEvent");
  const remoteFunctions = extractNames(text, "RemoteFunction");
  const classCounts = extractClassCounts(text);
  const decals = extractDecalIds(text);
  const images = extractImageLabelIds(text);
  const toolTextures = extractToolTextureIds(text);

  const decalManifest = {};
  for (const [id, name] of decals) decalManifest[id] = { name, type: "decal" };
  for (const [id, name] of images) {
    if (!decalManifest[id]) decalManifest[id] = { name, type: "image" };
  }
  for (const [id, info] of toolTextures) {
    if (!decalManifest[id]) decalManifest[id] = { name: info.name, type: info.type };
  }

  const placeId = "16530963934";
  const extractedAt = new Date().toISOString();

  const manifest = {
    placeId,
    extractedAt,
    sourceFile: path.basename(input),
    sourceSizeBytes: stat.size,
    counts: {
      assetIds: assetIds.length,
      tools: tools.length,
      lootTypes: lootTypes.length,
      lootModels: lootModels.length,
      decals: Object.keys(decalManifest).length,
      remoteEvents: remoteEvents.length,
      remoteFunctions: remoteFunctions.length,
      moduleScripts: classCounts.ModuleScript || 0,
      traps: traps.length,
    },
    classCounts,
    assetIds,
    tools,
    lootTypes,
    lootModels,
    gunConfigKeys,
    modulePaths,
    npcNames,
    traps,
    remoteEvents,
    remoteFunctions,
    decals: decalManifest,
  };

  ensureDir(OUT_DIR);

  const gameRef = buildGameReference({
    placeId,
    extractedAt,
    sourceFile: path.basename(input),
    sourceSizeBytes: stat.size,
    counts: manifest.counts,
    lootTypes,
    lootModels,
    tools,
    traps,
    npcNames,
    modulePaths,
    remoteEvents,
    gunConfigKeys,
    classCounts,
  });

  const gameDataDir = path.join(OUT_DIR, "game-data");
  ensureDir(gameDataDir);
  ensureDir(path.join(OUT_DIR, "assets"));

  fs.writeFileSync(path.join(OUT_DIR, "GAME_REFERENCE.txt"), gameRef);
  fs.writeFileSync(path.join(gameDataDir, "loot_models.txt"), lootModels.join("\n"));
  fs.writeFileSync(path.join(gameDataDir, "traps.txt"), traps.join("\n"));
  fs.writeFileSync(path.join(gameDataDir, "gun_config_keys.txt"), gunConfigKeys.join("\n"));
  fs.writeFileSync(path.join(gameDataDir, "module_paths.txt"), modulePaths.join("\n"));
  fs.writeFileSync(path.join(gameDataDir, "npc_names.txt"), npcNames.join("\n"));
  fs.writeFileSync(path.join(OUT_DIR, "assets", "decals.json"), JSON.stringify(decalManifest, null, 2));

  console.log(`Metadata: ${assetIds.length} asset IDs, ${tools.length} tools, ${lootTypes.length} loot types`);
  console.log(`Metadata: ${traps.length} traps, ${Object.keys(decalManifest).length} decals/images`);

  console.log("\nFull tree + script extraction...");
  const fullStats = extractFullDump(text, input, OUT_DIR, {
    placeId,
    extractedAt,
    sourceFile: path.basename(input),
    sourceSizeBytes: stat.size,
    metadata: {
      lootModels,
      gunConfigKeys,
      modulePaths,
      npcNames,
      traps,
      decals: decalManifest,
    },
  });

  const mergedManifest = {
    ...manifest,
    ...fullStats,
    metadata: {
      lootModels,
      gunConfigKeys,
      modulePaths,
      npcNames,
      traps,
      decals: decalManifest,
    },
  };
  fs.writeFileSync(path.join(OUT_DIR, "manifest.json"), JSON.stringify(mergedManifest, null, 2));

  console.log(`\nDone. ${fullStats.scripts.total} scripts, ${fullStats.instances.total.toLocaleString()} instances`);
  console.log("Wrote dump/ (scripts/, catalog/, instances/, game-data/, assets/)");

  const staleRoot = [
    "asset_ids.txt",
    "class_counts.json",
    "tools.txt",
    "loot_types.txt",
    "loot_models.txt",
    "traps.txt",
    "gun_config_keys.txt",
    "remote_events.txt",
    "remote_functions.txt",
    "module_paths.txt",
  ];
  for (const name of staleRoot) {
    const p = path.join(OUT_DIR, name);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  }

  for (const name of ["weapon_tiers.json", "tier_colors.json", "keycards.txt", "loot_types_full.txt"]) {
    const src = path.join(OUT_DIR, name);
    const dest = path.join(gameDataDir, name);
    if (fs.existsSync(src) && !fs.existsSync(dest)) fs.renameSync(src, dest);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
