-- Crew list under the coins pill: up to 5 other players with health, water %, ride icon, and a red
-- "REVIVE!" state (with distance) while they are Downed. Collapsible; hidden when you are alone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local J = RS:WaitForChild("Jerebu")
local UI = require(J:WaitForChild("UIStyle"))
local Config = require(J:WaitForChild("Config"))

local K, new, C = UI.Colors, UI.New, Color3.fromRGB
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right

local MAX_ROWS = 5
local ROW_H, ROW_GAP, HEAD_H = 40, 4, 26
local RIDE_EMOJI = { Bicycle = "🚲", Kapcai = "🛵", Truck = "🚒" }
local RED = C(200, 40, 50)
local DARK_TRACK = C(53, 32, 78)

local CrewUI = {}

local function healthColor(ratio: number): Color3
	if ratio <= 0.25 then return C(226, 70, 80) end
	if ratio <= 0.5 then return C(240, 175, 50) end
	return K.GreenTop
end

function CrewUI.new(parent: GuiObject, opts: { width: number?, layoutOrder: number?, getPlayers: (() -> { any })? }?)
	local me = Players.LocalPlayer
	local getPlayers = opts and opts.getPlayers or function() return Players:GetPlayers() end -- override is for tests
	local width = opts and opts.width or 190
	local collapsed = false

	local card = UI.Card({ Name = "Crew", Size = UDim2.fromOffset(width, HEAD_H), LayoutOrder = opts and opts.layoutOrder or 6, Visible = false, Parent = parent }, 14)
	local head = new("TextButton", { Name = "Header", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEAD_H), Parent = card })
	local headLabel = UI.Text({ Text = "CREW · KRU", Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0), TextSize = 12, TextColor3 = K.InkSoft, TextXAlignment = LEFT, Parent = head })
	local toggle = UI.Text({ Text = "−", Font = Enum.Font.GothamBold, Size = UDim2.fromOffset(26, HEAD_H), Position = UDim2.new(1, -30, 0, 0), TextSize = 20, TextColor3 = K.Outline, Parent = head })

	local rowsHolder = new("Frame", { Name = "Rows", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.fromOffset(8, HEAD_H), Parent = card }, {
		new("UIListLayout", { Padding = UDim.new(0, ROW_GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local rows: { [Player]: any } = {}

	local function makeRow(p: Player)
		local f = new("Frame", { Name = p.Name, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = K.Tint, BorderSizePixel = 0, Parent = rowsHolder }, { UI.Corner(10) })
		local st = UI.Stroke(K.Outline, 2)
		st.Transparency = 0.6
		st.Parent = f
		local name = UI.Text({ Text = p.DisplayName, Size = UDim2.new(1, -32, 0, 18), Position = UDim2.fromOffset(7, 2), TextSize = 13, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
		-- ride icon (image when Config.Icons has one, else emoji)
		local rideHolder = new("Frame", { Name = "Ride", Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -25, 0, 3), BackgroundTransparency = 1, Visible = false, Parent = f })
		local rideImg = new("ImageLabel", { Name = "Img", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = rideHolder })
		local rideEmoji = UI.Text({ Name = "Emoji", Text = "", Font = Enum.Font.GothamBold, Size = UDim2.fromScale(1, 1), TextSize = 16, Parent = rideHolder })
		UI.ImageFallback(rideImg, rideEmoji)
		-- bars row
		local bars = new("Frame", { Name = "Bars", Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(7, 22), BackgroundTransparency = 1, Parent = f })
		local track = new("Frame", { Name = "Track", Size = UDim2.new(0.58, 0, 0, 9), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = DARK_TRACK, BorderSizePixel = 0, Parent = bars }, { UI.Corner(5) })
		local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = K.GreenTop, BorderSizePixel = 0, Parent = track }, { UI.Corner(5) })
		local water = UI.Text({ Name = "Water", Text = "💧 100%", Size = UDim2.new(0.42, -6, 1, 0), Position = UDim2.new(0.58, 6, 0, 0), TextSize = 12, TextColor3 = C(30, 120, 220), TextXAlignment = RIGHT, Parent = bars })
		local alert = UI.Text({ Name = "Alert", Text = "REVIVE!", Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(7, 20), TextSize = 15, TextColor3 = RED, TextXAlignment = LEFT, Visible = false, Parent = f })
		local dist = UI.Text({ Name = "Dist", Text = "", Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 20), TextSize = 13, TextColor3 = RED, TextXAlignment = RIGHT, Visible = false, Parent = f })
		local row = { frame = f, stroke = st, name = name, rideHolder = rideHolder, rideImg = rideImg, rideEmoji = rideEmoji, bars = bars, fill = fill, water = water, alert = alert, dist = dist, downed = false }
		rows[p] = row
		return row
	end

	local function dropRow(p: Player)
		local r = rows[p]
		if r then
			r.frame:Destroy()
			rows[p] = nil
		end
	end

	local function refit(count: number)
		local h = HEAD_H
		if not collapsed and count > 0 then
			h += count * ROW_H + (count - 1) * ROW_GAP + 8
		end
		card.Size = UDim2.fromOffset(width, h)
		rowsHolder.Visible = not collapsed
		toggle.Text = collapsed and "+" or "−"
	end

	local shownCount = -1
	local function update()
		local others = {}
		for _, p in getPlayers() do
			if p ~= me then table.insert(others, p) end
		end
		for p in rows do
			if not table.find(others, p) then dropRow(p) end
		end
		local myRoot = me.Character and me.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local info = {}
		for _, p in others do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local d = (root and myRoot) and (root.Position - myRoot.Position).Magnitude or math.huge
			table.insert(info, { player = p, dist = d, downed = p:GetAttribute("Downed") == true })
		end
		-- downed teammates first, then nearest
		table.sort(info, function(a, b)
			if a.downed ~= b.downed then return a.downed end
			return a.dist < b.dist
		end)
		local shown = {}
		for i = 1, math.min(MAX_ROWS, #info) do shown[info[i].player] = i end
		for p in rows do
			if not shown[p] then dropRow(p) end
		end

		card.Visible = #others > 0
		local anyDowned = false
		for _, e in info do
			if e.downed then anyDowned = true end
		end
		headLabel.Text = anyDowned and "REVIVE NEEDED!" or ("CREW · KRU  (%d)"):format(#others)
		headLabel.TextColor3 = anyDowned and RED or K.InkSoft
		for i = 1, math.min(MAX_ROWS, #info) do
			local e = info[i]
			local p = e.player
			local r = rows[p] or makeRow(p)
			r.frame.LayoutOrder = i
			r.name.Text = p.DisplayName
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			local ratio = hum and hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
			local cap = p:GetAttribute("MaxWater") or 100
			local wf = math.clamp((p:GetAttribute("Water") or cap) / math.max(cap, 1), 0, 1)
			if p:GetAttribute("InfiniteWater") == true then wf = 1 end
			r.fill.Size = UDim2.fromScale(ratio, 1)
			r.fill.BackgroundColor3 = healthColor(ratio)
			r.water.Text = ("💧 %d%%"):format(math.floor(wf * 100 + 0.5))
			r.water.TextColor3 = wf <= 0.05 and C(210, 70, 50) or C(30, 120, 220)
			local ride = p:GetAttribute("Riding") or ""
			r.rideHolder.Visible = ride ~= ""
			if ride ~= "" then
				local cfg
				for _, rc in Config.Rides do if rc.id == ride then cfg = rc end end
				local img = cfg and Config.Icons[cfg.icon] or ""
				r.rideImg.Image = img
				r.rideImg.Visible = img ~= ""
				r.rideEmoji.Text = RIDE_EMOJI[ride] or "🚲"
			end
			r.downed = e.downed
			r.bars.Visible = not e.downed
			r.alert.Visible = e.downed
			r.dist.Visible = e.downed
			if e.downed then
				r.dist.Text = e.dist < math.huge and ("%dm"):format(e.dist // 1) or ""
				r.frame.BackgroundColor3 = C(255, 228, 226)
				r.stroke.Color = RED
				r.stroke.Transparency = 0
			else
				r.frame.BackgroundColor3 = K.Tint
				r.stroke.Color = K.Outline
				r.stroke.Transparency = 0.6
				r.stroke.Thickness = 2
			end
		end
		local count = math.min(MAX_ROWS, #info)
		if count ~= shownCount then
			shownCount = count
			refit(count)
		end
	end

	head.Activated:Connect(function()
		collapsed = not collapsed
		UI.PlayClick()
		refit(math.max(shownCount, 0))
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.15 then
			acc = 0
			update()
		end
		-- gentle pulse on a collapsing teammate's row
		local pulse = 2.5 + 1.5 * math.sin(os.clock() * 5)
		for _, r in rows do
			if r.downed then r.stroke.Thickness = pulse end
		end
	end)
	Players.PlayerRemoving:Connect(function(p) dropRow(p) end)
	update()

	local api = { Card = card }
	function api.SetWidth(w: number)
		width = w
		refit(math.max(shownCount, 0))
	end
	return api
end

return CrewUI
