-- RestedPandarianFarm.lua
RESTED_SLUG, Rested  = ...

Rested.FarmThings = {["Tilled Soil"] = true, ["Untilled Soil"] = true,
		["Occupied Soil"] = true, ["Encroaching Weed"] = true,
		["Swooping Plainshawk"] = true, ["Squatting Virmen"] = true, ["Voracious Virmen"] = true,
		["Stubborn Weed"] = true, ["Unstable Portal Shard"] = true, ["Rift Stalker"] = true,
		["Gina Mudclaw"] = true,
}
Rested.FarmPrefixes = { "Alluring", "Infested", "Parched", "Runty", "Smothered", "Tangled", "Wiggling", "Wild" }

function Rested.FarmIsCrop( name )
	if Rested.FarmThings[name] then
		return false
	else
		for _, pattern in pairs( Rested.FarmPrefixes ) do
			if string.find(name, "^"..pattern) then
				return false
			end
		end
	end
	return true
end

function Rested.FarmGetPlotSize( retryCount )
	local plotSizeQuests = { [2] = 30535, [4] = 30257, [8] = 30516, [12] = 30524, [16] = 30529 }
	Rested.me.farm = Rested.me.farm or {}
	for plotSize, qnum in Rested.SortedPairs( plotSizeQuests ) do
		local title = C_QuestLog.GetTitleForQuestID( qnum )
		local isComplete = C_QuestLog.IsQuestFlaggedCompleted( qnum )
		-- print( plotSize,  C_QuestLog.IsQuestFlaggedCompleted(qnum) )
		if title then
			if isComplete then
				Rested.me.farm.numPlots = plotSize
			end
		else
			-- print( plotSize..":"..qnum.." failed to get title: Using After" )
			if not retryCount or retryCount <= 10 then
				C_Timer.After( 1, function() Rested.FarmGetPlotSize( (retryCount and retryCount + 1 or 1) ) end )
			end
			return
		end
	end
	if not Rested.me.farm.numPlots then
		Rested.me.farm = nil
	end
end
function Rested.FarmGetDailyReset( )
	-- return low, and high
	local now = date( "*t" )
	--print( "hour: "..now.hour )
	if now.hour >= 2 then
		now.hour = 2
	end
	Rested.FarmPrev = time(now)
	Rested.FarmNext = Rested.FarmPrev + 86400
end

function Rested.FarmSoftFriendChanged( ... )
	if GetSubZoneText() == "Sunsong Ranch" then
		local unitName = UnitName("playertarget")
		local unitGUID = UnitGUID("playertarget")

		-- print( "--"..(unitName or "nil") )
		if unitGUID and unitName and Rested.FarmIsCrop(unitName) and not string.match(unitGUID, "^Pet") then
			Rested.me.farm = Rested.me.farm or {}
			Rested.me.farm.lastHarvest = time()
		end
	end
end

Rested.EventCallback( "PLAYER_SOFT_FRIEND_CHANGED", Rested.FarmSoftFriendChanged )
Rested.EventCallback( "QUEST_LOG_UPDATE", Rested.FarmGetPlotSize )
Rested.InitCallback( Rested.FarmGetPlotSize )
Rested.InitCallback( Rested.FarmGetDailyReset )

function Rested.FarmReport( realm, name, charStruct )
	if not Rested.FarmPrev then Rested.FarmGetDailyReset() end
	local rn = Rested.FormatName( realm, name )
	if charStruct.farm then
		-- print( realm, name, charStruct.farm, charStruct.farm.lastHarvest, charStruct.farm.numPlots )
		table.insert( Rested.charList, { 150 - (((charStruct.farm.lastHarvest or 1) - Rested.FarmPrev) * (150/86400)),
				string.format( "%i :: %s :: %s", (charStruct.farm.numPlots or 0), SecondsToTime( time() - (charStruct.farm.lastHarvest or 1) ), rn ) } )
		return 1
	end
end

-- Rested.reportReverseSort["Farm"] = true
Rested.dropDownMenuTable["Farm"] = "farm"
Rested.commandList["farm"] = {["help"] = {"","Show Farm report"}, ["func"] = function()
		Rested.reportName = "Farm"
		Rested.UIShowReport( Rested.FarmReport )
	end
}
