-- Jerebu build step 5/6: Lighting effects, ReplicatedStorage.Jerebu (Remotes + Sounds folders)
-- Scripts/modules (Config, UIStyle, ...) are added separately from src/.
-- Note: set Lighting.Technology = Future by hand in Properties (scripts can't).
local L = game.Lighting
L.ClockTime = 8
L.Brightness = 2.6
L.EnvironmentDiffuseScale = 1
L.EnvironmentSpecularScale = 0.6
L.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
L.Ambient = Color3.fromRGB(70, 70, 80)
L.GlobalShadows = true
L.GeographicLatitude = 3 -- Malaysia
for _, c in L:GetChildren() do c:Destroy() end
local atm = Instance.new("Atmosphere") atm.Name = "HazeAtmosphere" atm.Density = 0.28 atm.Offset = 0.2
atm.Color = Color3.fromRGB(199, 214, 230) atm.Decay = Color3.fromRGB(110, 130, 160) atm.Glare = 0.2 atm.Haze = 0.6 atm.Parent = L
local sky = Instance.new("Sky") sky.Name = "Sky" sky.SunAngularSize = 14 sky.Parent = L
local cc = Instance.new("ColorCorrectionEffect") cc.Name = "HazeColor" cc.Saturation = 0.08 cc.Contrast = 0.05 cc.Parent = L
local bloom = Instance.new("BloomEffect") bloom.Name = "Bloom" bloom.Intensity = 0.6 bloom.Size = 28 bloom.Threshold = 1.6 bloom.Parent = L
local sr = Instance.new("SunRaysEffect") sr.Name = "SunRays" sr.Intensity = 0.06 sr.Spread = 0.6 sr.Parent = L
local blur = Instance.new("BlurEffect") blur.Name = "HazeBlur" blur.Size = 0 blur.Parent = L

local RS = game.ReplicatedStorage
local J = RS:FindFirstChild("Jerebu") or Instance.new("Folder")
J.Name = "Jerebu"
for _, n in { "Remotes", "Sounds" } do
	local f = J:FindFirstChild(n) if f then f:Destroy() end
end
local R = Instance.new("Folder", J) R.Name = "Remotes"
for _, n in { "Spray", "Notify", "Report", "Sfx", "Ending", "Ride", "Ping" } do
	local e = Instance.new("RemoteEvent") e.Name = n e.Parent = R
end
local f = Instance.new("RemoteFunction") f.Name = "Shop" f.Parent = R

-- free Creator Store audio (ProSoundEffects + community), all verified to load
local S = Instance.new("Folder", J) S.Name = "Sounds"
local sounds = {
	FireLoop = { 90775708931474, 0.6, true },
	Spray = { 9126200774, 0.45, true },
	Sizzle = { 6383276435, 0.5, false },
	Birds = { 9112807051, 0.35, true },
	HazeWind = { 9114625552, 0.0, true },
	Click = { 15675059323, 0.5, false },
	Coin = { 1169806635, 0.45, false },
	Cough1 = { 85758067160676, 0.5, false },
	Cough2 = { 95197030860474, 0.5, false },
	Plane = { 86789153907970, 0.8, false },
	Alarm = { 9113089565, 0.25, false },
	Rain = { 9120018695, 0.7, true },
	Refill = { 9120576412, 0.4, true },
	Success = { 4612374036, 0.5, false },
	Ignite = { 135097195613949, 0.5, false },
}
for name, d in sounds do
	local s = Instance.new("Sound") s.Name = name s.SoundId = "rbxassetid://" .. d[1] s.Volume = d[2] s.Looped = d[3] s.Parent = S
end
J.Parent = RS
return "lighting + remotes + sounds ok"
