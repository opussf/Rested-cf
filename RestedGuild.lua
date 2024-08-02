--=================
-- Guild Info
--=================
table.insert( Rested.filterKeys, "guildName" )
function Rested.SaveGuildInfo( ... )
	--Rested.Print("PLAYER_GUILD_UPDATE")
	local gName, gRankName, gRankIndex = GetGuildInfo("player")
	Rested_restedState[Rested.realm][Rested.name].guildName = gName or nil
	Rested_restedState[Rested.realm][Rested.name].guildRank = gName and gRankName or nil
	Rested_restedState[Rested.realm][Rested.name].guildRankIndex = gName and gRankIndex or nil
	local rep, bottom, top, reaction = Rested.GetGuildRep()
	bottom = 0
	--rep = rep - bottom; top = top - bottom; bottom = 0
	Rested_restedState[Rested.realm][Rested.name].guildRep = gName and rep or nil
	Rested_restedState[Rested.realm][Rested.name].guildBottom = gName and bottom or nil
	Rested_restedState[Rested.realm][Rested.name].guildTop = gName and top or nil
	--Rested.Print(string.format("%s :: %i - %i - %i", gName or "None", bottom, rep, top))
end
function Rested.GetGuildRep( )
	-- C_Reputation.GetGuildFactionData
	factionData = C_Reputation.GetGuildFactionData()
	if factionData and factionData.name == Rested_restedState[Rested.realm][Rested.name].guildName then
		-- Rested.Print("Guild FactionData: "..factionData.name..":"..factionData.reaction..":"..factionData.currentStanding )
		return factionData.currentStanding, factionData.currentReationThreshold, factionData.nextReactionThreshold, factionData.reaction
	end
end

Rested.EventCallback( "PLAYER_GUILD_UPDATE", Rested.SaveGuildInfo )

Rested.dropDownMenuTable["Guild"] = "guild"
Rested.commandList["guild"] = {["help"] = {"","Show guild standing"}, ["func"] = function()
		Rested.reportName = "Guild Standing"
		Rested.UIShowReport( Rested.GuildStandingReport )
	end
}
function Rested.GuildStandingReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	local lineCount = 0
	if charStruct.guildName then
		lineCount = 1
		Rested.strOut = string.format( "%s :%s: %s",
				charStruct.guildName,
				(charStruct.guildRankIndex and _G["FACTION_STANDING_LABEL"..charStruct.guildRankIndex] or ""),
				rn )
		table.insert( Rested.charList,
				{ ( ( charStruct.guildRep or 0 ) / ( ( ( charStruct.guildTop or 0 ) - ( charStruct.guildBottom or 0 ) ) + 1 ) ) * 150,
					Rested.strOut
				}
		)
	end
	return lineCount
end
