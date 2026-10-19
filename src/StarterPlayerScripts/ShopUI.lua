-- Jerebu shop: tabbed kit modal (Upgrades · Hoses · Gear · Rides · Premium).
-- Names, prices, stats and Robux costs all come from Config; icons use Config.Icons[key] and fall back to an emoji.
-- HUD builds it with ShopUI.new({ parent = menusGui, playSound = fn }) and treats .Modal like the other modals.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local UI = require(J:WaitForChild("UIStyle"))
local Remotes = J:WaitForChild("Remotes")

local K = UI.Colors
local new = UI.New
local C = Color3.fromRGB
local WHITE = K.White
local LEFT = Enum.TextXAlignment.Left
local camera = workspace.CurrentCamera

local ShopUI = {}

local EMOJI = {
	Boots = "🥾", Pressure = "💨", Tank = "🛢️", Range = "🎯", Pump = "⛲", Lungs = "🌬️",
	Hose1 = "🚿", Hose2 = "🔧", Hose3 = "🔫", Hose4 = "🧼", Hose5 = "🎒", Hose6 = "⛈️",
	Mask1 = "😷", Mask2 = "😷", Mask3 = "😷", Mask4 = "😷",
	Bicycle = "🚲", Kapcai = "🛵", Truck = "🚒",
	Godspeed = "⚡", InfiniteTank = "♾️", VIP = "👑", DoubleCoins = "💰",
	Coins1 = "💵", Coins2 = "💰", Coins3 = "💎", CallRain = "🌧️", ServerBoost = "🚀",
}

local TONES = {
	purple = { top = K.PurpleTop, bot = K.PurpleBot, stroke = K.Outline, sub = C(238, 228, 250) },
	gold = { top = K.GoldTop, bot = K.GoldBot, stroke = K.GoldDark, sub = C(255, 247, 220) },
}

local BTN_W = 92
local TAB_H, SUB_H, MSG_H = 48, 22, 22
local SCROLL_Y = TAB_H + 8 + SUB_H + 4 -- 82

local function num(n: number): string -- 1234 -> "1,234"
	local s = tostring(math.floor(n + 0.5))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- "18 speed", "x1.4 power", "13% haze resist" from the track's own fmt (pct tracks are stored 0..1)
local function trackText(t, level: number): string
	local v = Config.TrackValue(t, level)
	if t.pct then v *= 100 end
	if t.fmt:find("%%d") then v = math.floor(v + 0.5) end
	return t.fmt:format(v)
end

local function coinCount(): number
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Coins")
	return c and c.Value or 0
end

local function scaledText(lbl: TextLabel, maxSize: number, minSize: number)
	lbl.TextScaled = true
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = minSize, Parent = lbl })
end

-- the one item that carries the "NEXT GOAL" badge: N95 first, then the two cheap rides, then the next hose tier
local function nextGoal(): string?
	if (player:GetAttribute("MaskTier") or 0) < 3 then return "Mask3" end
	if player:GetAttribute("Ride_Bicycle") ~= true then return "Ride_Bicycle" end
	if player:GetAttribute("Ride_Kapcai") ~= true then return "Ride_Kapcai" end
	local nxt = (player:GetAttribute("HoseOwned") or 1) + 1
	if nxt <= #Config.Hoses then return "Hose" .. nxt end
	return nil
end

local passByKey = {}
for _, p in Config.Passes do passByKey[p.key] = p end

function ShopUI.new(opt)
	local playSound = opt.playSound
	local modal = UI.Modal(opt.parent, { name = "Shop", title = "KEDAI · SHOP", width = 620, height = 400, titleSize = 36 })
	local panel = modal.Panel

	local refreshers: { () -> () } = {}
	local scrollers: { [string]: ScrollingFrame } = {}
	local tabButtons: { [string]: TextButton } = {}
	local cardFrames: { [string]: Frame } = {}
	local currentTab = "Upgrades"
	local currentGoal: string? = nil

	---------------------------------------------------------------- header: subtitle, coins, message
	local subLabel = UI.Text({ Name = "Sub", Size = UDim2.new(1, -116, 0, SUB_H), Position = UDim2.fromOffset(2, TAB_H + 8), TextXAlignment = LEFT, Parent = panel })
	scaledText(subLabel, 15, 10)
	local coinLabel = UI.Text({ Name = "Coins", Size = UDim2.fromOffset(112, SUB_H), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, TAB_H + 8), TextColor3 = K.Number, TextXAlignment = Enum.TextXAlignment.Right, Parent = panel })
	scaledText(coinLabel, 17, 11)
	local msgLabel = UI.Text({ Name = "Msg", Size = UDim2.new(1, 0, 0, MSG_H), Parent = panel })
	scaledText(msgLabel, 15, 10)
	local msgToken = 0
	local function setMsg(msg: string?, kind: string?)
		msgToken += 1
		msgLabel.Text = msg or ""
		msgLabel.TextColor3 = kind == "ok" and K.Number or (kind == "bad" and C(205, 80, 50) or K.Outline)
		local token = msgToken
		task.delay(5, function()
			if token == msgToken then msgLabel.Text = "" end
		end)
	end

	---------------------------------------------------------------- purchase calls
	local busy = false
	local function invoke(action: string, arg: any)
		if busy then return end
		busy = true
		local called, ok, msg = pcall(function() return Remotes.Shop:InvokeServer(action, arg) end)
		busy = false
		if not called then
			setMsg("Shop is busy, try again · Cuba lagi", "bad")
			return
		end
		if msg == "__prompted" then
			msgLabel.Text = "" -- Roblox's own purchase window is open; nothing to add
			return
		end
		if msg == "Coming soon!" then
			setMsg("Coming soon! · Akan datang", "info")
		else
			setMsg(msg or "", ok and "ok" or "bad")
			if ok then playSound("Success") end
		end
	end

	---------------------------------------------------------------- cards
	local function makeScroller(key: string): ScrollingFrame
		local s = new("ScrollingFrame", {
			Name = key, Position = UDim2.fromOffset(0, SCROLL_Y), Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 6, ScrollBarImageColor3 = K.PurpleBot, ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = panel,
		}, {
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			new("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }),
		})
		scrollers[key] = s
		return s
	end

	-- one purple (or gold) row: icon, name, BM name, info strip, and either a buy button or a status badge
	local function card(scroller: Instance, order: number, stripH: number, o)
		local t = TONES[o.tone or "purple"]
		local height = 64 + stripH + 8
		local f = new("Frame", {
			Name = o.name or o.en, Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = order, Parent = scroller,
		}, { UI.Corner(16), UI.Stroke(t.stroke, 3), UI.Gradient(t.top, t.bot), UI.Gloss(14) })
		local icon = UI.IconBox({ Name = "Icon", Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(10, 8), Parent = f }, Config.Icons[o.icon], EMOJI[o.icon])
		if o.tint then icon.BackgroundColor3 = o.tint end
		local textW = -(68 + BTN_W + 18)
		local title = UI.Text({ Name = "Title", Text = o.en, Size = UDim2.new(1, textW, 0, 26), Position = UDim2.fromOffset(68, 6), TextColor3 = WHITE, TextXAlignment = LEFT, Parent = f })
		scaledText(title, 19, 11)
		UI.TextStroke(t.stroke, 1.5).Parent = title
		local sub = UI.Text({ Name = "Sub", Text = o.bm or "", Size = UDim2.new(1, textW, 0, 16), Position = UDim2.fromOffset(68, 32), TextColor3 = t.sub, TextXAlignment = LEFT, Parent = f })
		scaledText(sub, 13, 9)
		local stripBox = new("Frame", {
			Name = "Strip", Size = UDim2.new(1, -20, 0, stripH), Position = UDim2.fromOffset(10, 64), BackgroundColor3 = t.stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = f,
		}, { UI.Corner(8), UI.Pad(0) })
		local strip = UI.Text({ Name = "Text", Text = o.strip or "", Size = UDim2.new(1, -14, 1, -4), Position = UDim2.fromOffset(7, 2), TextColor3 = WHITE, TextWrapped = true, RichText = true, TextXAlignment = LEFT, Parent = stripBox })
		scaledText(strip, 14, 9)
		local btn = UI.Button(o.kind or "green", "", { Name = "Buy", Size = UDim2.fromOffset(BTN_W, 44), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Parent = f }, 17)
		local badge = UI.Badge("green", "OWNED", { Name = "Badge", Size = UDim2.fromOffset(BTN_W, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 15), Visible = false, Parent = f }, 15)
		local goal = UI.Badge("gold", "NEXT GOAL · SASARAN", { Name = "Goal", Size = UDim2.fromOffset(156, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0, 0), Visible = false, ZIndex = 3, Parent = f }, 12)
		for _, d in goal:GetDescendants() do
			if d:IsA("GuiObject") then d.ZIndex = 3 end
		end
		local c = { frame = f, icon = icon, title = title, sub = sub, strip = strip, btn = btn, badge = badge, goal = goal, act = nil :: (() -> ())? }
		btn.Activated:Connect(function()
			if btn:GetAttribute("Disabled") then return end
			if c.act then c.act() end
		end)
		if o.name then cardFrames[o.name] = f end
		return c
	end

	-- state helpers: a buy/equip button (ok / muted when unaffordable / off when locked) or a status badge
	local function showBtn(c, label: string, kind: string, state: string, act: (() -> ())?)
		c.badge.Visible = false
		c.btn.Visible = true
		UI.SetKind(c.btn, kind)
		c.btn.Label.Text = label
		UI.SetEnabled(c.btn, state ~= "off")
		UI.SetMuted(c.btn, state == "muted")
		c.act = act
	end
	local function showBadge(c, label: string, kind: string)
		c.btn.Visible = false
		c.badge.Visible = true
		UI.SetBadge(c.badge, kind, label)
		c.act = nil
	end
	local function coinState(price: number): string
		return coinCount() < price and "muted" or "ok"
	end

	local function note(scroller: Instance, order: number, h: number, msg: string)
		local f = new("Frame", { Name = "Note", Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = K.Tint, BorderSizePixel = 0, LayoutOrder = order, Parent = scroller }, {
			UI.Corner(12), UI.Stroke(K.Outline, 2),
		})
		local t = UI.Text({ Text = msg, Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), TextColor3 = K.Outline, TextWrapped = true, RichText = true, TextXAlignment = LEFT, Parent = f })
		scaledText(t, 14, 9)
		return f
	end

	local function header(scroller: Instance, order: number, msg: string)
		local t = UI.Text({ Name = "Header", Text = msg, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order, TextColor3 = K.Outline, TextXAlignment = LEFT, Parent = scroller })
		scaledText(t, 17, 11)
	end

	---------------------------------------------------------------- Upgrades
	do
		local sc = makeScroller("Upgrades")
		for i, t in Config.Tracks do
			local c = card(sc, i, 24, { en = t.en, bm = t.bm, icon = t.icon })
			local pips = UI.Pips(Config.TrackMaxLevel, { Position = UDim2.fromOffset(68, 50), Size = UDim2.fromOffset(130, 10), Parent = c.frame }, 11, 8)
			table.insert(refreshers, function()
				local lvl = player:GetAttribute("Track_" .. t.id) or 1
				c.sub.Text = ("%s · Lv.%d/%d"):format(t.bm, lvl, Config.TrackMaxLevel)
				UI.SetPips(pips, lvl)
				local cost = Config.TrackCost(t, lvl)
				if cost then
					c.strip.Text = ("%s  →  <font color='#C9FFD2'>%s</font>"):format(trackText(t, lvl), trackText(t, lvl + 1))
					showBtn(c, "💰 " .. num(cost), "green", coinState(cost), function() invoke("BuyTrack", t.id) end)
				else
					c.strip.Text = trackText(t, lvl) .. "  (max · penuh)"
					showBadge(c, "MAX", "gold")
				end
			end)
		end
	end

	---------------------------------------------------------------- Hoses
	do
		local sc = makeScroller("Hoses")
		for i, h in Config.Hoses do
			local parts = {}
			if h.power > 1 then table.insert(parts, ("⚡ +%d%% power"):format(math.floor((h.power - 1) * 100 + 0.5))) end
			if h.radius > 0 then table.insert(parts, ("↔ wider spray +%d"):format(h.radius)) end
			if h.peatSoak > 1 then table.insert(parts, ("♨️ peat soaks %dx faster"):format(h.peatSoak)) end
			if h.tankMul > 1 then table.insert(parts, ("🛢️ +%d%% tank"):format(math.floor((h.tankMul - 1) * 100 + 0.5))) end
			local strip = #parts > 0 and table.concat(parts, "   ") or "Base power · no bonuses"
			local c = card(sc, i, 38, { en = h.en, icon = h.icon, tone = h.legendary and "gold" or "purple", strip = strip })
			c.sub.Text = ("%s · Tier %d%s"):format(h.bm, i, h.legendary and " · LEGENDARY" or "")
			table.insert(refreshers, function()
				local owned = player:GetAttribute("HoseOwned") or 1
				local eq = player:GetAttribute("HoseTier") or 1
				c.goal.Visible = currentGoal == "Hose" .. i
				if i <= owned then
					if i == eq then
						showBadge(c, "EQUIPPED", "green")
					else
						showBtn(c, "Equip", "green", "ok", function() invoke("EquipHose", i) end)
					end
				elseif i == owned + 1 then
					showBtn(c, "💰 " .. num(h.price), "green", coinState(h.price), function() invoke("BuyHose", i) end)
				else
					showBtn(c, "Locked", "green", "off", nil)
				end
			end)
		end
	end

	---------------------------------------------------------------- Gear
	do
		local sc = makeScroller("Gear")
		note(sc, 0, 52, "😷  <b>Honest note:</b> cloth masks don't filter fine haze particles well; a snug N95 does. Pakai N95 untuk perlindungan sebenar.")
		for i, m in Config.Masks do
			local strip = ("%d%% haze resist"):format(math.floor(m.resist * 100 + 0.5))
			if m.noCough then strip ..= "   ·   no coughing" end
			if m.noSlow then strip ..= "   ·   no haze slowdown" end
			local c = card(sc, i, 24, { en = m.en, bm = m.bm, icon = m.icon, strip = strip, tint = Config.MaskColors[i] })
			table.insert(refreshers, function()
				local tier = player:GetAttribute("MaskTier") or 0
				c.goal.Visible = currentGoal == "Mask" .. i
				if i <= tier then
					showBadge(c, "OWNED", "green")
				else
					showBtn(c, "💰 " .. num(m.price), "green", coinState(m.price), function() invoke("BuyMask", i) end)
				end
			end)
		end
	end

	---------------------------------------------------------------- Rides
	local selectTab -- forward: the Truck row jumps to the Premium tab
	do
		local sc = makeScroller("Rides")
		note(sc, 0, 40, "🚲  Rides can't spray: hop off to fight (the fire truck can). Turun untuk menyembur.")
		local speedTrack
		for _, t in Config.Tracks do
			if t.id == "Speed" then speedTrack = t end
		end
		for i, r in Config.Rides do
			local c = card(sc, i, 24, { en = r.en, bm = r.bm, icon = r.icon })
			local pass = r.pass and passByKey[r.pass]
			table.insert(refreshers, function()
				local run = speedTrack and math.floor(Config.TrackValue(speedTrack, player:GetAttribute("Track_Speed") or 1) + 0.5) or 0
				if pass then
					c.strip.Text = ("Game Pass  ·  speed %d  ·  roof cannon puts out nearby fires"):format(r.speed)
				else
					c.strip.Text = ("Top speed %d  ·  you run at %d"):format(r.speed, run)
				end
				c.goal.Visible = currentGoal == "Ride_" .. r.id
				if player:GetAttribute("Ride_" .. r.id) == true then
					showBadge(c, "OWNED", "green")
				elseif pass then
					showBtn(c, "R$ " .. num(pass.robux), "gold", "ok", function() selectTab("Premium", pass.key) end)
				else
					showBtn(c, "💰 " .. num(r.price), "green", coinState(r.price), function() invoke("BuyRide", r.id) end)
				end
			end)
		end
	end

	---------------------------------------------------------------- Premium
	do
		local sc = makeScroller("Premium")
		header(sc, 0, "Game Passes · Pas Permainan")
		for i, p in Config.Passes do
			local c = card(sc, i, 38, { en = p.en, bm = p.bm, icon = p.icon, strip = p.desc or "", name = "Pass_" .. p.key })
			table.insert(refreshers, function()
				if player:GetAttribute("Pass_" .. p.key) == true then
					showBadge(c, "OWNED", "green")
				else
					showBtn(c, "R$ " .. num(p.robux), "gold", "ok", function() invoke("BuyPass", p.key) end)
				end
			end)
		end
		header(sc, 100, "Items · Barang")
		for i, p in Config.Products do
			local strip = p.coins and ("+%s coins, instantly · terus ke akaun"):format(num(p.coins)) or (p.desc or "")
			local c = card(sc, 100 + i, 38, { en = p.en, bm = p.bm, icon = p.icon, strip = strip })
			table.insert(refreshers, function()
				showBtn(c, "R$ " .. num(p.robux), "gold", "ok", function() invoke("BuyProduct", p.key) end)
			end)
		end
	end

	---------------------------------------------------------------- refresh
	local function refresh()
		coinLabel.Text = "💰 " .. num(coinCount())
		currentGoal = nextGoal()
		for _, fn in refreshers do fn() end
	end

	local pending = false
	local function queueRefresh()
		if pending or not modal.IsOpen() then return end
		pending = true
		task.defer(function()
			pending = false
			refresh()
		end)
	end
	local WATCHED = { HoseOwned = true, HoseTier = true, MaskTier = true }
	player.AttributeChanged:Connect(function(name)
		if WATCHED[name] or name:sub(1, 6) == "Track_" or name:sub(1, 5) == "Ride_" or name:sub(1, 5) == "Pass_" then
			queueRefresh()
		end
	end)
	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 60)
		local coins = ls and ls:WaitForChild("Coins", 10)
		if coins then coins.Changed:Connect(queueRefresh) end
	end)

	---------------------------------------------------------------- tabs
	local TABS = {
		{ key = "Upgrades", label = "Upgrades", emoji = "⬆️", sub = "Upgrades · Naik Taraf  (permanent, saved)" },
		{ key = "Hoses", label = "Hoses", emoji = "🧯", sub = "Hoses · Hos  (equip any you own)" },
		{ key = "Gear", label = "Gear", emoji = "😷", sub = "Gear · Peralatan  (protect your lungs)" },
		{ key = "Rides", label = "Rides", emoji = "🚲", sub = "Rides · Tunggangan  (get around faster)" },
		{ key = "Premium", label = "Premium", emoji = "⭐", sub = "Premium · Robux  (optional extras)" },
	}
	local tabBar = new("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, TAB_H), BackgroundTransparency = 1, Parent = panel })
	for i, tab in TABS do
		local b = UI.Button("purple", "", { Name = tab.key, Size = UDim2.new(0.2, -4, 1, 0), Position = UDim2.new((i - 1) * 0.2, 2, 0, 0), Parent = tabBar }, 13)
		local lbl = b.Label :: TextLabel
		lbl.RichText = true
		lbl.LineHeight = 0.9
		lbl.Text = ('<font size="21">%s</font>\n%s'):format(tab.emoji, tab.label)
		lbl:FindFirstChildOfClass("UIStroke").Thickness = 1.5
		b.Activated:Connect(function() selectTab(tab.key) end)
		tabButtons[tab.key] = b
	end

	function selectTab(key: string, focusCard: string?)
		currentTab = key
		for _, tab in TABS do
			local on = tab.key == key
			scrollers[tab.key].Visible = on
			UI.SetKind(tabButtons[tab.key], on and "green" or "purple")
			if on then subLabel.Text = tab.sub end
		end
		local sc = scrollers[key]
		sc.CanvasPosition = Vector2.zero
		if focusCard then
			local target = cardFrames["Pass_" .. focusCard]
			if target then
				task.defer(function()
					sc.CanvasPosition = Vector2.new(0, math.max(0, target.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 4))
					local st = target:FindFirstChildOfClass("UIStroke")
					if st then
						st.Color = WHITE
						TweenService:Create(st, TweenInfo.new(1.4), { Color = K.Outline }):Play()
					end
				end)
			end
		end
	end

	---------------------------------------------------------------- layout
	local api = { Modal = modal }

	-- phones: panel as wide as the screen; height chosen so the modal's own fit-scale stays >= 0.85
	function api.Layout()
		local vp = camera.ViewportSize
		local w = vp.X < 470 and math.max(300, math.floor(vp.X - 20)) or 620
		local h = math.clamp(math.floor((vp.Y - 16) / 0.85) - 86, 270, 470)
		modal.SetSize(w, h)
		local scrollH = h - 40 - SCROLL_Y - 4 - MSG_H
		for _, s in scrollers do s.Size = UDim2.new(1, 0, 0, scrollH) end
		msgLabel.Position = UDim2.fromOffset(0, SCROLL_Y + scrollH + 4)
		if modal.IsOpen() then modal.Refit() end
	end

	-- call before opening: sizes the panel and brings every card up to date
	function api.Prepare(tab: string?)
		api.Layout()
		refresh()
		msgLabel.Text = ""
		selectTab(tab or currentTab)
	end
	api.Refresh = refresh
	api.Select = selectTab

	selectTab("Upgrades")
	api.Layout()
	refresh()
	return api
end

return ShopUI
