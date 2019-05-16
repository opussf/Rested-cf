-- RestediLvl.lua

-- function
function Rested.GetILvl()
	Rested.lastiLvlScan = Rested.lastiLvlScan or time() + 5  -- give it a 5 second grace period at startup.
	if( Rested.lastiLvlScan+1 <= time() ) then
		Rested.lastiLvlScan = time()
		local currentiLvl = select( 2, GetAverageItemLevel() )
		Rested_restedState[Rested.realm][Rested.name].iLvl = math.floor( currentiLvl )
		Rested_misc["maxiLvl"] = math.max( Rested_misc["maxiLvl"] or 0, math.floor( currentiLvl ) )
		--print( "iLvl is now: "..currentiLvl )
	end
end

Rested.EventCallback( "UNIT_INVENTORY_CHANGED", Rested.GetILvl )


Rested.dropDownMenuTable["iLvl"] = "ilvl"
Rested.commandList["ilvl"] = { ["help"] = {"","Show iLvl report"}, ["func"] = function()
		Rested.reportName = "Item Level"
		Rested.UIShowReport( Rested.iLevelReport )
	end
}
function Rested.iLevelReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	Rested_misc["maxiLvl"] = math.max( Rested_misc["maxiLvl"] or 0, math.floor( charStruct.iLvl ) )
	Rested.strOut = string.format( "%d :: %d :: %s",
			charStruct.iLvl or 0,
			charStruct.lvlNow,
			rn )
	table.insert( Rested.charList, {((charStruct.iLvl or 0) / Rested_misc["maxiLvl"]) * 150, Rested.strOut} )
	return 1
end

--[[



function Rested.ScanInv()
	Rested_options.iLvlHistory = Rested_options.iLvlHistory or {};
	Rested.lastScan = Rested.lastScan or time()+10;
	Rested.scanCount = Rested.scanCount or 0;
	--Rested.Print("lastScan ::"..(Rested.lastScan+5).."<:"..time());
	if (Rested.lastScan+1 <= time()) then
		Rested.lastScan=time();
		--Rested.Print(Rested.realm..":"..Rested.name);
		Rested.scanCount = Rested.scanCount + 1;
		local currentVal = select( 2, GetAverageItemLevel() )
		Rested_restedState[Rested.realm][Rested.name].iLvl = math.floor(currentVal);
		Rested_options["maxiLvl"] = math.max(Rested_options["maxiLvl"] or 0, math.floor(currentVal));

		Rested_options.iLvlHistory[Rested.lastScan] = currentVal;
		local timeCutOff = time() - Rested_options.iLvlMaxAge;  -- one hour

		-- Calculate stats for display
		local sum,min,minTS,ave,max,count,delcount,vm,sd = 0,nil,nil,0,0,0,0,0,0;
		local currValCount = 0;
		for ts, value in pairs(Rested_options.iLvlHistory) do
			if (value == currentVal) then currValCount = currValCount + 1; end
			if (ts > timeCutOff) then
				sum = sum + value;
				min = math.min(value,min or value);
				max = math.max(value,max);
				minTS = math.min(ts,minTS or ts);
				count = count + 1;
			else
				Rested_options.iLvlHistory[ts]=nil;
				delcount = delcount + 1;
			end
		end
		ave = sum/count;
		sum = 0;
		for _,value in pairs(Rested_options.iLvlHistory) do
			vm = value - ave;
			sum = sum + (vm * vm);
		end
		sd = (count > 1) and math.sqrt( sum / (count-1) ) or 0;
		local sdColor = "|cffffffff";
		if Rested.lastSD then
			if (sd > Rested.lastSD) then sdColor = COLOR_RED; end
			if (sd < Rested.lastSD) then sdColor = COLOR_GREEN; end
		end
		Rested.lastSD = sd;

		local currentColor = Rested.GetColorFromRange( currentVal, ave, 2*sd);
		local minColor = Rested.GetColorFromRange(min, ave, 2*sd);
		local maxColor = Rested.GetColorFromRange(max, ave, 2*sd);

		RestediLvlFrame:Show()
		RestediLvl_PositiveSD:SetMinMaxValues( min, max )
		RestediLvl_Ave:SetMinMaxValues( min, max )
		RestediLvl_NegativeSD:SetMinMaxValues( min, max )

		RestediLvl_PositiveSD:SetValue( ave+sd )
		RestediLvl_Ave:SetValue( ave )
		RestediLvl_NegativeSD:SetValue( ave-sd )

		local strOut = format("iLvl: %s%i|r (%s%i|r / %i / %s%i|r / %s%0.2f%s) %i/%i/-%i (%s) %0.2f%%",
				currentColor, math.floor(currentVal),
				minColor,min,ave,
				maxColor,max,
				sdColor,sd,COLOR_END,
				--Rested.scanCount,
				currValCount,
				count, delcount,
				date("%H:%M", time()+(minTS-timeCutOff) ),
				(currValCount/count)*100 );
		RestediLvl_String:SetText( strOut )
		--Rested.Print(time().." + ("..minTS.." - "..timeCutOff..") = "..(time()+(minTS-timeCutOff)))
		--Rested.Print( strOut, false )
	end
end


]]