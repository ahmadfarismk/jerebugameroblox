-- Jerebu build step 6/6: the Hose tool in StarterPack (its HoseClient LocalScript comes from src/)
local SP = game.StarterPack
local old = SP:FindFirstChild("Hose") if old then old:Destroy() end
local tool = Instance.new("Tool") tool.Name = "Hose" tool.ToolTip = "Hold click to spray water" tool.CanBeDropped = false
tool.GripPos = Vector3.new(0, -0.1, 0.6) tool.GripForward = Vector3.new(0, 0, -1) tool.GripRight = Vector3.new(1, 0, 0) tool.GripUp = Vector3.new(0, 1, 0)
local h = Instance.new("Part") h.Name = "Handle" h.Size = Vector3.new(0.6, 0.8, 2.6) h.Color = Color3.fromRGB(200, 40, 40) h.Material = Enum.Material.SmoothPlastic h.CanCollide = false h.Massless = true h.Parent = tool
local function weld(p, cf)
	p.CanCollide = false p.Massless = true p.Anchored = false
	p.CFrame = h.CFrame * cf p.Parent = tool
	local w = Instance.new("WeldConstraint") w.Part0 = h w.Part1 = p w.Parent = p
end
local barrel = Instance.new("Part") barrel.Name = "Barrel" barrel.Shape = Enum.PartType.Cylinder barrel.Size = Vector3.new(1.6, 0.5, 0.5) barrel.Color = Color3.fromRGB(190, 190, 195) barrel.Material = Enum.Material.Metal
weld(barrel, CFrame.new(0, 0.15, -1.9) * CFrame.Angles(0, math.pi / 2, 0))
local tip = Instance.new("Part") tip.Name = "Tip" tip.Size = Vector3.new(0.7, 0.7, 0.3) tip.Color = Color3.fromRGB(240, 200, 60)
weld(tip, CFrame.new(0, 0.15, -2.75))
local grip = Instance.new("Part") grip.Name = "Grip" grip.Size = Vector3.new(0.45, 1.1, 0.5) grip.Color = Color3.fromRGB(40, 40, 40)
weld(grip, CFrame.new(0, -0.7, 0.4) * CFrame.Angles(math.rad(-15), 0, 0))
local gauge = Instance.new("Part") gauge.Name = "Gauge" gauge.Shape = Enum.PartType.Cylinder gauge.Size = Vector3.new(0.3, 0.6, 0.6) gauge.Color = Color3.fromRGB(30, 140, 255) gauge.Material = Enum.Material.Neon
weld(gauge, CFrame.new(0.35, 0.2, 0.3))
local att = Instance.new("Attachment") att.Name = "Nozzle" att.Position = Vector3.new(0, 0.15, -2.95) att.Parent = h
local jet = Instance.new("ParticleEmitter") jet.Name = "Jet"
jet.Texture = "rbxasset://textures/particles/smoke_main.dds"
jet.Color = ColorSequence.new(Color3.fromRGB(210, 235, 255), Color3.fromRGB(160, 210, 255))
jet.LightEmission = 0.25 jet.LightInfluence = 0.6
jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 2.6) })
jet.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) })
jet.Lifetime = NumberRange.new(0.55, 0.75) jet.Rate = 90 jet.Speed = NumberRange.new(60, 68) jet.SpreadAngle = Vector2.new(3, 3)
jet.Acceleration = Vector3.new(0, -60, 0) jet.Drag = 0.6 jet.EmissionDirection = Enum.NormalId.Front jet.Enabled = false jet.Parent = att
local drops = Instance.new("ParticleEmitter") drops.Name = "Drops"
drops.Texture = "rbxasset://textures/particles/sparkles_main.dds"
drops.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
drops.Size = NumberSequence.new(0.25, 0.1) drops.Transparency = NumberSequence.new(0.2, 1)
drops.Lifetime = NumberRange.new(0.5, 0.8) drops.Rate = 60 drops.Speed = NumberRange.new(50, 62) drops.SpreadAngle = Vector2.new(6, 6)
drops.Acceleration = Vector3.new(0, -80, 0) drops.EmissionDirection = Enum.NormalId.Front drops.Enabled = false drops.Parent = att
tool.Parent = SP
return "hose tool ok"
