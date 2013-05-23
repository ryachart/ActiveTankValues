local HowMuchMitigation = {};

local class_spell_table = { 
			WARRIOR = "Shield Barrier", 
			DRUID = "Frenzied Regeneration"};
			
local mitigation_value_lookup = {
			WARRIOR = function()
				local ap = UnitAttackPower("player");
				local rage = min(60,UnitPower("player"));
				local str, effectiveStr, posBuffStr, negBuffStr = UnitStat("player", 1) --1 is str
				local sta, effectiveSta, posBuffSta, negBuffSta = UnitStat("player", 3) --3 is stamina
				if (rage < 20) then
					return 0;
				end
				local barrier_value = max(2*(ap - effectiveStr*2), sta*2.5) * rage/60;
				return math.floor(barrier_value);
			end,
			DRUID = function()
				local form = GetShapeshiftFormID();
				if (form ~= BEAR_FORM) then
					return 0;
				end
				local ap = UnitAttackPower("player");
				local rage = min(60,UnitPower("player"));
				local agi, effectiveAgi, posBuffAgi, negBuffAgi = UnitStat("player", 2) --2 is agi
				local sta, effectiveSta, posBuffSta, negBuffSta = UnitStat("player", 3) --3 is stamina
				if (rage == 0) then
					return 0;
				end
				local regen_value = max(2*(ap - effectiveAgi*2), sta*2.5) * rage/60;
				return math.floor(regen_value);
			end,
};

function HowMuchMitigation_OnLoad(self)
	SLASH_HOWMUCHMITIGATION1 = "/hmm";
	SlashCmdList["HOWMUCHMITIGATION"] = function(message, editbox) HowMuchMitigation:SlashCmd(message, editbox) end;
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:SetScript("OnEvent",function(self, event, ...)HowMuchMitigation[event](self, ...)end);
	HowMuchMitigation_MainText:SetText("0");
	if ( HowMuchMitigation_Settings == nil ) then
		HowMuchMitigation_Settings = { };
		HowMuchMitigation_Settings.IsLocked = false;
	end
end

function HowMuchMitigation:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2, ...)
	local class, classFileName = UnitClass("player");
	local resultValue = mitigation_value_lookup[classFileName]();
	if (resultValue == 0) then
		HowMuchMitigation_MainText:SetText();
	else 
		HowMuchMitigation_MainText:SetText(resultValue);
	end
	if (resultValue > 0) then
		HowMuchMitigation_MainButton1:Show();
	else
		HowMuchMitigation_MainButton1:Hide();
	end
end

function HowMuchMitigation:PLAYER_REGEN_DISABLED()
	HowMuchMitigation:Check_Visibility();
end

function HowMuchMitigation:PLAYER_REGEN_ENABLED()
	HowMuchMitigation:Check_Visibility();
end

function HowMuchMitigation:ACTIVE_TALENT_GROUP_CHANGED()
	HowMuchMitigation:Check_Visibility();
end

function HowMuchMitigation:PLAYER_ENTERING_WORLD()
	HowMuchMitigation:Check_Visibility();
	
	if (HowMuchMitigation_Settings.IsLocked) then
		self:RegisterForDrag();
	else
		self:RegisterForDrag("LeftButton");
	end
	local appropriateSpellTexture = GetSpellTexture(HowMuchMitigation:Appropriate_Spell());
	HowMuchMitigation_MainButton1:SetNormalTexture(appropriateSpellTexture);
end

function HowMuchMitigation:Check_Visibility()
	local inCombat = UnitAffectingCombat("player");
	local unlocked = not HowMuchMitigation_Settings.IsLocked;
	if ( HowMuchMitigation:Appropriate_Spell() and (inCombat or unlocked)) then
		HowMuchMitigation_Main:Show();
	else
		HowMuchMitigation_Main:Hide();
	end
end

function HowMuchMitigation:Appropriate_Spell()
	local class, classFileName = UnitClass("player");
	local spellName = class_spell_table[classFileName];
	local _, spellId = GetSpellBookItemInfo(spellName);
	if (spellId) then
		return spellName;
	else 
		return 0;
	end
end

function HowMuchMitigation:SlashCmd(message, editBox)
	local command, rest = message:match("^(%S*)%s*(.-)$");
	-- Nothing right now =/
	if (command == "lock") then
		if ( HowMuchMitigation_Settings.IsLocked ) then
			HowMuchMitigation_Main:RegisterForDrag("LeftButton");
			print("HMM: Frame unlocked.");
			HowMuchMitigation_Settings.IsLocked = false;
		else
			HowMuchMitigation_Main:RegisterForDrag();
			print("HMM: Frame locked.");
			HowMuchMitigation_Settings.IsLocked = true;
		end
		HowMuchMitigation:Check_Visibility();
	end
end