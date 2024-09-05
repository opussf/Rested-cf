-- RestedCSV.lua

function Rested.MakeCSV()
	strOut = "Realm,Name,Faction,Race,Class,Gender,Level,iLvl\n"
	for realm, chars in Rested.SortedPairs( Rested_restedState ) do
		for name, charStruct in Rested.SortedPairs( chars ) do
			strOut = strOut .. string.format( "%s,%s,%s,%s,%s,%s,%i,%i\n",
				realm, name, charStruct.faction, charStruct.race, charStruct.class,
				charStruct.gender, charStruct.lvlNow, (charStruct.iLvl or "") )
		end
	end
	Rested_csv = strOut
	RestedCSV_EditBox:SetText( Rested_csv )
	RestedCSV_EditBox:HighlightText()
	RestedCSV:Show()
	C_Timer.After(15, function() RestedCSV:Hide(); end)
	Rested.Print("CSV report created. Ctrl-C to copy CSV content to the clipboard.")
end

Rested.EventCallback( "PLAYER_ENTERING_WORLD", function() Rested_csv=nil; end )
Rested.commandList["csv"] = {["help"] = {"","Make CSV export"}, ["func"] = Rested.MakeCSV }
