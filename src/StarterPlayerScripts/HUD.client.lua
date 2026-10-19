-- Jerebu HUD: API meter, day/timer, water, toasts + kit menus (main menu, days board, how to play,
-- night report, ending, shop). All styling comes from ReplicatedStorage.Jerebu.UIStyle.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local UI = require(J:WaitForChild("UIStyle"))
local Assets = require(J:WaitForChild("ImageAssets"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local CrewUI = require(script.Parent:WaitForChild("CrewUI"))
local Remotes = J:WaitForChild("Remotes")
local Sounds = J:WaitForChild("Sounds")

local K = UI.Colors
local new = UI.New
local C = Color3.fromRGB
local WHITE = K.White
local INK, SOFT = K.Ink, K.InkSoft
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local BLACK3 = Color3.new(0, 0, 0)
local camera = workspace.CurrentCamera

local function playSound(name: string)
	local s = Sounds[name]:Clone()
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

local function text(props) return UI.Text(props) end
local function artwork(name, id, parent, size, position)
	local image = new("ImageLabel", { Name = name, Image = id or "", Size = size, Position = position or UDim2.new(), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Parent = parent })
	local symbol = ({ CoinIcon = "●", WaterIcon = "💧", CloudIcon = "☁", WindArrow = "➜", MaskWarningIcon = "⚠", APIFace = "●" })[name]
	if symbol then
		local fallback = text({ Name = "Fallback", Text = symbol, Size = UDim2.fromScale(1, 1), TextScaled = true, TextColor3 = K.Outline, Parent = image })
		local function refresh() fallback.Visible = not image.IsLoaded end
		UI.ImageFallback(image, fallback)
		refresh()
	end
	return image
end

local playerGui = player:WaitForChild("PlayerGui")
local gui = new("ScreenGui", { Name = "JerebuHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local hudScale = new("UIScale", { Parent = gui })
local menus = new("ScreenGui", { Name = "JerebuMenus", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })

-- layout results shared with toast()/placeCentre(); layoutHUD() fills them in
local stripY, belowY, toastCap = 9, 70, 460

---------------------------------------------------------------- columns
-- The HUD draws into the whole screen (IgnoreGuiInset) so the day pill and API card can sit in the Roblox
-- top-bar strip. Right column (API, health, water, truck, boost) and left column (coins row, mask hint,
-- ride button, crew) are list layouts, so they restack by themselves when something appears or hides.
local rightCol = new("Frame", { Name = "RightColumn", Size = UDim2.fromOffset(220, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 9), BackgroundTransparency = 1, Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
})
local leftCol = new("Frame", { Name = "LeftColumn", Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, Position = UDim2.fromOffset(12, 70), BackgroundTransparency = 1, Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local topRow = new("Frame", { Name = "TopRow", Size = UDim2.fromOffset(376, 50), LayoutOrder = 1, BackgroundTransparency = 1, Parent = leftCol })

---------------------------------------------------------------- API card (top right, in the top-bar strip)
local apiCard = UI.Card({ Name = "API", Size = UDim2.fromOffset(220, 128), LayoutOrder = 1, Parent = rightCol })
local apiStroke = apiCard:FindFirstChildOfClass("UIStroke") :: UIStroke
UI.Pad(10).Parent = apiCard
text({ Text = "IPU · AIR POLLUTANT INDEX", Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = SOFT, TextXAlignment = LEFT, Parent = apiCard })
-- the band chip is the strongest colour on the card
local chip = new("Frame", { Name = "Band", Size = UDim2.fromOffset(84, 52), Position = UDim2.fromOffset(0, 18), BackgroundColor3 = Config.Bands[1].color, BorderSizePixel = 0, Parent = apiCard }, {
	UI.Corner(12), UI.Stroke(K.Outline, 3), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(218, 218, 218)) }),
})
local apiFace = artwork("APIFace", Assets.APIGood, chip, UDim2.fromOffset(24, 24), UDim2.fromOffset(59, 14))
local apiNum = text({ Text = "42", Size = UDim2.new(1, -22, 1, 0), TextSize = 30, TextColor3 = WHITE, Parent = chip })
local apiNumStroke = UI.TextStroke(K.Outline, 2.5)
apiNumStroke.Parent = apiNum
local apiBandEn = text({ Text = "Good", Size = UDim2.new(1, -92, 0, 24), Position = UDim2.fromOffset(92, 20), TextScaled = true, TextXAlignment = LEFT, Parent = apiCard })
new("UITextSizeConstraint", { MaxTextSize = 19, Parent = apiBandEn })
local apiBandBm = text({ Text = "Baik", Size = UDim2.new(1, -92, 0, 18), Position = UDim2.fromOffset(92, 46), TextScaled = true, TextColor3 = SOFT, TextXAlignment = LEFT, Parent = apiCard })
new("UITextSizeConstraint", { MaxTextSize = 14, Parent = apiBandBm })
local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 78), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = apiCard }, { UI.Corner(5), UI.Stroke(K.Outline, 2) })
local kp = {}
for i, b in Config.Bands do
	local x = math.clamp(((b.min + math.min(b.max, 400)) / 2) / 400, 0, 1)
	table.insert(kp, ColorSequenceKeypoint.new(i == 1 and 0 or (i == #Config.Bands and 1 or x), b.color))
end
new("UIGradient", { Color = ColorSequence.new(kp), Parent = bar })
local pin = new("Frame", { Size = UDim2.fromOffset(6, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { UI.Corner(3), UI.Stroke(K.Outline, 2) })
local fireLine = text({ Text = "🔥 0 burning", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 94), TextSize = 14, TextXAlignment = LEFT, Parent = apiCard })

---------------------------------------------------------------- day banner (top centre)
local dayPill = new("Frame", {
	Name = "Day", Size = UDim2.fromOffset(230, 56), Position = UDim2.new(0.5, 0, 0, 9), AnchorPoint = Vector2.new(0.5, 0), LayoutOrder = 2,
	BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = gui,
}, { UI.Corner(16), UI.Stroke(K.GreenOutline, 3), UI.Gradient(K.GreenTop, K.GreenBot), UI.Gloss(12) })
local dayText = text({ Text = "HARI 1 / 7", Size = UDim2.new(1, -90, 0, 26), Position = UDim2.fromOffset(14, 5), TextSize = 22, TextColor3 = WHITE, TextXAlignment = LEFT, Parent = dayPill })
UI.TextStroke(K.GreenOutline, 2).Parent = dayText
local phaseText = text({ Text = "Get ready", Size = UDim2.new(1, -90, 0, 16), Position = UDim2.fromOffset(14, 33), TextSize = 13, TextColor3 = C(235, 255, 238), TextXAlignment = LEFT, Parent = dayPill })
local timerBox = new("Frame", { Size = UDim2.fromOffset(66, 28), Position = UDim2.new(1, -8, 0, 6), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = dayPill }, {
	UI.Corner(10), UI.Stroke(K.Outline, 2.5),
})
local timerFill = UI.Gradient(K.PurpleTop, K.PurpleBot)
timerFill.Parent = timerBox
local timerText = text({ Text = "4:00", Size = UDim2.fromScale(1, 1), TextSize = 19, TextColor3 = WHITE, Parent = timerBox })
local windArrow = artwork("WindArrow", Assets.Wind, dayPill, UDim2.fromOffset(24, 24), UDim2.new(1, -8, 0, 32))
windArrow.AnchorPoint = Vector2.new(1, 0)
text({ Text = "wind", Size = UDim2.fromOffset(40, 14), Position = UDim2.new(1, -31, 0, 38), AnchorPoint = Vector2.new(1, 0), TextSize = 12, TextColor3 = C(235, 255, 238), TextXAlignment = RIGHT, Parent = dayPill })

---------------------------------------------------------------- coins + menu + shop buttons (top left, under the Roblox top bar)
local coinPill = UI.Card({ Name = "Coins", Size = UDim2.fromOffset(160, 44), Position = UDim2.fromOffset(0, 3), Parent = topRow })
artwork("CoinIcon", Assets.Coin, coinPill, UDim2.fromOffset(28, 28), UDim2.fromOffset(5, 8))
local coinText = text({ Text = "0", Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(35, 0), TextSize = 18, TextXAlignment = LEFT, Parent = coinPill })
local menuBtn = UI.PurpleButton("", { Name = "MenuButton", Size = UDim2.fromOffset(50, 50), Position = UDim2.fromOffset(168, 0), Parent = topRow }, 26)
UI.MenuIcon(menuBtn)
local shopBtn = UI.GreenButton("SHOP · KEDAI", { Name = "ShopButton", Size = UDim2.fromOffset(150, 50), Position = UDim2.fromOffset(226, 0), LayoutOrder = 3, Parent = topRow }, 19)
local maskText = text({ Text = "", Size = UDim2.fromOffset(380, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Visible = false, TextSize = 14, TextColor3 = WHITE, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = leftCol })
UI.TextStroke(C(40, 24, 56), 2).Parent = maskText
local maskArt = artwork("MaskWarningIcon", Assets.MaskWarning, maskText, UDim2.fromOffset(20, 20), UDim2.fromOffset(0, -1))
maskArt.Visible = false

---------------------------------------------------------------- health + water (right column, under the API card)
local healthBox, setHealthWidth = require(script.Parent:WaitForChild("HealthUI")).new(rightCol, { width = 220, layoutOrder = 2 })
local waterBox = UI.Card({ Name = "Water", Size = UDim2.fromOffset(220, 54), LayoutOrder = 3, Parent = rightCol }, 16)
artwork("WaterIcon", Assets.Water, waterBox, UDim2.fromOffset(22, 22), UDim2.fromOffset(8, 3))
local waterLabel = text({ Text = "Water", Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(32, 7), TextSize = 14, TextScaled = true, TextXAlignment = LEFT, Parent = waterBox })
new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 8, Parent = waterLabel })
local waterTrack = new("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 29), BackgroundColor3 = C(226, 222, 236), BorderSizePixel = 0, Parent = waterBox }, { UI.Corner(7), UI.Stroke(K.Outline, 2) })
local waterFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = waterTrack }, { UI.Corner(7), UI.Gradient(C(110, 200, 255), C(30, 120, 240)) })

local crew = CrewUI.new(leftCol, { width = 200, layoutOrder = 6 })

---------------------------------------------------------------- rides (button + picker), truck water, server boost
local RIDE_EMOJI = { Bicycle = "🚲", Kapcai = "🛵", Truck = "🚒" }

local rideBox = new("Frame", { Name = "RideBox", Size = UDim2.fromOffset(64, 86), LayoutOrder = 5, BackgroundTransparency = 1, Visible = false, ZIndex = 6, Parent = leftCol })
local rideBtn = UI.PurpleButton("", { Name = "RideButton", Size = UDim2.fromOffset(64, 64), ZIndex = 6, Parent = rideBox }, 34)
local rideEmoji = rideBtn.Label :: TextLabel
rideEmoji.Font = Enum.Font.GothamBold
rideEmoji:FindFirstChildOfClass("UIStroke").Thickness = 0
local rideImg = new("ImageLabel", { Size = UDim2.new(1, -14, 1, -14), Position = UDim2.fromOffset(7, 7), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = rideBtn })
local rideCap = text({ Text = "Ride", Size = UDim2.fromOffset(150, 16), Position = UDim2.fromOffset(0, 68), TextSize = 13, TextColor3 = WHITE, TextXAlignment = LEFT, Parent = rideBox })
UI.TextStroke(C(40, 24, 56), 2).Parent = rideCap

-- tap outside the picker to close it (sized to the whole screen through the HUD UIScale)
local pickerCatcher = new("TextButton", { Name = "PickerCatcher", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = gui })
local picker = UI.Card({ Name = "RidePicker", Size = UDim2.fromOffset(214, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(88, 90), Visible = false, ZIndex = 5, Parent = gui }, 16)
UI.Pad(8).Parent = picker
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = picker })
text({ Text = "RIDES · TUNGGANGAN", Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = SOFT, TextXAlignment = LEFT, LayoutOrder = 0, Parent = picker })

local function setPicker(open: boolean)
	picker.Visible = open
	pickerCatcher.Visible = open
end

local PURPLE_SEQ = ColorSequence.new(K.PurpleTop, K.PurpleBot)
local GREEN_SEQ = ColorSequence.new(K.GreenTop, K.GreenBot)
local rideRows = {}
-- id "" is the Walk row; any other id is a Config.Rides entry
local function pickerRow(id: string, order: number, iconKey: string?, emoji: string, en: string)
	local b = new("TextButton", {
		Name = "Row_" .. (id == "" and "Walk" or id), Size = UDim2.new(1, 0, 0, 48), Text = "", AutoButtonColor = false,
		BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = order, Parent = picker,
	}, { UI.Corner(12), UI.Stroke(K.Outline, 2.5), UI.Gradient(K.PurpleTop, K.PurpleBot) })
	UI.IconBox({ Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(6, 6), Parent = b }, iconKey and Config.Icons[iconKey] or "", emoji)
	local name = text({ Text = en, Size = UDim2.new(1, -54, 0, 20), Position = UDim2.fromOffset(48, 5), TextColor3 = WHITE, TextXAlignment = LEFT, TextScaled = true, Parent = b })
	new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 10, Parent = name })
	UI.TextStroke(K.Outline, 1.5).Parent = name
	local sub = text({ Text = "", Size = UDim2.new(1, -54, 0, 14), Position = UDim2.fromOffset(48, 26), TextColor3 = C(238, 228, 250), TextXAlignment = LEFT, TextScaled = true, Parent = b })
	new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8, Parent = sub })
	UI.AttachFeel(b)
	b.Activated:Connect(function()
		-- the server mounts the id, or hops off when it is the ride you are already on ("" = Walk)
		Remotes.Ride:FireServer(id)
		setPicker(false)
	end)
	rideRows[id] = { btn = b, fill = b:FindFirstChild("Fill") :: UIGradient, stroke = b:FindFirstChildOfClass("UIStroke") :: UIStroke, sub = sub }
end
pickerRow("", 1, nil, "🚶", "Walk · Jalan kaki")
for i, r in Config.Rides do
	pickerRow(r.id, i + 1, r.icon, RIDE_EMOJI[r.id] or "🚲", r.en)
end

local function refreshRides()
	local riding = player:GetAttribute("Riding") or ""
	local best, current = nil, nil
	for _, r in Config.Rides do
		local row = rideRows[r.id]
		local has = player:GetAttribute("Ride_" .. r.id) == true
		row.btn.Visible = has
		if has then best = r end
		if r.id == riding then current = r end
		local on = riding == r.id
		row.fill.Color = on and GREEN_SEQ or PURPLE_SEQ
		row.stroke.Color = on and K.GreenOutline or K.Outline
		row.sub.Text = on and "Riding · tap to hop off" or ("%s · speed %d"):format(r.bm, r.speed)
	end
	local walk = rideRows[""]
	walk.fill.Color = riding == "" and GREEN_SEQ or PURPLE_SEQ
	walk.stroke.Color = riding == "" and K.GreenOutline or K.Outline
	walk.sub.Text = riding == "" and "On foot · Berjalan" or "Hop off · Turun"
	rideBox.Visible = best ~= nil
	if best == nil then setPicker(false) end
	local shown = current or best
	if shown then
		local img = Config.Icons[shown.icon]
		rideImg.Visible = img ~= nil and img ~= ""
		if rideImg.Visible then rideImg.Image = img end
		rideEmoji.Text = rideImg.Visible and "" or (RIDE_EMOJI[shown.id] or "🚲")
	end
	UI.SetKind(rideBtn, current and "green" or "purple")
	rideCap.Text = current and current.en or "Ride · Tunggang"
end
rideBtn.Activated:Connect(function() setPicker(not picker.Visible) end)
pickerCatcher.Activated:Connect(function() setPicker(false) end)
player.AttributeChanged:Connect(function(name)
	if name == "Riding" or name:sub(1, 5) == "Ride_" then refreshRides() end
end)
refreshRides()

-- fire truck: its own water tank (TruckWater 0-1, refilled at a hydrant or the river)
local truckBox = UI.Card({ Name = "TruckWater", Size = UDim2.fromOffset(220, 54), LayoutOrder = 4, Visible = false, Parent = rightCol }, 16)
local truckStroke = truckBox:FindFirstChildOfClass("UIStroke") :: UIStroke
local truckLabel = text({ Text = "", Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 6), TextXAlignment = LEFT, TextScaled = true, Parent = truckBox })
new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 9, Parent = truckLabel })
local truckTrack = new("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 29), BackgroundColor3 = C(226, 222, 236), BorderSizePixel = 0, Parent = truckBox }, { UI.Corner(7), UI.Stroke(K.Outline, 2) })
local truckFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = truckTrack }, { UI.Corner(7), UI.Gradient(C(110, 200, 255), C(30, 120, 240)) })
local shownTruck = 1

-- server boost timer chip
local boostChip = new("Frame", { Name = "Boost", Size = UDim2.fromOffset(220, 30), LayoutOrder = 5, BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, Parent = rightCol }, {
	UI.Corner(15), UI.Stroke(K.GreenOutline, 3), UI.Gradient(K.GreenTop, K.GreenBot), UI.Gloss(14),
})
local boostText = text({ Text = "", Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0), TextSize = 15, TextColor3 = WHITE, Parent = boostChip })
UI.TextStroke(K.GreenOutline, 1.5).Parent = boostText

---------------------------------------------------------------- seeding banner
local SEED_DARK = C(20, 70, 140)
local seedBanner = new("TextButton", {
	Name = "Seed", Size = UDim2.fromOffset(360, 44), Position = UDim2.new(0.5, 0, 0, 78), AnchorPoint = Vector2.new(0.5, 0), AutoButtonColor = false,
	BackgroundColor3 = WHITE, BorderSizePixel = 0, Text = "", Visible = false, Parent = gui,
}, { UI.Corner(14), UI.Gradient(C(90, 170, 245), C(30, 110, 200)), UI.Gloss(12) })
local seedStroke = UI.Stroke(SEED_DARK, 3)
seedStroke.Parent = seedBanner
local seedText = text({ Text = "", Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), TextScaled = true, TextColor3 = WHITE, Parent = seedBanner })
new("UITextSizeConstraint", { MaxTextSize = 15, Parent = seedText })
UI.TextStroke(SEED_DARK, 1.5).Parent = seedText

-- waypoint over the airstrip pad, visible through any haze while seeding is ready
local seedPad = workspace:WaitForChild("Map"):WaitForChild("Airstrip"):WaitForChild("SeedPad")
local seedWaypoint = new("BillboardGui", { Size = UDim2.fromOffset(64, 64), StudsOffsetWorldSpace = Vector3.new(0, 14, 0), AlwaysOnTop = true, Adornee = seedPad, Enabled = false, ResetOnSpawn = false, Parent = playerGui })
local seedIcon = text({ Text = "", Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 0, BackgroundColor3 = C(30, 110, 200), TextScaled = true, Font = Enum.Font.GothamBold, Parent = seedWaypoint })
artwork("CloudIcon", Assets.CloudSeeding, seedIcon, UDim2.fromScale(1, 1))
UI.Corner(24).Parent = seedIcon
UI.Stroke(WHITE, 2).Parent = seedIcon
local seedDist = text({ Text = "", Size = UDim2.fromOffset(64, 16), Position = UDim2.fromOffset(0, 48), TextSize = 13, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.4, Parent = seedWaypoint })

---------------------------------------------------------------- toasts
local toastHolder = new("Frame", { Name = "Toasts", Size = UDim2.fromOffset(460, 300), Position = UDim2.new(0.5, 0, 0, 130), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})
local kindColor = {
	info = K.PurpleBot, day = K.PurpleBot, warn = C(225, 135, 30), band = C(210, 85, 45), good = K.GreenBot,
	peat = C(140, 88, 55), seed = C(40, 120, 210),
}
local toastOrder = 0
local function toast(msg: string, kind: string)
	toastOrder += 1
	local col = kindColor[kind] or kindColor.info
	local dark = col:Lerp(BLACK3, 0.38)
	-- wrap inside the screen width (minus 12 px each side), measured in HUD design px
	local maxW = math.min(460, toastCap, (camera.ViewportSize.X - 24) / math.max(hudScale.Scale, 0.01)) - 32
	local ms = TextService:GetTextSize(msg, 16, UI.Font, Vector2.new(maxW - 6, 1000))
	local f = new("Frame", { Size = UDim2.fromOffset(math.min(maxW, math.ceil(ms.X) + 6) + 32, math.max(38, math.ceil(ms.Y) + 16)), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = toastOrder, Parent = toastHolder }, {
		UI.Corner(12), new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(col:Lerp(WHITE, 0.2), col) }),
	})
	local st = UI.Stroke(dark, 3)
	st.Transparency = 1
	st.Parent = f
	local sc = new("UIScale", { Scale = 0.85, Parent = f })
	local t = text({ Text = msg, Size = UDim2.fromScale(1, 1), TextSize = 16, TextWrapped = true, TextColor3 = WHITE, TextTransparency = 1, Parent = f })
	local ts = UI.TextStroke(dark, 1.5)
	ts.Transparency = 1
	ts.Parent = t
	local fade = TweenInfo.new(0.25)
	TweenService:Create(f, fade, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(st, fade, { Transparency = 0 }):Play()
	TweenService:Create(t, fade, { TextTransparency = 0 }):Play()
	TweenService:Create(ts, fade, { Transparency = 0 }):Play()
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(kind == "day" and 4 or 5, function()
		if not f.Parent then return end
		local out = TweenInfo.new(0.4)
		TweenService:Create(f, out, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(st, out, { Transparency = 1 }):Play()
		TweenService:Create(t, out, { TextTransparency = 1 }):Play()
		TweenService:Create(ts, out, { Transparency = 1 }):Play()
		task.wait(0.45)
		f:Destroy()
	end)
	local kids = 0
	for _, c in toastHolder:GetChildren() do if c:IsA("Frame") then kids += 1 end end
	if kids > 4 then
		local oldest, oo = nil, math.huge
		for _, c in toastHolder:GetChildren() do
			if c:IsA("Frame") and c.LayoutOrder < oo then oldest, oo = c, c.LayoutOrder end
		end
		if oldest then oldest:Destroy() end
	end
end

local function randomTip()
	return "💡 " .. Config.Tips[math.random(1, #Config.Tips)]
end

---------------------------------------------------------------- main menu
local menu = UI.Modal(menus, { name = "MainMenu", title = "JEREBU", width = 340, height = 414, close = false, titleSize = 46 })
menu.Shade.BackgroundTransparency = 0.55
local menuBackdrop = artwork("MenuBackground", Assets.MenuBackground, menu.Shade, UDim2.fromScale(1, 1))
menuBackdrop.ScaleType = Enum.ScaleType.Crop
menuBackdrop.ZIndex = 0
menuBackdrop.ImageTransparency = 0.3
local mp = menu.Panel
text({ Text = "7 Days of Haze · 7 Hari Jerebu", Size = UDim2.new(1, 0, 0, 22), TextSize = 18, Parent = mp })
local menuStatus = text({ Text = "", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 25), TextSize = 15, TextColor3 = K.Number, Parent = mp })
local playBtn = UI.PurpleButton("PLAY", { Name = "Play", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 54), Parent = mp }, 30)
local daysBtn = UI.PurpleButton("DAYS", { Name = "Days", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 124), Parent = mp }, 30)
local howBtn = UI.PurpleButton("HOW TO PLAY", { Name = "HowToPlay", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 194), Parent = mp }, 28)
local voteRemote = Remotes:WaitForChild("ModeVote")
local storyVote = UI.PurpleButton("STORY", { Name = "VoteStory", Size = UDim2.new(0.5, -4, 0, 46), Position = UDim2.fromOffset(0, 300), Parent = mp }, 20)
local survivalVote = UI.GreenButton("SURVIVAL", { Name = "VoteSurvival", Size = UDim2.new(0.5, -4, 0, 46), Position = UDim2.new(0.5, 4, 0, 300), Parent = mp }, 20)
local voteStatus = text({ Name = "VoteStatus", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 352), TextSize = 13, TextWrapped = true, Parent = mp })
storyVote.Activated:Connect(function() voteRemote:FireServer("Story") end)
survivalVote.Activated:Connect(function() voteRemote:FireServer("Survival") end)
local function refreshVotes()
	local open = workspace:GetAttribute("Phase") == "Intermission"
	storyVote.Active, survivalVote.Active = open, open
	voteStatus.Text = open and ("Story %d · Survival %d · Your vote: %s"):format(workspace:GetAttribute("StoryVotes") or 0, workspace:GetAttribute("SurvivalVotes") or 0, player:GetAttribute("ModeVote") or "none") or "Voting opens between runs. Ties choose Story."
end
for _, name in { "StoryVotes", "SurvivalVotes", "Phase" } do workspace:GetAttributeChangedSignal(name):Connect(refreshVotes) end
player:GetAttributeChangedSignal("ModeVote"):Connect(refreshVotes)
refreshVotes()
local menuTip = text({ Text = randomTip(), Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 258), TextSize = 13, TextWrapped = true, TextColor3 = SOFT, Parent = mp })

---------------------------------------------------------------- days board
local board = UI.Modal(menus, { name = "Days", title = "DAYS · HARI", width = 460, height = 340 })
local tiles = {}
for d = 1, Config.TotalDays do
	tiles[d] = UI.DayTile(d, { Size = UDim2.fromOffset(96, 124), Parent = board.Panel })
end
local boardTotal = text({ Text = "", Size = UDim2.fromOffset(312, 20), TextSize = 17, Parent = board.Panel })
local boardLegend = text({ Text = "3★ no fires left · 2★ API ≤ 100 · 1★ API ≤ 200", Size = UDim2.fromOffset(312, 16), TextSize = 12, TextColor3 = SOFT, Parent = board.Panel })

local dayStars: { [number]: number } = {}
local function starsFor(r): number
	if r.clean then return 3 end
	if r.apiAfter <= 100 then return 2 end
	if r.apiAfter <= 200 then return 1 end
	return 0
end

local function layoutBoard()
	local vp = camera.ViewportSize
	local TW, TH, G = 96, 124, 12
	local cw, ch
	if vp.X >= vp.Y then
		-- landscape: 1-4 on top, 5, 6 and a wide 7 below
		for d = 1, 6 do
			local col, row = (d - 1) % 4, (d - 1) // 4
			tiles[d].Size = UDim2.fromOffset(TW, TH)
			tiles[d].Position = UDim2.fromOffset(col * (TW + G), row * (TH + G))
		end
		tiles[7].Size = UDim2.fromOffset(TW * 2 + G, TH)
		tiles[7].Position = UDim2.fromOffset(2 * (TW + G), TH + G)
		cw, ch = 4 * TW + 3 * G, 2 * TH + G
	else
		-- portrait: 3 columns, wide 7 centred underneath (like the reference)
		for d = 1, 6 do
			local col, row = (d - 1) % 3, (d - 1) // 3
			tiles[d].Size = UDim2.fromOffset(TW, TH)
			tiles[d].Position = UDim2.fromOffset(col * (TW + G), row * (TH + G))
		end
		cw, ch = 3 * TW + 2 * G, 3 * TH + 2 * G
		tiles[7].Size = UDim2.fromOffset(TW * 2 + G, TH)
		tiles[7].Position = UDim2.fromOffset((cw - (TW * 2 + G)) // 2, 2 * (TH + G))
	end
	boardTotal.Size = UDim2.fromOffset(cw, 20)
	boardTotal.Position = UDim2.fromOffset(0, ch + 8)
	boardLegend.Size = UDim2.fromOffset(cw, 16)
	boardLegend.Position = UDim2.fromOffset(0, ch + 30)
	board.SetSize(cw + 40, ch + 40 + 48)
end

local function refreshBoard()
	local day = workspace:GetAttribute("Day") or 0
	local phase = workspace:GetAttribute("Phase") or "Intermission"
	local total = 0
	for d = 1, Config.TotalDays do
		local s = dayStars[d]
		if s then
			UI.SetDayTile(tiles[d], d, "done", s)
			total += s
		elseif d == day and phase == "Day" then
			UI.SetDayTile(tiles[d], d, "now")
		elseif d <= day then
			UI.SetDayTile(tiles[d], d, "missed")
		else
			UI.SetDayTile(tiles[d], d, "locked")
		end
	end
	boardTotal.Text = ("⭐ %d / %d"):format(total, Config.TotalDays * 3)
end

---------------------------------------------------------------- how to play
local how = UI.Modal(menus, { name = "HowToPlay", title = "HOW TO PLAY · CARA BERMAIN", width = 600, height = 344, titleSize = 30 })
local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
local steps = {
	{ "🔥", "Find the fires · Cari api", "Follow the smoke. Wind spreads fires fast: the arrow under the timer shows where it blows." },
	{ "🧯", "Spray · Sembur", touchOnly and "Equip the hose, face the fire, then tap and hold to spray." or "Equip the hose, aim and hold click to spray." },
	{ "💧", "Refill · Isi semula", "Tank empty? Stand at a hydrant or the river." },
	{ "♨️", "Soak peat fully · Basahkan gambut", "Peat smoulders underground. Keep spraying until it's fully out." },
	{ "😷", "Wear a mask · Pakai pelitup", "API over 100? Buy an N95 mask at the BOMBA station." },
}
local howRows = {}
for i, s in steps do
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, (i - 1) * 61), BackgroundTransparency = 1, Parent = how.Panel })
	local win = new("Frame", { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = row }, {
		UI.Corner(14), UI.Stroke(K.Outline, 3), UI.Gradient(WHITE, K.Tint),
	})
	artwork("TutorialArt", Assets[({ "TutorialSmoke", "TutorialSpray", "TutorialRefill", "TutorialPeat", "TutorialMask" })[i]], win, UDim2.fromScale(1, 1))
	local badge = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(-6, -6), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = win }, {
		UI.Corner(10), UI.Stroke(K.GreenOutline, 2), UI.Gradient(K.GreenTop, K.GreenBot),
	})
	text({ Text = tostring(i), Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = WHITE, Parent = badge })
	text({ Text = s[2], Size = UDim2.new(1, -64, 0, 22), Position = UDim2.fromOffset(64, 4), TextSize = 17, TextXAlignment = LEFT, TextScaled = true, Parent = row })
	local body = text({ Text = s[3], Size = UDim2.new(1, -64, 0, 28), Position = UDim2.fromOffset(64, 26), TextSize = 15, TextColor3 = SOFT, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = row })
	howRows[i] = { row = row, body = body }
end
for _, d in how.Panel:GetDescendants() do
	if d:IsA("TextLabel") and d.TextScaled then new("UITextSizeConstraint", { MaxTextSize = 18, Parent = d }) end
end

-- phones: a narrower panel at scale 1 (portrait) or a wide, short one (landscape) so body text stays >= 12 px
local function modalWidth(wide: number): number
	local vx = camera.ViewportSize.X
	return vx < 470 and math.max(300, math.floor(vx - 20)) or wide
end
local function layoutHow()
	local w = modalWidth(600)
	local bodyW = w - 40 - 64
	local y = 0
	for _, r in howRows do
		local bh = math.ceil(TextService:GetTextSize(r.body.Text, r.body.TextSize, r.body.Font, Vector2.new(bodyW, 1000)).Y)
		local h = math.max(56, 26 + bh + 2)
		r.row.Position = UDim2.fromOffset(0, y)
		r.row.Size = UDim2.new(1, 0, 0, h)
		r.body.Size = UDim2.new(1, -64, 0, bh + 2)
		y += h + 5
	end
	how.SetSize(w, y - 5 + 40)
end

---------------------------------------------------------------- night report
local report = UI.Modal(menus, { name = "Report", title = "Malam 1 · Night 1", width = 400, height = 304, titleSize = 34 })
local rp = report.Panel
local rStars = UI.Stars(46, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Parent = rp })
local rSub = text({ Text = "", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 50), TextSize = 15, TextWrapped = true, Parent = rp })
local rStats = text({ Text = "", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(4, 90), TextSize = 16, RichText = true, LineHeight = 1.15, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = rp })
local rApi = new("Frame", { Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, 160), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = rp }, {
	UI.Corner(12), UI.Stroke(K.Outline, 3), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(218, 218, 218)) }),
})
-- two fixed lines (number, then bilingual band) instead of TextScaled, which wrapped to 2 uneven lines
local rApiText = text({ Text = "", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 2), TextSize = 18, TextColor3 = WHITE, Parent = rApi })
local rApiStroke = UI.TextStroke(K.Outline, 2)
rApiStroke.Parent = rApiText
local rApiBand = text({ Text = "", Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 25), TextSize = 14, TextColor3 = WHITE, Parent = rApi })
local rApiBandStroke = UI.TextStroke(K.Outline, 1.5)
rApiBandStroke.Parent = rApiBand
local rTip = text({ Text = "", Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, 214), TextSize = 13, TextWrapped = true, TextColor3 = K.Outline, BackgroundTransparency = 0, BackgroundColor3 = K.Tint, Parent = rp })
UI.Corner(12).Parent = rTip
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = rTip })

---------------------------------------------------------------- ending
local ending = UI.Modal(menus, { name = "Ending", title = "", width = 480, height = 318, titleSize = 32 })
local ep = ending.Panel
local eSub = text({ Text = "", Size = UDim2.new(1, 0, 0, 40), TextSize = 15, TextWrapped = true, Parent = ep })
local chart = new("Frame", { Name = "Chart", Size = UDim2.new(1, -8, 0, 150), Position = UDim2.fromOffset(4, 46), BackgroundTransparency = 1, Parent = ep })
local eStars = text({ Text = "", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 204), TextSize = 18, TextColor3 = K.Outline, Parent = ep })
local eStats = text({ Text = "", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 228), TextSize = 14, RichText = true, TextScaled = true, Parent = ep })
new("UITextSizeConstraint", { MaxTextSize = 14, Parent = eStats })
local eFoot = text({ Text = "", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 256), TextSize = 12, TextColor3 = SOFT, TextWrapped = true, Parent = ep })

---------------------------------------------------------------- shop (tabbed; built by ShopUI from Config)
local shop = ShopUI.new({ parent = menus, playSound = playSound })

---------------------------------------------------------------- modal flow
local modals = { menu, board, how, report, ending, shop.Modal }
local function closeAll()
	for _, m in modals do m.Close() end
end
local function openOnly(m)
	closeAll()
	m.Open()
end

-- DAYS / HOW TO PLAY opened from the menu go back to it on close (reset on any phase change, so
-- closing them after the day has started returns to the game)
local backToMenu = false
local function closeSub(m)
	m.Close()
	if backToMenu then menu.Open() end
	backToMenu = false
end
board.OnClose = function() closeSub(board) end
how.OnClose = function() closeSub(how) end

playBtn.Activated:Connect(function() menu.Close() end)
daysBtn.Activated:Connect(function()
	refreshBoard()
	layoutBoard()
	openOnly(board)
	backToMenu = true
end)
howBtn.Activated:Connect(function()
	layoutHow()
	openOnly(how)
	backToMenu = true
end)
menuBtn.Activated:Connect(function()
	if menu.IsOpen() then menu.Close() else backToMenu = false openOnly(menu) end
end)

-- one way into the shop: the SHOP button, the station counter and the camp kiosk all land here
local function openShop(quiet: boolean?)
	shop.Prepare()
	backToMenu = false
	openOnly(shop.Modal)
	if not quiet then UI.PlayClick() end
end
shopBtn.Activated:Connect(function()
	if shop.Modal.IsOpen() then shop.Modal.Close() else openShop(true) end
end)

-- Keep the shop toggle above its modal backdrop without lifting the entire HUD.
local shopToggleGui = new("ScreenGui", { Name = "JerebuShopToggle", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11, Parent = playerGui })
local shopCloseToggle = UI.GreenButton("CLOSE SHOP", { Name = "CloseShop", Visible = false, Parent = shopToggleGui }, 19)
shopCloseToggle.Activated:Connect(function() shop.Modal.Close() end)
RunService.RenderStepped:Connect(function()
	shopCloseToggle.Visible = shop.Modal.IsOpen()
	if shopCloseToggle.Visible then
		local pos = shopBtn.AbsolutePosition - gui.AbsolutePosition
		shopCloseToggle.Position = UDim2.fromOffset(math.max(8, pos.X), math.max(70, pos.Y))
		shopCloseToggle.Size = UDim2.fromOffset(shopBtn.AbsoluteSize.X, shopBtn.AbsoluteSize.Y)
	end
end)

---------------------------------------------------------------- remote handlers
Remotes.Notify.OnClientEvent:Connect(function(msg: string, kind: string)
	if msg == "__opencamp" then return end
	if msg == "__openshop" then
		openShop()
		return
	end
	-- The downed banner already carries this message; avoid a duplicate toast underneath it.
	if player:GetAttribute("Downed") and string.find(msg, "You collapsed from the haze!", 1, true) then return end
	toast(msg, kind)
end)

local reportToken = 0
Remotes.Report.OnClientEvent:Connect(function(r)
	local n = starsFor(r)
	dayStars[r.day] = n
	report.Title.Text = ("Malam %d · Night %d"):format(r.day, r.day)
	rSub.Text = r.clean and "Every fire was out by nightfall. The air cleared a little." or "Some fires burned through the night..."
	rStats.Text = table.concat({
		("🧯 Fires put out: <font color='#2DA043'>%d</font> / %d"):format(r.out, r.spawned),
		("🌫️ Left burning overnight: <font color='#E0662A'>%d</font>"):format(r.left),
		("📈 Day average API: %d"):format(r.avg),
	}, "\n")
	local afterBand = Config.Bands[Config.BandIndex(r.apiAfter)]
	local diff = r.apiAfter - r.apiBefore
	rApi.BackgroundColor3 = afterBand.color
	rApiStroke.Color = afterBand.color:Lerp(BLACK3, 0.45)
	rApiBandStroke.Color = rApiStroke.Color
	rApiText.Text = ("🌙 API tonight: %d  (%s%d)"):format(r.apiAfter, diff >= 0 and "+" or "", diff)
	rApiBand.Text = ("%s · %s"):format(afterBand.en, afterBand.bm)
	UI.FitText(rApiText, report.W - 40 - 24, 18, 11)
	UI.FitText(rApiBand, report.W - 40 - 24, 14, 10)
	rTip.Text = randomTip()
	backToMenu = false
	openOnly(report)
	if board.IsOpen() then refreshBoard() end
	-- stars pop in one by one
	UI.SetStars(rStars, 0)
	reportToken += 1
	local token = reportToken
	for i = 1, n do
		task.delay(0.25 + 0.3 * i, function()
			if token ~= reportToken then return end
			UI.SetStars(rStars, i)
			local s = rStars:FindFirstChild("S" .. i)
			if s then
				s.TextSize = 70
				TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { TextSize = 50 }):Play()
			end
			UI.PlayClick()
		end)
	end
	task.delay(Config.ReportLength - 1, function()
		if token == reportToken then report.Close() end
	end)
end)

local endings = {
	clear = { "Langit Cerah · Clear Skies", "🌤️ You kept the haze away. The town can breathe again." },
	survived = { "Bertahan · Survived", "😷 The town made it through, but the air hurt everyone. Can you do better?" },
	emergency = { "Darurat Jerebu · Haze Emergency", "🚨 The haze took over. Schools closed, hospitals filled. Try again and save the air." },
}

Remotes.Ending.OnClientEvent:Connect(function(e)
	if e.mode == "Survival" then
		ending.Title.Text = "Hari demi Hari"
		UI.SetBannerTone(ending.Banner, "sombre")
		eSub.Text = e.reason == "evacuated" and "The town was evacuated after a hazardous day." or "The crew is down. Rest, regroup, and try again."
		for _, c in chart:GetChildren() do c:Destroy() end
		text({ Text = tostring(e.days) .. (e.days == 1 and " DAY SURVIVED" or " DAYS SURVIVED"), Size = UDim2.fromScale(1, 1), TextSize = 32, TextColor3 = K.Number, Parent = chart })
		eStars.Text = ("Session best: %d days"):format(e.best or 0)
		eStats.Text = ("Fires out: <b>%d</b> · Run reward: <b>%d coins</b>"):format(e.out, e.reward or 0)
		eFoot.Text = "Vote for your next run soon."
		backToMenu = false
		openOnly(ending)
		task.delay(Config.EndingLength - 1, function() ending.Close() end)
		return
	end
	local info = endings[e.ending] or endings.survived
	ending.Title.Text = info[1]
	eSub.Text = info[2]
	local sombre = e.ending == "emergency"
	UI.SetBannerTone(ending.Banner, sombre and "sombre" or "green")
	for _, c in chart:GetChildren() do c:Destroy() end
	local n = #e.daily
	-- 18 px reserved top (value labels) and bottom (H labels); bars scale to the run's peak so a
	-- clean run still reads, with a faint guide line at API 100 for honesty
	local LABEL, AREA = 18, 150 - 36
	local peak = 0
	for _, v in e.daily do peak = math.max(peak, v) end
	local maxV = math.max(120, peak * 1.1)
	local guideY = math.floor(100 / maxV * AREA + 0.5)
	new("Frame", { Name = "Guide", Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -LABEL - guideY), BackgroundColor3 = Config.Bands[2].color, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 0, Parent = chart })
	text({ Text = "100", Size = UDim2.fromOffset(22, 12), Position = UDim2.new(1, 1, 1, -LABEL - guideY), AnchorPoint = Vector2.new(0, 0.5), TextSize = 10, TextColor3 = SOFT, TextXAlignment = LEFT, Parent = chart })
	for i, v in e.daily do
		local band = Config.Bands[Config.BandIndex(v)]
		local barH = math.max(12, math.floor(math.clamp(v / maxV, 0, 1) * AREA + 0.5))
		local col = new("Frame", {
			Size = UDim2.new(1 / n, -12, 0, barH), Position = UDim2.new((i - 1) / n, 6, 1, -LABEL - barH),
			BackgroundColor3 = band.color, BorderSizePixel = 0, Parent = chart,
		}, { UI.Corner(math.min(8, barH // 2)), UI.Stroke(K.Outline, 2), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(215, 215, 215)) }) })
		text({ Text = tostring(math.floor(v + 0.5)), Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, -18), TextSize = 13, Parent = col })
		text({ Text = "H" .. i, Size = UDim2.new(1 / n, -12, 0, 16), Position = UDim2.new((i - 1) / n, 6, 1, -16), TextSize = 13, TextColor3 = SOFT, Parent = chart })
	end
	local total = 0
	for _, s in dayStars do total += s end
	eStars.Text = ("⭐ %d / %d stars"):format(total, Config.TotalDays * 3)
	eStats.Text = ("Average API: <b>%d</b>   ·   Fires out: <b>%d</b> / %d   ·   Trees lost: <b>%d</b>"):format(e.average, e.out, e.spawned, e.burnt)
	eFoot.Text = "A new run starts soon. Check real API readings on MyJAS / APIMS."
	backToMenu = false
	openOnly(ending)
	task.delay(Config.EndingLength - 1, function()
		ending.Close()
	end)
	-- no celebration for the emergency ending: the sombre banner and silence say enough
	if not sombre then playSound("Success") end
end)

---------------------------------------------------------------- layout (top-bar strip, columns, phones)
local function layoutHUD()
	local vp = camera.ViewportSize
	local inset = GuiService:GetGuiInset().Y
	local portrait = vp.X < vp.Y
	local s, colW, leftW
	if portrait then
		s = math.clamp(vp.X / 420, 0.6, 1)
		colW = 200
		leftW = math.clamp(math.floor(vp.X / s - colW - 30), 150, 230)
	else
		s = math.clamp(math.min(vp.X / 760, vp.Y / 500), 0.6, 1)
		colW = 220
		leftW = 376
	end
	hudScale.Scale = s
	-- ~9 screen px from the true top (inside the Roblox top-bar strip); everything else sits below the bar
	belowY = math.ceil((inset + 10) / s)
	stripY = inset >= 20 and math.floor(9 / s + 0.5) or belowY
	toastCap = portrait and 1000 or math.max(240, vp.X / s - 2 * (colW + 22))

	-- right column: API card, health, water, truck, boost (same width, 8 px gaps)
	rightCol.Size = UDim2.fromOffset(colW, 0)
	rightCol.Position = UDim2.new(1, -10, 0, portrait and belowY or stripY)
	apiCard.Size = UDim2.fromOffset(colW, 128)
	setHealthWidth(colW)
	waterBox.Size = UDim2.fromOffset(colW, 54)
	truckBox.Size = UDim2.fromOffset(colW, 54)
	boostChip.Size = UDim2.fromOffset(colW, 30)

	-- left column: coins + menu (+ shop) row, mask hint, ride button, crew
	leftCol.Position = UDim2.fromOffset(12, belowY)
	if portrait then
		coinPill.Size = UDim2.fromOffset(130, 44)
		menuBtn.Position = UDim2.fromOffset(136, 0)
		topRow.Size = UDim2.fromOffset(186, 50)
		dayPill.Parent = leftCol
		dayPill.AnchorPoint = Vector2.new(0, 0)
		dayPill.Size = UDim2.fromOffset(leftW, 56)
		dayPill.LayoutOrder = 2
		shopBtn.Parent = leftCol
		shopBtn.Size = UDim2.fromOffset(leftW, 46)
		shopBtn.LayoutOrder = 3
		maskText.Size = UDim2.fromOffset(leftW, 0)
		crew.SetWidth(leftW)
	else
		coinPill.Size = UDim2.fromOffset(160, 44)
		menuBtn.Position = UDim2.fromOffset(168, 0)
		topRow.Size = UDim2.fromOffset(376, 50)
		dayPill.Parent = gui
		dayPill.AnchorPoint = Vector2.new(0.5, 0)
		dayPill.Size = UDim2.fromOffset(230, 56)
		dayPill.Position = UDim2.new(0.5, 0, 0, stripY)
		shopBtn.Parent = topRow
		shopBtn.Size = UDim2.fromOffset(150, 50)
		shopBtn.Position = UDim2.fromOffset(226, 0)
		maskText.Size = UDim2.fromOffset(380, 0)
		crew.SetWidth(220)
	end
	toastHolder.Size = portrait and UDim2.new(1, -24, 0, 300) or UDim2.fromOffset(460, 300)
	pickerCatcher.Size = UDim2.fromScale(1 / s, 1 / s)
	layoutHow()
	shop.Layout()
	if board.IsOpen() then layoutBoard() end
	for _, m in modals do
		if m.IsOpen() then m.Refit() end
	end
end

-- seed banner and toasts hang under the day pill (landscape) or under both columns (portrait);
-- on narrow landscape screens they also drop below the coins row so they never cover it
local function placeCentre()
	local vp = camera.ViewportSize
	local s = hudScale.Scale
	local portrait = vp.X < vp.Y
	-- AbsolutePosition starts below the Roblox top bar even with IgnoreGuiInset, so measure from the left column's own origin
	local function bottomOf(o: GuiObject): number
		return belowY + (o.AbsolutePosition.Y + o.AbsoluteSize.Y - leftCol.AbsolutePosition.Y) / s
	end
	local y, bannerW
	if portrait then
		bannerW = vp.X / s - 24
		y = rightCol.Position.Y.Offset + rightCol.AbsoluteSize.Y / s
		y = math.max(y, bottomOf(shopBtn))
		if maskText.Visible then y = math.max(y, bottomOf(maskText)) end
		if rideBox.Visible then y = math.max(y, bottomOf(rideBox)) end
		y += 8
		seedBanner.Size = UDim2.new(1, -24, 0, 44)
	else
		bannerW = 360
		y = stripY + 56 + 8
		seedBanner.Size = UDim2.fromOffset(360, 44)
		local leftRowRight = 12 + 376 + 8
		local centre = vp.X / s / 2
		if centre - bannerW / 2 < leftRowRight then y = math.max(y, belowY + 50 + 8) end
	end
	seedBanner.AnchorPoint = Vector2.new(0.5, 0)
	seedBanner.Position = UDim2.new(0.5, 0, 0, y)
	local ty = y + (seedBanner.Visible and 52 or 0)
	if not portrait then
		local leftRowRight = 12 + 376 + 8
		local toastW = math.min(460, toastCap)
		if vp.X / s / 2 - toastW / 2 < leftRowRight then ty = math.max(ty, belowY + 50 + 8) end
	end
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, ty)
	-- ride picker opens beside the ride button
	if picker.Visible then
		local off = (rideBox.AbsolutePosition - leftCol.AbsolutePosition) / s
		picker.Position = UDim2.fromOffset(12 + off.X + 76, belowY + off.Y)
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutHUD)
layoutHUD()
layoutBoard()
refreshBoard()

workspace:GetAttributeChangedSignal("Day"):Connect(function()
	if (workspace:GetAttribute("Day") or 0) == 0 then table.clear(dayStars) end
	if board.IsOpen() then refreshBoard() end
end)

-- menu on join
menu.Open()

---------------------------------------------------------------- per-frame bindings
local shownAPI = workspace:GetAttribute("API") or Config.StartAPI
local shownWater = 1
local lastTipSwap = os.clock()
local lastPhase = workspace:GetAttribute("Phase") or "Intermission"

local function fmtTime(s: number)
	return ("%d:%02d"):format(s // 60, s % 60)
end

RunService.RenderStepped:Connect(function(dt)
	-- API
	local api = workspace:GetAttribute("API") or Config.StartAPI
	shownAPI += (api - shownAPI) * math.min(1, dt * 3)
	local bi = Config.BandIndex(shownAPI)
	local band = Config.Bands[bi]
	apiNum.Text = tostring(math.floor(shownAPI + 0.5))
	chip.BackgroundColor3 = band.color
	apiNumStroke.Color = band.color:Lerp(BLACK3, 0.45)
	apiFace.Image = Assets[({ "APIGood", "APIModerate", "APIUnhealthy", "APIVeryUnhealthy", "APIHazardous" })[bi]]
	apiBandEn.Text = band.en
	apiBandBm.Text = band.bm
	pin.Position = UDim2.new(math.clamp(shownAPI / 400, 0, 1), 0, 0.5, 0)
	local fires = workspace:GetAttribute("Fires") or 0
	local sm = workspace:GetAttribute("Smoulder") or 0
	fireLine.Text = ("🔥 %d burning"):format(fires) .. (sm > 0 and ("   ♨️ %d smouldering"):format(sm) or "")
	if bi >= 4 then
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 4)
		apiStroke.Color = band.color
		apiStroke.Thickness = 3 + 2 * pulse
	else
		apiStroke.Color = K.Outline
		apiStroke.Thickness = 3
	end

	-- day / phase
	local phase = workspace:GetAttribute("Phase") or "Intermission"
	local day = workspace:GetAttribute("Day") or 0
	local tl = workspace:GetAttribute("TimeLeft") or 0
	dayText.Text = day > 0 and (workspace:GetAttribute("Mode") == "Survival" and ("HARI %d"):format(day) or ("HARI %d / %d"):format(day, Config.TotalDays)) or "JEREBU"
	timerText.Text = fmtTime(tl)
	phaseText.Text = phase == "Day" and "Put out the fires!" or (phase == "Report" and "Night falls..." or (phase == "Ended" and "Run over" or "Get ready"))
	if workspace:GetAttribute("Mode") == "Survival" then
		phaseText.Text = phase == "Night" and "MALAM · Regroup at camp" or phase == "Camp" and "KEM · Build together" or phase == "Day" and "SURVIVAL · Fight fires" or phaseText.Text
	end
	local hurry = phase == "Day" and tl <= 30
	timerFill.Color = hurry and ColorSequence.new(C(240, 110, 80), C(200, 60, 45)) or ColorSequence.new(K.PurpleTop, K.PurpleBot)
	local w = workspace:GetAttribute("Wind") :: Vector3?
	if w then
		-- arrow relative to camera so it reads like a compass
		local look = camera.CFrame.LookVector
		local camAng = math.atan2(look.X, -look.Z)
		local windAng = math.atan2(w.X, -w.Z)
		windArrow.Rotation = math.deg(windAng - camAng) - 90
	end

	-- phase transitions drive the menu
	if phase ~= lastPhase then
		backToMenu = false
		if phase == "Day" and lastPhase == "Intermission" then
			menu.Close()
		elseif phase == "Intermission" and lastPhase == "Ended" then
			table.clear(dayStars)
			backToMenu = false
			openOnly(menu)
		end
		if board.IsOpen() then refreshBoard() end
		lastPhase = phase
	end
	if menu.IsOpen() then
		if phase == "Intermission" then
			menuStatus.Text = ("Day 1 starts in %d · Hari 1 bermula"):format(tl)
		elseif phase == "Day" then
			menuStatus.Text = ("Hari %d / %d · fires are burning!"):format(day, Config.TotalDays)
		elseif phase == "Report" then
			menuStatus.Text = "Night falls · Malam tiba"
		else
			menuStatus.Text = "Run over · a new run starts soon"
		end
		if os.clock() - lastTipSwap > 6 then
			lastTipSwap = os.clock()
			menuTip.Text = randomTip()
		end
	end

	-- coins / mask
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		coinText.Text = ("%d   🧯 %d"):format(ls.Coins.Value, ls.Padam.Value)
	end
	if bi >= 3 then
		local tier = player:GetAttribute("MaskTier") or 0
		if player:GetAttribute("Mask") then
			maskText.Text = "     Mask on - you're protected"
			maskText.TextColor3 = C(150, 240, 175)
		elseif tier > 0 then
			maskText.Text = "     This mask only helps a little. An N95 protects best"
			maskText.TextColor3 = C(255, 220, 130)
		else
			maskText.Text = "     No mask! Buy one at the BOMBA station"
			maskText.TextColor3 = C(255, 200, 100)
		end
	else
		maskText.Text = ""
	end

	-- water
	local cap = player:GetAttribute("MaxWater") or 100
	maskArt.Visible = maskText.Text ~= ""
	local water = player:GetAttribute("Water") or cap
	local infinite = player:GetAttribute("InfiniteWater") == true
	local frac = infinite and 1 or math.clamp(water / cap, 0, 1)
	shownWater += (frac - shownWater) * math.min(1, dt * 8)
	waterFill.Size = UDim2.fromScale(shownWater, 1)
	waterFill.Visible = shownWater > 0.01
	if infinite then
		waterLabel.Text = "Water  ∞"
		waterLabel.TextColor3 = INK
	elseif player:GetAttribute("Refilling") then
		waterLabel.Text = ("Refilling...  %d / %d"):format(water, cap)
		waterLabel.TextColor3 = C(30, 120, 220)
	elseif water <= 0.5 then
		waterLabel.Text = "Tank empty! Find a hydrant"
		waterLabel.TextColor3 = C(210, 70, 50)
	else
		waterLabel.Text = ("Water  %d / %d"):format(water, cap)
		waterLabel.TextColor3 = INK
	end

	-- cloud seeding banner
	if workspace:GetAttribute("SeedReady") then
		seedBanner.Visible = true
		seedText.Text = ("☁️ CLOUD SEEDING READY · Airstrip  (%d/%d loaded)"):format(workspace:GetAttribute("SeedLoaded") or 0, workspace:GetAttribute("SeedNeed") or 1)
		seedStroke.Thickness = 3 + 1.5 * (0.5 + 0.5 * math.sin(os.clock() * 3))
		seedWaypoint.Enabled = true
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then seedDist.Text = ("%dm"):format((seedPad.Position - root.Position).Magnitude // 1) end
	else
		seedBanner.Visible = false
		seedWaypoint.Enabled = false
	end

	-- fire truck tank
	local onTruck = player:GetAttribute("Riding") == "Truck"
	truckBox.Visible = onTruck
	if onTruck then
		local tw = player:GetAttribute("TruckWater") or 1
		shownTruck += (tw - shownTruck) * math.min(1, dt * 8)
		truckFill.Size = UDim2.fromScale(shownTruck, 1)
		truckFill.Visible = shownTruck > 0.01
		if tw <= 0.02 then
			truckLabel.Text = "🚒 Empty · Kosong! Find water"
			truckLabel.TextColor3 = C(210, 70, 50)
			truckStroke.Color = C(235, 120, 40)
			truckStroke.Thickness = 3 + 2 * (0.5 + 0.5 * math.sin(os.clock() * 5))
		else
			truckLabel.Text = ("🚒 Truck water  %d%%%s"):format(math.floor(tw * 100 + 0.5), player:GetAttribute("TruckSpraying") and "  · spraying" or "")
			truckLabel.TextColor3 = INK
			truckStroke.Color = K.Outline
			truckStroke.Thickness = 3
		end
	end

	-- server boost timer
	local boostLeft = (workspace:GetAttribute("BoostUntil") or 0) - workspace:GetServerTimeNow()
	boostChip.Visible = boostLeft > 0
	if boostLeft > 0 then boostText.Text = "⚡ Server Boost " .. fmtTime(math.ceil(boostLeft)) end

	maskText.Visible = maskText.Text ~= ""
	placeCentre()
end)
