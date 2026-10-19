# Bahaya Jerebu — Kem Bomba Rimba world review

Reviewed 18 October 2026. Existing Roblox world was inspected read-only; no map instances or gameplay scripts changed.

## Direction
Build a Malaysian forest-response expedition game: a welcoming kampung and BOMBA base, a forward forest camp, then risky routes into peat swamp and hill forest. Cooperation comes from carrying water, scouting smoke, rescuing residents, and maintaining access routes. Keep the seven-day haze crisis as the current round; add regions and objectives before lengthening it.
The reference is [99 Nights in the Forest by Grandma's Favourite Games](https://www.roblox.com/games/79546208627805/99-Nights-in-the-Forest), whose official description emphasizes building a camp with friends. Borrow that shared-home / expedition rhythm. The following proposed systems are our design, not claims about that game's internals. Use tropical trees, stilt architecture, water infrastructure, and haze instead of copying its monsters or pine-forest identity.

## Observed map facts
- Live `Workspace.Map`: Town 221 BaseParts; Forest 1,186; Refill 28; Airstrip 19, plus bridge and rails.
- 302 models tagged `Tree`; source defines 280 trees plus 22 peat patches. Most forest forms are cylinders and spherical crowns, with a palm variant.
- Ten similar stilt houses share one geometry; BOMBA at approximately (-40, -40), school at (110, 65), airstrip at (-120, 60), in Roblox X/Z coordinates.
- Source terrain is a 900 × 900 stud square. River spans east–west at Z=-130; one 14-stud-wide bridge crosses at X=0.
- Northeast peatland occupies roughly X=150..370, Z=-360..-180. Most major facilities cluster in the town; nine hydrants favor the center and four exit paths.
- `StreamingEnabled` is already true. This is useful groundwork, not evidence of multiplayer/mobile performance.
- Studio capture returned a blank viewport. Visual judgements here are based on measured geometry and construction code, not a claimed successful screenshot or walk-through.

## Priorities and placement proposal
1. **P0 — Make routes legible.** Keep the station spawn. Add a large route board outside it, colored/shape-coded trail posts, and a visible water-tower silhouette at each supply outpost. First objective should be visible from the station exit.
2. **P0 — Separate walking and vehicle circulation.** Preserve a clear 18–24 stud service-road corridor from station to bridge; test actual truck turning radius. The existing 14-stud bridge is a plausible congestion point for two crews. Add a pedestrian crossing before increasing player count; do not just decorate the choke point.
3. **P1 — Create forward camp at approximately (-75,-205), north of river and west of main path.** Clear a roughly 90 × 80 stud area selectively. Place pavilion, kiosk, water tank, and rescue shelter around a 30-stud gathering court. Keep a straight truck pull-through; no parked vehicles across the exits.
4. **P1 — Three distinct destination silhouettes.** Northeast peat swamp: dark stumps, low water and raised boardwalks. Northwest hill forest: tall buttress trees, lookout and switchback path. Southeast village fringe: palms, orchards and residents to protect. Put dense foliage in clusters, with clear fighting lanes between them.
5. **P1 — Loop routes, not dead ends.** Branch from camp toward peatland and lookout, then reconnect to river supplies. Offer one short hazardous route and one longer supply-rich route. Ensure every objective has two approach directions and space for 4 players to spray without body-blocking.
6. **P2 — Reserve expansion sockets.** Keep paths leaving the current west/north/east edges for later sectors. Each sector gets an arrival landmark, supply node, two objective clearings, return shortcut and extraction/rescue point. Build a new sector independently instead of making one enormous merged terrain mesh.

## Multiplayer plan (proposed targets, not tested limits)
- Start with 4–6 players per round. Test 8 only after fire synchronization, streaming and mobile performance measurements.
- Use soft roles: scout spots smoke; hose crew fights; driver hauls water; rescuer completes side objectives. Any player can switch roles; avoid a single required class blocking progress.
- Scale active incidents with crew size, with a cap and travel-time allowance. Keep API shared and rewards contribution-aware so scouting/resupply also pay.
- Give camp a shared upgrade track: reserve tank, radio/lookout, rescue shelter, then second supply route. Night reports show visible restoration progress and the next threatened district.
- Leave refuge and refill interactions server-authoritative. Keep critical interaction models available together under streaming, and handle missing streamed landmarks on clients.

## Authored Blender kit
`assets/world/kem-bomba-rimba/Kem_Bomba_Rimba.blend` contains a staged original kit, with 12 individually exported FBX and GLB modules in `exports/`:
command pavilion, water tower, supply kiosk, rescue shelter, 12 × 10 boardwalk, 12-unit rail, lookout with stairs, trail post, buttress tree, palm, peat stump, river rocks.
The intended look is simple low-poly forms, teal support structures, warm terracotta gables, pale trim, yellow safety accents, and readable tropical foliage. Blank signs deliberately accept editable Roblox SurfaceGui text later.
All 12 source meshes total **2,120 triangles** before importer material splitting. No external textures or third-party models; all geometry was authored procedurally for this request. Ground-center origins and dimensions are recorded in `manifest.json`. `build_kit.py` preserves the exact construction recipe.
The .blend is a kit presentation scene, not a replacement map. Its floor, camera, and light are not in individual exports.
`kit-preview.png` was rendered and visually reviewed. All 24 FBX/GLB exports were reimported in Blender: source triangle counts matched exactly, dimensions matched within 0.01 units, and bounds were finite. `validation.json` records results and SHA-256 hashes. `world-layout.svg` shows the proposed route and camp arrangement.

## Import handoff and required tests
- Import individual FBX files into a staging folder first. Confirm the boardwalk is 12 studs long and 10 wide; set import scale accordingly. Blender uses Z-up; FBX exports Y-up. Do not assume importer defaults match the intended scale.
- These are decorative shells: create simple invisible collision floors/ramps/walls in Studio. Avoid a single convex collision hull sealing the pavilion or lookout; disable collision on roof trim, leaves and decorative braces.
- The tree meshes do not carry Roblox `Tree` tags, `Peat`/`Ground` attributes, or `Trunk` PrimaryParts. Adapt them to the existing fire-target contract before replacing any current burnable tree.
- No working refill, shop, rescue, climb, or building mechanic is embedded in a mesh. Keep those server scripts and prompt anchors in native Roblox instances.
- Check FBX material/color preservation in Studio; the GLB copies preserve named flat materials as an interchange reference. No Roblox import or live collision test was performed.
- Test two trucks at bridge, four players on stairs, all entrances with R15/mobile controls, smoke visibility across each route, and streamed return to camp before rollout.
- Maintain the real API band meanings and the school closure rule. Haze must still communicate danger without concealing the immediate navigable path.

## Tool and verification limits
Blender 5.2 generated the new source and exports in a separate background session, preserving any user's interactive file. The game-dev CLI was unavailable, so its canonical-package validation was not run; these are reviewed source assets, not a certified game-ready package. No paid provider, live map replacement or publication was used.
