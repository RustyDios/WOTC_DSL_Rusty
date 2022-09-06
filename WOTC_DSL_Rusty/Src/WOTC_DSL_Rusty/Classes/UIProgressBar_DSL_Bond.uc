//----------------------------------------------------------------------------
//  FILE:    UIProgressBar.uc  AUTHOR:  Brit Steiner   RustyDios
//
//  CREATED 06/07/22    11:00  UPDATED 17/07/22	21:00
//
//  PURPOSE: Simple progress bar that displays percentage, with vertical option
//----------------------------------------------------------------------------

class UIProgressBar_DSL_Bond extends UIPanel;

var string BGColor, FillColor;
var bool IsHighlighted, bIsVertical;
var public bool bHighlightOnMouseEvent;

var UIPanel BGBar, FillBar;
var float Percent; 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  INIT PANEL
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UIProgressBar_DSL_Bond InitProgressBar(	optional name InitName,
															optional float InitX, 
															optional float InitY, 
															optional float InitWidth, 
															optional float InitHeight, 
															optional float InitPercentFilled,
															optional EUIState InitFillColorState = eUIState_Normal,
															optional bool InitVertical )
{
	InitPanel(InitName);
	SetPosition(InitX, InitY);

	BGBar = Spawn(class'UIPanel', self);
	BGBar.bAnimateOnInit = false;																//class'UIUtilities_Controls'.const.MC_X2BackgroundShading);
	BGBar.InitPanel('BGBoxSimpleBG', class'UIUtilities_Controls'.const.MC_GenericPixel); 		//class'UIUtilities_Controls'.const.MC_X2BackgroundSimple); 
	BGBar.SetSize(InitWidth, InitHeight); 
	BGBar.SetColor(class'UIUtilities_Colors'.const.FADED_HTML_COLOR); 

	FillBar = Spawn(class'UIPanel', self);
	FillBar.bAnimateOnInit = false;																//class'UIUtilities_Controls'.const.MC_X2BackgroundShading);
	FillBar.InitPanel('BGBoxSimpleFill', class'UIUtilities_Controls'.const.MC_GenericPixel); 	//class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	FillBar.SetSize(InitWidth, InitHeight);
	//FillBar.SetPosition(0, 0); //TODO: may need to adjust the bar once we finalize visuals. 
	
	SetColorState(InitFillColorState);

	Percent = InitPercentFilled;
    bIsVertical = InitVertical;

	SetSize(InitWidth, InitHeight);
	//SetPercent(InitPercentFilled); //Called in SetSize now so it updates if size updates

	return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  RESIZE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	if (Width != NewWidth || Height != NewHeight)
	{
		Width = NewWidth;
		Height = NewHeight;

		BGBar.SetSize(Width, Height);
		FillBar.SetSize(Width, Height);
	}

	SetPercent(Percent);

	return self; 
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  SET COLOURS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UIPanel SetColor(string ColorLabel)
{
	FillBar.SetColor(ColorLabel);
	return self;
}

simulated function UIProgressBar_DSL_Bond SetColorState(EUIState ColorState)
{
	SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(ColorState));
	return self;
}

simulated function UIProgressBar_DSL_Bond SetBGColor(string ColorLabel)
{
	BGBar.SetColor(ColorLabel);
	return self;
}

simulated function UIProgressBar_DSL_Bond SetBGColorState(EUIState ColorState)
{
	SetBGColor(class'UIUtilities_Colors'.static.GetColorLabelFromState(ColorState));
	return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  SET PERCENT     // Percent as value 0.00 to 1.00
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function SetPercent(float DisplayPercent)
{
	//ensure stored percent and new displayed percent match up
	if (Percent != DisplayPercent)
	{
		Percent = DisplayPercent;
	}

    //auto-convert display percent to a float between 0.01 and 1.00, cap percent at 100%
    if (DisplayPercent > 1.0 && DisplayPercent <= 100.0)
    {
		`LOG("Warning: You've set bar value at [" $ DisplayPercent $"%], higher than 1.0, Auto converted for now, but you should fix this.",, 'UIProgressBar_DSL_Bond');
        DisplayPercent = DisplayPercent * 0.01;
    }
    else if (DisplayPercent > 100.0)
    {
		`LOG("Warning: You've set bar value at [" $ DisplayPercent $"%], higher than 100.0, Auto converted for now, capped at 100%, but you should fix this.",, 'UIProgressBar_DSL_Bond');
        DisplayPercent = 1.00;
    }

    //Hide bar if not required and return, no point in doing anything else
	if (DisplayPercent <= 0.01)
	{
		FillBar.Hide();
		return;
	}

    //set vertical or horizontal
    if (bIsVertical)
    {
        if (DisplayPercent >= 1.0)
		{
			FillBar.SetSize(Width, Height);
		}
        else
		{
			FillBar.SetSize(Width, Height * DisplayPercent);
		}

		//shift fillbar down so it looks like it's filling upwards 
		FillBar.SetPosition(BGBar.X, BGBar.Y + (BGBar.Height - FillBar.Height));

        if (FillBar.Height > 1) { FillBar.Show(); }
    }
    else
    {
        if (DisplayPercent >= 1.0)
		{
			FillBar.SetSize(Width, Height);
		}
        else
		{
			FillBar.SetSize(Width * DisplayPercent, Height);
		}
        
		//Fillbar will fill left to right
        if (FillBar.Width > 1) { FillBar.Show(); }
    }

	//change colour if full
	if (DisplayPercent >= 1.00)
	{
		SetColor("FEF4CB"); // Perk / Promotion Yellow
	}
	else
	{
		SetColor("9ACBCB"); // Cyan
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  HIGHLIGHT & SCREEN MANIPULATIONS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UIProgressBar_DSL_Bond SetHighlighted(bool Highlight)
{
	local int Index;
	local string NewColor;

	if(IsHighlighted != Highlight)
	{
		IsHighlighted = Highlight;

		Index = InStr(BGColor, "_highlight");

		if( IsHighlighted && Index == INDEX_NONE )
        {
			NewColor = BGColor $ "_highlight";
        }
		else if( Index != INDEX_NONE )
        {
			NewColor = Left(BGColor, Index);
        }

		SetBGColor(NewColor);
	}

	return self;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	// HAX: Controls in lists don't handle their own focus changes
	if( GetParent(class'UIList') != none ) return;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			OnReceiveFocus();
			if(bHighlightOnMouseEvent) { SetHighlighted(true); }
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			OnLoseFocus();
			if(bHighlightOnMouseEvent) { SetHighlighted(false); }
			break;
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  DEFAULT PROPERTIES
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bIsNavigable = false;
	bProcessesMouseEvents = false;
	bHighlightOnMouseEvent = false;
}
