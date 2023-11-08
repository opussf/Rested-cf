-- RestedAzerite.lua
Rested.AuctionsDurations = {  -- auction duration is set as index of duration dropdown
	[1] = 12 * 3600, -- 12 hours
	[2] = 24 * 3600, -- 24 hours
	[3] = 48 * 3600, -- 48 hours
}
Rested.AuctionAge = Rested.AuctionsDurations[3]
Rested.AuctionType = nil

function Rested.AuctionsClear()
	--local AuctionAge = 48 * 3600 -- 48 hours
	local activeCount = 0
	if Rested.me.Auctions then
		for aID in pairs( Rested.me.Auctions ) do
			if Rested.me.Auctions[aID].created <= time() - Rested.me.Auctions[aID].duration then
				Rested.me.Auctions[aID] = nil
			else
				activeCount = activeCount + 1
			end
		end
		if activeCount == 0 then
			Rested.me.Auctions = nil
		end
	end
end

function Rested.AuctionCreate( AuctionId )
	--Rested.Print( "AuctionCreate( "..AuctionId.." )" )
	--local AuctionAge = 48 * 3600 -- 48 hours
	Rested.me["Auctions"] = Rested.me["Auctions"] or {}
	Rested.me.Auctions[AuctionId] = {
			["created"] = time(),
			["duration"] = Rested.AuctionAge,
			["type"] = Rested.AuctionType,
			["version"] = RESTED_MSG_VERSION,
			["total"] = Rested.AuctionTotal,
	}
	Rested.AuctionType = nil
	Rested.AuctionsClear()

end

Rested.InitCallback( Rested.AuctionsClear )
Rested.EventCallback( "AUCTION_HOUSE_AUCTION_CREATED", Rested.AuctionCreate )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.AuctionsClear )

Rested.dropDownMenuTable["Auctions"] = "auctions"
Rested.commandList["auctions"] = {["help"] = {"","Show auction counts"}, ["func"] = function()
		Rested.reportName = "Auctions"
		Rested.UIShowReport( Rested.AuctionsReport )
	end
}
function Rested.AuctionsReport( realm, name, charStruct )
	local AuctionAge = 48 * 3600 -- 48 hours
	local rn = Rested.FormatName( realm, name )
	if charStruct.Auctions then
		local now = time()
		local activeCount, activeOldest = 0, now
		local expiredCount, expiredOldest = 0, now
		local maxDuration = 0
		for id in pairs( charStruct.Auctions ) do
			if charStruct.Auctions[id].created <= now - charStruct.Auctions[id].duration then
				expiredCount = expiredCount + 1
				expiredOldest = min( expiredOldest, charStruct.Auctions[id].created )
			else
				activeCount = activeCount + 1
				activeOldest = min( activeOldest, charStruct.Auctions[id].created )
				maxDuration = max( maxDuration, charStruct.Auctions[id].duration )
			end
		end
		local lineCount = 0
		if activeCount > 0 then
			Rested.strOut = string.format( "%d (%s to go) %s",
					activeCount, SecondsToTime( ( activeOldest + maxDuration) - now ), rn )
			table.insert( Rested.charList,
					{ ( ( activeOldest + AuctionAge - time() ) / AuctionAge ) * 150,
					Rested.strOut } )
			lineCount = lineCount + 1
		end
		if expiredCount > 0 then
			Rested.strOut = string.format( "%d (EXPIRED) %s",
					expiredCount, rn )
			table.insert( Rested.charList,
					{ 0, Rested.strOut } )
			lineCount = lineCount + 1
		end
		return lineCount
	end
	return 0
end

-- Reminders

function Rested.AuctionsExpired( realm, name, struct )
	returnStruct = {}
	reminderTime = time() + 60
	expiredCount = 0
	if struct.Auctions then
		for aID in pairs( struct.Auctions ) do
			local AuctionAge = struct.Auctions[aID].duration
			if struct.Auctions[aID].created <= time() - AuctionAge then
				expiredCount = expiredCount + 1
			end
		end
		if expiredCount > 0 then
			if( not returnStruct[reminderTime] ) then
				returnStruct[reminderTime] = {}
			end
			table.insert( returnStruct[reminderTime],
					string.format( "%s has %i expired auctions.",
							Rested.FormatName( realm, name ), expiredCount
					)
			)
		end
	end
	return returnStruct
end
Rested.ReminderCallback( Rested.AuctionsExpired )

-- post
C_AuctionHouse_PostCommodity = C_AuctionHouse.PostCommodity
C_AuctionHouse.PostCommodity = function( ... )
	-- C_AuctionHouse.PostCommodity(item, duration, quantity, unitPrice )
	item, duration, quantity, unitPrice = ...
	Rested.AuctionAge = Rested.AuctionsDurations[duration]
	Rested.AuctionType = "Commodity"
	Rested.AuctionTotal = quantity * unitPrice
	C_AuctionHouse_PostCommodity( ... )
end

C_AuctionHouse_PostItem = C_AuctionHouse.PostItem
C_AuctionHouse.PostItem = function( ... )
	-- C_AuctionHouse.PostItem(item, duration, quantity, bid, buyout)
	item, duration, quantity, bid, buyout = ...
	Rested.AuctionAge = Rested.AuctionsDurations[duration]
	Rested.AuctionType = "Item"
	Rested.AuctionTotal = quantity * ( buyout or bid )
	C_AuctionHouse_PostItem( ... )
end

-- Misc functions
function Rested.AuctionsOwnedAuctionsUpdated( ... )
	local a = select( 1, ... ) or "nil"
	Rested.Print( "OWNED_AUCTIONS_UPDATED( "..a.." )" )
end

Rested.EventCallback( "OWNED_AUCTIONS_UPDATED", Rested.AuctionsOwnedAuctionsUpdated )

function Rested.ScanMail()
	Rested.Print( "ScanMail" )
end

Rested.EventCallback( "MAIL_SHOW", Rested.ScanMail )
