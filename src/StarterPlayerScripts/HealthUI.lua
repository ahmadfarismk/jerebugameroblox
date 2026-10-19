-- Native, responsive health meter. Optional uploaded art: set this ModuleScript's
-- HeartImage attribute to rbxassetid://... for assets/bahaya-jerebu/health/60-health-heart.png.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Jerebu"):WaitForChild("UIStyle"))
local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("Jerebu"):WaitForChild("ImageAssets"))
local K, new = UI.Colors, UI.New
local HealthUI = {}

-- parent: the right-hand HUD column (a list layout stacks it under the API card).
-- Returns box, setWidth(w) (keeps it as wide as the column).
function HealthUI.new(parent: GuiObject, opts: { width: number?, layoutOrder: number? }?)
	local player = Players.LocalPlayer
	local width = opts and opts.width or 220
	local box = new("Frame", { Name = "Health", Size = UDim2.fromOffset(width, 40), LayoutOrder = opts and opts.layoutOrder or 2, BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = parent }, {
		UI.Corner(18), UI.Stroke(K.Outline, 3), UI.Gradient(K.PurpleTop, K.PurpleBot),
	})
	local heart = UI.Text({ Name = "HeartFallback", Text = "♥", Font = Enum.Font.GothamBold, TextSize = 34, TextColor3 = Color3.fromRGB(255, 70, 90), Size = UDim2.fromOffset(44, 40), Parent = box })
	UI.TextStroke(K.Outline, 2).Parent = heart
	local art = new("ImageLabel", { Name = "HeartImage", Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(2, 0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = box })
	local function refreshArt()
		local id = script:GetAttribute("HeartImage") or Assets.Heart
		art.Image = type(id) == "string" and id or ""
		art.Visible = art.Image ~= ""
		heart.Visible = not (art.Visible and art.IsLoaded)
	end
	local artChanged = script:GetAttributeChangedSignal("HeartImage"):Connect(refreshArt)
	local artLoaded = UI.ImageFallback(art, heart)
	refreshArt()
	local track = new("Frame", { Name = "Track", Position = UDim2.fromOffset(46, 7), Size = UDim2.new(1, -54, 1, -14), BackgroundColor3 = Color3.fromRGB(53, 32, 78), BorderSizePixel = 0, Parent = box }, { UI.Corner(12) })
	local clip = new("Frame", { Name = "FillClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = track })
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = clip }, { UI.Corner(12), UI.Gradient(K.GreenTop, K.GreenBot), UI.Gloss(10) })
	local gradient = fill:FindFirstChildOfClass("UIGradient")
	local label = UI.Text({ Name = "Value", Text = "HEALTH  —", Size = UDim2.fromScale(1, 1), TextSize = 15, TextColor3 = K.White, ZIndex = 3, Parent = track })
	UI.TextStroke(K.Outline, 1.5).Parent = label
	-- Keep the fill at full track width and reveal it through a rectangular clip.
	-- This avoids a rounded end or minimum corner width overstating very low health.
	local function sizeFill() fill.Size = UDim2.fromOffset(track.AbsoluteSize.X / math.max(box.AbsoluteSize.X / box.Size.X.Offset, 0.01), 26) end
	local sizeConnection = track:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeFill)
	sizeFill()
	local function setWidth(w: number)
		box.Size = UDim2.fromOffset(w, 40)
		sizeFill()
	end
	local connections = {}
	local tween = nil
	local generation = 0
	local disposed = false
	local function disconnectHumanoid()
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		if tween then tween:Cancel() tween = nil end
	end
	local function bind(character)
		generation += 1
		local token = generation
		disconnectHumanoid()
		label.Text = "HEALTH  —"
		clip.Size = UDim2.fromScale(0, 1)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if disposed or token ~= generation or player.Character ~= character or not humanoid then return end
		local function update(instant)
			local maxHealth = math.max(0, humanoid.MaxHealth)
			local health = math.clamp(humanoid.Health, 0, maxHealth)
			local ratio = maxHealth > 0 and health / maxHealth or 0
			local top, bottom = K.GreenTop, K.GreenBot
			if ratio <= 0.25 then
				top, bottom = Color3.fromRGB(255, 99, 99), Color3.fromRGB(211, 46, 66)
			elseif ratio <= 0.5 then
				top, bottom = Color3.fromRGB(255, 205, 77), Color3.fromRGB(222, 144, 30)
			end
			gradient.Color = ColorSequence.new(top, bottom)
			label.Text = health <= 0 and "RESPAWNING..." or ((ratio <= 0.25 and "LOW HP  " or "HEALTH  ") .. ("%d / %d"):format(math.ceil(health), math.ceil(maxHealth)))
			box:SetAttribute("HealthRatio", ratio)
			if tween then tween:Cancel() end
			if instant or health <= 0 then
				clip.Size = UDim2.fromScale(ratio, 1)
			else
				tween = TweenService:Create(clip, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(ratio, 1) })
				tween:Play()
			end
		end
		table.insert(connections, humanoid.HealthChanged:Connect(function() update(false) end))
		table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function() update(false) end))
		update(true)
	end
	local added = player.CharacterAdded:Connect(function(character) task.spawn(bind, character) end)
	local removing = player.CharacterRemoving:Connect(function()
		generation += 1
		disconnectHumanoid()
		clip.Size = UDim2.fromScale(0, 1)
		box:SetAttribute("HealthRatio", 0)
		label.Text = "RESPAWNING..."
	end)
	if player.Character then task.spawn(bind, player.Character) end
	local wasEnabled = true
	pcall(function() wasEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) end)
	task.spawn(function()
		for _ = 1, 10 do
			if disposed then return end
			if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end) then return end
			task.wait(0.3)
		end
	end)
	box.Destroying:Connect(function()
		disposed = true
		generation += 1
		disconnectHumanoid()
		added:Disconnect()
		removing:Disconnect()
		sizeConnection:Disconnect()
		artChanged:Disconnect()
		artLoaded:Disconnect()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, wasEnabled) end)
	end)
	return box, setWidth
end

return HealthUI