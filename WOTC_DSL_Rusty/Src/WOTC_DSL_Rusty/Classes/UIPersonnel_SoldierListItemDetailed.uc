//*******************************************************************************************
//  FILE:  Detailed Soldier List Item BY BOUNTYGIVER && RUSTYDIOS
//  
//	File CREATED 08/12/20	02:00	LAST UPDATED 05/08/24	04:00
//
//  Uses CHL issues #322 #1134 and expands on -bg-'s original DSL
//
//*******************************************************************************************
class UIPersonnel_SoldierListItemDetailed extends UIPersonnel_SoldierListItem config(Game);

var config int NUM_HOURS_TO_DAYS;
var config array<name> PSI_CLASSES;
var config bool POSITIVE_SHOW_PSI, ROOKIE_SHOW_PSI, ALWAYS_SHOW_PSI, ALWAYS_SHOW_WEAPONICONS, bFULL_NUM_DISPLAY, bRustyEnableDSLLogging, bRustyExtraIconPositionTest;
var config bool bSHOW_MAXHEALTH, bSTICKYLIST, bShouldAnimateBond, bShowAttentionBondmateHovered, bShowAttentionBondmateInSquad;
var config array<string> StatIconPath, APColours, APImagePath, NAColours, NAImagePath;
var config array<RPGOWeaponCatImage> RPGOWeaponCatImages; //Struct in MoreDetailsManager

var config bool bAddPerk_HP, bAddPerk_Mob, bAddPerk_Def, bAddPerk_Dodge, bAddPerk_Hack, bAddPerk_Psi, bAddPerk_Aim, bAddPerk_Will, bAddPerk_Armour, bAddPerk_Shields;
var config bool bAddGear_HP, bAddGear_Mob, bAddGear_Def, bAddGear_Dodge, bAddGear_Hack, bAddGear_Psi, bAddGear_Aim, bAddGear_Will, bAddGear_Armour, bAddGear_Shields;

var config int AWCTemplatesDisplayLength, TraitTemplatesDisplayLength;

//rank column
//Officer, SPARK, AP(RPGO), ComInt
var UIIcon	Icon_FlagTopNrm, Icon_FlagTopDis, Icon_FlagBotNrm, Icon_FlagBotDis, Icon_SlotR, Icon_Slot1;
var UIText  Text_SlotR,	Text_Slot1;

//name column
//Normal	Health, 	Mobility, 	Dodge, 		Defense, 	Hack, 		Psi, 		Aim, 		Will		Primary		Secondary
//Detailed	Armour,		Shield,		Missions,	XPShare,							Kills,		PCS
var UIImage	Icon_Slot2, Icon_Slot3,	Icon_Slot4,	Icon_Slot5,	Icon_Slot6, Icon_Slot7,	Icon_Slot8,	Icon_Slot9,	Icon_SlotP, Icon_SlotS; 
var UIText  Text_Slot2,	Text_Slot3,	Text_Slot4,	Text_Slot5, Text_Slot6, Text_Slot7, Text_Slot8, Text_Slot9;

var float IconXPos, IconYPos, IconXDelta, IconScale, IconToTextOffsetX, IconToTextOffsetY, IconXDeltaSmallValue, DisabledAlpha;
var float TraitIconX, AbilityIconX, TraitIconY, AbilityIconY;

//perk displays
var UIPanel BadTraitPanel, BonusAbilityPanel;
var array<UIIcon> BadTraitIcons, BonusAbilityIcons;
var array<X2AbilityTemplate> AWCTemplates;
var array<X2TraitTemplate> TraitTemplates;

//var UIProgressBar BondProgressBar;
var UIProgressBar_DSL_Bond BondProgressBar;
var float BondIconX, BondIconY, BondBarWidth, BondBarHeight;

//other values
var bool bIsFocussed, bShouldHideBonds, bShouldShowBondProgressBar, bShouldShowDetailed, bRPGODetected;
var string strUnitName, strClassName, PCSImage, PCSName, PCSStats, LoadoutImageP, LoadoutImageS, DisabledToolTipText;
var string statsRPGO, statsAP, statsHealth, statsMobility, statsDodge, statsDefense, statsHack, statsPsi, statsAim, statsWill;
var string statsArmor, statsShields, statsMissions, statsXP, statsKills;
var int intAptitude, Text_Slot9_X_WILL, Text_Slot9_X_PCS, Icon_Slot9_X_WILL, Icon_Slot9_X_PCS;
var eUIState PCSState, HPState;

//from parents values
//var UIPanel BG;
//var StateObjectReference UnitRef;
//var UIImage PsiMarkup;
//var UIBondIcon BondIcon;
//var bool m_bIsDisabled;
//var localized string BondmateTooltip; 

////////////////////////////////////////////////
//	ON INIT
////////////////////////////////////////////////

simulated function InitListItem(StateObjectReference initUnitRef)
{
	local XComGameState_Unit Unit;
	local UIList ContainerList;

	super.InitListItem(initUnitRef);

	class'MoreDetailsManager'.static.GetOrSpawnParentDM(self).IsMoreDetails = false;
	bRPGODetected = class'X2DownloadableContentInfo_WOTC_DSL_Rusty'.static.IsRPGOLoaded();
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(initUnitRef.ObjectID));
	
	SetUnitStats(Unit);

	AddAdditionalItems(Unit, self);
	UpdateAdditionalItems(self);

	// HAX: get parent list to manipulate
	if (default.bSTICKYLIST)
	{
		ContainerList = UIList(GetParent(class'UIList'));
		ContainerList.bStickyHighlight = true;
	}
}

////////////////////////////////////////////////
//	BUILD SCREEN
////////////////////////////////////////////////

simulated function AddAdditionalItems(XComGameState_Unit Unit, UIPersonnel_SoldierListItemDetailed ListItem)
{
	local StackedUIIconData StackedClassIcon; // Variable for issue #1134

	///////////////////////////////////////////////
    //	shift old rows up to create space
	///////////////////////////////////////////////
    
	//	check language for icon offset
	if(GetLanguage() == "JPN") { IconToTextOffsetY = -3.0; }

    ListItem.MC.ChildSetNum("RankFieldContainer", "_y", (GetLanguage() == "JPN" ? -3 : 0));

	ListItem.MC.ChildSetString("NameFieldContainer.NameField", "htmlText", class'UIUtilities_Text'.static.GetColoredText(strUnitName, eUIState_Normal));
	ListItem.MC.ChildSetNum("NameFieldContainer.NameField", "_y", (GetLanguage() == "JPN" ? -25 :-22));

	ListItem.MC.ChildSetString("NicknameFieldContainer.NicknameField", "htmlText", " ");
	ListItem.MC.ChildSetBool("NicknameFieldContainer.NicknameField", "_visible", false);

	ListItem.MC.ChildSetNum("ClassFieldContainer", "_y", (GetLanguage() == "JPN" ? -3 : 0));

	///////////////////////////////////////////////
    //	shift old icons to fit panel better
	///////////////////////////////////////////////
	ListItem.MC.ChildSetNum("FlagIconMC.imageTarget", "_y", 2);

	ListItem.MC.ChildSetNum("RankMC.iconTarget", "_y", 4);

	ListItem.MC.ChildSetNum("ClassMC.iconTarget", "_x", 4);
	ListItem.MC.ChildSetNum("ClassMC.iconTarget", "_y", 4);

	ListItem.MC.ChildSetNum("FactionLogoMC", "ImageOffset", 3);
	ListItem.MC.ChildSetBool("FactionLogoMC", "bHasBeenSetUp", false);

	StackedClassIcon = Unit.GetStackedClassIcon();
	AS_SetFactionIcon(StackedClassIcon);

	///////////////////////////////////////////////
    //	add icons in rows per divider
	///////////////////////////////////////////////

    AddRankColumnIcons(Unit, ListItem);
	AddNameColumnIcons(Unit, ListItem);
	AddSpecColumnIcons(Unit, ListItem);
}

////////////////////////////////////////////////
//  INFORMATION GATHERING
///////////////////////////////////////////////

simulated function SetUnitStats(XComGameState_Unit Unit)
{
	local UnitValue RPGOValue;
	local int HealthCur, HealthMax, WillCur, WillMax;

	// Get Unit base stats and any stat modifications from abilities
    statsAP 		= string(Unit.AbilityPoints);
    
	HealthCur		= GetUnitStatsValue(Unit, eStat_HP, default.bAddPerk_HP, default.bAddGear_HP);
	HealthMax		= GetUnitStatsValue(Unit, eStat_HP, default.bAddPerk_HP, default.bAddGear_HP, true);
	HPState 		= HealthCur < HealthMax ? eUIState_Warning : eUIState_Good;
   	statsHealth 	= default.bSHOW_MAXHEALTH ? HealthCur $"/" $HealthMax : string(HealthCur);

	WillCur			= GetUnitStatsValue(Unit, eStat_Will, default.bAddPerk_Will, default.bAddGear_Will);
	WillMax			= GetUnitStatsValue(Unit, eStat_Will, default.bAddPerk_Will, default.bAddGear_Will, true);
   	statsWill 		= WillCur $"/" $WillMax;

	statsMobility 	= string(GetUnitStatsValue(Unit, eStat_Mobility, 		default.bAddPerk_Mob, 		default.bAddGear_Mob));
	statsDefense 	= string(GetUnitStatsValue(Unit, eStat_Defense, 		default.bAddPerk_Def, 		default.bAddGear_Def));
	statsDodge 		= string(GetUnitStatsValue(Unit, eStat_Dodge, 			default.bAddPerk_Dodge, 	default.bAddGear_Dodge));
	statsHack 		= string(GetUnitStatsValue(Unit, eStat_Hacking, 		default.bAddPerk_Hack, 		default.bAddGear_Hack));
	statsPsi 		= string(GetUnitStatsValue(Unit, eStat_PsiOffense, 		default.bAddPerk_Psi, 		default.bAddGear_Psi));
	statsAim 		= string(GetUnitStatsValue(Unit, eStat_Offense, 		default.bAddPerk_Aim, 		default.bAddGear_Aim));

	statsArmor 		= string(GetUnitStatsValue(Unit, eStat_ArmorMitigation,	default.bAddPerk_Armour, 	default.bAddGear_Armour));
	statsShields 	= string(GetUnitStatsValue(Unit, eStat_ShieldHP, 		default.bAddPerk_Shields,	default.bAddGear_Shields));

	statsMissions	= string(Unit.GetNumMissions());
	statsKills 		= string(Unit.GetNumKills());
	statsXP 		= GetPromotionProgress(Unit);
	
	//PCSStats 		= GetPCSString(Unit);
	//PCSImage 		= GetPCSImageForUnit(Unit);
	//PCSName		= GetPCSNameForUnit(Unit);

	SetPCSDetails(Unit); // PCSStats, PCSImage, PCSName, PCSState

	if(Unit.GetName(eNameType_Nick) == " ")	{ strUnitName = CAPS(Unit.GetName(eNameType_First) @ Unit.GetName(eNameType_Last));	}
	else	{ strUnitName = CAPS(Unit.GetName(eNameType_First) @ Unit.GetName(eNameType_Nick) @ Unit.GetName(eNameType_Last));	}

	LoadoutImageP = GetRPGOCatImage(X2WeaponTemplate(Unit.GetPrimaryWeapon().GetMyTemplate()).WeaponCat);
	LoadoutImageS = GetRPGOCatImage(X2WeaponTemplate(Unit.GetSecondaryWeapon().GetMyTemplate()).WeaponCat);

	// <> TODO : can't confirm item in pistol slot will be weapon or how to get pistol slot
	//LoadoutImageT = GetRPGOCatImage(X2WeaponTemplate(Unit.Get-ITEMSLOT-.GetMyTemplate()).WeaponCat); 

	Unit.GetUnitValue('NaturalAptitude', RPGOValue);	intAptitude = int(RPGOValue.fValue);
	Unit.GetUnitValue('StatPoints', RPGOValue);			statsRPGO 	= string(int(RPGOValue.fValue));

	//YES things are offset here so they appear correct in the log, stop changing it damn OCD !!
	`LOG( "RUSTY DSL PANEL INITIED FOR UNIT \n"
		 $"UNIT NAME	[" @strUnitName @"] \n"
		 $"PRIMARY	IMG	[" @LoadoutImageP @"] \n"
		 $"SECONDARY IMG[" @LoadoutImageS @"] \n"
		 $"AP			[" @statsAP @"] \n"
		 $"HEALTH		[" @statsHealth @"] \n"
		 $"MOBILITY		[" @statsMobility @"] \n"
		 $"DEFENSE		[" @statsDefense @"] \n"
		 $"DODGE		[" @statsDodge @"] \n"
		 $"HACK			[" @statsHack @"] \n"
		 $"PSI			[" @statsPsi @"] \n"
		 $"AIM			[" @statsAim @"] \n"
		 $"WILL			[" @statsWill @"] \n"
		 $"ARMOUR		[" @statsArmor @"] \n"
		 $"SHIELDS		[" @statsShields @"] \n"
		 $"MISSIONS		[" @statsMissions @"] \n"
		 $"XPSHARE		[" @statsXP @"] \n"
		 $"KILLS		[" @statsKills @"] \n"
		 $"PCS STATS	[" @PCSStats @"] \n"
		 $"PCS ICON		[" @PCSImage @"] \n"
		 $"PCS NAME		[" @PCSName @"] \n"
		 $"PCS STATE	[" @PCSState @"] \n"
		 $"APTITUDE		[" @intAptitude @"] \n"
		 $"RPGOSTAT		[" @statsRPGO @"]"
		 , default.bRustyEnableDSLLogging, 'DSLRusty_STATS');
}

	///////////////////////////////////////////////
    //	FIND STAT COMBINED VALUE
	///////////////////////////////////////////////

simulated function int GetUnitStatsValue(XComGameState_Unit Unit, ECharStatType Stat, bool bAddPerk, bool bAddGear, optional bool bIsMax)
{
	local int StatValue;

	//GET BASE VALUE, ARMOUR IS DIFFERENT, FIGURE OUT IF WE NEED MAX OR CURRENT
	if (Stat == eStat_ArmorMitigation )	{ StatValue = int(Unit.GetArmorMitigationForUnitFlag()); }
	else	 { StatValue = bIsMax ? int(Unit.GetMaxStat(Stat)) : int(Unit.GetCurrentStat(Stat)); }

	//ADD TO STAT VALUE FROM VARIOUS PLACES
	if (bAddPerk) { StatValue += Unit.GetUIStatFromAbilities(Stat); }
	if (bAddGear) { StatValue += Unit.GetUIStatFromInventory(Stat); }

	//RETURN COMBINED TOTAL
	return StatValue;
}

	///////////////////////////////////////////////
    //	FIND WEAPON CATEGORY IMAGE
	///////////////////////////////////////////////

simulated function string GetRPGOCatImage(name ItemCat)
{
	local RPGOWeaponCatImage RPGOWCI;

	foreach default.RPGOWeaponCatImages(RPGOWCI)
	{
		if (RPGOWCI.Category == ItemCat)
		{
			return "img:///" $ RPGOWCI.ImagePath;
		}
	}

	return "img:///UILibrary_RPGO_DSL.loadout_icon_empty";
}

	///////////////////////////////////////////////
    //	FIND AND SET PCS DETAILS
	///////////////////////////////////////////////

simulated function SetPCSDetails(XComGameState_Unit Unit)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> EquippedImplants;
	local XComGameState_Item FirstPCS;
	local int i, HPIndex, TotalBoost, BoostValue;
	local string strBoostValue, strTotalBoost;
	local bool bHasStatBoostBonus, bUsingBoostIncrements;

	XComHQ = `XCOMHQ;
	if (XComHQ != none)	{ bHasStatBoostBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;	}

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	if (EquippedImplants.Length > 0)
	{
		FirstPCS = EquippedImplants[0];
		strTotalBoost = "";
		strBoostValue = "";

		if (FirstPCS != none)
		{
			bUsingBoostIncrements = X2EquipmentTemplate(FirstPCS.GetMyTemplate()).bUseBoostIncrement;
			HPIndex = FirstPCS.StatBoosts.Find('StatType', eStat_HP);

			for (i = 0 ; i < FirstPCS.StatBoosts.length ; i++)
			{
				//GET VALUE OF THIS BOOST
				BoostValue = FirstPCS.StatBoosts[i].Boost;

				//INCREASE VALUE BASED ON INTEGRATED WARFARE
				if (bHasStatBoostBonus)
				{				
					if (bUsingBoostIncrements) { BoostValue += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement; }
					else { BoostValue += Round(BoostValue * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue); }
				}

				//increase HP if HP is the stat we're collecting and BetaStrike is ON
				if (i == HPIndex && `SecondWaveEnabled('BetaStrike') ) 
				{
					BoostValue *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
				}

				//CONVERT TO AND MERGE STRINGS
				TotalBoost += BoostValue;
				strBoostValue = (BoostValue > 0 ? "+" : "") $ string(BoostValue);

				if (strTotalBoost != "") { strTotalBoost $= ":"; }
				strTotalBoost $= strBoostValue;
			}

			//SET PCS STRINGS
			PCSStats = strTotalBoost;
			PCSImage = class'UIUtilities_Image'.static.GetPCSImage(FirstPCS);
			PCSName = ColorText("PCS:","27AAE1") $ Repl(FirstPCS.GetMyTemplate().GetItemFriendlyName(FirstPCS.ObjectID), "PCS:", "");
		}
	}

	//SET PCS STATE >0 GOOD, <0 BAD, 0 NORMAL
	if(TotalBoost != 0) { PCSState = TotalBoost > 0 ? eUIState_Good : eUIState_Bad; } else { PCSState = eUIState_Normal; }

}

	///////////////////////////////////////////////
    //	FIND PCS IMAGE - DEPRECIATED
	///////////////////////////////////////////////

simulated function string GetPCSImageForUnit(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> EquippedImplants;

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	if (EquippedImplants.Length > 0) { return class'UIUtilities_Image'.static.GetPCSImage(EquippedImplants[0]);	}
	return "";
}

	///////////////////////////////////////////////
    //	FIND PCS NAME - DEPRECIATED
	///////////////////////////////////////////////

simulated function string GetPCSNameForUnit(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> EquippedImplants;

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	if (EquippedImplants.Length > 0) { return ColorText("PCS:","53B45E") @ EquippedImplants[0].GetMyTemplate().GetItemFriendlyName(EquippedImplants[0].ObjectID); }
	return "";
}

	///////////////////////////////////////////////
    //	FIND PCS VALUE AND COLOUR - DEPRECIATED
	///////////////////////////////////////////////

simulated function string GetPCSString(XComGameState_Unit Unit)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> EquippedImplants;
	local XComGameState_Item ImplantToAdd;
	local int i, Index, TotalBoost, BoostValue;
	local bool bHasStatBoostBonus, bUsingBoostIncrements;

	XComHQ = `XCOMHQ;

	if (XComHQ != none)	{ bHasStatBoostBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;	}

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	if (EquippedImplants.Length > 0)
	{
		ImplantToAdd = EquippedImplants[0];
	}
	
	if(ImplantToAdd != none)
	{
		Index = ImplantToAdd.StatBoosts.Find('StatType', eStat_HP);
		bUsingBoostIncrements = X2EquipmentTemplate(ImplantToAdd.GetMyTemplate()).bUseBoostIncrement;

		for (i = 0; i < ImplantToAdd.StatBoosts.length ; i++)
		{
			BoostValue = ImplantToAdd.StatBoosts[0].Boost;

			if (bHasStatBoostBonus)
			{				
				if (bUsingBoostIncrements) { BoostValue += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement; }
				else { BoostValue += Round(BoostValue * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue); }
			}
			
			if (i == Index) //only increase beta strike HP if HP is the stat we're collecting
			{
				if (`SecondWaveEnabled('BetaStrike'))
				{
					BoostValue *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
				}
			}

			TotalBoost += BoostValue;
		}
	}

	if(TotalBoost != 0)
    {
		PCSState = TotalBoost > 0 ? eUIState_Good : eUIState_Bad;
		return (TotalBoost > 0 ? "+" : "") $ string(TotalBoost);
    }
	else
	{
		PCSState = eUIState_Normal;
	}

	return "";
}

	///////////////////////////////////////////////
    //	FIND UNITS CURRENT XP SHARES
	///////////////////////////////////////////////

simulated function string GetPromotionProgress(XComGameState_Unit Unit)
{
	local X2SoldierClassTemplate ClassTemplate;
	local string promoteProgress;
	local int NumKills, XPThreshold, KillAssistValue;

    //BAIL FOR NON SOLDIER UNITS
	if (Unit.IsSoldier()) { ClassTemplate = Unit.GetSoldierClassTemplate();	}
	else { return "--";	}

    // BAIL FOR NO CLASS
	// BAIL FOR UNITS THAT DONT RANK UP (PSI OPS, BUILDABLE UNITS, SHEN, CENTRAL, VIPS) AND CONFIG SET TO BLOCK TOO 
	// BAIL FOR MAX RANK UNITS THAT ARE NOT ROOKIES (AS ROOKIE HAS ONLY 1 RANK SO WOULD ALWAYS BE MAX RANK)
	if (ClassTemplate == none || Unit.GetSoldierRank() >= ClassTemplate.GetMaxConfiguredRank() && ClassTemplate.DataName != 'Rookie' || ClassTemplate.bBlockRankingUp)
	{
		return "--";
	}

    // ===== DISPLAY ===== //
	XPThreshold = class'X2ExperienceConfig'.static.GetRequiredKills(Unit.GetSoldierRank() + 1);
	KillAssistValue = max(1, ClassTemplate.KillAssistsPerKill); //minimum value is 1 for multiplication, because some mods might not set this at all and default is 0

    if (default.bFULL_NUM_DISPLAY)
    {
		NumKills  = Round(Unit.KillCount);															// Basic Kills Made
		NumKills += Round(Unit.BonusKills);															// Add in bonus kills
		NumKills += Unit.NonTacticalKills;															// Add Non-tactical kills (from covert actions)
		NumKills += class'X2ExperienceConfig'.static.GetRequiredKills(Unit.StartingRank);			// Add required kills of StartingRank
		NumKills += Round((Unit.WetWorkKills * class'X2ExperienceConfig'.default.NumKillsBonus));	// Increase kills for WetWork bonus if appropriate - DEPRECATED

		NumKills = NumKills * KillAssistValue;														// Multiply the above for Kill Assists 'Full' Count

		//NumKills += Round(Unit.GetNumKillsFromAssists());											// Add number of kills from assists - Using Split Method
		NumKills += Round(Unit.KillAssistsCount);													// Add number of kills from assists
		NumKills += Round(Unit.PsiCredits);															// Add number of kills from psi assists

		NumKills = Unit.TriggerOverrideTotalNumKills(NumKills / KillAssistValue) * KillAssistValue;	//CHL Override for total, to include LW Mission Based XP!

		promoteProgress = NumKills $ "/" $ XPThreshold * KillAssistValue;
	}
	else
    {
		NumKills = Unit.GetTotalNumKills();
        promoteProgress = NumKills $ "/" $ XPThreshold;
    }

	return promoteProgress;
}

	/////////////////////////////////////////////////////
    //	CONSTRUCT TIME VALUE - NON CHL
	/////////////////////////////////////////////////////

static function GetTimeLabelValue(int Hours, out int TimeValue, out string TimeLabel)
{	
	if (Hours < 0 || Hours > 24 * 30 * 12) // Ignore year long missions
	{
		TimeValue = 0;
		TimeLabel = "-+-";
		return;
	}

	if (Hours > default.NUM_HOURS_TO_DAYS)
	{
		Hours = FCeil(float(Hours) / 24.0f);
		TimeValue = Hours;
		TimeLabel = class'UIUtilities_Text'.static.GetDaysString(Hours);
	}
	else
	{
		TimeValue = Hours;
		TimeLabel = class'UIUtilities_Text'.static.GetHoursString(Hours);
	}
}

	/////////////////////////////////////////////////////
    //	STATUS DISPLAY MESSAGE - NON CHL
	//	TECHNICALLY NOT NEEDED ANYMORE BUT KEPT FOR REF
	/////////////////////////////////////////////////////

static function GetStatusStringsSeparate(XComGameState_Unit Unit, out string Status, out string TimeLabel, out int TimeValue)
{
	local bool bProjectExists;
	local int iHours;
	local LWTuple Tuple;

	Tuple = new class'LWTuple';
	Tuple.Id = 'CustomizeStatusStringsSeparate';
	Tuple.Data.Add(4);
	Tuple.Data[0].kind = LWTVBool;		Tuple.Data[0].b = false;
	Tuple.Data[1].kind = LWTVString;	Tuple.Data[1].s = Status;
	Tuple.Data[2].kind = LWTVString;	Tuple.Data[2].s = TimeLabel;
	Tuple.Data[3].kind = LWTVInt;		Tuple.Data[3].i = TimeValue;

	`XEVENTMGR.TriggerEvent('CustomizeStatusStringsSeparate', Tuple, Unit);

	if (Tuple.Data[0].b)
	{
		Status = Tuple.Data[1].s;
		TimeLabel = Tuple.Data[2].s;
		TimeValue = Tuple.Data[3].i;

		return;
	}
	
	if (Unit.IsOnCovertAction()) //moved above wounded as wounded sparks can go on covert ops now ... 
	{
		Status = Unit.GetCovertActionStatus(iHours);
		if (Status != "")
        {
			bProjectExists = true;
        }
	}
	else if( Unit.IsInjured() )
	{
		Status = Unit.GetWoundStatus(iHours);
		if (Status != "")
        {
			bProjectExists = true;
        }
	}
	else if (Unit.IsTraining() || Unit.IsPsiTraining() || Unit.IsPsiAbilityTraining())
	{
		Status = Unit.GetTrainingStatus(iHours);
		if (Status != "")
        {
			bProjectExists = true;
        }
	}
	else if( Unit.IsDead() )
	{
		Status = "KIA";
	}
	else
	{
		Status = "";
	}
	
	if (bProjectExists)
	{
		GetTimeLabelValue(iHours, TimeValue, TimeLabel);
	}
}

	/////////////////////////////////////////////////////
    //	PERSONNEL STATUS - NON CHL
	//	TECHNICALLY NOT NEEDED ANYMORE BUT KEPT FOR REF
	/////////////////////////////////////////////////////

static function GetPersonnelStatusSeparate(XComGameState_Unit Unit, out string Status, out string TimeLabel, out string TimeValue, optional int FontSizeZ = -1, optional bool bIncludeMentalState = false)
{
	local EUIState eState; 
	local int TimeNum;
	local bool bHideZeroDays;

	bHideZeroDays = true;

	if(Unit.IsMPCharacter())
	{
		Status = class'UIUtilities_Strategy'.default.m_strAvailableStatus;
		eState = eUIState_Good;
		TimeNum = 0;
		Status = class'UIUtilities_Text'.static.GetColoredText(Status, eState, FontSizeZ);
		return;
	}

	// template names are set in X2Character_DefaultCharacters.uc
	if (Unit.IsScientist() || Unit.IsEngineer())
	{
		// CHL: The old GetPersonnelStatusSeparate() implementation just returned the location
		// but I think that's because it was never called for any unit other than soldiers.
		// This seems more correct.
		if (Unit.IsInjured())
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Bad;
		}
		else if (Unit.IsOnCovertAction())
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Warning;
		}
		else 
		{
			Status = class'UIUtilities_Text'.static.GetSizedText(Unit.GetLocation(), FontSizeZ);
		}
	}
	else if (Unit.IsSoldier())
	{
		// soldiers get put into the hangar to indicate they are getting ready to go on a mission
		if(`HQPRES != none &&  `HQPRES.ScreenStack.IsInStack(class'UISquadSelect') && `XCOMHQ.IsUnitInSquad(Unit.GetReference()) )
		{
			Status = class'UIUtilities_Strategy'.default.m_strOnMissionStatus;
			eState = eUIState_Highlight;
		}
		else if (Unit.bRecoveryBoosted)
		{
			Status = class'UIUtilities_Strategy'.default.m_strBoostedStatus;
			eState = eUIState_Warning;
		}
		else if(  Unit.IsOnCovertAction() ) //moved above wounded as wounded sparks can go on covert ops now ... 
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Warning;
			bHideZeroDays = false;
		}
		else if( Unit.IsInjured() || Unit.IsDead() )
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Bad;
		}
		else if(Unit.GetMentalState() == eMentalState_Shaken)
		{
			GetUnitMentalState(Unit, Status, TimeLabel, TimeNum);
			eState = Unit.GetMentalStateUIState();
		}
		else if( Unit.IsPsiTraining() || Unit.IsPsiAbilityTraining() )
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Psyonic;
		}
		else if( Unit.IsTraining() )
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			eState = eUIState_Warning;
		}
		else if(bIncludeMentalState && Unit.BelowReadyWillState())
		{
			GetUnitMentalState(Unit, Status, TimeLabel, TimeNum);
			eState = Unit.GetMentalStateUIState();
		}
		else
		{
			GetStatusStringsSeparate(Unit, Status, TimeLabel, TimeNum);
			if (Status == "")
			{
				Status = class'UIUtilities_Strategy'.default.m_strAvailableStatus;
				TimeNum = 0;
			}
			eState = eUIState_Good;
		}
	}

	Status = class'UIUtilities_Text'.static.GetColoredText(Status, eState, FontSizeZ);
	TimeLabel = class'UIUtilities_Text'.static.GetColoredText(TimeLabel, eState, FontSizeZ);

	if( TimeNum == 0 && bHideZeroDays )
    {
		TimeValue = "";
    }
	else
    {
		TimeValue = class'UIUtilities_Text'.static.GetColoredText(string(TimeNum), eState, FontSizeZ);
    }
}

	///////////////////////////////////////////////
    //	MENTAL STATUS - NON CHL BUT CHL IMPROVED
	///////////////////////////////////////////////

static function GetUnitMentalState(XComGameState_Unit UnitState, out string Status, out string TimeLabel, out int TimeValue)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectRecoverWill WillProject;
	local int iHours;

	History = `XCOMHISTORY;
	Status = UnitState.GetMentalStateLabel();
	TimeLabel = "";
	TimeValue = 0;

	if(UnitState.BelowReadyWillState())
	{
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRecoverWill', WillProject)
		{
			if(WillProject.ProjectFocus.ObjectID == UnitState.ObjectID)
			{
				iHours = WillProject.GetCurrentNumHoursRemaining();
				TimeValue = iHours;

				// Start Issue #322
				class'UIUtilities_Strategy'.static.TriggerOverridePersonnelStatusTime(UnitState, true, TimeLabel, TimeValue);

				// If no override has been provided, i.e. the time label is still an empty string, then default to the old modded behavior.
				if (TimeLabel == "")
				{
					GetTimeLabelValue(iHours, TimeValue, TimeLabel);
				}

				break;
			}
		}
	}
}

////////////////////////////////////////////////
//  INFORMATION GATHERING -- TO DISPLAY ITEMS
///////////////////////////////////////////////

	///////////////////////////////////////////////
    //	TOP FLAG ITEM -- 'OFFICER ICON'
	///////////////////////////////////////////////

simulated function bool ShouldShowIcon_FlagTopNrm(XComGameState_Unit Unit)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'ShouldShowIcon_FlagTopNrm';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;	Tuple.Data[0].b = false;
	Tuple.Data[1].kind = XComLWTVName;	Tuple.Data[1].n = nameof(Screen.class);

	`XEVENTMGR.TriggerEvent('DSLShouldShowIcon_FlagTopNrm', Tuple, Unit);

	return Tuple.Data[0].b;
}

	///////////////////////////////////////////////
    //	BOTTOM FLAG ITEM -- 'SPARK ICON'
	///////////////////////////////////////////////

simulated function bool ShouldShowIcon_FlagBotNrm(XComGameState_Unit Unit)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'ShouldShowIcon_FlagBotNrm';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;	Tuple.Data[0].b = false;
	Tuple.Data[1].kind = XComLWTVName;	Tuple.Data[1].n = nameof(Screen.class);

	`XEVENTMGR.TriggerEvent('DSLShouldShowIcon_FlagBotNrm', Tuple, Unit);

	return Tuple.Data[0].b;
}

	///////////////////////////////////////////////
    //	PSI VALUE -- PRETTY MUCH ALWAYS ON NOW
	///////////////////////////////////////////////

simulated function bool ShouldShowPsi(XComGameState_Unit Unit)
{
	local LWTuple Tuple;	//OLDTUPLE SO OLD

	//we have no reason not to show any more so we can just override for this DSL redux
    if (default.ALWAYS_SHOW_PSI) { return true; }

	//create tuple here so we can set our config as a default and then mods can override if they want
	//personally not sure the purpose of sending the screen class name but need to keep it for backwards compatibility
	Tuple = new class'LWTuple';
	Tuple.Id = 'ShouldShowPsi';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = LWTVBool;	Tuple.Data[0].b = false;
	Tuple.Data[1].kind = LWTVName;	Tuple.Data[1].n = nameof(Screen.class);

	//config setings from this mod
	if (Unit.IsPsiOperative()
		|| (default.PSI_CLASSES.Find(Unit.GetSoldierClassTemplateName()) != INDEX_NONE)
		|| (default.ROOKIE_SHOW_PSI && Unit.GetRank() == 0)
		|| (default.POSITIVE_SHOW_PSI && Unit.GetCurrentStat(eStat_PsiOffense) > 0 )
	)
	{
		Tuple.Data[0].b = true;
	}

	//allow other mods to override or adjust
	`XEVENTMGR.TriggerEvent('DSLShouldShowPsi', Tuple, Unit);

	//return result
	return Tuple.Data[0].b;
}

	///////////////////////////////////////////////
    //	SHOW WEAPON ICONS
	///////////////////////////////////////////////

static function bool ShouldDisplayWeaponIcons( XComGameState_Unit Unit, bool bRPGO)
{
	local XComLWTuple Tuple;

    if (default.ALWAYS_SHOW_WEAPONICONS) { return true; }

	Tuple = new class'XComLWTuple';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;		Tuple.Data[0].b = bRPGO; //false;
	Tuple.Data[1].kind = XComLWTVObject;	Tuple.Data[1].o = Unit;

	`XEVENTMGR.TriggerEvent('DSLShouldDisplayWeaponIcons', Tuple, Unit);

	return Tuple.Data[0].b;
}

	///////////////////////////////////////////////
    //	SHOW MENTAL STATE
	///////////////////////////////////////////////

simulated protected function bool ShouldDisplayMentalStatus (XComGameState_Unit Unit)
{
	// Use the Community Highlander event so that we work with mods that use the mental status display override hook
	//if (class'X2DownloadableContentInfo_WOTC_DSL_Rusty'.default.bForceHighlanderMethod)
	//{
		return TriggerShouldDisplayMentalStatus(Unit);
	//}

	// Fallback to default logic
	//return Unit.IsActive();
}

//copied from CHL Start issue #651
simulated protected function bool TriggerShouldDisplayMentalStatus (XComGameState_Unit Unit)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;		Tuple.Data[0].b = Unit.IsActive(); //FALLBACK TO DEFAULT LOGIC
	Tuple.Data[1].kind = XComLWTVObject;	Tuple.Data[1].o = Unit;

	`XEVENTMGR.TriggerEvent('SoldierListItem_ShouldDisplayMentalStatus', Tuple, self);

	return Tuple.Data[0].b;
}

///////////////////////////////////////////////////////////////
//  UPDATE DATA  THIS IS WHERE WE UPDATE THE BASE SCREEN
///////////////////////////////////////////////////////////////

simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local string flagIcon, rankIcon, rankShort, classIcon, classname, mentalStatus, status, statusTimeLabel, statusTimeValue, UnitLoc;
	local int iRank, iTimeNum, BondLevel;
	
	//local X2SoldierClassTemplate SoldierClass;

	local XComGameState_ResistanceFaction FactionState;
	local StackedUIIconData StackedClassIcon, EmptyIconInfo; // Variable for issue #1134 and #295

	local XComLWTuple Tuple;

	//FOR THIS UNIT
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	//ABORT IF UNIT DOES NOT EXIST! HOW?
	if (Unit == none) { return;	}

	//==================================================
	//CHECK LW UNIT/OFFICER STATUS
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'GetLWUnitInfo';
	Tuple.Data.Add(9);
	Tuple.Data[0].kind = XComLWTVBool;		Tuple.Data[0].b = false;	//Is the unit an Officer
	Tuple.Data[1].kind = XComLWTVInt;		Tuple.Data[1].i = -1;		//Officer Rank integer value
	Tuple.Data[2].kind = XComLWTVString;	Tuple.Data[2].s = "";		//Officer Rank Full Name string
	Tuple.Data[3].kind = XComLWTVString;	Tuple.Data[3].s = "";		//Officer Rank Short string
	Tuple.Data[4].kind = XComLWTVString;	Tuple.Data[4].s = "";		//Officer Rank Icon Path
	Tuple.Data[5].kind = XComLWTVBool;		Tuple.Data[5].b = false;	//Is a Haven Liason
	Tuple.Data[6].kind = XComLWTVObject;	Tuple.Data[6].o = none;		//XComGameState_WorldRegion object for the region the unit is located in
	Tuple.Data[7].kind = XComLWTVBool;		Tuple.Data[7].b = false;	//Is the unit Locked in their Haven
	Tuple.Data[8].kind = XComLWTVBool;		Tuple.Data[8].b = false;	//Is this unit on a mission right now

	`XEVENTMGR.TriggerEvent('GetLWUnitInfo', Tuple, Unit, none);
	//==================================================

	///////////////////////////////////////////////
	//	RANK AND CLASS ICONS FROM CHL OR NOT
	///////////////////////////////////////////////

	//AS CHL IS NOW HARDCODED REQUIRED MOD JUST COMMENT OUT THE OTHER METHODS HERE
	//if (class'X2DownloadableContentInfo_WOTC_DSL_Rusty'.default.bForceHighlanderMethod )
	//{
		// Use the Community Highlander function so that we work with mods that use the unit status hooks it provides.
		class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, status, statusTimeLabel, statusTimeValue);

		iRank 	  = Tuple.Data[0].b ? Tuple.Data[1].i : Unit.GetRank();
		rankIcon  = Tuple.Data[0].b ? Tuple.Data[4].s : Unit.GetSoldierRankIcon(iRank);			// Issue #408
		rankshort = Tuple.Data[0].b ? Tuple.Data[3].s : Unit.GetSoldierShortRankName(iRank);
		classIcon = Unit.GetSoldierClassIcon();				// Issue #106
		classname = Unit.GetSoldierClassDisplayName();
	//}
	//else
	//{
		//Use THIS MODS internal function, updated with some CHL features
	//	GetPersonnelStatusSeparate(Unit, status, statusTimeLabel, statusTimeValue);

		//OLD methods to get the information that do not require CHL !ugh!
	//	SoldierClass = Unit.GetSoldierClassTemplate();
	//	rankIcon  = Tuple.Data[0].b ? Tuple.Data[4].s : class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	//	rankshort = Tuple.Data[0].b ? Tuple.Data[3].s : `GET_RANK_ABBRV(Unit.GetRank(), SoldierClass.DataName);
	//	classIcon = SoldierClass.IconImage;
	//	classname = SoldierClass != None ? SoldierClass.DisplayName : "";
	//}

	///////////////////////////////////////////////
	//	LOCATION, TIME AND MENTAL STATUS DISPLAY
	///////////////////////////////////////////////

	mentalStatus = "";
	if(ShouldDisplayMentalStatus(Unit))
	{
		//CHL IMPROVED MENTAL STATUS
		GetUnitMentalState(Unit, mentalStatus, statusTimeLabel, iTimeNum);
		statusTimeLabel = class'UIUtilities_Text'.static.GetColoredText(statusTimeLabel, Unit.GetMentalStateUIState());

		if(iTimeNum != 0)
		{
			statusTimeValue = class'UIUtilities_Text'.static.GetColoredText(string(iTimeNum), Unit.GetMentalStateUIState());
		}
	}

	if (statusTimeValue == "") { statusTimeValue = "---"; }

	// if personnel is not staffed, don't show location
	UnitLoc = "";
	if( class'UIUtilities_Strategy'.static.DisplayLocation(Unit) )
    {
		UnitLoc = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
    }

	///////////////////////////////////////////////////////////////
	//	BOND ICON - NEEDS BEFORE AS_UPDATE TO HAVE BOND LEVEL OUT
	///////////////////////////////////////////////////////////////

	AddBondIconAndBar();
	UpdateBondIconAndBar(Unit, BondLevel);

	//as bond and promote icon share the same space, we want to hide the bond icon if the unit can promote
	if (Unit.ShowPromoteIcon())
	{
		BondIcon.Hide();
		BondProgressBar.Hide();
		bShouldHideBonds = true;
		bShouldShowBondProgressBar = false;
	}

	///////////////////////////////////////////////
	//	UPDATE ALL ORIG DATA Inc Issue #106, #408
	//	THIS IS SENDING THE INFO TO FLASH OBJECT
	///////////////////////////////////////////////

	flagIcon = Unit.GetCountryTemplate().FlagImage;

	AS_UpdateDataSoldier(
		Caps(Unit.GetName(eNameType_Full)),
		Caps(Unit.GetName(eNameType_Nick)),
		Caps(rankshort),
		rankIcon,
		Caps(classname),
		classIcon,
		status,
		statusTimeValue $"\n" $ Class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Class'UIUtilities_Text'.static.GetSizedText( statusTimeLabel, 12)),
		UnitLoc,
		flagIcon,
		false, // is disabled - LEFTOVER COMMENT from base game file, this mod handles disabled - RustyDios
		Unit.ShowPromoteIcon(),
		false, // psi soldiers cant rank up via missions - LEFTOVER COMMENT from base game file - RustyDios
		mentalStatus,
		BondLevel
	);

	///////////////////////////////////////////////
	//	FACTION ICON	 Inc Issue #1134, #295
	///////////////////////////////////////////////

	FactionState = Unit.GetResistanceFaction();
	StackedClassIcon = Unit.GetStackedClassIcon();

	if (StackedClassIcon.Images.Length > 0)
	{
		AS_SetFactionIcon(StackedClassIcon);
	}
	else if (FactionState != none)
	{
		AS_SetFactionIcon(FactionState.GetFactionIcon());
	}
	else
	{
		// Preserve backwards compatibility in case AS_SetFactionIcon() is overridden via an MCO, like us?.
		AS_SetFactionIcon(EmptyIconInfo);
	}

	///////////////////////////////////////////////
    //	UPDATE OUR NEW STAT ICONS & INFO TEXTS
	///////////////////////////////////////////////

	UpdateAdditionalItems(self);

	///////////////////////////////////////////////
	//	TOOLTIP TEXT FOR PERKS AND FINISH UPDATE
	///////////////////////////////////////////////

	//YES THIS NEEDS TO RUN TWICE FOR SOME REASON OR ELSE IT GETS CHOKED OUT FOR ITEMS PAST THE FIRST PAGE ??
	//I DON'T UNDERSTAND WHY THIS IS NOR DO I CARE TO UNDERSTAND WHY THIS IS, ONLY THAT THIS WORKS WHEN RUN TWICE AND NOT OTHERWISE
	//<> TODO : FURTHER INVESTIGATION ?!
	RefreshTooltipText();
	RefreshTooltipText();
}

//////////////////////////////////////////////////////////
//  UPDATING NEW STUFF HERE
//////////////////////////////////////////////////////////

function UpdateBondIconAndBar(XComGameState_Unit Unit, out int BondLevel)
{
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	local float CohesionPercent, CohesionMax;
	local array<int> CohesionThresholds;

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		BondLevel = BondData.BondLevel;

		if( !BondIcon.bIsInited ) { InitBondIconAndBar(BondmateRef, BondData); }

		if (BondLevel < 3)
		{
			//this should work out cohesion to be a value between 0.01 and 1.00
			CohesionThresholds = class'X2StrategyGameRulesetDataStructures'.default.CohesionThresholds;
			CohesionMax = float(CohesionThresholds[Clamp(BondLevel + 1, 0, CohesionThresholds.Length - 1)]);
			CohesionPercent = float(BondData.Cohesion) / CohesionMax;
			BondProgressBar.SetPercent(CohesionPercent);
			BondProgressBar.Show();
			bShouldShowBondProgressBar = true;
		}
		else
		{
			BondProgressBar.Hide();	//HIDE AS AT MAX BOND
		}

		BondIcon.Show();
	}
	else if( Unit.ShowBondAvailableIcon(BondmateRef, BondData) )
	{
		BondLevel = BondData.BondLevel;

		if( !BondIcon.bIsInited ) { InitBondIconAndBar(BondmateRef, BondData); }

		BondIcon.Show();
		BondIcon.SetBondLevel(0); 	// zero is the cohesion icon
		BondIcon.AnimateCohesion(default.bShouldAnimateBond);
		BondProgressBar.Hide();		// HIDE AS AT MIN BOND
	}
	else
	{
		//BondmateRef will be NoneRef, BondData will be default values
		if( !BondIcon.bIsInited ) { InitBondIconAndBar(BondmateRef, BondData); }

		// NO BOND DETAILS HIDE ALL
		BondIcon.Hide();
		BondProgressBar.Hide();
		bShouldHideBonds = true;
		BondLevel = -1;
	}
}

///////////////////////////////////////////////
//	UPDATE FOR FOCUS/DISABLED COLOURS
///////////////////////////////////////////////

function UpdateAdditionalItems(UIPersonnel_SoldierListItem ListItem)
{
	ShowDetailed(false);
	UpdateDisabled();
	UpdateItemsForFocus(false);
	FocusBondmateEntry(false);
}

///////////////////////////////////////////////
//	RANK COLUMN ADDITIONS
///////////////////////////////////////////////

function AddIconSlot(out UIIcon Icon_Slot, string Slot_Number, string BGColour, string ImagePath)
{
	Icon_Slot = Spawn(class'UIIcon', self);
	Icon_Slot.bAnimateOnInit = false;
	Icon_Slot.bIsNavigable = false;
	Icon_Slot.bDisableSelectionBrackets = true;

	Icon_Slot.InitIcon(name("Icon_Slot" $ Slot_Number $ "_ListItem_RD"), , false, true);

	Icon_Slot.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
	Icon_Slot.SetBGColor( BGColour);

	Icon_Slot.SetScale(IconScale * 0.6);
	Icon_Slot.SetPosition(IconXPos - (IconToTextOffsetX * 0.1), IconYPos);

	Icon_Slot.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $ ImagePath));
	Icon_Slot.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $ ImagePath $"_bg"));
}

function AddIconSlotFlag(out UIIcon Icon_Flag, string Icon_Slot, string ImagePath, string BGColour)
{
	Icon_Flag = Spawn(class'UIIcon', self);
	Icon_Flag.bAnimateOnInit = false;
	Icon_Flag.bIsNavigable = false;
	Icon_Flag.bDisableSelectionBrackets = true;
	
	Icon_Flag.InitIcon(name("Icon_Flag" $ Icon_Slot $"_ListItem_RD"), , false, true, 18);
	
	Icon_Flag.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
	Icon_Flag.SetBGColor(BGColour);
	
	Icon_Flag.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $ ImagePath)); 
	Icon_Flag.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $ ImagePath $"_bg"));
}

//YES TWO ICONS .. BECAUSE CHANGING THE COLOUR WAS BEING STUPID, SO I MAKE DO WITH HIDING ONE IF NEEDED
//NOT OPTIMAL BUT IT GETS THE JOB DONE AND I WAS GETTING FRUSTRATED FIGURING IT OUT !!
function AddIconSlotSmall(out UIIcon Icon_FlagNrm, out UIIcon Icon_FlagDis, string Icon_Slot, string ImagePath, int YPos)
{
	AddIconSlotFlag(Icon_FlagNrm, Icon_Slot $ "Nrm", ImagePath, class'UIUtilities_Colors'.const.PERK_HTML_COLOR);
	AddIconSlotFlag(Icon_FlagDis, Icon_Slot $ "Dis", ImagePath, class'UIUtilities_Colors'.const.FADED_HTML_COLOR);

	Icon_FlagDis.SetPosition(IconXPos - (518 * 0.1), YPos );	Icon_FlagDis.Hide();
	Icon_FlagNrm.SetPosition(IconXPos - (518 * 0.1), YPos );	Icon_FlagNrm.Show();
}

// ADD icons to rank field ... combat intelligence , LW Officer Icon, SPARK Icon ... (combat intelligence, LW Officer Icon, SPARK Icon)
function AddRankColumnIcons(XComGameState_Unit Unit, UIPersonnel_SoldierListItem ListItem)
{
	local bool bUnitIsOfficer, bUnitIsSPARK;

	bUnitIsOfficer = false;
	bUnitIsSPARK = false;

   	IconXPos = 118;

	/* <>SLOT 1 */ 
	if (Icon_Slot1 == none) { AddIconSlot(Icon_Slot1, "1", APColours[int(Unit.ComInt)], APImagePath[int(Unit.ComInt)] 	); } //ComInt
	if (Icon_SlotR == none) { AddIconSlot(Icon_SlotR, "R", NAColours[intAptitude], 		NAImagePath[intAptitude] 		); } //RPGO AP

	if (Text_Slot1 == none)
	{
		Text_Slot1 = Spawn(class'UIText', self);
		Text_Slot1.bAnimateOnInit = false;
		Text_Slot1.InitText('Text_Slot1_ListItem_RD').SetPosition(IconXPos + IconToTextOffsetX, IconYPos + IconToTextOffsetY);
	}

	// ASK THE EVENT LISTENER FUNCTION IF WE IS AN OFFICER
	bUnitIsOfficer = class'X2EventListener_StatusOfDSLRusty'.static.IsUnitOfficer(Unit);

	`LOG("Unit[" @Unit.GetName(eNameType_Full) @"] Is An Officer [" @bUnitIsOfficer @"] RustyPositionTest [" @default.bRustyExtraIconPositionTest @"]", default.bRustyEnableDSLLogging, 'DSLRusty_SLI');

	if (bUnitIsOfficer || default.bRustyExtraIconPositionTest || ShouldShowIcon_FlagTopNrm(Unit))
	{
		if (Icon_FlagTopNrm == none) { AddIconSlotSmall(Icon_FlagTopNrm, Icon_FlagTopDis, "Top", StatIconPath[8], 5 ); } //Officer Icon
	}
	else
	{
		if (Icon_FlagTopNrm != none) { Icon_FlagTopDis.Hide();	Icon_FlagTopNrm.Hide();	}
	}

	// ASK THE EVENT LISTENER FUNCTION IF WE IS A SPARK
	bUnitIsSPARK = class'X2EventListener_StatusOfDSLRusty'.static.IsUnitSPARK(Unit);

	`LOG("Unit[" @Unit.GetName(eNameType_Full) @"] Is A SPARK [" @bUnitIsSPARK @"] RustyPositionTest [" @default.bRustyExtraIconPositionTest @"]", default.bRustyEnableDSLLogging, 'DSLRusty_SLI');

	if (bUnitIsSPARK || default.bRustyExtraIconPositionTest || ShouldShowIcon_FlagBotNrm(Unit))
	{
		if (Icon_FlagBotNrm == none) { AddIconSlotSmall(Icon_FlagBotNrm, Icon_FlagBotDis, "Bot", StatIconPath[18], 25 ); } //SPARK Icon
	}
	else
	{
		if (Icon_FlagBotNrm != none) { Icon_FlagBotDis.Hide();	Icon_FlagBotNrm.Hide();	}
	}
}

///////////////////////////////////////////////
//	NAME COLUMN ADDITIONS
///////////////////////////////////////////////

function AddBondIconAndBar()
{
	if (BondProgressBar == none)
	{
		BondProgressBar = Spawn(class'UIProgressBar_DSL_Bond', self); //Spawn(class'UIProgressBar', self);
	}

	if( BondIcon == none )
	{
		BondIcon = Spawn(class'UIBondIcon', self);
		if( `ISCONTROLLERACTIVE )
        {
			BondIcon.bIsNavigable = false; 
        }
	}
}

function InitBondIconAndBar(StateObjectReference BondmateRef, SoldierBond BondData)
{
	if( BondIcon == none || BondProgressBar == none)
	{
		AddBondIconAndBar();
	}
	
	BondIcon.InitBondIcon('UnitBondIcon', BondData.BondLevel, , BondData.Bondmate);
	BondIcon.SetPosition(BondIconX, BondIconY);
	BondIcon.SetBondmateTooltip(BondmateRef);
	BondProgressBar.InitProgressBar('UnitBondProgressBar', BondIconX + 28, BondIconY -2, BondBarWidth, BondBarHeight, 1.0, eUIState_Normal, true);
}

function AddStatSlot(out UIImage Icon_Slot, out UIText Text_Slot, string Slot_Number, string ImagePath)
{
	Icon_Slot = Spawn(class'UIImage', self);
	Icon_Slot.bAnimateOnInit = false;
	Icon_Slot.bIsNavigable = false;
	Icon_Slot.InitImage(name("Icon_Slot" $ Slot_Number $ "_ListItem_RD"), ImagePath );
	Icon_Slot.SetScale(IconScale);
	Icon_Slot.SetPosition(IconXPos, IconYPos); //"UILibrary_RustyDSL.Image_Health"

	Text_Slot = Spawn(class'UIText', self);
	Text_Slot.bAnimateOnInit = false;
	Text_Slot.InitText(name("Text_Slot" $ Slot_Number $ "_ListItem_RD"));
	Text_Slot.SetPosition(IconXPos + IconToTextOffsetX, IconYPos + IconToTextOffsetY);
}

function AddPerkPanel(out UIPanel PerkPanel, name initName, int LengthSize)
{
	PerkPanel = Spawn(class'UIPanel', self);
	PerkPanel.bAnimateOnInit = false;
	PerkPanel.bIsNavigable = false;
	PerkPanel.InitPanel(initName);
	PerkPanel.SetPosition(IconXPos, IconYPos+1);
	PerkPanel.SetSize(IconToTextOffsetX * LengthSize, IconToTextOffsetX);
	//PerkPanel.AnimateScroll(IconToTextOffsetX, IconToTextOffsetX);
}

function InitPerkIcon(UIIcon PerkIcon, name InitName, string ImagePath, int initXpos, int initYpos)
{
	PerkIcon.bDisableSelectionBrackets = true;
	PerkIcon.bIsNavigable = false;
	PerkIcon.InitIcon(InitName, ImagePath, false, false);
	PerkIcon.SetScale(IconScale);
	PerkIcon.SetPosition(initXpos, initYpos);
	PerkIcon.SetForegroundColor("9ACBCB");
}

//ADD icons to name field ... health, mobility, dodge, defense, hack, psi, trait perks ... (armor, shields, kills, missions, xp, awc Perks)
function AddNameColumnIcons(XComGameState_Unit Unit, UIPersonnel_SoldierListItem ListItem)
{
	local X2EventListenerTemplateManager 	EventTemplateManager;
	local X2TraitTemplate 					TraitTemplate;

	local X2AbilityTemplateManager			AbilityTemplateManager;
	local X2AbilityTemplate 				AbilityTemplate;

	local X2SoldierClassTemplate SoldierClass;

	local int i, idx, AWCRank, AWCRow;

	/* <>SLOT 2 */ IconXPos = 170;						if(Icon_Slot2 == none || Text_Slot2 == none) { AddStatSlot(Icon_Slot2, Text_Slot2, "2", StatIconPath[0]); } // Health/Aim	/ Armour
	/* <>SLOT 3 */ IconXPos += IconXDeltaSmallValue +6;	if(Icon_Slot3 == none || Text_Slot3 == none) { AddStatSlot(Icon_Slot3, Text_Slot3, "3", StatIconPath[1]); } // Mobility		/ Shields
	/* <>SLOT 4 */ IconXPos += IconXDeltaSmallValue;	if(Icon_Slot4 == none || Text_Slot4 == none) { AddStatSlot(Icon_Slot4, Text_Slot4, "4", StatIconPath[2]); } // Dodge		/ Missions
	/* <>SLOT 5 */ IconXPos += IconXDeltaSmallValue;	if(Icon_Slot5 == none || Text_Slot5 == none) { AddStatSlot(Icon_Slot5, Text_Slot5, "5", StatIconPath[6]); } // Defense		/ XP Progress
	/* <>SLOT 6 */ IconXPos += IconXDeltaSmallValue;	if(Icon_Slot6 == none || Text_Slot6 == none) { AddStatSlot(Icon_Slot6, Text_Slot6, "6", StatIconPath[3]); } // Hacking

	/* <>SLOT 7 */ IconXPos += IconXDeltaSmallValue +8;
	if (ShouldShowPsi(Unit)) { 	if(Icon_Slot7 == none || Text_Slot7 == none) { AddStatSlot(Icon_Slot7, Text_Slot7, "7", StatIconPath[4]); } } // Psi Offense

    //RESET/HARDCODE X POS FOR WEAPONS ICONS
	IconXPos = 440;

	if (ShouldDisplayWeaponIcons(Unit, bRPGODetected))
	{
		if(Icon_SlotP == none || Icon_SlotS == none)
		{
			Icon_SlotP = Spawn(class'UIImage', self);
			Icon_SlotP.bAnimateOnInit = false;
			Icon_SlotP.InitImage('Icon_SlotP_ListItem_RD', LoadoutImageP );
			Icon_SlotP.SetScale(IconScale);
			Icon_SlotP.SetPosition(IconXPos, -8);

			Icon_SlotS = Spawn(class'UIImage', self);
			Icon_SlotS.bAnimateOnInit = false;
			Icon_SlotS.InitImage('Icon_SlotS_ListItem_RD', LoadoutImageS );
			Icon_SlotS.SetScale(IconScale);
			Icon_SlotS.SetPosition(IconXPos + 36, -8);
		}
	}

    //RESET/HARDCODE X POS FOR TRAIT PERKS PANEL
	IconXPos = 454;

    // Bad Traits Panel spawn
	if (BadTraitPanel == none )
	{
		AddPerkPanel (BadTraitPanel, 'BadTraitIcons_List_RD', default.TraitTemplatesDisplayLength);

		//bad traits panel fill
		TraitTemplates.length = 0;
		BadTraitIcons.length = 0;

		if (default.TraitTemplatesDisplayLength > 0)
		{
			EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

			for (i = 0; i < Unit.AcquiredTraits.Length; i++)
			{
				TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(Unit.AcquiredTraits[i]));
				if (TraitTemplate != none)
				{
					//Add if not already there
					if (TraitTemplates.Find(TraitTemplate) == INDEX_NONE)
					{
						TraitTemplates.AddItem(TraitTemplate);
					}
				}
			}

			//Now we have gathered the Trait perks
			foreach TraitTemplates(TraitTemplate)
			{
				BadTraitIcons.AddItem(Spawn(class'UIIcon', BadTraitPanel)); 
				idx = BadTraitIcons.length -1;
				InitPerkIcon(BadTraitIcons[idx], name("TraitIcon_ListItem_RD_" $ idx), TraitTemplate.IconImage, TraitIconX, TraitIconY);
				TraitIconX += IconToTextOffsetX;

				//Hide Icons past the limit
				if (TraitIconX > (IconToTextOffsetX * default.TraitTemplatesDisplayLength) ) { BadTraitIcons[idx].Hide(); }
			}
		}
	}

    //RESET/HARDCODE X POS FOR AWC PERKS PANEL
	IconXPos = 400;

	//2ND PAGE detailed AWC abilities spawn
	if (BonusAbilityPanel == none)
	{
		AddPerkPanel (BonusAbilityPanel, 'BonusAbilityIcons_List_RD', default.AWCTemplatesDisplayLength);

		//awc perks panel fill
		AWCTemplates.length = 0;
		BonusAbilityIcons.length = 0;

		if (default.AWCTemplatesDisplayLength > 0)
		{
			AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
			SoldierClass = Unit.GetSoldierClassTemplate();
			AWCRank = Unit.GetRank(); //this is a check rank

			//Grab any ADDED/ACTUAL AWC Perks the unit might have unlocked
			for (i = 0 ; i < Unit.AWCAbilities.Length ; i++)
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(Unit.AWCAbilities[i].AbilityType.AbilityName);
				if (AbilityTemplate != none && Unit.AWCAbilities[i].bUnlocked && AWCRank >= Unit.AWCAbilities[i].iRank)
				{
					//Add if not already there
					if (AWCTemplates.Find(AbilityTemplate) == INDEX_NONE)
					{
						AWCTemplates.AddItem(AbilityTemplate);
					}
				}
			}

			//detailed AWC fill from last row of class tree, note does not count for hero units or units that are not allowed AWC
			if (class'X2SoldierClass_DefaultChampionClasses'.default.ChampionClasses.Find(Unit.GetSoldierClassTemplateName()) != INDEX_NONE)
			{
				//Do nothing, it was a hero unit
			}
			else if (SoldierClass.bAllowAWCAbilities)
			{
				// we ASSUME that the last row is the XCOM/AWC random deck row
				// we also ASSUME that the localisation is set up correctly to have the correct number of titles!
				// <> TODO : Make this better!
				AWCRow = Max(0, SoldierClass.AbilityTreeTitles.Length - 1);
				AWCRank = SoldierClass.GetMaxConfiguredRank(); //this is all ranks the class has, 7/8

				//Check each rank for any perks in the last row that the soldier has purchased, don't check SQD (start at index 1)
				for (i = 1; i <= AWCRank; i++)
				{
					if (Unit.AbilityTree[i].Abilities.Length > AWCRow )
					{
						AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(Unit.AbilityTree[i].Abilities[AWCRow].AbilityName);
						if (AbilityTemplate != none && Unit.HasSoldierAbility(Unit.AbilityTree[i].Abilities[AWCRow].AbilityName))
						{
							//Add if not existing
							if (AWCTemplates.Find(AbilityTemplate) == INDEX_NONE)
							{
								AWCTemplates.AddItem(AbilityTemplate);
							}
						}
					}
				}
			}

			//Now we have gathered the AWC perks we want to display
			foreach AWCTemplates(AbilityTemplate)
			{
				BonusAbilityIcons.AddItem(Spawn(class'UIIcon', BonusAbilityPanel));
				idx = BonusAbilityIcons.Length - 1;
				InitPerkIcon(BonusAbilityIcons[idx], name("AbilityIcon_ListItem_RD_" $ idx), AbilityTemplate.IconImage, AbilityIconX, AbilityIconY);
				AbilityIconX += IconToTextOffsetX;

				//Hide Icons past the limit
				if (AbilityIconX > (IconToTextOffsetX * default.AWCTemplatesDisplayLength) ) { BonusAbilityIcons[idx].Hide(); }
			}
		}
	}

    //stop adding stuffs
}

///////////////////////////////////////////////
//	CLASS COLUMN ADDITIONS
///////////////////////////////////////////////

//ADD icons to Class field ... Aim, will, ... (Kills, PCS)
function AddSpecColumnIcons(XComGameState_Unit Unit, UIPersonnel_SoldierListItem ListItem)
{
	/* <>SLOT 8 */ IconXPos = 598;				if(Icon_Slot8 == none || Text_Slot8 == none) { AddStatSlot(Icon_Slot8, Text_Slot8, "8", StatIconPath[5]); } // Aim/Health	/ Kills
	/* <>SLOT 9 */ IconXPos += IconXDelta +6;	if(Icon_Slot9 == none || Text_Slot9 == none) { AddStatSlot(Icon_Slot9, Text_Slot9, "9", StatIconPath[7]); } // Will			/ PCS

	Text_Slot9_X_WILL = Text_Slot9.X; Text_Slot9_X_PCS = Text_Slot9.X -18;
	Icon_Slot9_X_WILL = Icon_Slot9.X; Icon_Slot9_X_PCS = Icon_Slot9.X -14;
}

///////////////////////////////////////////////
//	STATUS COLUMN ADDITIONS
///////////////////////////////////////////////

//	NONE - ITS CONFUSING ENOUGH AND HAS DIRECT CHL OVERRIDES

////////////////////////////////////////////////////////////////
//  UPDATE AND SWITCH DISPLAYED LISTS
///////////////////////////////////////////////////////////////

function HideAllStats()
{
    Text_Slot1.Hide();		Icon_Slot1.Hide();	Icon_SlotR.Hide(); 

	Text_Slot2.Hide();  	Icon_Slot2.Hide();
	Text_Slot3.Hide();		Icon_Slot3.Hide();
	Text_Slot4.Hide();		Icon_Slot4.Hide();
    Text_Slot5.Hide();  	Icon_Slot5.Hide();
	Text_Slot6.Hide();		Icon_Slot6.Hide();
	Text_Slot7.Hide();		Icon_Slot7.Hide();

	Text_Slot8.Hide();		Icon_Slot8.Hide();
	Text_Slot9.Hide();		Icon_Slot9.Hide();

	Icon_SlotP.Hide();		Icon_SlotS.Hide();

	BondIcon.Hide();		BondProgressBar.Hide();
    BadTraitPanel.Hide();	BonusAbilityPanel.Hide();
}

function ShowDetailed(bool IsDetailed)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	bShouldShowDetailed = IsDetailed;

    //HIDE EVERYTHING AND WORK OUT FROM HERE AFTERWARDS, MAKES IT LOOK LIKE THEY ARE REFRESHING/SWAPPING
	HideAllStats();

	//Show RPGO Style weapon icons if enabled
	if (ShouldDisplayWeaponIcons(Unit, bRPGODetected) ) { Icon_SlotP.Show(); Icon_SlotS.Show(); }

    //Show what is required
	if (IsDetailed)
	{
		//Set Rank Column ... Aptitude or ComInt
		bRPGODetected ? Icon_SlotR.Show() : Icon_Slot1.Show();
		Text_Slot1.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(bRPGODetected ? statsRPGO : statsAP, eUIState_Normal));
		Text_Slot1.Show();

		//Set Name Column
		Icon_Slot2.LoadImage(StatIconPath[12]);	Text_Slot2.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsArmor,	eUIState_Normal));
		Icon_Slot3.LoadImage(StatIconPath[13]);	Text_Slot3.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsShields, 	eUIState_Normal));
		Icon_Slot4.LoadImage(StatIconPath[9]);	Text_Slot4.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsMissions, eUIState_Normal));
		Icon_Slot5.LoadImage(StatIconPath[11]);	Text_Slot5.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsXP, 		eUIState_Normal));

		//Set Class Column
		Icon_Slot8.LoadImage(StatIconPath[10]);	Text_Slot8.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsKills,	eUIState_Normal));

		//Show Above Values
		Text_Slot2.Show();	Text_Slot3.Show();	Text_Slot4.Show();	Text_Slot5.Show();	Text_Slot8.Show();
		Icon_Slot2.Show();	Icon_Slot3.Show();	Icon_Slot4.Show();	Icon_Slot5.Show();	Icon_Slot8.Show();

		//Special Handling - PCS/Will Slot
		if (PCSImage != "")
		{
			Text_Slot9.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(PCSStats, eUIState_Normal));
			Text_Slot9.SetPosition(Text_Slot9_X_PCS, Text_Slot9.Y);
			Text_Slot9.Show();
			
			Icon_Slot9.LoadImage(PCSImage);
			Icon_Slot9.SetScale(IconScale * 0.5);
			Icon_Slot9.SetPosition(Icon_Slot9_X_PCS, Icon_Slot9.Y);
			Icon_Slot9.Show();
		}		

		//Perks Panel
        BonusAbilityPanel.Show();
	}
	else
	{
		//Set Rank Column
		Text_Slot1.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsAP, eUIState_Normal));	

		//Set Name Column
		Icon_Slot3.LoadImage(StatIconPath[1]);	Text_Slot3.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsMobility, eUIState_Normal));
		Icon_Slot4.LoadImage(StatIconPath[2]);	Text_Slot4.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsDodge, 	eUIState_Normal)); 
		Icon_Slot5.LoadImage(StatIconPath[6]);	Text_Slot5.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsDefense, 	eUIState_Normal));
		Icon_Slot6.LoadImage(StatIconPath[3]);	Text_Slot6.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsHack, 	eUIState_Normal));

		//Set Name Column and Class Column ... Health/Aim Switcheroo
		if (default.bSHOW_MAXHEALTH)
		{
			Icon_Slot2.LoadImage(StatIconPath[5]);	Text_Slot2.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsAim, eUIState_Normal)); 
			Icon_Slot8.LoadImage(StatIconPath[0]);	Text_Slot8.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsHealth, eUIState_Normal));
		}
		else 
		{
			Icon_Slot2.LoadImage(StatIconPath[0]);	Text_Slot2.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsHealth, eUIState_Normal)); 
			Icon_Slot8.LoadImage(StatIconPath[5]);	Text_Slot8.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsAim, eUIState_Normal));
		}

		//Show Above Values
		Text_Slot1.Show();	Text_Slot2.Show();	Text_Slot3.Show();	Text_Slot4.Show();	Text_Slot5.Show();	Text_Slot6.Show();  Text_Slot8.Show();	
		Icon_Slot1.Show();	Icon_Slot2.Show();	Icon_Slot3.Show();	Icon_Slot4.Show();	Icon_Slot5.Show();	Icon_Slot6.Show();	Icon_Slot8.Show();  

		//Special Handling - Psi - YES WE HAVE NO REASON NOT TO NOW, BUT BACKWARDS COMPATIBILTY COMPELLS US TO CHECK!
		if (ShouldShowPsi(Unit))
		{
			Icon_Slot7.LoadImage(StatIconPath[4]);	Text_Slot7.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsPsi, 	eUIState_Normal));
			Text_Slot7.Show();	Icon_Slot7.Show();
		}

		//Special Handling - PCS/Will - YES WE HAVE TO RESCALE AND MOVE BACK IF WE HAD A PCS IMAGE
		Icon_Slot9.LoadImage(StatIconPath[7]);	Text_Slot9.SetHtmlText(class'UIUtilities_Text'.static.GetColoredText(statsWill, eUIState_Normal)); 
		if (PCSImage != "")
		{
			Text_Slot9.SetPosition(Text_Slot9_X_WILL, Text_Slot9.Y);
			Icon_Slot9.SetPosition(Icon_Slot9_X_WILL, Icon_Slot9.Y);
			Icon_Slot9.SetScale(IconScale);
		}
		Text_Slot9.Show();	Icon_Slot9.Show();

		//Perks Panel
		BadTraitPanel.Show();
	}

	//SET ABOVE IF THE UNIT HAS A BOND/PROGRESS
	if (!bShouldHideBonds) { BondIcon.Show();	if (bShouldShowBondProgressBar) { BondProgressBar.Show();	} }

	//THIS ENSURES WE GET THE RIGHT COLOURED TEXT ETC WHEN WE SWITCH
	UpdateDisabled();
	UpdateItemsForFocus(bIsFocussed);

	RefreshTooltipText(); //we have switched awc/traits and bond shown so lets update the tooltip too
}

//////////////////////////////////////////////////
//  UI MANIPULATION
/////////////////////////////////////////////////

simulated function UIButton SetDisabled(bool disabled, optional string TooltipText)
{
	DisabledToolTipText = TooltipText;

	super.SetDisabled(disabled, TooltipText);

	UpdateDisabled();
	UpdateItemsForFocus(bIsFocussed);

	RefreshTooltipText(); //super set tooltip text to OLD text, so we need to reset it to us :)

	return self;
}

//adjust icons for disabled view (almost blacked out)
simulated function UpdateDisabled()
{
	local float UpdateAlpha;
	local UIIcon PerkIcon;

	if(Icon_FlagTopNrm != none && Icon_FlagTopDis != none)
	{
		if(IsDisabled) 	{ Icon_FlagTopNrm.Hide(); Icon_FlagTopDis.Show(); }
		else  			{ Icon_FlagTopNrm.Show(); Icon_FlagTopDis.Hide(); }
	}

	if(Icon_FlagBotNrm != none && Icon_FlagBotDis != none)
	{
		if(IsDisabled) 	{ Icon_FlagBotNrm.Hide(); Icon_FlagBotDis.Show(); }
		else			{ Icon_FlagBotNrm.Show(); Icon_FlagBotDis.Hide(); }
	}

	UpdateAlpha = (IsDisabled ? DisabledAlpha : 1.0f);

	if(Icon_Slot2 != none) { Icon_Slot2.SetAlpha(UpdateAlpha); 	}
	if(Icon_Slot3 != none) { Icon_Slot3.SetAlpha(UpdateAlpha);	}
	if(Icon_Slot4 != none) { Icon_Slot4.SetAlpha(UpdateAlpha);	}
	if(Icon_Slot5 != none) { Icon_Slot5.SetAlpha(UpdateAlpha);	}
	if(Icon_Slot6 != none) { Icon_Slot6.SetAlpha(UpdateAlpha);	}
	if(Icon_Slot7 != none) { Icon_Slot7.SetAlpha(UpdateAlpha);	}

	if(Icon_Slot8 != none) { Icon_Slot8.SetAlpha(UpdateAlpha);	}
	if(Icon_Slot9 != none) { Icon_Slot9.SetAlpha(UpdateAlpha);	}

	if(Icon_SlotP != none) { Icon_SlotP.SetAlpha(UpdateAlpha);	}
	if(Icon_SlotS != none) { Icon_SlotS.SetAlpha(UpdateAlpha);	}

	/* set traits */	foreach BadTraitIcons(PerkIcon) 		{ PerkIcon.SetAlpha(UpdateAlpha); }
	/* set AWC perks */	foreach BonusAbilityIcons(PerkIcon) 	{ PerkIcon.SetAlpha(UpdateAlpha); }
}

//adjust text for highlight
simulated function UpdateItemsForFocus(bool Focussed)
{
	//local string AP, Health, Mobility, Dodge, Defense, Hack, Psi, Aim, Will, Armor, Shields, Kills, Missions, XP;
	local XComGameState_Unit Unit;
	local UIIcon PerkIcon;
	local bool bReverse;
	local int isUIState, PCSColour, PsiColour, WillState, HPColours;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	isUIState = (IsDisabled ? eUIState_Disabled : eUIState_Normal);
	PsiColour = (IsDisabled ? eUIState_Disabled : eUIState_Psyonic);
	PCSColour = (IsDisabled ? eUIState_Disabled : int(PCSState));
	WillState = (IsDisabled ? eUIState_Disabled : int(Unit.GetMentalStateUIState()));
	HPColours = (IsDisabled ? eUIState_Disabled : int(HPState));

	bIsFocussed = Focussed;
	bReverse = bIsFocussed && !IsDisabled;

	//set text displays to unit stats gathered above
    if (bShouldShowDetailed)
	{
		Text_Slot1.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(bRPGODetected ? statsRPGO : statsAP, ( bReverse ? -1 : isUIState )));	//natapt or comint .. black to cyan

		Text_Slot2.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsArmor,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot3.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsShields,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot4.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsMissions,	( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot5.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsXP,			( bReverse ? -1 : isUIState )));	//black to cyan

		Text_Slot8.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsKills,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot9.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(PCSStats,			( bReverse ? -1 : PCSColour )));	//black to good/bad

		/* set AWC perks */	foreach BonusAbilityIcons(PerkIcon)	{ PerkIcon.SetForegroundColor( bReverse ? "000000" : "9ACBCB");}	//black to cyan
	}
	else
	{
		Text_Slot1.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsAP,			( bReverse ? -1 : isUIState )));	//black to cyan

		if (default.bSHOW_MAXHEALTH)
		{
			Text_Slot2.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsAim,		( bReverse ? -1 : isUIState )));	//black to cyan
		}
		else 
		{
			Text_Slot2.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsHealth,	( bReverse ? -1 : isUIState )));	//black to cyan
		}
		Text_Slot3.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsMobility,	( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot4.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsDodge,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot5.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsDefense,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot6.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsHack,		( bReverse ? -1 : isUIState )));	//black to cyan
		Text_Slot7.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsPsi,			( bReverse ? -1 : PsiColour )));	//black to purple

		if (default.bSHOW_MAXHEALTH)
		{
			Text_Slot8.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsHealth,	( bReverse ? -1 : HPColours )));	//black to traffic
		}
		else
		{
			Text_Slot8.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsAim,		( bReverse ? -1 : isUIState )));	//black to cyan
		}

		Text_Slot9.SetHtmlText( class'UIUtilities_Text'.static.GetColoredText(statsWill,		( bReverse ? -1 : WillState )));	//black to traffic

		/* set traits */	foreach BadTraitIcons(PerkIcon)		{ PerkIcon.SetForegroundColor( bReverse ? "000000" : "9ACBCB");}	//black to cyan
	}

	//set bond progress bar
	if (bIsFocussed)
	{
		BondProgressBar.SetColor("27AAE1"); // Blue science
	}
	else
	{
		BondProgressBar.SetPercent(BondProgressBar.Percent); // Cyan or gold if full
	}
}

//makes bond icon have a flashy outline for partner
simulated function FocusBondmateEntry(bool IsFocus)
{
	local XComGameState_Unit Unit;
	local UIPersonnel_SoldierListItemDetailed OtherListItem;
	local array<UIPanel> AllOtherListItem;
	local UIPanel OtherItem;
	local StateObjectReference BondmateRef;
	local SoldierBond BondData;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		ParentPanel.GetChildrenOfType(class'UIPersonnel_SoldierListItemDetailed', AllOtherListItem);
		foreach AllOtherListitem(OtherItem)
		{
			OtherListItem = UIPersonnel_SoldierListItemDetailed(OtherItem);
			if (OtherListItem != none && OtherListItem.UnitRef.ObjectID == BondmateRef.ObjectID)
			{
				if (IsFocus)
				{
					OtherListItem.NeedsAttention(default.bShowAttentionBondmateHovered);
					OtherListItem.BondIcon.OnReceiveFocus();
				}
				else
				{
					OtherListItem.NeedsAttention(false);
					OtherListItem.BondIcon.OnLoseFocus();
				}
			}
		}

		//highlight my icon if my bondmate is in the squad and I am not
		if (`XCOMHQ.IsUnitInSquad(BondmateRef) && !`XCOMHQ.IsUnitInSquad(UnitRef))
		{
			NeedsAttention(default.bShowAttentionBondmateInSquad);
			BondIcon.OnReceiveFocus();
		}
		else
		{
			NeedsAttention(false);
			BondIcon.OnLoseFocus();
		}
	}
}

simulated function NeedsAttention(bool bAttention, optional bool bForceOnStage = false)
{
	super.NeedsAttention(bAttention, bForceOnStage);

	AttentionIcon.SetPosition(486, 12); // next to the bond icon, middle of bar
}

protected function CreateAttentionIcon()
{
	// We have a member that will either connect to what is on stage, or will spawn a clip in for us to use.  
	AttentionIcon = Spawn(class'UIPanel', self);
	AttentionIcon.bAnimateOnInit = false;
	AttentionIcon.InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon);
	AttentionIcon.DisableNavigation();
	AttentionIcon.SetSize(70, 70); //the animated rings count as part of the size. 
	AttentionIcon.SetPosition(486, 12);
	Navigator.RemoveControl(AttentionIcon);
}

////////////////////////////////////////
//  TEXT/TOOLTIPS FUNCTIONS
////////////////////////////////////////

static function string ColorText( string strValue, string HexColor )
{
	return "<font color='#"$HexColor$"'>"$strValue$"</font>";
}

//refresh and update tooltips on hover over abilities and traits
simulated function RefreshTooltipText()
{
	local XComGameState_Unit 				Unit, Bondmate;
	local StateObjectReference 				BondmateRef;
	local SoldierBond 						BondData;

	local X2TraitTemplate 					TraitTemplate;
	local X2AbilityTemplate 				AbilityTemplate;

	local string textTooltip, traitTooltip;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	//clear tooltip
	textTooltip = "";
	traitTooltip = "";

	//Set any disabled reason first, possible input from disabled reason, KDM
	textTooltip = DisabledTooltipText;

	//add bond details if any
	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));

		//add linebreak if we had disabled details
		if (textTooltip != "") { textTooltip $= "\n\n"; }

		textTooltip $= ColorText(Caps(Repl(BondmateTooltip, "%SOLDIERNAME", ColorText(Bondmate.GetName(eNameType_FullNick), "9ACBCB") ) ), "3CEDD4" );
	}
	else if( Unit.ShowBondAvailableIcon(BondmateRef, BondData) )
	{
		//add linebreak if we had disabled details
		if (textTooltip != "") { textTooltip $= "\n\n"; }

		textTooltip $= ColorText(class'XComHQPresentationLayer'.default.m_strBannerBondAvailable, "5CD16C");
	}

	//set text displays to page
    if (bShouldShowDetailed)
	{
		//add linebreak if we had previous details
		if (textTooltip != "") { textTooltip $= "\n\n"; }

		//add pcs name if has one
		if (PCSName != "") { textTooltip $= PCSName $"\n\n"; }

		//add perk names if any (we gathered these earlier)
		foreach AWCTemplates(AbilityTemplate)
		{
			if (AbilityTemplate != none)
			{
				textTooltip $= AbilityTemplate.LocFriendlyName $"\n";
			}
		}
	}
	else if (Unit.AcquiredTraits.length > 0)
	{
		//add linebreak if we had previous details
		if (textTooltip != "") { textTooltip $= "\n\n"; }

		//add trait tips if any, construct traits multi-string (we gathered these earlier)
		foreach TraitTemplates(TraitTemplate)
		{
			//start new line for new trait
			if (traitTooltip != "") { traitTooltip $= "\n"; }

			if (TraitTemplate != none)
			{
				traitTooltip $= ColorText(TraitTemplate.TraitFriendlyName, TraitTemplate.bPositiveTrait ? "53B45E" : "BF1E2E");
				traitTooltip $= "\n -" @ TraitTemplate.TraitDescription;
			}
		}

		//merge previous and trait tooltips
		textTooltip $= traitTooltip;
	}

	//if it's not blank set it
	if (textTooltip != "")
	{
		SetTooltipText_Improved(textTooltip,"", 650, /* Height-Auto */, /* Loc-false */, 4); //ANCHOR_MIDDLE_LEFT
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CachedTooltipID, true);

		//expand the bondmate icon tooltip text too as selecting/hovering over the area is hard!
		//set Bond Icon to use the same tooltip!
		BondIcon.SetTooltip(Movie.Pres.m_kTooltipMgr.GetTooltipByID(CachedTooltipID));
	}
	else
	{
		SetTooltipText_Improved("");
	}
}

//overwrite of this function traced back through UIPersonnel_SoldierListItem > UIPersonnel_ListItem > UIButton > UIPanel
//doing this so we can ALSO input width/height, behaviour, color, displaytime and delay
simulated function SetTooltipText_Improved(string strText, 
                                    optional string Title			= "",
                                    optional float MaxW				= class'UITextTooltip'.default.maxW,				/* 300 */
                                    optional float MaxH				= class'UITextTooltip'.default.maxH, 				/* 300 */
                                    optional bool bRelativeLocation	= class'UITextTooltip'.default.bRelativeLocation,	/* false */
                                    optional int TooltipAnchor      = class'UITextTooltip'.default.Anchor, 				/* 1 top left */
                                    optional float OffsetX			= 0.0,
                                    optional float OffsetY			= 0.0,
                                    optional bool bFollowMouse      = class'UITextTooltip'.default.bFollowMouse,		/* true */
                                    optional float Delay            = class'UITextTooltip'.default.tDelay,				/* 0.75 */
                                    optional int Hover 				= class'UITextTooltip'.default.eTTBehavior,			/* 0 eUITT_Behavior_Hover */
                                    optional int Colour				= class'UITextTooltip'.default.eTTColor,			/* 0 eUITT_Style_Cyan */
                                    optional float DisplayTime		= class'UITextTooltip'.default.tDisplayTime,		/* -1.0  */
                                    optional float AnimateIn		= class'UITextTooltip'.default.tAnimateIn,			/* 0.2 */
                                    optional float AnimateOut		= class'UITextTooltip'.default.tAnimateOut			/* 0.2 */
                                )
{
    //REMOVE ANY PREVIOUS TOOLTIPS FROM THE CHILD
    if (bHasTooltip) { RemoveTooltip(); }

    //SET NEW TEXT
    if (strText != "")
    {
		//THIS CREATES AND ASSIGNS THE NEW TOOLTIP TO THE CHILD
		CachedTooltipId = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(strText, OffsetX, OffsetY, string(MCPath), 
			Title, bRelativeLocation, TooltipAnchor, bFollowMouse, MaxW, MaxH, Hover, Colour, DisplayTime, Delay, AnimateIn, AnimateOut);

		SetTooltip(Movie.Pres.m_kTooltipMgr.GetTooltipByID(CachedTooltipID));
		bHasTooltip = true;
	}
}

/////////////////////////////////////////////////////////////////////////
//  'SCREEN' MANIPULATION
///////////////////////////////////////////////////////////////////////

simulated function OnMouseEvent(int Cmd, array<string> Args)
{
	// HAX: get parent list to manipulate
	local UIList ContainerList;
	ContainerList = UIList(GetParent(class'UIList'));

	//make sure we correctly switch colours during sticky mode
	if (ContainerList.bStickyHighlight && ContainerList.GetSelectedItem() == self)
	{
		// Ensure we're not processing any delayed mouse events if the user has requested to ignore mouse input.
		if(ContainerList.HasHitTestDisabled()) return;

		switch(cmd)
		{
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
				OnReceiveFocus();
				break;
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
				OnLoseFocus();
				break;
			default:
				Super(UIPanel).OnMouseEvent(Cmd, Args);
				break;
		}

		return;
	}

	Super(UIPanel).OnMouseEvent(Cmd, Args);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateItemsForFocus(true);
	FocusBondmateEntry(true);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	UpdateItemsForFocus(false);
	FocusBondmateEntry(false);
}

///////////////////////////////////////////////////////////////////////
//  DEFAULT PROPERTIES
///////////////////////////////////////////////////////////////////////

defaultproperties
{
	LibID = "SoldierListItem";

	IconToTextOffsetX = 22.0f; // 26
	IconXDeltaSmallValue = 44.0f;
	IconXDelta = 60.0f; // 64
	IconYPos = 23.0f;
	IconScale = 0.65f;

	BondIconX = 518.0f;
	BondIconY = 8.0f;
	BondBarWidth = 5.0f;
	BondBarHeight = 38.0f;

	DisabledAlpha = 0.5f;
	DisabledToolTipText = "";

	bAnimateOnInit = false;

}
