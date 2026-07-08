#!/usr/bin/env node
/**
 * Download decal/image assets via Roblox Thumbnails API with rate limiting.
 *
 * Run: node scripts/extract-item-catalog.mjs && npm run download-assets
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const MANIFEST = path.join(ROOT, "dump/manifest.json");
const CATALOG = path.join(ROOT, "src/game/havoc_item_catalog.lua");
const OUT_DIR = path.join(ROOT, "assets/decals");

const THUMB_API = "https://thumbnails.roblox.com/v1/assets";
const BATCH = 25;
const DELAY_MS = 500;
const RETRY_DELAY_MS = 2000;
const MAX_RETRIES = 3;

const args = process.argv.slice(2);
const missingOnly = args.includes("--missing-only");
const slow = args.includes("--slow");

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function collectCatalogIds() {
  if (!fs.existsSync(CATALOG)) return [];
  const src = fs.readFileSync(CATALOG, "utf8");
  const ids = new Set();
  for (const match of src.matchAll(/default = "(\d+)"/g)) {
    if (match[1] && match[1] !== "0") ids.add(match[1]);
  }
  for (const match of src.matchAll(/\] = "(\d+)"/g)) {
    if (match[1] && match[1] !== "0") ids.add(match[1]);
  }
  return [...ids];
}

async function downloadUrl(url, dest) {
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": "July-Asset-Sync/1.0" },
        redirect: "follow",
      });
      if (res.status === 429) {
        await sleep(RETRY_DELAY_MS * attempt);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());
      if (buf.length < 50) throw new Error(`too small (${buf.length}b)`);
      fs.writeFileSync(dest, buf);
      return buf.length;
    } catch (e) {
      if (attempt === MAX_RETRIES) throw e;
      await sleep(RETRY_DELAY_MS);
    }
  }
}

async function resolveThumbnails(ids) {
  const q = new URLSearchParams({
    assetIds: ids.join(","),
    returnPolicy: "PlaceHolder",
    size: "420x420",
    format: "Png",
  });
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const res = await fetch(`${THUMB_API}?${q}`, {
      headers: { "User-Agent": "July-Asset-Sync/1.0" },
    });
    if (res.status === 429) {
      await sleep(RETRY_DELAY_MS * attempt);
      continue;
    }
    if (!res.ok) throw new Error(`Thumbnails API HTTP ${res.status}`);
    const json = await res.json();
    const out = new Map();
    const rows = json.data || [];
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const id = ids[i];
      if (id && row.imageUrl && row.state === "Completed") {
        out.set(String(id), row.imageUrl);
      }
    }
    return out;
  }
  throw new Error("Thumbnails API rate limited");
}

async function main() {
  const manifestIds = fs.existsSync(MANIFEST)
    ? Object.keys(JSON.parse(fs.readFileSync(MANIFEST, "utf8")).decals || {})
    : [];
  const catalogIds = collectCatalogIds();
  let ids = [...new Set([...manifestIds, ...catalogIds])].filter((id) => id && id !== "0");

  fs.mkdirSync(OUT_DIR, { recursive: true });

  if (missingOnly) {
    ids = ids.filter((id) => !fs.existsSync(path.join(OUT_DIR, `${id}.png`)));
  }

  const delay = slow ? DELAY_MS * 2 : DELAY_MS;
  console.log(`Downloading ${ids.length} assets → assets/decals/ (batch=${BATCH}, delay=${delay}ms)`);

  let ok = 0;
  let fail = 0;

  for (let i = 0; i < ids.length; i += BATCH) {
    const batch = ids.slice(i, i + BATCH);
    let thumbs;
    try {
      thumbs = await resolveThumbnails(batch);
    } catch (e) {
      console.warn(`  batch ${i}-${i + batch.length}: ${e.message}`);
      fail += batch.length;
      await sleep(RETRY_DELAY_MS);
      continue;
    }

    for (const id of batch) {
      const dest = path.join(OUT_DIR, `${id}.png`);
      const url = thumbs.get(String(id));
      if (!url) {
        console.warn(`  skip ${id} — no thumbnail`);
        fail++;
        continue;
      }
      try {
        const size = await downloadUrl(url, dest);
        console.log(`  ✓ ${id}.png (${(size / 1024).toFixed(1)} KB)`);
        ok++;
      } catch (e) {
        console.warn(`  ✗ ${id}: ${e.message}`);
        fail++;
      }
      await sleep(50);
    }

    if (i + BATCH < ids.length) await sleep(delay);
  }

  const report = { ok, fail, total: ids.length, downloadedAt: new Date().toISOString() };
  fs.writeFileSync(path.join(OUT_DIR, "download_report.json"), JSON.stringify(report, null, 2));
  console.log(`Done: ${ok} ok, ${fail} failed`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
