#!/usr/bin/env node
/**
 * Extract workspace reference, asset IDs, weapons, and decals from an RBXLX dump.
 *
 * Usage: node scripts/extract-dump.mjs [path-to.rbxlx]
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_DUMP = path.join(
  process.env.LOCALAPPDATA || "",
  "Volt",
  "workspace",
  "place 16530963934 Game(2).rbxlx"
);

const OUT_DIR = path.join(ROOT, "dump");
const REF_DIR = path.join(ROOT, "references", "dump");

const input = process.argv[2] || DEFAULT_DUMP;

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function extractAssetIds(text) {
  const ids = new Set();
  const re = /rbxassetid:\/\/(\d+)/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    ids.add(m[1]);
  }
  return [...ids].sort((a, b) => Number(a) - Number(b));
}

function extractToolNames(text) {
  const names = new Set();
  const re = /class="Tool"[\s\S]*?Name"><!\[CDATA\[([^\]]+)\]\]>/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const name = m[1].trim();
    if (name && !name.startsWith("_")) names.add(name);
  }
  return [...names].sort();
}

function extractLootTypes(text) {
  const types = new Set();
  const re = /lootType[\s\S]*?Value"><!\[CDATA\[([^\]]+)\]\]>/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    types.add(m[1].trim());
  }
  return [...types].sort();
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

function extractTextureIds(text) {
  const textures = new Map();
  const re = /TextureID"><!\[CDATA\[(rbxassetid:\/\/\d+)\]\]>/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const id = m[1].replace("rbxassetid://", "");
    if (!textures.has(id)) textures.set(id, `texture_${id}`);
  }
  return textures;
}

function buildGameReference({ placeId, tools, lootTypes }) {
  const lines = [
    "# Havoc — Game Reference",
    `# Place ID: ${placeId}`,
    `# Extracted: ${new Date().toISOString()}`,
    "",
    "## Workspace Layout",
    "",
    "Workspace/",
    "├── __viewmodel/          # FPS viewmodel rig",
    "├── Buildings/",
    "│   ├── Objects/",
    "│   ├── Loots/",
    "│   │   ├── Ammo/",
    "│   │   ├── Bodies/",
    "│   │   ├── Objects/",
    "│   │   ├── Doors/",
    "│   │   ├── Interactable/",
    "│   │   └── Loots/",
    "│   │       ├── Crates/",
    "│   │       └── Stashes/",
    "│   └── Glass/",
    "├── Ignored/",
    "└── [NPC folder]          # Name from GetGSync RemoteFunction",
    "",
    "## Loot Model Pattern",
    "",
    "Model → data/ (Configuration)",
    "  ├── lootType (StringValue)",
    "  ├── isOpen (BoolValue)",
    "  └── isLocked (BoolValue)",
    "",
    "## Combat",
    "",
    "- Guns Client: ReplicatedStorage.Storage.Modules.Frameworks.Guns.Client",
    "- Fire: shared.Network:FireServer('fire', ...) + Events.server:Fire('damage', ...) for NPCs",
    "- Ray length: 1024 studs (MouseRaycast pattern)",
    "- Muzzle: MuzzleFX attachment on weapon Handle, or Head",
    "- Team: Humanoid:GetAttribute('Team')",
    "- Boss: Character:GetAttribute('Boss')",
    "",
    "## NPC Folder Discovery",
    "",
    "shared.charactersFolderName = ReplicatedStorage.Storage.Events.GetGSync:InvokeServer()",
    "",
  ];

  if (lootTypes.length) {
    lines.push("## Loot Types Found In Dump", "");
    for (const t of lootTypes) lines.push(`- ${t}`);
    lines.push("");
  }

  if (tools.length) {
    lines.push("## Weapons / Tools", "");
    for (const t of tools.slice(0, 80)) lines.push(`- ${t}`);
    if (tools.length > 80) lines.push(`- ... and ${tools.length - 80} more`);
    lines.push("");
  }

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
  const tools = extractToolNames(text);
  const lootTypes = extractLootTypes(text);
  const decals = extractDecalIds(text);
  const images = extractImageLabelIds(text);
  const textures = extractTextureIds(text);
  const toolTextures = extractToolTextureIds(text);

  const decalManifest = {};
  for (const [id, name] of decals) decalManifest[id] = { name, type: "decal" };
  for (const [id, name] of images) {
    if (!decalManifest[id]) decalManifest[id] = { name, type: "image" };
  }
  for (const [id, name] of textures) {
    if (!decalManifest[id]) decalManifest[id] = { name, type: "texture" };
  }
  for (const [id, info] of toolTextures) {
    if (!decalManifest[id]) decalManifest[id] = { name: info.name, type: info.type };
  }

  // Fallback: use first 300 unique asset IDs if no decals parsed
  if (Object.keys(decalManifest).length === 0) {
    for (const id of assetIds.slice(0, 300)) {
      decalManifest[id] = { name: `asset_${id}`, type: "asset" };
    }
  }

  const placeId = "16530963934";
  const manifest = {
    placeId,
    extractedAt: new Date().toISOString(),
    sourceFile: path.basename(input),
    sourceSizeBytes: stat.size,
    counts: {
      assetIds: assetIds.length,
      tools: tools.length,
      lootTypes: lootTypes.length,
      decals: Object.keys(decalManifest).length,
    },
    assetIds,
    tools,
    lootTypes,
    decals: decalManifest,
  };

  ensureDir(OUT_DIR);
  ensureDir(REF_DIR);

  const gameRef = buildGameReference({ placeId, tools, lootTypes });

  fs.writeFileSync(path.join(OUT_DIR, "GAME_REFERENCE.txt"), gameRef);
  fs.writeFileSync(path.join(REF_DIR, "GAME_REFERENCE.txt"), gameRef);
  fs.writeFileSync(path.join(OUT_DIR, "manifest.json"), JSON.stringify(manifest, null, 2));
  fs.writeFileSync(path.join(OUT_DIR, "asset_ids.txt"), assetIds.join("\n"));
  fs.writeFileSync(path.join(OUT_DIR, "tools.txt"), tools.join("\n"));

  console.log(`Extracted ${assetIds.length} asset IDs`);
  console.log(`Extracted ${tools.length} tools`);
  console.log(`Extracted ${lootTypes.length} loot types`);
  console.log(`Extracted ${Object.keys(decalManifest).length} decal/image/texture entries`);
  console.log("Wrote dump/GAME_REFERENCE.txt, dump/manifest.json");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
