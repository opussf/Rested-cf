-- RestedCaches.lua
-----------------------------------------
-- Track WarWithIn Caches

Rested.cacheQuests = {84736,84737,84738,84739}
function Rested.GetCompletedCaches()
	local count = 0
	for _,qnum in ipairs( Rested.cacheQuests ) do
		count = count + (C_QuestLog.IsQuestFlaggedCompleted(qnum) and 1 or 0)
	end
	if count > 0 and (not Rested.me.weeklyCacheCount or count ~= Rested.me.weeklyCacheCount) then
		Rested.me.weeklyCacheCount = count
		Rested.me.weeklyCacheTS = time()
	end
end
function Rested.ResetCaches( realm, name, charStruct )
	if charStruct.weeklyCacheTS and charStruct.weeklyCacheTS <= Rested.previousWeekReset then
		charStruct.weeklyCacheTS = nil
		charStruct.weeklyCacheCount = nil
	end
end
function Rested.CachesReport( realm, name, charStruct )
	if charStruct.weeklyCacheCount then
		table.insert( Rested.charList, { (charStruct.weeklyCacheCount / #Rested.cacheQuests) * 150 ,
			string.format( "%i :: %s", charStruct.weeklyCacheCount, Rested.FormatName( realm, name ) )
		} )
		return 1
	end
end

Rested.reportReverseSort["Caches"] = true
Rested.dropDownMenuTable["Caches"] = "caches"
Rested.commandList["caches"] = { ["help"] = {"","Caches opened."}, ["func"] = function()
		Rested.reportName = "Caches"
		Rested.UIShowReport( Rested.CachesReport )
	end
}
Rested.EventCallback( "QUEST_LOG_UPDATE", Rested.GetCompletedCaches )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.GetCompletedCaches )

Rested.InitCallback( function()
		C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
		WeeklyRewardsFrame:Show()
		_, Rested.previousWeekReset = Rested.GetWeeklyQuestResetTime()
		Rested.ForAllChars( Rested.ResetCaches, true )
		WeeklyRewardsFrame:Hide()
	end
)

-- Special thanks to whomever identified the quests, and wrote an amazing macro for this.
