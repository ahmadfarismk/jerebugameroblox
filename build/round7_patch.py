from pathlib import Path
p=Path('src/ServerScriptService/JerebuServer.server.lua')
s=p.read_text(encoding='utf-8')
def replace(a,b):
 global s
 assert a in s,a[:100]
 s=s.replace(a,b,1)
replace('local Progression = require(script.Parent:WaitForChild("Progression"))','local Progression = require(script.Parent:WaitForChild("Progression"))\nlocal Camp = require(script.Parent:WaitForChild("CampUpgrades"))')
replace('share = Progression.addCoins(plr, share, true)','share = Progression.addCoins(plr, share, true)\n\t\t\tCamp.creditFire(share)')
replace('local secs = if solo then Config.Revive.soloDownSeconds else Config.Revive.downSeconds','local secs = (if solo then Config.Revive.soloDownSeconds else Config.Revive.downSeconds) + (Camp.has("RescueShelter") and 10 or 0)\n\tplr:SetAttribute("DownedDuration", secs)')
replace('prompt.HoldDuration = Config.Revive.holdSeconds','prompt.HoldDuration = Camp.has("RescueShelter") and 1.2 or Config.Revive.holdSeconds')
replace('if inZone(pos, z) then return true end','if (z:GetAttribute("Rate") or 30) > 0 and inZone(pos, z) then return true end')
replace('elseif State.phase == "Day" then','elseif State.mode == "Survival" and Camp.contains(root.Position) and (State.phase == "Night" or State.phase == "Camp" or Camp.has("FieldKitchen")) then\n\t\t\t\t\tif Camp.has("FieldKitchen") then hum.Health = math.min(hum.MaxHealth, hum.Health + 4 * dt) end\n\t\t\t\telseif State.phase == "Day" or State.phase == "Night" then')
replace('local drain = (Config.Health.drain[band] or 0) * (1 - Progression.stats(plr).resist)','local drain = (Config.Health.drain[band] or 0) * (1 - Progression.stats(plr).resist) * (State.phase == "Night" and 0.5 or 1)')
replace('local function runDay(day: number, cfg)', '''local function phaseLength(name, normal)
	if RunService:IsStudio() then
		local value = workspace:GetAttribute("Debug" .. name .. "Length")
		if typeof(value) == "number" and value >= 1 and value <= normal then return value end
	end
	return normal
end

local function runNight(day)
	notify("MALAM · Return to camp together to rest.", "day")
	local candidates = {}
	for _, info in Trees do
		if not info.fire and not info.burnt and (info.pos - Camp.center).Magnitude <= 150 then table.insert(candidates, info) end
	end
	for _ = 1, math.min(#candidates, 2 + math.floor(day / 3), maxFires()) do
		local index = rng:NextInteger(1, #candidates)
		ignite(table.remove(candidates, index), 10)
	end
	local duration, elapsed, checked = phaseLength("Night", 60), 0, false
	countdown("Night", duration, function(dt)
		elapsed += dt
		game.Lighting.ClockTime = (20 + 8 * math.min(1, elapsed / duration)) % 24
		stepFires(dt)
		stepAPI(dt)
		if not checked and elapsed >= duration / 2 then
			checked = true
			local crew = Players:GetPlayers()
			local safe = #crew > 0
			for _, p in crew do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not root or not hum or hum.Health <= 0 or p:GetAttribute("Downed") or not (Camp.contains(root.Position) or inZone(root.Position, safeZone)) then safe = false end
			end
			if safe then
				for _, p in crew do Progression.addCoins(p, 5, false) end
				notify("The crew rests! +5 coins each.", "good")
				skipPhase = true
			end
		end
	end)
	clearAllFires()
	setAttr("Fires", 0)
	setAttr("Smoulder", 0)
end

local function runDay(day: number, cfg)''')
replace('Remotes.Report:FireAllClients({','if State.mode ~= "Survival" then Remotes.Report:FireAllClients({')
replace('\t\tmode = State.mode,\n\t})','\t\tmode = State.mode,\n\t}) end')
replace('\tif State.mode == "Survival" then\n\t\tState.completedDays += 1','\tif State.mode == "Survival" then\n\t\trunNight(day)\n\t\tif survivalReason then return end\n\t\tState.completedDays += 1')
replace('\tend\n\tcountdown("Report", Config.ReportLength)','\t\tnotify("KEM · Spend the shared Camp Fund at the kiosk.", "good")\n\t\tgame.Lighting.ClockTime = 6\n\t\tcountdown("Camp", phaseLength("Camp", 20))\n\telse\n\t\tcountdown("Report", Config.ReportLength)\n\tend')
replace('(State.phase == "Day" or State.phase == "Report")','(State.phase == "Day" or State.phase == "Night" or State.phase == "Camp")')
replace('State.mode = "Story"','State.mode = "Story"\n\t\tCamp.reset()')
p.write_text(s,encoding='utf-8')
p=Path('src/ServerScriptService/CampServices.server.lua');s=p.read_text(encoding='utf-8').replace('humanoid.Health <= 0','humanoid.Health <= 0 or player:GetAttribute("Downed")').replace('notify:FireClient(player, "__openshop", "shop")','local isCamp = workspace:GetAttribute("Mode") == "Survival" and workspace:GetAttribute("Phase") == "Camp"\n\tnotify:FireClient(player, isCamp and "__opencamp" or "__openshop", "shop")');p.write_text(s,encoding='utf-8')
p=Path('src/StarterPlayerScripts/DownedUI.client.lua');s=p.read_text(encoding='utf-8').replace('local total = solo and Config.Revive.soloDownSeconds or Config.Revive.downSeconds','local total = player:GetAttribute("DownedDuration") or (solo and Config.Revive.soloDownSeconds or Config.Revive.downSeconds)');p.write_text(s,encoding='utf-8')
p=Path('src/StarterPlayerScripts/HUD.client.lua');s=p.read_text(encoding='utf-8').replace('if msg == "__openshop" then','if msg == "__opencamp" then return end\n\tif msg == "__openshop" then').replace('if workspace:GetAttribute("Mode") == "Survival" and phase == "Day" then phaseText.Text = "SURVIVAL · Fight fires" end','if workspace:GetAttribute("Mode") == "Survival" then\n\t\tphaseText.Text = phase == "Night" and "MALAM · Regroup at camp" or phase == "Camp" and "KEM · Build together" or phase == "Day" and "SURVIVAL · Fight fires" or phaseText.Text\n\tend');p.write_text(s,encoding='utf-8')
