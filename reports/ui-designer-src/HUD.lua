-- Jerebu HUD: API meter, day/timer, water, toasts + kit menus (main menu, days board, how to play,
-- night report, ending, shop). All styling comes from ReplicatedStorage.Jerebu.UIStyle.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local UI = require(J:WaitForChild("UIStyle"))
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

local playerGui = player:WaitForChild("PlayerGui")
local gui = new("ScreenGui", { Name = "JerebuHUD", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local hudScale = new("UIScale", { Parent = gui })
local menus = new("ScreenGui", { Name = "JerebuMenus", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })

---------------------------------------------------------------- API card (top right)
local apiCard = UI.Card({ Name = "API", Size = UDim2.fromOffset(220, 128), Position = UDim2.new(1, -12, 0, 12), AnchorPoint = Vector2.new(1, 0), Parent = gui })
local apiStroke = apiCard:FindFirstChildOfClass("UIStroke") :: UIStroke
UI.Pad(10).Parent = apiCard
text({ Text = "IPU · AIR POLLUTANT INDEX", Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = SOFT, TextXAlignment = LEFT, Parent = apiCard })
-- the band chip is the strongest colour on the card
local chip = new("Frame", { Name = "Band", Size = UDim2.fromOffset(84, 52), Position = UDim2.fromOffset(0, 18), BackgroundColor3 = Config.Bands[1].color, BorderSizePixel = 0, Parent = apiCard }, {
	UI.Corner(12), UI.Stroke(K.Outline, 3), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(218, 218, 218)) }),
})
local apiNum = text({ Text = "42", Size = UDim2.fromScale(1, 1), TextSize = 36, TextColor3 = WHITE, Parent = chip })
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
	Name = "Day", Size = UDim2.fromOffset(230, 56), Position = UDim2.new(0.5, 0, 0, 12), AnchorPoint = Vector2.new(0.5, 0),
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
local windArrow = text({ Text = "➤", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -12, 0, 37), AnchorPoint = Vector2.new(1, 0), TextSize = 14, TextColor3 = WHITE, Parent = dayPill })
text({ Text = "wind", Size = UDim2.fromOffset(40, 14), Position = UDim2.new(1, -31, 0, 38), AnchorPoint = Vector2.new(1, 0), TextSize = 12, TextColor3 = C(235, 255, 238), TextXAlignment = RIGHT, Parent = dayPill })

---------------------------------------------------------------- coins + menu button (top left, under roblox menu)
local coinPill = UI.Card({ Name = "Coins", Size = UDim2.fromOffset(160, 44), Position = UDim2.fromOffset(12, 12), Parent = gui })
local coinText = text({ Text = "💰 0", Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0), TextSize = 18, TextXAlignment = LEFT, Parent = coinPill })
local menuBtn = UI.PurpleButton("☰", { Name = "MenuButton", Size = UDim2.fromOffset(50, 50), Position = UDim2.fromOffset(180, 9), Parent = gui }, 26)
local maskText = text({ Text = "", Size = UDim2.fromOffset(280, 18), Position = UDim2.fromOffset(14, 64), TextSize = 14, TextColor3 = WHITE, TextXAlignment = LEFT, Parent = gui })
UI.TextStroke(C(40, 24, 56), 2).Parent = maskText

---------------------------------------------------------------- water (bottom centre)
local waterBox = UI.Card({ Name = "Water", Size = UDim2.fromOffset(300, 54), Position = UDim2.new(0.5, 0, 1, -84), AnchorPoint = Vector2.new(0.5, 1), Parent = gui }, 16)
local waterLabel = text({ Text = "💧 Water", Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(12, 7), TextSize = 14, TextXAlignment = LEFT, Parent = waterBox })
local waterTrack = new("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 29), BackgroundColor3 = C(226, 222, 236), BorderSizePixel = 0, Parent = waterBox }, { UI.Corner(7), UI.Stroke(K.Outline, 2) })
local waterFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = waterTrack }, { UI.Corner(7), UI.Gradient(C(110, 200, 255), C(30, 120, 240)) })

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
local seedWaypoint = new("BillboardGui", { Size = UDim2.fromOffset(64, 64), StudsOffsetWorldSpace = Vector3.new(0, 14, 0), AlwaysOnTop = true, Adornee = seedPad, Enabled = false, Parent = playerGui })
local seedIcon = text({ Text = "☁️", Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 0, BackgroundColor3 = C(30, 110, 200), TextScaled = true, Font = Enum.Font.GothamBold, Parent = seedWaypoint })
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
	local f = new("Frame", { Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = toastOrder, Parent = toastHolder }, {
		UI.Corner(12), new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(col:Lerp(WHITE, 0.2), col) }),
	})
	local st = UI.Stroke(dark, 3)
	st.Transparency = 1
	st.Parent = f
	local sc = new("UIScale", { Scale = 0.85, Parent = f })
	local t = text({ Text = msg, Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextSize = 16, TextColor3 = WHITE, TextTransparency = 1, Parent = f })
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
local menu = UI.Modal(menus, { name = "MainMenu", title = "JEREBU", width = 340, height = 332, close = false, titleSize = 46 })
menu.Shade.BackgroundTransparency = 0.55
local mp = menu.Panel
text({ Text = "7 Days of Haze · 7 Hari Jerebu", Size = UDim2.new(1, 0, 0, 22), TextSize = 18, Parent = mp })
local menuStatus = text({ Text = "", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 25), TextSize = 15, TextColor3 = K.Number, Parent = mp })
local playBtn = UI.PurpleButton("PLAY", { Name = "Play", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 54), Parent = mp }, 30)
local daysBtn = UI.PurpleButton("DAYS", { Name = "Days", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 124), Parent = mp }, 30)
local howBtn = UI.PurpleButton("HOW TO PLAY", { Name = "HowToPlay", Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 194), Parent = mp }, 28)
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
local how = UI.Modal(menus, { name = "HowToPlay", title = "HOW TO PLAY · CARA BERMAIN", width = 440, height = 344, titleSize = 30 })
local steps = {
	{ "🔥", "Find the fires · Cari api", "Follow the smoke. The wind ➤ spreads fires fast." },
	{ "🧯", "Spray · Sembur", "Equip the hose, aim and hold click to spray." },
	{ "💧", "Refill · Isi semula", "Tank empty? Stand at a hydrant or the river." },
	{ "♨️", "Soak peat fully · Basahkan gambut", "Peat smoulders underground. Keep spraying until it's fully out." },
	{ "😷", "Wear a mask · Pakai pelitup", "API over 100? Buy an N95 mask at the BOMBA station." },
}
for i, s in steps do
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, (i - 1) * 61), BackgroundTransparency = 1, Parent = how.Panel })
	local win = new("Frame", { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = row }, {
		UI.Corner(14), UI.Stroke(K.Outline, 3), UI.Gradient(WHITE, K.Tint),
	})
	text({ Text = s[1], Size = UDim2.fromScale(1, 1), TextSize = 30, Font = Enum.Font.GothamBold, Parent = win })
	local badge = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(-6, -6), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = win }, {
		UI.Corner(10), UI.Stroke(K.GreenOutline, 2), UI.Gradient(K.GreenTop, K.GreenBot),
	})
	text({ Text = tostring(i), Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = WHITE, Parent = badge })
	text({ Text = s[2], Size = UDim2.new(1, -64, 0, 22), Position = UDim2.fromOffset(64, 4), TextSize = 17, TextXAlignment = LEFT, TextScaled = true, Parent = row }, nil)
	text({ Text = s[3], Size = UDim2.new(1, -64, 0, 28), Position = UDim2.fromOffset(64, 26), TextSize = 13, TextColor3 = SOFT, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = row })
end
for _, d in how.Panel:GetDescendants() do
	if d:IsA("TextLabel") and d.TextScaled then new("UITextSizeConstraint", { MaxTextSize = 17, Parent = d }) end
end

---------------------------------------------------------------- night report
local report = UI.Modal(menus, { name = "Report", title = "Malam 1 · Night 1", width = 400, height = 304, titleSize = 34 })
local rp = report.Panel
local rStars = UI.Stars(46, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Parent = rp })
local rSub = text({ Text = "", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 50), TextSize = 15, TextWrapped = true, Parent = rp })
local rStats = text({ Text = "", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(4, 90), TextSize = 16, RichText = true, LineHeight = 1.15, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = rp })
local rApi = new("Frame", { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 164), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = rp }, {
	UI.Corner(12), UI.Stroke(K.Outline, 3), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(218, 218, 218)) }),
})
local rApiText = text({ Text = "", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), TextScaled = true, TextColor3 = WHITE, Parent = rApi })
new("UITextSizeConstraint", { MaxTextSize = 17, Parent = rApiText })
local rApiStroke = UI.TextStroke(K.Outline, 2)
rApiStroke.Parent = rApiText
local rTip = text({ Text = "", Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 210), TextSize = 13, TextWrapped = true, TextColor3 = K.Outline, BackgroundTransparency = 0, BackgroundColor3 = K.Tint, Parent = rp })
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

---------------------------------------------------------------- shop
local shop = UI.Modal(menus, { name = "Shop", title = "KEDAI · GEAR", width = 400, height = 324, titleSize = 36 })
local shopList = new("Frame", { Size = UDim2.new(1, 0, 0, 254), BackgroundTransparency = 1, Parent = shop.Panel }, {
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local shopMsg = text({ Text = "", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 262), TextSize = 14, TextScaled = true, Parent = shop.Panel })
new("UITextSizeConstraint", { MaxTextSize = 14, Parent = shopMsg })

local shopRows = {}
local function shopRow(key: string, icon: string, order: number)
	local row = new("Frame", { Name = key, Size = UDim2.new(1, 0, 0, 78), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = order, Parent = shopList }, {
		UI.Corner(16), UI.Stroke(K.Outline, 3), UI.Gradient(K.PurpleTop, K.PurpleBot), UI.Gloss(14),
	})
	local win = new("Frame", { Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(11, 11), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = row }, { UI.Corner(12) })
	text({ Text = icon, Size = UDim2.fromScale(1, 1), TextSize = 32, Font = Enum.Font.GothamBold, Parent = win })
	local title = text({ Text = "", Size = UDim2.new(1, -196, 0, 22), Position = UDim2.fromOffset(78, 9), TextScaled = true, TextColor3 = WHITE, TextXAlignment = LEFT, Parent = row })
	new("UITextSizeConstraint", { MaxTextSize = 18, Parent = title })
	UI.TextStroke(K.Outline, 1.5).Parent = title
	local desc = text({ Text = "", Size = UDim2.new(1, -196, 0, 38), Position = UDim2.fromOffset(78, 32), TextSize = 12, TextColor3 = C(244, 236, 252), TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium, Parent = row })
	local btn = UI.GreenButton("", { Name = "Buy", Size = UDim2.fromOffset(104, 50), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = row }, 18)
	btn.Activated:Connect(function()
		if btn:GetAttribute("Disabled") then return end
		local ok, msg = Remotes.Shop:InvokeServer(key)
		shopMsg.Text = msg or ""
		shopMsg.TextColor3 = ok and K.Number or C(205, 80, 50)
		if ok then playSound("Success") end
	end)
	shopRows[key] = { title = title, desc = desc, btn = btn }
end
shopRow("Tank", "🛢️", 1)
shopRow("Nozzle", "🚿", 2)
shopRow("Mask", "😷", 3)

local function refreshShop()
	local tank = player:GetAttribute("Tank") or 1
	local noz = player:GetAttribute("Nozzle") or 1
	local function set(key, title, desc, price)
		local r = shopRows[key]
		r.title.Text = title
		r.desc.Text = desc
		r.btn.Label.Text = price and ("💰 " .. price) or "Owned"
		UI.SetEnabled(r.btn, price ~= nil)
	end
	if tank < #Config.Tanks then
		set("Tank", ("Water Tank Lv.%d"):format(tank + 1), ("Carry %d water (now %d). Fewer trips to the river."):format(Config.Tanks[tank + 1].cap, Config.Tanks[tank].cap), Config.Tanks[tank + 1].price)
	else
		set("Tank", "Water Tank MAX", ("Carrying %d water."):format(Config.Tanks[tank].cap), nil)
	end
	if noz < #Config.Nozzles then
		set("Nozzle", ("Nozzle Lv.%d"):format(noz + 1), ("Stronger, longer spray (range %d)."):format(Config.Nozzles[noz + 1].range), Config.Nozzles[noz + 1].price)
	else
		set("Nozzle", "Nozzle MAX", ("Range %d."):format(Config.Nozzles[noz].range), nil)
	end
	set("Mask", "N95 Mask", "No coughing and less slowdown when the API is above 100.", (not player:GetAttribute("Mask")) and Config.MaskPrice or nil)
end
player:GetAttributeChangedSignal("Tank"):Connect(refreshShop)
player:GetAttributeChangedSignal("Nozzle"):Connect(refreshShop)
player:GetAttributeChangedSignal("Mask"):Connect(refreshShop)
refreshShop()

---------------------------------------------------------------- modal flow
local modals = { menu, board, how, report, ending, shop }
local function closeAll()
	for _, m in modals do m.Close() end
end
local function openOnly(m)
	closeAll()
	m.Open()
end

-- DAYS / HOW TO PLAY opened from the menu go back to it on close
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
	openOnly(how)
	backToMenu = true
end)
menuBtn.Activated:Connect(function()
	if menu.IsOpen() then menu.Close() else backToMenu = false openOnly(menu) end
end)

---------------------------------------------------------------- remote handlers
Remotes.Notify.OnClientEvent:Connect(function(msg: string, kind: string)
	if msg == "__openshop" then
		refreshShop()
		shopMsg.Text = ""
		backToMenu = false
		openOnly(shop)
		UI.PlayClick()
		return
	end
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
	rApiText.Text = ("🌙 API tonight: %d %s · %s  (%s%d)"):format(r.apiAfter, afterBand.en, afterBand.bm, diff >= 0 and "+" or "", diff)
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
	local info = endings[e.ending] or endings.survived
	ending.Title.Text = info[1]
	eSub.Text = info[2]
	for _, c in chart:GetChildren() do c:Destroy() end
	local n = #e.daily
	local maxV = 400
	for i, v in e.daily do
		local band = Config.Bands[Config.BandIndex(v)]
		local h = math.clamp(v / maxV, 0.04, 1)
		local col = new("Frame", {
			Size = UDim2.new(1 / n, -12, h, -20), Position = UDim2.new((i - 1) / n, 6, 1 - h, 0),
			BackgroundColor3 = band.color, BorderSizePixel = 0, Parent = chart,
		}, { UI.Corner(8), UI.Stroke(K.Outline, 2), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, C(215, 215, 215)) }) })
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
	playSound("Success")
end)

---------------------------------------------------------------- layout (phones: UIScale + portrait rearrange)
local function layoutHUD()
	local vp = camera.ViewportSize
	if vp.X < vp.Y then
		-- portrait: day banner drops under the coins so the top row fits
		hudScale.Scale = math.clamp(vp.X / 420, 0.6, 1)
		coinPill.Size = UDim2.fromOffset(130, 44)
		menuBtn.Position = UDim2.fromOffset(150, 9)
		apiCard.Size = UDim2.fromOffset(200, 128)
		dayPill.AnchorPoint = Vector2.new(0, 0)
		dayPill.Size = UDim2.fromOffset(188, 56)
		dayPill.Position = UDim2.fromOffset(12, 66)
		maskText.Position = UDim2.fromOffset(14, 128)
		seedBanner.Size = UDim2.new(1, -24, 0, 44)
		seedBanner.Position = UDim2.new(0.5, 0, 0, 150)
		toastHolder.Size = UDim2.new(1, -24, 0, 300)
		toastHolder.Position = UDim2.new(0.5, 0, 0, 200)
	else
		hudScale.Scale = math.clamp(math.min(vp.X / 760, vp.Y / 500), 0.6, 1)
		coinPill.Size = UDim2.fromOffset(160, 44)
		menuBtn.Position = UDim2.fromOffset(180, 9)
		apiCard.Size = UDim2.fromOffset(220, 128)
		dayPill.AnchorPoint = Vector2.new(0.5, 0)
		dayPill.Size = UDim2.fromOffset(230, 56)
		dayPill.Position = UDim2.new(0.5, 0, 0, 12)
		maskText.Position = UDim2.fromOffset(14, 64)
		seedBanner.Size = UDim2.fromOffset(360, 44)
		seedBanner.Position = UDim2.new(0.5, 0, 0, 78)
		toastHolder.Size = UDim2.fromOffset(460, 300)
		toastHolder.Position = UDim2.new(0.5, 0, 0, 130)
	end
	if board.IsOpen() then layoutBoard() end
	for _, m in modals do
		if m.IsOpen() then m.Refit() end
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
	dayText.Text = day > 0 and ("HARI %d / %d"):format(day, Config.TotalDays) or "JEREBU"
	timerText.Text = fmtTime(tl)
	phaseText.Text = phase == "Day" and "Put out the fires!" or (phase == "Report" and "Night falls..." or (phase == "Ended" and "Run over" or "Get ready"))
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
		coinText.Text = ("💰 %d   🧯 %d"):format(ls.Coins.Value, ls.Padam.Value)
	end
	if bi >= 3 then
		if player:GetAttribute("Mask") then
			maskText.Text = "😷 Mask on - you're protected"
			maskText.TextColor3 = C(150, 240, 175)
		else
			maskText.Text = "⚠️ No mask! Buy one at the BOMBA station"
			maskText.TextColor3 = C(255, 200, 100)
		end
	else
		maskText.Text = ""
	end

	-- water
	local cap = player:GetAttribute("MaxWater") or 100
	local water = player:GetAttribute("Water") or cap
	local frac = math.clamp(water / cap, 0, 1)
	shownWater += (frac - shownWater) * math.min(1, dt * 8)
	waterFill.Size = UDim2.fromScale(shownWater, 1)
	waterFill.Visible = shownWater > 0.01
	if player:GetAttribute("Refilling") then
		waterLabel.Text = ("💧 Refilling...  %d / %d"):format(water, cap)
		waterLabel.TextColor3 = C(30, 120, 220)
	elseif water <= 0.5 then
		waterLabel.Text = "💧 Tank empty! Go to a hydrant or the river"
		waterLabel.TextColor3 = C(210, 70, 50)
	else
		waterLabel.Text = ("💧 Water  %d / %d"):format(water, cap)
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
end)
