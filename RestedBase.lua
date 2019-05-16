-- RestedBase.lua
-- Track 'base' data.

-- ignore
-- allows the user to ignore an alt for a bit of time (set with options)
-- sets 'ignore' which is a timestamp for when to stop ignoring.
-- absence of 'ignore' means to not ignore alt.
function Rested.SetIgnore( param )
	if( param and strlen( param ) > 0 ) then
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
		Rested.strOut = string.format( "%s: %s", SecondsToTime( timeToGo ), Rested.FormatName( realm, name ) )
		table.insert( Rested.charList, {(timeToGo/Rested_options.ignoreTime)*150, Rested.strOut} )
		return 1
	end
	return 0
end
Rested.commandList["ignore"] = { ["func"] = Rested.SetIgnore, ["help"] = {"<search>", "Ignore matched chars, or show ignored." } }
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
	Rested_restedState[Rested.realm][Rested.name].rested = Rested.restedValue
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
		local restedAt = now + ( ( 150 - restedVal ) / restRate )
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
	if restedVal >= 150 then
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
	if (charStruct.lvlNow ~= Rested.maxLevel and charStruct.restedPC < 150) or
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
	Rested.strOut = string.format( "%d (%s): %s",
		charStruct.lvlNow,
		--(charStruct.xpNow / charStruct.xpMax) * 100,
		select(1,Rested.FormatRested(charStruct)),
		rn )
	table.insert( Rested.charList, {(charStruct.lvlNow / Rested.maxLevel) * 150, Rested.strOut} )
	return 1
end

Rested.dropDownMenuTable["Nag"] = "nag"
Rested.commandList["nag"] = {["help"] = {"","Show nag characters"}, ["func"] = function()
		Rested.reportName = "Nag Characters"
		Rested.UIShowReport( Rested.NagCharacters )
	end
}
function Rested.NagCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	rn = Rested.FormatName( realm, name )
	local timeSince = time() - charStruct.updated
	if (charStruct.lvlNow == Rested.maxLevel and
			timeSince >= Rested_options.maxCutOff*86400 and
			timeSince <= Rested_options.maxStale * 86400) then
		Rested.strOut = format( "%d :: %s : %s", charStruct.lvlNow, SecondsToTime(timeSince), rn )
		table.insert( Rested.charList, {(timeSince/(Rested_options.maxStale*86400))*150, Rested.strOut} )
		return 1
	end
	return 0
end
Rested.InitCallback( function()
		Rested_options.maxCutOff = Rested_options.maxCutOff or 7
		Rested_options.maxStale = Rested_options.maxStale or 10
	end
)
Rested.EventCallback( "PLAYER_ENTERING_WORLD", function()
		if( Rested.ForAllChars( Rested.NagCharacters ) > 0 ) then
			Rested.Command( "nag" )
		end
	end
)
function Rested.SetNag( inVal )
	-- This sets the NagTime (maxCutOff) to a number of seconds -- change the name of the setting (and how the setting is used)
	Rested_options["maxCutoff"] = Rested.DecodeTime( inVal, "d" )
end
Rested.commandList["setnag"] = {["help"] = {"#[s|m|h|d|w]", "Set the time before a max level character shows up in the nag report."},
		["func"] = Rested.SetNag }

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
	local stale = Rested_options.maxStale * 86400
	timeSince = time() - charStruct.updated

	if (timeSince > stale) then
		Rested.strOut = format( "%d :: %s : %s", charStruct.lvlNow, SecondsToTime(timeSince), rn )
		table.insert( Rested.charList, {timeSince, Rested.strOut} )
		return 1
	end
	return 0
end
function Rested.SetStale( inVal )
	Rested_options["maxStale"] = Rested.DecodeTime( inVal, "d" )
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
		table.insert( Rested.charList, {(timeSince / (Rested_options.maxStale*86400)) * 150, Rested.strOut} )
		return 1
	end
	return 0
end
