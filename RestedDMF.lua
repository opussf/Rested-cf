-- RestedDMF.lua
RESTED_SLUG, Rested  = ...

-- Rested.me.DMF { lastVisit = time(), questID = true }
function Rested.DMFQuestComplete( ... )
	if GetZoneText() == "Darkmoon Island" then
		Rested.me.DMF = Rested.me.DMF or {["lastVisit"] = time()}
		local questID = ...
		Rested.me.DMF[questID] = time()
	end
end
function Rested.DMFIsOnDMFIsland()
	if GetZoneText() == "Darkmoon Island" then
		-- Rested.me.DMF = Rested.me.DMF or {}
		if Rested.me.DMF then
			if Rested.me.DMF.lastVisit < Rested.DMFStart then -- Visited before this month's DMF
				Rested.me.DMF = {["lastVisit"] = Rested.me.DMF.lastVisit}
			end
		else
			Rested.me.DMF = {}
		end
		Rested.me.DMF.lastVisit = time()
		Rested.Command( "dmf" )
	end
end
function Rested.DMFThisMonth()
	-- set start and end
	local now = date( "*t" )
	local monthFirstWDay = ( now.wday - now.day + 1 ) % 7  -- remainder is always +
	if monthFirstWDay == 0 then monthFirstWDay = 7 end
	local firstSundy = ( monthFirstWDay == 1 ) and 1 or ((7 - ( monthFirstWDay -1 )) % 7 ) + 1
	local endSaturday = firstSundy + 6

	now.day = firstSundy; now.hour = 0; now.minute = 1
	Rested.DMFStart = time( now )
	now.day = endSaturday; now.hour = 23; now.minute = 59
	Rested.DMFEnd = time( now )
end

Rested.EventCallback( "QUEST_TURNED_IN", Rested.DMFQuestComplete )
Rested.EventCallback( "ZONE_CHANGED_NEW_AREA", Rested.DMFIsOnDMFIsland )
Rested.InitCallback( Rested.DMFThisMonth )

function Rested.DMFReport( realm, name, charStruct )
	if not Rested.DMFStart then Rested.DMFThisMonth() end
	local rn = Rested.FormatName( realm, name )
	if charStruct.DMF then
		local questCount = 0
		for k,v in pairs( charStruct.DMF ) do
			if k ~= "lastVisit" then
				questCount = questCount + 1
			end
		end
		table.insert( Rested.charList, { 150 - ((charStruct.DMF.lastVisit - Rested.DMFStart) * (150/(Rested.DMFEnd - Rested.DMFStart))),
				string.format( "%i :: %s :: %s", questCount, SecondsToTime( time() - charStruct.DMF.lastVisit ), rn ) } )
		return 1
	else
		local nameCode, lcv = 0, 0
		for lcv = 1, min(string.len(nameCode), 3) do
			nameCode = nameCode * 100 + string.byte( name, lcv)
		end
		table.insert( Rested.charList, { 99999999 - nameCode, string.format( "No record of visit :: %s", rn ) } )
		return 1
	end
end

Rested.dropDownMenuTable["Darkmoon Faire"] = "dmf"
Rested.commandList["dmf"] = {["help"] = {"","Show DMF report"}, ["func"] = function()
		Rested.reportName = "Darkmoon Faire"
		Rested.UIShowReport( Rested.DMFReport )
	end
}
