local lookout=workspace.Map.KemBombaRimba.Buildings.ForestLookout
local base=lookout:GetPivot()
local cream=lookout:FindFirstChild("07_LookoutTower__cream") if cream then cream.Transparency=1 end
for _,p in lookout:GetChildren() do
 if p.Name=="DeckRail" and base:PointToObjectSpace(p.Position).Z < -5 then p:Destroy() end
end
local function p(name,size,cf,color)
 local v=Instance.new("Part") v.Name=name v.Size=size v.CFrame=cf v.Color=color or Color3.fromRGB(117,83,67)
 v.Material=Enum.Material.WoodPlanks v.Anchored=true v.CanTouch=false v.Parent=lookout return v
end
local a=base:PointToWorldSpace(Vector3.new(20,0.4,-24))
local b=base:PointToWorldSpace(Vector3.new(0,14,-1))
p("CrewAccessRamp",Vector3.new(8,0.5,(b-a).Magnitude+0.4),CFrame.lookAt((a+b)/2,b))
local cf=CFrame.lookAt((a+b)/2,b)
for _,x in {-4.3,4.3} do p("RampHandrail",Vector3.new(0.4,2,(b-a).Magnitude),cf*CFrame.new(x,1.5,0),Color3.fromRGB(233,214,163)) end
p("AccessibleLanding",Vector3.new(10,0.5,8),base*CFrame.new(0,14,-3))
p("FrontRailLeft",Vector3.new(4,2.5,0.4),base*CFrame.new(-4,15.5,-5.5),Color3.fromRGB(233,214,163))
p("LookoutRidge",Vector3.new(15.2,0.45,0.4),base*CFrame.new(0,25.3,0),Color3.fromRGB(233,214,163))
return true
