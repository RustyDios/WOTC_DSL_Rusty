//---------------------------------------------------------------------------------------
//  FILE:    MoreDetailsManager.uc
//
//	CREATED BY BOUNTYGIVER	08/12/20	02:00
//	EDITED	BY RUSTYDIOS	17/07/22	21:00
//
//	CONTROLS DISPLAYS OF EXTRA DSL OPTIONS LIKE DETAILS BUTTON AND LEGEND
//
//---------------------------------------------------------------------------------------
class MoreDetailsManager extends UIPanel dependson(UIStatListImproved_DSLKey);

struct RPGOWeaponCatImage
{
	var name Category;
	var string ImagePath;
};

var localized array<string> m_strNaturalAptitudeLabels;
var localized string m_strToggleDetails, m_strShowLegend, m_strLegendTitle, m_strShieldsLabel, m_strPCSLabel, m_strSPARKLabel, m_strNaturalAptitude, m_strSkillPoints;
var localized string m_strSection1, m_strSection2, m_strSection3, m_strSection4, m_strSection5, m_strSectionR;

var UIBGBox LegendTextBG, RPGOTextBG;
var UIPanel LegendText, LegendSplitLine, RPGOText, RPGOSplitline;
var UIX2PanelHeader LegendTitleHeader, RPGOTitleHeader;
var UIStatListImproved_DSLKey LegendStatsList, RPGOStatsList;

var bool IsMoreDetails, IsLegendOpen, bRPGODetected, bDisplayWeaponIcons;

////////////////////////////////////////////////
//  GET OR SPAWN MANAGER PARENT
///////////////////////////////////////////////

static function MoreDetailsManager GetParentDM(UIPanel ChildPanel)
{
	local MoreDetailsManager MDMgr;

	MDMgr = MoreDetailsManager(ChildPanel.Screen.GetChildByName('DSL_MoreDetailsMgr', false));

	if (MDMgr != none)
	{
		return MDMgr;
	}
}

//safely create if it doesn't exist yet
static function MoreDetailsManager GetOrSpawnParentDM(UIPanel ChildPanel)
{
	local MoreDetailsManager MDMgr;
	local MoreDetailsNavigatorWrapper NewNavMgr;

	MDMgr = GetParentDM(ChildPanel);

	if (MDMgr != none)
	{
		return MDMgr;
	}

	MDMgr = ChildPanel.Screen.Spawn(class'MoreDetailsManager', ChildPanel.Screen);
	MDMgr.InitPanel('DSL_MoreDetailsMgr');

	NewNavMgr = new(ChildPanel.Screen) class'MoreDetailsNavigatorWrapper' (ChildPanel.Screen.Navigator);
	NewNavMgr.InitNavigator(ChildPanel.Screen);
	NewNavMgr.ChildNavigator = ChildPanel.Screen.Navigator;

	ChildPanel.Screen.Navigator = NewNavMgr;

	return MDMgr;
}

////////////////////////////////////////////////
//  ON INIT
///////////////////////////////////////////////

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	bRPGODetected = class'X2DownloadableContentInfo_WOTC_DSL_Rusty'.static.IsRPGOLoaded();
	bDisplayWeaponIcons = class'UIPersonnel_SoldierListItemDetailed'.static.ShouldDisplayWeaponIcons() ;

	BuildLegendPanel();

	if (bRPGODetected || bDisplayWeaponIcons )
	{
		BuildRPGOPanel();
	}

	//HIDE UNTILL CALLED
	IsLegendOpen = false;
	ToggleLegend(IsLegendOpen);

	AddHelp();

	return self;
}

////////////////////////////////////////////////
//  BUILD NEW SIDE PANEL FOR LEGEND KEY
///////////////////////////////////////////////

simulated function BuildLegendPanel()
{
    //setup the text background panel
    LegendTextBG = Spawn(class'UIBGBox', self);
    LegendTextBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    LegendTextBG.InitBG('DSL_Legend_BG', 20, 86, 250, 900); // pos x, pos y , width, height

    //setup the text panel to the same size and position
    LegendText = Spawn(class'UIPanel', self);
    LegendText.InitPanel('DSL_Legend_Text');
    LegendText.SetSize(LegendTextBG.Width, LegendTextBG.Height);

    //setup the text panel title
	LegendTitleHeader = Spawn(class'UIX2PanelHeader', LegendText);
	LegendTitleHeader.InitPanelHeader('DSL_Legend_Title', "", "");
	LegendTitleHeader.SetHeaderWidth(LegendText.Width - 20);
	LegendTitleHeader.bRealizeOnSetText = true;	//allows recolouring of the title

	//setup a 'linebreak'
	LegendSplitLine = Spawn(class'UIPanel', LegendText);
	LegendSplitLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
    LegendSplitLine.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
	LegendSplitLine.SetSize( LegendText.Width - 30, 2 );
    LegendSplitLine.SetAlpha( 15 );

	//setup the multiline shaded stats list
	LegendStatsList = Spawn(class'UIStatListImproved_DSLKey', LegendText);
	LegendStatsList.InitStatList('StatsList');
	LegendStatsList.SetSize(LegendText.Width - 20, LegendText.Height - 80);
	LegendStatsList.PADDING_LEFT = 5;
	LegendStatsList.PADDING_RIGHT = 5;

	//shift positions
	LegendText.SetPosition(LegendTextBG.X, LegendTextBG.Y);
	LegendTitleHeader.SetPosition(LegendTitleHeader.X + 10, LegendTitleHeader.Y + 10);
    LegendSplitLine.SetPosition(LegendTitleHeader.X + 5, LegendTitleHeader.Y + 40);
	LegendStatsList.SetPosition(LegendTitleHeader.X, LegendTitleHeader.Y + 50);

	SetLegendText();
}

////////////////////////////////////////////////
//  BUILD NEW SIDE PANEL FOR LEGEND KEY
///////////////////////////////////////////////

simulated function BuildRPGOPanel()
{
    //setup the text background panel
    RPGOTextBG = Spawn(class'UIBGBox', self);
    RPGOTextBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    RPGOTextBG.InitBG('DSL_RPGO_BG', 1648, 86, 250, 900); // pos x, pos y , width, height

    //setup the text panel to the same size and position
    RPGOText = Spawn(class'UIPanel', self);
    RPGOText.InitPanel('DSL_RPGO_Text');
    RPGOText.SetSize(RPGOTextBG.Width, RPGOTextBG.Height);

    //setup the text panel title
	RPGOTitleHeader = Spawn(class'UIX2PanelHeader', RPGOText);
	RPGOTitleHeader.InitPanelHeader('DSL_RPGO_Title', "", "");
	RPGOTitleHeader.SetHeaderWidth(RPGOText.Width - 20);
	RPGOTitleHeader.bRealizeOnSetText = true;	//allows recolouring of the title

	//setup a 'linebreak'
	RPGOSplitLine = Spawn(class'UIPanel', RPGOText);
	RPGOSplitLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
    RPGOSplitLine.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
	RPGOSplitLine.SetSize( RPGOText.Width - 30, 2 );
    RPGOSplitLine.SetAlpha( 15 );

	//setup the multiline shaded stats list
	RPGOStatsList = Spawn(class'UIStatListImproved_DSLKey', RPGOText);
	RPGOStatsList.IconSize = 28;
	RPGOStatsList.InitStatList('StatsList');
	RPGOStatsList.SetSize(RPGOText.Width - 20, RPGOText.Height - 80);
	RPGOStatsList.PADDING_LEFT = 5;
	RPGOStatsList.PADDING_RIGHT = 5;

	//shift positions
	RPGOText.SetPosition(RPGOTextBG.X, RPGOTextBG.Y);
	RPGOTitleHeader.SetPosition(RPGOTitleHeader.X + 10, RPGOTitleHeader.Y + 10);
    RPGOSplitLine.SetPosition(RPGOTitleHeader.X + 5, RPGOTitleHeader.Y + 40);
	RPGOStatsList.SetPosition(RPGOTitleHeader.X, RPGOTitleHeader.Y + 50);

	SetRPGOText();
}

////////////////////////////////////////////////
//  ADD BUTTON CONTROLS TO NAV HELP
///////////////////////////////////////////////

simulated function AddHelp()
{
	local UINavigationHelp NavHelp;
	local int i;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	
	if(`SCREENSTACK.IsTopScreen(Screen) && NavHelp.m_arrButtonClickDelegates.Length > 0 && NavHelp.m_arrButtonClickDelegates.Find(OnToggleDetails) == INDEX_NONE)
	{
		//ADD BUTTON TO TOGGLE DETAILS OF SCREEN
		NavHelp.AddCenterHelp(m_strToggleDetails, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RT_R2, OnToggleDetails, false, "" /* ToolTipText */);

		//ADD BUTTON TO OPEN LEGEND PANEL
		if (`ISCONTROLLERACTIVE)
		{
			NavHelp.AddLeftHelp(m_strShowLegend, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, OnToggleLegend, false, m_strShowLegend);
		}
		else
		{
			NavHelp.SetButtonType("XComButtonIconPC");
			i = eButtonIconPC_Details;
			NavHelp.AddLeftHelp(string(i), string(i), OnToggleLegend, false, m_strShowLegend);
			NavHelp.SetButtonType("");
		}

	}

	if (`SCREENSTACK.IsInStack(Screen.class))
	{
		Screen.SetTimer(1.0f, false, nameof(AddHelp), self);
	}
}

////////////////////////////////////////////////
//  OPEN/CLOSE DETAILED VIEW
///////////////////////////////////////////////

simulated function OnToggleDetails()
{
	local array<UIPanel> AllChildren;
	local UIPanel OnePanel;
	local UIPersonnel_SoldierListItemDetailed ChildPanel;

	IsMoreDetails = !IsMoreDetails;

	Screen.GetChildrenOfType(class'UIPersonnel_SoldierListItemDetailed', AllChildren);

	foreach AllChildren(OnePanel)
	{
		ChildPanel = UIPersonnel_SoldierListItemDetailed(OnePanel);
		if (ChildPanel != none)
		{
			ChildPanel.ShowDetailed(IsMoreDetails);
		}
	}
}

////////////////////////////////////////////////
//  OPEN/CLOSE LEGEND PANEL
///////////////////////////////////////////////

simulated function OnToggleLegend()
{
	ToggleLegend(!IsLegendOpen);
}

simulated function ToggleLegend(bool ShouldWeShow)
{
	if (ShouldWeShow)
	{
		IsLegendOpen = true;

		LegendTextBG.Show();		LegendText.Show();
		LegendTitleHeader.Show();	LegendSplitLine.Show();		LegendStatsList.Show();

		if(bRPGODetected || bDisplayWeaponIcons )
		{
			RPGOTextBG.Show();		RPGOText.Show();
			RPGOTitleHeader.Show();	RPGOSplitLine.Show();		RPGOStatsList.Show();
		}
	}
	else
	{
		IsLegendOpen = false;

		LegendTextBG.Hide();		LegendText.Hide();
		LegendTitleHeader.Hide();	LegendSplitLine.Hide();		LegendStatsList.Hide();

		RPGOTextBG.Hide();			RPGOText.Hide();
		RPGOTitleHeader.Hide();		RPGOSplitLine.Hide();		RPGOStatsList.Hide();
	}
}

////////////////////////////////////////////////
//  UPDATE LEGEND  - DATA GATHERING
///////////////////////////////////////////////

simulated function SetLegendText()
{
	LegendTitleHeader.SetText(class'UIUtilities_Text'.static.GetColoredText(CAPS(m_strLegendTitle), eUIState_Normal, 28), "");
	LegendStatsList.RefreshData(GetLegendStats());
}

simulated function array<UISummary_DSL_Legend> GetLegendStats()
{
	local array<UISummary_DSL_Legend> Stats;
	local UISummary_DSL_Legend StatsEntry;

	local array<string> APColours, APImagePath, StatIconPath;
	local int i;

	//gather information
	APColours = class'UIPersonnel_SoldierListItemDetailed'.default.APColours;
	APImagePath = class'UIPersonnel_SoldierListItemDetailed'.default.APImagePath;
	StatIconPath = class'UIPersonnel_SoldierListItemDetailed'.default.StatIconPath;

	//reset our array
	Stats.Length = 0;	

	//construct AP Icon list
	StatsEntry.LabelState = eUIState_Header;
	StatsEntry.IconBGColor = "";	
	StatsEntry.Label = Repl(class'UISoldierHeader'.default.m_strCombatIntel, ":","");	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);

	StatsEntry.LabelState = eUIState_Normal;
	for (i = 0 ; i < APColours.length ; i++)
	{
		StatsEntry.Label = class'X2StrategyGameRulesetDataStructures'.default.ComIntLabels[i] ;
		StatsEntry.IconBGColor = APColours[i];	
		StatsEntry.IconPath = APImagePath[i];	
		Stats.AddItem(StatsEntry);
	}

	StatsEntry.IconBGColor = "";
	StatsEntry.Label = Repl(class'UISoldierHeader'.default.m_strSoldierAP, ":","");		StatsEntry.IconPath = StatIconPath[17];	Stats.AddItem(StatsEntry);

	//construct other icons
	//I could have looped through all the StatIconPath array here and just added as they came up
	//BUT I wanted more direct control, with sections and 'headers'

	StatsEntry.Label = m_strSection1;		StatsEntry.LabelState = eUIState_Header;	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);	

	StatsEntry.LabelState = eUIState_Normal;
	StatsEntry.Label = class'XLocalizedData'.default.HealthLabel;						StatsEntry.IconPath = StatIconPath[0];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'UISoldierHeader'.default.m_strMobilityLabel;				StatsEntry.IconPath = StatIconPath[1];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'XLocalizedData'.default.DodgeLabel;						StatsEntry.IconPath = StatIconPath[2];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'XLocalizedData'.default.DefenseLabel;						StatsEntry.IconPath = StatIconPath[6];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'XLocalizedData'.default.TechLabel;							StatsEntry.IconPath = StatIconPath[3];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'XLocalizedData'.default.PsiOffenseLabel;					StatsEntry.IconPath = StatIconPath[4];	Stats.AddItem(StatsEntry);	
	
	StatsEntry.Label = m_strSection2;		StatsEntry.LabelState = eUIState_Header;	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);	

	StatsEntry.LabelState = eUIState_Normal;
	StatsEntry.Label = class'XLocalizedData'.default.AimLabel;							StatsEntry.IconPath = StatIconPath[5];	Stats.AddItem(StatsEntry);
	StatsEntry.Label = class'XLocalizedData'.default.WillLabel;							StatsEntry.IconPath = StatIconPath[7];	Stats.AddItem(StatsEntry);	

	StatsEntry.Label = m_strSection3;		StatsEntry.LabelState = eUIState_Header;	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);

	StatsEntry.LabelState = eUIState_Normal;
	StatsEntry.Label = class'XLocalizedData'.default.ArmorLabel;						StatsEntry.IconPath = StatIconPath[12];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = m_strShieldsLabel;												StatsEntry.IconPath = StatIconPath[13];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = Repl(class'UISoldierHeader'.default.m_strMissionsLabel, ":","");	StatsEntry.IconPath = StatIconPath[9];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'XLocalizedData'.default.XpSharesLabel;						StatsEntry.IconPath = StatIconPath[11];	Stats.AddItem(StatsEntry);
	
	StatsEntry.Label = m_strSection4;		StatsEntry.LabelState = eUIState_Header;	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);	

	StatsEntry.LabelState = eUIState_Normal;
	StatsEntry.Label = Repl(class'UISoldierHeader'.default.m_strKillsLabel, ":","");	StatsEntry.IconPath = StatIconPath[10];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = m_strPCSLabel;													StatsEntry.IconPath = StatIconPath[16];	Stats.AddItem(StatsEntry);	

	StatsEntry.Label = m_strSection5;		StatsEntry.LabelState = eUIState_Header;	StatsEntry.IconPath = "";				Stats.AddItem(StatsEntry);

	StatsEntry.LabelState = eUIState_Normal;
	StatsEntry.Label = class'UIArmory_MainMenu'.default.m_strPromote;					StatsEntry.IconPath = StatIconPath[11];	Stats.AddItem(StatsEntry);	
	StatsEntry.Label = class'UIArmory_MainMenu'.default.m_strSoldierBonds;				StatsEntry.IconPath = StatIconPath[14];	Stats.AddItem(StatsEntry);
	StatsEntry.Label = Repl(class'UIToDoWidget'.default.LabelBondAvailableText,":","");	StatsEntry.IconPath = StatIconPath[15];	Stats.AddItem(StatsEntry);

	StatsEntry.Label = m_strSPARKLabel;													StatsEntry.IconPath = StatIconPath[18];	StatsEntry.IconBGColor = "FEF4CB";	Stats.AddItem(StatsEntry);
	StatsEntry.Label = CAPS(class'XLocalizedData'.default.OfficerBradfordFirstName);	StatsEntry.IconPath = StatIconPath[8];	StatsEntry.IconBGColor = "FEF4CB";	Stats.AddItem(StatsEntry);//might localise weird ?

	return Stats;
}

////////////////////////////////////////////////
//  GET FILL STATS FOR THE RPGO PANEL
///////////////////////////////////////////////

simulated function SetRPGOText()
{
	RPGOTitleHeader.SetText(class'UIUtilities_Text'.static.GetColoredText(CAPS(m_strLegendTitle), eUIState_Normal, 28), "");
	RPGOStatsList.RefreshData(GetRPGOStats());
}

simulated function array<UISummary_DSL_Legend> GetRPGOStats()
{
	local array<UISummary_DSL_Legend> Stats;
	local UISummary_DSL_Legend StatsEntry;

	local array<RPGOWeaponCatImage> RPGOWeaponCatImages;
	local array<string> NAColours, NAImagePath, StatIconPath;
	local int i;

	local X2ItemTemplateManager ItemMgr;

	//gather information
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NAColours = class'UIPersonnel_SoldierListItemDetailed'.default.NAColours;
	NAImagePath = class'UIPersonnel_SoldierListItemDetailed'.default.NAImagePath;
	StatIconPath = class'UIPersonnel_SoldierListItemDetailed'.default.StatIconPath;
	RPGOWeaponCatImages = class'UIPersonnel_SoldierListItemDetailed'.default.RPGOWeaponCatImages;

	//reset our array
	Stats.Length = 0;	

	//construct AP Icon list

	if (bRPGODetected)
	{
		StatsEntry.Label = m_strNaturalAptitude; StatsEntry.LabelState = eUIState_Header; StatsEntry.IconBGColor = "";	StatsEntry.IconPath = ""; Stats.AddItem(StatsEntry);

		StatsEntry.LabelState = eUIState_Normal;
		for (i = 0 ; i < NAColours.length ; i++)
		{
			StatsEntry.Label = m_strNaturalAptitudeLabels[i] ;
			StatsEntry.IconBGColor = NAColours[i];	
			StatsEntry.IconPath = NAImagePath[i];	
			Stats.AddItem(StatsEntry);
		}

		StatsEntry.Label = m_strSkillPoints; 	 StatsEntry.IconBGColor = ""; StatsEntry.IconPath = StatIconPath[17]; Stats.AddItem(StatsEntry);
	}

	if (bRPGODetected || bDisplayWeaponIcons)
	{
		StatsEntry.Label = m_strSectionR;		 StatsEntry.LabelState = eUIState_Header; StatsEntry.IconBGColor = "";	StatsEntry.IconPath = ""; Stats.AddItem(StatsEntry);

		StatsEntry.LabelState = eUIState_Normal;
		StatsEntry.IconSize = 32;
		StatsEntry.IconOffsetX = -6;
		StatsEntry.IconOffsetY = -8;

		for (i = 0 ; i < RPGOWeaponCatImages.length ; i++)
		{
			if (ItemMgr.WeaponCategoryIsValid(RPGOWeaponCatImages[i].Category))
			{
				StatsEntry.Label = GetLocalizedCategory(RPGOWeaponCatImages[i].Category);
				StatsEntry.IconPath = RPGOWeaponCatImages[i].ImagePath;
				Stats.AddItem(StatsEntry);
			}
		}
	}

	return Stats;
}

////////////////////////////////////////////////
//  HELPER - ATTEMPT LOCALISE CATEGORY
///////////////////////////////////////////////

static public function string GetLocalizedCategory(name Key)
{
	local string defaultreturn;

	switch (Key)
	{
		case 'rifle': 				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryRifle); 				break;
		case 'sniper_rifle':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySniperRifle);		break;
		case 'cannon':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryCannon); 			break;
		case 'shotgun':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryShotgun); 			break;
		case 'gauntlet':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryGauntlet); 			break;
		case 'vektor_rifle':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryVektorRifle);		break;
		case 'bullpup':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryBullpup); 			break;
		case 'SMG':					return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySMG);	 			break;
		case 'pistol':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPistol); 			break;
		case 'sword':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySword); 				break;
		case 'gremlin':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryGremlin); 			break;
		case 'grenade_launcher':	return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryGrenadeLauncher);	break;
		case 'claymore':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryClaymore); 			break;
		case 'claymoreP':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryClaymoreP);			break;
		case 'wristblade':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryWristblade);			break;
		case 'sidearm':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySidearm); 			break;
		case 'psiamp':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPsiamp); 			break;
		case 'replace_psiamp':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPsiamp); 			break;
		case 'psiamp_pm':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPsiampPM); 			break;
		case 'sparkrifle':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySparkrifle);			break;
		case 'sparkbit':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySparkBit);			break;
		case 'spark_shield':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySparkShield);		break;
		case 'combatknife':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryCombatknife);		break;
		case 'arcthrower':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryArcthrower);			break;
		case 'holotargeter':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryHolotargeter);		break;
		case 'lw_gauntlet':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryLWGauntlet);			break;
		case 'lwgauntlet':			return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryLWGauntlet);			break;
		case 'sawedoffshotgun':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategorySawedoffshotgun);	break;
		case 'Heavy':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryHeavy); 				break;
		case 'psionicreaper':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPsionicReaper);	 	break;
		case 'psigatlingrifle':		return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryPsiGatlingRifle);	break;
		case 'empty':				return CAPS(class'XGLocalisedData_DSL'.default.ItemCategoryEmpty); 				break;
	}

	defaultreturn = string(key);
	defaultreturn = Repl(defaultreturn,"iri_","");
	defaultreturn = Repl(defaultreturn,"_", " ");
	
	return CAPS(defaultreturn);
}
