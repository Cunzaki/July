/**
 * July / Havoc rbxlx dumper — hierarchy-first place dump.
 *
 * Layout highlights:
 *   scripts/hierarchy/...   mirrors DataModel folders (Rojo-style init.lua)
 *   scripts/flat/...        dotted path filenames for quick search
 *   tree/*.txt              ASCII service trees (├── / └──)
 *   catalog/                TSVs for remotes, modules, assets, …
 *   game-data/              Havoc loot / tools / traps cheat lists
 *
 * Usage:
 *   node scripts/dump-rbxlx.mjs [path/to/place.rbxlx] [outDir]
 *   npm run dump
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const DEFAULT_RBXLX = path.join(
  process.env.LOCALAPPDATA || "",
  "Volt",
  "workspace",
  "place 16530963934 Game(1).rbxlx"
);

const rbxlxPath = path.resolve(process.argv[2] || DEFAULT_RBXLX);
const outDir = path.resolve(process.argv[3] || path.join(ROOT, "dump"));

const SCRIPT_CLASSES = new Set(["Script", "LocalScript", "ModuleScript"]);
const REMOTE_CLASSES = new Set([
  "RemoteEvent",
  "RemoteFunction",
  "UnreliableRemoteEvent",
]);
const BINDABLE_CLASSES = new Set(["BindableEvent", "BindableFunction"]);
const VALUE_CLASSES = new Set([
  "BoolValue",
  "NumberValue",
  "IntValue",
  "StringValue",
  "ObjectValue",
  "Vector3Value",
  "CFrameValue",
  "Color3Value",
  "BrickColorValue",
  "RayValue",
]);
const GUI_CLASSES = new Set([
  "ScreenGui",
  "BillboardGui",
  "SurfaceGui",
  "Frame",
  "ScrollingFrame",
  "TextLabel",
  "TextButton",
  "TextBox",
  "ImageLabel",
  "ImageButton",
  "ViewportFrame",
]);
const SERVICE_ORDER = [
  "Workspace",
  "Players",
  "Lighting",
  "MaterialService",
  "ReplicatedFirst",
  "ReplicatedStorage",
  "ServerScriptService",
  "ServerStorage",
  "StarterGui",
  "StarterPack",
  "StarterPlayer",
  "Teams",
  "SoundService",
  "Chat",
  "TextChatService",
  "LocalizationService",
];

function die(msg) {
  console.error(msg);
  process.exit(1);
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function wipeDir(p) {
  fs.rmSync(p, { recursive: true, force: true });
  ensureDir(p);
}

function textContent(raw) {
  if (raw == null) return "";
  const m = String(raw).match(/<!\[CDATA\[([\s\S]*?)\]\]>/);
  if (m) return m[1];
  return String(raw)
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

function safeSeg(name) {
  return String(name || "unnamed")
    .replace(/[<>:"/\\|?*\x00-\x1f]/g, "_")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 120) || "unnamed";
}

function writeLines(file, lines) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, lines.join("\n") + (lines.length ? "\n" : ""), "utf8");
}

function tsvEscape(s) {
  return String(s ?? "").replace(/\t/g, " ").replace(/\r?\n/g, " ");
}

/* ---------------- Attributes / Tags ---------------- */

function decodeAttributes(b64) {
  if (!b64 || !b64.trim()) return null;
  let buf;
  try {
    buf = Buffer.from(b64.trim(), "base64");
  } catch {
    return { _error: "bad_base64" };
  }
  if (buf.length < 4) return null;
  let o = 0;
  const count = buf.readUInt32LE(o);
  o += 4;
  if (count > 10_000) return { _error: "count_too_large", count };
  const out = {};
  try {
    for (let i = 0; i < count; i++) {
      if (o + 4 > buf.length) break;
      const nlen = buf.readUInt32LE(o);
      o += 4;
      if (nlen > 4096 || o + nlen > buf.length) break;
      const name = buf.slice(o, o + nlen).toString("utf8");
      o += nlen;
      if (o >= buf.length) break;
      const t = buf[o++];
      let value;
      switch (t) {
        case 2: {
          const sl = buf.readUInt32LE(o);
          o += 4;
          value = buf.slice(o, o + sl).toString("utf8");
          o += sl;
          break;
        }
        case 3:
          value = buf[o++] !== 0;
          break;
        case 4:
          value = buf.readInt32LE(o);
          o += 4;
          break;
        case 5:
          value = buf.readFloatLE(o);
          o += 4;
          break;
        case 6:
          value = buf.readDoubleLE(o);
          o += 8;
          break;
        case 7:
          value = { scale: buf.readFloatLE(o), offset: buf.readInt32LE(o + 4) };
          o += 8;
          break;
        case 8:
          value = {
            x: { scale: buf.readFloatLE(o), offset: buf.readInt32LE(o + 4) },
            y: { scale: buf.readFloatLE(o + 8), offset: buf.readInt32LE(o + 12) },
          };
          o += 16;
          break;
        case 9:
          value = buf.readUInt32LE(o);
          o += 4;
          break;
        case 10:
          value = {
            r: buf.readFloatLE(o),
            g: buf.readFloatLE(o + 4),
            b: buf.readFloatLE(o + 8),
          };
          o += 12;
          break;
        case 11:
          value = { x: buf.readFloatLE(o), y: buf.readFloatLE(o + 4) };
          o += 8;
          break;
        case 12:
          value = {
            x: buf.readFloatLE(o),
            y: buf.readFloatLE(o + 4),
            z: buf.readFloatLE(o + 8),
          };
          o += 12;
          break;
        case 14: {
          const keypoints = buf.readUInt32LE(o);
          o += 4;
          const pts = [];
          for (let k = 0; k < keypoints && o + 12 <= buf.length; k++) {
            pts.push({
              time: buf.readFloatLE(o),
              value: buf.readFloatLE(o + 4),
              envelope: buf.readFloatLE(o + 8),
            });
            o += 12;
          }
          value = pts;
          break;
        }
        case 15: {
          const keypoints = buf.readUInt32LE(o);
          o += 4;
          const pts = [];
          for (let k = 0; k < keypoints && o + 20 <= buf.length; k++) {
            pts.push({
              time: buf.readFloatLE(o),
              r: buf.readFloatLE(o + 4),
              g: buf.readFloatLE(o + 8),
              b: buf.readFloatLE(o + 12),
              envelope: buf.readFloatLE(o + 16),
            });
            o += 20;
          }
          value = pts;
          break;
        }
        case 16:
          value = { min: buf.readFloatLE(o), max: buf.readFloatLE(o + 4) };
          o += 8;
          break;
        case 17:
          value = {
            min: { x: buf.readFloatLE(o), y: buf.readFloatLE(o + 4) },
            max: { x: buf.readFloatLE(o + 8), y: buf.readFloatLE(o + 12) },
          };
          o += 16;
          break;
        case 19: {
          const sl = buf.readUInt32LE(o);
          o += 4;
          value = buf.slice(o, o + sl).toString("utf8");
          o += sl;
          break;
        }
        default:
          out[name] = { _unknownType: t };
          return out;
      }
      out[name] = value;
    }
  } catch (e) {
    out._decodeError = String(e.message || e);
  }
  return Object.keys(out).length ? out : null;
}

function decodeTags(b64) {
  if (!b64 || !b64.trim()) return [];
  let buf;
  try {
    buf = Buffer.from(b64.trim(), "base64");
  } catch {
    return [];
  }
  const tags = [];
  let o = 0;
  while (o + 4 <= buf.length) {
    const len = buf.readUInt32LE(o);
    o += 4;
    if (len === 0 || len > 512 || o + len > buf.length) break;
    tags.push(buf.slice(o, o + len).toString("utf8"));
    o += len;
  }
  return tags;
}

/* ---------------- Property parse ---------------- */

function parseVector3(inner) {
  const x = +(inner.match(/<X>([^<]*)<\/X>/)?.[1] ?? NaN);
  const y = +(inner.match(/<Y>([^<]*)<\/Y>/)?.[1] ?? NaN);
  const z = +(inner.match(/<Z>([^<]*)<\/Z>/)?.[1] ?? NaN);
  if ([x, y, z].some(Number.isNaN)) return textContent(inner);
  return { x, y, z };
}

function parseCFrame(inner) {
  const nums = {};
  for (const k of ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"]) {
    const m = inner.match(new RegExp(`<${k}>([^<]*)</${k}>`));
    if (m) nums[k] = +m[1];
  }
  return Object.keys(nums).length ? nums : textContent(inner);
}

function parseContent(inner) {
  const url = inner.match(/<url>([\s\S]*?)<\/url>/);
  if (url) return textContent(url[1]);
  if (/<null\s*\/>/.test(inner)) return null;
  return textContent(inner);
}

function parsePropValue(tag, inner) {
  switch (tag) {
    case "bool":
      return inner.trim() === "true";
    case "int":
    case "int64":
    case "token":
      return Number.parseInt(inner, 10);
    case "float":
    case "double":
      return Number.parseFloat(inner);
    case "string":
    case "ProtectedString":
      return textContent(inner);
    case "Ref":
      return inner.trim();
    case "BinaryString":
      return inner.trim();
    case "Vector3":
      return parseVector3(inner);
    case "CoordinateFrame":
    case "OptionalCoordinateFrame":
      return parseCFrame(inner);
    case "Content":
    case "UniqueId":
    case "SecurityCapabilities":
      return parseContent(inner);
    default:
      if (inner.includes("<X>") && inner.includes("<Y>")) return parseVector3(inner);
      return textContent(inner);
  }
}

function parseProperties(block) {
  const props = {};
  const re =
    /<(bool|int|int64|float|double|token|string|ProtectedString|Ref|BinaryString|Color3|Color3uint8|Vector3|CoordinateFrame|OptionalCoordinateFrame|Content|UniqueId|SecurityCapabilities|NumberRange|UDim|UDim2|Rect2D|Font|SharedString|url) name="([^"]+)"[^>]*>([\s\S]*?)<\/\1>/g;
  let m;
  while ((m = re.exec(block))) {
    props[m[2]] = parsePropValue(m[1], m[3]);
  }
  const emptyRe = /<(bool|int|float|string|BinaryString|Content) name="([^"]+)"\s*\/>/g;
  while ((m = emptyRe.exec(block))) {
    if (!(m[2] in props)) props[m[2]] = null;
  }
  return props;
}

function parseItems(xml) {
  const instances = [];
  const opens = [];
  const re = /<Item class="([^"]+)" referent="([^"]+)">|<\/Item>/g;
  let m;
  while ((m = re.exec(xml))) {
    if (m[0].startsWith("</")) {
      if (!opens.length) continue;
      const open = opens.pop();
      const inner = xml.slice(open.endTag, m.index);
      const propsMatch = inner.match(/^[\s\S]*?<Properties>([\s\S]*?)<\/Properties>/);
      const props = propsMatch ? parseProperties(propsMatch[1]) : {};
      const nameRaw = props.Name != null ? String(props.Name) : open.className;
      const name = nameRaw.trim();
      if (props.Name != null) props.Name = name;
      const parent = opens.length ? opens[opens.length - 1] : null;
      const inst = {
        referent: open.referent,
        class: open.className,
        name,
        parent_referent: parent ? parent.referent : null,
        properties: props,
        _childRefs: open.childRefs || [],
      };
      instances.push(inst);
      if (parent) {
        parent.childRefs = parent.childRefs || [];
        parent.childRefs.push(open.referent);
      }
    } else {
      opens.push({
        className: m[1],
        referent: m[2],
        endTag: m.index + m[0].length,
        childRefs: [],
      });
    }
  }
  return instances;
}

function buildPaths(instances) {
  const byRef = new Map(instances.map((i) => [i.referent, i]));
  for (const inst of instances) {
    const parts = [];
    let cur = inst;
    const guard = new Set();
    while (cur && !guard.has(cur.referent)) {
      guard.add(cur.referent);
      parts.push(String(cur.name || cur.class));
      cur = cur.parent_referent != null ? byRef.get(cur.parent_referent) : null;
    }
    parts.reverse();
    inst.pathParts = parts;
    inst.path = parts.join(".");
    inst.fsParts = parts.map(safeSeg);
  }
  return byRef;
}

function extractAssetIds(value, into) {
  if (value == null) return;
  if (typeof value === "string") {
    for (const m of value.matchAll(/rbxassetid:\/\/(\d+)/g)) into.add(m[1]);
    for (const m of value.matchAll(/id=(\d{5,})/g)) into.add(m[1]);
  } else if (typeof value === "object") {
    for (const v of Object.values(value)) extractAssetIds(v, into);
  }
}

/* ---------------- Script formatting / paths ---------------- */

function formatLuaSource(source) {
  let s = String(source ?? "");
  // strip NULs / weird control chars except tab/newline
  s = s.replace(/\0/g, "").replace(/[\x01-\x08\x0b\x0c\x0e-\x1f]/g, "");
  s = s.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
  // trim trailing spaces per line, keep indentation
  s = s
    .split("\n")
    .map((line) => line.replace(/[ \t]+$/g, ""))
    .join("\n");
  // collapse 3+ blank lines → 2
  s = s.replace(/\n{3,}/g, "\n\n");
  if (s.length && !s.endsWith("\n")) s += "\n";
  return s;
}

function scriptHeader(inst) {
  const lines = [
    "--[[",
    `  Class    : ${inst.class}`,
    `  Name     : ${inst.name}`,
    `  Path     : ${inst.path}`,
    `  Referent : ${inst.referent}`,
  ];
  if (inst.tags?.length) lines.push(`  Tags     : ${inst.tags.join(", ")}`);
  if (inst.attributes && Object.keys(inst.attributes).length) {
    lines.push(`  Attrs    : ${Object.keys(inst.attributes).join(", ")}`);
  }
  lines.push(`  Dumped   : ${new Date().toISOString()}`);
  lines.push("]]");
  lines.push("");
  return lines.join("\n");
}

function classSuffix(className) {
  if (className === "LocalScript") return ".client.lua";
  if (className === "Script") return ".server.lua";
  return ".lua";
}

/**
 * Hierarchy path for a script.
 * ModuleScripts that contain other scripts → Name/init.lua (Rojo-style).
 * Sibling name collisions → Name.Class.lua
 */
function hierarchyScriptRel(inst, childrenMap, siblingNameCounts) {
  const parentParts = inst.fsParts.slice(0, -1);
  const leaf = safeSeg(inst.name);
  const kids = childrenMap.get(inst.referent) || [];
  const hasScriptKids = kids.some((k) => SCRIPT_CLASSES.has(k.class));

  const parentKey = inst.parent_referent ?? "__root__";
  const key = `${parentKey}\0${leaf.toLowerCase()}`;
  const needsClass = (siblingNameCounts.get(key) || 0) > 1;

  const ext =
    inst.class === "LocalScript"
      ? ".client.lua"
      : inst.class === "Script"
        ? ".server.lua"
        : ".lua";

  if (hasScriptKids && inst.class === "ModuleScript") {
    const file = needsClass ? `init.${inst.class}.lua` : "init.lua";
    return [...parentParts, leaf, file].join("/");
  }

  const file = needsClass ? `${leaf}.${inst.class}${ext}` : `${leaf}${ext}`;
  return [...parentParts, file].join("/");
}

function flatScriptName(inst) {
  return `${inst.fsParts.join(".")}.${inst.class}.lua`;
}

function extractRequires(source) {
  const out = new Set();
  const re = /require\s*\(([^)]+)\)/g;
  let m;
  while ((m = re.exec(source || "")) !== null) out.add(m[1].trim());
  return [...out];
}

/* ---------------- ASCII tree ---------------- */

function buildAsciiTree(rootRef, childrenMap, { maxDepth = 8, maxChildren = 200, filter = null } = {}) {
  const lines = [];
  function walk(ref, prefix, depth, isLast) {
    if (depth > maxDepth) return;
    const kids = (childrenMap.get(ref) || []).filter((k) => (filter ? filter(k) : true));
    const shown = kids.slice(0, maxChildren);
    shown.forEach((k, i) => {
      const last = i === shown.length - 1 && kids.length <= maxChildren;
      const branch = last ? "└── " : "├── ";
      const extra =
        SCRIPT_CLASSES.has(k.class)
          ? ""
          : (childrenMap.get(k.referent) || []).length
            ? ` (${(childrenMap.get(k.referent) || []).length})`
            : "";
      lines.push(`${prefix}${branch}${k.class}  ${k.name}${extra}`);
      const nextPrefix = prefix + (last ? "    " : "│   ");
      walk(k.referent, nextPrefix, depth + 1, last);
    });
    if (kids.length > maxChildren) {
      lines.push(`${prefix}└── … +${kids.length - maxChildren} more`);
    }
  }
  walk(rootRef, "", 0, true);
  return lines;
}

/* ---------------- Havoc game-data ---------------- */

function collectHavocGameData(instances, childrenMap) {
  const lootTypes = new Set();
  const lootModels = new Set();
  const tools = [];
  const traps = new Set();
  const trapKw = ["tripmine", "mine", "alarm", "airstrike", "sentry", "toxic", "gas", "claymore", "grenade", "trap"];

  for (const inst of instances) {
    if (inst.class === "Tool") tools.push(inst.path);
    if (inst.class === "StringValue" && inst.name === "lootType" && inst.properties.Value != null) {
      lootTypes.add(String(inst.properties.Value));
      // parent model name
      // climb to Model
      let cur = inst;
      // use pathParts
      if (inst.pathParts.length >= 2) {
        lootModels.add(inst.pathParts[inst.pathParts.length - 3] || inst.pathParts[inst.pathParts.length - 2]);
      }
    }
    const lower = inst.name.toLowerCase();
    if (trapKw.some((k) => lower.includes(k))) traps.add(inst.name);
  }

  return {
    lootTypes: [...lootTypes].sort(),
    lootModels: [...lootModels].sort(),
    tools: [...new Set(tools)].sort(),
    traps: [...traps].sort(),
  };
}

/* ---------------- Main ---------------- */

function main() {
  if (!fs.existsSync(rbxlxPath)) die(`Missing rbxlx: ${rbxlxPath}`);

  console.log(`Reading ${rbxlxPath}`);
  console.log(`  size ${(fs.statSync(rbxlxPath).size / 1e6).toFixed(1)} MB`);
  const t0 = Date.now();
  const xml = fs.readFileSync(rbxlxPath, "utf8");
  const sourceStat = fs.statSync(rbxlxPath);

  const meta = {
    placeId: +(xml.match(/PlaceId:\s*(\d+)/)?.[1] || 16530963934),
    placeVersion: +(xml.match(/PlaceVersion:\s*(\d+)/)?.[1] || 0),
    clientVersion: xml.match(/Client Version:\s*([^\s]+)/)?.[1] || null,
    executor: xml.match(/Executor:\s*([^\n\]]+)/)?.[1]?.trim() || null,
    dumpedAtUtc: xml.match(/Date \(UTC\):\s*([^\n]+)/)?.[1]?.trim() || null,
  };

  console.log("Parsing Item tree…");
  const instances = parseItems(xml);
  console.log(`  ${instances.length.toLocaleString()} instances`);
  buildPaths(instances);

  const childrenMap = new Map();
  for (const inst of instances) {
    const p = inst.parent_referent ?? "__root__";
    if (!childrenMap.has(p)) childrenMap.set(p, []);
    childrenMap.get(p).push(inst);
  }

  // sibling name counts (for collision disambiguation)
  const siblingNameCounts = new Map();
  for (const inst of instances) {
    if (!SCRIPT_CLASSES.has(inst.class)) continue;
    const parentKey = inst.parent_referent ?? "__root__";
    const key = `${parentKey}\0${safeSeg(inst.name).toLowerCase()}`;
    siblingNameCounts.set(key, (siblingNameCounts.get(key) || 0) + 1);
  }

  const allAssets = new Set();
  const classStats = {};
  const scripts = [];
  const remotes = [];
  const bindables = [];
  const values = [];
  const tools = [];
  const sounds = [];
  const prompts = [];
  const animations = [];
  const imageAssets = [];
  const meshAssets = [];
  const attrRows = [];
  const requireGraph = {};

  for (const inst of instances) {
    classStats[inst.class] = (classStats[inst.class] || 0) + 1;
    const props = inst.properties;

    if (props.AttributesSerialize) {
      inst.attributes = decodeAttributes(props.AttributesSerialize);
      delete props.AttributesSerialize;
      if (inst.attributes) {
        attrRows.push({
          referent: inst.referent,
          path: inst.path,
          class: inst.class,
          attributes: inst.attributes,
        });
      }
    } else {
      inst.attributes = null;
    }

    if (props.Tags) {
      inst.tags = decodeTags(props.Tags);
      delete props.Tags;
    } else {
      inst.tags = [];
    }

    for (const v of Object.values(props)) extractAssetIds(v, allAssets);

    if (SCRIPT_CLASSES.has(inst.class)) {
      const source = props.Source != null ? String(props.Source) : "";
      const { Source, ...rest } = props;
      inst.properties = rest;
      inst._source = source;
      scripts.push(inst);
    }

    if (REMOTE_CLASSES.has(inst.class)) remotes.push(inst);
    if (BINDABLE_CLASSES.has(inst.class)) bindables.push(inst);
    if (VALUE_CLASSES.has(inst.class)) values.push(inst);
    if (inst.class === "Tool") tools.push(inst);
    if (inst.class === "Sound") {
      sounds.push(inst);
      extractAssetIds(props.SoundId, allAssets);
    }
    if (inst.class === "ProximityPrompt") prompts.push(inst);
    if (inst.class === "Animation") {
      animations.push(inst);
      extractAssetIds(props.AnimationId, allAssets);
    }
    if (
      inst.class === "ImageLabel" ||
      inst.class === "ImageButton" ||
      inst.class === "Decal" ||
      inst.class === "Texture"
    ) {
      const img = props.Image || props.Texture || props.TextureID || null;
      if (img) imageAssets.push({ path: inst.path, class: inst.class, image: img });
      extractAssetIds(img, allAssets);
    }
    if (inst.class === "MeshPart" || inst.class === "SpecialMesh" || inst.class === "FileMesh") {
      const mesh = props.MeshId || null;
      const tex = props.TextureID || props.TextureId || null;
      meshAssets.push({ path: inst.path, class: inst.class, meshId: mesh, textureId: tex });
      extractAssetIds(mesh, allAssets);
      extractAssetIds(tex, allAssets);
    }
  }

  console.log("Writing dump…");
  wipeDir(outDir);

  const dirs = {
    catalog: path.join(outDir, "catalog"),
    tree: path.join(outDir, "tree"),
    index: path.join(outDir, "index"),
    instances: path.join(outDir, "instances"),
    byClass: path.join(outDir, "instances", "by_class"),
    scriptsHier: path.join(outDir, "scripts", "hierarchy"),
    scriptsFlat: path.join(outDir, "scripts", "flat"),
    attributes: path.join(outDir, "attributes"),
    gameData: path.join(outDir, "game-data"),
  };
  for (const d of Object.values(dirs)) ensureDir(d);

  // --- instances ---
  const byClassLines = new Map();
  const allLines = [];
  const indexLines = ["referent\tclass\tname\tpath\tparent_referent\ttags"];
  for (const inst of instances) {
    const row = {
      referent: inst.referent,
      class: inst.class,
      name: inst.name,
      path: inst.path,
      parent_referent: inst.parent_referent,
      properties: inst.properties,
      attributes: inst.attributes,
      tags: inst.tags,
    };
    const line = JSON.stringify(row);
    allLines.push(line);
    if (!byClassLines.has(inst.class)) byClassLines.set(inst.class, []);
    byClassLines.get(inst.class).push(line);
    indexLines.push(
      [
        inst.referent,
        inst.class,
        tsvEscape(inst.name),
        tsvEscape(inst.path),
        inst.parent_referent ?? "",
        (inst.tags || []).join(","),
      ].join("\t")
    );
  }
  writeLines(path.join(dirs.instances, "all.jsonl"), allLines);
  for (const [cls, lines] of byClassLines) {
    writeLines(path.join(dirs.byClass, `${safeSeg(cls)}.jsonl`), lines);
  }
  writeLines(path.join(dirs.index, "instances.tsv"), indexLines);

  // --- scripts (hierarchy + flat) ---
  console.log(`  writing ${scripts.length} scripts (hierarchy + flat)…`);
  const scriptIndex = [
    "referent\tclass\tpath\thierarchy_file\tflat_file\tbytes\trequires",
  ];
  let scriptBytes = 0;

  for (const inst of scripts) {
    const body = formatLuaSource(inst._source);
    const header = scriptHeader(inst);
    const content = header + body;
    scriptBytes += Buffer.byteLength(content);

    const hierRel = hierarchyScriptRel(inst, childrenMap, siblingNameCounts);
    const flatRel = flatScriptName(inst);
    const hierAbs = path.join(dirs.scriptsHier, hierRel);
    const flatAbs = path.join(dirs.scriptsFlat, flatRel);
    ensureDir(path.dirname(hierAbs));
    ensureDir(path.dirname(flatAbs));
    fs.writeFileSync(hierAbs, content, "utf8");
    fs.writeFileSync(flatAbs, content, "utf8");

    const requires = extractRequires(body);
    if (requires.length) requireGraph[inst.path] = requires;

    scriptIndex.push(
      [
        inst.referent,
        inst.class,
        tsvEscape(inst.path),
        tsvEscape(`scripts/hierarchy/${hierRel}`),
        tsvEscape(`scripts/flat/${flatRel}`),
        Buffer.byteLength(content),
        tsvEscape(requires.join("; ")),
      ].join("\t")
    );
  }
  writeLines(path.join(outDir, "scripts", "_index.tsv"), scriptIndex);
  writeLines(path.join(outDir, "scripts", "README.md"), [
    "# Scripts",
    "",
    "| Folder | Purpose |",
    "|--------|---------|",
    "| `hierarchy/` | Mirrors DataModel folders. ModuleScripts with script children use `Name/init.lua`. |",
    "| `flat/` | Single-folder dotted paths (`ReplicatedStorage.Storage.Modules.Network.ModuleScript.lua`) for ripgrep. |",
    "| `_index.tsv` | referent → both paths + require() strings |",
    "",
    "Every file starts with a `--[[ … ]]` header (class, path, referent, tags).",
    "Sources are normalized (LF, no trailing spaces, NUL stripped).",
  ]);
  fs.writeFileSync(
    path.join(dirs.catalog, "requires.json"),
    JSON.stringify(requireGraph, null, 2)
  );

  // --- attributes ---
  writeLines(
    path.join(dirs.attributes, "all.jsonl"),
    attrRows.map((r) => JSON.stringify(r))
  );

  // --- catalogs ---
  const sortedClasses = Object.entries(classStats).sort((a, b) => b[1] - a[1]);
  fs.writeFileSync(
    path.join(dirs.catalog, "class_stats.json"),
    JSON.stringify(Object.fromEntries(sortedClasses), null, 2)
  );
  writeLines(
    path.join(dirs.catalog, "class_stats.txt"),
    sortedClasses.map(([c, n]) => `${n}\t${c}`)
  );

  const catalogTsv = (file, rows, cols, mapFn) => {
    writeLines(path.join(dirs.catalog, file), [cols.join("\t"), ...rows.map(mapFn)]);
  };

  catalogTsv("remotes.tsv", remotes, ["class", "path", "referent"], (i) =>
    [i.class, tsvEscape(i.path), i.referent].join("\t")
  );
  catalogTsv("bindables.tsv", bindables, ["class", "path", "referent"], (i) =>
    [i.class, tsvEscape(i.path), i.referent].join("\t")
  );
  catalogTsv(
    "modules.tsv",
    scripts.filter((s) => s.class === "ModuleScript"),
    ["path", "referent", "hierarchy_file"],
    (i) =>
      [
        tsvEscape(i.path),
        i.referent,
        tsvEscape(`scripts/hierarchy/${hierarchyScriptRel(i, childrenMap, siblingNameCounts)}`),
      ].join("\t")
  );
  catalogTsv("values.tsv", values, ["class", "path", "value"], (i) =>
    [i.class, tsvEscape(i.path), tsvEscape(JSON.stringify(i.properties.Value))].join("\t")
  );
  catalogTsv("tools.tsv", tools, ["path", "referent"], (i) =>
    [tsvEscape(i.path), i.referent].join("\t")
  );
  catalogTsv("sounds.tsv", sounds, ["path", "soundId"], (i) =>
    [tsvEscape(i.path), tsvEscape(i.properties.SoundId)].join("\t")
  );
  catalogTsv("proximity_prompts.tsv", prompts, ["path", "action", "object"], (i) =>
    [
      tsvEscape(i.path),
      tsvEscape(i.properties.ActionText),
      tsvEscape(i.properties.ObjectText),
    ].join("\t")
  );
  catalogTsv("animations.tsv", animations, ["path", "animationId"], (i) =>
    [tsvEscape(i.path), tsvEscape(i.properties.AnimationId)].join("\t")
  );
  catalogTsv("image_assets.tsv", imageAssets, ["class", "path", "image"], (i) =>
    [i.class, tsvEscape(i.path), tsvEscape(i.image)].join("\t")
  );
  catalogTsv("mesh_assets.tsv", meshAssets, ["class", "path", "meshId", "textureId"], (i) =>
    [i.class, tsvEscape(i.path), tsvEscape(i.meshId), tsvEscape(i.textureId)].join("\t")
  );
  writeLines(path.join(dirs.catalog, "assets.tsv"), [
    "assetId",
    ...[...allAssets].sort((a, b) => Number(a) - Number(b)),
  ]);

  // --- ASCII trees ---
  console.log("  building ASCII trees…");
  const roots = instances.filter((i) => i.parent_referent == null);
  const serviceLines = ["class\tname\tpath\tchild_count\treferent"];
  for (const r of roots) {
    serviceLines.push(
      [r.class, tsvEscape(r.name), tsvEscape(r.path), (childrenMap.get(r.referent) || []).length, r.referent].join(
        "\t"
      )
    );
  }
  writeLines(path.join(dirs.tree, "services.tsv"), serviceLines);

  const findService = (nameOrClass) =>
    roots.find((r) => r.name === nameOrClass || r.class === nameOrClass);

  const treeTargets = [
    ["workspace", "Workspace", 6, 120],
    ["replicated_storage", "ReplicatedStorage", 7, 150],
    ["server_script_service", "ServerScriptService", 8, 200],
    ["starter_player", "StarterPlayer", 8, 200],
    ["starter_gui", "StarterGui", 6, 100],
  ];

  for (const [file, svc, depth, maxKids] of treeTargets) {
    const node = findService(svc);
    if (!node) continue;
    const lines = [`${node.class}  ${node.name}`, ...buildAsciiTree(node.referent, childrenMap, {
      maxDepth: depth,
      maxChildren: maxKids,
    })];
    writeLines(path.join(dirs.tree, `${file}.txt`), lines);
  }

  // Script-only tree under RS + SSS (very useful)
  const scriptFilter = (k) =>
    SCRIPT_CLASSES.has(k.class) ||
    k.class === "Folder" ||
    k.class === "ModuleScript" ||
    k.class === "Configuration" ||
    (childrenMap.get(k.referent) || []).some(
      (c) => SCRIPT_CLASSES.has(c.class) || c.class === "Folder"
    );

  for (const [file, svc] of [
    ["scripts_replicated_storage", "ReplicatedStorage"],
    ["scripts_server", "ServerScriptService"],
    ["scripts_starter_player", "StarterPlayer"],
  ]) {
    const node = findService(svc);
    if (!node) continue;
    const lines = [
      `# Script / Folder tree — ${svc}`,
      `${node.class}  ${node.name}`,
      ...buildAsciiTree(node.referent, childrenMap, {
        maxDepth: 12,
        maxChildren: 300,
        filter: scriptFilter,
      }),
    ];
    writeLines(path.join(dirs.tree, `${file}.txt`), lines);
  }

  // Full shallow hierarchy (depth 3) for overview
  const fullShallow = ["# DataModel (depth ≤ 3)", "Game"];
  for (const r of [...roots].sort((a, b) => {
    const ai = SERVICE_ORDER.indexOf(a.class);
    const bi = SERVICE_ORDER.indexOf(b.class);
    return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
  })) {
    fullShallow.push(`├── ${r.class}  ${r.name}`);
    fullShallow.push(
      ...buildAsciiTree(r.referent, childrenMap, { maxDepth: 3, maxChildren: 40 }).map(
        (l) => `│   ${l}`
      )
    );
  }
  writeLines(path.join(dirs.tree, "overview.txt"), fullShallow);

  writeLines(
    path.join(dirs.tree, "gui.txt"),
    instances.filter((i) => GUI_CLASSES.has(i.class)).map((i) => `${i.class}\t${i.path}`)
  );

  // --- Havoc game-data ---
  const gameData = collectHavocGameData(instances, childrenMap);
  writeLines(path.join(dirs.gameData, "loot_types.txt"), gameData.lootTypes);
  writeLines(path.join(dirs.gameData, "loot_models.txt"), gameData.lootModels);
  writeLines(path.join(dirs.gameData, "tools.txt"), gameData.tools);
  writeLines(path.join(dirs.gameData, "traps.txt"), gameData.traps);
  writeLines(
    path.join(dirs.gameData, "remotes.txt"),
    remotes.map((r) => `${r.class}\t${r.path}`)
  );

  const ws = findService("Workspace");
  const wsFolders = ws
    ? (childrenMap.get(ws.referent) || [])
        .filter((c) => c.class === "Folder" || c.class === "Model")
        .map((c) => `  workspace.${c.name}  (${(childrenMap.get(c.referent) || []).length} children)`)
    : [];
  const rs = findService("ReplicatedStorage");
  const rsKids = rs
    ? (childrenMap.get(rs.referent) || []).map(
        (c) => `  ReplicatedStorage.${c.name} (${c.class}, ${(childrenMap.get(c.referent) || []).length} kids)`
      )
    : [];

  const gameRef = [
    "Havoc — Game Reference (from dump/)",
    "===================================",
    `Dumped: ${new Date().toISOString()}`,
    `Source: ${path.basename(rbxlxPath)} (${(sourceStat.size / 1e6).toFixed(2)} MB)`,
    `PlaceId: ${meta.placeId}  PlaceVersion: ${meta.placeVersion}`,
    `Client: ${meta.clientVersion || "?"}  Executor: ${meta.executor || "?"}`,
    `SynSaveInstance UTC: ${meta.dumpedAtUtc || "?"}`,
    `Instances: ${instances.length.toLocaleString()}  Scripts: ${scripts.length}  Remotes: ${remotes.length}  Assets: ${allAssets.size}`,
    "",
    "WORKSPACE FOLDERS",
    "-----------------",
    ...wsFolders,
    "",
    "REPLICATED STORAGE (top-level)",
    "------------------------------",
    ...rsKids,
    "",
    "COMBAT / NETWORK (typical Havoc)",
    "--------------------------------",
    "  Guns client : ReplicatedStorage.Storage.Modules.Frameworks.Guns.Client",
    "  Network     : ReplicatedStorage.Storage.Modules.Network",
    "  NPC folder  : ReplicatedStorage.Storage.Events.GetGSync (RemoteFunction)",
    "  Fire        : Network:FireServer('fire', …)",
    "",
    "DUMP LAYOUT",
    "-----------",
    "  scripts/hierarchy/  — folder tree matching the place (use this first)",
    "  scripts/flat/       — dotted filenames for search",
    "  tree/*.txt          — ASCII trees (workspace, RS, script-only)",
    "  catalog/*.tsv       — remotes, modules, assets, …",
    "  game-data/          — loot types, tools, traps",
    "  instances/          — full jsonl + by_class/",
    "",
    "COUNTS",
    "------",
    `  ModuleScript: ${scripts.filter((s) => s.class === "ModuleScript").length}`,
    `  LocalScript : ${scripts.filter((s) => s.class === "LocalScript").length}`,
    `  Script      : ${scripts.filter((s) => s.class === "Script").length}`,
    `  RemoteEvent : ${remotes.filter((r) => r.class === "RemoteEvent").length}`,
    `  RemoteFunction: ${remotes.filter((r) => r.class === "RemoteFunction").length}`,
    `  Tools       : ${tools.length}`,
    `  Loot types  : ${gameData.lootTypes.length}`,
    `  Trap names  : ${gameData.traps.length}`,
    "",
    "TOP CLASSES",
    "-----------",
    ...sortedClasses.slice(0, 20).map(([c, n]) => `  ${n}\t${c}`),
  ];
  writeLines(path.join(outDir, "GAME_REFERENCE.txt"), gameRef);

  const manifest = {
    game: "Havoc",
    source_file: path.basename(rbxlxPath),
    source_path: rbxlxPath,
    source_size_bytes: sourceStat.size,
    dumped_at: new Date().toISOString(),
    place_id: meta.placeId,
    place_version: meta.placeVersion,
    client_version: meta.clientVersion,
    executor: meta.executor,
    synsave_dumped_at_utc: meta.dumpedAtUtc,
    total_instances: instances.length,
    total_scripts: scripts.length,
    script_bytes: scriptBytes,
    total_remotes: remotes.length,
    total_assets: allAssets.size,
    total_attributes_instances: attrRows.length,
    class_stats: Object.fromEntries(sortedClasses),
    game_data: {
      loot_types: gameData.lootTypes.length,
      loot_models: gameData.lootModels.length,
      tools: gameData.tools.length,
      traps: gameData.traps.length,
    },
    layout: {
      "scripts/hierarchy": "DataModel-mirrored folders + init.lua",
      "scripts/flat": "dotted Class.lua names",
      "tree/": "ASCII hierarchies",
      "catalog/": "TSV indexes",
      "game-data/": "Havoc loot/tools/traps",
      "instances/": "jsonl + by_class",
      "attributes/": "decoded AttributesSerialize",
    },
    dumper: "scripts/dump-rbxlx.mjs",
  };
  fs.writeFileSync(path.join(outDir, "manifest.json"), JSON.stringify(manifest, null, 2));

  writeLines(path.join(outDir, "README.md"), [
    "# Havoc — rbxlx Full Dump",
    "",
    `Source: \`${manifest.source_file}\``,
    `Size: ${(sourceStat.size / 1e6).toFixed(2)} MB`,
    `PlaceId: **${meta.placeId}** · PlaceVersion: **${meta.placeVersion}**`,
    `Instances: **${instances.length.toLocaleString()}** · Scripts: **${scripts.length}** · Assets: **${allAssets.size}**`,
    "",
    "## Layout",
    "",
    "| Path | Purpose |",
    "|------|---------|",
    "| `scripts/hierarchy/` | **Primary** — mirrors place folders; `ModuleScript` packs use `init.lua` |",
    "| `scripts/flat/` | Dotted paths for ripgrep |",
    "| `scripts/_index.tsv` | referent → hierarchy + flat + requires |",
    "| `tree/` | ASCII trees (`workspace.txt`, `scripts_replicated_storage.txt`, …) |",
    "| `catalog/` | remotes, modules, assets, sounds, … |",
    "| `game-data/` | loot types, tools, traps |",
    "| `instances/` | all.jsonl + by_class/ |",
    "| `attributes/` | decoded AttributesSerialize |",
    "| `GAME_REFERENCE.txt` | cheat-sheet |",
    "",
    "## Regenerate",
    "",
    "```bash",
    "npm run dump",
    "# or",
    `node scripts/dump-rbxlx.mjs "${rbxlxPath.replace(/\\/g, "/")}"`,
    "```",
  ]);

  const ms = Date.now() - t0;
  console.log(`Done in ${(ms / 1000).toFixed(1)}s → ${outDir}`);
  console.log(
    `  instances=${instances.length} scripts=${scripts.length} (~${(scriptBytes / 1e6).toFixed(1)} MB) remotes=${remotes.length} assets=${allAssets.size}`
  );
}

main();
