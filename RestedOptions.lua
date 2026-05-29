RESTED_SLUG, Rested  = ...

function Rested.OptionsPanel_OnLoad(panel)
	panel.name = "Rested"
	RestedOptionsFrame_Title:SetText(RESTED_MSG_ADDONNAME.." v"..RESTED_MSG_VERSION)

	panel.OnCommit = Rested.OptionsPanel_OKAY
	panel.OnDefault = function() end
	panel.OnRefresh = Rested.OptionsPanel_Refresh

	-- Register Options frame
	local category, layout = Settings.RegisterCanvasLayoutCategory( panel, panel.name )
	panel.category = category
	Settings.RegisterAddOnCategory(category)
end
function Rested.OptionsPanel_Reset()
	-- Called from Addon_Loaded
end
function Rested.OptionsPanel_OKAY()
	-- Data was recorded, clear the temp
	-- this is now the 'close' button
end

function Rested.OptionsPanel_Refresh()
	-- Called when options panel is opened.
end

-------------

function Rested.OptionsPanel_CheckButton_OnShow( self, option, text )
	getglobal(self:GetName().."Text"):SetText(text);
	self:SetChecked(Rested_options[option]);
end
function Rested.OptionsPanel_CheckButton_OnClick( self, option )
	Rested_options[option] = self:GetChecked()
end
function Rested.OptionsPanel_RadioButton_OnClick( self, otherRadioButtons ) --"nagIncludeToEndOfLevel",[RestedOptionsFrame_IncludeOverPercent])
	Rested_options[self:GetAttribute("var")] = true
	for _, f in ipairs(otherRadioButtons) do
		f:SetChecked(false)
		Rested_options[f:GetAttribute("var")] = nil
	end
end
function Rested.OptionsPanel_DurationEditBox_Onload( self, option, text )
	self:SetText(Rested.SecondsToText(Rested_options[option]))
end
function Rested.OptionsPanel_DurationEditBox_OnEditFocusLost( self, option )
	Rested_options[option] = Rested.TextToSeconds( self:GetText() )
	if option == "nagStart" and Rested_options.nagStart > Rested_options.staleStart then
		Rested_options.nagStart = Rested_options.staleStart
	end
	if option == "staleStart" and Rested_options.staleStart < Rested_options.nagStart then
		Rested_options.staleStart = Rested_options.nagStart
	end
	self:SetText(Rested.SecondsToText(Rested_options[option]))
end

function Rested.OptionsPanel_EditBox_OnShow( self, option )
	self:SetText( tostring( Rested_options[option] ) )
	self:SetCursorPosition(0)
end
function Rested.OptionsPanel_EditBox_OnEditFocusLost( self, option )
	Rested_options[option] = tonumber( self:GetText() ) or 0
	if option == "nagIncludeOverPercentValue" and Rested_options[option] > 150 then
		Rested_options[option] = 150
	end
	self:SetText( tostring( Rested_options[option] ) )
end

-------------

function Rested.OptionsPanel_Init()
	if Rested_options.nagIncludeOverPercentValue == nil then
		Rested_options.nagIncludeOverPercentValue = 75
		Rested_options.nagEnabled = true
		Rested_options.nagIncludeLeveling = true
		Rested_options.nagIncludeToEndOfLevel = true
		Rested_options.nagIncludeOverPercent = nil
		Rested_options.nagIncludeMaxLevel = true
	end
end
Rested.InitCallback( Rested.OptionsPanel_Init )
Rested.commandList["options"] = {
		["help"] = {"","Open the options panel"},
		["func"] = function() Settings.OpenToCategory( RestedOptionsFrame.category:GetID() ) end,
}
