-- RestedBase.lua
-- Track 'base' data.

-- ignore
-- allows the user to ignore an alt for a bit of time (set with options)
-- sets 'ignore' which is a timestamp for when to stop ignoring.
-- absence of 'ignore' means to not ignore alt.
function Rested.SetIgnore( param )
	-- do the original search and ignore
	if( param and strlen( param ) > 0 ) then
		-- break the param into strings seperated by spaces
		local charMatches = {}
		for ignoreStr in string.gmatch( param, "%S+" ) do
			table.insert( charMatches, ignoreStr )
		end
		-- test for time values from the back
		local isTime = true
		local seconds = 0
		while( isTime ) do
			secFromText = Rested.TextToSeconds( charMatches[#charMatches] )
			if( secFromText ~= nil ) then
				seconds = seconds + secFromText
				Rested_options.ignoreTime = seconds
				charMatches[#charMatches] = nil
			else
				isTime = false
			end
		end
		param = table.concat( charMatches, " " )  -- concat with spaces
		--print( "Param: "..param )

		param = string.upper( param )
		Rested.Print( "SetIgnore: "..param )
		for realm in pairs( Rested_restedState ) do
			for name, struct in pairs( Rested_restedState[realm] ) do
				if( ( string.find( string.upper( realm ), param ) ) or
						( string.find( string.upper( name ), param ) ) ) then
					struct.ignore = time() + Rested_options.ignoreTime
					Rested.Print( string.format( "Ignoring %s:%s for %s", realm, name, SecondsToTime( Rested_options.ignoreTime ) ) )
				end
			end
		end
	else
		-- put code here to show the report
		Rested.reportName = "Ignored"
		Rested.UIShowReport( Rested.IgnoredCharacters, true )
	end
end
function Rested.UpdateIgnore( realm, name, charStruct )
	-- clear ignore for this charStruct if expired
	if( charStruct.ignore and time() >= charStruct.ignore ) then
		charStruct.ignore = nil
	end
end
function Rested.IgnoredCharacters( realm, name, charStruct )
	if( charStruct.ignore ) then
		timeToGo = charStruct.ignore - time()
		if( timeToGo >= ( Rested_options.ignoreDateLimit and Rested_options.ignoreDateLimit or 7776000 ) ) then
			Rested.strOut = string.format( "%s: %s", date( "%x %X", charStruct.ignore ), Rested.FormatName( realm, name ) )
		else
			Rested.strOut = string.format( "%s: %s", SecondsToTime( timeToGo ), Rested.FormatName( realm, name ) )
		end
		table.insert( Rested.charList, {(timeToGo/Rested_options.ignoreTime)*150, Rested.strOut} )
		return 1
	end
	return 0
end
Rested.commandList["ignore"] = { ["func"] = Rested.SetIgnore, ["help"] = {"<search> [ignore Duration]", "Ignore matched chars, or show ignored." } }
Rested.EventCallback( "PLAYER_ENTERING_WORLD", function() Rested.ForAllChars( Rested.UpdateIgnore, true ); end )
Rested.dropDownMenuTable["Ignore"] = "ignore"


function Rested.SaveRestedState()
	-- update anything based on rested state
	-- lvlNow, xpNow, xpMax, isResting, restedPC, rested
	Rested.restedValue = GetXPExhaustion() or 0  -- XP till Exhaustion
	Rested.xpMax = UnitXPMax( "player" )
	Rested.restedPC = ( Rested.restedValue > 0 and ( ( Rested.restedValue / Rested.xpMax ) * 100 ) or 0 )

	Rested_restedState[Rested.realm][Rested.name].lvlNow = UnitLevel( "player" )
	Rested_restedState[Rested.realm][Rested.name].xpNow = UnitXP( "player" )
	Rested_restedState[Rested.realm][Rested.name].xpMax = Rested.xpMax
	Rested_restedState[Rested.realm][Rested.name].isResting = IsResting()
	Rested_restedState[Rested.realm][Rested.name].rested = Rested.restedValue   -- this is how much rested XP you have
	Rested_restedState[Rested.realm][Rested.name].restedPC = Rested.restedPC
end

Rested.InitCallback( Rested.SaveRestedState )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveRestedState )
Rested.EventCallback( "PLAYER_XP_UPDATE", Rested.SaveRestedState )
Rested.EventCallback( "PLAYER_UPDATE_RESTING", Rested.SaveRestedState )
Rested.EventCallback( "UPDATE_EXHAUSTION", Rested.SaveRestedState )
Rested.EventCallback( "CHANNEL_UI_UPDATE", Rested.SaveRestedState )  -- what IS this event?

--
function Rested.ReminderIsNotResting( realm, name, struct )
	returnStruct = {}
	reminderTime = time() + 60
	if( not struct.isResting ) then
		if( not returnStruct[reminderTime] ) then
			returnStruct[reminderTime] = {}
		end
		table.insert( returnStruct[reminderTime],
				string.format( "%s is not resting.", Rested.FormatName( realm, name, false ) ) )
	end
	return returnStruct
end
Rested.ReminderCallback( Rested.ReminderIsNotResting )

Rested.reminderValues = {
	[0] = COLOR_GREEN.."RESTED:"..COLOR_END.." %s:%s is now fully rested.",
	[60] = COLOR_GREEN.."RESTED:"..COLOR_END.." 1 minute until %s:%s is fully rested.",
	[300] = COLOR_GREEN.."RESTED:"..COLOR_END.." 5 minutes until %s:%s is fully rested.",
	[600] = COLOR_GREEN.."RESTED:"..COLOR_END.." 10 minutes until %s:%s is fully rested.",
	[900] = COLOR_GREEN.."RESTED:"..COLOR_END.." 15 minutes until %s:%s is fully rested.",
	[1800] = COLOR_GREEN.."RESTED:"..COLOR_END.." 30 minutes until %s:%s is fully rested.",
	[3600] = COLOR_GREEN.."RESTED:"..COLOR_END.." 1 hour until %s:%s is fully rested.",
	[7200] = COLOR_GREEN.."RESTED:"..COLOR_END.." 2 hours until %s:%s is fully rested.",
	[14400] = COLOR_GREEN.."RESTED:"..COLOR_END.." 4 hours until %s:%s is fully rested.",
	[21600] = COLOR_GREEN.."RESTED:"..COLOR_END.." 6 hours until %s:%s is fully rested.",
	[28800] = COLOR_GREEN.."RESTED:"..COLOR_END.." 8 hours until %s:%s is fully rested.",
	[43200] = COLOR_GREEN.."RESTED:"..COLOR_END.." 12 hours until %s:%s is fully rested.",
	[57600] = COLOR_GREEN.."RESTED:"..COLOR_END.." 16 hours until %s:%s is fully rested.",
	[86400] = COLOR_GREEN.."RESTED:"..COLOR_END.." 1 day until %s:%s is fully rested.",
	[172800] = COLOR_GREEN.."RESTED:"..COLOR_END.." 2 days until %s:%s is fully rested.",
	[432000] = COLOR_GREEN.."RESTED:"..COLOR_END.." 5 days until %s:%s is fully rested.",
}
Rested.restedRates = { [ true ] = 5/(8*3600), [ false ] = 5/(32*3600) }  -- 5% every 8 hours
function Rested.RestedReminderValues( realm, name, struct )
	returnStruct = {}
	if( struct.lvlNow and struct.lvlNow < Rested.maxLevel ) then
		local now = time()
		local timeSince = now - struct.updated
		local restRate = Rested.restedRates[struct.isResting]
		local restAdded = restRate * timeSince
		local restedVal = struct.restedPC + restAdded
		local restedAt = now + ( ( (Rested.maxRestedByRace[struct.race] or 150) - restedVal ) / restRate )
		for diff, format in pairs( Rested.reminderValues ) do
			reminderTime = tonumber( restedAt - diff )
			if( reminderTime > now ) then
				if( not returnStruct[reminderTime] ) then
					returnStruct[reminderTime] = {}
				end
				table.insert( returnStruct[reminderTime], string.format( format, realm, name ) )
			end
		end
	end
end
Rested.ReminderCallback( Rested.RestedReminderValues )

--  Reports
------------------------------
Rested.dropDownMenuTable["Level"] = "level"
Rested.commandList["level"] = {["help"] = {"","Show % of level"}, ["func"] = function()
		Rested.reportName = "% of Level"
		Rested.UIShowReport( Rested.OfLevel )
	end
}
function Rested.OfLevel( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	if charStruct.lvlNow < Rested.maxLevel then
		local lvlPC = charStruct.xpNow / charStruct.xpMax
		Rested.strOut = string.format( "%d :: %0.2f%% %s",
				charStruct.lvlNow,
				lvlPC * 100,
				rn)
		table.insert( Rested.charList, {lvlPC * 150, Rested.strOut} )
		return 1
	end
	return 0
end

Rested.dropDownMenuTable["Full"] = "full"
Rested.commandList["full"] = {["help"] = {"", "Show fully rested characters"}, ["func"] = function()
		Rested.reportName = "Fully Rested"
		Rested.UIShowReport( Rested.FullyRested )
	end
}
function Rested.FullyRested( realm, name, charStruct )
	-- 80 (15.5%): Realm:Name
	local rn = Rested.FormatName( realm, name )
	local restedStr, restedVal, code, timeTillRested = Rested.FormatRested( charStruct )
	if restedVal >= (Rested.maxRestedByRace[charStruct.race] or 150) then
		Rested.strOut = string.format("%d %s",
				charStruct.lvlNow,
				rn)
		table.insert( Rested.charList, {(charStruct.xpNow / charStruct.xpMax)*150, Rested.strOut} )
		return 1
	end
	return 0
end

Rested.dropDownMenuTable["Resting"] = "resting"
Rested.commandList["resting"] = {["help"] = {"","Show resting characters"}, ["func"] = function ()
		Rested.reportName = "Resting Characters"
		Rested.UIShowReport( Rested.RestingCharacters )
	end
}
function Rested.RestingCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	if (charStruct.lvlNow ~= Rested.maxLevel and charStruct.restedPC <= (Rested.maxRestedByRace[charStruct.race] or 150)-1) or
			(realm == Rested.realm and name == Rested.name) then
		local restedStr, restedVal, code, timeTillRested = Rested.FormatRested( charStruct )
		Rested.strOut = string.format("% 2d%s %s", charStruct.lvlNow, code, restedStr)
		if timeTillRested then
			Rested.strOut = Rested.strOut.." "..SecondsToTime(timeTillRested)
		end

		rn = Rested.FormatName( realm, name )
		Rested.strOut = Rested.strOut..": "..rn
		table.insert( Rested.charList, {restedVal, Rested.strOut} )
		return 1
	end
	return 0
end

Rested.dropDownMenuTable["All"] = "all"
Rested.commandList["all"] = {["help"] = {"","Show all characters"}, ["func"] = function()
		Rested.reportName = "All"
		Rested.UIShowReport( Rested.AllCharacters )
	end
}
function Rested.AllCharacters( realm, name, charStruct )
	-- 80 (15.5%): Realm:Name
	rn = Rested.FormatName( realm, name )
	Rested.strOut = string.format( "%0.2f (%s): %s",
		charStruct.lvlNow + ((charStruct.xpNow / charStruct.xpMax )),
		--(charStruct.xpNow / charStruct.xpMax) * 100,
		select(1,Rested.FormatRested(charStruct)),
		rn )
	table.insert( Rested.charList, {((charStruct.lvlNow + (charStruct.xpNow / charStruct.xpMax ))/ Rested.maxLevel) * 150, Rested.strOut} )
	return 1
end

Rested.dropDownMenuTable["Nag"] = "nag"
Rested.commandList["nag"] = {["help"] = {"","Show nag characters"}, ["func"] = function()
		Rested.reportName = "Nag Characters"
		Rested.UIShowReport( Rested.NagCharacters )
	end,
	["desc"] = {"Leveling toons will be shown if their rested pool covers the rest of the current level.",
				"Leveling toons won't be shown if they were fully rested when logged out.",
				"Max level toons will be shown if they have not been played from nagStart to staleStart."
	}
}
function Rested.NagCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	if( charStruct.nonag ) then
		if( charStruct.nonag > time() ) then
			return 0
		else charStruct.nonag = nil
		end
	end
	local reportStr = "%d :: %s : %s"  -- (lvl Now) :: timeSince : Name
	rn = Rested.FormatName( realm, name )
	local timeSince = time() - charStruct.updated
	if( charStruct.lvlNow == Rested.maxLevel and  -- maxLevel char in the NAG range
			timeSince >= Rested_options.nagStart and
			timeSince <= Rested_options.staleStart ) then
		Rested.strOut = string.format( reportStr, charStruct.lvlNow, SecondsToTime( timeSince ), rn )
		table.insert( Rested.charList, {(timeSince/(Rested_options.staleStart))*(Rested.maxRestedByRace[charStruct.race] or 150), Rested.strOut} )
		return 1
	end
	if( charStruct.lvlNow < Rested.maxLevel and charStruct.restedPC <= (Rested.maxRestedByRace[charStruct.race] or 150)-1 ) then -- leveling character
		local restedStr, restedVal, code, timeTillRested = Rested.FormatRested( charStruct )
		rs = Rested.formatRestedStruct  -- side effect of FormatRested()
		if( ( not rs.lvlPCLeft or restedVal >= rs.lvlPCLeft ) and -- lvlPCLeft is not set if you are fully rested
				restedVal <= 250 ) then  -- 200 % rested.   Let it expire after a time.
			Rested.strOut = string.format( reportStr, charStruct.lvlNow, restedStr, rn )
			table.insert( Rested.charList, { restedVal, Rested.strOut } )
			return 1
		end
	end
	useColor = useColor and ( realm == Rested.realm and name == Rested.name )
	if( charStruct.isResting == false and not ( realm == Rested.realm and name == Rested.name ) ) then
		Rested.strOut = string.format( reportStr .. " NOT RESTING", charStruct.lvlNow, SecondsToTime( timeSince ), rn )
		table.insert( Rested.charList, { (timeSince/(Rested_options.staleStart))*(Rested.maxRestedByRace[charStruct.race] or 150), Rested.strOut } )
		return 1
	end
	return 0
end
Rested.InitCallback( function()
		Rested_options.nagStart = Rested_options.nagStart or 7 * 86400
		Rested_options.staleStart = Rested_options.staleStart or 10 * 86400
	end
)
Rested.EventCallback( "PLAYER_ENTERING_WORLD", function()
		if( Rested.ForAllChars( Rested.NagCharacters ) > 0 ) then
			Rested.Command( "nag" )
			Rested.autoCloseAfter = Rested_options.nagTimeOut and time()+Rested_options.nagTimeOut or nil
		end
	end
)
function Rested.SetNag( inVal )
	-- This sets the NagTime (maxCutOff) to a number of seconds -- change the name of the setting (and how the setting is used)
	local newNag = ( Rested.TextToSeconds( inVal, "d" ) or 0 )
	if newNag > 0 then
		local previousNag = SecondsToTime( Rested_options.nagStart )
		if( newNag <= Rested_options.staleStart ) then
			Rested_options["nagStart"] = newNag
			Rested.Print( string.format( "nagStart changed from %s to %s", previousNag, SecondsToTime( newNag ) ) )
		else
			Rested.Print( "nagStart cannot be greater than staleStart" )
		end
	else
		Rested.Print( string.format( "nagStart is set at %s", SecondsToTime( Rested_options.nagStart ) ) )
	end
end
Rested.commandList["setnag"] = {["help"] = {"#[s|m|h|d|w]", "Set the time before a max level character shows up in the nag report."},
		["func"] = Rested.SetNag }

function Rested.SetNagTimeOut( inVal )
	--print("SetNagTimeOut( "..inVal.." )" )
	local previousTimeOut = (Rested_options.nagTimeOut and SecondsToTime( Rested_options.nagTimeOut ) or "Do Not Auto Hide" )
	-- This set the Timeout for the Nag report
	if( inVal == "" ) then
		Rested.Print( "NagTimeOut currently set to: "..previousTimeOut )
	else
		local newTimeOut = Rested.TextToSeconds( inVal, "d" )
		--print( "newTimeOut: "..newTimeOut )
		if newTimeOut >= 0 then
			Rested_options["nagTimeOut"] = newTimeOut
			Rested.Print( string.format( "NagTimeOut changed from %s to %s", previousTimeOut, SecondsToTime( newTimeOut ) ) )
		end
		if Rested_options.nagTimeOut == 0 then
			Rested_options.nagTimeOut = nil
		end
	end
end
Rested.commandList["setnagtimeout"] = {["help"] = {"#[s|m|h|d|w]", "Set the time to autoshow the nag window."},
	["func"] = Rested.SetNagTimeOut,
	["desc"] = {"Set how long the nag report is auto shown for."},
}

function Rested.SetNoNag( param )
	if( param and strlen( param ) > 0 ) then
		-- break the param into strings seperated by spaces
		local charMatches = {}
		for ignoreStr in string.gmatch( param, "%S+" ) do
			table.insert( charMatches, ignoreStr )
		end
		-- test for time values from the back
		local isTime = true
		local seconds = 0
		while( isTime ) do
			secFromText = Rested.TextToSeconds( charMatches[#charMatches] )
			if( secFromText ~= nil ) then
				seconds = seconds + secFromText
				Rested_options.noNagTime = seconds
				charMatches[#charMatches] = nil
			else
				isTime = false
			end
		end
		Rested_options.noNagTime = Rested_options.noNagTime or (7 * 86400)
		param = table.concat( charMatches, " " )  -- concat with spaces

		param = string.upper( param )
		Rested.Print( "NoNag: "..param )
		for realm in pairs( Rested_restedState ) do
			for name, struct in pairs( Rested_restedState[realm] ) do
				if( ( string.find( string.upper( realm ), param ) ) or
						( string.find( string.upper( name ), param ) ) ) then
					struct.nonag = time() + Rested_options.noNagTime
					Rested.Print( string.format( "NoNag for %s:%s for %s", realm, name, SecondsToTime( Rested_options.noNagTime ) ) )
				end
			end
		end
	end
end
function Rested.UpdateNoNag( realm, name, charStruct )
	if( charStruct.nonag and
			( time() >= charStruct.nonag or (Rested.realm == realm and Rested.name == name) ) ) then
		charStruct.nonag = nil
	end
end

Rested.commandList["nonag"] = {
		["func"] = Rested.SetNoNag,
		["help"] = { "<search> [ignore duration]", "Remove matched chars from the nag list for duration, or until visited." },
		["desc"] = {"Remove this player from the nag report for duration time, or until visited."}
}
Rested.EventCallback( "PLAYER_ENTERING_WORLD", function() Rested.ForAllChars( Rested.UpdateNoNag, true ); end )

-- Stale characters
Rested.dropDownMenuTable["Stale"] = "stale"
Rested.commandList["stale"] = {["help"] = {"","Show stale characters"}, ["func"] = function()
		Rested.reportName = "Stale Characters"
		Rested.UIShowReport( Rested.StaleCharacters )
	end
}
function Rested.StaleCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	local rn = Rested.FormatName( realm, name )
	local stale = Rested_options.staleStart
	timeSince = time() - charStruct.updated

	if (timeSince > stale) then
		Rested.strOut = format( "%d :: %s : %s", charStruct.lvlNow, SecondsToTime(timeSince), rn )
		table.insert( Rested.charList, {timeSince, Rested.strOut} )
		return 1
	end
	return 0
end
function Rested.SetStale( inVal )
	local newStale = ( Rested.TextToSeconds( inVal, "d" ) or 0 )
	if newStale > 0 then
		local previousStale = SecondsToTime( Rested_options.staleStart )
		if( newStale >= Rested_options.nagStart ) then
			Rested_options["staleStart"] = newStale
			Rested.Print( string.format( "staleStart changed from %s to %s", previousStale, SecondsToTime( newStale ) ) )
		else
			Rested.Print( "staleStart cannot be less than nagStart" )
		end
	else
		Rested.Print( string.format( "staleStart is set at %s", SecondsToTime( Rested_options.staleStart ) ) )
	end
end
Rested.commandList["setstale"] = {["help"] = {"#[s|m|h|d|w]", "Set the time before a max level character shows up as stale."},
		["func"] = Rested.SetStale }

-- Max level characters
Rested.dropDownMenuTable["Max"] = "max"
Rested.commandList["max"] = {["help"] = {"","Show max level characters"}, ["func"] = function()
		Rested.reportName = "Max Level Characters"
		Rested.UIShowReport( Rested.MaxCharacters )
	end
}
function Rested.MaxCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	if( charStruct.lvlNow == Rested.maxLevel ) then
		timeSince = time() - charStruct.updated
		rn = Rested.FormatName( realm, name )
		if (realm == Rested.realm and name == Rested.name) then
			Rested.strOut = rn
		else
			Rested.strOut = SecondsToTime(timeSince) ..": ".. rn
		end
		table.insert( Rested.charList, {(timeSince / (Rested_options.staleStart)) * 150, Rested.strOut} )
		return 1
	end
	return 0
end
