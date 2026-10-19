-- Run once in Edit after importing ServerStorage.KemBombaKit.
-- Preserves the old map (with gameplay tags stripped from backup clones).
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local map = workspace.Map
local kit = SS:WaitForChild("KemBombaKit")
assert(not map:FindFirstChild("KemBombaRimba"), "Layout already installed")
local backup = Instance.new("Folder")
backup.Name = "Backup_WorldBeforeKem_20261018"
backup.Parent = SS
local function stripTags(inst)
	for _,tag in CS:GetTags(inst) do CS:RemoveTag(inst,tag) end
	for _,d in inst:GetDescendants() do
		for _,tag in CS:GetTags(d) do CS:RemoveTag(d,tag) end
	end
end
for _,top in map:GetChildren() do
	if top:IsA("Folder") then
		local folder = Instance.new("Folder") folder.Name=top.Name folder.Parent=backup
		for i,child in top:GetChildren() do
			local copy=child:Clone() stripTags(copy) copy.Parent=folder
			if i%30==0 then task.wait() end
		end
	else local copy=top:Clone() stripTags(copy) copy.Parent=backup end
end
local world = Instance.new("Folder") world.Name="KemBombaRimba" world.Parent=map
local routes = Instance.new("Folder") routes.Name="Routes" routes.Parent=world
local buildings = Instance.new("Folder") buildings.Name="Buildings" buildings.Parent=world
local details = Instance.new("Folder") details.Name="Landmarks" details.Parent=world
local rp = RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Terrain}
local function ground(x,z)
	local hit=workspace:Raycast(Vector3.new(x,150,z),Vector3.new(0,-300,0),rp)
	return hit and hit.Position.Y or 2
end
local function part(parent,name,size,cf,color,mat,invisible)
	local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Anchored=true
	p.Color=color or Color3.fromRGB(116,108,88) p.Material=mat or Enum.Material.Ground
	p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
	p.CanTouch=false p.Transparency=invisible and 1 or 0 p.Parent=parent return p
end
local function collision(model,name,size,pos)
	return part(model,name,size,model:GetPivot()*CFrame.new(pos),nil,Enum.Material.SmoothPlastic,true)
end
local function place(key,name,x,z,yaw,y)
	local m=kit[key]:Clone() m.Name=name
	m:PivotTo(CFrame.new(x,y or ground(x,z)+0.2,z)*CFrame.Angles(0,math.rad(yaw or 0),0))
	m.Parent=buildings return m
end
local corridors={}
local function route(name,points,width,color)
	for i=1,#points-1 do
		local a,b=points[i],points[i+1]
		table.insert(corridors,{a=a,b=b,width=width})
		local length=(b-a).Magnitude
		local count=math.ceil(length/10)
		for j=1,count do
			local p=a:Lerp(b,(j-1)/count) local q=a:Lerp(b,j/count)
			local start=Vector3.new(p.X,ground(p.X,p.Y)+0.3,p.Y)
			local finish=Vector3.new(q.X,ground(q.X,q.Y)+0.3,q.Y)
			local mid=(start+finish)/2
			part(routes,name,Vector3.new(width,0.5,(finish-start).Magnitude+0.6),CFrame.lookAt(mid,finish),color,Enum.Material.Ground)
		end
		task.wait()
	end
end
local V=Vector2.new
route("ServiceRoad",{V(0,-65),V(0,-104)},24)
route("CampAccess",{V(0,-157),V(-42,-180),V(-42,-250),V(0,-270)},24)
route("CampFootpath",{V(-32,-157),V(-75,-177),V(-75,-204)},12)
route("LookoutLoop",{V(-75,-204),V(-140,-205),V(-190,-240),V(-190,-280),V(-130,-290),V(-42,-250)},12,Color3.fromRGB(172,147,96))
route("PeatLoop",{V(0,-270),V(80,-270),V(140,-250),V(220,-250),V(220,-200),V(80,-175),V(0,-157)},12,Color3.fromRGB(117,100,83))
-- A broad, separate truck crossing; pedestrians have their own parallel crossing.
map.Bridge.Size=Vector3.new(24,1,50)
map.RailL.Position=Vector3.new(-12.5,2.6,-130)
map.RailR.Position=Vector3.new(12.5,2.6,-130)
local function ramp(name,x,z1,y1,z2,y2,width)
	local a,b=Vector3.new(x,y1,z1),Vector3.new(x,y2,z2)
	part(routes,name,Vector3.new(width,0.5,(b-a).Magnitude+0.4),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(111,102,88),Enum.Material.Concrete)
end
ramp("VehicleSouthRamp",0,-93,ground(0,-93)+0.3,-106,0.85,24)
ramp("VehicleNorthRamp",0,-154,0.85,-169,ground(0,-169)+0.3,24)
part(routes,"PedestrianDeck",Vector3.new(12,1,50),CFrame.new(-32,0.6,-130),Color3.fromRGB(117,83,67),Enum.Material.WoodPlanks)
for _,x in {-38.3,-25.7} do part(routes,"PedestrianRail",Vector3.new(0.5,3,50),CFrame.new(x,2.6,-130),Color3.fromRGB(233,214,163),Enum.Material.Wood) end
ramp("PedestrianSouthRamp",-32,-95,ground(-32,-95)+0.3,-106,0.85,12)
ramp("PedestrianNorthRamp",-32,-154,0.85,-165,ground(-32,-165)+0.3,12)
route("TownFootpath",{V(-32,-95),V(-40,-65)},12)
-- Flat court with enough space for a full crew to regroup.
part(routes,"CampCourt",Vector3.new(36,0.6,32),CFrame.new(-77,2.25,-198),Color3.fromRGB(158,144,112),Enum.Material.Pavement)
local pavilion=place("01_CommandPavilion","CommandPavilion",-78,-229,180)
collision(pavilion,"DeckCollider",Vector3.new(24,0.5,18),Vector3.new(0,1,0))
collision(pavilion,"EntryCollider",Vector3.new(10,0.7,3),Vector3.new(0,0.35,-10))
for _,x in {-10,10} do for _,z in {-7,7} do collision(pavilion,"ColumnCollider",Vector3.new(0.8,10,0.8),Vector3.new(x,6,z)) end end
collision(pavilion,"TableCollider",Vector3.new(9,3.5,4),Vector3.new(0,1.75,2))
local shelter=place("04_RescueShelter","RescueShelter",-111,-225,90)
collision(shelter,"DeckCollider",Vector3.new(16,0.5,12),Vector3.new(0,2,0))
collision(shelter,"BackWallCollider",Vector3.new(15,5,0.4),Vector3.new(0,5,5.5))
for i=0,2 do collision(shelter,"StepCollider",Vector3.new(6,0.5,1.3),Vector3.new(0,1.5-i*0.5,-7-i)) end
local kiosk=place("03_SupplyKiosk","SupplyKiosk",-111,-187,90)
collision(kiosk,"DeckCollider",Vector3.new(12,0.5,9),Vector3.new(0,0.5,0))
collision(kiosk,"CounterCollider",Vector3.new(10,4,2),Vector3.new(0,2.5,-2))
local tower=place("02_WaterTower","WaterTower",-56,-230)
for _,x in {-3.5,3.5} do for _,z in {-3.5,3.5} do collision(tower,"LegCollider",Vector3.new(0.7,14,0.7),Vector3.new(x,7,z)) end end
local zone=part(tower,"CampRefill",Vector3.new(18,8,16),tower:GetPivot()*CFrame.new(-7,3,0),nil,nil,true)
zone.CanCollide=false zone:SetAttribute("Rate",30) CS:AddTag(zone,"Refill")
local lookout=place("07_LookoutTower","ForestLookout",-190,-261)
collision(lookout,"UpperDeck",Vector3.new(12,0.5,12),Vector3.new(0,14,0))
-- Import maps Blender X to -X. Wide native steps follow the authored switchback.
for i=0,13 do
	collision(lookout,"LowerStair",Vector3.new(5,0.5,1),Vector3.new(9,0.5+i*0.5,-5+i*0.8))
	collision(lookout,"UpperStair",Vector3.new(5,0.5,1),Vector3.new(5,7.5+i*0.5,6-i*0.8))
end
collision(lookout,"Landing",Vector3.new(9,0.5,3),Vector3.new(7,7,7))
for _,z in {-5.5,5.5} do collision(lookout,"DeckRail",Vector3.new(12,3,0.4),Vector3.new(0,15.5,z)) end
collision(lookout,"DeckRail",Vector3.new(0.4,3,11),Vector3.new(-5.5,15.5,0))
-- A 72-stud raised peat walk, with continuous collision across plank seams.
for i=0,5 do
	local walk=place("05_Boardwalk_12x10","PeatBoardwalk"..i,151+i*12,-250,0,3)
	collision(walk,"WalkCollider",Vector3.new(12,0.35,10),Vector3.new(0,1.2,0))
	for _,z in {-255.2,-244.8} do
		local rail=place("06_Railing_12","PeatRailing",151+i*12,z,0,4.4)
		collision(rail,"RailCollider",Vector3.new(12.5,3.8,0.5),Vector3.new(0,2,0))
	end
end
-- Relocate, never discard, fire targets that block the camp or marked routes.
for _,pair in {{137,145},{225,217}} do
	local a=Vector3.new(pair[1],ground(pair[1],-250)+0.3,-250)
	local b=Vector3.new(pair[2],4.15,-250)
	part(routes,"PeatAccessRamp",Vector3.new(10,0.5,(b-a).Magnitude+0.4),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(117,83,67),Enum.Material.WoodPlanks)
end
local function distanceToSegment(p,a,b)
	local ab=b-a local t=math.clamp((p-a):Dot(ab)/ab:Dot(ab),0,1)
	return (p-(a+ab*t)).Magnitude
end
local function blocked(x,z)
	if x>-132 and x<-22 and z>-252 and z<-162 then return true end
	if math.abs(x+190)<25 and math.abs(z+261)<27 then return true end
	if math.abs(x+32)<12 and z>-170 and z<-90 then return true end
	for _,c in corridors do if distanceToSegment(V(x,z),c.a,c.b)<c.width/2+6 then return true end end
	return false
end
local moved=0 local rng=Random.new(181026)
local occupied={}
for _,m in CS:GetTagged("Tree") do if m:IsDescendantOf(workspace) and m.PrimaryPart then table.insert(occupied,m.PrimaryPart.Position) end end
for _,m in map.Forest:GetChildren() do
	if m:IsA("Model") and m.PrimaryPart then
		local p=m.PrimaryPart.Position
		if blocked(p.X,p.Z) then
			for _=1,300 do
				local x,z=rng:NextNumber(-350,350),rng:NextNumber(-380,-175)
				local peat=m:GetAttribute("Peat")
				if peat then x=rng:NextNumber(165,360) z=rng:NextNumber(-350,-190) end
				local clear=not blocked(x,z)
				if clear then for _,q in occupied do if (V(x,z)-V(q.X,q.Z)).Magnitude<12 then clear=false break end end end
				if clear then
					local y=ground(x,z) local oldGround=m:GetAttribute("Ground") or 2
					m:PivotTo(m:GetPivot()+Vector3.new(x-p.X,y-oldGround,z-p.Z))
					m:SetAttribute("Ground",y) table.insert(occupied,Vector3.new(x,y,z)) moved+=1 break
				end
			end
		end
	end
end
-- The existing hydrant was in the approach lane.
for _,m in map.Refill:GetChildren() do
	if m:IsA("Model") then local cf=m:GetBoundingBox()
		if math.abs(cf.Position.X)<2 and math.abs(cf.Position.Z+100)<3 then m:PivotTo(m:GetPivot()+Vector3.new(19,0,0)) end
	end
end
local function sign(name,x,z,message,color)
	local m=place("08_TrailSign",name,x,z)
	local p=part(m,"ReadableSign",Vector3.new(12,5,0.4),m:GetPivot()*CFrame.new(0,6,-0.5),color or Color3.fromRGB(35,123,117),Enum.Material.SmoothPlastic)
	p.CanCollide=false
	for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
		local gui=Instance.new("SurfaceGui") gui.Face=face gui.PixelsPerStud=35 gui.Parent=p
		local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(255,244,211)
		t.Text=message t.TextWrapped=true t.TextScaled=true t.Font=Enum.Font.FredokaOne t.Parent=gui
	end
	return m
end
sign("TownRouteBoard",-40,-68,"KEM BOMBA RIMBA\nCross river · Follow teal signs")
sign("CampWelcome",-67,-174,"KEM BOMBA RIMBA\nWater · Supplies · Rescue")
sign("TrailJunction",-22,-171,"← CAMP / LOOKOUT\nPEAT LOOP →",Color3.fromRGB(139,102,48))
sign("PeatWarning",138,-242,"GAMBUT · PEAT\nStay on the boardwalk",Color3.fromRGB(139,102,48))
sign("LookoutSign",-178,-241,"MENARA TINJAU\nScout smoke · Return to camp")
sign("ExpansionWest",-220,-283,"HILL FOREST\nFuture sector",Color3.fromRGB(77,92,88))
for _,data in {
	{"09_ButtressTree","CampTree",-135,-240},{"09_ButtressTree","LookoutTree",-218,-269},
	{"10_Palm","CampPalm",-118,-167},{"10_Palm","RiverPalm",-59,-157},
	{"11_PeatStump","PeatStumpA",160,-264},{"11_PeatStump","PeatStumpB",204,-266},
	{"12_RiverRocks","BankRocks",-51,-149},{"12_RiverRocks","LookoutRocks",-210,-239}
} do local m=place(data[1],data[2],data[3],data[4]) m.Parent=details end
local prompt=Instance.new("ProximityPrompt") prompt.Name="CampShopPrompt" prompt.ActionText="Open shop" prompt.ObjectText="Bomba supplies"
prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=kiosk.CounterCollider
world:SetAttribute("RelocatedTrees",moved)
world:SetAttribute("DesignCrewSize",6)
world:SetAttribute("BuildVersion","2026-10-18")
-- Preserve terrain voxels before replacing grass material below paths.
local terrain=workspace.Terrain
local low=Vector3int16.new(-65,-4,-100)
local high=Vector3int16.new(65,12,-15)
local terrainBackup=terrain:CopyRegion(Region3int16.new(low,high))
terrainBackup.Name="TerrainBeforeKemSurface"
terrainBackup:SetAttribute("CornerX",low.X)
terrainBackup:SetAttribute("CornerY",low.Y)
terrainBackup:SetAttribute("CornerZ",low.Z)
terrainBackup.Parent=backup
local function pave(pos,size)
	local region=Region3.new(pos-size/2,pos+size/2):ExpandToGrid(4)
	terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.Ground)
	terrain:ReplaceMaterial(region,4,Enum.Material.LeafyGrass,Enum.Material.Ground)
end
pave(Vector3.new(-77,3,-207),Vector3.new(108,12,88))
for i,p in routes:GetChildren() do
	local s,c=p.Size,p.CFrame
	local x=math.abs(c.RightVector.X)*s.X+math.abs(c.LookVector.X)*s.Z
	local z=math.abs(c.RightVector.Z)*s.X+math.abs(c.LookVector.Z)*s.Z
	pave(p.Position,Vector3.new(x+2,12,z+2))
	if i%20==0 then task.wait() end
end
return {relocatedTrees=moved,models=#buildings:GetChildren(),routeParts=#routes:GetChildren()}
