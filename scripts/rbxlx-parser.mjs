/**
 * Stack parser for Roblox RBXLX (UniversalSynSaveInstance dumps).
 * Builds an instance tree with names, script sources, and simple property values.
 */

const OPEN_RE = /<Item class="([^"]+)" referent="([^"]+)">/g;
const CLOSE_TAG = "</Item>";

const SCRIPT_CLASSES = new Set(["ModuleScript", "LocalScript", "Script"]);

export function parseRbxlx(text) {
  const tags = [];

  let m;
  OPEN_RE.lastIndex = 0;
  while ((m = OPEN_RE.exec(text)) !== null) {
    tags.push({
      type: "open",
      pos: m.index,
      contentStart: m.index + m[0].length,
      className: m[1],
      referent: m[2],
    });
  }

  let pos = 0;
  while ((pos = text.indexOf(CLOSE_TAG, pos)) !== -1) {
    tags.push({
      type: "close",
      pos,
      contentEnd: pos,
    });
    pos += CLOSE_TAG.length;
  }

  tags.sort((a, b) => {
    if (a.pos !== b.pos) return a.pos - b.pos;
    return a.type === "open" ? -1 : 1;
  });

  const root = { className: "Game", name: "Game", referent: "root", children: [] };
  const stack = [root];

  for (const tag of tags) {
    if (tag.type === "open") {
      const node = {
        className: tag.className,
        referent: tag.referent,
        name: tag.className,
        children: [],
        _contentStart: tag.contentStart,
      };
      stack[stack.length - 1].children.push(node);
      stack.push(node);
      continue;
    }

    const node = stack.pop();
    if (!node || node._contentStart == null) continue;

    const raw = text.slice(node._contentStart, tag.contentEnd);
    delete node._contentStart;
    applyProperties(node, raw);
  }

  assignPaths(root, "", {});
  return root;
}

function applyProperties(node, raw) {
  const propsEnd = raw.search(/<Item class="/);
  const propsSection = propsEnd === -1 ? raw : raw.slice(0, propsEnd);

  node.name = readCdata(propsSection, "Name") || node.className;

  if (SCRIPT_CLASSES.has(node.className)) {
    node.source = readCdata(propsSection, "Source") ?? "";
  }

  const stringValue = readCdata(propsSection, "Value");
  if (stringValue != null) node.value = stringValue;

  const doubleValue = readTagValue(propsSection, "double", "Value");
  if (doubleValue != null) node.numberValue = Number(doubleValue);

  const boolValue = readTagValue(propsSection, "bool", "Value");
  if (boolValue != null) node.boolValue = boolValue === "true";

  const texture = readCdata(propsSection, "Texture")
    ?? readCdata(propsSection, "TextureID")
    ?? readCdata(propsSection, "Image")
    ?? readUrlContent(propsSection, "SoundId");
  if (texture) node.assetRef = texture;

  if (node.className === "Tool") {
    const tex = readCdata(propsSection, "TextureId");
    if (tex) node.textureId = tex;
  }
}

function readCdata(section, propName) {
  const re = new RegExp(
    `<(?:string|ProtectedString) name="${propName}"><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/(?:string|ProtectedString)>`,
    "m"
  );
  const m = section.match(re);
  return m ? m[1] : null;
}

function readTagValue(section, tag, propName) {
  const re = new RegExp(`<${tag} name="${propName}">([^<]*)<\\/${tag}>`);
  const m = section.match(re);
  return m ? m[1].trim() : null;
}

function readUrlContent(section, propName) {
  const re = new RegExp(
    `<Content name="${propName}"><url><!\\[CDATA\\[([^\\]]+)\\]\\]><\\/url><\\/Content>`,
    "m"
  );
  const m = section.match(re);
  return m ? m[1] : null;
}

function safeSegment(name) {
  return String(name || "unnamed")
    .replace(/[<>:"|?*\\]/g, "_")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 120) || "unnamed";
}

function assignPaths(node, parentPath, siblingCounts) {
  const base = safeSegment(node.name);
  const key = `${parentPath}\0${base}`;
  siblingCounts[key] = (siblingCounts[key] || 0) + 1;
  const suffix = siblingCounts[key] > 1 ? `_${siblingCounts[key]}` : "";
  node.path = parentPath ? `${parentPath}/${base}${suffix}` : `${base}${suffix}`;

  for (const child of node.children) {
    assignPaths(child, node.path, siblingCounts);
  }
}

export function walkTree(node, visit) {
  visit(node);
  for (const child of node.children) walkTree(child, visit);
}

export function collectByClass(root, className) {
  const out = [];
  walkTree(root, (node) => {
    if (node.className === className) out.push(node);
  });
  return out;
}

export { SCRIPT_CLASSES };
