-- Crew pings. Hold Q (desktop), tap the ping button (touch) or hold ButtonL1 (gamepad) to open a radial
-- menu: Fire, Water, Help, Follow. Release on an option to send it; a quick tap of Q / L1 sends a Fire
-- ping at the cursor (screen centre on touch / gamepad). Incoming pings become billboard markers for 8 s.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local UI = require(J:WaitForChild("UIStyle"))
local Assets = require(J:WaitForChild("ImageAssets"))
local Remotes = J:WaitForChild("Remotes")
local PingRemote = Remotes:WaitForChild("Ping")

local K, new, C = UI.Colors, UI.New, Color3.fromRGB
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local HOLD_TAP = 0.18 -- shorter than this = quick tap (Fire ping)
local RADIUS = 92
local DEAD_ZONE = 28
local MARKER_SECONDS = 8

-- kind -> look. Art comes from ImageAssets when it is there; the emoji is the readable fallback.
local KINDS = {
	Fire = { en = "Fire", bm = "Api", emoji = "🔥", image = Assets.Fire, color = C(235, 110, 40), dir = Vector2.new(0, -1) },
	Water = { en = "Water", bm = "Air", emoji = "💧", image = "", color = C(46, 160, 220), dir = Vector2.new(1, 0) },
	Help = { en = "Help", bm = "Tolong", emoji = "🆘", image = "", color = C(200, 40, 50), dir = Vector2.new(0, 1) },
	Follow = { en = "Follow", bm = "Ikut", emoji = "➡️", image = "", color = C(69, 198, 83), dir = Vector2.new(-1, 0) },
}
local ORDER = { "Fire", "Water", "Help", "Follow" }

local gui = new("ScreenGui", { Name = "JerebuPing", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })

---------------------------------------------------------------- aiming
local function rayParams(): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = { player.Character }
	return p
end

-- world point under a viewport position (cursor or screen centre)
local function aimAt(screen: Vector2): Vector3
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, rayParams())
	local pos = hit and hit.Position or (ray.Origin + ray.Direction * 120)
	-- the server ignores pings further than 500 studs from you
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local off = pos - root.Position
		if off.Magnitude > 480 then pos = root.Position + off.Unit * 480 end
	end
	return pos
end

local function screenCentre(): Vector2
	local vp = camera.ViewportSize
	return Vector2.new(vp.X / 2, vp.Y / 2)
end

local lastSend = -math.huge
local pingButton: TextButton? = nil
local function send(kind: string, pos: Vector3)
	if os.clock() - lastSend < Config.PingCooldown then return end
	lastSend = os.clock()
	PingRemote:FireServer(kind, pos)
	if pingButton then
		UI.SetMuted(pingButton, true)
		task.delay(Config.PingCooldown, function() UI.SetMuted(pingButton, false) end)
	end
end

---------------------------------------------------------------- wheel
local catcher = new("TextButton", { Name = "Catcher", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = gui })
local wheel = new("Frame", { Name = "Wheel", Size = UDim2.fromOffset(340, 340), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui })
local wheelScale = new("UIScale", { Parent = wheel })
local disc = new("Frame", { Name = "Disc", Size = UDim2.fromOffset(RADIUS * 2 + 70, RADIUS * 2 + 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C(34, 20, 52), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = wheel }, {
	UI.Corner(300), UI.Stroke(K.Outline, 3),
})
local hub = UI.Text({ Name = "Hub", Text = "PING", Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), TextSize = 18, TextColor3 = K.White, Parent = wheel })
UI.TextStroke(K.Outline, 2).Parent = hub

local options: { [string]: { holder: Frame, btn: TextButton, scale: UIScale, cap: TextLabel } } = {}
for _, kind in ORDER do
	local def = KINDS[kind]
	local holder = new("Frame", { Name = kind, Size = UDim2.fromOffset(84, 84), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, def.dir.X * RADIUS, 0.5, def.dir.Y * RADIUS), BackgroundTransparency = 1, Parent = wheel })
	local btn = UI.PurpleButton("", { Name = "Btn", Size = UDim2.fromOffset(72, 72), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = holder })
	btn:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 36)
	local gloss = btn:FindFirstChild("Gloss")
	if gloss then gloss.Visible = false end
	UI.IconBox({ Size = UDim2.fromOffset(46, 46), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = btn }, def.image, def.emoji).Name = "Icon"
	local cap = UI.Text({ Name = "Cap", Text = ("%s · %s"):format(def.en, def.bm), Size = UDim2.fromOffset(110, 16), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -2), TextSize = 13, TextColor3 = K.White, Parent = holder })
	UI.TextStroke(C(40, 24, 56), 2).Parent = cap
	local sc = new("UIScale", { Name = "Pick", Parent = holder })
	options[kind] = { holder = holder, btn = btn, scale = sc, cap = cap }
end

local aimRing = new("Frame", { Name = "AimRing", Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui }, {
	UI.Corner(9), UI.Stroke(K.White, 2),
})

local state: { source: string, t0: number, centre: Vector2, aim: Vector3, shown: boolean, pick: string? }? = nil

local function setPick(kind: string?)
	if not state or state.pick == kind then return end
	state.pick = kind
	for k, o in options do
		local on = k == kind
		UI.SetKind(o.btn, on and "green" or "purple")
		TweenService:Create(o.scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Scale = on and 1.18 or 1 }):Play()
	end
	hub.Text = kind and KINDS[kind].en:upper() or "PING"
end

local function modalOpen(): boolean
	local menus = playerGui:FindFirstChild("JerebuMenus")
	if menus then
		for _, m in menus:GetChildren() do
			if m:IsA("GuiObject") and m.Visible then return true end
		end
	end
	return false
end

local function showWheel(at: Vector2)
	local vp = camera.ViewportSize
	local half = RADIUS + 60
	local shown = Vector2.new(math.clamp(at.X, half, math.max(half, vp.X - half)), math.clamp(at.Y, half, math.max(half, vp.Y - half)))
	wheel.Position = UDim2.fromOffset(shown.X, shown.Y)
	wheel.Visible = true
	wheelScale.Scale = 0.8
	TweenService:Create(wheelScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function hideWheel()
	wheel.Visible = false
	catcher.Visible = false
	aimRing.Visible = false
	for _, o in options do
		o.scale.Scale = 1
		UI.SetKind(o.btn, "purple")
	end
	hub.Text = "PING"
end

local function begin(source: string, centre: Vector2)
	if state or modalOpen() then return end
	state = { source = source, t0 = os.clock(), centre = centre, aim = aimAt(centre), shown = false, pick = nil }
end

local function finish()
	local s = state
	state = nil
	hideWheel()
	if not s then return end
	if not s.shown then
		send("Fire", s.aim) -- quick tap
	elseif s.pick then
		send(s.pick, s.aim)
	end
end

local function pickFromVector(v: Vector2): string?
	if v.Magnitude < DEAD_ZONE then return nil end
	if math.abs(v.X) > math.abs(v.Y) then return v.X > 0 and "Water" or "Follow" end
	return v.Y < 0 and "Fire" or "Help"
end

local function padVector(): Vector2
	for _, input in UIS:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local p = input.Position
			if Vector2.new(p.X, p.Y).Magnitude > 0.5 then return Vector2.new(p.X, -p.Y) * 100 end
		end
	end
	return Vector2.zero
end

RunService.RenderStepped:Connect(function()
	local s = state
	if not s or s.source == "touch" then return end
	if not s.shown and os.clock() - s.t0 >= HOLD_TAP then
		s.shown = true
		showWheel(s.centre)
		if s.source == "key" then
			aimRing.Position = UDim2.fromOffset(s.centre.X, s.centre.Y)
			aimRing.Visible = true
		end
	end
	if s.shown then
		if s.source == "key" then
			setPick(pickFromVector(UIS:GetMouseLocation() - s.centre))
		else
			setPick(pickFromVector(padVector()))
		end
	end
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		begin("key", UIS:GetMouseLocation())
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
		begin("pad", screenCentre())
	end
end)

UIS.InputEnded:Connect(function(input)
	if not state then return end
	if (input.KeyCode == Enum.KeyCode.Q and state.source == "key") or (input.KeyCode == Enum.KeyCode.ButtonL1 and state.source == "pad") then
		finish()
	end
end)

---------------------------------------------------------------- touch: ping button + tappable wheel
for kind, o in options do
	o.btn.Activated:Connect(function()
		if state and state.source == "touch" then
			local s = state
			state = nil
			hideWheel()
			send(kind, s.aim)
		end
	end)
end
catcher.Activated:Connect(function()
	if state and state.source == "touch" then
		state = nil
		hideWheel()
	end
end)

local function openTouchWheel()
	if state then return end
	if modalOpen() then return end
	local c = screenCentre()
	state = { source = "touch", t0 = os.clock(), centre = c, aim = aimAt(c), shown = true, pick = nil }
	catcher.Visible = true
	showWheel(c - Vector2.new(0, 20))
end

pingButton = UI.PurpleButton("PING", { Name = "PingButton", Size = UDim2.fromOffset(58, 58), AnchorPoint = Vector2.new(0.5, 1), Visible = UIS.TouchEnabled, Parent = gui }, 15)
pingButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 29)
pingButton.Activated:Connect(openTouchWheel)

-- sit above Roblox's jump button (70 px at W-95 / top H-90 on small screens; 120 px at W-170 / top H-210)
local function placePingButton()
	local vp = camera.ViewportSize
	local small = math.min(vp.X, vp.Y) <= 500
	local jumpSize = small and 70 or 120
	local jumpX = vp.X - (small and 95 or 170)
	local jumpTop = vp.Y - (small and 90 or 210)
	pingButton.Position = UDim2.fromOffset(jumpX + jumpSize / 2, jumpTop - 12)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(placePingButton)
placePingButton()
-- losing window focus mid-hold never delivers the key release; drop the wheel instead of leaving it stuck
UIS.WindowFocusReleased:Connect(function()
	if state then
		state = nil
		hideWheel()
	end
end)

---------------------------------------------------------------- incoming pings
local markers: { [Player]: { gui: BillboardGui, att: Attachment, born: number, pos: Vector3, dist: TextLabel } } = {}

local function removeMarker(sender: Player)
	local m = markers[sender]
	if not m then return end
	markers[sender] = nil
	m.gui:Destroy()
	m.att:Destroy()
end

local function showPing(sender: Player, kind: string, pos: Vector3)
	local def = KINDS[kind]
	if not def or typeof(pos) ~= "Vector3" then return end
	removeMarker(sender)
	local att = new("Attachment", { Name = "Ping_" .. sender.UserId, Parent = workspace.Terrain })
	att.WorldPosition = pos
	local bb = new("BillboardGui", {
		Name = "PingMarker", Adornee = att, Size = UDim2.fromOffset(160, 104), StudsOffsetWorldSpace = Vector3.new(0, 6, 0),
		AlwaysOnTop = true, LightInfluence = 0, MaxDistance = math.huge, ResetOnSpawn = false, Parent = playerGui,
	})
	local pop = new("UIScale", { Scale = 0.3, Parent = bb })
	local ring = new("Frame", { Name = "Ring", Size = UDim2.fromOffset(52, 52), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(80, 28), BackgroundTransparency = 1, Parent = bb }, {
		UI.Corner(40), UI.Stroke(def.color, 4),
	})
	local ringStroke = ring:FindFirstChildOfClass("UIStroke") :: UIStroke
	TweenService:Create(ring, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), { Size = UDim2.fromOffset(104, 104) }):Play()
	TweenService:Create(ringStroke, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), { Transparency = 1 }):Play()
	local dot = new("Frame", { Name = "Dot", Size = UDim2.fromOffset(52, 52), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(80, 28), BackgroundColor3 = def.color, BorderSizePixel = 0, Parent = bb }, {
		UI.Corner(26), UI.Stroke(K.White, 3), new("UIGradient", { Rotation = 90, Color = ColorSequence.new(def.color:Lerp(K.White, 0.3), def.color:Lerp(Color3.new(0, 0, 0), 0.15)) }),
	})
	local icon = UI.IconBox({ Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = dot }, def.image, def.emoji)
	icon.BackgroundTransparency = 1
	local who = sender == player and "You" or sender.DisplayName
	local nameLbl = UI.Text({ Name = "Who", Text = ("%s · %s"):format(who, def.en), Size = UDim2.fromOffset(160, 18), Position = UDim2.fromOffset(0, 58), TextSize = 15, TextColor3 = K.White, Parent = bb })
	UI.TextStroke(C(24, 14, 36), 3).Parent = nameLbl
	local distLbl = UI.Text({ Name = "Dist", Text = "", Size = UDim2.fromOffset(160, 16), Position = UDim2.fromOffset(0, 77), TextSize = 14, TextColor3 = C(255, 236, 170), Parent = bb })
	UI.TextStroke(C(24, 14, 36), 3).Parent = distLbl
	TweenService:Create(pop, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	markers[sender] = { gui = bb, att = att, born = os.clock(), pos = pos, dist = distLbl }
	UI.PlayClick()
end

PingRemote.OnClientEvent:Connect(function(sender, kind, pos)
	if typeof(sender) == "Instance" and sender:IsA("Player") and typeof(kind) == "string" then
		showPing(sender, kind, pos)
	end
end)
Players.PlayerRemoving:Connect(removeMarker)

RunService.RenderStepped:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local now = os.clock()
	for sender, m in markers do
		local age = now - m.born
		if age >= MARKER_SECONDS then
			removeMarker(sender)
		else
			if root then m.dist.Text = ("%dm"):format((m.pos - root.Position).Magnitude // 1) end
			-- fade out through the last second
			local fade = age > MARKER_SECONDS - 1 and (age - (MARKER_SECONDS - 1)) or 0
			for _, d in m.gui:GetDescendants() do
				if d:IsA("TextLabel") then
					d.TextTransparency = fade
					local st = d:FindFirstChildOfClass("UIStroke")
					if st then st.Transparency = fade end
				end
			end
			local dot = m.gui:FindFirstChild("Dot")
			if dot then dot.BackgroundTransparency = fade end
		end
	end
end)
