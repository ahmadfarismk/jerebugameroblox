import { readdir } from "node:fs/promises";
const base = process.argv[2] || "http://127.0.0.1:5175";
const files = [
  "index.html",
  ...(await readdir(new URL("../dist/assets/", import.meta.url))).map(
    (f) => "assets/" + f,
  ),
];
let total = 0;
for (const path of files) {
  const r = await fetch(base + "/" + path, {
    headers: { "Accept-Encoding": "identity" },
  });
  if (!r.ok) throw Error(`${path}: ${r.status}`);
  const bytes = (await r.arrayBuffer()).byteLength;
  total += bytes;
  console.log(`${bytes}\t${path}`);
}
console.log(
  JSON.stringify({
    files: files.length,
    httpResponseBodyBytes: total,
    under5MB: total < 5_000_000,
    scope:
      "Every production file, including all optional runtime art; uncompressed HTTP response bodies. Excludes HTTP headers.",
  }),
);
