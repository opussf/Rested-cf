-- RestedIsNext.lua
RESTED_SLUG, Rested  = ...

function Rested.RegisterIsNext()
	SLASH_ISNEXT1 = "/isnext"
	SlashCmdList["ISNEXT"] = Rested.SetNextCharacters
end
function Rested.GetCharacterIndex()
	if Rested_misc.prevChar and Rested_misc.prevIndex and Rested_misc.prevChar == Rested.realm.."-"..Rested.name then
		SetCVar("lastCharacterIndex", Rested_misc.prevIndex)  -- Reset the index.
	end

	local characterIndex = GetCVar("lastCharacterIndex")

	for r, _ in pairs( Rested_restedState ) do
		for n, cs in pairs( Rested_restedState[r] ) do
			if cs.characterIndex == characterIndex then
				cs.characterIndex = nil  -- Always clear current, then set.
			end
		end
	end

	Rested_restedState[Rested.realm][Rested.name].characterIndex = characterIndex
	Rested_restedState[Rested.realm][Rested.name].isNextIndex = nil
	Rested.ShiftIsNextCharacterIndex()
	_, _, Rested.nextCharacterIndex = Rested.IsNext_GetMinMaxNext()
end
function Rested.SetNextCharacterIndex()
	Rested_misc.prevChar = Rested.realm.."-"..Rested.name
	Rested_misc.prevIndex = Rested_restedState[Rested.realm][Rested.name].characterIndex
	if Rested.nextCharacterIndex then
		SetCVar("lastCharacterIndex", Rested.nextCharacterIndex)
	end
end

function Rested.IsNext_GetMinMaxNext()
	local isNextMin,isNextMax, isNextCharacterIndex = nil, nil, nil
	for r, _ in pairs( Rested_restedState ) do
		for n, cs in pairs( Rested_restedState[r] ) do
			if cs.isNextIndex then
				isNextMin = math.min( cs.isNextIndex, isNextMin or cs.isNextIndex )
				isNextMax = math.max( cs.isNextIndex, isNextMax or cs.isNextIndex )
				if isNextMin == cs.isNextIndex then
					isNextCharacterIndex = cs.characterIndex
				end
			end
		end
	end
	return isNextMin, isNextMax, isNextCharacterIndex
end
function Rested.ShiftIsNextCharacterIndex()
	local indexMin, indexMax = Rested.IsNext_GetMinMaxNext()
	local maxOut = nil
	if indexMin then
		local shiftVal = indexMin - 1
		for r, _ in pairs( Rested_restedState ) do
			for n, cs in pairs( Rested_restedState[r] ) do
				if cs.isNextIndex then
					cs.isNextIndex = cs.isNextIndex - shiftVal
					maxOut = math.max( cs.isNextIndex, maxOut or cs.isNextIndex )
				end
			end
		end
	end
	return maxOut
end
function Rested.SetNextCharacters( param )
	if( param and strlen( param ) > 0 ) then
		local currentIndex= Rested.ShiftIsNextCharacterIndex() or 0
		for searchName in string.gmatch( param, "([^ ]+)" ) do
			searchName = string.lower(searchName)
			if Rested.isNextMacros[searchName] and Rested.isNextMacros[searchName].func then
				Rested.isNextMacros[searchName].func(param)
				break  -- @TODO:  Remove this
			else
				local toRemove = ( string.sub( searchName, 1, 1 ) == "-" )
				if toRemove then
					searchName = string.sub( searchName, 2 )
				end
				for r, _ in pairs( Rested_restedState ) do
					for n, cs in pairs( Rested_restedState[r] ) do
						local match = false
						if( string.find( string.lower(r), searchName ) or
								string.find( string.lower(n), searchName ) ) then
							match = true
						else
							for _, key in pairs( Rested.filterKeys ) do
								if( cs[key] and string.find( string.lower( cs[key] ), searchName ) ) then
									match = true
								end
							end
						end
						if match then
							if toRemove then
								cs.isNextIndex = nil
							else
								currentIndex = currentIndex + 1
								cs.isNextIndex = currentIndex
							end
						end
					end
				end
			end
		end
		_, _, Rested.nextCharacterIndex = Rested.IsNext_GetMinMaxNext()
	end
	Rested.reportName = "Play Next"
	Rested.UIShowReport( Rested.NextCharsReport, true )
end

Rested.InitCallback(Rested.RegisterIsNext)
Rested.EventCallback("PLAYER_ENTERING_WORLD", function() C_Timer.After(5, Rested.GetCharacterIndex) end)
Rested.EventCallback("PLAYER_LOGOUT", Rested.SetNextCharacterIndex)

Rested.reportShowIgnored["Play Next"] = true
Rested.dropDownMenuTable["IsNext"] = "isnext"
Rested.commandList["isnext"] = {
	["help"] = {"space seperated character list", "Add the next characters to visit."},
	["func"] = Rested.SetNextCharacters,
}
table.insert( Rested.CSVFields, {"CharacterIndex", "characterIndex"} )

function Rested.NextCharsReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	if charStruct.isNextIndex then
		Rested.strOut = string.format( "%s :: %s%s",
			charStruct.isNextIndex,
			rn,
			(charStruct.characterIndex and "" or " (?)") )
		table.insert( Rested.charList, { 150 - charStruct.isNextIndex, Rested.strOut } )
		return 1
	end
end

-- macros
function Rested.isNextMacroList(param)
	Rested.Print("isnext macro list:")
	for macro, info in Rested.SortedPairs( Rested.isNextMacros ) do
		Rested.Print( string.format("   %s %s -> %s",
				macro, info.help[1], info.help[2] ), false )
	end
end
function Rested.isNextAlpha(param)
	local offset = string.match(param, " (%d+)") or 0
	local alpha = {}
	for realm, chars in pairs(Rested_restedState) do
		for name, charStruct in pairs(chars) do
			alpha[#alpha + 1] = name..":"..realm
		end
	end
	table.sort(alpha)
	for i, nameRealm in ipairs(alpha) do
		local name, realm = string.match(nameRealm, "^(.*):(.*)$")
		Rested_restedState[realm][name].isNextIndex = i + offset
	end
end
function Rested.isNextRandom(param)
	local offset = string.match(param, " (%d+)") or 0
	local r = {}
	for realm, chars in pairs(Rested_restedState) do
		for name, charStruct in pairs(chars) do
			r[#r + 1] = charStruct
		end
	end
	for lcv = 1, #r do
		rc = r[random(1, #r)]
		if not rc.isNextIndex then
			rc.isNextIndex = 1 + offset
			break
		end
	end
end
function Rested.isNextFarm(param)
	-- print("Param:", param)
	local mod, offset = string.match(param, "(%d+)%s*(%d*)")
	mod, offset = tonumber(mod) or 7, tonumber(offset) or 0
	-- print( "mod:", mod )
	-- print( "offset:", offset )

	Rested.ForAllChars(function(r, n, c)
		-- print(r,n,c.characterIndex, c.characterIndex%mod, date("%w")%mod, c.farm)
		-- print("not c.isNextIndex", not c.isNextIndex)
		if not c.isNextIndex
				and c.characterIndex
				and c.farm
				and c.farm.lastHarvest
				and c.farm.lastHarvest<time()-86400
				and c.characterIndex%mod==date("%w")%mod
				and n~=Rested.name then
			c.isNextIndex = c.characterIndex+offset
		end
	end, true)
end
function Rested.isNextProfCooldowns(param)
	local offset = string.match(param, "(%d+)") or 0

	Rested.ForAllChars(function(r, n, c)
		if not c.isNextIndex
				and c.tradeCD
				and n~=Rested.name then
			for id,t in pairs(c.tradeCD) do
				if t.cdTS and t.cdTS<time() then
					c.isNextIndex=c.characterIndex+offset
					return
				end
			end
		end
	end, true)
end
-- function Rested.isNextConcentration(param)
-- 	local offset = string.match(param, "(%d+)") or 0

-- 	Rested.ForAllChars(function(r, n, c)
-- 		if not c.isNextIndex
-- 				and c.concentration
-- 				and n~=Rested.name then
-- 			for profName, struct in pairs( c.concentration ) do
-- 				if struct.value < struct.max then
-- 					local timeToFull = ((struct.max - struct.value) / Rested.ConcentrationRateGain) - (time() - struct.ts)

-- 					print(n.."-"..r.." Needs: "..(struct.max - struct.value).." in "..SecondsToTime(timeToFull).." ("..timeToFull.."s)")
-- 					if timeToFull < 86400 then
-- 						c.isNextIndex = c.characterIndex + offset
-- 						return
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end, true)
-- end
function Rested.isNextGarrisonCache(param)
	local offset = string.match(param, "(%d+)") or 0

	Rested.ForAllChars(function(r, n, c)
		if not c.isNextIndex
				and c.garrisonQuantity
				and c.garrisonQuantity<10000
				and c.garrisonCache
				and c.garrisonCache<time()-216000
				and n~=Rested.name then
			c.isNextIndex = c.characterIndex+offset
		end
	end, true)
end
function Rested.isNextAuctions(param)
	local offset = string.match(param, "(%d+)") or 0

	Rested.ForAllChars(function(r,n,c)
		if not c.isNextIndex
				and c.Auctions
				and n~=Rested.name then
			for id, a in pairs(c.Auctions) do
				if a.created <= time() - a.duration then
					c.isNextIndex = c.characterIndex + offset
					return
				end
			end
		end
	end, true)
end

Rested.isNextMacros = {
	[":alpha"] = {
		["help"] = {"offset", "Queue all toons alphabetically."},
		["func"] = Rested.isNextAlpha,
	},
	[":rand"] = {
		["help"] = {"offset", "Queue a random character."},
		["func"] = Rested.isNextRandom,
	},
	[":farm"] = {
		["help"] = {"day offset", "Queue for pandarian farm."},
		["func"] = Rested.isNextFarm,
	},
	[":cooldowns"] = {
		["help"] = {"offset", "Queue for profession cooldowns."},
		["func"] = Rested.isNextProfCooldowns,
	},
	-- [":conc"] = {
	-- 	["help"] = {"offset", "Queue for profession concentration."},
	-- 	["func"] = Rested.isNextConcentration,
	-- },
	[":gcache"] = {
		["help"] = {"offset", "Queue for garrison cache"},
		["func"] = Rested.isNextGarrisonCache,
	},
	[":auctions"] = {
		["help"] = {"offset", "Queue for expired auctions"},
		["func"] = Rested.isNextAuctions,
	},
	[":macros"] = {
		["help"] = {"", "List macros"},
		["func"] = Rested.isNextMacroList,
	},
}
