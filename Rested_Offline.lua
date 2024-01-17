#!/usr/bin/env lua

-- first character of this string (http://www.lua.org/manual/5.2/manual.html#pdf-package.config)
pathSeparator = string.sub(package.config, 1, 1)

function ParsePath( pathIn, separator )
	srcFilePathTable = {}
	local j = 0
	while true do
		local i, j, subName = string.find( pathIn, "(.+)"..separator )
		if i == nil then break end
		--print( pathIn, i, j, string.sub( pathIn, i, j ), subName )
		table.insert( srcFilePathTable, subName )
		pathIn = string.sub( pathIn, j )
		--print( pathIn )
	end
	return table.concat( srcFilePathTable, pathSeparator ), srcFilePathTable
end
function TableFromTOC( tocFile )
	tocFileTable = {}
	local f = io.open( tocFile, "r" )
	local tocContents = f:read("*all")  -- read the whole file
	--print( tocContents )
	while true do
		local i, j, luaFile = string.find( tocContents, "([%a]*)%.lua" )
		if i == nil then break end
		table.insert( tocFileTable, luaFile )
		tocContents = string.sub( tocContents, j )
		--print( tocContents )
	end
	return tocFileTable
end
function FileExists( name )
	if name then
		local f = io.open( name, "r" )
		if f then io.close( f ) return true else return false end
	end
	return false
end
function DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end

-- WoWAPI functions that are not needed, and special ones that are
-- Taken mostly from wowStubs.lua
GetAddOnMetadata = function() end
GetXPExhaustion = function() end
UnitXPMax = function() end
function SecondsToTime( secondsIn, noSeconds, notAbbreviated, maxCount )
	-- http://www.wowwiki.com/API_SecondsToTime
	-- formats seconds to a readable time  -- WoW omits seconds if 0 even if noSeconds is false
	-- secondsIn: number of seconds to work with
	-- noSeconds: True to ommit seconds display (optional - default: false)
	-- notAbbreviated: True to use full unit text, short text otherwise (optional - default: false)
	-- maxCount: Maximum number of terms to return (optional - default: 2)
	maxCount = maxCount or 2
	local days, hours, minutes, seconds = 0
	local outArray = {}
	days = math.floor( secondsIn / 86400 )
	secondsIn = secondsIn - (days * 86400)

	hours = math.floor( secondsIn / 3600 )
	secondsIn = secondsIn - (hours * 3600)

	minutes = math.floor( secondsIn / 60 )
	seconds = math.floor( secondsIn - (minutes * 60) )


	-- format output
	local includeZero = false
	formats = { { "%i Day", "%i Day", days},
			{ "%i Hr", "%i Hours", hours},
			{ "%i Min", "%i Minutes", minutes},
			{ "%i Sec", "%i Seconds", seconds},
		}
	if noSeconds or seconds == 0 then  -- remove the seconds format if no seconds
		table.remove(formats, 4)
	end

	for i = 1,#formats do
		if (#outArray < maxCount) and (((formats[i][3] > 0) or includeZero)) then
			table.insert( outArray,
					string.format( formats[i][(notAbbreviated and 2 or 1)], formats[i][3] )
			)
			includeZero = true  -- include subsequent 0 values
		end
	end
	return( table.concat( outArray, " " ) )
end
C_AuctionHouse = {}
C_AuctionHouse.PostCommodity = function( ... ) end
C_AuctionHouse.PostItem = function( ... ) end
max = math.max
min = math.min
format = string.format
time = os.time
date = os.date
unpack = table.unpack
Frame = {
		["__isShown"] = true,
		["Events"] = {},
		["Hide"] = function( self ) self.__isShown = false; end,
		["Show"] = function( self ) self.__isShown = true; end,
		["IsVisible"] = function( self ) return( self.__isShown ) end,
		["RegisterEvent"] = function(self, event) self.Events[event] = true; end,
		["SetPoint"] = function() end,
		["UnregisterEvent"] = function(self, event) self.Events[event] = nil; end,
		["GetName"] = function(self) return self.framename end,
		["SetFrameStrata"] = function() end,
		["SetWidth"] = function(self, value) self.width = value; end,
		["SetHeight"] = function(self, value) self.height = value; end,
		["CreateFontString"] = function(self, ...) return(CreateFontString(...)) end,
		["GetValue"] = function( self, ... ) return(0); end,

		["SetMinMaxValues"] = function() end,
		["SetValue"] = function() end,
		["SetStatusBarColor"] = function() end,
		["SetScript"] = function() end,
		["SetAttribute"] = function() end,
}
FrameGameTooltip = {
		["HookScript"] = function( self, callback ) end,
		["GetName"] = function(self) return self.name end,
		["SetOwner"] = function(self, newOwner) end, -- this is only for tooltip frames...
		["ClearLines"] = function(self) end, -- this is only for tooltip frames...
		["SetHyperlink"] = function(self, hyperLink) end, -- this is only for tooltip frames...
		["init"] = function(frameName)
			_G[frameName.."TextLeft2"] = CreateFontString(frameName.."TextLeft2")
			_G[frameName.."TextLeft3"] = CreateFontString(frameName.."TextLeft3")
			_G[frameName.."TextLeft4"] = CreateFontString(frameName.."TextLeft4")
		end,
}
function CreateFrame( frameType, frameName, parentFrame, inheritFrame )
--	print("CreateFrame: needing a new frame of type: "..(frameType or "nil"))
	newFrame = {}
	for k,v in pairs( Frame ) do
		newFrame[k] = v
	end
	if frameType and _G["Frame"..frameType] then  -- construct the name of the table to pull from, use _G to reference it.
		for k, f in pairs(_G["Frame"..frameType]) do  -- add the methods in the sub frame to the returned frame
			if k == "init" then  -- check to see if the key is 'init', which is a function to run when creating the Frame
				f(frameName)  -- run the ["init"] function
			else
				newFrame[k] = f  -- add the method to the frame
			end
		end
	end
	frameName = newFrame
	--http://www.wowwiki.com/API_CreateFrame
	return newFrame
end
function CreateFontString( name, ... )
	--print("Creating new FontString: "..name)
	FontString = {}
	--	print("1")
	for k,v in pairs(Frame) do
		FontString[k] = v
	end
	FontString.text = ""
	FontString["SetText"] = function(self,text) self.text=text; end
	FontString["GetText"] = function(self) return(self.text); end
	FontString.name=name
	--print("FontString made?")
	return FontString
end
function CreateStatusBar( name, ... )
	StatusBar = {}
	for k,v in pairs(Frame) do
		StatusBar[k] = v
	end
	StatusBar.name=name

	StatusBar["SetMinMaxValues"] = function() end;
	StatusBar["Show"] = function() end;

	return StatusBar
end
function DecolorText( textIn )
	textIn = string.gsub( textIn, "|c%x%x%x%x%x%x%x%x", "" )
	textIn = string.gsub( textIn, "|r", "" )
	return( textIn )
end

-- Create needed frames
RestedFrame = CreateFrame( "Frame", "RestedFrame" )
RestedUIFrame = CreateFrame( "Frame", "RestedUIFrame" )
RestedUIFrame_TitleText = CreateFontString( "RestedUIFrame_TitleText" )
RestedScrollFrame_VSlider = CreateFrame( "Frame", "RestedScrollFrame_VSlider" )
UIDropDownMenu_SetText = function() end

-- Work down the parameters
srcFilePath = ParsePath( arg[0], pathSeparator )
tocFile = srcFilePath..pathSeparator.."Rested.toc"

accountPath = arg[1]
if( accountPath ) then
	-- remove 'extra' separators from the end of the given path
	while (string.sub( accountPath, -1, -1 ) == pathSeparator) do
		accountPath = string.sub( accountPath, 1, -2 )
	end
	-- append the expected location of the datafile
	dataFilePath = {
		accountPath,
		"SavedVariables",
		"Rested.lua"
	}
	dataFile = table.concat( dataFilePath, pathSeparator )
end

if( tocFile and FileExists( tocFile ) and
		accountPath and dataFile and FileExists( dataFile ) ) then
	tocFileTable = TableFromTOC( tocFile )
	package.path = srcFilePath..pathSeparator.."?.lua;" .. package.path
	for _,f in pairs( tocFileTable ) do
		require( f )
	end
	-- Call init Functions
	Rested.showNumBars = 50
	Rested.UIBuildBars()
	DoFile( dataFile )

	-- MaxLevel from the data file
	Rested.maxLevel = Rested_misc["maxLevel"]
	Rested.ForAllChars( Rested.UpdateIgnore, true )

	-- command List
	if not arg[2] then arg[2] = "resting"; end
	reportsTable = {table.unpack( arg, 2 )}
	for _, report in pairs( reportsTable ) do
		RestedUIFrame_TitleText:SetText( report.." Report is Empty" )

		if Rested.commandList and report then
			if( Rested.commandList[report] ) then
				Rested.commandList[report].func()
			end
			print( RestedUIFrame_TitleText:GetText() )
			for i, bar in pairs( Rested.bars ) do
				textOut = bar.text:GetText()
				if( #textOut > 0 ) then
					print( DecolorText( textOut ) )
				end
			end
		end
	end
else
	io.stderr:write( "Something is wrong.  Lets review:\n\n" )
	io.stderr:write( "Usage: Rested_Online.lua <AccountPath> [report name list]\n" )
	io.stderr:write( "[report name list] defaults to \"resting\"\n\n" )
	io.stderr:write( "Version            : 3.6.1\n" )
	io.stderr:write( "TOC file           : "..( tocFile or "False" ).."\n" )
	io.stderr:write( "TOC file found     : "..( FileExists( tocFile ) and " True" or "False" ).."\n" )
	io.stderr:write( "Account Path given : "..( accountPath and " True" or "False" ).."\n" )
	if not accountPath then
		io.stderr:write( "Please provide the path to the WTF/Account/<yourAccount>\n" )
	end
	io.stderr:write( "Data file          : "..( dataFile or "False" ).."\n" )
	io.stderr:write( "Data file exists   : "..( FileExists( dataFile ) and " True" or "False" ).."\n" )
end
