# Map contract — read this before changing `Workspace.Map`

For Codex (or anyone) reworking or expanding the map. The game scripts find map pieces **by name,
tag and attribute**. Move, restyle or replace anything you like, as long as these stay true.
If you must rename or remove one, tell the lead first so the scripts can change in the same step.

## Required instances (scripts index these by exact path)
| Path | Used by | Rules |
|---|---|---|
| `Workspace.Map` (Folder) | everything | Keep the name. |
| `Map.Town.FireStation` (Model) | server | Its **bounding box is the safe zone**: inside it players heal 8 HP/s and take no haze damage. Keep it an enclosed-feeling building roughly 40×30 studs; a bigger box = a bigger safe zone. |
| `Map.Town.FireStation.ShopCounter` (BasePart) with child `ShopPrompt` (ProximityPrompt) | server → opens shop | `RequiresLineOfSight = false`. Keep it reachable from the spawn. |
| `Map.Town.FireStation.Spawn` (SpawnLocation) | Roblox spawn | Face it out of the door (the join camera looks the way the spawn faces). |
| `Map.Town.School.FieldClosed` (Model) with `Tape` parts and `ClosedSign` (Part with `SurfaceGui`) | server | Toggled at API > 100 (real Malaysian rule). Parts start `Transparency = 1`. |
| `Map.Airstrip.SeedPad` (Part) with `SeedPrompt` (ProximityPrompt) | server, HUD waypoint | Cloud seeding loads here. |
| `Map.Airstrip.SeedingPlane` (Model, PrimaryPart set, wingspan along its local X) | server | Flies from its starting pivot. Needs ~250 studs of clear air ahead of its nose. |

## Tags and attributes
**Burnable trees:** any `Model` tagged **`Tree`** with:
- `PrimaryPart` = the trunk (named `Trunk`).
- Attribute **`Ground`** (number) = ground height Y at the trunk.
- Attribute **`Peat`** (bool) = true for peat-swamp fuel (burns low, smoulders, must be soaked).
- Fire spreads between trees within **34 studs** of each other, so tree spacing sets spread speed.
  Dense clusters burn fast; keep clear lanes for players and trucks.
- Fires are read once when the server starts. New trees need a server restart to be burnable.

**Refill zones:** any `BasePart` tagged **`Refill`** with attribute **`Rate`** (water/sec; river 30,
hydrant 40). Invisible, `CanCollide = false`, `CanQuery = false`. Players refill while inside the
box (+4 studs height). The truck also refills there.

## Coordinates the code assumes
- **Town centre = world origin (0, 0, 0).** Early days only spawn fires within 320 / 360 / 420 / 520
  studs of the origin (days 1–4). If the town moves, tell the lead to move that origin.
- Peat swamp ≈ X 150–370, Z −360 to −180 (≈375 studs out), so peat first burns on Day 3.
  Moving the swamp closer makes peat appear earlier.
- Players walk 18–27 studs/s (upgrades), Bicycle 32, Kapcai 48, Truck 40. A 4-minute day ≈ 4,300 studs
  of walking at base speed. Keep objectives within ~450 studs of a refill point.

## Expansion rules (multiplayer-ready)
- Build each new region as its own folder under `Map.Sectors.<Name>` with: arrival landmark,
  at least one `Refill` zone, burnable `Tree` models, and two approaches (no dead ends).
- Truck routes: keep ≥ 18-stud-wide drivable paths between town, camp and each sector; bridges ≥ 18
  studs (the current 14-stud bridge is a choke point for two trucks).
- Rides attach at hip height and don't collide, so keep slopes gentle (< 35°) on main routes.
- `StreamingEnabled` is on. Keep the station, refill zones and seed pad in persistent models
  (`ModelStreamingMode = Persistent`) so they are never streamed out.
- Performance: max 22 fires at once (scales later). Avoid > 2,000 new parts per sector; prefer meshes
  for decoration with collision off.
- Don't use the official JBPM/BOMBA emblem. Generic red + the word "BOMBA" is fine.

## Things that are safe to change freely
House layout, roads, terrain shape (keep the river crossable), decoration, lighting props, the
Blender kit from `assets/world/kem-bomba-rimba/`, signs, colours. Haze visuals are client-side and
don't depend on map parts.
