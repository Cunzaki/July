#!/usr/bin/env node
/**
 * Vector local MCP — API.md + game dump search for July / April / Vector scripts.
 *
 * Complements the official GitBook MCP (vector-lua-engine).
 * Does NOT talk to a live Vector process (no runtime IPC exists).
 *
 * Tools:
 *   search_vector_api   — search April/docs/API.md
 *   get_api_section     — fetch a ## section from API.md
 *   search_game_dump    — search Havoc (July) and/or Fallen (April) dumps
 *   list_dump_scripts   — find dump script files by name
 *   read_dump_file      — read a file under a dump root (size-capped)
 *   havoc_reference     — GAME_REFERENCE.txt for Havoc
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WORKSPACE = path.resolve(__dirname, '../../..'); // Vector Scripts/
const JULY = path.join(WORKSPACE, 'July');
const APRIL = path.join(WORKSPACE, 'April');

const PATHS = {
  api: path.join(APRIL, 'docs', 'API.md'),
  havocDump: path.join(JULY, 'dump'),
  fallenDump: path.join(APRIL, 'dump'),
  havocRef: path.join(JULY, 'dump', 'GAME_REFERENCE.txt'),
  fallenRef: path.join(APRIL, 'dump', 'GAME_REFERENCE.txt'),
};

const MAX_READ = 80_000;
const MAX_HITS = 40;
const CONTEXT = 2;

function text(s) {
  return { content: [{ type: 'text', text: String(s) }] };
}

function exists(p) {
  try {
    return fs.existsSync(p);
  } catch {
    return false;
  }
}

function readLimited(filePath, max = MAX_READ) {
  const buf = fs.readFileSync(filePath);
  if (buf.length <= max) return buf.toString('utf8');
  return buf.subarray(0, max).toString('utf8') + `\n\n… truncated (${buf.length} bytes total)`;
}

function searchFile(filePath, query, maxHits = MAX_HITS) {
  if (!exists(filePath)) return [`Missing: ${filePath}`];
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  const q = query.toLowerCase();
  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].toLowerCase().includes(q)) continue;
    const start = Math.max(0, i - CONTEXT);
    const end = Math.min(lines.length - 1, i + CONTEXT);
    const block = [];
    for (let j = start; j <= end; j++) {
      block.push(`${j + 1}|${lines[j]}`);
    }
    hits.push(block.join('\n'));
    if (hits.length >= maxHits) break;
  }
  if (hits.length === 0) return [`No matches for "${query}" in ${path.basename(filePath)}`];
  return hits;
}

function walkFiles(root, { exts, maxFiles = 4000 } = {}) {
  const out = [];
  if (!exists(root)) return out;
  const stack = [root];
  while (stack.length && out.length < maxFiles) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (e.name === 'node_modules' || e.name === '.git') continue;
        stack.push(full);
      } else if (e.isFile()) {
        if (exts && !exts.some((x) => e.name.toLowerCase().endsWith(x))) continue;
        out.push(full);
      }
    }
  }
  return out;
}

function searchDump(dumpRoot, query, { prefer = [], maxHits = 25 } = {}) {
  if (!exists(dumpRoot)) return [`Dump missing: ${dumpRoot}`];
  const q = query.toLowerCase();
  const preferNames = prefer.map((p) => p.toLowerCase());
  const candidates = [];

  // Prefer catalogs / refs first
  for (const name of [
    'GAME_REFERENCE.txt',
    'README.md',
    'manifest.json',
    'modules.txt',
    'remotes.txt',
    path.join('catalog', 'modules.tsv'),
    path.join('catalog', 'remotes.tsv'),
    path.join('catalog', 'tools.tsv'),
  ]) {
    const p = path.join(dumpRoot, name);
    if (exists(p)) candidates.push(p);
  }

  // Then text/json/tsv/lua under scripts + catalog + game-data
  for (const sub of ['catalog', 'game-data', 'scripts', 'tree']) {
    const subRoot = path.join(dumpRoot, sub);
    for (const f of walkFiles(subRoot, {
      exts: ['.txt', '.tsv', '.md', '.json', '.jsonl', '.lua'],
      maxFiles: 800,
    })) {
      candidates.push(f);
    }
  }

  // Dedupe preserve order
  const seen = new Set();
  const files = [];
  for (const f of candidates) {
    if (seen.has(f)) continue;
    seen.add(f);
    files.push(f);
  }

  // Sort preferred filename matches first
  files.sort((a, b) => {
    const an = path.basename(a).toLowerCase();
    const bn = path.basename(b).toLowerCase();
    const ap = preferNames.some((p) => an.includes(p)) ? 0 : 1;
    const bp = preferNames.some((p) => bn.includes(p)) ? 0 : 1;
    return ap - bp;
  });

  const results = [];
  for (const file of files) {
    if (results.length >= maxHits) break;
    let content;
    try {
      const st = fs.statSync(file);
      if (st.size > 2_000_000) continue; // skip huge jsonl for naive scan
      content = fs.readFileSync(file, 'utf8');
    } catch {
      continue;
    }
    if (!content.toLowerCase().includes(q)) continue;
    const lines = content.split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      if (!lines[i].toLowerCase().includes(q)) continue;
      const rel = path.relative(dumpRoot, file);
      const start = Math.max(0, i - 1);
      const end = Math.min(lines.length - 1, i + 1);
      const block = [];
      for (let j = start; j <= end; j++) block.push(`${j + 1}|${lines[j]}`);
      results.push(`### ${rel}\n${block.join('\n')}`);
      if (results.length >= maxHits) break;
    }
  }

  if (results.length === 0) return [`No dump matches for "${query}" under ${dumpRoot}`];
  return results;
}

function getApiSection(name) {
  if (!exists(PATHS.api)) return `API.md missing at ${PATHS.api}`;
  const raw = fs.readFileSync(PATHS.api, 'utf8');
  const lines = raw.split(/\r?\n/);
  const needle = name.trim().toLowerCase();
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^##\s+(.+)$/);
    if (!m) continue;
    if (m[1].toLowerCase().includes(needle)) {
      start = i;
      break;
    }
  }
  if (start < 0) {
    const headings = lines
      .filter((l) => l.startsWith('## '))
      .map((l) => l.slice(3))
      .join('\n');
    return `Section not found: "${name}"\n\nAvailable:\n${headings}`;
  }
  let end = lines.length;
  for (let i = start + 1; i < lines.length; i++) {
    if (/^##\s+/.test(lines[i])) {
      end = i;
      break;
    }
  }
  return lines.slice(start, end).join('\n');
}

function resolveDumpRoot(game) {
  if (game === 'havoc' || game === 'july') return PATHS.havocDump;
  if (game === 'fallen' || game === 'april') return PATHS.fallenDump;
  return null;
}

const server = new McpServer({
  name: 'vector-local',
  version: '1.0.0',
});

server.registerTool(
  'search_vector_api',
  {
    title: 'Search Vector API.md',
    description:
      'Full-text search of April/docs/API.md (Vector Lua Engine API 1.4 + April conventions). Use for draw/entity/raycast/menu/gc rules.',
    inputSchema: {
      query: z.string().describe('Search string, e.g. track_silent_target, getgc, on_frame'),
    },
  },
  async ({ query }) => text(searchFile(PATHS.api, query).join('\n\n---\n\n'))
);

server.registerTool(
  'get_api_section',
  {
    title: 'Get API.md section',
    description: 'Return one ## section from API.md by name substring (e.g. "Raycast", "GC API", "Rules").',
    inputSchema: {
      section: z.string().describe('Section name substring'),
    },
  },
  async ({ section }) => text(getApiSection(section))
);

server.registerTool(
  'search_game_dump',
  {
    title: 'Search game dump',
    description:
      'Search extracted rbxlx dump catalogs/scripts. game=havoc (July place 16530963934) or fallen (April place 13800717766).',
    inputSchema: {
      query: z.string(),
      game: z.enum(['havoc', 'fallen', 'july', 'april']).default('havoc'),
    },
  },
  async ({ query, game }) => {
    const root = resolveDumpRoot(game);
    return text(searchDump(root, query).join('\n\n'));
  }
);

server.registerTool(
  'list_dump_scripts',
  {
    title: 'List dump scripts',
    description: 'List script filenames in a dump that match a name substring.',
    inputSchema: {
      name: z.string().describe('Substring of script path/name'),
      game: z.enum(['havoc', 'fallen', 'july', 'april']).default('havoc'),
      limit: z.number().int().min(1).max(200).default(50),
    },
  },
  async ({ name, game, limit }) => {
    const root = resolveDumpRoot(game);
    const scripts = path.join(root, 'scripts');
    if (!exists(scripts)) return text(`No scripts/ under ${root}`);
    const q = name.toLowerCase();
    const matches = walkFiles(scripts, { exts: ['.lua'], maxFiles: 5000 })
      .map((f) => path.relative(scripts, f))
      .filter((rel) => rel.toLowerCase().includes(q))
      .slice(0, limit);
    return text(matches.length ? matches.join('\n') : `No scripts matching "${name}"`);
  }
);

server.registerTool(
  'read_dump_file',
  {
    title: 'Read dump file',
    description: 'Read a relative path under a dump root (e.g. GAME_REFERENCE.txt, catalog/remotes.tsv, scripts/...).',
    inputSchema: {
      relative_path: z.string(),
      game: z.enum(['havoc', 'fallen', 'july', 'april']).default('havoc'),
    },
  },
  async ({ relative_path, game }) => {
    const root = resolveDumpRoot(game);
    const full = path.resolve(root, relative_path);
    if (!full.startsWith(path.resolve(root))) return text('Path escapes dump root');
    if (!exists(full)) return text(`Not found: ${relative_path}`);
    return text(readLimited(full));
  }
);

server.registerTool(
  'havoc_reference',
  {
    title: 'Havoc game reference',
    description: 'Return July/dump/GAME_REFERENCE.txt — Havoc place combat/loot/workspace cheat sheet.',
    inputSchema: {},
  },
  async () => {
    if (!exists(PATHS.havocRef)) return text(`Missing ${PATHS.havocRef}`);
    return text(readLimited(PATHS.havocRef, 120_000));
  }
);

server.registerTool(
  'vector_mcp_info',
  {
    title: 'Vector MCP capabilities',
    description: 'Explain what this MCP can and cannot do vs the GitBook MCP / live Vector.',
    inputSchema: {},
  },
  async () =>
    text(`Vector MCP landscape

1) Official GitBook MCP (already in Cursor as vector-lua-engine)
   URL: https://project-vector-1.gitbook.io/vector-lua-engine/~gitbook/mcp
   Tools: searchDocumentation, getPage
   Best for: live official prose docs

2) This server (vector-local)
   Local API.md + Havoc/Fallen dumps
   Best for: offline API rules, dump remotes/modules/scripts, July/April RE

3) NOT possible without Vector exposing IPC
   - Inject / toggle modules in a running Vector client
   - Stream entity/draw state from Vector into Cursor
   - Call raycast.* / menu.* from MCP (those only exist inside Vector's Lua sandbox)

Paths
  API: ${PATHS.api} (${exists(PATHS.api) ? 'ok' : 'MISSING'})
  Havoc dump: ${PATHS.havocDump} (${exists(PATHS.havocDump) ? 'ok' : 'MISSING'})
  Fallen dump: ${PATHS.fallenDump} (${exists(PATHS.fallenDump) ? 'ok' : 'MISSING'})
`)
);

const transport = new StdioServerTransport();
await server.connect(transport);
