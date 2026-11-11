// Erzeugt web/svf-places.js: mitgelieferte Beispielgebiete für web/svf.html.
// Lädt je Gebiet die OSM-Daten (OSM-API, über curl) und wandelt sie mit demselben
// Code um, den die Seite für live geladene Orte benutzt (Abschnitt <osm-core> in svf.html).
//
//   node tools/bundle-svf-places.js [cache-verzeichnis]
//
// Daten © OpenStreetMap-Mitwirkende, ODbL 1.0 (https://www.openstreetmap.org/copyright)
"use strict";
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");

const HALF = 300;   // m: jedes Gebiet ist 600 m × 600 m groß
const PLACES = [
  ["Essen, Innenstadt", 51.4564, 7.0111],
  ["Köln, Altstadt und Dom", 50.9395, 6.9590],
  ["Frankfurt, Bankenviertel", 50.1115, 8.6735],
  ["Barcelona, Eixample", 41.3915, 2.1650],
  ["New York, Midtown", 40.7490, -73.9850]
];

const root = path.join(__dirname, ".."), cache = process.argv[2] || path.join(root, "tools", ".osm-cache");
const html = fs.readFileSync(path.join(root, "web", "svf.html"), "utf8");
const core = /\/\* <osm-core> \*\/([\s\S]*?)\/\* <\/osm-core> \*\//.exec(html);
if (!core) throw new Error("Abschnitt <osm-core> in web/svf.html nicht gefunden");
const { parseOsm } = new Function(core[1] + "\nreturn { parseOsm };")();

fs.mkdirSync(cache, { recursive: true });
const out = [];
for (const [name, lat, lon] of PLACES) {
  const file = path.join(cache, name.replace(/[^a-z0-9]+/gi, "_") + ".json");
  if (!fs.existsSync(file)) {
    const dLat = HALF / 110540, dLon = HALF / (111320 * Math.cos(lat * Math.PI / 180));
    const bbox = [lon - dLon, lat - dLat, lon + dLon, lat + dLat].map(v => v.toFixed(6)).join(",");
    execFileSync("curl", ["-sS", "-f", "-m", "120", "-A", "svf-places-bundler/1.0", "-o", file,
      `https://api.openstreetmap.org/api/0.6/map.json?bbox=${bbox}`], { stdio: "inherit" });
  }
  const b = parseOsm(JSON.parse(fs.readFileSync(file, "utf8")).elements, lat, lon, HALF);
  // kompakt: [Teil, Höhe, Herkunft, Ring, Ring, ...], Koordinaten in Dezimetern
  out.push({ name, lat, lon, half: HALF, b: b.map(x => [x.p, x.h, x.s, ...x.r.map(r => r.map(v => Math.round(v * 10)))]) });
  console.log(name, b.length, "Gebäude");
}
const date = new Date().toISOString().slice(0, 10);
fs.writeFileSync(path.join(root, "web", "svf-places.js"),
  `// Beispielgebiete für svf.html, erzeugt von tools/bundle-svf-places.js am ${date}.\n` +
  `// Gebäudegrundrisse © OpenStreetMap-Mitwirkende, ODbL 1.0 (https://www.openstreetmap.org/copyright)\n` +
  `window.SVF_PLACES = ${JSON.stringify(out)};\n`);
