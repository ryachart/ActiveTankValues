local ActiveTankValues = {};

local class_spell_table = { 
			WARRIOR = "112048", --Shield Barrier  
			DRUID = "22842", --Frenzied Regeneration
			PALADIN = "85673" --Word of Glory
};

local mitigation_value_lookup = {
			WARRIOR = function()
				local apBase, apPosBuff, apNegBuff = UnitAttackPower("player")
				local rage = min(60,UnitPower("player"));
				local str, effectiveStr, posBuffStr, negBuffStr = UnitStat("player", 1) --1 is str
				local sta, effectiveSta, posBuffSta, negBuffSta = UnitStat("player", 3) --3 is stamina
				local totalAp = apBase+apPosBuff+apNegBuff;
				if (rage < 20) then
					return 0;
				end
				
				
				local barrier_value = totalAp * 1.125;
				local resolveValue = GetResolveValue()
				return floor(barrier_value * resolveValue * (rage / 20));
			end,
			DRUID = function()
				local form = GetShapeshiftFormID();
				if (form ~= BEAR_FORM) then
					return 0;
				end
				local apBase, apPosBuff, apNegBuff = UnitAttackPower("player")
				local rage = min(60,UnitPower("player"));
				local agi, effectiveAgi, posBuffAgi, negBuffAgi = UnitStat("player", 2) --2 is agi
				local sta, effectiveSta, posBuffSta, negBuffSta = UnitStat("player", 3) --3 is stamina
				local totalAp = apBase+apPosBuff+apNegBuff;
				if (rage < 20) then
					return 0;
				end
				
				
				local regen_value = floor(math.max(2 * (totalAp - 2 * agi), math.min(math.max(rage, 20), 60) / 60 * sta * 2.5))
				return regen_value;
			end,
			PALADIN = function()
				local holyPower = min(3,UnitPower("player", SPELL_POWER_HOLY_POWER));
				local sp = GetSpellBonusHealing();
				local baseHealing = 5054; --Average Base Healing
				local name, rank, icon, count, dispelType, 
				duration, expires, caster, isStealable, 
				shouldConsolidate, spellID, canApplyAura, 
				isBossDebuff, value1, value2, value3 = UnitBuff("player", "Bastion of Glory");
				local bastionOfGloryModifier = 1.0;
				if (value2) then
					bastionOfGloryModifier = value2/100.0 + 1;
				end
				
				return math.floor(bastionOfGloryModifier*holyPower*(baseHealing+(.49*sp)));
			end
};

function GetResolveValue()
	name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura("player", "Resolve")
	if value2 == nil or value2 == 0 then 
		return 1 
	end;
	return (1 + value2/100)
end


function ActiveTankValues_OnLoad(self)
	SLASH_ActiveTankValues1 = "/atv";
	SlashCmdList["ActiveTankValues"] = function(message, editbox) ActiveTankValues:SlashCmd(message, editbox) end;
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:SetScript("OnEvent",function(self, event, ...)ActiveTankValues[event](self, ...)end);
	ActiveTankValues_MainText:SetText("0");
	if ( ActiveTankValues_Settings == nil ) then
		ActiveTankValues_Settings = { };
		ActiveTankValues_Settings.IsLocked = false;
	end
	
	local class, classFileName = UnitClass("player");
	if (classFileName == "WARRIOR") then
		ActiveTankValues_MainStatusBar:SetMinMaxValues(0.0, 1.0);
		ActiveTankValues_MainStatusBar:SetStatusBarColor(0.0,1.0,0.0,1.0);
		ActiveTankValues_MainStatusBar:SetPoint("BOTTOM", self, "CENTER", 0, -20)
		ActiveTankValues_MainStatusBar:SetWidth(100)
		ActiveTankValues_MainStatusBar:SetHeight(10)
		ActiveTankValues_MainStatusBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		ActiveTankValues_MainStatusBar:GetStatusBarTexture():SetHorizTile(false)
		ActiveTankValues_MainStatusBar:GetStatusBarTexture():SetVertTile(false)
		ActiveTankValues_MainStatusBar:SetStatusBarColor(0, 0.65, 0)
		
		ActiveTankValues_MainStatusBar.bg = ActiveTankValues_MainStatusBar:CreateTexture(nil, "BACKGROUND")
		ActiveTankValues_MainStatusBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		ActiveTankValues_MainStatusBar.bg:SetAllPoints(true)
		ActiveTankValues_MainStatusBar.bg:SetVertexColor(0, 0.35, 0)
		ActiveTankValues_MainStatusBar:SetScript("OnUpdate", function(self, elapsed) 
			local name, rank, icon, count, dispelType, 
					duration, expires, caster, isStealable, 
					shouldConsolidate, spellID, canApplyAura, 
					isBossDebuff, value1, value2, value3 = UnitBuff("player", "Shield Barrier");
					if (expires and duration) then
						local remainingBarrierPercentage = abs((GetTime() - expires)/duration);
						self:SetValue(remainingBarrierPercentage);
					end
			end
		);
	end
end

function ActiveTankValues:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2, ...)
	local class, classFileName = UnitClass("player");
	local resultValue = mitigation_value_lookup[classFileName]();
	local isAbsorbing = false;
	
	if classFileName == "WARRIOR" then
		local name, rank, icon, count, dispelType, 
				duration, expires, caster, isStealable, 
				shouldConsolidate, spellID, canApplyAura, 
				isBossDebuff, value1, value2, value3 = UnitBuff("player", "Shield Barrier");
				if (value2 and value2 > 0) then
					ActiveTankValues_MainText:SetText(value2);
					ActiveTankValues_MainText:SetTextColor(0,1,0,1);
					isAbsorbing = true;
					ActiveTankValues_MainStatusBar:Show();
					--print("StatusBarValue: ", ActiveTankValues_MainStatusBar:GetValue());
				end
	end
	
	
	if not isAbsorbing then
		ActiveTankValues_MainText:SetTextColor(1,1,1,1);
		ActiveTankValues_MainStatusBar:SetValue(0);
		ActiveTankValues_MainStatusBar:Hide();
		if (resultValue == 0) then
			ActiveTankValues_MainText:SetText();
		else 
			ActiveTankValues_MainText:SetText(resultValue);
		end
	end
	
	if (resultValue > 0 or isAbsorbing) then
			ActiveTankValues_MainButton1:Show();
		else
			ActiveTankValues_MainButton1:Hide();
	end
end

function ActiveTankValues:PLAYER_REGEN_DISABLED()
	ActiveTankValues:Check_Visibility();
end

function ActiveTankValues:PLAYER_REGEN_ENABLED()
	ActiveTankValues:Check_Visibility();
end

function ActiveTankValues:ACTIVE_TALENT_GROUP_CHANGED()
	ActiveTankValues:Check_Visibility();
end

function ActiveTankValues:PLAYER_ENTERING_WORLD()
	ActiveTankValues:Check_Visibility();
	
	if (ActiveTankValues_Settings.IsLocked) then
		self:RegisterForDrag();
	else
		self:RegisterForDrag("LeftButton");
	end
end

function ActiveTankValues:Check_Visibility()
	local inCombat = UnitAffectingCombat("player");
	local unlocked = not ActiveTankValues_Settings.IsLocked;
	local app_spell = ActiveTankValues:Appropriate_Spell()
	if (app_spell and (inCombat or unlocked)) then
		ActiveTankValues_Main:Show();
		ActiveTankValues_Main:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		local appropriateSpellTexture = GetSpellTexture(app_spell);
		ActiveTankValues_MainButton1:SetNormalTexture(appropriateSpellTexture);
	else
		ActiveTankValues_Main:Hide();
		if (ActiveTankValues_Main:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED")) then
			ActiveTankValues_Main:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
	end
end

function ActiveTankValues:Appropriate_Spell()
	local class, classFileName = UnitClass("player");
	local spellId = class_spell_table[classFileName];
	if spellId then
		local spellName = GetSpellInfo(spellId);
		local skillType = GetSpellBookItemInfo(spellName);
		if (skillType == "SPELL") then
			return spellName;
		else
			return false;
		end
	end
end

function ActiveTankValues:SlashCmd(message, editBox)
	local command, rest = message:match("^(%S*)%s*(.-)$");
	-- Nothing right now =/
	if (command == "lock") then
		if ( ActiveTankValues_Settings.IsLocked ) then
			ActiveTankValues_Main:RegisterForDrag("LeftButton");
			print("HMM: Frame unlocked.");
			ActiveTankValues_Settings.IsLocked = false;
		else
			ActiveTankValues_Main:RegisterForDrag();
			print("HMM: Frame locked.");
			ActiveTankValues_Settings.IsLocked = true;
		end
		ActiveTankValues:Check_Visibility();
	end
end