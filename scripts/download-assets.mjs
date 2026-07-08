#!/usr/bin/env node
/**
 * Download game asset thumbnails with conservative rate limiting and resume support.
 *
 * Sources (in priority order):
 *   dump/assets/asset_ids.txt   — all rbxassetid from place
 *   dump/assets/decals.json     — decal/image map
 *   dump/manifest.json          — decal keys
 *   src/game/havoc_item_catalog.lua — item texture IDs
 *   dump/catalog/instances.jsonl  — weaponsInfo textureId rows
 *
 * Run: npm run download-assets
 *      npm run download-missing   (skip existing PNGs, slower pacing)
 */

import fs from "fs";
import path from "path";
import readline from "readline";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT_DIR = path.join(ROOT, "assets/decals");
const REPORT_PATH = path.join(OUT_DIR, "download_report.json");
const PROGRESS_PATH = path.join(OUT_DIR, "download_progress.json");

const THUMB_API = "https://thumbnails.roblox.com/v1/assets";
const BATCH = 100; // Roblox allows up to 100 IDs per request
const API_INTERVAL_MS = 700; // ~86 req/min (limit is 100/min)
const API_INTERVAL_SLOW_MS = 1000;
const CDN_CONCURRENCY = 12;
const RETRY_DELAY_MS = 3000;
const MAX_RETRIES = 4;

const args = process.argv.slice(2);
const missingOnly = args.includes("--missing-only");
const slow = args.includes("--slow");
const allIds = args.includes("--all") || !args.includes("--catalog-only");

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function parseRetryAfter(res) {
  const header = res.headers.get("Retry-After");
  if (!header) return null;
  const seconds = Number(header);
  if (!Number.isNaN(seconds)) return seconds * 1000;
  const date = Date.parse(header);
  if (!Number.isNaN(date)) return Math.max(0, date - Date.now());
  return null;
}

class ApiRateLimiter {
  constructor(intervalMs) {
    this.intervalMs = intervalMs;
    this.nextSlot = 0;
    this.backoffUntil = 0;
  }

  async acquire() {
    const now = Date.now();
    const waitFor = Math.max(this.nextSlot - now, this.backoffUntil - now, 0);
    if (waitFor > 0) await sleep(waitFor);
    this.nextSlot = Math.max(Date.now(), this.nextSlot) + this.intervalMs;
  }

  penalize(retryAfterMs) {
    const penalty = retryAfterMs || this.intervalMs * 3;
    this.backoffUntil = Date.now() + penalty;
    this.nextSlot = this.backoffUntil;
  }
}

async function runPool(items, concurrency, fn) {
  const results = new Array(items.length);
  let index = 0;
  async function worker() {
    while (index < items.length) {
      const i = index++;
      results[i] = await fn(items[i], i);
    }
  }
  const workers = Math.min(concurrency, items.length);
  await Promise.all(Array.from({ length: workers }, worker));
  return results;
}

function readText(file) {
  if (!fs.existsSync(file)) return "";
  return fs.readFileSync(file, "utf8");
}

function collectFromAssetIdsTxt() {
  const file = path.join(ROOT, "dump/assets/asset_ids.txt");
  const ids = new Set();
  for (const line of readText(file).split(/\r?\n/)) {
    const id = line.trim();
    if (/^\d+$/.test(id) && id !== "0") ids.add(id);
  }
  return ids;
}

function collectFromDecalsJson() {
  const ids = new Set();
  for (const file of [
    path.join(ROOT, "dump/assets/decals.json"),
    path.join(ROOT, "dump/manifest.json"),
  ]) {
    if (!fs.existsSync(file)) continue;
    const data = JSON.parse(readText(file));
    const decals = data.decals || data;
    if (decals && typeof decals === "object") {
      for (const id of Object.keys(decals)) {
        if (/^\d+$/.test(id) && id !== "0") ids.add(id);
      }
    }
  }
  return ids;
}

function collectFromCatalogLua() {
  const file = path.join(ROOT, "src/game/havoc_item_catalog.lua");
  if (!fs.existsSync(file)) return new Set();
  const src = readText(file);
  const ids = new Set();
  for (const match of src.matchAll(/default = "(\d+)"/g)) {
    if (match[1] && match[1] !== "0") ids.add(match[1]);
  }
  for (const match of src.matchAll(/\] = "(\d+)"/g)) {
    if (match[1] && match[1] !== "0") ids.add(match[1]);
  }
  return ids;
}

async function collectFromInstancesJsonl() {
  const file = path.join(ROOT, "dump/catalog/instances.jsonl");
  if (!fs.existsSync(file)) return new Set();
  const ids = new Set();
  const rl = readline.createInterface({
    input: fs.createReadStream(file, { encoding: "utf8" }),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    if (!line.includes("textureId") || !line.includes("rbxassetid")) continue;
    for (const match of line.matchAll(/rbxassetid:\/\/(\d+)/g)) {
      if (match[1] && match[1] !== "0") ids.add(match[1]);
    }
  }
  return ids;
}

function loadProgress() {
  if (!fs.existsSync(PROGRESS_PATH)) return { completed: {}, failed: {} };
  try {
    return JSON.parse(readText(PROGRESS_PATH));
  } catch {
    return { completed: {}, failed: {} };
  }
}

function saveProgress(progress) {
  fs.writeFileSync(PROGRESS_PATH, JSON.stringify(progress, null, 2));
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

async function resolveThumbnails(ids, rateLimiter) {
  const q = new URLSearchParams({
    assetIds: ids.join(","),
    returnPolicy: "PlaceHolder",
    size: "420x420",
    format: "Png",
  });
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    await rateLimiter.acquire();
    const res = await fetch(`${THUMB_API}?${q}`, {
      headers: { "User-Agent": "July-Asset-Sync/1.0" },
    });
    if (res.status === 429) {
      rateLimiter.penalize(parseRetryAfter(res) || RETRY_DELAY_MS * attempt);
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

async function downloadBatch(batch, thumbs, progress, stats) {
  const jobs = batch.map((id) => ({
    id,
    url: thumbs.get(String(id)),
    dest: path.join(OUT_DIR, `${id}.png`),
  }));

  await runPool(jobs, CDN_CONCURRENCY, async ({ id, url, dest }) => {
    if (fs.existsSync(dest)) {
      progress.completed[id] = fs.statSync(dest).size;
      stats.skipped++;
      return;
    }

    if (!url) {
      progress.failed[id] = "no thumbnail";
      stats.fail++;
      return;
    }

    try {
      const size = await downloadUrl(url, dest);
      progress.completed[id] = size;
      stats.ok++;
      if (stats.ok % 50 === 0) {
        console.log(`  ✓ ${stats.ok} downloaded (${id}.png, ${(size / 1024).toFixed(1)} KB)`);
      }
    } catch (e) {
      progress.failed[id] = e.message;
      console.warn(`  ✗ ${id}: ${e.message}`);
      stats.fail++;
    }
  });

  if ((stats.ok + stats.fail) % 50 === 0) saveProgress(progress);
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const catalogIds = collectFromCatalogLua();
  const decalIds = collectFromDecalsJson();
  const textureIds = await collectFromInstancesJsonl();
  const allAssetIds = collectFromAssetIdsTxt();

  let ids;
  if (allIds) {
    ids = new Set([...allAssetIds, ...decalIds, ...catalogIds, ...textureIds]);
  } else {
    ids = new Set([...decalIds, ...catalogIds, ...textureIds]);
  }

  ids = [...ids].filter((id) => id && id !== "0").sort((a, b) => Number(a) - Number(b));

  if (missingOnly) {
    ids = ids.filter((id) => !fs.existsSync(path.join(OUT_DIR, `${id}.png`)));
  }

  const progress = loadProgress();
  ids = ids.filter((id) => !progress.completed[id]);

  const apiInterval = slow ? API_INTERVAL_SLOW_MS : API_INTERVAL_MS;
  const rateLimiter = new ApiRateLimiter(apiInterval);
  console.log(
    `Downloading ${ids.length} assets → assets/decals/ (batch=${BATCH}, api=${apiInterval}ms, cdn=${CDN_CONCURRENCY}, all=${allIds})`
  );

  const stats = { ok: 0, fail: 0, skipped: 0 };
  let pendingDownloads = Promise.resolve();

  for (let i = 0; i < ids.length; i += BATCH) {
    const batch = ids.slice(i, i + BATCH);
    let thumbs;
    for (let batchAttempt = 1; batchAttempt <= MAX_RETRIES; batchAttempt++) {
      try {
        thumbs = await resolveThumbnails(batch, rateLimiter);
        break;
      } catch (e) {
        if (batchAttempt === MAX_RETRIES) {
          console.warn(`  batch ${i}-${i + batch.length}: ${e.message} (giving up)`);
          for (const id of batch) {
            progress.failed[id] = e.message;
            stats.fail++;
          }
          saveProgress(progress);
        } else {
          console.warn(`  batch ${i}-${i + batch.length}: ${e.message} (retry ${batchAttempt}/${MAX_RETRIES})`);
          rateLimiter.penalize(RETRY_DELAY_MS * batchAttempt);
        }
      }
    }
    if (!thumbs) continue;

    pendingDownloads = pendingDownloads.then(() => downloadBatch(batch, thumbs, progress, stats));
  }

  await pendingDownloads;
  const { ok, fail, skipped } = stats;

  saveProgress(progress);

  const report = {
    ok,
    fail,
    skipped,
    total: ids.length,
    allMode: allIds,
    completedTotal: Object.keys(progress.completed).length,
    failedTotal: Object.keys(progress.failed).length,
    downloadedAt: new Date().toISOString(),
  };
  fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2));
  console.log(`Done: ${ok} ok, ${fail} failed, ${skipped} skipped, ${report.completedTotal} total on disk`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
