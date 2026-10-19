# Jerebu — Shop items, upgrades & image prompts

Two parts: **(A) the item list** (what to build) and **(B) ChatGPT image prompts** (what to generate).
Prices are starting points; the game tester should tune them after a full 7-day run.

---

# A. Item list

## A1. Why walking feels bad (and what fixes it)
QA measured walking at ~70% of a played day. Stat upgrades help, but the biggest win is **giving players
faster ways to move** that they earn early. So the plan has three layers:

1. **Upgrade tracks** (coins, many small levels) — the "always something to save for" grind.
2. **Hose tiers** (coins, big milestones) — each tier is a new, fancier model you can see.
3. **Rides** (coins early, Robux premium) — bicycle → kapcai → fire truck, so distance stops being a chore.

## A2. Upgrade tracks (earned with coins, permanent, saved)
Each track has 10 levels. Cost grows ~1.45× per level. Effects are per level, capped at Lv10.

| Track | Shop name (EN · BM) | What it does | Lv1 → Lv10 | Lv2 cost → Lv10 cost |
|---|---|---|---|---|
| Run speed | Kasut Bomba · Bomba Boots | Walk speed | 18 → 27 | 40 → 830 |
| Put-out speed | Tekanan Air · Water Pressure | Fire damage per second | ×1.0 → ×2.2 | 50 → 1,040 |
| Water tank | Tangki Air · Water Tank | Max water | 100 → 550 | 40 → 830 |
| Spray range | Muncung Jauh · Long Nozzle | Hose range (studs) | 40 → 70 | 45 → 930 |
| Refill speed | Pam Laju · Fast Pump | Refill rate at hydrant/river | ×1.0 → ×3.0 | 30 → 620 |
| Haze lungs | Paru-paru Kuat · Strong Lungs | Less slowdown + fewer coughs above API 100 | 0% → 60% resist | 35 → 720 |

*These replace the current 3-level Tank and Nozzle items.*

## A3. Hose tiers (coins, each one a new model)
Tiers multiply the stats from the tracks and change the look + spray effect.

| Tier | Name | Look (for the model + icon) | Bonus | Price |
|---|---|---|---|---|
| 1 | Hos Asas · Starter Hose | Red hose, plain brass nozzle | — | free |
| 2 | Muncung Tembaga · Brass Jet | Polished brass nozzle, leather grip, pressure gauge | +15% power | 300 |
| 3 | Jet Berkembar · Twin Jet | Two parallel barrels, chrome, blue tank strap | +30% power, wider spray | 900 |
| 4 | Meriam Busa · Foam Cannon | Chunky yellow cannon, white foam tank on top | +45% power, **peat soaks 2× faster** | 2,200 |
| 5 | Ransel Hidro · Hydro Pack | Backpack water tank + glowing blue hose & gun | +60% power, +50% tank | 4,500 |
| 6 | Meriam Ribut · Storm Cannon (legendary) | Sleek white/gold cannon, glowing cyan core, tiny storm cloud inside | +80% power, spray puts out fires in a small cone | 9,000 |

## A4. Gear
| Item | Name | Effect | Price |
|---|---|---|---|
| Mask T1 | Pelitup Kain · Cloth Mask | 25% haze resist | 30 |
| Mask T2 | Pelitup Perubatan · Surgical Mask | 45% haze resist | 80 |
| Mask T3 | N95 | 70% resist, no coughing | 160 |
| Mask T4 | Respirator · Alat Pernafasan | 90% resist, no slowdown | 400 |
| Helmet | Topi Bomba · Fire Helmet | Cosmetic (colour variants) | 50–200 |

*Real-world note in the description:* "In real haze, an N95 is what protects you. Cloth masks don't filter PM2.5."

## A5. Rides (fixes the walking problem directly)
| Ride | Name | Speed | Notes | Price |
|---|---|---|---|---|
| Bicycle | Basikal | 32 | Spawns at the station rack, ride anywhere | 250 coins |
| Kapcai | Motosikal Kapcai | 48 | Classic Malaysian underbone bike (generic, no brand); carries 1 passenger | 1,500 coins |
| Fire truck | Trak Bomba | 40 | Premium — see A6 | Robux |

Rides can't spray; hop off to fight (except the truck).

## A6. Premium (Robux) — permanent Game Passes

| Pass | What you asked for | How I'd balance it | Suggested price |
|---|---|---|---|
| **Godspeed · Laju Kilat** | Godspeed running | Walk speed ×1.5 on top of boots (≈40 max), golden speed trail, ignores haze slowdown | 199 R$ |
| **Infinite Tank · Tangki Tanpa Had** | Unlimited water | Never runs out of water. Fires still take time to put out | 249 R$ |
| **Bomba Fire Truck · Trak Bomba** | Truck that wipes fires nearby | Drivable truck with a roof water cannon. Fires within 30 studs lose intensity very fast (~80/s), so small fires vanish almost instantly. Stays on roads/paths/flat ground; needs a 20 s refill at a hydrant after ~45 s of spraying. **Peat only goes to smouldering**; you still soak it on foot. Up to 3 friends can ride on the back | 499 R$ |
| **VIP Bomba** | — | 2× coins, gold helmet, VIP chat tag | 299 R$ |
| **2× Coins** | — | Doubles coin earnings | 149 R$ |

### Developer products (one-time buys, can repeat)
| Product | Effect | Price |
|---|---|---|
| Coin packs | 500 / 1,500 / 5,000 coins | 49 / 129 / 349 R$ |
| **Panggil Hujan · Call the Rain** | Starts cloud seeding for the **whole server** right now (once per day) | 79 R$ |
| **Server Boost** | Everyone gets +25% speed & put-out power for 10 minutes | 99 R$ |

### Why I changed the truck from "instant wipe"
The game is co-op with **one shared API meter**. If one buyer's truck deletes every fire instantly,
everyone else has nothing to do and the 7-day tension disappears. That makes free players leave, and then the server is empty for the buyer too.
The version above still *feels* like an instant wipe on normal fires, but keeps peat, refills and roads as limits.
**Call the Rain** and **Server Boost** are the healthiest earners: the buyer becomes the hero of the whole server.

### Tone guardrails (haze is a real crisis)
- Sell **convenience and cosmetics**. Never sell a mask that's the *only* way to survive. The free N95 tier must stay reachable with coins.
- No loot boxes / random paid rewards (Roblox requires odds disclosure; it also doesn't fit the theme).
- Don't use the official **JBPM / BOMBA emblem or uniforms** in assets. Use generic red trucks with the word "BOMBA" only, so it's not mistaken for the real agency.

---

# B. ChatGPT image prompts

## B0. How to use
1. Open **one** ChatGPT chat for all images so the style stays consistent.
2. Paste the **Style Block** first, then send each item prompt one by one.
3. After the first good icon, say *"Use this exact style for every next image."*
4. Download PNGs. If the background isn't transparent, ask: *"Same image, transparent background."*
5. Upload to Roblox (Creator Hub → Development Items → Images, or the Asset Manager in Studio), then paste the asset IDs back to me to wire into the shop.

## B1. Style Block (paste this first)
```
You are making game icons for a Roblox game called "Jerebu: 7 Days of Haze" — a cheerful,
kid-friendly co-op firefighting game set in a Malaysian kampung and rainforest.

Style rules for EVERY image:
- Cartoon 3D-rendered look, chunky rounded shapes, soft studio lighting, glossy highlights.
- Thick dark outline around the object (deep purple #5B3D7D), like a mobile-game sticker icon.
- Bright, saturated colours. Main UI colours of the game are purple (#A06CC6) and green (#45C653).
- One object, centred, filling ~80% of the frame, slight 3/4 angle.
- Transparent background (PNG). No text, no letters, no numbers, no logos, no watermark.
- Square 1024x1024.
- No real brands, no official government emblems.
Reply "ready" and wait for my item prompts.
```

## B2. Upgrade track icons
1. **Bomba Boots** — `Icon: a pair of chunky red-and-yellow firefighter boots with reflective stripes and little white speed lines / wind swooshes behind them.`
2. **Water Pressure** — `Icon: a round brass pressure gauge with the needle pushed into the red zone, a burst of blue water spraying out from behind it.`
3. **Water Tank** — `Icon: a rounded blue water tank / canister with a big droplet symbol embossed on it (a shape, not text), water sloshing at the top.`
4. **Long Nozzle** — `Icon: a long brass hose nozzle shooting a long straight stream of blue water with a small target circle at the end of the stream.`
5. **Fast Pump** — `Icon: a red fire hydrant with water gushing out fast from its side, plus small motion swirls.`
6. **Strong Lungs** — `Icon: a cute pair of pink cartoon lungs with a small green leaf and a soft sparkle, clean fresh-air swirls around them.`

## B3. Hose tier icons (also used as reference for the 3D models)
1. **Starter Hose** — `Icon: a coiled red fire hose with a plain brass nozzle.`
2. **Brass Jet** — `Icon: a polished shiny brass hose nozzle with a brown leather grip and a small round pressure gauge on top.`
3. **Twin Jet** — `Icon: a chrome water gun with two parallel barrels, a blue strap, water spraying from both barrels.`
4. **Foam Cannon** — `Icon: a chunky yellow handheld foam cannon with a white tank on top, fluffy white foam bursting from the barrel.`
5. **Hydro Pack** — `Icon: a firefighter backpack water tank (blue, rounded) connected by a glowing blue hose to a sleek blue water gun.`
6. **Storm Cannon (legendary)** — `Icon: a sleek white-and-gold futuristic water cannon with a glowing cyan core where a tiny swirling storm cloud with mini lightning lives; legendary glow aura behind it.`

## B4. Gear icons
1. **Cloth Mask** — `Icon: a simple pastel cloth face mask with a soft fabric texture and ear loops.`
2. **Surgical Mask** — `Icon: a light-blue pleated surgical face mask with white ear loops.`
3. **N95** — `Icon: a white N95 cup-shaped respirator mask with a small valve and two straps.`
4. **Respirator** — `Icon: a chunky half-face respirator with two round filter cartridges, grey and orange.`
5. **Fire Helmet** — `Icon: a classic red firefighter helmet with a long back brim and a blank gold shield badge on the front (no symbols on the shield).`

## B5. Rides
1. **Bicycle** — `Icon: a cute red city bicycle with a front basket holding a small water bottle.`
2. **Kapcai** — `Icon: a small classic Southeast Asian underbone motorcycle (generic, no brand), red and white, with a small box on the back.`
3. **Fire Truck** — `Icon: a chunky cartoon red fire truck with a water cannon on the roof spraying blue water, a ladder on top, the word-free side panel, front 3/4 view.`

## B6. Premium icons (make these feel special)
Add to each: `Premium look: gold rim glow and small sparkles behind the object.`
1. **Godspeed** — `Icon: a golden winged firefighter boot with a lightning bolt trail.`
2. **Infinite Tank** — `Icon: a glowing blue water tank with an infinity-loop shape made of flowing water wrapped around it.`
3. **Bomba Fire Truck** — reuse B5.3 + premium look.
4. **VIP Bomba** — `Icon: a shiny gold firefighter helmet with a sparkle and a small crown shape on top.`
5. **2× Coins** — `Icon: two stacked gold coins (blank faces, no symbols) with a bright upward arrow made of light.`
6. **Coin packs (3 sizes)** — `Icon: a small / medium / large pile of shiny gold coins (blank faces).` (send 3 times: small pile, sack of coins, treasure chest overflowing with coins)
7. **Call the Rain** — `Icon: a small white propeller plane flying above a fluffy grey rain cloud, blue raindrops falling.`
8. **Server Boost** — `Icon: a glowing green-and-purple rocket badge with upward arrows, energetic sparkles.`

## B7. Other game assets (to replace emojis and improve the look)
**Currency & HUD (use 512x512, transparent):**
1. **Coin (game currency)** — `Icon: one shiny gold coin with a small water-droplet shape stamped in the middle (no letters).`  *(replaces 💰)*
2. **Water droplet** — `Icon: a glossy blue water droplet with a white shine.`  *(water bar)*
3. **Fire marker** — `Icon: a bright orange cartoon flame inside a round red badge.`  *(fire markers)*
4. **Smouldering peat marker** — `Icon: a dark brown round badge with glowing orange embers and a thin wisp of grey smoke rising.`
5. **Hydrant marker** — `Icon: a small red fire hydrant inside a round blue badge.`
6. **Cloud seeding marker** — `Icon: a white cloud with blue raindrops inside a round blue badge.`
7. **Mask warning** — `Icon: a yellow warning triangle with a simple face-mask shape inside (no text).`
8. **Wind arrow** — `Icon: a stylised curved white wind swoosh ending in an arrow, light blue outline.`

**API band faces (5 images, 512x512) — for the API card:**
`Icon: a round cartoon sky badge with a face — [variant].` Send 5 variants:
- Good: bright blue sky, big happy sun face.
- Moderate: light grey-green sky, calm sun face.
- Unhealthy: yellow hazy sky, sun face wearing a mask, slightly worried.
- Very Unhealthy: orange-brown smog, sun face coughing behind a mask.
- Hazardous: dark red-brown smog, barely visible sun with closed sad eyes.

**Badges (Roblox badges, 512x512, round):**
`Round achievement badge, purple rim with green ribbon, centred symbol — [variant].`
- First Fire Out: a hose spraying a small flame.
- Peat Hunter: a soaked peat patch with a check-mark shape.
- Clear Skies: blue sky with sun and clouds.
- Cloud Seeder: plane and rain cloud.
- 7 Days Survived: a calendar page with 7 small stars (no numbers).
- Full Squad: four firefighter helmets together.

**Game icon (Roblox experience icon, 512x512, NOT transparent):**
```
Square game icon. A cheerful cartoon Malaysian kid firefighter in a red helmet and white N95 mask,
spraying water at a forest fire, with a hazy orange sky on one half and a clean blue sky on the
other half, palm and rainforest trees, purple and green accents, thick outlines, bold and readable
at small size. No text.
```

**Thumbnails (Roblox store, 1920x1080, NOT transparent) — make 3:**
1. `Wide cartoon scene: a kampung house on stilts and a red fire station in front of a rainforest; three kid firefighters spraying fires on the tree line; orange haze rolling in; dramatic and fun. No text.`
2. `Wide cartoon scene: a small white propeller plane flying over a hazy forest, rain falling and putting out fires, sky clearing from orange to blue where the rain falls. No text.`
3. `Wide cartoon scene: a red fire truck on a dirt road blasting a water cannon at burning trees, kids riding on the back cheering. No text.`
*(Add the "JEREBU" title in Studio or an editor afterwards. AI image text is often misspelled.)*

**Loading screen / menu background (1920x1080):**
`Soft-focus cartoon panorama of a Malaysian kampung by a rainforest at sunrise, gentle haze on the horizon, calm and hopeful mood, empty space in the centre for a logo. No text.`

**How-to-play illustrations (5 images, 768x768, transparent):**
1. A kid firefighter looking through binoculars at smoke over trees.
2. A kid firefighter holding a hose and spraying a flame.
3. A kid firefighter refilling a tank at a red hydrant.
4. A kid firefighter soaking a smouldering ground patch until steam rises.
5. A kid firefighter putting on a white N95 mask.

---

## C. After the images: what I'll build
When you send the asset IDs:
1. **Server:** upgrade tracks + hose tiers + rides in Config, saved in the DataStore. Game Pass / Developer Product checks via MarketplaceService (Studio uses test purchases).
2. **UI designer:** new tabbed shop (Upgrades · Hoses · Gear · Rides · Premium) in the purple/green kit, using your icons.
3. **VFX designer:** the 6 hose models + per-tier spray effects, the bicycle/kapcai/truck, the truck's water cannon.
4. **Game tester:** re-balance the 7 days with upgrades in play, so maxed players aren't bored and new players still help.

You'll need to create the Game Passes and Developer Products yourself in the Creator Hub (it needs your account) and send me their IDs.
