-- RestedMounts.lua
function Rested.BuildMountSpells( )
	-- Build a table of [spellID] = "mountName"
	Rested.mountSpells = {}
	local mountIDs = C_MountJournal.GetMountIDs()
	for _, mID in pairs(mountIDs) do
		--print( mID )
		mName, mSpellID = C_MountJournal.GetMountInfoByID( mID )
		Rested.mountSpells[ mSpellID ] = mName
	end
end
function Rested.GetCurrentMount( ... )
	arg1 = ...
	if( arg1 == "MOUNT" ) then   -- only look if the event is for MOUNT
		if( not IsMounted() ) then -- IsMounted() seems to be updated AFTER this event, and after the auras are updated.
			Rested.currentMount = nil  -- it will be True (you are mounted) if you were mounted when the event fired (probably not from you)
		end
		if( not Rested.mountSpells ) then
			Rested.BuildMountSpells()
		end
		for an=1,40 do
			aName, _, _, aType, _, _, _, _, _, aID = UnitAura( "player", an )
			if( aName ) then
				--print( "Aura "..an..": "..aName.." ("..(aID or "nil")..")" )
				if( Rested.mountSpells[aID] and Rested.mountSpells[aID] == aName ) then
					--print( aName.." is a mount." )
					if( not Rested.currentMount ) then
						print( "You have mounted: "..aName.." at "..date() )
						Rested.currentMount = aID
						--Screenshot()
						Rested_misc.mountHistory[time()] = aName
						Rested.PruneByAge( Rested_misc.mountHistory, Rested_options.mountHistoryAge )
					end
				end
				--print( string.format( "Aura %s: %s (%s) (id=%s)", an, aName, aType, aId ) )
			else
				break
			end
		end
	end
	Rested.PruneByAge( Rested_misc.mountHistory, Rested_options.mountHistoryAge )
end
Rested.InitCallback( function()
		Rested_misc.mountHistory = Rested_misc.mountHistory or {}
		Rested_options.mountHistoryAge = Rested_options.mountHistoryAge or 259200
	end
)
-- set the history age to 2 hours
Rested.EventCallback( "COMPANION_UPDATE", Rested.GetCurrentMount )
Rested.EventCallback( "COMPANION_LEARNED", Rested.BuildMountSpells )
--Rested.EventCallback( "COMPANION_UPDATE", function( ... ) cType, arg2 = ...; Rested.Print( string.format( "COMPANION_UPDATE( %s, %s )", (cType or "nil"), (arg2 or "nil") ) ); end )

Rested.dropDownMenuTable["Mounts"] = "mounts"
Rested.commandList["mounts"] = { ["help"] = {"","Show recent mount history"}, ["func"] = function()
		Rested.reportName = "Mount history"
		Rested.UIShowReport( Rested.MountReport )
	end
}
function Rested.MountReport( realm, name, charStruct )
	--print( "size of charList: "..#Rested.charList )
	if( #Rested.charList == 0 and Rested_misc.mountHistory ) then
		Rested.PruneByAge( Rested_misc.mountHistory, Rested_options.mountHistoryAge )
		local mountCount = {}
		for ts, mount in pairs( Rested_misc.mountHistory ) do
			if( mountCount[mount] ) then
				mountCount[mount].count = mountCount[mount].count + 1
				mountCount[mount].mostRecent = math.max( mountCount[mount].mostRecent, ts )
			else
				mountCount[mount] = { ["count"] = 1, ["mostRecent"] = ts }
			end
		end
		local lineCount = 0
		for mount, struct in pairs( mountCount ) do
			Rested.strOut = string.format( "%d (%s ago) %s", struct.count, SecondsToTime( time() - struct.mostRecent ), mount )
			table.insert( Rested.charList,
					{ ( ( struct.mostRecent + Rested_options.mountHistoryAge - time() ) / Rested_options.mountHistoryAge ) * 150, Rested.strOut } )
			lineCount = lineCount + 1
		end
		return lineCount
	end
end
function Rested.SetMountHistoryAge( inVal )
	local previousVal = SecondsToTime( Rested_options.mountHistoryAge )
	local newVal = Rested.DecodeTime( inVal, "d" )
	Rested_options["mountHistoryAge"] = newVal
	Rested.Print( string.format( "mountHistoryAge changed from %s to %s", previousVal, SecondsToTime( newVal ) ) )
end
Rested.commandList["setmountage"] = {["help"] = {"#[s|m|h|d|w]", "Set the time to track mounts."},
		["func"] = Rested.SetMountHistoryAge }

