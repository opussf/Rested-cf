-- RestediLvl.lua

-- function
function Rested.GetILvl()
	Rested.lastiLvlScan = Rested.lastiLvlScan or time() + 5  -- give it a 5 second grace period at startup.
	if( Rested.lastiLvlScan+1 <= time() ) then
		Rested.lastiLvlScan = time()
		local currentiLvl = select( 2, GetAverageItemLevel() )
		Rested.me.iLvl = math.floor( currentiLvl or 0 )
		Rested_misc["maxiLvl"] = math.max( Rested_misc["maxiLvl"] or 0, math.floor( currentiLvl or 0 ) )
		-- print( "iLvl is now: "..currentiLvl )
	end
end

Rested.EventCallback( "PLAYER_EQUIPMENT_CHANGED", function() C_Timer.After( 1, Rested.GetILvl ) end )
Rested.EventCallback( "ZONE_CHANGED_NEW_AREA", Rested.GetILvl )

Rested.dropDownMenuTable["iLvl"] = "ilvl"
Rested.commandList["ilvl"] = { ["help"] = {"","Show iLvl report"}, ["func"] = function()
		Rested.reportName = "Item Level"
		Rested.UIShowReport( Rested.iLevelReport )
	end
}
function Rested.iLevelReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	Rested_misc["maxiLvl"] = math.max( Rested_misc["maxiLvl"] or 0, math.floor( charStruct.iLvl or 0 ) )
	Rested.strOut = string.format( "%d :: %d :: %s",
			charStruct.iLvl or 0,
			charStruct.lvlNow,
			rn )
	table.insert( Rested.charList, {((charStruct.iLvl or 0) / Rested_misc["maxiLvl"]) * 150, Rested.strOut} )
	return 1
end
