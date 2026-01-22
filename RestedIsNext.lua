-- RestedIsNext.lua
RESTED_SLUG, Rested  = ...

function Rested.RegisterIsNext()
	SLASH_ISNEXT1 = "/isnext"
	SlashCmdList["ISNEXT"] = Rested.SetNextCharacters
end
function Rested.GetCharacterIndex()
	local characterIndex = GetCVar("lastCharacterIndex")

	for r, _ in pairs( Rested_restedState ) do
		for n, cs in pairs( Rested_restedState[r] ) do
			if cs.characterIndex == characterIndex then
				cs.characterIndex = nil
			end
		end
	end

	Rested_restedState[Rested.realm][Rested.name].characterIndex = characterIndex
	Rested_restedState[Rested.realm][Rested.name].isNextIndex = nil
	Rested.ShiftIsNextCharacterIndex()
	_, _, Rested.nextCharacterIndex = Rested.IsNext_GetMinMaxNext()
end
function Rested.SetNextCharacterIndex()
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
		_, _, Rested.nextCharacterIndex = Rested.IsNext_GetMinMaxNext()
	end
	Rested.reportName = "Play Next"
	Rested.UIShowReport( Rested.NextCharsReport, true )
end

Rested.InitCallback( Rested.GetCharacterIndex )
Rested.InitCallback( Rested.RegisterIsNext)
Rested.EventCallback( "PLAYER_LOGOUT", Rested.SetNextCharacterIndex )

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
