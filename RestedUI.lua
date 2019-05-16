-- RestedUI.lua
Rested.showNumBars = 6
Rested.displayList = {}
Rested.charList = {}
-- Rested.displayList = { { displayValue (% of 100), "display text" }, {value, 'text'}, ... }

--  UI Handling code
---------------------------------
function Rested.UIBuildBars()
	if( not Rested.bars ) then
		Rested.bars = {}
		for idx = 1, Rested.showNumBars do
			Rested.bars[idx] = {}
			local item = CreateFrame("StatusBar", "Rested_ItemBar"..idx, RestedScrollContents, "Rested_RestedBarTemplate")
			Rested.bars[idx].bar = item
			if idx == 1 then
				item:SetPoint("TOPLEFT", "RestedScrollFrame", "TOPLEFT", 5, -5)
			else
				item:SetPoint("TOPLEFT", Rested.bars[idx-1].bar, "BOTTOMLEFT", 0, 0)
			end
			item:SetMinMaxValues(0, 150)
			item:SetValue(0)
			--item:SetScript("OnClick", Rested.BarClick);
			local text = item:CreateFontString("Rested_ItemText"..idx, "OVERLAY", "Rested_RestedBarTextTemplate")
			Rested.bars[idx].text = text
			text:SetPoint("TOPLEFT", item, "TOPLEFT", 5, 0)
		end
		print( "Bars built" )
	end
end
Rested.InitCallback( Rested.UIBuildBars )

function Rested.UIOnDragStart()
	RestedUIFrame:StartMoving()
end
function Rested.UIOnDragStop()
	RestedUIFrame:StopMovingOrSizing()
end
function Rested.UIResetFrame()
	for i = 1, Rested.showNumBars do
		Rested.bars[i].bar:SetValue(0)
		Rested.bars[i].text:SetText("")
		Rested.bars[i].bar:Hide()
	end
end
function Rested.UIUpdateFrame()
	if( RestedUIFrame:IsVisible() and Rested.reportFunction ) then  -- a non-set reportFunction will break this.
		count = Rested.ForAllChars( Rested.reportFunction, ( Rested.reportName == "Ignored" ) )
		RestedUIFrame_TitleText:SetText( "Rested - "..Rested.reportName.." - "..count )
		RestedScrollFrame_VSlider:SetMinMaxValues( 0, max( 0, count-Rested.showNumBars ) )
		if count > 0 then
			table.sort( Rested.charList, function( a, b ) return( a[1] > b[1] ); end )
			offset = math.floor( RestedScrollFrame_VSlider:GetValue() )
			for i = 1, Rested.showNumBars do
				idx = i + offset
				if idx <= count then
					Rested.bars[i].bar:SetValue( max( 0, Rested.charList[idx][1] ) ) -- sorted on value
					Rested.bars[i].text:SetText( Rested.charList[idx][2] )
					Rested.bars[i].bar:Show()
				else
					Rested.bars[i].bar:Hide()
				end
			end
		elseif( Rested.bars and count == 0 ) then
			for i = 1, Rested.showNumBars do
				Rested.bars[i].bar:Hide()
			end
		end
	end
end
function Rested.UIOnUpdate( arg1 )
	-- only gets called when the report frame is shown
	if( Rested.UIlastUpdate == nil ) or ( Rested.UIlastUpdate <= time() ) then
		Rested.UIlastUpdate = time() + 1 -- only update once a second
		Rested.UIUpdateFrame()
	end
end

function Rested.UIShowReport( reportFunction )
	-- use reportFunction to drive the report
	--print( "Rested.UIShowReport" )
	Rested.reportFunction = reportFunction
	RestedUIFrame:Show()
	Rested.UIResetFrame()

	Rested.UIUpdateFrame()
	UIDropDownMenu_SetText( RestedUIFrame.DropDownMenu, Rested.reportName )
end

-- DropDown code
function Rested.UIDropDownOnClick( self, cmd )
	--print( "Rested.UIDropDownOnClick( "..cmd.." )" )
	Rested.commandList[cmd].func()
end
function Rested.UIDropDownInitialize( self, level, menuList )
	-- This is called when the drop down is initialized, when it needs to build the choice box
	-- level and menuList are ignored here
	-- based on Rested.dropDownMenuTable["Full"] = "full"
	-- the Key is what to show, the value is what rested command to call
	-- using Rested.commandList["full"] = {["func"] = function() end }
	local info = UIDropDownMenu_CreateInfo()
	for text, cmd in pairs( Rested.dropDownMenuTable ) do
		info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.notCheckable = true
		info.arg1 = cmd
		info.func = Rested.UIDropDownOnClick

		UIDropDownMenu_AddButton( info, level )
	end
end
function Rested.UIDropDownOnLoad( self )
	UIDropDownMenu_Initialize( RestedUIFrame.DropDownMenu, Rested.UIDropDownInitialize ) -- displayMode, level, menuList
	UIDropDownMenu_JustifyText( RestedUIFrame.DropDownMenu, "LEFT" )
end

-- Filter Code
function Rested.updateFilter()
	if RestedEditBox:GetNumLetters() then
		Rested.filter = string.upper(RestedEditBox:GetText())
		Rested.UIUpdateFrame()
	else
		Rested.filter = nil
	end
end

-- Report Suport
--------------------------------------
