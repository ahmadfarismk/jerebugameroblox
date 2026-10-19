-- Jerebu UI kit: native rebuild of the purple/green cartoon style (ui-reference/Nut_April_25.jpg).
-- HUD and menus call these builders instead of hand-styling.
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")

local UIStyle = {}
local C = Color3.fromRGB

UIStyle.Font = Enum.Font.FredokaOne

UIStyle.Colors = {
	White = C(255, 255, 255),
	PanelLow = C(228, 228, 232),
	Outline = C(91, 61, 125),
	PurpleTop = C(160, 108, 198),
	PurpleBot = C(122, 79, 166),
	PurpleTopDown = C(134, 88, 172),
	PurpleBotDown = C(100, 62, 140),
	GreenTop = C(69, 198, 83),
	GreenBot = C(32, 161, 46),
	GreenTopDown = C(52, 170, 65),
	GreenBotDown = C(24, 132, 36),
	GreenOutline = C(29, 122, 40),
	Wood = C(110, 74, 54),
	WoodOutline = C(70, 46, 34),
	Gold = C(255, 194, 26),
	GoldRim = C(205, 120, 20),
	StarEmpty = C(91, 61, 125),
	Number = C(45, 180, 67),
	Ink = C(70, 45, 100), -- body text on white
	InkSoft = C(122, 104, 146),
	Tint = C(240, 234, 248), -- pale purple box on white
	GoldTop = C(255, 214, 92), -- premium / legendary accent
	GoldBot = C(232, 150, 30),
	GoldTopDown = C(226, 178, 60),
	GoldBotDown = C(196, 120, 20),
	GoldDark = C(150, 92, 14),
}
local K = UIStyle.Colors

local GREY = { C(200, 194, 208), C(165, 157, 177), C(200, 194, 208), C(165, 157, 177), C(112, 102, 124) }
local PALETTE = {
	purple = { K.PurpleTop, K.PurpleBot, K.PurpleTopDown, K.PurpleBotDown, K.Outline },
	green = { K.GreenTop, K.GreenBot, K.GreenTopDown, K.GreenBotDown, K.GreenOutline },
	gold = { K.GoldTop, K.GoldBot, K.GoldTopDown, K.GoldBotDown, K.GoldDark },
}

---------------------------------------------------------------- primitives
function UIStyle.New(class: string, props: { [string]: any }?, children: { Instance }?): any
	local i = Instance.new(class)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then parent = v else (i :: any)[k] = v end
		end
	end
	if children then
		for _, c in children do c.Parent = i end
	end
	if parent then i.Parent = parent end
	return i
end
local New = UIStyle.New

function UIStyle.Corner(r: number): UICorner
	return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

function UIStyle.Pad(p: number): UIPadding
	return New("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) })
end

function UIStyle.Stroke(color: Color3, thick: number): UIStroke
	return New("UIStroke", { Color = color, Thickness = thick, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round })
end

-- outline around glyphs (big headings, white text on colour)
function UIStyle.TextStroke(color: Color3, thick: number): UIStroke
	return New("UIStroke", { Color = color, Thickness = thick, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round })
end

function UIStyle.Gradient(top: Color3, bottom: Color3): UIGradient
	return New("UIGradient", { Name = "Fill", Rotation = 90, Color = ColorSequence.new(top, bottom) })
end

-- thin glossy strip along the top inner edge
function UIStyle.Gloss(inset: number?): Frame
	local i = inset or 10
	return New("Frame", {
		Name = "Gloss", Size = UDim2.new(1, -i * 2, 0, 4), Position = UDim2.fromOffset(i, 3),
		BackgroundColor3 = K.White, BackgroundTransparency = 0.5, BorderSizePixel = 0,
	}, { UIStyle.Corner(2) })
end

function UIStyle.Text(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or UIStyle.Font
	props.TextColor3 = props.TextColor3 or K.Ink
	props.TextSize = props.TextSize or 16
	return New("TextLabel", props)
end

-- largest TextSize (maxSize..minSize) that keeps the text on one line within width (TextScaled wraps instead)
function UIStyle.FitText(lbl: TextLabel, width: number, maxSize: number, minSize: number?): number
	local size = maxSize
	local floor = minSize or 10
	while size > floor and TextService:GetTextSize(lbl.Text, size, lbl.Font, Vector2.new(10000, 1000)).X > width do
		size -= 1
	end
	lbl.TextScaled = false
	lbl.TextWrapped = false
	lbl.TextSize = size
	return size
end

-- right-pointing arrow built from bars (FredokaOne has no ➤); rotate the frame to aim it
function UIStyle.Arrow(props: { [string]: any }, color: Color3?, outline: Color3?): Frame
	props.BackgroundTransparency = 1
	local f = New("Frame", props)
	local function bar(name: string, w: number, x: number, y: number, rot: number)
		New("Frame", {
			Name = name, Size = UDim2.fromScale(w, 0.22), Position = UDim2.fromScale(x, y), AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot, BackgroundColor3 = color or K.White, BorderSizePixel = 0, Parent = f,
		}, { UIStyle.Corner(2), UIStyle.Stroke(outline or K.GreenOutline, 1) })
	end
	bar("Shaft", 0.8, 0.45, 0.5, 0)
	bar("HeadA", 0.5, 0.68, 0.34, 45)
	bar("HeadB", 0.5, 0.68, 0.66, -45)
	return f
end

---------------------------------------------------------------- panels
-- big kit panel: white body, lower part fades to grey, thick purple outline
function UIStyle.Panel(props: { [string]: any }, radius: number?): Frame
	props.BackgroundColor3 = K.White
	props.BorderSizePixel = 0
	local f = New("Frame", props)
	UIStyle.Corner(radius or 36).Parent = f
	UIStyle.Stroke(K.Outline, 5).Parent = f
	New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, K.White), ColorSequenceKeypoint.new(0.62, K.White),
			ColorSequenceKeypoint.new(0.68, K.PanelLow), ColorSequenceKeypoint.new(1, K.PanelLow),
		}),
		Parent = f,
	})
	return f
end

-- compact panel for the in-play HUD (thinner outline, softer fade)
function UIStyle.Card(props: { [string]: any }, radius: number?, thick: number?): Frame
	props.BackgroundColor3 = K.White
	props.BorderSizePixel = 0
	local f = New("Frame", props)
	UIStyle.Corner(radius or 14).Parent = f
	UIStyle.Stroke(K.Outline, thick or 3).Parent = f
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, K.White), ColorSequenceKeypoint.new(0.6, K.White), ColorSequenceKeypoint.new(1, C(236, 234, 240)),
	}), Parent = f })
	return f
end

---------------------------------------------------------------- feel
function UIStyle.PlayClick()
	local J = RS:FindFirstChild("Jerebu")
	local folder = J and J:FindFirstChild("Sounds")
	local t = folder and folder:FindFirstChild("Click")
	if t then
		local s = t:Clone()
		s.Parent = SoundService
		s:Play()
		s.Ended:Once(function() s:Destroy() end)
	end
end

local function setPressed(b: GuiButton, down: boolean)
	local kind = b:GetAttribute("Kind")
	if not kind then return end
	local p = (b:GetAttribute("Disabled") or b:GetAttribute("Muted")) and GREY or PALETTE[kind]
	local fill = b:FindFirstChild("Fill") :: UIGradient?
	if fill then fill.Color = ColorSequence.new(down and p[3] or p[1], down and p[4] or p[2]) end
	local lbl = b:FindFirstChild("Label") :: GuiObject?
	if lbl then lbl.Position = UDim2.fromOffset(0, down and 3 or 0) end
	local gloss = b:FindFirstChild("Gloss") :: GuiObject?
	if gloss then gloss.Position = UDim2.new(gloss.Position.X, UDim.new(0, down and 6 or 3)) end
end

-- hover 1.04, press 0.96 (0.08 s), click sound
function UIStyle.AttachFeel(b: GuiButton)
	local sc = New("UIScale", { Name = "Feel", Parent = b })
	local hover, down = false, false
	local function apply()
		local target = (down and 0.96) or (hover and 1.04) or 1
		TweenService:Create(sc, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Scale = target }):Play()
		setPressed(b, down)
	end
	b.MouseEnter:Connect(function() hover = true apply() end)
	b.MouseLeave:Connect(function() hover = false down = false apply() end)
	b.MouseButton1Down:Connect(function()
		if b:GetAttribute("Disabled") then return end
		down = true
		apply()
	end)
	b.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			down = false
			if t == Enum.UserInputType.Touch then hover = false end
			apply()
		end
	end)
	b.Activated:Connect(function()
		if not b:GetAttribute("Disabled") then UIStyle.PlayClick() end
	end)
end

---------------------------------------------------------------- buttons
function UIStyle.Button(kind: string, text: string, props: { [string]: any }, textSize: number?): TextButton
	local p = PALETTE[kind] or PALETTE.purple
	props.Text = ""
	props.AutoButtonColor = false
	props.BackgroundColor3 = K.White
	props.BorderSizePixel = 0
	local b = New("TextButton", props)
	b:SetAttribute("Kind", kind)
	UIStyle.Corner(14).Parent = b
	UIStyle.Stroke(p[5], 4).Parent = b
	UIStyle.Gradient(p[1], p[2]).Parent = b
	UIStyle.Gloss(10).Parent = b
	local lbl = UIStyle.Text({ Name = "Label", Text = text, Size = UDim2.fromScale(1, 1), TextColor3 = K.White, TextSize = textSize or 26, Parent = b })
	UIStyle.TextStroke(p[5], 2).Parent = lbl
	UIStyle.AttachFeel(b)
	return b
end

function UIStyle.PurpleButton(text: string, props: { [string]: any }, textSize: number?): TextButton
	return UIStyle.Button("purple", text, props, textSize)
end

function UIStyle.GreenButton(text: string, props: { [string]: any }, textSize: number?): TextButton
	return UIStyle.Button("green", text, props, textSize)
end

-- gold = Robux purchases
function UIStyle.GoldButton(text: string, props: { [string]: any }, textSize: number?): TextButton
	return UIStyle.Button("gold", text, props, textSize)
end

-- three white bars (FredokaOne has no ☰ glyph)
function UIStyle.MenuIcon(b: GuiButton)
	local lbl = b:FindFirstChild("Label") :: TextLabel?
	if lbl then lbl.Text = "" end
	local holder = New("Frame", { Name = "Icon", Size = UDim2.fromScale(0.5, 0.42), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = lbl or b })
	for i = 0, 2 do
		New("Frame", { Size = UDim2.new(1, 0, 0.22, 0), Position = UDim2.fromScale(0, i * 0.39), BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = holder }, {
			UIStyle.Corner(3), UIStyle.Stroke(K.Outline, 1.5),
		})
	end
end

local function repaint(b: GuiButton)
	local kind = b:GetAttribute("Kind")
	local grey = b:GetAttribute("Disabled") or b:GetAttribute("Muted") or not kind
	local p = grey and GREY or PALETTE[kind]
	local fill = b:FindFirstChild("Fill") :: UIGradient?
	if fill then fill.Color = ColorSequence.new(p[1], p[2]) end
	local st = b:FindFirstChildOfClass("UIStroke")
	if st then st.Color = p[5] end
	local lbl = b:FindFirstChild("Label")
	local ls = lbl and lbl:FindFirstChildOfClass("UIStroke")
	if ls then ls.Color = p[5] end
end

-- greys a kit button out (Active alone does not stop clicks, so handlers check the Disabled attribute)
function UIStyle.SetEnabled(b: GuiButton, on: boolean)
	b:SetAttribute("Disabled", not on)
	b.Active = on
	repaint(b)
end

-- greyed with a pink label but still clickable, so the server can say why (e.g. too few coins)
function UIStyle.SetMuted(b: GuiButton, muted: boolean)
	b:SetAttribute("Muted", muted)
	repaint(b)
	local lbl = b:FindFirstChild("Label") :: TextLabel?
	if lbl then lbl.TextColor3 = muted and C(255, 214, 206) or K.White end
end

-- switch a kit button between "purple" / "green" / "gold" (tabs, buy vs equip)
function UIStyle.SetKind(b: GuiButton, kind: string)
	b:SetAttribute("Kind", kind)
	repaint(b)
end

-- white rounded window holding an ImageLabel, or an emoji when the image id is empty
-- IsLoaded can change without a property signal; sample while the image exists.
function UIStyle.ImageFallback(img: ImageLabel, fallback: GuiObject)
	local elapsed = 0
	local connection
	local function refresh()
		fallback.Visible = not (img.Image ~= "" and img.IsLoaded)
	end
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.2 then elapsed = 0 refresh() end
	end)
	img.Destroying:Once(function() connection:Disconnect() end)
	refresh()
	return connection
end

function UIStyle.IconBox(props: { [string]: any }, image: string?, emoji: string?): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or K.White
	props.BorderSizePixel = 0
	local f = New("Frame", props)
	UIStyle.Corner(12).Parent = f
	New("ImageLabel", { Name = "Img", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = f })
	local em = UIStyle.Text({ Name = "Emoji", Text = "", Size = UDim2.fromScale(1, 1), TextScaled = true, Font = Enum.Font.GothamBold, Parent = f })
	New("UITextSizeConstraint", { MaxTextSize = 32, Parent = em })
	UIStyle.SetIcon(f, image, emoji)
	UIStyle.ImageFallback(f.Img, f.Emoji)
	return f
end

function UIStyle.SetIcon(f: Frame, image: string?, emoji: string?)
	local img = f:FindFirstChild("Img") :: ImageLabel
	local em = f:FindFirstChild("Emoji") :: TextLabel
	local has = image ~= nil and image ~= ""
	img.Image = has and (image :: string) or ""
	img.Visible = has
	em.Visible = not (has and img.IsLoaded)
	em.Text = emoji or ""
end

-- row of small level pips (filled = reached)
function UIStyle.Pips(count: number, props: { [string]: any }, pipW: number, pipH: number): Frame
	props.BackgroundTransparency = 1
	local f = New("Frame", props)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
	for i = 1, count do
		New("Frame", { Name = "P" .. i, Size = UDim2.fromOffset(pipW, pipH), LayoutOrder = i, BackgroundColor3 = C(82, 52, 116), BorderSizePixel = 0, Parent = f }, {
			UIStyle.Corner(3), UIStyle.Stroke(K.Outline, 1.5),
		})
	end
	return f
end

function UIStyle.SetPips(f: Instance, n: number)
	for i = 1, #f:GetChildren() do
		local p = f:FindFirstChild("P" .. i) :: Frame?
		if p then p.BackgroundColor3 = i <= n and K.GreenTop or C(82, 52, 116) end
	end
end

-- non-clickable status label in a kit colour ("OWNED", "EQUIPPED", "MAX")
function UIStyle.Badge(kind: string, text: string, props: { [string]: any }, textSize: number?): Frame
	props.BackgroundColor3 = K.White
	props.BorderSizePixel = 0
	local f = New("Frame", props)
	UIStyle.Corner(12).Parent = f
	UIStyle.Stroke(K.GreenOutline, 3).Parent = f
	UIStyle.Gradient(K.GreenTop, K.GreenBot).Parent = f
	UIStyle.Gloss(8).Parent = f
	local lbl = UIStyle.Text({ Name = "Label", Text = text, Size = UDim2.fromScale(1, 1), TextColor3 = K.White, TextSize = textSize or 16, Parent = f })
	UIStyle.TextStroke(K.GreenOutline, 1.5).Parent = lbl
	UIStyle.SetBadge(f, kind, text)
	return f
end

function UIStyle.SetBadge(f: Frame, kind: string, text: string?)
	local p = PALETTE[kind] or PALETTE.green
	local fill = f:FindFirstChild("Fill") :: UIGradient?
	if fill then fill.Color = ColorSequence.new(p[1], p[2]) end
	local st = f:FindFirstChildOfClass("UIStroke")
	if st then st.Color = p[5] end
	local lbl = f:FindFirstChild("Label") :: TextLabel?
	if lbl then
		if text then lbl.Text = text end
		local ls = lbl:FindFirstChildOfClass("UIStroke")
		if ls then ls.Color = p[5] end
	end
end

-- small purple square with a white X (sits inside a green banner, top-right)
function UIStyle.CloseButton(props: { [string]: any }): TextButton
	props.Size = props.Size or UDim2.fromOffset(50, 50)
	-- FredokaOne has no ✕ glyph; a bold X matches the reference kit anyway
	local b = UIStyle.Button("purple", "X", props, 28)
	b:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 12)
	b:FindFirstChildOfClass("UIStroke").Thickness = 3
	b.Name = "Close"
	return b
end

---------------------------------------------------------------- banner + posts
function UIStyle.GreenBanner(text: string, props: { [string]: any }, textSize: number?): Frame
	props.BackgroundColor3 = K.White
	props.BorderSizePixel = 0
	local f = New("Frame", props)
	UIStyle.Corner(18).Parent = f
	UIStyle.Stroke(K.GreenOutline, 4).Parent = f
	UIStyle.Gradient(K.GreenTop, K.GreenBot).Parent = f
	UIStyle.Gloss(14).Parent = f
	local t = UIStyle.Text({
		Name = "Title", Text = text, Size = UDim2.new(1, -128, 1, -14), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
		TextScaled = true, TextColor3 = K.White, Parent = f,
	})
	New("UITextSizeConstraint", { MaxTextSize = textSize or 40, Parent = t })
	UIStyle.TextStroke(K.GreenOutline, 2.5).Parent = t
	return f
end

-- "green" (default) or "sombre" (dark red-brown, for the Haze Emergency ending)
local BANNER_TONES = {
	green = { K.GreenTop, K.GreenBot, K.GreenOutline },
	sombre = { C(150, 62, 52), C(96, 38, 34), C(62, 24, 22) },
}
function UIStyle.SetBannerTone(banner: Frame, tone: string)
	local t = BANNER_TONES[tone] or BANNER_TONES.green
	local fill = banner:FindFirstChild("Fill") :: UIGradient?
	if fill then fill.Color = ColorSequence.new(t[1], t[2]) end
	local st = banner:FindFirstChildOfClass("UIStroke")
	if st then st.Color = t[3] end
	local title = banner:FindFirstChild("Title")
	local ts = title and title:FindFirstChildOfClass("UIStroke")
	if ts then ts.Color = t[3] end
end

-- two wooden posts joining a panel to the banner below it
function UIStyle.Posts(props: { [string]: any }): Frame
	props.BackgroundTransparency = 1
	local f = New("Frame", props)
	for i, x in { 0.2, 0.65 } do
		New("Frame", {
			Name = "Post" .. i, Size = UDim2.new(0.15, 0, 1, 0), Position = UDim2.fromScale(x, 0),
			BackgroundColor3 = K.Wood, BorderSizePixel = 0, Parent = f,
		}, { UIStyle.Stroke(K.WoodOutline, 3), UIStyle.Gradient(K.Wood, C(92, 60, 44)) })
	end
	return f
end

---------------------------------------------------------------- stars + day tiles
function UIStyle.Stars(size: number, props: { [string]: any }): Frame
	props.BackgroundTransparency = 1
	props.Size = props.Size or UDim2.fromOffset(size * 3 + math.floor(size * 0.15) * 2, size)
	local f = New("Frame", props)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, math.floor(size * 0.15)),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = f,
	})
	for i = 1, 3 do
		local s = UIStyle.Text({ Name = "S" .. i, Text = "★", Size = UDim2.fromOffset(size, size), TextSize = math.floor(size * 1.1), TextColor3 = K.StarEmpty, LayoutOrder = i, Parent = f })
		local rim = UIStyle.TextStroke(K.GoldRim, math.max(1, size / 20))
		rim.Name = "Rim"
		rim.Transparency = 1
		rim.Parent = s
	end
	return f
end

function UIStyle.SetStars(f: Instance, n: number)
	for i = 1, 3 do
		local s = f:FindFirstChild("S" .. i) :: TextLabel?
		if s then
			local on = i <= n
			s.TextColor3 = on and K.Gold or K.StarEmpty
			local rim = s:FindFirstChild("Rim") :: UIStroke?
			if rim then rim.Transparency = on and 0 or 1 end
		end
	end
end

-- purple tile with a white window (number / lock), 3 stars and a green "DAY n" strip
function UIStyle.DayTile(day: number, props: { [string]: any }): Frame
	props.BackgroundTransparency = 1
	props.Name = props.Name or ("Day" .. day)
	local root = New("Frame", props)
	local body = New("Frame", { Name = "Body", Size = UDim2.new(1, 0, 1, -16), BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = root }, {
		UIStyle.Corner(22), UIStyle.Stroke(K.Outline, 4), UIStyle.Gradient(K.PurpleTop, K.PurpleBot), UIStyle.Gloss(16),
	})
	local win = New("Frame", { Name = "Window", Size = UDim2.new(1, -16, 0.56, 0), Position = UDim2.fromOffset(8, 9), BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = body }, { UIStyle.Corner(16) })
	local num = UIStyle.Text({ Name = "Num", Text = tostring(day), Size = UDim2.new(1, -8, 1, -6), Position = UDim2.fromOffset(4, 3), TextScaled = true, TextColor3 = K.Number, Parent = win })
	New("UITextSizeConstraint", { MaxTextSize = 44, Parent = num })
	UIStyle.Stars(20, { Name = "Stars", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.56, 13), Parent = body })
	local strip = New("Frame", { Name = "Strip", Size = UDim2.new(1, 6, 0, 30), Position = UDim2.new(0, -3, 1, -30), BackgroundColor3 = K.White, BorderSizePixel = 0, Parent = root }, {
		UIStyle.Corner(10), UIStyle.Stroke(K.GreenOutline, 3), UIStyle.Gradient(K.GreenTop, K.GreenBot),
	})
	local lbl = UIStyle.Text({ Name = "Label", Text = "DAY " .. day, Size = UDim2.fromScale(1, 1), TextSize = 17, TextColor3 = K.White, Parent = strip })
	UIStyle.TextStroke(K.GreenOutline, 1.5).Parent = lbl
	return root
end

-- state: "done" (stars 0-3), "now" (today), "missed" (no data, e.g. joined late), "locked" (future)
function UIStyle.SetDayTile(tile: Frame, day: number, state: string, stars: number?)
	local body = tile:FindFirstChild("Body") :: Frame
	local win = body:FindFirstChild("Window") :: Frame
	local num = win:FindFirstChild("Num") :: TextLabel
	UIStyle.SetStars(body:FindFirstChild("Stars") :: Frame, state == "done" and (stars or 0) or 0)
	win.BackgroundColor3 = state == "now" and C(222, 246, 226) or K.White
	if state == "locked" then
		num.Text = "🔒"
		num.TextColor3 = K.Number
	else
		num.Text = tostring(day)
		num.TextColor3 = state == "missed" and C(186, 180, 196) or K.Number
	end
end

---------------------------------------------------------------- modal (panel on posts over a green banner)
local POSTS, BANNER = 22, 64

export type Modal = {
	Shade: Frame, Root: Frame, Panel: Frame, Banner: Frame, Title: TextLabel, CloseButton: TextButton?,
	W: number, H: number, OnClose: (() -> ())?,
	SetSize: (w: number, h: number) -> (), Open: () -> (), Close: () -> (), IsOpen: () -> boolean, Refit: () -> (),
}

function UIStyle.Modal(parent: Instance, opt: { name: string, title: string, width: number, height: number, close: boolean?, titleSize: number? }): Modal
	local m = {} :: any
	local shade = New("Frame", {
		Name = opt.name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(24, 14, 36), BackgroundTransparency = 0.45,
		BorderSizePixel = 0, Visible = false, Active = true, Parent = parent,
	})
	local root = New("Frame", { Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = shade })
	local fit = New("UIScale", { Name = "Fit", Parent = root })
	local posts = UIStyle.Posts({ Name = "Posts", ZIndex = 0, Parent = root })
	local panel = UIStyle.Panel({ Name = "Panel", Parent = root })
	UIStyle.Pad(20).Parent = panel
	local banner = UIStyle.GreenBanner(opt.title, { Name = "Banner", Parent = root }, opt.titleSize)
	local closeBtn = nil
	if opt.close ~= false then
		closeBtn = UIStyle.CloseButton({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Parent = banner })
	end
	m.Shade, m.Root, m.Panel, m.Banner, m.CloseButton = shade, root, panel, banner, closeBtn
	m.Title = banner:FindFirstChild("Title")
	local titleMax = opt.titleSize or 40
	-- keep clear of the close button on the right (and symmetric so the title stays centred)
	m.Title.Size = UDim2.new(1, -150, 1, -14)
	local function fitTitle()
		if m.W then UIStyle.FitText(m.Title, m.W - 158, titleMax, 14) end
	end
	m.Title:GetPropertyChangedSignal("Text"):Connect(fitTitle)

	function m.SetSize(w: number, h: number)
		m.W, m.H = w, h
		root.Size = UDim2.fromOffset(w, h + POSTS + BANNER)
		panel.Size = UDim2.fromOffset(w, h)
		panel:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, math.min(44, math.floor(w * 0.11)))
		posts.Size = UDim2.fromOffset(w, POSTS + 16)
		posts.Position = UDim2.fromOffset(0, h - 8)
		banner.Size = UDim2.fromOffset(w, BANNER)
		banner.Position = UDim2.fromOffset(0, h + POSTS)
		fitTitle()
	end
	local function fitScale(): number
		local vp = workspace.CurrentCamera.ViewportSize
		return math.clamp(math.min((vp.X - 16) / m.W, (vp.Y - 16) / (m.H + POSTS + BANNER)), 0.4, 1)
	end
	function m.Refit()
		fit.Scale = fitScale()
	end
	function m.Open()
		local s = fitScale()
		shade.Visible = true
		fit.Scale = s * 0.82
		TweenService:Create(fit, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = s }):Play()
	end
	function m.Close()
		shade.Visible = false
	end
	function m.IsOpen(): boolean
		return shade.Visible
	end
	if closeBtn then
		closeBtn.Activated:Connect(function()
			if m.OnClose then m.OnClose() else m.Close() end
		end)
	end
	m.SetSize(opt.width, opt.height)
	return m
end

return UIStyle
