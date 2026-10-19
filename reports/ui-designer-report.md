# UI Designer report: Jerebu (2026-10-17)

## Status: code written, NOT in Studio yet, NOT playtested
Roblox Studio lost its connection after I read the scripts. At ~01:15, `list_roblox_studios` started
returning nothing, and `RobloxStudioBeta.exe` is no longer running. Only `RobloxPlayerBeta` and
`RobloxCrashHandler` are left, so Studio probably crashed. I waited about 10 minutes and it did not
come back. I did not relaunch Studio or reopen the place, because that could clash with the VFX
agent's unsaved work or with Studio's crash recovery.
**Nothing in the place was changed by me.** I never set the playtest lock, so there is none to clear.

The finished code is saved here, ready to paste:
- `reports/ui-designer-src/UIStyle.lua` → new ModuleScript `ReplicatedStorage.Jerebu.UIStyle`
- `reports/ui-designer-src/HUD.lua` → replaces all of `StarterPlayer.StarterPlayerScripts.HUD`

These sources were checked by reading only. Nobody has compiled or run them yet.

## What the code does (priorities 1–6, all written)
1. **HUD restyle (compact):** the API card is a white kit card with a purple outline. The band
   colour fills a chip behind the big API number, so it is still the strongest colour on the card.
   The band name and BM name sit in ink text beside it. The gauge has a purple outline. When the band
   is 4 or higher, the outline pulses in the band colour. The day pill is now a green banner, with the
   timer in a purple box that turns red at ≤30 s. Coins use a white card. Water uses a white card with
   an outlined blue fill bar. Toasts are kit pills: a gradient per kind, a dark outline and a Back-ease
   pop. The seed banner is blue kit style with a pulsing outline. The seed waypoint billboard is
   unchanged.
2. **Main menu** (opens on join): a JEREBU banner on posts, the bilingual subtitle, a live status line
   (countdown, current day or night), PLAY / DAYS / HOW TO PLAY, and rotating tips. PLAY closes it.
   The ☰ purple button next to the coins reopens it. It closes on its own when Intermission turns into
   Day, and reopens when a new run starts after Ended.
3. **DAYS board:** 7 kit day tiles. Each has a purple body, a white window, 3 stars and a green
   "DAY n" strip. DAY 7 is wide. Landscape uses 4+3 tiles and portrait uses 3+3+1. Stars come from
   `Report` on the client: 3★ clean, 2★ apiAfter ≤ 100, 1★ ≤ 200, 0★ otherwise. Tile states:
   done / now (green window) / missed (joined late, grey number) / locked 🔒. Shows a "⭐ x / 21"
   total and a legend. Resets when `Day` goes back to 0.
4. **Night report:** banner "Malam n · Night n". Stars pop in one at a time with clicks. Below them:
   stats, an "API tonight" chip in the band colour, and a tip box. It still closes after ReportLength-1.
   **Ending:** the ending name is on the banner. Chart bars keep the band colours and get a purple
   outline. Also shows the run's star total, the stats and the MyJAS/APIMS footer.
5. **Shop:** banner "KEDAI · GEAR" with a ✕. Items are purple rows with a white icon window and a green
   price button. Owned items are greyed out with `UIStyle.SetEnabled`. Purchase messages are green on
   success and orange on failure.
6. **How to play:** banner "HOW TO PLAY · CARA BERMAIN" over 5 numbered steps with emoji (🔥 🧯 💧 ♨️ 😷).
   Each step title is bilingual.

Feel: every kit button gets a UIScale tween (hover 1.04, press 0.96, 0.08 s) and the `Sounds.Click`
sound. While pressed, the gradient darkens and the label and gloss move down 3 px. Modals pop in with
a Back tween. DAYS and HOW TO PLAY go back to the menu when closed with ✕.

## UIStyle API
Tokens: `Colors.*` (Outline, Purple*/Green* top, bottom and pressed, Wood, Gold, StarEmpty, Number, Ink,
InkSoft, Tint, PanelLow) and `Font` (FredokaOne).
Builders: `New, Corner, Pad, Stroke, TextStroke, Gradient, Gloss, Text, Panel, Card, Button,
PurpleButton, GreenButton, SetEnabled, CloseButton, GreenBanner, Posts, Stars, SetStars, DayTile,
SetDayTile, AttachFeel, PlayClick, Modal`. `Modal(parent, {name,title,width,height,close?,titleSize?})`
returns `{Shade, Root, Panel, Banner, Title, CloseButton, SetSize, Open, Close, IsOpen, Refit, OnClose}`.

## Mobile (reasoned, not tested on a device)
- The HUD sits in `JerebuHUD` with one UIScale. Landscape uses min(X/760, Y/500). Portrait uses X/420,
  and the day banner moves under the coins while the coins and API card get narrower.
- At 667×375 landscape the scale is 0.75, so the 50 px menu button is about 37 px. That is below 44 px.
  This needs a fix (for example a minimum of 60 px design size on phones) once it can be tested.
- At 375×667 portrait the scale is 0.89, so the menu button is about 45 px.
- Modals sit in a separate `JerebuMenus` ScreenGui. Each one scales itself to fit the screen with
  16 px margins. The main menu is about 0.89 in landscape, so its 58 px buttons come out around 51 px.

## Not done or not verified
- Not inserted into Studio, not playtested, no `screen_capture` images, no LogService error check.
  None of the steps in the role file's "Verify" section has been run.
- Two glyphs might not render in FredokaOne and would fall back to another font: `★` and `☰`. If either
  looks wrong, swap it for an emoji or an ImageLabel.

## To finish (next agent or me, once Studio is back)
1. Create `ReplicatedStorage.Jerebu.UIStyle` (ModuleScript) from UIStyle.lua. Replace the source of
   `StarterPlayerScripts.HUD` with HUD.lua.
2. Take the playtest lock and run play. Check `PlayerGui.JerebuHUD` and `JerebuMenus.MainMenu` exist,
   and check `LogService:GetLogHistory()` for errors.
3. Use `DebugAPI` 40 and 250 to check the HUD, and `DebugSkip` to reach the report, DAYS and the ending.
   Open the shop at the ShopCounter. Take screen captures, then stop play and clear the lock and any
   debug attributes.

## Requests for other roles
- None. All the data needed comes from the existing `Report` and `Ending` payloads.

## Fix round 1 (2026-10-17, after QA)
Changed `UIStyle`, `HUD` and added a new LocalScript `StarterPlayerScripts.JoinCamera`. All three are mirrored in
`src/` (byte length and checksum match Studio). HazeFX and JerebuServer were not touched.
- **B3 wind arrow:** new `UIStyle.Arrow(props)`, built from 3 rounded bars (a shaft and two head bars). It replaces
  the blank `➤` in the day pill and keeps the same rotation maths. How to Play step 1 now reads "Wind spreads fires
  fast: the arrow under the timer shows where it blows."
- **B5 toasts:** `toast()` measures the text with TextService and wraps it inside min(460, screen − 24 px). At
  375×647 (HUD scale 0.893) the widest toast is 351 px on screen, x 12–363. A long seed toast wrapped to 2 lines
  in play (439×48).
- **B6 chart:** 18 px is kept free above and below the bars for labels. Bar height is max(12, v / maxV × 114) with
  maxV = max(120, peak × 1.1), and a faint "100" guide line marks API 100. With Clear-run values 20–63 the bars
  are 19–57 px with every label readable, and API 20 in an emergency run still shows a visible bar.
- **B9:** `backToMenu` now resets on every Phase change. I tested it in play: opened DAYS from the menu during
  Report, waited for Day, then pressed X. Result: back in the game with the menu closed.
- **B10:** on touch, `layoutHUD` lifts the water card above Roblox's TouchJump button when the two would
  overlap (it uses the TouchJump layout formula). At 375×647 the card bottom is at y549, the jump button top is
  at y557. Checked by calculation only.
- **B11:** How to Play body text is 15 px and shop descriptions are 14 px. On phones the modals change shape:
  `modalWidth()` is screen − 20 in portrait, and the panels are wide and short in landscape (How 600, Shop 560).
  Row heights follow the measured text (`layoutHow`, `layoutShop`). Effective sizes: portrait 375 → 15 / 14 px
  (scale 1); landscape 667×375 → 12.6 / 12.3 px. Step 2 says "tap and hold" when the device is touch-only.
- **B14:** new `UIStyle.FitText`, which picks the largest size that fits on one line. Modal titles use it (the
  title area now leaves room for the X). The report API chip now shows 2 fixed lines: "🌙 API tonight: 276 (+21)"
  and then "Very Unhealthy · Sangat Tidak Sihat". The How to Play banner fits on one line, and "Darurat Jerebu ·
  Haze Emergency" no longer touches the X.
- **B15:** new `UIStyle.SetBannerTone(banner, "sombre"|"green")`. The Emergency ending uses a dark red-brown
  banner and plays no Success sound. Other endings reset the banner to green (checked in play).
- **B16:** `JoinCamera` places the camera 12 studs behind the root, facing where the character looks, 0.3 s after
  each spawn. In play the camera looked along +Z (0, −0.14, 0.99) out of the station door.
- **B17:** new `UIStyle.SetMuted`. Unaffordable buy buttons turn grey with a pink price but can still be
  clicked, so the server still answers "Not enough coins". The shop refreshes when Coins changes. Tested in play
  at 130 and 70 coins.
- Also: `SetEnabled` now shares a `repaint()` helper with `SetMuted`. Pressed buttons stay grey while muted.

**Verified:** 2 short playtests with the lock taken and released. LogService shows no errors except the expected
DataStore `StudioAccessToApisNotAllowed`. Captures: UIFix_Join, UIFix_HowToPlay2, UIFix_Report, UIFix_Shop,
UIFix_ShopMuted, UIFix_EndingClear, UIFix_EndingEmergency2. I faked the endings by firing `Remotes.Ending` to my
client from the Server context. The game loop was not changed. `DebugAPI` and `DebugSkip` were cleared.
**Not verified on a device:** the 375 px layouts (checked by maths, not the emulator), the touch wording, and the
water-card lift, because Studio's TouchEnabled is false.

## Round 3: tabbed shop, ride button, truck bar, boost chip (2026-10-17/18)
Changed `UIStyle`, `HUD`; new ModuleScript `StarterPlayerScripts.ShopUI`. All three mirrored in `src/` (byte lengths match
Studio: UIStyle 23774, HUD 45224, ShopUI 19890). HazeFX, RideFX, Config, JerebuServer, Progression untouched.
- **Shop** (`ShopUI.new{parent, playSound}`, opened by Notify `__openshop` via `shop.Prepare()`): tabs Upgrades · Hoses · Gear ·
  Rides · Premium, subtitle per tab in EN · BM, live coin balance, scrolling card lists, message line. Everything comes from
  Config (`Tracks/TrackCost/TrackValue/fmt/pct`, `Hoses`, `Masks`, `MaskColors`, `Rides`, `Passes`, `Products`, `Icons`); no prices in UI code.
  - Upgrades: icon, EN/BM name, 10 level pips, "18 speed → 19 speed", cost button or gold MAX badge.
  - Hoses: 6 cards; only the next tier is buyable, owned = Equip, current = EQUIPPED badge, others "Locked"; Storm Cannon is a gold card
    tagged LEGENDARY. Strip shows power %, radius, peat soak, tank bonuses from Config.
  - Gear: honest note (cloth masks barely filter PM2.5, N95 does, EN + BM); 4 masks with resist %, no-cough / no-slow flags, OWNED for tiers <= MaskTier,
    any higher tier buyable; icon window tinted with `Config.MaskColors`.
  - Rides: Bicycle / Kapcai (coins; shows your run speed for comparison); Truck shows R$ price and jumps to the Premium tab, scrolled to and flashing its pass card.
  - Premium: 5 passes + 5 products with gold R$ buttons, OWNED for passes. `__prompted` shows nothing; "Coming soon!" shows "Coming soon! · Akan datang" in purple.
  - "NEXT GOAL · SASARAN" gold badge (economy request): N95 until MaskTier >= 3, then Bicycle, then Kapcai, then next hose tier; only one card at a time.
  - Icons: `Config.Icons[key]` ImageLabel when non-empty, else emoji. Unaffordable buttons use `SetMuted`. Cards refresh on `Track_*/Ride_*/Pass_*/Hose*/MaskTier` attribute changes and on Coins changes (coalesced, only while open).
- **Ride button** (HUD, shown only if any `Ride_<id>` true): opens a picker (Walk + owned rides, current one green); tap a ride = `Ride:FireServer(id)`, tap the current ride or Walk
  (`""`) hops off; tap outside closes. Button shows the current/best ride icon and name. Landscape: under the mask line; portrait: row under the day pill (seed banner and toasts shift down while shown).
- **Truck bar**: when `Riding == "Truck"`, a card above the water bar with TruckWater %, "· spraying", and when empty an orange pulsing "Empty · Kosong! Refill at a hydrant or the river".
- **Server Boost chip**: green chip "⚡ Server Boost 9:42" under the API card while `BoostUntil` is in the future.
- **Water**: `InfiniteWater == true` forces a full bar and "Water ∞", never the empty warning (tested with Water = 0).
- Mask hint: with a weak mask (tier 1-2) the HUD now says "This mask only helps a little. An N95 protects best" instead of "No mask!".
- UIStyle additions: `GoldButton`, `SetKind`, `IconBox/SetIcon`, `Pips/SetPips`, `Badge/SetBadge`, gold palette + `Colors.Gold*`.

**Verified (2 short playtests, lock taken/released, DebugCoins 20000 + DebugCoins/BoostUntil cleared):** bought through the UI with
`user_mouse_input` clicks: Brass Jet (hose), N95, Bicycle, Kapcai, Truck pass, Infinite Tank pass, Server Boost product; Coins, owned badges
and the goal badge all updated live. Mounted/dismounted Bicycle-Kapcai-Truck via the picker (Walk, same ride again). Truck bar full and empty, boost chip, ∞ water checked.
Captures: UI3_ShopUpgrades, UI3_ShopHoses, UI3_ShopHosesLegend, UI3_ShopGear, UI3_ShopRides, UI3_ShopRidesOwned,
UI3_ShopPremiumTruckLink, UI3_ShopPremiumTop, UI3_ShopPremiumItems, UI3_RidePicker, UI3_TruckBar, UI3_TruckEmpty,
UI3_PortraitShop, UI3_PortraitGear, UI3_PortraitHUD, UI3_PortraitHUDRide, UI3_PortraitPicker. 375x647 portrait used the Device Simulator (reset afterwards).
No script errors in LogService (only Roblox UIBlox warnings).
**Not verified:** real touch input (Studio TouchEnabled stays false), live Robux prompts, the 3D view (night capture was dark), Premium tab at 375 px
(Upgrades and Gear checked), cards once real Config.Icons images exist (ImageLabel path untested with an image).

**Requests / notes:** none blocking. Setting `Ride_*` attributes by hand gets overwritten by Progression.apply every 3 s, so test by buying. Studio's HttpService is off, so scripts were pushed by paste.

## Round 5: top-strip layout, shop button, pings, crew panel, downed banner (2026-10-18)
Changed `HUD`, `HealthUI`; new `CrewUI` (ModuleScript, required by HUD), `PingUI`, `DownedUI` (LocalScripts). `UIStyle`, ShopUI, Config, JerebuServer,
Progression, HazeFX, RideFX, CrewFX, CampServices untouched. All five are mirrored in `src/`; Adler-32 and byte length match Studio
(HUD 50277, HealthUI 6257, CrewUI 8882, PingUI 15027, DownedUI 4102). README table updated.
- **Layout.** `JerebuHUD` now has `IgnoreGuiInset = true`. `layoutHUD()` reads `GuiService:GetGuiInset()` and puts the day pill (top centre) and the right column
  about 9 screen px from the true top, inside the Roblox top-bar strip. Right column = list layout, all `colW` wide (220, 200 in portrait), 8 px gaps, order:
  API card, Health bar, Water card, Truck water bar (only on the truck), Server Boost chip. `HealthUI.new(parent, {width})` replaces the old "above waterBox" logic
  and returns `box, setWidth`. Left column (below the bar, so clear of Roblox's own buttons) = list layout: coins + menu + SHOP row, mask hint (now wraps),
  ride button, crew panel. The bottom centre is empty, so the hotbar is clear. `placeCentre()` (every frame) hangs the seed banner and toasts under the day pill
  (landscape) or under both columns (portrait), and drops them below the coins row on narrow landscape screens. The ride picker follows the ride button. Water and
  truck texts were shortened to fit 220 px ("Tank empty! Find a hydrant", "Empty · Kosong! Find water"). Portrait (375x647): everything sits below the top bar; left column
  = coins/menu, day pill, SHOP, mask, ride, crew; right column as above. The old touch "lift the water card over the jump button" code is gone (water is at the top now).
- **SHOP · KEDAI** (green kit button next to the menu button; own full-width row in portrait). One `openShop()` is used by the button and by the `__openshop` Notify
  (station counter and camp kiosk), so all three open the same tabbed ShopUI. Pressing the button while the shop is open closes it.
- **Pings** (`PingUI`): hold Q (cursor = aim point, wheel at the cursor, pick by direction, release to send), tap Q (< 0.18 s) = Fire ping at the cursor,
  hold ButtonL1 (screen-centre aim, pick with the right stick), touch = round PING button above Roblox's jump button, tap it to open a tappable wheel, tap outside to cancel.
  Wheel: Fire 🔥 (ImageAssets.Fire), Water 💧, Help 🆘, Follow ➡️ (emoji fallbacks, bilingual captions). Sends `Remotes.Ping:FireServer(kind, pos)` (raycast hit, clamped
  to 480 studs; local 1.5 s cooldown dims the button). Incoming: `Ping.OnClientEvent` -> BillboardGui marker (AlwaysOnTop, adornee is an Attachment under Terrain,
  `StudsOffsetWorldSpace = (0, 6, 0)` as the VFX designer asked), kind-coloured icon + pulsing ring, "Name · Kind", distance, `Sounds.Click`, 8 s, one per sender, fades in the last second.
  Blocked while a menu modal is open. Window blur cancels the wheel.
- **Crew panel** (`CrewUI`): up to 5 others, downed first then nearest; name, Humanoid health bar (green/amber/red), water %, ride icon (Config.Icons or emoji), red
  "REVIVE!" row with distance when `Downed`; collapsible header ("CREW · KRU (n)", turns red "REVIVE NEEDED!" even when collapsed); hidden when solo.
- **Downed banner** (`DownedUI`): warm cream card, "You collapsed!" and a draining bar. "A teammate can revive you · 23s" (countdown from `DownedUntil` vs `GetServerTimeNow()`),
  or "Heading back to the BOMBA station · 6s" when `#Players <= 1`. Soft blue veil, no red flash.

**Verified in play** (3 short playtests, lock taken/released, DebugAPI cleared, no Debug attributes left, LogService clean apart from "Plugin loaded"/UIBlox noise).
Captures: UI5_Landscape1, UI5_ShopButtonOpen, UI5_PingMarker_noAO, UI5_PingWheel, UI5_PingWater, UI5_Downed_solo, UI5_Portrait1, UI5_Portrait_Wheel, UI5_Portrait_Crew,
UI5_Portrait_CrewCollapsed3, UI5_Portrait_ShopBtn, UI5_Portrait_Busy, UI5_Landscape_Busy. Checked: day pill + API card in the strip; Health/Water stacked under the API card;
truck bar, boost chip, seed banner, toasts, mask hint and ride button at 1530x520 desktop and 375x647 portrait (device simulator, touch on); SHOP button opens the shop in both;
Q tap = Fire ping round trip (server -> marker + the VFX pillar, "You · Fire 3m"); Q hold -> wheel -> Water chosen and sent (marker "You · Water"); touch PING button -> wheel -> Help sent;
downed with `DebugAPI = 380`, Health 5, teleported out of the station: banner counted 6 s and cleared after respawn.
**Not verified / caveats**
- **AlwaysOnTop billboards do not appear in `screen_capture`** (same for a plain test billboard); markers render with AlwaysOnTop off, so the marker captures were taken with it
  switched off after spawn. The shipped code keeps AlwaysOnTop = true. Please eyeball it in a real client.
- Only one player was available: the crew panel was verified by feeding fake players through `CrewUI.new(..., { getPlayers = fn })` (the hook exists for tests); the "A teammate can revive you"
  text and the real REVIVE prompt flow need a 2-player run. Gamepad (ButtonL1 + right stick) is untested.
- The Roblox PlayerList (top right under the bar) is not part of captures, so a possible overlap of the right column with it was not seen. If it collides, hide it with
  `StarterGui:SetCoreGuiEnabled(PlayerList, false)` (the crew panel + coins pill cover its job) -- say the word.
- Portrait toasts (up to 4 stacked) can run over the PING button for a few seconds.
- The mouse tool adds a different y offset in the device simulator (clicking by instance path missed small targets by ~20 px); real touch not tried.
**Requests:** none blocking. Optional: server could set `Downed` players' `DownedUntil` once for the revive countdown only (already does).
