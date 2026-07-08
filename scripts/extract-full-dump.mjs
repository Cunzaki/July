#!/usr/bin/env node
/**
 * Full RBXLX extraction: scripts, instance catalog, remotes, tools, assets.
 *
 * Usage: node scripts/extract-full-dump.mjs [path-to.rbxlx]
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parseRbxlx, walkTree, collectByClass, SCRIPT_CLASSES } from "./rbxlx-parser.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const DEFAULT_DUMP = path.join(
  process.env.LOCALAPPDATA || "",
  "Volt",
  "workspace",
  "place 16530963934 Game(2).rbxlx"
);

const IMPORTANT_CLASSES = new Set([
  "RemoteEvent",
  "RemoteFunction",
  "BindableEvent",
  "BindableFunction",
  "UnreliableRemoteEvent",
  "Tool",
  "StringValue",
  "BoolValue",
  "NumberValue",
  "ObjectValue",
  "Configuration",
  "Decal",
  "ImageLabel",
  "Sound",
]);

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJson(file, data) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function writeText(file, text) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, text);
}

function scriptExtension(className) {
  if (className === "LocalScript") return ".client.lua";
  if (className === "Script") return ".server.lua";
  return ".lua";
}

function scriptHeader(node) {
  return [
    `-- Class: ${node.className}`,
    `-- Path: ${node.path}`,
    `-- Referent: ${node.referent}`,
    `-- Extracted from Havoc place dump`,
    "",
  ].join("\n");
}

function extractRequires(source) {
  const out = new Set();
  const re = /require\s*\(([^)]+)\)/g;
  let m;
  while ((m = re.exec(source || "")) !== null) out.add(m[1].trim());
  return [...out];
}

function extractAssetIds(text) {
  const ids = new Set();
  const re = /rbxassetid:\/\/(\d+)/g;
  let m;
  while ((m = re.exec(text)) !== null) ids.add(m[1]);
  return [...ids].sort((a, b) => Number(a) - Number(b));
}

function buildReadme(stats) {
  return `# Havoc — Full Game Dump

Place ID: **${stats.placeId}**  
Extracted: **${stats.extractedAt}**  
Source: \`${stats.sourceFile}\` (${stats.sourceSizeMb} MB)

## Contents

| Folder | Description |
|--------|-------------|
| \`scripts/\` | All ${stats.scripts.total} Lua sources (${stats.scripts.modules} modules, ${stats.scripts.local} local, ${stats.scripts.server} server) |
| \`catalog/\` | Machine-readable indexes (instances, scripts, remotes, requires) |
| \`instances/\` | Curated instance dumps by important class |
| \`game-data/\` | Flat text lists (tools, loot, traps, remotes, gun keys) |
| \`assets/\` | Asset ID lists and decal/image manifest |

## Quick stats

- Total instances: **${stats.instances.total.toLocaleString()}**
- ModuleScripts: **${stats.scripts.modules}**
- LocalScripts: **${stats.scripts.local}**
- Scripts: **${stats.scripts.server}**
- RemoteEvents: **${stats.remotes.events}**
- RemoteFunctions: **${stats.remotes.functions}**
- Tools: **${stats.tools}**
- Unique asset IDs: **${stats.assetIds}**

## Script layout

\`\`\`
scripts/
  ModuleScript/ReplicatedStorage/Storage/Modules/...
  LocalScript/StarterPlayer/StarterPlayerScripts/...
  Script/ServerScriptService/...
\`\`\`

## Key game paths

- Drops / player items: \`Workspace/Buildings/Objects\`
- Loot containers: \`Workspace/Buildings/Loots/...\`
- Gun client: \`ReplicatedStorage/Storage/Modules/Frameworks/Guns/Client\`
- Network module: \`ReplicatedStorage/Storage/Modules/Network\`
- NPC folder name: \`ReplicatedStorage/Storage/Events/GetGSync\` RemoteFunction

See \`GAME_REFERENCE.txt\` for combat, loot patterns, and cheat dev notes.
`;
}

export function extractFullDump(text, sourceFile, outDir, meta = {}) {
  console.log("Parsing instance tree...");
  const t0 = Date.now();
  const tree = parseRbxlx(text);
  console.log(`  Parsed in ${((Date.now() - t0) / 1000).toFixed(1)}s`);

  const dirs = {
    root: outDir,
    scripts: path.join(outDir, "scripts"),
    catalog: path.join(outDir, "catalog"),
    instances: path.join(outDir, "instances"),
    gameData: path.join(outDir, "game-data"),
    assets: path.join(outDir, "assets"),
  };

  for (const d of Object.values(dirs)) ensureDir(d);

  const classCounts = {};
  const scriptsIndex = [];
  const remotes = { events: [], functions: [], bindables: [] };
  const tools = [];
  const lootTypes = new Set();
  const importantByClass = {};
  let instanceCount = 0;
  let scriptsWritten = 0;
  let scriptBytes = 0;
  const requireGraph = {};

  const instStream = fs.createWriteStream(path.join(dirs.catalog, "instances.jsonl"), "utf8");

  walkTree(tree, (node) => {
    if (node.className === "Game") return;

    instanceCount++;
    classCounts[node.className] = (classCounts[node.className] || 0) + 1;

    const row = {
      class: node.className,
      name: node.name,
      path: node.path,
      referent: node.referent,
    };
    if (node.value != null) row.value = node.value;
    if (node.numberValue != null) row.number = node.numberValue;
    if (node.boolValue != null) row.bool = node.boolValue;
    if (node.assetRef) row.asset = node.assetRef;
    instStream.write(`${JSON.stringify(row)}\n`);

    if (SCRIPT_CLASSES.has(node.className)) {
      const rel = `${node.path}${scriptExtension(node.className)}`;
      const outFile = path.join(dirs.scripts, node.className, rel);
      ensureDir(path.dirname(outFile));
      const body = node.source ?? "";
      const content = scriptHeader(node) + body + (body.endsWith("\n") ? "" : "\n");
      fs.writeFileSync(outFile, content, "utf8");
      scriptsWritten++;
      scriptBytes += content.length;

      const requires = extractRequires(body);
      if (requires.length) requireGraph[node.path] = requires;

      scriptsIndex.push({
        class: node.className,
        name: node.name,
        path: node.path,
        referent: node.referent,
        file: path.relative(outDir, outFile).replace(/\\/g, "/"),
        lines: content.split("\n").length,
        bytes: content.length,
        requires,
      });
    }

    if (node.className === "RemoteEvent" || node.className === "UnreliableRemoteEvent") {
      remotes.events.push({ name: node.name, path: node.path, referent: node.referent });
    } else if (node.className === "RemoteFunction") {
      remotes.functions.push({ name: node.name, path: node.path, referent: node.referent });
    } else if (node.className === "BindableEvent" || node.className === "BindableFunction") {
      remotes.bindables.push({ class: node.className, name: node.name, path: node.path });
    } else if (node.className === "Tool") {
      tools.push({
        name: node.name,
        path: node.path,
        textureId: node.textureId || null,
      });
    } else if (node.className === "StringValue" && node.name === "lootType" && node.value) {
      lootTypes.add(node.value);
    }

    if (IMPORTANT_CLASSES.has(node.className)) {
      if (!importantByClass[node.className]) importantByClass[node.className] = [];
      importantByClass[node.className].push({
        name: node.name,
        path: node.path,
        referent: node.referent,
        ...(node.value != null ? { value: node.value } : {}),
        ...(node.numberValue != null ? { number: node.numberValue } : {}),
        ...(node.boolValue != null ? { bool: node.boolValue } : {}),
        ...(node.assetRef ? { asset: node.assetRef } : {}),
        ...(node.textureId ? { textureId: node.textureId } : {}),
      });
    }
  });

  instStream.end();

  remotes.events.sort((a, b) => a.path.localeCompare(b.path));
  remotes.functions.sort((a, b) => a.path.localeCompare(b.path));
  remotes.bindables.sort((a, b) => a.path.localeCompare(b.path));
  tools.sort((a, b) => a.name.localeCompare(b.name));
  scriptsIndex.sort((a, b) => a.path.localeCompare(b.path));

  writeJson(path.join(dirs.catalog, "class_counts.json"), classCounts);
  writeJson(path.join(dirs.catalog, "scripts-index.json"), scriptsIndex);
  writeJson(path.join(dirs.catalog, "remotes.json"), remotes);
  writeJson(path.join(dirs.catalog, "tools.json"), tools);
  writeJson(path.join(dirs.catalog, "require-graph.json"), requireGraph);
  writeJson(path.join(dirs.catalog, "loot-types.json"), [...lootTypes].sort());

  for (const [cls, rows] of Object.entries(importantByClass)) {
    const clsDir = path.join(dirs.instances, cls);
    ensureDir(clsDir);
    writeJson(path.join(clsDir, "all.json"), rows);
    writeText(
      path.join(clsDir, "paths.txt"),
      rows.map((r) => `${r.path}${r.value != null ? `\t${r.value}` : ""}`).join("\n") + "\n"
    );
  }

  const assetIds = extractAssetIds(text);
  writeText(path.join(dirs.assets, "asset_ids.txt"), assetIds.join("\n") + "\n");

  const moduleScripts = collectByClass(tree, "ModuleScript");
  writeText(
    path.join(dirs.gameData, "module_scripts.txt"),
    moduleScripts.map((n) => n.path).join("\n") + "\n"
  );
  writeText(
    path.join(dirs.gameData, "remote_events.txt"),
    remotes.events.map((r) => `${r.path}\t(${r.name})`).join("\n") + "\n"
  );
  writeText(
    path.join(dirs.gameData, "remote_functions.txt"),
    remotes.functions.map((r) => `${r.path}\t(${r.name})`).join("\n") + "\n"
  );
  writeText(
    path.join(dirs.gameData, "tools.txt"),
    tools.map((t) => t.name).join("\n") + "\n"
  );
  writeText(
    path.join(dirs.gameData, "loot_types.txt"),
    [...lootTypes].sort().join("\n") + "\n"
  );

  const stat = fs.statSync(sourceFile);
  const placeId = meta.placeId || "16530963934";
  const extractedAt = meta.extractedAt || new Date().toISOString();

  const stats = {
    placeId,
    extractedAt,
    sourceFile: path.basename(sourceFile),
    sourceSizeMb: (stat.size / 1024 / 1024).toFixed(1),
    instances: { total: instanceCount, byClass: classCounts },
    scripts: {
      total: scriptsWritten,
      modules: classCounts.ModuleScript || 0,
      local: classCounts.LocalScript || 0,
      server: classCounts.Script || 0,
      bytes: scriptBytes,
    },
    remotes: {
      events: remotes.events.length,
      functions: remotes.functions.length,
      bindables: remotes.bindables.length,
    },
    tools: tools.length,
    lootTypes: lootTypes.size,
    assetIds: assetIds.length,
  };

  writeJson(path.join(dirs.root, "manifest.json"), {
    ...meta,
    ...stats,
    scriptIndexFile: "catalog/scripts-index.json",
    instanceCatalog: "catalog/instances.jsonl",
  });

  writeText(path.join(dirs.root, "README.md"), buildReadme(stats));

  console.log(`  Instances: ${instanceCount.toLocaleString()}`);
  console.log(`  Scripts written: ${scriptsWritten} (${(scriptBytes / 1024 / 1024).toFixed(1)} MB)`);
  console.log(`  Remotes: ${remotes.events.length} events, ${remotes.functions.length} functions`);
  console.log(`  Tools: ${tools.length}, loot types: ${lootTypes.size}`);

  return stats;
}

async function main() {
  const input = process.argv[2] || DEFAULT_DUMP;
  const outDir = path.join(ROOT, "dump");

  if (!fs.existsSync(input)) {
    console.error("Dump not found:", input);
    process.exit(1);
  }

  console.log("Reading:", input);
  const text = fs.readFileSync(input, "utf8");
  extractFullDump(text, input, outDir);
  console.log("Wrote full dump to dump/");
}

if (import.meta.url === `file://${process.argv[1].replace(/\\/g, "/")}` ||
    process.argv[1]?.endsWith("extract-full-dump.mjs")) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
