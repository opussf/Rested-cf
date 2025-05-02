-- RestedMythic.lua
RESTED_SLUG, Rested  = ...

-- Event CHALLENGE_MODE_MAPS_UPDATE

function Rested.StoreMythicInfo()
	Rested.me.mythic_currentSeasonScore = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player").currentSeasonScore
	local found = false
	for b = 0, 4 do
		for s = 1, C_Container.GetContainerNumSlots(b) do
			local itemId = C_Container.GetContainerItemID(b, s)
			if (itemId == 180653) then
				found = true
				local mythicInfo = {strsplit( ":", C_Container.GetContainerItemLink(b, s) )}
				local mythicPlusMapID
				for i,v in ipairs( mythicInfo) do
					if( v == "180653" ) then
						mythicPlusMapID = mythicInfo[i+1]
						break
					end
				end
				Rested.me.mythic_keyMapName = C_ChallengeMode.GetMapUIInfo( mythicPlusMapID )
				Rested.me.mythic_keyMapLevel = C_MythicPlus.GetOwnedKeystoneLevel()
			end
		end
	end
	if not found then
		Rested.me.mythic_keyMapName = nil
		Rested.me.mythic_keyMapLevel = nil
	end
	if Rested.me.mythic_currentSeasonScore == 0 and not Rested.me.mythic_keyMapName then
		Rested.me.mythic_currentSeasonScore = nil
	end
end

Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.StoreMythicInfo )
Rested.EventCallback( "CHALLENGE_MODE_COMPLETED", Rested.StoreMythicInfo )

function Rested.MythicReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	if charStruct.mythic_currentSeasonScore or charStruct.mythic_keyMapName then
		Rested.mythicScoreMax = math.max( Rested.mythicScoreMax or 1, charStruct.mythic_currentSeasonScore)
		table.insert( Rested.charList, { (charStruct.mythic_currentSeasonScore / Rested.mythicScoreMax ) * 150,
				string.format( "%s : %s :: %s",
					charStruct.mythic_currentSeasonScore, ( charStruct.mythic_keyMapLevel and charStruct.mythic_keyMapLevel.." - "..charStruct.mythic_keyMapName or "No Key" ),
					rn
				)
			}
		)
		return 1
	end
end

table.insert( Rested.filterKeys, "mythic_keyMapName" )

Rested.dropDownMenuTable["Mythic"] = "mythic"
Rested.commandList["mythic"] = {["help"] = {"", "Show Mythic key report"}, ["func"] = function()
		Rested.StoreMythicInfo()
		Rested.reportName = "Mythic"
		Rested.UIShowReport( Rested.MythicReport )
	end
}
