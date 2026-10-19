KEM BOMBA RIMBA — original modular kit for Bahaya Jerebu

Open Kem_Bomba_Rimba.blend in Blender. kit-preview.png shows the entire kit.
exports/ contains 12 individual FBX assets and 12 GLB copies, with origin at ground-center.
The Blender scene is a kit display, not a ready-to-replace world map.
build_kit.py rebuilds the complete kit with Blender 5.2; it writes the named files in this directory.
manifest.json records dimensions and source triangle counts (2,120 total).
validation.json records successful Blender reimport of all 24 exports, matching triangles and dimensions, plus SHA-256 hashes.
world-layout.svg is a map diagram showing existing facilities and proposed routes/camp.

START: import 05_Boardwalk_12x10.fbx into a staging folder in Studio and confirm 12 x 10 stud width/depth.
Then apply that scale consistently to the rest. Exports use Y-up. Materials are flat named colors; no texture dependencies.
Make simple native collision proxies. Do not let convex collision fill the interiors of shelters or towers.
Add native Roblox gameplay anchors, SurfaceGui signs, Tree tags and fire attributes separately as appropriate.
Current live world is unchanged. Nothing here was published or imported into Roblox.

See reports/world-design-report.md (from project root) for the measured map review and multiplayer expansion proposal.
Original geometry was authored for this project, with no third-party mesh/texture input.
Not validated through the unavailable game-dev CLI; Roblox import, avatar scale, collisions and mobile performance still require checks.
