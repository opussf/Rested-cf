--=================
-- Guild Info
--=================
table.insert( Rested.filterKeys, "guildName" )
function Rested.SaveGuildInfo( ... )
	-- Rested.Print("PLAYER_GUILD_UPDATE")
	local gName, gRankName, gRankIndex = GetGuildInfo("player")
	Rested.me.guildName = gName or nil
	Rested.me.guildRank = gName and gRankName or nil
	Rested.me.guildRankIndex = gName and gRankIndex or nil  -- gRankIndex is the index of the rank

	local rep, bottom, top, reaction = Rested.GetGuildRep()
	bottom = 0
	--rep = rep - bottom; top = top - bottom; bottom = 0
	Rested.me.guildRep = gName and rep or nil
	Rested.me.guildBottom = gName and bottom or nil
	Rested.me.guildTop = gName and top or nil
	Rested.me.guildReaction= gName and reaction or nil  -- reaction is the FactionStandingLabel index.
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
		Rested.SaveGuildInfo()
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
				(charStruct.guildReaction and _G["FACTION_STANDING_LABEL"..charStruct.guildReaction] or ""),
				rn )
		table.insert( Rested.charList,
				{ ( ( charStruct.guildRep or 0 ) / ( ( ( charStruct.guildTop or 0 ) - ( charStruct.guildBottom or 0 ) ) + 1 ) ) * 150,
					Rested.strOut
				}
		)
	else
		lineCount = 1
		Rested.strOut = string.format( "No guild :: %s",
			rn )
		table.insert( Rested.charList, { 0, Rested.strOut } )
	end
	return lineCount
end
