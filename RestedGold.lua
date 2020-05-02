-- RestedGold.lua

function Rested.SaveGold()
	Rested.me.gold = GetMoney() or 0
end

Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveGold )
Rested.EventCallback( "PLAYER_MONEY", Rested.SaveGold )

Rested.dropDownMenuTable["Gold"] = "gold"
Rested.commandList["gold"] = {["help"] = {"","Show gold"}, ["func"] = function()
		Rested.reportName = "Gold"
		Rested.UIShowReport( Rested.GoldReport )
	end
}
function Rested.GoldReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )

	local c = charStruct.gold or 0
	Rested.goldMax = math.max( Rested.goldMax or 1, c )
	local g = math.floor(c / 10000); c = c - ( g * 10000 )
	local s = math.floor(c / 100);   c = c - ( s * 100 )
	--print( rn.."::"..g.."::".. ( ( charStruct.gold and charStruct.gold or 0 ) / Rested.goldMax ) * 150 )

	Rested.strOut = string.format( "%sg %ss %sc :: %s",
			g, s, c, rn )
	table.insert( Rested.charList, { ( ( charStruct.gold and charStruct.gold or 0 ) / Rested.goldMax ) * 150, Rested.strOut } )
	return 1
end
