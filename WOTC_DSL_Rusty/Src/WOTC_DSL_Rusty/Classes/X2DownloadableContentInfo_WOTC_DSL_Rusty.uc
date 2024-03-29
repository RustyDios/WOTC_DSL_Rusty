//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTC_DSL_Rusty.uc                                    
//
//	CREATED BY RUSTYDIOS	08/12/20	02:00
//	LAST EDITED				12/11/23	21:10
//
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTC_DSL_Rusty extends X2DownloadableContentInfo;

//var config bool IsRequiredCHLInstalled, bForceHighlanderMethod;

var config bool bRPGODetected;
var private config bool bIsRPGOLoaded, bIsRPGOLoadedChecked;

// Copied from robojumper's SquadSelect. Checks whether the Community Highlander
// is active and meets the given minimum version requirement.
//	HIGHLANDER IS NOW A HARD REQUIRED MOD, WE DONT CARE WHAT VERSION
static function bool IsCHLMinVersionInstalled(int iMajor, int iMinor)
{
	//if (default.bForceHighlanderMethod)
	//{
		return true;
	//}
	
	//return class'CHXComGameVersionTemplate'.default.MajorVersion > iMajor ||
	//	(class'CHXComGameVersionTemplate'.default.MajorVersion == iMajor &&
	//	 class'CHXComGameVersionTemplate'.default.MinorVersion >= iMinor);
}

static event OnLoadedSavedGame(){}

static final function bool IsRPGOLoaded()
{
	//return true;
	
	if (default.bIsRPGOLoadedChecked)
	{
		return default.bIsRPGOLoaded;
	}

	default.bIsRPGOLoadedChecked = true;
	default.bIsRPGOLoaded = IsModActive('XCOM2RPGOverhaul');

	return default.bIsRPGOLoaded;
}

static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}

static event OnLoadedSavedGameToStrategy(){}
static event InstallNewCampaign(XComGameState StartState){}

//static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState){}
//static event OnPostMission(){}
//static event ModifyTacticalTransferStartState(XComGameState TransferStartState){}
//static event OnExitPostMissionSequence(){}

// Added in Community Highlander 1.18, so if this is called, the highlander is guaranteed to be loaded.
//	HIGHLANDER IS NOW A HARD REQUIRED MOD, WE DONT CARE WHAT VERSION
//static function OnPreCreateTemplates()
//{
//	default.IsRequiredCHLInstalled = IsCHLMinVersionInstalled(1, 19);
//}

//static event OnPostTemplatesCreated(){}
//static event OnDifficultyChanged(){}
//static event UpdateDLC(){}
//static event OnPostAlienFacilityCreated(XComGameState NewGameState, StateObjectReference MissionRef){}
//static event OnPostFacilityDoomVisualization(){}
//static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef){return false;}

/// <summary>
/// A dialogue popup used for players to confirm or deny whether new gameplay content should be installed for this DLC / Mod.
/// </summary>
//static function EnableDLCContentPopup()
//{
//	local TDialogueBoxData kDialogData;
//
//	kDialogData.eType = eDialog_Normal;
//	kDialogData.strTitle = default.EnableContentLabel;
//	kDialogData.strText = default.EnableContentSummary;
//	kDialogData.strAccept = default.EnableContentAcceptLabel;
//	kDialogData.strCancel = default.EnableContentCancelLabel;
//
//	kDialogData.fnCallback = EnableDLCContentPopupCallback_Ex;
//	`HQPRES.UIRaiseDialog(kDialogData);
//}

//simulated function EnableDLCContentPopupCallback(eUIAction eAction){}
//simulated function EnableDLCContentPopupCallback_Ex(Name eAction)
//{	
//	switch (eAction)
//	{
//		case 'eUIAction_Accept':	EnableDLCContentPopupCallback(eUIAction_Accept);	break;
//		case 'eUIAction_Cancel':	EnableDLCContentPopupCallback(eUIAction_Cancel);	break;
//		case 'eUIAction_Closed':	EnableDLCContentPopupCallback(eUIAction_Closed);	break;
//	}
//}

//static function bool ShouldUpdateMissionSpawningInfo(StateObjectReference MissionRef){return false;}
//static function bool UpdateMissionSpawningInfo(StateObjectReference MissionRef){return false;}
//static function string GetAdditionalMissionDesc(StateObjectReference MissionRef){return "";}
//static function bool AbilityTagExpandHandler(string InString, out string OutString){return false;}
//static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay){}
//static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet){}

exec function RustyFix_DSL_GiveOverloadToUnit()
{
	local UIArmory							Armory;
	local StateObjectReference				UnitRef;
	local XComGameState_Unit				UnitState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local array<name>TraitTemplateNames;
	local name TraitTemplateName;
	local X2AbilityTemplateManager AbMan;
	local X2AbilityTemplate AbilityTemplate;
	local SoldierClassAbilityType AbilityType;
	local ClassAgnosticAbility Ability;

	History = `XCOMHISTORY;

	Armory = UIArmory(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory'));
	if (Armory == none)
	{
		return;
	}

	UnitRef = Armory.GetUnitRef();
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	if (UnitState == none)
	{
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding overload to unit");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	TraitTemplateNames.AddItem('FearOfSectoids');
	TraitTemplateNames.AddItem('FearOfPanic');
	TraitTemplateNames.AddItem('FearOfMissedShots');
	TraitTemplateNames.AddItem('FearOfVertigo');
	TraitTemplateNames.AddItem('FearOfVipers');
	TraitTemplateNames.AddItem('FearOfArchons');
	TraitTemplateNames.AddItem('FearOfStunLancers');

	foreach TraitTemplateNames(TraitTemplateName)
	{
		UnitState.AcquireTrait(NewGameState, TraitTemplateName, true);
	}

	AbMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TraitTemplateNames.length = 0;

	TraitTemplateNames.AddItem('Fuse');
	TraitTemplateNames.AddItem('Soulfire');
	TraitTemplateNames.AddItem('SoulSteal');
	TraitTemplateNames.AddItem('PaleHorse');
	TraitTemplateNames.AddItem('TargetDefinition');
	TraitTemplateNames.AddItem('Insanity');
	TraitTemplateNames.AddItem('Inspire');

	foreach TraitTemplateNames(TraitTemplateName)
	{
		AbilityTemplate = AbMan.FindAbilityTemplate(TraitTemplateName);
		AbilityType.AbilityName = AbilityTemplate.DataName;

		Ability.AbilityType = AbilityType;
		Ability.bUnlocked = true;
		Ability.iRank = 1;
		UnitState.bSeenAWCAbilityPopup = true;
		UnitState.AWCAbilities.AddItem(Ability);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return;
}
