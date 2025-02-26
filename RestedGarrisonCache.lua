-- RestedGarrisonCache.lua

function Rested.GatherGarrisonResources( ... )
	local type, link, amount = ...
	-- Rested.Print( "GatherGarrisonResources: "..type..":"..link..":"..amount )
	if type == "currency" and strfind( link, "Garrison Resources" ) then
		Rested.me.garrisonCache = time()

	end
end
function Rested.GarrisonResources( ... )
	local curInfo = C_CurrencyInfo.GetCurrencyInfo( 824 ) -- 824 = garrison resources
	Rested.me.garrisonQuantity = curInfo.quantity
end

Rested.EventCallback( "SHOW_LOOT_TOAST", Rested.GatherGarrisonResources )
Rested.EventCallback( "CURRENCY_DISPLAY_UPDATE", Rested.GarrisonResources )
Rested.InitCallback( Rested.GarrisonResources )

Rested.dropDownMenuTable["Garrison Cache"] = "gcache"
Rested.commandList["gcache"] = { ["help"] = {"","Show garrison cache report."}, ["func"] = function()
		Rested.reportName="Garrison Cache"
		Rested.UIShowReport( Rested.GcacheReport )
	end
}
Rested.cacheRate = 6 -- 6/hour (144/day)
Rested.cacheMax = 500  -- Todo:  This needs to come from a variable, and be stored per character...  :|
Rested.cacheMin = 5
function Rested.GcacheWhenAt( targetAmount, gCacheTS )
	return ( gCacheTS + ( ( targetAmount / Rested.cacheRate ) * 3600 ) )
end
function Rested.GcacheReport( realm, name, charStruct )
	if( charStruct.garrisonCache ) then
		local rn = Rested.FormatName( realm, name )
		local timeSince = time() - charStruct.garrisonCache

		local resourcesInCache = math.floor(math.min( ( timeSince / 3600 ) * Rested.cacheRate, Rested.cacheMax ))

		local fullAt = ( (Rested.cacheMax / Rested.cacheRate) * 3600 ) + charStruct.garrisonCache

		if( ( fullAt + Rested_options.staleStart > time() ) -- has the cache been full for less than the stale time
				or ( charStruct.garrisonQuantity and charStruct.garrisonQuantity < 10000 )
				or ( name == Rested.name and realm == Rested.realm ) ) then
			if fullAt > time() then
				table.insert( Rested.charList,
						{ (resourcesInCache / Rested.cacheMax) * 150,
							string.format( "%i%s : %s :: %s",
								(resourcesInCache >= Rested.cacheMin and resourcesInCache or 0),
								(charStruct.garrisonQuantity and " : "..charStruct.garrisonQuantity or ""),
								SecondsToTime( fullAt - time() ),
								rn) } )
			else
				table.insert( Rested.charList,
						{ timeSince,
							string.format( "%i%s : %s :: %s",
								Rested.cacheMax,
								(charStruct.garrisonQuantity and " : "..charStruct.garrisonQuantity or ""),
								SecondsToTime( time() - fullAt ),
								rn) } )
			end
			return 1
		end
	end
end

--[[
currencyID = 824
local curInfo = C_CurrencyInfo.GetCurrencyInfo( tonumber( currencyID ) )
		local iHaveNum = curInfo["quantity"]
		local currencyLink = C_CurrencyInfo.GetCurrencyLink( tonumber( currencyID ), iHaveNum )
		local gained = iHaveNum - cData.total
		if cData.total ~= iHaveNum then
			local progressString = string.format("%i/%i %s%s",  -- Build the progress string
					iHaveNum, cData.needed,
					(INEED_options.includeChange
						and string.format("(%s%+i%s) ", ((gained > 0) and COLOR_GREEN or COLOR_RED), gained, COLOR_END)
						or ""),
					currencyLink)
			_ = INEED_options.showProgress and UIErrorsFrame:AddMessage( progressString )
			_ = INEED_options.printProgress and INEED.Print( progressString )
			INEED_currency[currencyID]['total'] = iHaveNum
			INEED_currency[currencyID]['updated'] = time()
		end

		]]

-- Add in a garrison level like the Pandarian Farm report
-- level : cache : Time :: rn
-- Quests:
-- 1: 34586: Establish Your Garrison
-- 2: 36592:
-- 3: 36615: My Very Own Castle

-- /rested quests 34586,36615