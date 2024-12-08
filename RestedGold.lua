-- RestedGold.lua
function Rested.SaveGold()
	Rested.me.gold = GetMoney() or 0
	Rested.WBBGold = C_Bank.FetchDepositedMoney( Enum.BankType.Account )
end

Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveGold )
Rested.EventCallback( "PLAYER_MONEY", Rested.SaveGold )

Rested.dropDownMenuTable["Gold"] = "gold"
Rested.commandList["gold"] = {["help"] = {"","Show gold"}, ["func"] = function()
		Rested.reportName = "Gold"
		Rested.UIShowReport( Rested.GoldReport )
	end
}
function Rested.GoldSilverCopperFromCopper( copperIn )
	local c = copperIn or 0
	local g = math.floor(c / 10000); c = c - ( g * 10000 )
	local s = math.floor(c / 100);   c = c - ( s * 100 )
	return g, s, c
end
function Rested.GoldReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	local count = 1

	if( #Rested.charList == 0 ) then
		Rested.reportName = "Gold"
		g, s, c = Rested.GoldSilverCopperFromCopper( Rested.WBBGold or 0 )
		Rested.strOut = string.format( "%sg %ss %sc :: Warband Bank",
				g, s, c )
		table.insert( Rested.charList, { 151, Rested.strOut } )
		Rested.goldSum = Rested.WBBGold
		count = count + 1
	end

	local c = charStruct.gold or 0
	Rested.goldSum = ( Rested.goldSum or 0 ) + c
	Rested.goldMax = math.max( Rested.goldMax or 1, c )

	g, s, c = Rested.GoldSilverCopperFromCopper( c )
	--print( rn.."::"..g.."::".. ( ( charStruct.gold and charStruct.gold or 0 ) / Rested.goldMax ) * 150 )

	Rested.reportName = string.format( "Gold (%sG)", math.floor( Rested.goldSum / 10000 ) )

	Rested.strOut = string.format( "%sg %ss %sc :: %s",
			g, s, c, rn )
	table.insert( Rested.charList, { ( ( charStruct.gold and charStruct.gold or 0 ) / Rested.goldMax ) * 150, Rested.strOut } )
	return count
end
