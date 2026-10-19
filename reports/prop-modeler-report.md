# Prop Modeler report (round 3)

## Built (Edit mode, nothing else touched)
`ServerStorage.Hoses` (Tools, parts incl. Handle) and `ServerStorage.Rides` (Models). Rebuild script: `build/07_props.lua`.

| Model | Parts | Look |
|---|---|---|
| Hose1 | 6 | red hose, brass nozzle, coil |
| Hose2 | 11 | polished brass, leather grip/wraps, gauge |
| Hose3 | 12 | chrome twin barrels, blue strap + mini tank |
| Hose4 | 10 | chunky yellow foam cannon, white foam tank on top |
| Hose5 | 14 | glowing blue gun, twin-tank backpack (+Z, behind the hand), neon hose |
| Hose6 | 13 | white/gold, cyan neon core in glass bulb, tiny cloud, cyan stripes |
| Bicycle | 29 | red city bike, wooden basket, lamp |
| Kapcai | 31 | red/white underbone moped (no brand), rear box, mirrors |
| Truck | 59 | red fire truck, cab with roof cannon + light bar, low bed "well", water tank, ladder, BOMBA name plates (SurfaceGui) |

## Contract checks (all via execute_luau, Edit + one playtest)
- Hoses: Tool RequiresHandle=true, CanBeDropped=false, `Handle` > `Nozzle` (0,0.15,-2.95; same muzzle as starter) > `Jet` + `Drops` (cloned, Enabled=false), no scripts, every other part WeldConstraint'd, Anchored=false / CanCollide=false / Massless=true. All <= 14 parts.
- Rides: PrimaryPart=`Body`, `Seat` attachment in PrimaryPart with world rotation identity (forward = -Z), truck also `Cannon` (0,5.0,-7.6). Parts: 29 / 31 / 59 (budgets 60 / 60 / 120).
- Playtest (lock "prop-modeler", cleared, play stopped, DebugCoins removed): BuyHose 2..6 all succeeded, equipped tool each time was the new model (Tier attr = n, parts match, HoseClient added by server). Hose6 equipped: Spray(pos,true) turned Jet.Enabled on; muzzle look direction matched character facing. BuyRide Bicycle/Kapcai and BuyPass Truck succeeded; Ride:FireServer for each mounted (RideModel in character, Riding attr set) and dismounted with "".
- Ground contact while mounted: Bicycle wheels bottom == floor (0.00 gap); Kapcai 0.2 below floor; Truck 0.2 below floor.

## Not verified
- Visuals: screen_capture returned a black frame (Studio window not visible), so no capture ids; proportions are checked numerically only. Please eyeball the models once (especially Hose5 backpack offset, truck cab/bed, kapcai rider fit).

## Notes / requests
- The server welds the model so Seat == player's HumanoidRootPart, which is always ~3 studs above the floor. A realistic tall truck would sink into the ground, so the truck is built as a low-slung "well" bed (floor ~0.15, walls to waist height, wheels outside the walls). If lead wants a taller truck, Progression would need to raise the root (e.g. Humanoid.HipHeight) while riding; no change needed for the current models.
- The tool name is "Hose<tier>" in ServerStorage; the server renames it to "Hose" in the backpack (observed), HoseClient present.
- No scripts were edited. `shared.PropLib` was used only as a temporary helper in Edit mode and cleared.
