# Jerebu roadmap — monetization, survival mode, multiplayer, bosses

Status today (18 Oct 2026): the 7-day "Krisis 7 Hari" round is complete with upgrades, hose tiers,
rides, passes, health drain and the tabbed shop. Everything below is a plan, not built yet.
Guiding rule throughout: **haze is a real health crisis.** Sell fun, speed and style, never safety.

---

## 1. Monetization, expanded

### 1.1 What's live (ids still 0 until you create them in the Creator Hub)
Game Passes: Godspeed 199, Infinite Tank 249, Bomba Truck 499, VIP 299, 2x Coins 149.
Products: coin packs 49/129/349, Call the Rain 79, Server Boost 99.

### 1.2 New revenue streams (in order of value vs effort)
| # | Stream | What it is | Price idea | Why it's healthy |
|---|---|---|---|---|
| 1 | **Starter Bomba Pack** (one-time product, first 3 days after joining) | Bicycle + N95 + 500 coins + exclusive red helmet skin | 99 R$ | Best first-purchase conversion on Roblox; everything in it is earnable for free |
| 2 | **Private servers** (Roblox VIP servers) | A server for a friend group or a **school class** | 100 R$ / month | Teachers and families will pay for a safe, private session; zero dev cost |
| 3 | **Cosmetic shop (rotating, coins + Robux)** | Hose skins (Batik, Wau Bulan, Ketupat, Merdeka, Hari Raya, Deepavali, CNY), helmet styles, spray colours, truck paint jobs, emotes, name-tag frames | 25–150 R$ each, some coin-only | Pure style; rotation (daily/weekly) drives return visits. Fixed stock you can see, **no loot boxes** |
| 4 | **Musim Pass (season pass, ~6 weeks)** | Free + premium tracks of 30 tiers earned with XP from fires, rescues, boss fights. Rewards: cosmetics, coins, a season badge | 349–399 R$ | Rewards playing, not paying; each season brings a new theme and a boss variant |
| 5 | **Camp decorations** (survival mode) | Styles for the shared camp: lanterns, murals, flags, stilt-house skins | 25–75 R$ | Shown to the whole server; social flex without power |
| 6 | **Premium Payouts** | Roblox pays you for Premium subscribers' play time automatically | free | Comes from retention, which the season pass and daily rotation improve |
| 7 | **Rewarded video ads** (if your experience is eligible) | Opt-in ad for +50% coins on the night report | — | Player chooses; check Roblox's current eligibility and age rules first |
| 8 | **Gifting** | Buy a pass or skin for a friend | same prices | Social, especially for co-op crews |

### 1.3 Survival-mode products (careful)
- **Second Wind** (revive yourself once per run when you pass out): **earnable** in runs AND
  sellable (49 R$, max 1 per run). Never let money fully remove the risk of passing out.
- **Camp Rebuild** (restore a destroyed camp building instantly): coins only, not Robux.

### 1.4 Rules we keep
- Masks, healing and the safe zone are **never** paywalled. The best free mask (N95) stays cheap.
- Paid random rewards: **no.** Roblox requires disclosed odds and some countries ban them.
- Use `PolicyService` before showing any paid random item or ad to a player.
- All prices shown in the shop before purchase; no "fake discount" timers.
- Kid audience: no pressure copy ("BUY NOW OR LOSE!"), no pay-gated co-op roles.

---

## 2. Health (built) — tuning notes
Haze drains HP outside during the Day: Unhealthy 0.4/s, Very Unhealthy 1.0/s, Hazardous 2.0/s,
reduced by haze resist (masks + Strong Lungs; an N95 cuts it by 70%). Inside the BOMBA station: +8 HP/s.
Clean air (Good/Moderate): +1 HP/s. At 0 HP you **pass out** and respawn at the station (5 s).
Roblox's default auto-regen is disabled. Numbers live in `Config.Health`.
Next: a "breath" vignette at low HP, a heartbeat sound, and a teammate **carry/revive** (multiplayer).

---

## 3. Game modes

### 3.1 Krisis 7 Hari (current, story mode) — keep it
Short, finishable, three endings. The tutorial and the main "first session" experience.

### 3.2 Hari demi Hari — survival mode (inspired by the "99 Nights" rhythm, our own design)
Survive the haze season day by day with your crew until everyone passes out.
- **Endless days**, each harder: more fires, stronger wind, more peat, transboundary haze rising.
  Milestones every 10 days (badges + rewards). Leaderboard: **most days survived** (solo / squad).
- **Run ends** when the whole crew is passed out at once, or when the API stays Hazardous for a
  full day ("the town is evacuated"). A passed-out player respawns at camp after a timer that grows each day,
  or instantly if a teammate revives them (spray-revive / carry to station).
- **Shared camp** (the expedition base, matching Codex's forward-camp plan): crew spends a shared
  "Camp Fund" (a slice of every fire's coins) on water tower, lookout (shows fires further in haze),
  rescue shelter (faster revives), firebreak building (stops spread in a sector), second truck bay.
  Camp resets each run, so every run has its own build path.
- **Night phase** (short, 60 s): darkness + embers drifting on the wind start new fires near camp;
  players defend the camp. Sleep at camp to skip ahead once everyone is inside.
- **Events per day** (one random): wind shift, dry lightning, villager rescue, hydrant broken,
  cloud seeding available, mini boss (see 5).
- **Progression carry-over**: upgrades, hoses, rides and cosmetics carry over from the 7-day mode.
  The camp and the run do not.

---

## 4. Multiplayer plan
| Area | Plan |
|---|---|
| Server size | 4–6 per round at launch, test 8 after performance checks (fires, streaming, phones) |
| Structure | **Lobby place** (mode select, shop, cosmetics, party up) → **TeleportService reserved server** per run. Friends teleport together as a party. Private servers for schools |
| Late join | Allowed in Day 1–2 of 7-day mode; survival mode lets players join a crew between days |
| Roles (soft) | Hose crew, Scout (spots smoke, marks fires for everyone), Driver (truck, water hauling), Medic (revives, carries). Anyone can do anything; roles just give bonus XP and coins for that action |
| Rewards | Contribution-based (already for fires). Add pay for scouting marks, refilling teammates, revives, camp building, so non-sprayers earn too |
| Scaling | Fires per day +50% per extra player (built). Bosses scale HP with crew size. MaxFires scales from 22 up to 34 at 6 players |
| Shared state | API, camp, boss HP are server-owned. Clients only send intents (spray at, ride, buy) |
| Saves | Move to **session locking** (e.g. a ProfileStore-style library) before multi-server launch, so a player can't be loaded in two servers at once and lose progress |
| Anti-grief | Spraying players gives a harmless push + funny splash (fun, not damage). No friendly fire. Kick-vote for AFK in survival |
| Communication | Ping wheel (Fire here / Need water / Revive me / Follow me), quick chat, optional voice per Roblox rules |
| Performance | StreamingEnabled (on), persistent key models, fire visuals culled by distance, sectors loaded as folders |

---

## 5. Bosses
All bosses are **personified fire and haze**, not people or countries. The lesson stays: haze comes
from fires and is beaten by teamwork, prevention and rain.

### 5.1 Mini bosses (appear as a day event; 1–3 players)
| Boss | Behaviour | How to beat it | Reward |
|---|---|---|---|
| **Bara Gergasi** (Giant Ember) | A walking ember creature that leaves burning ground and lights trees it passes | Spray it from 2 sides; its core cools in stages; slows in clean air | Coins + "Ember" hose skin piece |
| **Pusaran Api** (Fire Whirl) | A tornado of flame pushed by the wind arrow; doubles spread along its path | Get ahead of it (read the wind), spray it until it collapses; the truck cannon is strong here | Coins + trail cosmetic |
| **Ratu Gambut** (Peat Queen) | Burrows under the peat swamp; pops up at peat vents, smoulders them, re-ignites soaked ones | Soak every vent before she surfaces; Foam Cannon shines | Coins + peat badge |

### 5.2 Big boss — **Sang Jerebu** (the Haze Titan)
Appears over the peat swamp on **Day 7** of the story mode and every **10th day** in survival.
A huge smoke giant with glowing ember hearts; the whole server fights together.
1. **Phase 1, Smog Wall:** API jumps one band; visibility drops; it spits ember balls that start
   fires around the map. Crew splits: some fight fires, scouts find its **3 ember hearts**.
2. **Phase 2, Hearts:** each heart sits in a different sector guarded by burning ground; spray each
   heart to zero (HP scales with crew). Every heart destroyed clears some haze.
3. **Phase 3, Rain finale:** the seeding plane unlocks for free; half the crew loads flares at the
   airstrip (co-op hold), rain falls, Sang Jerebu shrinks, everyone hoses its core.
- Fail state: if the API hits 400 during the fight, the town evacuates (bad ending / run ends).
- Rewards: boss badge, exclusive cosmetic (e.g. "Pemadam Jerebu" golden helmet), big coin payout,
  season-pass XP. Telegraphed attacks, no instant kills; the danger is mostly haze + fires.
- Tech: server state machine (phases, shared HP, scaling), client-only VFX (smoke giant built from
  particle volumes + a simple mesh body), ember projectiles as server-spawned fires.

---

## 6. Build order
| Phase | Scope | Who |
|---|---|---|
| **0 — now** | Polish 7-day mode: remaining tester polish (Hose5 backpack offset, hotbar vs shop banner, haze readability of hose tiers), create real pass/product ids, enable DataStore API in Game Settings and test saves, publish | lead + you |
| **1 — multiplayer hardening** | Session-locked saves, lobby place + teleport, party, ping wheel, contribution rewards for scouting/refills, MaxFires scaling, 2–4 player playtests | lead (server), ui-designer (lobby/ping), game-tester |
| **2 — map expansion** | Codex: forward camp + first new sector per `design/MAP_CONTRACT.md`; prop-modeler: camp buildings from the Blender kit; first mini boss (Bara Gergasi) | Codex, prop-modeler, vfx-designer, lead |
| **3 — survival mode** | Hari demi Hari loop, camp fund + buildings, night phase, revive/carry, leaderboards, Second Wind | lead, ui-designer, economy-balancer, game-tester |
| **4 — Sang Jerebu + season 1** | Big boss, other mini bosses, Musim Pass season 1, cosmetic rotation, Starter Pack | all agents |

Each phase ends with a full game-tester pass and an economy-balancer check before publishing.
