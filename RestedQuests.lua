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
				if title then
					Rested.me.quests = Rested.me.quests or {}
					Rested.me.quests[qnum] = {
						["title"] = title,
						["completed"] = completed,
						["addedTS"] = time() + qcount,
						["completedTS"] = ( completed and time() or nil ),
					}
					qcount = qcount + 1

					Rested.Print( qnum..":"..title..":"..(completed and "DONE" or "Available") )
				elseif not retryCount or retryCount <= 5 then
					Rested.Print( "Retrying questID: "..qnum )
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
							qnum, (qinfo.completed and "COMPLETE" or "progress"), qinfo.title ) } )
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
