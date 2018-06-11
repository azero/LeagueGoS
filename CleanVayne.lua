--Clean Vayne By: AZer0

--[[
Features:
-Highly configurable
-Smart target selection
-Combo: Q/W/E/R Usage
-Item Usage: Combo / Harass
-Disable/Enable Autos on stealth
-Anti-Chanelled
-Anti-Gap Closer
-Kill Steal
-Auto Level [R > Q > W > E]
-QSS / Scimitar usage

Best With: IOW
Version: 103

To Do:
-Better E Calculations
-Better Q position
-Add spell procs to damage calculations
-Jungle clear
-Summoners Cleanse/Heal/Barrier/Ignite
-Auto Updater
]]--

local champName = GetObjectName(myHero)
local mainMenu = MenuConfig("CleanVayne" , "--[[ Clean Vayne Mechanics ]]--")

local trueRange = GetRange(myHero)
local levelTree = { _Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E }


local farmInfo = {
	["MinionsNearDeath"] = 0
}
local recallInfo = {}
local champInfo = {
	["Q"] = { type = "self", range = 0 },
	["W"] = { type = "buff" },
	["E"] = { type = "target", range = 0 },
	["R"] = { type = "self" },
	["Stealth"] = false,
	["Autos"] = true
}

if champName ~= "Vayne" then
	print("<font color=\"#FF0000\">[</font><font color=\"#000000\">Clean Mechanics</font><font color=\"#FF0000\">]</font> <font color=\"#FFFFFF\">This script only supports Vayne.</font>")
	return
end

if not pcall( require, "MapPositionGOS" ) then PrintChat("MapPositionGOS is missing.") return end

local spellList = {
	["Chanelled"] = {
		--ADC's
		["Caitlyn"] = { _R },
		["Lucian"] = { _R },
		["MissFortune"] = { _R },
		["Varus"] = { _Q },
		--Mid
		["Katarina"] = { _R },
		["FiddleSticks"] = { _W, _R },
		["VelKoz"] = { _R },
		["Karthus"] = { _R },
		["Xerath"] = { _Q, _R },
		["TwistedFate"] = { _R },
		["Malzahar"] = { _R },
		--Top
		["Galio"] = { _R },
		["Nunu"] = { _R },
		["Shen"] = { _R },
		["Pantheon"] = { _R },
		["Warwick"] = { _R },
		["TahmKench"] = { _R },
		--Supports
		["Janna"] = { _R }
	},
	["GapCloser"] = {
		--ADC's
		["Ezreal"] = { _E },
		["Graves"] = { _E },
		["Lucian"] = { _E },
		["Tristana"] = { _W },
		--Mid
		["Akali"] = { _R },
		["Corki"] = { _W },
		["Diana"] = { _R },
		["FiddleSticks"] = { _R },
		["Fizz"] = { _Q },
		["Katarina"] = { _E },
		["Kassadin"] = { _R },
		["LeBlanc"] = { _W, _R },
		["Rengar"] = { _R },
		["Talon"] = { _E },
		["Ziggs"] = { _W },
		--Top
		["Aatrox"] = { _Q },
		["Amumu"] = { _Q },
		["Elise"] = { _Q, _E },
		["Fiora"] = { _Q },
		["Gnar"] = { _E },
		["Gragas"] = { _E },
		["Hecarim"] = { _R },
		["Irelia"] = { _Q },
		["JarvanIV"] = { _Q, _R },
		["Jax"] = { _Q },
		["Jayce"] = { _Q },
		["Kennen"] = { _E },
		["KhaZix"] = { _E },
		["Lissandra"] = { _E },
		["LeeSin"] = { _Q, _W },
		["Malphite"] = { _R },
		["MasterYi"] = { _Q },
		["MonkeyKing"] = { _E },
		["Nautilus"] = { _Q },
		["Nocturne"] = { _R },
		["Olaf"] = { _R },
		["Pantheon"] = { _W, _R },
		["Poppy"] = { _E },
		["RekSai"] = { _E },
		["Renekton"] = { _E },
		["Riven"] = { _Q, _E },
		["Sejuani"] = { _Q },
		["Sion"] = { _R },
		["Shen"] = { _E },
		["Shyvana"] = { _R },
		["Tryndamere"] = { _E },
		["Udyr"] = { _E },
		["Volibear"] = { _Q },
		["Vi"] = { _Q },
		["XinZhao"] = { _E },
		["Yasuo"] = { _E },
		["Zac"] = { _E },
		--Supports
		["Alistar"] = { _W },
		["Leona"] = { _E },
		["Thresh"] = { _Q }
	}
}

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function EnemyCanAAMe()
	local eInRange = 0
	for i, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, GetRange(enemy)) then
			eInRange = eInRange + 1
		end
	end
	return eInRange
end

function EnemyInRange(range)
	local eInRange = 0
	for i, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, range) then
			eInRange = eInRange + 1
		end
	end
	return eInRange
end

function EnemyInRangeOf(range, unit)
	local eInRange = 0
	for i, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistance(unit, enemy) <= range then
			eInRange = eInRange + 1
		end
	end
	return eInRange
end

function AllyInRange(range)
	local aInRange = 0
	for i, ally in pairs(GetAllyHeroes()) do
		if ValidTarget(ally, range) then
			aInRange = aInRange + 1
		end
	end
	return aInRange
end

function IsReady(unit, spell)
	if CanUseSpell(unit, spell) == READY then
		return true
	end
	return false
end

local antiPrettySpam = nil
function PrettyPrint(message)
	if message and antiPrettySpam ~= message then
		antiPrettySpam = message
		print("<font color=\"#FF0000\">[</font><font color=\"#FFFF00\">Clean Vayne</font><font color=\"#FF0000\">]</font> <font color=\"#FFFFFF\">" .. message .. "</font>")
	end
end

function GetTarget()
	local mTarget = nil
	local mTHP = 0
	
	for _, e in pairs(GetEnemyHeroes()) do
		local hitDistance = GetRange(myHero) + GetHitBox(e)
		if ValidTarget(e, radius) then
			local cHP = GetCurrentHP(e) + GetDmgShield(e)
			if mTarget == nil then
				mTarget = e
				mTHP = cHP
			else
				if cHP < mTHP then
					mTarget = e
					mTHP = cHP
				end
			end
		end
	end
	
	return mTarget
end

function ActiveMode()
	if _G.IOW_Loaded then
		return IOW:Mode()
	elseif GoSWalkLoaded then
		if GoSWalk.CurrentMode == 0 then return "Combo"
		elseif GoSWalk.CurrentMode == 1 then return "Harass"
		elseif GoSWalk.CurrentMode == 2 then return "LaneClear"
		elseif GoSWalk.CurrentMode == 3 then return "LastHit" end
	end
end

function KillStealHP(e)
	return GetCurrentHP(e) + GetArmor(e) + GetDmgShield(e) + (GetHPRegen(e) * 1.75)
end

--Thank you to GoS-U for the AA enable/disable
function DiableAutos()
	if _G.IOW then
		IOW.attacksEnabled = false
	elseif _G.GoSWalkLoaded then
		_G.GoSWalk:EnableAttack(false)
	elseif _G.DAC_Loaded then
		DAC:AttacksEnabled(false)
	elseif _G.AutoCarry_Loaded then
		DACR.attacksEnabled = false
	end
	champInfo["Autos"] = false
end

--Thank you to GoS-U for the AA enable/disable
function EnableAutos()
	if _G.IOW then
		IOW.attacksEnabled = true
	elseif _G.GoSWalkLoaded then
		_G.GoSWalk:EnableAttack(true)
	elseif _G.DAC_Loaded then
		DAC:AttacksEnabled(true)
	elseif _G.AutoCarry_Loaded then
		DACR.attacksEnabled = true
	end
	champInfo["Autos"] = true
end

function UpdateSkills()
	if champInfo["E"].range == 0 and IsReady(myHero, _E) then
		champInfo["E"].range = GetCastRange(myHero, _E)
	end
	if champInfo["Q"].range == 0 and IsReady(myHero, _Q) then
		champInfo["Q"].range = GetCastRange(myHero, _Q)
	end
	
	trueRange = GetRange(myHero)
end

function OnCombo()
	local eIn1200 = EnemyInRange(1000)
	local aIn1200 = AllyInRange(1000)
	
	if champInfo["Stealth"] then
		if eIn1200 >= aIn1200 then
			DiableAutos()
		elseif eIn1200 >= 1 and (GetCurrentHealth(myHero)/GetMaxHealth(myHero)) <= 50 then
			DiableAutos()
		end
	else
		if champInfo["Autos"] == false then
			EnableAutos()
		end
	end
	
	local cTarget = GetTarget()
	if cTarget then
		local trueRange = GetHitBox(cTarget) + GetRange(myHero)
		local targetRange = GetDistance(myHero, cTarget)
		
		if ValidTarget(cTarget) then
			
			local item3144 = GetItemSlot(myHero, 3144) --Bilgewater Cutlass
			local item3153 = GetItemSlot(myHero, 3153) --Blade of the Ruined King
			local item3142 = GetItemSlot(myHero, 3142) --Ghost Blade
				
			if mainMenu.Items.bork.combo:Value() and item3144 >= 1 and ValidTarget(cTarget, 400) and CanUseSpell(myHero, item3144) == READY then
				CastTargetSpell(cTarget, item3144)
			end
			if mainMenu.Items.cutlass.combo:Value() and item3153 >= 1 and ValidTarget(cTarget, 400) and CanUseSpell(myHero, item3153) == READY then
				CastTargetSpell(cTarget, item3153)
			end
			if mainMenu.Items.ghostblade.combo:Value() and item3142 >= 1 and ValidTarget(cTarget, 400) and CanUseSpell(myHero, item3142) == READY then
				CastSpell(item3142)
			end
			
			if mainMenu.Combo.Q.use:Value() and IsReady(myHero, _Q) then
				if GotBuff(cTarget, "VayneSilveredDebuff") >= 2 then 
					if GetDistance(TumbleEnd(GetOrigin(cTarget)), cTarget) < trueRange then
						CastSkillShot(_Q, cTarget)
						if mainMenu.draw.spells then
							PrettyPrint("Cast Spell [Q] [To Target] [Proc W]")
						end
					elseif GetDistance(TumbleEnd(GetMousePos()), cTarget) < trueRange then
						CastSkillShot(_Q, GetMousePos())
						if mainMenu.draw.spells then
							PrettyPrint("Cast Spell [Q] [Mouse Position] [Proc W]")
						end
					end
				elseif targetRange > trueRange and GetDistance(TumbleEnd(GetOrigin(cTarget)), cTarget) < trueRange then
					CastSkillShot(_Q, cTarget)
					if mainMenu.draw.spells then
						PrettyPrint("Cast Spell [Q] [To Target]")
					end
				elseif targetRange > trueRange and GetDistance(TumbleEnd(GetMousePos()), cTarget) < trueRange then
					CastSkillShot(_Q, GetMousePos())
					if mainMenu.draw.spells then
						PrettyPrint("Cast Spell [Q] [Mouse Position]")
					end
				end
			end
			
			if mainMenu.Combo.E.use:Value() and IsReady(myHero, _E) and targetRange <= champInfo["E"].range then
				WallStun(cTarget)
				if mainMenu.draw.spells then
					PrettyPrint("Cast Spell [E] [" .. GetObjectName(cTarget) .. "]")
				end
			end
			
			if mainMenu.Combo.R.use:Value() and IsReady(myHero, _R) then
				if eIn1200 >= 2 then
					CastSpell(_R)
					if mainMenu.draw.spells then
						PrettyPrint("Cast Spell [R] [>=2]")
					end
				end
			end
			
		end
	end
	
	if mainMenu.Combo.E.use:Value() and IsReady(myHero, _E) then
		for _, e in pairs(GetEnemyHeroes()) do
			if e and ValidTarget(e, champInfo["E"].range) then
				WallStun(e)
				PrettyPrint("Cast Spell [E] [" .. GetObjectName(e) .. "]")
			end
		end
	end
end

function OnHarass()
	if (GetCurrentMana(myHero)/GetMaxMana(myHero)) > (mainMenu.Harass.mana:Value()/100) then
		local mNearDeath = 0
		for _, m in pairs(minionManager.objects) do
			if GetTeam(m) == MINION_ENEMY and ValidTarget(m, trueRange) then
				if GetCurrentHP(m) + GetArmor(m) + GetDmgShield(m) <= GetBonusDmg(myHero) + GetBaseDamage(myHero) then
					mNearDeath = mNearDeath + 1
				end
			end
		end
		if mNearDeath > 1 then
			farmInfo["MinionsNearDeath"] = mNearDeath
		end
	end
	
	local cTarget = GetTarget()
	if cTarget then
		local trueRange = GetHitBox(cTarget) + GetRange(myHero)
		local targetRange = GetDistance(myHero, cTarget)
		
		local item3144 = GetItemSlot(myHero, 3144) --Bilgewater Cutlass
		local item3153 = GetItemSlot(myHero, 3153) --Blade of the Ruined King
			
		if mainMenu.Items.bork.harass:Value() and item3144 >= 1 and ValidTarget(cTarget, 350) and CanUseSpell(myHero, item3144) == READY then
			CastTargetSpell(cTarget, item3144)
		end
		if mainMenu.Items.cutlass.harass:Value() and item3153 >= 1 and ValidTarget(cTarget, 350) and CanUseSpell(myHero, item3153) == READY then
			CastTargetSpell(cTarget, item3153)
		end
		
		if ValidTarget(cTarget) then
			if mainMenu.Harass.Q.use:Value() and IsReady(myHero, _Q) then
				if GetDistance(TumbleEnd(GetOrigin(cTarget)), cTarget) < trueRange then
					CastSkillShot(_Q, cTarget)
					PrettyPrint("Cast Spell [Q] [To Target]")
				elseif GetDistance(TumbleEnd(GetMousePos()), cTarget) < trueRange then
					CastSkillShot(_Q, GetMousePos())
					PrettyPrint("Cast Spell [Q] [Mouse Position]")
				end
			end
			
			if mainMenu.Harass.E.use:Value() and IsReady(myHero, _E) and targetRange <= champInfo["E"].range then
				WallStun(cTarget)
				PrettyPrint("Cast Spell [E] [" .. GetObjectName(cTarget) .. "]")
			end
		end
	end
end

function OnLaneClear()
	if (GetCurrentMana(myHero)/GetMaxMana(myHero)) > (mainMenu.LaneClear.mana:Value()/100) then
		local mNearDeath = 0
		for _, m in pairs(minionManager.objects) do
			if GetTeam(m) == MINION_ENEMY and ValidTarget(m, trueRange) then
				if GetCurrentHP(m) + GetArmor(m) + GetDmgShield(m) <= GetBonusDmg(myHero) + GetBaseDamage(myHero) then
					mNearDeath = mNearDeath + 1
				end
			end
		end
		if mNearDeath > 1 then
			farmInfo["MinionsNearDeath"] = mNearDeath
		end
	end
end

function OnLastHit()
	if (GetCurrentMana(myHero)/GetMaxMana(myHero)) > (mainMenu.LastHit.mana:Value()/100) then
		local mNearDeath = 0
		for _, m in pairs(minionManager.objects) do
			if GetTeam(m) == MINION_ENEMY and ValidTarget(m, trueRange) then
				if GetCurrentHP(m) + GetArmor(m) + GetDmgShield(m) <= GetBonusDmg(myHero) + GetBaseDamage(myHero) then
					mNearDeath = mNearDeath + 1
				end
			end
		end
		if mNearDeath > 1 then
			farmInfo["MinionsNearDeath"] = mNearDeath
		end
	end
end

function WallStun(target)
	--This will work for now, credits to: [Reincarnation] Vayne - Chine.lua (Edited By: Me)
	local predictedChamp = GetPredictionForPlayer(GetOrigin(myHero), target, GetMoveSpeed(target), 2000, 250, 1000, 1, false, true)
	local playerVector = Vector(predictedChamp.PredPos)
	local myVector = Vector(GetOrigin(myHero))
	local maxEDistance = playerVector - (playerVector - myVector) * ( - mainMenu.Combo.E.range:Value() / GetDistance(playerVector))
	local pushLine = Line(Point(playerVector.x, playerVector.y, playerVector.z), Point(maxEDistance.x, maxEDistance.y, maxEDistance.z))
	for _, position in pairs(pushLine:__getPoints()) do
		if MapPosition:inWall(position) then
			CastTargetSpell(target, _E)
			break
		end
	end
end

function TumbleEnd(loc)
	return GetOrigin(myHero) + (Vector(loc) - GetOrigin(myHero)):normalized() * 300
end

function AutoLevel()
	if GetLevelPoints(myHero) > 0 then
		DelayAction(function() LevelSpell(levelTree[GetLevel(myHero) + 1 - GetLevelPoints(myHero)]) end, 0.5)
	end
end

function OnChanelling(unit, spell)
	if IsReady(myHero, _E) and unit and ValidTarget(unit, champInfo["E"].range) then
		CastTargetSpell(unit, _E)
		PrettyPrint("Cast Spell [E] [" .. GetObjectName(unit) .. "] [" .. spell.name .. "]")
	end
end

function OnGapCloser(unit, spell)
	if IsReady(myHero, _E) and unit and ValidTarget(unit, champInfo["E"].range) then
		CastTargetSpell(unit, _E)
		PrettyPrint("Cast Spell [E] [" .. GetObjectName(unit) .. "] [" .. spell.name .. "]")
	end
end

function LifeAfterAuto(target, autos)
	if not autos then
		autos = 1
	end
	
	if target then
		local eHP = KillStealHP(target)
		local mDMG = (GetBonusDmg(myHero) + GetBaseDamage(myHero)) * autos
		return eHP - mDMG
	else
		return 0
	end
end

function KillSteal()
	if IsReady(myHero, _Q) then
		for _, e in pairs(GetEnemyHeroes()) do
			if e and ValidTarget(e, trueRange) then
				local eDamage = (40*GetCastLevel(myHero,_E)+10)+(0.5*GetBonusDmg(myHero))
				if KillStealHP(e) < eDamage then
					CastTargetSpell(e, _E)
					if mainMenu.draw.spells then
						PrettyPrint("Cast Spell [E] [Kill Steal] [" .. GetObjectName(e) .. "]")
					end
				end
			end
		end
	end
end

function UseScimitar(t)
	if GetItemSlot(myHero, 3139) >= 1 and CanUseSpell(myHero, GetItemSlot(myHero, 3139)) == READY then
		CastTargetSpell(myHero, GetItemSlot(myHero, 3139))
		PrettyPrint("Using [Scimitar] on [" .. t .. "]")
		return true
	end
	return false
end

function UseQSS(t)
	if GetItemSlot(myHero, 3140) >= 1 and CanUseSpell(myHero, GetItemSlot(myHero, 3140)) == READY then
		CastTargetSpell(myHero, GetItemSlot(myHero, 3140))
		PrettyPrint("Using [QSS] on [" .. t .. "]")
		return true
	end
	return false
end

function UseCleanse(t)
	return false
end

function RemoveCC()
	if GotBuff(myHero, "veigareventhorizonstun") > 0 then
		local cName = "Veigar Stun"
		if mainMenu.Items.scimitar.stun:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.stun:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.stun:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "stun") > 0 then
		local cName = "Stun"
		if mainMenu.Items.scimitar.stun:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.stun:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.stun:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "taunt") > 0 then
		local cName = "Taunt"
		if mainMenu.Items.scimitar.taunt:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.taunt:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.taunt:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "slow") > 0 then
		local cName = "Slow"
		if mainMenu.Items.scimitar.slow:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.slow:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.slow:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "snare") > 0 then
		local cName = "Snare"
		if mainMenu.Items.scimitar.snare:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.snare:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.snare:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "charm") > 0 then
		local cName = "Charm"
		if mainMenu.Items.scimitar.charm:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.charm:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.charm:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "suppression") > 0 then
		local cName = "Suppression"
		if mainMenu.Items.scimitar.supression:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.supression:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.supression:Value() and UseCleanse(cName) then
			return true
		end
	end
	
	if GotBuff(myHero, "flee") > 0 then
		local cName = "Flee"
		if mainMenu.Items.scimitar.flee:Value() and UseScimitar(cName) then
			return true
		end
		if mainMenu.Items.qss.flee:Value() and UseQSS(cName) then
			return true
		end
		if mainMenu.Summs.cleanse.flee:Value() and UseCleanse(cName) then
			return true
		end
	end
end

OnDraw(function()
	if mainMenu.draw.q:Value() and IsReady(myHero, _Q) then
		DrawCircle(myHeroPos(), champInfo["Q"].range, 1, 0, mainMenu.draw.qColor:Value())
	end
	if mainMenu.draw.e:Value() and IsReady(myHero, _E) then
		DrawCircle(myHeroPos(), champInfo["E"].range, 1, 0, mainMenu.draw.eColor:Value())
	end
	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and ValidTarget(enemy, 2000) then
			local tLevel = 10
			local underText = WorldToScreen(1, GetOrigin(enemy).x, GetOrigin(enemy).y, GetOrigin(enemy).z)
			if mainMenu.draw.damage:Value() then
				local eHP = KillStealHP(enemy)
				local mDMG = (GetBonusDmg(myHero) + GetBaseDamage(myHero))
				local toKill = round(eHP / mDMG, 0)
				DrawText("Autos: " .. toKill, 17, underText.x - 45, underText.y + tLevel, 0xff32cd32)
				tLevel = tLevel + 18
			end
			if mainMenu.draw.drawW:Value() then
				local wStacks = GotBuff(enemy, "VayneSilveredDebuff")
				DrawText("W Stacks: " .. wStacks, 17, underText.x - 45, underText.y + tLevel, 0xff32cd32)
				tLevel = tLevel + 18
			end
			if mainMenu.draw.drawAARange:Value() then
				DrawCircle(GetOrigin(enemy), GetRange(enemy), 1, 0, 0xff32cd32)
			end
		end
	end
end)

OnUpdateBuff(function(unit, buff)
	if unit == myHero and buff.Name == "vaynetumblefade" then 
		champInfo["Stealth"] = true
	end
end)

OnRemoveBuff(function(unit, buff)
	if unit == myHero and buff.Name == "vaynetumblefade" then 
		champInfo["Stealth"] = false
	end
end)

OnProcessSpellAttack(function(unit, spell)
	if unit == myHero then
		local cMode = ActiveMode()
		local myT = GetTarget()
		if cMode == "LaneClear" or cMode == "LastHit" then
			if farmInfo["MinionsNearDeath"] >= 2 and IsReady(myHero, _Q) then
				CastSkillShot(_Q, GetOrigin(myHero))
			end
		elseif cMode == "Combo" then
			if IsReady(myHero, _Q) and myT and ValidTarget(myT, 1200) then
				CastSkillShot(_Q, GetOrigin(myT))
			else
				local item3144 = GetItemSlot(myHero, 3144) --Bilgewater Cutlass
				local item3153 = GetItemSlot(myHero, 3153) --Blade of the Ruined King
				
				if mainMenu.Items.bork.combo:Value() and item3144 >= 1 and ValidTarget(myT, 400) and CanUseSpell(myHero, item3144) == READY then
					CastTargetSpell(myT, item3144)
				elseif mainMenu.Items.cutlass.combo:Value() and item3153 >= 1 and ValidTarget(myT, 400) and CanUseSpell(myHero, item3153) == READY then
					CastTargetSpell(myT, item3153)
				end
			end
		elseif cMode == "Harass" then
			if IsReady(myHero, _Q) then
				CastSkillShot(_Q, GetOrigin(myT))
			else
				local item3144 = GetItemSlot(myHero, 3144) --Bilgewater Cutlass
				local item3153 = GetItemSlot(myHero, 3153) --Blade of the Ruined King
				
				if mainMenu.Items.bork.harass:Value() and item3144 >= 1 and ValidTarget(myT, 400) and CanUseSpell(myHero, item3144) == READY then
					CastTargetSpell(myT, item3144)
				elseif mainMenu.Items.cutlass.harass:Value() and item3153 >= 1 and ValidTarget(myT, 400) and CanUseSpell(myHero, item3153) == READY then
					CastTargetSpell(myT, item3153)
				end
			end
		end
		
	end
end)

OnTick(function(mHero)
	UpdateSkills()
	
	AutoLevel()
	KillSteal()
	
	local mode = ActiveMode()
	
	if mode == "Combo" then
		farmInfo["MinionsNearDeath"] = 0
		OnCombo()
	elseif mode == "LaneClear" then
		OnLaneClear()
	elseif mode == "LastHit" then
		OnLastHit()
	elseif mode == "Harass" then
		OnHarass()
	end
end)

OnLoad(function(mHero)
	PrettyPrint("Loading Champion [Vayne]")
	
	mainMenu:Menu("Combo", "--[[ Combo ]]--")
		mainMenu.Combo:Menu("Q", "--[[ Q - Tumble ]]--")
			mainMenu.Combo.Q:Boolean("use", "Use Spell [Q]", true)
			mainMenu.Combo.Q:Boolean("reset", "Use For [Reset]", true)
			
		mainMenu.Combo:Menu("E", "--[[ E - Condemn ]]--")
			mainMenu.Combo.E:Boolean("use", "Use Spell [E]", true)
			mainMenu.Combo.E:Boolean("reset", "Use For [Knock Back]", true)
			mainMenu.Combo.E:Slider("range", "Knock Back Range", 400, 350, 490, 1)
			for _, enemy in pairs(GetEnemyHeroes()) do
				mainMenu.Combo.E:Boolean("champ" .. GetObjectName(enemy), "Use On [" .. GetObjectName(enemy) .. "]", true)
			end
			
		mainMenu.Combo:Menu("R", "--[[ R - Final Hour ]]--")
			mainMenu.Combo.R:Boolean("use", "Use Spell [R]", true)
	
	----------------------------------------------------------------------------------------	
	mainMenu:Menu("Harass", "--[[ Harass ]]--")
		mainMenu.Harass:Menu("Q", "--[[ Q - Tumble ]]--")
			mainMenu.Harass.Q:Boolean("use", "Use Spell [Q]", true)
			mainMenu.Harass.Q:Boolean("reset", "Use For [Reset]", true)
			mainMenu.Harass:Slider("mana", "Min Mana Percent", 40, 0, 100, 5)
			
		mainMenu.Harass:Menu("E", "--[[ E - Condemn ]]--")
			mainMenu.Harass.E:Boolean("use", "Use Spell [E]", true)
			mainMenu.Harass.E:Boolean("reset", "Use For [Knock Back]", true)
			mainMenu.Harass.E:Slider("range", "Knock Back Range", 400, 350, 490, 1)
			for _, enemy in pairs(GetEnemyHeroes()) do
				mainMenu.Harass.E:Boolean("champ" .. GetObjectName(enemy), "Use On [" .. GetObjectName(enemy) .. "]", true)
			end
	
	----------------------------------------------------------------------------------------
	mainMenu:Menu("LastHit", "--[[ Last Hit ]]--")
		mainMenu.LastHit:Menu("Q", "--[[ Q - Tumble ]]--")
			mainMenu.LastHit.Q:Boolean("use", "Use Spell [Q]", true)
			mainMenu.LastHit.Q:Boolean("reset", "Use For [Reset]", true)
			mainMenu.LastHit:Slider("mana", "Min Mana Percent", 40, 0, 100, 5)
	
	----------------------------------------------------------------------------------------
	mainMenu:Menu("LaneClear", "--[[ Lane Clear ]]--")
		mainMenu.LaneClear:Menu("Q", "--[[ Q - Tumble ]]--")
			mainMenu.LaneClear.Q:Boolean("use", "Use Spell [Q]", true)
			mainMenu.LaneClear.Q:Boolean("reset", "Use For [Reset]", true)
			mainMenu.LaneClear:Slider("mana", "Min Mana Percent", 40, 0, 100, 5)
	
	----------------------------------------------------------------------------------------
	mainMenu:Menu("KillSteal", "--[[ Kill Steal ]]--")
		mainMenu.KillSteal:Menu("Q", "--[[ Q - Tumble ]]--")
			mainMenu.KillSteal.Q:Boolean("use", "Use Spell [Q]", true)
			
		mainMenu.KillSteal:Menu("E", "--[[ E - Condemn ]]--")
			mainMenu.KillSteal.E:Boolean("use", "Use Spell [E]", true)
		
	----------------------------------------------------------------------------------------
	mainMenu:Menu("Items", "--[[ Items ]]--")
		mainMenu.Items:Menu("bork", "--[[ Blade of the Ruined King ]]--")
			mainMenu.Items.bork:Boolean("combo", "Use In [Combo]", true)
			mainMenu.Items.bork:Boolean("harass", "Use In [Harass]", true)
		
		mainMenu.Items:Menu("cutlass", "--[[ Bilgewater Cutlass ]]--")
			mainMenu.Items.cutlass:Boolean("combo", "Use In [Combo]", true)
			mainMenu.Items.cutlass:Boolean("harass", "Use In [Harass]", true)
			
		mainMenu.Items:Menu("ghostblade", "--[[ Ghost Blade ]]--")
			mainMenu.Items.ghostblade:Boolean("combo", "Use In [Combo]", true)
			mainMenu.Items.ghostblade:Boolean("harass", "Use In [Harass]", true)
		
		mainMenu.Items:Menu("qss", "--[[ Quicksilver Sash ]]--")
			mainMenu.Items.qss:Boolean("slow", "Use On [Slow]", true)
			mainMenu.Items.qss:Boolean("stun", "Use On [Stun]", true)
			mainMenu.Items.qss:Boolean("snare", "Use On [Snare]", true)
			mainMenu.Items.qss:Boolean("taunt", "Use On [Taunt]", true)
			mainMenu.Items.qss:Boolean("charm", "Use On [Charm]", true)
			mainMenu.Items.qss:Boolean("supression", "Use On [Supression]", true)
			mainMenu.Items.qss:Boolean("flee", "Use On [Flee]", true)
		
		mainMenu.Items:Menu("scimitar", "--[[ Mercurial Scimitar ]]--")
			mainMenu.Items.scimitar:Boolean("slow", "Use On [Slow]", true)
			mainMenu.Items.scimitar:Boolean("stun", "Use On [Stun]", true)
			mainMenu.Items.scimitar:Boolean("snare", "Use On [Snare]", true)
			mainMenu.Items.scimitar:Boolean("taunt", "Use On [Taunt]", true)
			mainMenu.Items.scimitar:Boolean("charm", "Use On [Charm]", true)
			mainMenu.Items.scimitar:Boolean("supression", "Use On [Supression]", true)
			mainMenu.Items.scimitar:Boolean("flee", "Use On [Flee]", true)
			
	----------------------------------------------------------------------------------------
	mainMenu:Menu("Summs", "--[[ Summoner Spells ]]--")
		mainMenu.Items:Menu("cleanse", "--[[ Cleanse ]]--")
			mainMenu.Items.cleanse:Boolean("slow", "Use On [Slow]", true)
			mainMenu.Items.cleanse:Boolean("stun", "Use On [Stun]", true)
			mainMenu.Items.cleanse:Boolean("snare", "Use On [Snare]", true)
			mainMenu.Items.cleanse:Boolean("taunt", "Use On [Taunt]", true)
			mainMenu.Items.cleanse:Boolean("charm", "Use On [Charm]", true)
			mainMenu.Items.cleanse:Boolean("supression", "Use On [Supression]", true)
			mainMenu.Items.cleanse:Boolean("flee", "Use On [Flee]", true)
	
	----------------------------------------------------------------------------------------
	mainMenu:Menu("draw", "--[[ Display ]]--")
		mainMenu.draw:Boolean("q", "Draw [Q]", true)
		mainMenu.draw:ColorPick("qColor", "Q Color", {255,255,255,0})
		mainMenu.draw:Boolean("e", "Draw [E]", true)
		mainMenu.draw:ColorPick("eColor", "E Color", {255,255,255,0})
		mainMenu.draw:Boolean("spells", "Print [Spells]", true)
		mainMenu.draw:Boolean("damage", "Draw [Damage]", true)
		mainMenu.draw:Boolean("drawW", "Draw [W Stacks]", true)
		mainMenu.draw:Boolean("drawAARange", "Draw [Enemy AA Range]", true)
	
	PrettyPrint("Done Loading Champion [Vayne]")
	PrettyPrint("Welcome To Clean Mechanics - Vayne. By: AZer0")
	PrettyPrint("If you find any issues please let me know. This script is in BETA.")
end)

OnProcessSpell(function(unit, spell)
	if GetObjectType(unit) == Obj_AI_Hero and GetTeam(unit) ~= GetTeam(myHero) then
		local uName = GetObjectName(unit)
		if spellList["Chanelled"][uName] then
			for _, s in pairs(spellList["Chanelled"][uName]) do
				if s and GetCastName(unit, s) == spell.name then
					OnChanelling(unit, spell)
					break
				end
			end
		end
		
		if spellList["GapCloser"][uName] then
			for _, s in pairs(spellList["GapCloser"][uName]) do
				if s and GetCastName(unit, s) == spell.name then
					OnGapCloser(unit, spell)
					break
				end
			end
		end
		
		RemoveCC()
	end
end)

OnProcessRecall(function(unit,recall)
	if GetTeam(unit) ~= GetTeam(myHero) then
		if recall.isStart then
			table.insert(recallInfo, { hero = unit, startTime = GetGameTimer(), length = recall.totalTime / 1000})
		else
			for i, r in pairs(recallInfo) do
				if recall.champ == unit then
					table.remove(recallInfo, i)
					break
				end
			end
		end
	end
end)