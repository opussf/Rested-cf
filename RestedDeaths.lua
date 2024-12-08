-- RestedDeaths.lua
function Rested.SaveDeaths()
	-- update death count
	Rested_restedState[Rested.realm][Rested.name].deaths = tonumber( GetStatistic( 60 ) or 0 )  -- 60 is number of deaths

	Rested_misc["maxDeaths"] = math.max( Rested_misc["maxDeaths"] or 0,
			Rested_restedState[Rested.realm][Rested.name].deaths or 0 )
end

Rested.InitCallback( Rested.SaveDeaths )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveDeaths )

Rested.dropDownMenuTable["Deaths"] = "deaths"
Rested.commandList["deaths"] = {["help"] = {"","Show number of deaths"}, ["func"] = function()
		Rested.reportName = "Deaths"
		Rested.UIShowReport( Rested.DeathReport )
	end
}
function Rested.DeathReport( realm, name, charStruct )
	-- lvl
	local rn = Rested.FormatName( realm, name )
	Rested_misc["maxDeaths"] = math.max( Rested_misc["maxDeaths"] or 0, charStruct.deaths or 0 )
	Rested.strOut = string.format( "%s :: %s",
			charStruct.deaths or "Unscanned",
			rn )
	table.insert( Rested.charList, {((charStruct.deaths or -1) / Rested_misc["maxDeaths"]) * 150, Rested.strOut} );
	return 1
end
