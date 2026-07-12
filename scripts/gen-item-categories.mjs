import fs from "fs";
import path from "path";

const base =
  "c:/Users/Cunza/Desktop/Projects/Vector Scripts/July/dump/scripts/hierarchy/ReplicatedStorage/Storage/Modules/Items";
const outPath =
  "c:/Users/Cunza/Desktop/Projects/Vector Scripts/July/src/game/item_categories.lua";

const cats = fs
  .readdirSync(base, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .sort();

const sections = [];
const nameToCat = {};

for (const c of cats) {
  const dir = path.join(base, c);
  const names = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".lua"))
    .map((f) => f.replace(/\.lua$/, "").replace(/_/g, " "))
    .sort();
  const label = c.charAt(0).toUpperCase() + c.slice(1);
  sections.push({ id: c, label, items: names });
  for (const n of names) nameToCat[n] = c;
}

function toLua(val, indent = 0) {
  const pad = "    ".repeat(indent);
  if (val === null) return "nil";
  if (typeof val === "string") return JSON.stringify(val);
  if (typeof val === "number" || typeof val === "boolean") return String(val);
  if (Array.isArray(val)) {
    if (val.length === 0) return "{}";
    const lines = val.map((v) => pad + "    " + toLua(v, indent + 1));
    return "{\n" + lines.join(",\n") + ",\n" + pad + "}";
  }
  const keys = Object.keys(val);
  if (keys.length === 0) return "{}";
  const lines = keys.map(
    (k) => pad + "    [" + JSON.stringify(k) + "] = " + toLua(val[k], indent + 1)
  );
  return "{\n" + lines.join(",\n") + ",\n" + pad + "}";
}

const lua = `local M = {}

M.SECTIONS = ${toLua(sections)}

M.NAME_TO_CATEGORY = ${toLua(nameToCat)}

function M.resolve(name)
    if not name or name == "" then return nil end
    return M.NAME_TO_CATEGORY[name]
end

function M.section(id)
    for i = 1, #M.SECTIONS do
        local s = M.SECTIONS[i]
        if s.id == id then
            return s, i
        end
    end
    return nil
end

function M.section_index(id)
    for i = 1, #M.SECTIONS do
        if M.SECTIONS[i].id == id then
            return i
        end
    end
    return nil
end

return M
`;

fs.writeFileSync(outPath, lua);
console.log("wrote", sections.length, "sections", Object.keys(nameToCat).length, "items");
