// W3C Design Tokens Format and Resolver Modules, 2025.10.
const D = {};
export default D;
{
  const isObj = v => v && typeof v === "object" && !Array.isArray(v);
  const isToken = v => isObj(v) && "$value" in v;
  const ALIAS = /^\{([^{}]+)\}$/;

  // get(path) returns the parsed JSON of a file.
  D.load = async (resolverPath, get) => {
    const dir = resolverPath.replace(/[^/]*$/, ""), resolver = await get(resolverPath), files = {};
    const src = async s => {
      if (!s.$ref) return s;
      if (s.$ref.startsWith("#/")) throw new Error("A source can't point inside the resolver: " + s.$ref);
      return files[s.$ref] || (files[s.$ref] = await get(dir + s.$ref));
    };
    const layers = async list => { let t = {}; for (const s of list) t = D.merge(t, await src(s)); return t; };
    const order = resolver.resolutionOrder.map(x => x.$ref.replace("#/", "").split("/"));
    const mods = order.filter(([k]) => k === "modifiers").map(([, name]) => name);
    if (mods.length > 1) throw new Error("Only one modifier is supported");
    const build = async ctx => { let t = {}; for (const [kind, name] of order) t = D.merge(t, await layers(kind === "sets" ? resolver.sets[name].sources : resolver.modifiers[name].contexts[ctx])); return t; };
    const out = { resolver, files, contexts: {} };
    let base = {}; for (const [kind, name] of order) if (kind === "sets") base = D.merge(base, await layers(resolver.sets[name].sources));
    out.base = base;
    const modifier = mods[0] && resolver.modifiers[mods[0]];
    for (const ctx of modifier ? Object.keys(modifier.contexts) : ["default"]) out.contexts[ctx] = await build(ctx);
    return out;
  };

  D.merge = (a, b) => {
    if (!isObj(a) || !isObj(b) || isToken(b) || isToken(a)) return b;
    const out = { ...a };
    for (const [k, v] of Object.entries(b)) out[k] = k in out && !k.startsWith("$") ? D.merge(out[k], v) : v;
    return out;
  };

  D.tokens = tree => {
    const out = new Map();
    const walk = (node, path, type) => {
      const t = node.$type || type;
      for (const [k, v] of Object.entries(node)) {
        if (k.startsWith("$") && k !== "$root") continue;
        if (!isObj(v)) continue;
        const p = k === "$root" ? path : [...path, k];
        if (isToken(v)) out.set(p.join("."), { path: p.join("."), raw: v.$value, type: v.$type || t, description: v.$description, deprecated: v.$deprecated, extensions: v.$extensions });
        else walk(v, p, t);
      }
    };
    walk(tree, [], undefined);
    return out;
  };

  // With onError, a token that can't be resolved is reported and skipped.
  D.resolve = (tree, onError) => {
    const all = D.tokens(tree), done = new Map();
    const get = (path, stack) => {
      if (done.has(path)) return done.get(path);
      const t = all.get(path);
      if (!t) throw new Error(`{${path}} points at nothing` + (stack.length ? ` (from ${stack[stack.length - 1]})` : ""));
      if (stack.includes(path)) throw new Error("Aliases go round in a circle: " + [...stack, path].join(" → "));
      const nextStack = [...stack, path];
      const value = val(t.raw, nextStack);
      const alias = typeof t.raw === "string" && t.raw.match(ALIAS);
      const resolved = { ...t, value, type: t.type || (alias ? get(alias[1], nextStack).type : undefined), alias: alias ? alias[1] : undefined };
      done.set(path, resolved);
      return resolved;
    };
    const val = (v, stack) => {
      if (typeof v === "string") { const m = v.match(ALIAS); return m ? get(m[1], stack).value : v; }
      if (Array.isArray(v)) return v.map(x => val(x, stack));
      if (isObj(v)) return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, val(x, stack)]));
      return v;
    };
    for (const p of all.keys()) { try { get(p, []); } catch (e) { if (!onError) throw e; onError(e.message); } }
    return done;
  };

  const WEIGHTS = { thin: 100, hairline: 100, "extra-light": 200, "ultra-light": 200, light: 300, normal: 400, regular: 400, book: 400, medium: 500, "semi-bold": 600, "demi-bold": 600, bold: 700, "extra-bold": 800, "ultra-bold": 800, black: 900, heavy: 900, "extra-black": 950, "ultra-black": 950 };
  const num = v => typeof v === "number" && isFinite(v);
  const dim = (v, units = ["px", "rem"]) => isObj(v) && num(v.value) && units.includes(v.unit);
  const CHECK = {
    color: v => isObj(v) && typeof v.colorSpace === "string" && Array.isArray(v.components) && v.components.length === 3 && v.components.every(c => c === "none" || (num(c) && (v.colorSpace !== "srgb" || (c >= 0 && c <= 1))))
      && (v.alpha == null || (num(v.alpha) && v.alpha >= 0 && v.alpha <= 1)) && (v.hex == null || /^#[0-9a-f]{6}$/i.test(v.hex)),
    dimension: v => dim(v),
    duration: v => dim(v, ["ms", "s"]),
    cubicBezier: v => Array.isArray(v) && v.length === 4 && v.every(num) && v[0] >= 0 && v[0] <= 1 && v[2] >= 0 && v[2] <= 1,
    number: num,
    fontFamily: v => typeof v === "string" || (Array.isArray(v) && v.length > 0 && v.every(x => typeof x === "string")),
    fontWeight: v => (num(v) && v >= 1 && v <= 1000) || v in WEIGHTS,
    shadow: v => (Array.isArray(v) ? v : [v]).every(s => isObj(s) && CHECK.color(s.color) && dim(s.offsetX) && dim(s.offsetY) && dim(s.blur) && dim(s.spread) && (s.inset == null || typeof s.inset === "boolean")),
    typography: v => isObj(v) && CHECK.fontFamily(v.fontFamily) && dim(v.fontSize) && CHECK.fontWeight(v.fontWeight) && dim(v.letterSpacing) && num(v.lineHeight)
  };
  D.TYPES = Object.keys(CHECK);
  D.check = tree => {
    const bad = [];
    const names = (node, path) => {
      for (const [k, v] of Object.entries(node)) {
        const p = [...path, k].join(".");
        if (k.startsWith("$")) { if (!["$value", "$type", "$description", "$extensions", "$deprecated", "$root", "$extends", "$schema"].includes(k)) bad.push(`${p}: unknown property`); if (k === "$type" && !CHECK[v]) bad.push(`${p}: unknown type "${v}"`); continue; }
        if (/[{}.]/.test(k)) bad.push(`${p}: a name can't contain { } or .`);
        if (isObj(v) && !isToken(v)) names(v, [...path, k]);
      }
    };
    names(tree, []);
    const res = D.resolve(tree, msg => bad.push(msg));
    for (const t of res.values()) {
      if (!t.type) bad.push(`${t.path}: no $type, here or on a group above it`);
      else if (!CHECK[t.type]) bad.push(`${t.path}: unknown type "${t.type}"`);
      else if (!CHECK[t.type](t.value)) bad.push(`${t.path}: not a valid ${t.type}: ${JSON.stringify(t.value).slice(0, 120)}`);
    }
    return bad;
  };

  const round = (n, d = 4) => Math.round(n * 10 ** d) / 10 ** d;
  D.rgb = c => c.components.map(x => Math.round((x === "none" ? 0 : x) * 255));
  D.hex = c => c.hex ? c.hex.toLowerCase() : "#" + D.rgb(c).map(x => x.toString(16).padStart(2, "0")).join("");
  const GENERIC = ["serif", "sans-serif", "monospace", "cursive", "fantasy", "system-ui", "ui-serif", "ui-sans-serif", "ui-monospace", "ui-rounded", "-apple-system", "BlinkMacSystemFont"];
  D.css = (type, v) => {
    if (type === "color") return v.alpha != null && v.alpha < 1 ? `rgb(${D.rgb(v).join(" ")} / ${round(v.alpha, 3)})` : D.hex(v);
    if (type === "dimension" || type === "duration") return `${round(v.value)}${v.unit}`;
    if (type === "cubicBezier") return `cubic-bezier(${v.join(",")})`;
    if (type === "number") return String(v);
    if (type === "fontFamily") return (Array.isArray(v) ? v : [v]).map(f => GENERIC.includes(f) || !/\s/.test(f) ? f : `"${f}"`).join(", ");
    if (type === "fontWeight") return String(num(v) ? v : WEIGHTS[v]);
    if (type === "shadow") return (Array.isArray(v) ? v : [v]).map(s => `${s.inset ? "inset " : ""}${D.css("dimension", s.offsetX)} ${D.css("dimension", s.offsetY)} ${D.css("dimension", s.blur)} ${D.css("dimension", s.spread)} ${D.css("color", s.color)}`).join(", ");
    if (type === "typography") return `${D.css("fontWeight", v.fontWeight)} ${D.css("dimension", v.fontSize)}/${v.lineHeight} ${D.css("fontFamily", v.fontFamily)}`;
    throw new Error("No CSS for type " + type);
  };
  D.weight = v => (num(v) ? v : WEIGHTS[v]);

  D.flat = res => Object.fromEntries([...res.values()].map(t => [t.path, D.css(t.type, t.value)]));
}
