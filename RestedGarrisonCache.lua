-- RestedGarrisonCache.lua

function Rested.GatherGarrisonResources( ... )
	local type, link, amount = ...
	-- Rested.Print( "GatherGarrisonResources: "..type..":"..link..":"..amount )
	if type == "currency" and strfind( link, "Garrison Resources" ) then
		Rested.me.garrisonCache = time()
	end
end

Rested.EventCallback( "SHOW_LOOT_TOAST", Rested.GatherGarrisonResources )

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
	local rn = Rested.FormatName( realm, name )
	local lineCount = 0
	if charStruct.garrisonCache then
		lineCount = 1
		local timeSince = time() - charStruct.garrisonCache
		local timeSinceStr = SecondsToTime(timeSince)

		local resourcesInCache = math.min( ( timeSince / 3600 ) * Rested.cacheRate, Rested.cacheMax )

		Rested.strOut = string.format("%i - %s :: %s",
				(resourcesInCache >= Rested.cacheMin and resourcesInCache or 0),
				timeSinceStr,
				rn)
		table.insert( Rested.charList,
				{ (resourcesInCache / Rested.cacheMax) * 150 ,
					Rested.strOut
				}
		)
	end
	return lineCount
end