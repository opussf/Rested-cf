-- RestedQuests.lua

function Rested.QuestCommand( strIn, retryCount )
	if strIn and strIn ~= '' then
		if strIn == "clear" then
			Rested.me.quests = nil
		else
			qcount = 0
			for qnum in string.gmatch( strIn, "([0-9]+)[,]*" ) do
				-- Rested.Print( "Checking quest: "..qnum )
				title = C_QuestLog.GetTitleForQuestID( qnum )
				completed = C_QuestLog.IsQuestFlaggedCompleted( qnum )
				onquest = C_QuestLog.IsOnQuest( qnum )
				Rested.me.quests = Rested.me.quests or {}
				Rested.me.quests[qnum] = {
						["title"] = title or "Unknown Name",
						["completed"] = completed,
						["onquest"] = onquest,
						["addedTS"] = time() + qcount,
						["completedTS"] = ( completed and time() or nil ),
					}
				qcount = qcount + 1
				if not title and (not retryCount or retryCount <= 5) then
					-- Rested.Print( "Retrying questID: "..qnum )
					C_Timer.After( 1, function() Rested.QuestCommand( qnum, (retryCount and retryCount + 1 or 1) ) end )
				end
			end
		end
	end
	Rested.reportName = "Quests"
	Rested.UIShowReport( Rested.QuestReport )
end
function Rested.QuestReport( realm, name, charStruct )
	count = 0
	if Rested.realm == realm and Rested.name == name and charStruct.quests then
		for qnum, qinfo in pairs( charStruct.quests ) do
			if qinfo.completed and qinfo.completedTS < time() - 160 then
				charStruct.quests[qnum] = nil
			else
				table.insert( Rested.charList, { time() - (qinfo.completed and qinfo.completedTS or qinfo.addedTS),
						string.format( "%6i: %s :: %s",
							qnum, (qinfo.completed and "COMPLETE" or (qinfo.onquest and "in progress" or "future")), qinfo.title ) } )
				count = count + 1
			end
		end
	end
	return count
end
function Rested.QuestUpdate()
	if Rested.me.quests then
		questCount = 0
		for qnum, qinfo in pairs( Rested.me.quests ) do
			questCount = questCount + 1
			if not qinfo.completed and C_QuestLog.IsQuestFlaggedCompleted( qnum ) then
				Rested.me.quests[qnum].completed = true
				Rested.me.quests[qnum].completedTS = time()
			elseif not qinfo.onquest and C_QuestLog.IsOnQuest( qnum ) then
				Rested.me.quests[qnum].onquest = true
				Rested.me.quests[qnum].addedTS = time()
			elseif qinfo.completed and qinfo.completedTS < time() - 160 then  -- completd more than 5 minutes ago.
				Rested.me.quests[qnum] = nil
			end
		end
		if questCount == 0 then
			Rested.me.quests = nil
		end
	end
end
function Rested.QuestRemoved( questID, flag )
	questID = tostring(questID)
	-- Event payload is questID, and a boolean flag
	if Rested.me.quests and Rested.me.quests[questID] then
		Rested.me.quests[questID].completed = true   -- make an abandoned flag?
		Rested.me.quests[questID].completedTS = time()
	end
end

Rested.dropDownMenuTable["Quests"] = "quests"
Rested.commandList["quests"] = { ["help"] = {"[clear|questnum,...]","Track quests by quest numbers"}, ["func"] = Rested.QuestCommand }
Rested.reportReverseSort["Quests"] = true
Rested.EventCallback( "QUEST_LOG_UPDATE", Rested.QuestUpdate )
-- Rested.EventCallback( "QUEST_ACCEPTED", Rested.QuestCommand )
Rested.EventCallback( "QUEST_REMOVED", Rested.QuestRemoved )

-- storylines
function Rested.QuestStoryline( strIn )
	if strIn and strIn ~= '' then
		for slnum in string.gmatch( strIn, "([0-9]+)[,]*" ) do
			local questNums = C_QuestLine.GetQuestLineQuests( slnum )
			Rested.QuestCommand( table.concat( questNums, "," ) )
		end
	end
end
Rested.commandList["storylines"] = { ["help"] = {"[storyline,...]","Track quests in a storyline"}, ["func"] = Rested.QuestStoryline }


--[[

/rested quests 84967,86835,84965,84964,84963,84961,84960,84959,84958,85039,85003,84957,84956
/rested quests 84826,84827,84831,85730,86327,84834,84869,84838,84848,84867,86332,84876,84879,84883,84910
/rested quests 90517,86946,84866,84865,84864,84863,84862,84861,84860,84859,84858,84857,84856,86495,84855,85961,85032
/rested quests 85037,84906,84905,84904,84903,84902,84900,84899,84898,84897,
/rested quests 86820

/rested storylines 5690,5717,5696,5734,5733,5780


C_QuestLog.IsOnQuest(questID)
C_QuestLog.IsComplete(questID)



local questLines = C_QuestLine.GetAvailableQuestLines(uiMapID)
for _, ql in ipairs(questLines) do
    print(ql.questLineName, ql.questLineID)
end

each ql:
{
    questLineName = string,
    questLineID = number,
    questID = number,       -- first quest in the line
    isCampaign = boolean,
    isHidden = boolean
}

local uiMapID = 84 -- Stormwind City
local questLines = C_QuestLine.GetAvailableQuestLines(uiMapID)

for _, ql in ipairs(questLines) do
    print("Storyline:", ql.questLineName)
    local quests = C_QuestLine.GetQuestLineQuests(ql.questLineID, uiMapID)
    for _, quest in ipairs(quests) do
        print(" -", quest.questName, "(ID:", quest.questID .. ")")
    end
end

----------------------------

C_CampaignInfo.GetCampaignChapterInfo(campaignChapterID)
C_CampaignInfo.GetCampaignID(questID)


C_QuestLine.GetQuestLineQuests(questLineID)
C_QuestLine.IsComplete(questLineID)

C_QuestLine.GetQuestLineQuests(5690)















]]
