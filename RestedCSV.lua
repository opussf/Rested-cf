-- RestedCSV.lua

Rested.CSVFields = {
	{"Faction", "faction"},
	{"Race", "race"},
	{"Class", "class"},
	{"Gender", "gender"},
	{"Level", "lvlNow"},
	{"iLvl", "iLvl"},
	{"Copper","gold"},
	{"Prof1","prof1"},
	{"Prof2","prof2"},
	{"Prof3","prof3"},
	{"Prof4","prof4"},
	{"Prof5","prof5"},
}
function Rested.MakeCSV()
	local report = {}
	local row = {"Realm","Name"}
	for _, fieldStruct in ipairs( Rested.CSVFields ) do
		table.insert( row, fieldStruct[1] )
	end
	table.insert( report, table.concat( row, "," ) )

	for realm, chars in Rested.SortedPairs( Rested_restedState ) do
		for name, charStruct in Rested.SortedPairs( chars ) do
			row = {realm, name}
			for _, fieldStruct in ipairs( Rested.CSVFields ) do
				table.insert( row, (charStruct[fieldStruct[2]] or "") )
			end
			table.insert( report, table.concat( row, "," ) )
		end
	end
	Rested_csv = table.concat( report, "\n" ).."\n"
	RestedCSV_EditBox:SetText( Rested_csv )
	RestedCSV_EditBox:HighlightText()
	RestedCSV:Show()
	C_Timer.After(15, function() RestedCSV:Hide(); end)
	Rested.Print("CSV report created. Ctrl-C to copy CSV content to the clipboard.")
end

Rested.EventCallback( "PLAYER_ENTERING_WORLD", function() Rested_csv=nil; end )
Rested.commandList["csv"] = {["help"] = {"","Make CSV export"}, ["func"] = Rested.MakeCSV }
