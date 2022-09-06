//---------------------------------------------------------------------------------------
//  FILE:   UIStatListImproved.uc BY Brit Steiner --  6/24/2014 and RustyDios 22/06/22
//	EDITED:	08/07/22	03:30
//
//	This is an autoformatting list of data in 2 columns 
//	Image + Label will autoscroll left/right, Alternating background tint slightly. 
//
//	A copy of UIStatList mixed with UITextContainer and UIList to get vertical autoscroll properly working
//	!!	SCROLLBAR HAS ISSUES -- ENSURE ALWAYS SET TO AUTOSCROLL	!!
//
//---------------------------------------------------------------------------------------

class UIStatListImproved_DSLKey extends UIPanel;

struct TUIStatList_DSL_Legend
{
	var int ID;
	var UIPanel BG; 
	var UIScrollingText Label;
    var UIICon Icon;
};

struct UISummary_DSL_Legend
{
	var string Label; 
	var string IconPath;
    var string IconBGColor;
	var int IconSize;
	var int IconOffsetX;
	var int IconOffsetY;

	var EUIState LabelState; 

	structdefaultproperties
	{
		IconSize = 22;
		LabelState = eUIState_Normal;
	}
};

var array<TUIStatList_DSL_Legend> Items;

// UI member variables
var UIPanel     textcontainer;
var UIMask      mask;
var UIScrollbar	scrollbar;

//scrolling stuffs
var bool bAutoScroll; 
var int	scrollbarPadding;
var float ScrollPercent;

//padding and sizing stuffs
var float PADDING_LEFT, PADDING_RIGHT, VALUE_COL_SIZE, LineHeight, LineHeight3D;
var int IconSize;

delegate OnSizeRealized();

////////////////////////////////////////////////
//  ON INIT
////////////////////////////////////////////////

simulated function UIPanel InitStatList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional float InitWidth, 
										  optional float InitHeight, 
										  optional float InitLeftPadding = 14, 
										  optional float InitRightPadding = 14,
                                          optional bool initAutoScroll = true)  
{
	InitPanel(InitName, InitLibID);
	
	bAutoScroll = initAutoScroll; 

	CreateTextContainer();
	
	SetPosition(InitX, InitY);
    SetSize(initWidth, initHeight);
	
	PADDING_LEFT = InitLeftPadding;
	PADDING_RIGHT = InitRightPadding;

	return self; 
}

simulated function CreateTextContainer()
{
	textcontainer = Spawn(class'UIPanel', self);
	textcontainer.bAnimateOnInit = false;
	textcontainer.bCascadeFocus = false;
	textcontainer.bIsNavigable = false;
	textcontainer.InitPanel('Listtextcontainer');

	// HAX: items are contained within textcontainer, so our Navigator must reference the container's Navigator
	Navigator = textcontainer.Navigator.InitNavigator(self); // set owner to be self;

	// Remove the container so its not part of the navigation cycle
	Navigator.RemoveControl(textcontainer);

	// text starts off hidden, show after text sizing information is obtained
	textcontainer.Hide();
}

////////////////////////////////////////////////
//  REFRESH - UPDATE DATA
////////////////////////////////////////////////

simulated function RefreshData(array<UISummary_DSL_Legend> Stats)
{
	local TUIStatList_DSL_Legend Item;
	local int i, ActualLineHeight;
	local UITextStyleObject LabelStyle; //EUIUtilities_TextStyle

	ActualLineHeight = Screen.bIsIn3D ? LineHeight3D : LineHeight;

	// Issue #235 start - trims list for incorrect values
	// class'CHHelpers'.static.GroupItemStatsByLabel(Stats);
	// Issue #235 end

	for( i = 0; i < Stats.Length; i++ )
	{
		// Place new items if we need to. Place items into textcontainer for scrolling
		if( i > Items.Length-1 )
		{
			Item.ID = i; 

			//Alternating lines shaded background
			Item.BG = Spawn(class'UIPanel', textcontainer);
			Item.BG.bAnimateOnInit = false;
            Item.BG.InitPanel(Name("BGShading"$i), class'UIUtilities_Controls'.const.MC_X2BackgroundShading);
			Item.BG.SetPosition(0, (i * ActualLineHeight) + 3);
			Item.BG.SetSize(width, ActualLineHeight);

			//left side Icon
            Item.Icon = Spawn(class'UIIcon', textcontainer);
            Item.Icon.bAnimateOnInit = false;
            Item.Icon.bDisableSelectionBrackets = true;

            Item.Icon.InitIcon(Name("Icon"$i),,false, true);
            Item.Icon.SetSize(IconSize, IconSize);
            Item.Icon.SetPosition(PADDING_LEFT, (i * ActualLineHeight) + 2 );

			//right side scrolling text .. note NO setheight or setsize, only width
			Item.Label = Spawn(class'UIScrollingText', textcontainer);
			Item.Label.bAnimateOnInit = false;
            Item.Label.InitScrollingText(Name("Label"$i), "", width - PADDING_RIGHT - PADDING_LEFT, PADDING_RIGHT, (i * ActualLineHeight) + 2); //name, text, w, x, y

			Items.AddItem(Item);
		}
		
		// Grab our target item
		Item = Items[i]; 

		//update label and text colour
		LabelStyle = class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_StatLabel, Screen.bIsIn3D); // Stats[i].LabelStyle
		LabelStyle.iState = Stats[i].LabelState;
		Item.Label.SetX(VALUE_COL_SIZE + PADDING_LEFT);
		Item.Label.SetWidth( width - PADDING_RIGHT - PADDING_LEFT - VALUE_COL_SIZE );
		Item.Label.SetHTMLText( class'UIUtilities_Text'.static.StyleTextCustom(Stats[i].Label, LabelStyle));
		Item.Label.Show();

		//update the icon
        if (Stats[i].IconPath != "")
        {
            if (Stats[i].IconBGColor != "")
            {
                Item.Icon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
                Item.Icon.SetBGColor( Stats[i].IconBGColor );
	            Item.Icon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $Stats[i].IconPath $"_bg"));
            }
			else
			{
				Item.Icon.HideBG();
			}

			if (Stats[i].IconSize != IconSize)
			{
	            Item.Icon.SetSize(Stats[i].IconSize, Stats[i].IconSize);
			}

			if (Stats[i].IconOffsetX != 0 || Stats[i].IconOffsetY != 0 )
			{
				Item.Icon.SetPosition(Item.Icon.X + Stats[i].IconOffsetX, Item.Icon.Y + Stats[i].IconOffsetY);
			}
			
            Item.Icon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath("img:///" $Stats[i].IconPath));
            Item.Icon.Show();
        }
		else
		{
			Item.Label.SetX((VALUE_COL_SIZE * 0.5) );
			Item.Icon.Hide();
		}

		//Alternating lines have shaded background
		if( i % 2 == 0 ) { Item.BG.Show(); }
		else 			 { Item.BG.Hide(); }
	}

	// Hide any excess list items if we didn't use them. 
	for( i = Stats.Length; i < Items.Length; i++ )
	{
		Item = Items[i];
		Item.Label.Hide();
        Item.Icon.Hide();
		Item.BG.Hide();
	}

	//set container height to full stats list height
	textcontainer.Height = Stats.Length * ActualLineHeight;

	//adjust for bounds of 'stat list' height and add autoscroll or scrollbar as needed
    RealizeListBounds();

	if(OnSizeRealized != None)
    {
		OnSizeRealized();
    }
}

////////////////////////////////////////////////
//  SIZE CONTROLS
////////////////////////////////////////////////

// Sizing this control really means sizing its mask
simulated function SetWidth(float newWidth)
{
	if(width != newWidth)
	{
		width = newWidth;
		textcontainer.SetWidth(newWidth);

		if(mask != none)
		{
			mask.SetWidth(width);

			if (scrollbar != none)
			{
				scrollbar.SnapToControl(mask);
			}
		}
	}
}

// This also is changed
simulated function SetHeight(float newHeight)
{
	if(height != newHeight)
	{
		height = newHeight;
		//textcontainer.SetHeight(newHeight); // NO!

		if(mask != none)
		{
			mask.SetHeight(height);

			if (scrollbar != none)
			{
				scrollbar.SnapToControl(mask);
			}
		}
	}
}

simulated function UIPanel SetSize(float newWidth, float newHeight)
{
	SetWidth(newWidth);
	SetHeight(newHeight);
	return self;
}

////////////////////////////////////////////////
//  AUTO SIZE FOR MASKING SCROLLING
////////////////////////////////////////////////

simulated function RealizeListBounds()
{
	//reset current scroll
	textcontainer.ClearScroll();

	//if list height is bigger than desired height, add mask and autoscroll/scrollbar
	if(textcontainer.Height > height)
	{
		if(mask == none)
		{
			mask = Spawn(class'UIMask', self).InitMask();
		}

		mask.SetMask(textcontainer);
		mask.SetSize(width, height);

		if( bAutoScroll )
		{
			textcontainer.AnimateScroll( textcontainer.Height, height);
		}
		else
		{
			if(scrollbar == none)
			{
				scrollbar = Spawn(class'UIScrollbar', self).InitScrollbar();
			}
			scrollbar.SnapToControl(mask, -scrollbarPadding);
			//scrollbar.NotifyPercentChange(textcontainer.SetScroll); //<> TODO: UIPanel does not have this functionality, but UIText does!!
		}
	}
	else if(mask != none)
	{
		mask.Remove();
		mask = none;

		if(scrollbar != none)
		{
			scrollbar.Remove();
			scrollbar = none;
		}
	}

	textcontainer.SetWidth(width);
	textcontainer.Show();
}

////////////////////////////////////////////////
//  ALLOW FOR SCROLLBAR -MANUAL SCROLLING BUST-
////////////////////////////////////////////////

simulated function OnChildMouseEvent( UIPanel control, int cmd )
{
	if(scrollbar != none && cmd == class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP)
    {
		scrollbar.OnMouseScrollEvent(-1);
    }
	else if(scrollbar != none && cmd == class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN)
    {
		scrollbar.OnMouseScrollEvent(1);
    }
}

/*simulated function SetScroll(float percent)
{
	if(ScrollPercent != percent)
	{
		ScrollPercent = percent;
		mc.FunctionNum("setScrollPercent", percent);
	}
}*/

////////////////////////////////////////////////
//  DEFAULT PROPERTIES
///////////////////////////////////////////////

defaultproperties
{
	//LibID = 'TextControl';
	//ScrollPercent = 0;

	LineHeight = 26.0; 
	LineHeight3D = 26.0; 

	PADDING_LEFT	= 5.0;
	PADDING_RIGHT	= 5.0;
	VALUE_COL_SIZE	= 32;
	IconSize = 22;

	bIsNavigable = false;
	scrollbarPadding = 10;
}
