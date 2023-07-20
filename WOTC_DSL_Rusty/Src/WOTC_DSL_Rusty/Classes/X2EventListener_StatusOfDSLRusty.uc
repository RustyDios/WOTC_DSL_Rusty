////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  FILE:  X2EventListener_StatusOfDSLRusty            
//  
//	File created	11/01/21    12:20
//	LAST UPDATED    20/07/23	13:30
//
//  This listener uses a CHL event to set the status in the barracks correctly uses CHL issue #322 ++
//	Also has functions for dealing with LW Officers -- Many thanks to Iridar !!
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class X2EventListener_StatusOfDSLRusty extends X2EventListener config (Game);

var localized string strOfficerAlreadySelectedStatus, strCommandingOfficer, strSPARKAlreadySelectedStatus, strSPARKUnit;

var config array<name> OfficerUnitValues, OfficerCharacterTemplates, OfficerSoldierClasses, OfficerAbilities;
var config array<name> SPARKUnitValues, SPARKCharacterTemplates, SPARKSoldierClasses, SPARKAbilities;
var config bool bEnableExtraRJSSHeaders, bOnlyOneOfficer, bOneSingleSPARK;

//var class<XComGameState_BaseObject> LWOfficerComponentClass;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  SETUP TEMPLATE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	//local X2EventListener_StatusOfDSLRusty CDO;

	Templates.AddItem(CreateListenerTemplate_StatusOfDSLRusty());

	//	MUCHAS GRACIAS TO IRIDAR !!
	//CDO = X2EventListener_StatusOfDSLRusty(class'XComEngine'.static.GetClassDefaultObject(class'WOTC_DSL_Rusty.X2EventListener_StatusOfDSLRusty'));
	//CDO.LWOfficerComponentClass = class<XComGameState_BaseObject>(class'XComEngine'.static.GetClassByName('XComGameState_Unit_LWOfficer'));
	//if (CDO.LWOfficerComponentClass != none)
	//{
	//	`LOG("LWOTC officer component class detected.", class'UIPersonnel_SoldierListItemDetailed'.default.bRustyEnableDSLLogging, 'DSLRusty');
	//}

	return Templates; 
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CREATE TEMPLATE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function CHEventListenerTemplate CreateListenerTemplate_StatusOfDSLRusty()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'StatusOfDSLRusty');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('UIPersonnel_OnSortFinished',	OnUIPSortDone,  			ELD_Immediate, 60);

	Template.AddCHEvent('rjSquadSelect_ExtraInfo', 		OnRJSS_ExtraInfosOfficer, 	ELD_Immediate, 45);	// Triggered From RJSS
	Template.AddCHEvent('rjSquadSelect_ExtraInfo', 		OnRJSS_ExtraInfosSparks, 	ELD_Immediate, 40);	// Triggered From RJSS

	Template.AddCHEvent('OverridePersonnelStatus', 		OnStatusOfOfficer, 			ELD_Immediate, 35);
	Template.AddCHEvent('OverridePersonnelStatus', 		OnStatusOfSPARK,   			ELD_Immediate, 25);

	Template.AddCHEvent('OverridePersonnelStatusTime',	OnPersonnelStatusTime, 		ELD_Immediate, 10);

	return Template;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  CONVERTING DAYS TO HOURS IF LESS THAN THRESHOLD
//
//	BASICALLY THIS WHOLE LISTENER IS PARTLY FUCKED BECAUSE SOMEONE OUT THERE FEEDS IN DAYS TO IT INSTEAD OF HOURS
//	SO I HAD TO ADD IN A WHOLE IFFY STRING CHECK TO MAKE SURE THE CONVERSION IS NOT ALREADY FUCKING DONE!
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
//FOR REF/INFO ONLY called in UiUtilities_Strategy 

	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverridePersonnelStatusTime';
	OverrideTuple.Data.Add(4);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = IsMentalState;
	OverrideTuple.Data[1].kind = XComLWTVString;
	OverrideTuple.Data[1].s = TimeLabel;
	OverrideTuple.Data[2].kind = XComLWTVInt;
	OverrideTuple.Data[2].i = TimeNum;

	`XEVENTMGR.TriggerEvent('OverridePersonnelStatusTime', OverrideTuple, Unit);
*/

static function EventListenerReturn OnPersonnelStatusTime(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local string	TimeLabel, HourString, DaysString;
	local int		TimeValue, Thresholds;
	local bool bLogs;

	Tuple = XComLWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	bLogs = class'UIPersonnel_SoldierListItemDetailed'.default.bRustyEnableDSLLogging;

	if (Tuple == none || Unitstate == none)
	{
		`LOG("TIME Bailout : INVALID DATA IN" , bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	//TimeValue should already be supplied in HOURS <<< BUT THERE ARE CASES WHEN IT ISNT
	TimeValue = Tuple.Data[2].i;
	TimeLabel = Tuple.Data[1].s;

	`LOG("TIME TUPLE DATA BGN: UNIT  [" @UnitState.GetFullName() @"]", bLogs, 'DSLRusty');
	`LOG("TIME TUPLE DATA IN : LABEL [" @TimeLabel @"] VALUE [" @ TimeValue @"] ", bLogs, 'DSLRusty');

	if (Tuple.Data[0].b) 
	{
		`LOG("TIME TUPLE DATA SKP: WAS MENTAL", bLogs, 'DSLRusty');
		return ELR_NoInterrupt; //no change for mental states ?
	}
	
	if (TimeValue <= 0 || TimeValue > 8760 ) // Ignore year long missions and paused stuff/completed?  24*365 = 8760 = 1yr
	{
		Tuple.Data[2].i = 0;
		Tuple.Data[1].s = "-!-";

		`LOG("TIME TUPLE DATA SKP: WAS MORE THAN YEAR OR LESS THAN 0", bLogs, 'DSLRusty');
		`LOG("TIME TUPLE DATA OUT: LABEL [" @Tuple.Data[1].s @"] VALUE [" @ Tuple.Data[2].i @"] ", bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	//WORK OUT WHAT STRING IS USED FOR HOURS/DAYS TO CHECK CURRENT STATUSES OF VALUE
	if( TimeValue == 1 )
	{
		HourString = class'UIUtilities_Text'.default.m_strHour;
		DaysString = class'UIUtilities_Text'.default.m_strDay;
	}
	else
	{
		HourString = class'UIUtilities_Text'.default.m_strHours;
		DaysString = class'UIUtilities_Text'.default.m_strDays;
	}

	//IF someone already set it to DAYS, convert it back to hours
	if ( InStr(TimeLabel, DaysString) != INDEX_NONE)
	{
		//convert back to hours
		TimeValue = TimeValue * 24;

		`LOG("TIME TUPLE DATA WAS IN DAYS. CONVERTED BACK TO HOURS", bLogs, 'DSLRusty');
	}

	//FIND OUR THRESHOLD VALUE
	Thresholds = class'UIPersonnel_SoldierListItemDetailed'.default.NUM_HOURS_TO_DAYS;

	//as long as the conversion is set positive, and not set to HOURS already
	if ( Thresholds > 0 && InStr(TimeLabel, HourString) == INDEX_NONE )
	{
		//above the threshold is displayed in days, below displayed in hours
		if (TimeValue > Thresholds )
		{
			//CONVERT TO DAYS
			Tuple.Data[2].i = FCeil(float(TimeValue) / 24.0f);
			Tuple.Data[1].s = DaysString;
		}
		else 
		{
			//CONTINUE IN HOURS
			Tuple.Data[2].i = TimeValue;
			Tuple.Data[1].s = HourString;
		}
	
		`LOG("TIME TUPLE DATA CHG: LIMIT [" @Thresholds @"]", bLogs, 'DSLRusty');
	}
	
	`LOG("TIME TUPLE DATA OUT: LABEL [" @Tuple.Data[1].s @"] VALUE [" @ Tuple.Data[2].i @"] ", bLogs, 'DSLRusty');
	return ELR_NoInterrupt;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
//FOR REF/INFO ONLY called in UiUtilities_Strategy 
static function TriggerOverridePersonnelStatus(XComGameState_Unit Unit,	out string Status, out EUIState eState,	
	out string TimeLabel, out string TimeValueOverride,	out int TimeNum, out int HideTime, out int DoTimeConversion)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverridePersonnelStatus';
	OverrideTuple.Data.Add(7);
	OverrideTuple.Data[0].s = Status;
	OverrideTuple.Data[1].s = TimeLabel;
	OverrideTuple.Data[2].s = TimeValueOverride;
	OverrideTuple.Data[3].i = TimeNum;
	OverrideTuple.Data[4].i = int(eState);
	OverrideTuple.Data[5].b = HideTime != 0;
	OverrideTuple.Data[6].b = DoTimeConversion != 0;

	`XEVENTMGR.TriggerEvent('OverridePersonnelStatus', OverrideTuple, Unit);
}
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  WHAT DO WE DO IF AN OFFICER IS PRESENT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function EventListenerReturn OnStatusOfOfficer(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple					Tuple;
    local XComGameState_Unit			UnitState, SquadMember;
	local int i;

	local bool bOfficerInSquad, bUnitIsOfficer, bLogs;

    Tuple = XComLWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	bOfficerInSquad = false;
	bUnitIsOfficer = false;

	bLogs = class'UIPersonnel_SoldierListItemDetailed'.default.bRustyEnableDSLLogging;

	if ( !default.bOnlyOneOfficer)
	{
		`LOG("Officer status Bailout : Option Not Enabled" , bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	bUnitIsOfficer = IsUnitOfficer(UnitState);

	//bail if the squad is empty or unit not an officer
	if (`XCOMHQ.Squad.Length <= 0 || !bUnitIsOfficer)
	{
		`LOG("Officer status Bailout : EmptySquad or not an Officer" , bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	//check the squad for an officer
	for(i = 0; i < `XCOMHQ.Squad.Length; i++)
	{
		SquadMember = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.Squad[i].ObjectID));

		if (IsUnitOfficer(SquadMember))
		{
			bOfficerInSquad = true;
		}
	}

	`LOG("Overwrite status:" @bUnitIsOfficer @":" @bOfficerInSquad, bLogs, 'DSLRusty');

    //if (UnitState != none && !bUnitInSquad && class'LWOfficerUtilities'.static.IsOfficer(Unit) && class'LWOfficerUtilities'.static.HasOfficerInSquad() && !bAllowWoundedSoldiers)
	//already have an officer and this guy is an officer too... set red flag
    if (bOfficerInSquad && bUnitIsOfficer )
	{
        Tuple.Data[0].s = default.strOfficerAlreadySelectedStatus;	//Officer In Squad
        Tuple.Data[1].s = "";										//time string y
        Tuple.Data[2].s = "";										//time value override z?
        Tuple.Data[3].i = 0;										//time number, days/hrs
        Tuple.Data[4].i = eUIState_Warning;							//eUIState_Bad;                //colour from EUI State - see UI Utilities_Colours
        Tuple.Data[5].b = true;										//Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
        Tuple.Data[6].b = false;									//convert time to hours
    }

	return ELR_NoInterrupt;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  WHAT DO WE DO IF A SPARK IS PRESENT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function EventListenerReturn OnStatusOfSPARK(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple					Tuple;
    local XComGameState_Unit			UnitState, SquadMember;
	local int i;

	local bool bSPARKInSquad, bUnitIsSPARK, bLogs;

    Tuple = XComLWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	bSPARKInSquad = false;
	bUnitIsSPARK = false;

	bLogs = class'UIPersonnel_SoldierListItemDetailed'.default.bRustyEnableDSLLogging;

	if ( !default.bOneSingleSPARK)
	{
		`LOG("SPARK status Bailout : Option Not Enabled" , bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	bUnitIsSPARK = IsUnitSPARK(UnitState);

	//bail if the squad is empty or unit not a SPARK
	if (`XCOMHQ.Squad.Length <= 0 || !bUnitIsSPARK)
	{
		`LOG("SPARK status Bailout : EmptySquad or not a SPARK" , bLogs, 'DSLRusty');
		return ELR_NoInterrupt;
	}

	//check the squad for an SPARK
	for(i = 0; i < `XCOMHQ.Squad.Length; i++)
	{
		SquadMember = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.Squad[i].ObjectID));

		if (IsUnitSPARK(SquadMember))
		{
			bSPARKInSquad = true;
		}
	}

	`LOG("Overwrite status:" @bUnitIsSPARK @":" @bSPARKInSquad, bLogs, 'DSLRusty');

	//already have an SPARK and this guy is an SPARK too... set red flag
    if (bSPARKInSquad && bUnitIsSPARK )
	{
        Tuple.Data[0].s = default.strSPARKAlreadySelectedStatus;	//SPARK In Squad
        Tuple.Data[1].s = "";										//time string y
        Tuple.Data[2].s = "";										//time value override z?
        Tuple.Data[3].i = 0;										//time number, days/hrs
        Tuple.Data[4].i = eUIState_Warning;							//eUIState_Bad;                //colour from EUI State - see UI Utilities_Colours
        Tuple.Data[5].b = true;										//Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
        Tuple.Data[6].b = false;									//convert time to hours
    }

	return ELR_NoInterrupt;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  EXTRA THINGS WE ADD TO RJSS -- COMMANDING OFFICER AND SPARK UNIT TEXT FIELD -- CALLED FROM RJSS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function EventListenerReturn OnRJSS_ExtraInfosOfficer(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local LWTuple	 Tuple, NoteTuple;
	local LWTValue	 Value;
	local int		 SlotIndex;
	local array<int> SlotIndexes;

	Tuple = LWTuple(EventData);
	
	// Check that we are interested in actually doing something
	if (Tuple == none || Tuple.Id != 'rjSquadSelect_ExtraInfo' || !default.bEnableExtraRJSSHeaders)
	{
		return ELR_NoInterrupt;
	}

	SlotIndex = Tuple.Data[0].i;

	SlotIndexes.length = 0;
	SlotIndexes = FindUnitSquadSlotIndexes(false);

	//OFFICER STATUS
	if (SlotIndexes.Find(SlotIndex) != INDEX_NONE)
	{
		Value.kind = LWTVObject;

		NoteTuple = new class'LWTuple';
		NoteTuple.Data.Length = 3;

		NoteTuple.Data[0].kind = LWTVString;
		NoteTuple.Data[0].s = default.strCommandingOfficer;
			
		NoteTuple.Data[1].kind = LWTVString;
		NoteTuple.Data[1].s = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR; // Text color
			
		NoteTuple.Data[2].kind = LWTVString;
		NoteTuple.Data[2].s = "FFD700"; // Background color, iri's gold = "FFD700"

		Value.o = NoteTuple;
		Tuple.Data.AddItem(Value);
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnRJSS_ExtraInfosSparks(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local LWTuple	 Tuple, NoteTuple;
	local LWTValue	 Value;
	local int		 SlotIndex;
	local array<int> SlotIndexes;

	Tuple = LWTuple(EventData);
	
	// Check that we are interested in actually doing something
	if (Tuple == none || Tuple.Id != 'rjSquadSelect_ExtraInfo' || !default.bEnableExtraRJSSHeaders)
	{
		return ELR_NoInterrupt;
	}

	SlotIndex = Tuple.Data[0].i;

	SlotIndexes.length = 0;
	SlotIndexes = FindUnitSquadSlotIndexes(true);

	//SPARK STATUS - ADDS ABOVE OFFICER STATUS
	if (SlotIndexes.Find(SlotIndex) != INDEX_NONE)
	{
		Value.kind = LWTVObject;

		NoteTuple = new class'LWTuple';
		NoteTuple.Data.Length = 3;

		NoteTuple.Data[0].kind = LWTVString;
		NoteTuple.Data[0].s = default.strSPARKUnit;
        
		NoteTuple.Data[1].kind = LWTVString;
		NoteTuple.Data[1].s = class'UIUtilities_Colors'.const.WHITE_HTML_COLOR; // Text color
        
		NoteTuple.Data[2].kind = LWTVString;
		NoteTuple.Data[2].s = class'UIUtilities_Colors'.const.FADED_HTML_COLOR; // Background color, "546f6f"; // Faded Cyan

		Value.o = NoteTuple;
		Tuple.Data.AddItem(Value);
    }

	return ELR_NoInterrupt;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  INFORMATION GATHERING
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static final function array<int> FindUnitSquadSlotIndexes(bool bLookForSparks)
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local XComGameState_Unit				UnitState;
	local int i;
	local array<int> iUnitIndexes;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	iUnitIndexes.length = 0;

	for (i = 0; i < XComHQ.Squad.Length; i++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));

		if (UnitState != none )
		{
			if (IsUnitSpark(UnitState) && bLookForSparks)
			{
				iUnitIndexes.AddItem(i);
			}
			else if (IsUnitOfficer(UnitState) && !bLookForSparks)
			{
				iUnitIndexes.AddItem(i);
			}
		}
	}

	return iUnitIndexes;
}

static final function bool IsUnitSpark(const out XComGameState_Unit UnitState)
{
	local UnitValue	UV;
	local name ValueName;

	//Attempts to find 'SPARK' units
	if (UnitState.GetMyTemplateName() == 'SparkSoldier' || UnitState.GetMyTemplateName() == 'LostTowersSpark')	{ return true; }
	else if (UnitState.HasAnyOfTheAbilitiesFromAnySource(default.SPARKAbilities)) 								{ return true; }
	else if (default.SPARKCharacterTemplates.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)					{ return true; }
	else if (default.SPARKSoldierClasses.Find(UnitState.GetSoldierClassTemplateName()) != INDEX_NONE) 			{ return true; }

	foreach default.SPARKUnitValues(ValueName)
	{
		if (UnitState.GetUnitValue(ValueName, UV))
		{
			return true;
		}
	}

	return false;
}

static final function bool IsUnitOfficer(const out XComGameState_Unit UnitState)
{
	local UnitValue	UV;
	local name ValueName;

	//if (default.LWOfficerComponentClass != none && UnitState.FindComponentObject(default.LWOfficerComponentClass) != none){ return true; }
	if (GetIsUnitLWOfficer(UnitState)) { return true; }
	else if (UnitState.HasAnyOfTheAbilitiesFromAnySource(default.OfficerAbilities))											{ return true; }
	else if (default.OfficerCharacterTemplates.Find(UnitState.GetMyTemplateName()) != INDEX_NONE) 							{ return true; }
	else if (default.OfficerSoldierClasses.Find(UnitState.GetSoldierClassTemplateName()) != INDEX_NONE)						{ return true; }

	foreach default.OfficerUnitValues(ValueName)
	{
		if (UnitState.GetUnitValue(ValueName, UV))
		{
			return true;
		}
	}

	return false;
}

static function bool GetIsUnitLWOfficer(XComGameState_Unit Unit)
{
	local XComLWTuple Tuple;

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

	return Tuple.Data[0].b;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  EXTRA THINGS WE DO ON SORT OF UI PERSONNEL
//	So this CHL event runs AFTER the normal list has been sorted and set up
//	this means that Screen.m_arrSoldiers == Screen.m_kList ? HOPEFULLY ?
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function EventListenerReturn OnUIPSortDone(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local UIPersonnel SS_Screen;

	SS_Screen = UIPersonnel(EventSource);

	if (SS_Screen != none)
	{
		if (SS_Screen.IsA('UIPersonnel_SquadSelect') || SS_Screen.IsA('SSAAT_UIPersonnel_Select') )
		{
			if(default.bOnlyOneOfficer) { TryDisableOfficers(SS_Screen); }
			if(default.bOneSingleSPARK) { TryDisableForSpark(SS_Screen); }
		}

		RefreshTitle(SS_Screen);
	}

	return ELR_NoInterrupt;
}

static function RefreshTitle(UIPersonnel SS_Screen)
{
	local string HeaderString;

	if( SS_Screen.m_arrNeededTabs.Length == 1 )
	{
		switch( SS_Screen.m_arrNeededTabs[0] )
		{
			case eUIPersonnel_Soldiers:		HeaderString = SS_Screen.m_strSoldierTab;	break;
			case eUIPersonnel_Scientists:	HeaderString = SS_Screen.m_strScientistTab;	break;
			case eUIPersonnel_Engineers:	HeaderString = SS_Screen.m_strEngineerTab;	break;
			case eUIPersonnel_Deceased:		HeaderString = SS_Screen.m_strDeceasedTab;	break;
		}

		SS_Screen.SetScreenHeader(HeaderString $ " [" $ SS_Screen.m_kList.GetItemCount() $ "]" );
	}
}

static function TryDisableOfficers(UIScreen Screen)
{
	local UIPersonnel SS_Screen;
	local UIPersonnel_SoldierListItemDetailed ListItem;

    local XComGameState_Unit UnitState, SquadMember;
	local bool bOfficerInSquad;
	local int i;

	//cast the screen
	SS_Screen = UIPersonnel(Screen);

	//check the squad for an officer
	for(i = 0; i < `XCOMHQ.Squad.Length; i++)
	{
		SquadMember = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.Squad[i].ObjectID));

		// ASK THE EVENT LISTENER FUNCTION IF WE IS AN OFFICER
		if (IsUnitOfficer(SquadMember))
		{
			bOfficerInSquad = true;
		}
	}

	//bail if the squad is empty or unit no officer in squad
	if (`XCOMHQ.Squad.Length <= 0 || !bOfficerInSquad) { return; }

	if (SS_Screen.IsA('UIPersonnel_SquadSelect') || SS_Screen.IsA('SSAAT_UIPersonnel_Select') )
	{
		for (i = 0 ; i < SS_Screen.m_kList.GetItemCount() ; i++)
		{
			ListItem = UIPersonnel_SoldierListItemDetailed(SS_Screen.m_kList.GetItem(i));
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ListItem.UnitRef.ObjectID));

			if (IsUnitOfficer(UnitState) && !ListItem.IsDisabled)
			{
				ListItem.SetDisabled(true, default.strOfficerAlreadySelectedStatus);
				ListItem.RefreshTooltipText();
			}
		}
	}
}

static function TryDisableForSpark(UIScreen Screen)
{
	local UIPersonnel SS_Screen;
	local UIPersonnel_SoldierListItemDetailed ListItem;

    local XComGameState_Unit UnitState, SquadMember;
	local bool bSPARKInSquad;
	local int i;

	//cast the screen
	SS_Screen = UIPersonnel(Screen);

	//if the screen is not UIP bail
	if (SS_Screen == none)	{ return; }

	//check the squad for a SPARK
	for(i = 0; i < `XCOMHQ.Squad.Length; i++)
	{
		SquadMember = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.Squad[i].ObjectID));

		// ASK THE EVENT LISTENER FUNCTION IF WE IS A SPARK
		if (IsUnitSpark(SquadMember))
		{
			bSPARKInSquad = true;
		}
	}

	//bail if the squad is empty or unit no Spark in Squad
	if (`XCOMHQ.Squad.Length <= 0 || !bSPARKInSquad) { return; }

	if (SS_Screen.IsA('UIPersonnel_SquadSelect') || SS_Screen.IsA('SSAAT_UIPersonnel_Select') )
	{
		for (i = 0 ; i < SS_Screen.m_kList.GetItemCount() ; i++)
		{
			ListItem = UIPersonnel_SoldierListItemDetailed(SS_Screen.m_kList.GetItem(i));
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ListItem.UnitRef.ObjectID));

			if (IsUnitSpark(UnitState) && !ListItem.IsDisabled)
			{
				ListItem.SetDisabled(true, default.strSPARKAlreadySelectedStatus);
				ListItem.RefreshTooltipText();
			}
		}
	}
}
