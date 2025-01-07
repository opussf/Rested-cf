-- RestedProfessions.lua

function Rested.SaveProfessionInfo()
	local profs = {GetProfessions()}

	for num, index in pairs( profs ) do
		name, _, skillLevel, maxSkillLevel = GetProfessionInfo( index )
		--print( index..":".." -> "..( name or "nil" ).." ("..skillLevel.."/"..maxSkillLevel..")" )
		Rested.me["prof"..num] = name
		Rested.me["prof"..num.."skill"] = skillLevel
		Rested.me["prof"..num.."maxSkill"] = maxSkillLevel
	end
end
function Rested.ScanTradeSkill()
	local recipeTable = C_TradeSkillUI.GetAllRecipeIDs()
	local recipeInfoTable = {}
	local categoryInfoTable = {}
	Rested.tradeskillCategorys = Rested.tradeskillCategorys or {}

	for _,recipeID in pairs( recipeTable ) do
		cdSeconds, hasCD, num3, num4 = C_TradeSkillUI.GetRecipeCooldown( recipeID )
		-- 1=secondsLeft / nil, 2=False/true, 3 = 0, 4= 0
		if cdSeconds then
			recipeInfoTable = C_TradeSkillUI.GetRecipeInfo( recipeID )
			categoryInfoTable = C_TradeSkillUI.GetCategoryInfo( recipeInfoTable.categoryID, categoryInfoTable )

			rLink = C_TradeSkillUI.GetRecipeItemLink( recipeID )
			Rested.me["tradeCD"] = Rested.me["tradeCD"] or {}
			Rested.me.tradeCD[recipeID] = {["cdTS"] = math.floor(cdSeconds + time()), ["category"] = recipeInfoTable.name }
		end
	end
end
function Rested.PruneTradeSkill()
	if Rested.me.tradeCD then
		local count = 0
		for k, v in pairs( Rested.me.tradeCD ) do
			if( v.cdTS < time() ) then
				Rested.me.tradeCD[k] = nil
			else
				count = count + 1
			end
		end
		if count == 0 then
			Rested.me.tradeCD = nil
		end
	end
end

Rested.EventCallback( "UNIT_INVENTORY_CHANGED", Rested.SaveProfessionInfo )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveProfessionInfo )
Rested.EventCallback( "TRADE_SKILL_LIST_UPDATE", Rested.ScanTradeSkill )
Rested.EventCallback( "PLAYER_LEAVING_WORLD", Rested.PruneTradeSkill )

table.insert( Rested.filterKeys, "prof1" )
table.insert( Rested.filterKeys, "prof2" )
table.insert( Rested.filterKeys, "prof3" )
table.insert( Rested.filterKeys, "prof4" )
table.insert( Rested.filterKeys, "prof5" )

Rested.dropDownMenuTable["Prof CD"] = "cooldowns"
Rested.commandList["cooldowns"] = { ["help"] = {"","Profession Cooldowns"}, ["func"] = function()
		Rested.reportName = "Cooldowns"
		Rested.UIShowReport( Rested.Cooldowns )
	end,
	["desc"] = {""},
}

function Rested.Cooldowns( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	local count = 0
	if( charStruct.tradeCD ) then
		local recipeSum = {}
		for recipeID, struct in pairs( charStruct.tradeCD ) do
			recipeSum[struct.category] = recipeSum[struct.category] or
					{ ["pc"] = ( ( 86400 - ( struct.cdTS - time() ) ) / 86400 ) * 150,
					["ts"] = struct.cdTS,
					["count"] = 0 }

			recipeSum[struct.category].count = recipeSum[struct.category].count + 1
		end
		for category, struct in pairs( recipeSum ) do
			secondsToGo = struct.ts - time()
			Rested.strOut = string.format( "%s : %s :: %s",
					(secondsToGo > 0 and SecondsToTime( secondsToGo ) or COLOR_RED..date( "%m/%d %H:%M", struct.ts )..COLOR_END),
					category,
					rn )
			table.insert( Rested.charList,
					{ struct.pc, Rested.strOut } )
			count = count + 1
		end
		return count
	end
end

function Rested.ReminderCooldowns( realm, name, charStruct )
	returnStruct = {}
	if( charStruct.tradeCD ) then
		local recipeSum = {}
		for recipeID, struct in pairs( charStruct.tradeCD ) do
			recipeSum[struct.category] = struct.cdTS
		end
		for category, cdTS in pairs( recipeSum ) do
			if( not returnStruct[cdTS] ) then
				returnStruct[cdTS] = {}
			end
			table.insert( returnStruct[cdTS],
					string.format( "%s has available cooldowns for %s", Rested.FormatName( realm, name, false ), category ) )
		end
	end
	return returnStruct
end
Rested.ReminderCallback( Rested.ReminderCooldowns )
-----------
-- Concentration
-----------
Rested.ProfNameMap = {
	["Khaz Algar"] = "Khaz",
	["Dragon Isles"] = "Dragon"
}
function Rested.GetConcentration()
	-- Rested.Print( "GetConcentration()" )
	local professionInfos = C_TradeSkillUI.GetChildProfessionInfos()
	for i, professionInfo in pairs( professionInfos ) do
		local concentrationCurrencyID = C_TradeSkillUI.GetConcentrationCurrencyID( professionInfo.professionID )
		if concentrationCurrencyID and concentrationCurrencyID>0 then
			local currencyInfo = C_CurrencyInfo.GetCurrencyInfo( concentrationCurrencyID )
			profName = professionInfo.professionName
			for long, short in pairs( Rested.ProfNameMap ) do
				profName = string.gsub( profName, long, short )
			end
			-- Rested.Print( profName..": "..currencyInfo.quantity.." of "..currencyInfo.maxQuantity )
			Rested.me.concentration = Rested.me.concentration or {}
			Rested.me.concentration[profName] = Rested.me.concentration[profName] or {}
			Rested.me.concentration[profName].max = currencyInfo.maxQuantity

			if Rested.me.concentration[profName].value ~= currencyInfo.quantity then
				Rested.me.concentration[profName].ts = time()
			else
				Rested.me.concentration[profName].ts = Rested.me.concentration[profName].ts or time()
			end
			Rested.me.concentration[profName].value = currencyInfo.quantity
		end
	end
	local knownProfs = {}
	for num, index in pairs( {GetProfessions()} ) do -- index is the profession number, num is 1,2
		name = GetProfessionInfo( index )
		if name then table.insert( knownProfs, name ) end-- add Name
	end
	local count = 0
	if knownProfs[1] and knownProfs[1] ~= nil and Rested.me.concentration then
		for profName, _ in pairs( Rested.me.concentration ) do
			found = false
			for _, searchTerm in pairs( knownProfs ) do
				if searchTerm and string.find( profName, searchTerm ) then found = true end
			end
			if not found then
				Rested.me.concentration[profName] = nil
			else
				count = count + 1
			end
		end
	end
	if count == 0 then
		Rested.me.concentration = nil
	end
end
Rested.ConcentrationRateGain = 1/360  -- 1 per 6 min
function Rested.ProfConcentrationReport( realm, name, charStruct )
	local count = 0
	if( charStruct.concentration ) then
		for profName, struct in pairs( charStruct.concentration ) do
			if struct.value < struct.max then
				local needToMax = struct.max - struct.value
				local timeToMax = struct.ts + ( needToMax / Rested.ConcentrationRateGain )
				local timeSince = time() - struct.ts
				local current = math.min( struct.max, math.floor( struct.value + (timeSince * Rested.ConcentrationRateGain) ) )
				table.insert( Rested.charList, { ( current / struct.max ) * 150,
						string.format( "%4i: %s%s :: %s",
							current,
							(struct.max > current and SecondsToTime( (struct.max - current) / Rested.ConcentrationRateGain ).." " or ""),
							profName, Rested.FormatName( realm, name ) ) } )
				count = count + 1
			else
				local timeSince = time() - struct.ts
				local timeOut = 86400 * 2
				if timeSince < timeOut then
					table.insert( Rested.charList, { ( timeSince / timeOut ) * 150,
							string.format( "%4i: %s :: %s",
								struct.max, profName, Rested.FormatName( realm, name ) ) } )
					count = count + 1
				end
			end
		end
	end
	return count
end
Rested.EventCallback( "TRADE_SKILL_LIST_UPDATE", Rested.GetConcentration )
Rested.EventCallback( "TRADE_SKILL_NAME_UPDATE", Rested.GetConcentration )

Rested.dropDownMenuTable["Prof Conc"] = "conc"
Rested.commandList["conc"] = { ["help"] = {"","Profession concentration"}, ["func"] = function()
		Rested.reportName = "Prof Concentration"
		Rested.UIShowReport( Rested.ProfConcentrationReport )
	end
}

function Rested.ProfConcentrationReminders( realm, name, charStruct )
	returnStruct = {}
	if charStruct.concentration then
		for profName, profStruct in pairs( charStruct.concentration ) do
			currentQuantity = math.min( profStruct.value + ((time() - profStruct.ts) * Rested.ConcentrationRateGain), profStruct.max )
			fullPercent = currentQuantity / profStruct.max
			returnStruct[time()+15] = returnStruct[time()+15] or {}
			if currentQuantity >= profStruct.max then
				table.insert( returnStruct[time()+15], Rested.FormatName( realm, name ).." has full "..profName.." concentration." )
			elseif fullPercent > 0.75 then
				table.insert( returnStruct[time()+15], Rested.FormatName( realm, name ).." has more than 75% "..profName.." concentration." )
			elseif fullPercent > 0.5 then
				table.insert( returnStruct[time()+15], Rested.FormatName( realm, name ).." has more than half "..profName.." concentration." )
			end
			for targetQuantity = profStruct.value, profStruct.max do
				if targetQuantity % 100 == 0 then
					secondsAtTarget = profStruct.ts + ((targetQuantity-profStruct.value) / Rested.ConcentrationRateGain)
					if secondsAtTarget > time() then
						returnStruct[secondsAtTarget] = returnStruct[secondsAtTarget] or {}
						table.insert( returnStruct[secondsAtTarget], Rested.FormatName( realm, name ).." has "..targetQuantity.." "..profName.." concentration." )
					end
				end
			end
		end
	end
	return returnStruct
end

Rested.ReminderCallback( Rested.ProfConcentrationReminders )
