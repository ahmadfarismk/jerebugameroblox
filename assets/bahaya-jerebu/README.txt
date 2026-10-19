Bahaya Jerebu! / Dblox asset set

61 original PNGs: 59 from design/shop-items-and-image-prompts.md plus
the requested heart icon and health-bar design preview.
Open gallery.html to browse. manifest.json records actual dimensions and alpha.
prompts.json contains the 59 subject prompts and shared simplified art direction.
health/prompts.json contains the two extra prompts.

Generated with built-in image_gen. The boots image was used as a style reference
for subsequent assets; tutorial 55 was the character reference for 56-59.
No API/CLI fallback, stock art copying, or programmatically drawn image substitutes.

DIMENSIONS: The generator returned 1254x1254 square images, 1672x941 scenes,
and a 2172x724 health-bar preview, rather than the requested export dimensions.
These are untouched native outputs. They have not been resized to Claude's
1024/512/768 square or 1920x1080 delivery targets.
56 PNGs have real alpha transparency; five marketing images are opaque.

HEALTH UI: src/StarterPlayerScripts/HealthUI.lua is a ModuleScript required by HUD.
It builds a live native purple/green bar above water. Health/MaxHealth are read
from the current Humanoid; damage, healing, maximum-health changes and respawns
update the bar. No new damage or regeneration rules were added.
The full health-bar PNG is a design preview, not the live fill texture.
All 61 PNGs are now uploaded to Roblox. See roblox-uploads.json for the IDs.
The shop, HUD, tutorial, main menu, health heart, and fire/hydrant markers are wired
in local src and the open Studio place. See reports/image-ui-integration.md.
59/61 images rendered in the client validation grid. Water and BadgePeat still
reported fetch failures; the water HUD keeps a readable fallback.
Marketing images and badge art are uploaded/cataloged, not configured as
experience thumbnails or awardable badges. No publishing was performed.
Studio confirmed "Saved new changes in Bahaya Jerebu! to Roblox" after Ctrl+S.
