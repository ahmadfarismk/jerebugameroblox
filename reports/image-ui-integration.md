# Image upload and UI integration — 18 October 2026

61 PNGs uploaded to Roblox under the place owner's account (creator 96592687).
All filename/key/image-ID mappings are in assets/bahaya-jerebu/roblox-uploads.json
and src/ReplicatedStorage/Jerebu/ImageAssets.lua.

Installed in open place 71624879418597 and mirrored in local src:
- Config: 29 shop cards map to generated art, with separate ride/premium truck images.
- HUD: coin, water, API band faces, wind, mask warning, cloud-seeding marker,
  five tutorial images, main-menu background, and existing ride picker.
- HealthUI: uploaded heart, live health fill and readable fallback.
- UIStyle: image fallback loading fix (visible image request; poll IsLoaded at 5 Hz
  because its property signal did not reliably fire in Studio; cleanup on destroy).
- HazeFX: fire/peat billboard art.
- AssetMarkers: nearby hydrant icons (90-stud maximum range).
- ImageAssets: all 61 IDs available for future UI/content integration.

Verification:
- All 61 assets exist as image IDs returned by Roblox's upload connector.
- Temporary client grid rendered 59/61. Water (90801669324588) and
  BadgePeat (87173107468670) returned AssetFetchStatus.Failure at final check.
  Upload retry returned the same IDs. Studio later logged HTTP 502 for BadgePeat;
  Water's cause is unconfirmed. No moderation bypass was attempted.
  Water retains a readable native fallback. Peat badge is catalog-only.
- Shop boots and premium Godspeed artwork visually checked; 29 card mappings
  exist. Hidden/offscreen ImageLabels are lazily loaded, so not all report
  IsLoaded until displayed. Five tutorial images confirmed loaded.
- Heart IsLoaded true, fallback false; 20/100 shows LOW HP.
- Respawn returns 100/100 with exactly one health bar and loaded heart.
- No client MessageError entries in final playtest.
- Backups in ServerStorage.Backup_ImageIntegration_20261018.
- Test grid removed, play stopped, lock cleared, loopback servers stopped.
- Narrow landscape Studio viewport tested; mobile emulator and full seven-day
  multiplayer round were not tested.

Scope:
Marketing images, badge artwork, helmet, and full health-bar preview are uploaded
and cataloged. No experience icon/thumbnail configuration or badge-award system
was created; no new helmet item or monetization products were invented.
The health preview remains a design reference; live fill uses native UI.
Studio confirmed the place saved to Roblox after Ctrl+S. No publishing was performed.
