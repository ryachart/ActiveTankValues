local HowMuchMitigation = {};

function HowMuchMitigation_OnLoad(self)
{
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
}

function HowMuchMitigation:ACTIVE_TALENT_GROUP_CHANGED()
{
	HowMuchMitigation:Check_Visibility()
}

function HowMuchMitigation:PLAYER_ENTERING_WORLD()
{
	HowMuchMitigation:Check_Visibility()
}

function HowMuchMitigation:Check_Visibility()
{
	if ( HowMuchMitigation:Has_Any_Tracked_Ability() ) then
		ConsoleAddMessage("Detected the need to show this addon.")
		HowMuchMitigation_Main:Show();
	else
		ConsoleAddMessage("Detected the need to hide this addon.")
		HowMuchMitigation_Main:Hide();
	end
}

function HowMuchMitigation:Has_Any_Tracked_Ability()
{
	return HowMuchMitigation:HasShieldBarrier();
}

function HowMuchMitigation:Has_Shield_Barrier()
{
	local _, spellId = GetSpellBookItemInfo("Shield Barrier");
	if ( spellId ) then
		return true;
	end
	return false;
}