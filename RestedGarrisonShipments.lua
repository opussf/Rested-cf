-- RestedGarrisonShipments.lua

function Rested.Shipments_CRAFTER_CLOSED()
	-- this IS the prune function.
	-- print("CRAFTER_CLOSED")
	if Rested.me.garrisonShipments then
		local buildingCount = 0
		for buildingName, si in pairs( Rested.me.garrisonShipments ) do
			buildingCount = buildingCount + 1
			-- print(buildingName, #Rested.me.garrisonShipments[buildingName].shipments, buildingCount)
			if not Rested.me.garrisonShipments[buildingName].shipments or #Rested.me.garrisonShipments[buildingName].shipments == 0 then
				Rested.me.garrisonShipments[buildingName] = nil
				buildingCount = buildingCount - 1
			end
		end
		if buildingCount == 0 then
			Rested.me.garrisonShipments = nil
		end
	end
end
function Rested.Shipments_CRAFTER_INFO( ... )
	-- print("CRAFTER_INFO")
	local _, queuedShipments, maxShipments, ownedShipments, plotID = ...
	local z, buildingName = C_Garrison.GetOwnedBuildingInfoAbbrev(plotID)
	Rested.buildingName = buildingName
	local numPending = C_Garrison.GetNumPendingShipments()
	local name, texture, quality, itemID, followerID, duration = C_Garrison.GetShipmentItemInfo();

	Rested.me.garrisonShipments = Rested.me.garrisonShipments or {}
	Rested.me.garrisonShipments[buildingName] = Rested.me.garrisonShipments[buildingName] or {}
	Rested.me.garrisonShipments[buildingName].sampleTS = time()
	if numPending then
		Rested.me.garrisonShipments[buildingName].shipments = {}
		for i = 1, numPending do
			local t = {C_Garrison.GetPendingShipmentInfo(i)}
			Rested.me.garrisonShipments[buildingName].shipments[i] = t[7]
			Rested.me.garrisonShipments[buildingName].duration = duration
		end
	end
	local x, y = C_Map.GetPlayerMapPosition( C_Map.GetBestMapForUnit("player"), "player" ):GetXY();
	Rested.me.garrisonShipments[buildingName].x = x*100
	Rested.me.garrisonShipments[buildingName].y = y*100
end
function Rested.IsWithInDistance(x, y, d)
	if x and y then
		local cx, cy = C_Map.GetPlayerMapPosition( C_Map.GetBestMapForUnit("player"), "player" ):GetXY()
		cx = cx*100; cy = cy*100
		local distance = math.sqrt((cx-x)^2 + (cy-y)^2)
		if distance <= d then
			return true
		end
	end
end
function Rested.Shipments_LOOT_READY()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID == 582 or mapID == 590 then -- only if in the garrison map
		for buildingName, si in pairs(Rested.me.garrisonShipments or {}) do
			if Rested.IsWithInDistance(si.x, si.y, 3) then  -- distance of 1.5 might be good.
				for i = #Rested.me.garrisonShipments[buildingName].shipments, 1, -1 do
					if Rested.me.garrisonShipments[buildingName].sampleTS + Rested.me.garrisonShipments[buildingName].shipments[i] < time() then
						table.remove(Rested.me.garrisonShipments[buildingName].shipments, i) -- remove work order
					end
				end
			end
		end
		Rested.Shipments_CRAFTER_CLOSED()
	end
end
function Rested.Shipments_FixMissingShipments()
	if Rested.me.garrisonShipments then
		for buildingName, si in pairs( Rested.me.garrisonShipments ) do
			if not Rested.me.garrisonShipments[buildingName].shipments then
				print("Found an issue.")
				local t = date("*t") -- table with year, month, day, hour, min, sec, etc.
				t.day = t.day + 1
				t.hour = 9
				t.min = 0
				t.sec = 0
				local t9 = time(t)
				print(date("%Y-%m-%d %H:%M:%S", t9))
				Rested.me.garrisonShipments[buildingName].shipments = {
					t9 - Rested.me.garrisonShipments[buildingName].sampleTS
				}
				Rested.me.garrisonShipments[buildingName].duration = 14400
			end
		end
	end
end

Rested.EventCallback("SHIPMENT_CRAFTER_CLOSED", Rested.Shipments_CRAFTER_CLOSED)
Rested.EventCallback("SHIPMENT_CRAFTER_INFO", Rested.Shipments_CRAFTER_INFO)
Rested.EventCallback("LOOT_READY", Rested.Shipments_LOOT_READY)
Rested.InitCallback(Rested.Shipments_FixMissingShipments)

Rested.dropDownMenuTable["Garrison Work Orders"] = "gwo"
Rested.commandList["gwo"] = { ["help"] = {"","Show garrison work order report."}, ["func"] = function()
		Rested.reportName="Garrison Work Orders"
		Rested.UIShowReport( Rested.GShipmentReport )
	end
}

function Rested.GShipmentReport( realm, name, charStruct )
	if( charStruct.garrisonShipments ) then
		local rn = Rested.FormatName( realm, name )
		local count = 0
		for buildingName, si in Rested.SortedPairs( charStruct.garrisonShipments ) do
			local firstComplete, lastComplete = 0, 0
			local working = 0
			local queued = 0
			for i, duration in ipairs(charStruct.garrisonShipments[buildingName].shipments or {}) do
				queued = queued + 1
				lastComplete = si.sampleTS + duration
				if si.sampleTS + duration > time() then
					working = working + 1
					if firstComplete == 0 then
						firstComplete = si.sampleTS + duration
						-- print(i, SecondsToTime(firstComplete - time()), firstComplete - 14400, (time()-(firstComplete-14400))/14400 )
					end
				end
			end
			local complete = queued - working
			if working == 0 then
				table.insert( Rested.charList,
					{ 150 + ( time() - lastComplete ),
						string.format("%s%02i%s/%02i %s :: %s : %s",
								complete > 0 and COLOR_GREEN or "",
								complete,
								complete > 0 and COLOR_END or "",
								queued,
								SecondsToTime(time() - lastComplete, false, false, 1),
								buildingName,
								rn)
					}
				)
			else
				table.insert( Rested.charList,
					{ ((time() - (firstComplete - si.duration)) / si.duration) * 150,
						string.format("%s%02i%s/%02i %s :: %s : %s",
								complete > 0 and COLOR_GREEN or "",
								complete,
								complete > 0 and COLOR_END or "",
								queued,
								SecondsToTime(firstComplete - time()),
								buildingName,
								rn)
					}
				)
			end
			count = count + 1
		end
		return count
	end
end

function Rested.GWOReminders( realm, name, struct )
	local rn = Rested.FormatName( realm, name )
	local returnStruct = {}
	local now = time()
	for buildingName, gs in pairs(struct.garrisonShipments or {}) do
		local reminder = true
		for _, dur in ipairs(gs.shipments or {}) do
			reminder = reminder and (gs.sampleTS + dur < time())
		end
		if reminder then
			returnStruct[now+30] = returnStruct[now+30] or {}
			table.insert( returnStruct[now+30], string.format("%s has a full Garrison Work Order.", rn ) )
		end
	end
	return returnStruct
end
Rested.ReminderCallback( Rested.GWOReminders )
