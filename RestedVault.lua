-- RestedVault.lua
Rested.vaultActivities = { { 3, "Raid" }, { 1, "Dungeon" }, { 6, "World" } }

function Rested.Rewards_Update( ... )
	-- print( "WEEKLY_REWARDS_UPDATE:" )
	Rested.me.weeklyRewards = ( C_WeeklyRewards.HasAvailableRewards() or nil )
	-- print( "Has Available Rewards: "..(Rested.me.weeklyRewards and "True" or "False"))
	countActivities, Rested.maxActivities, count = {}, 0, 0
	for _, struct in ipairs( Rested.vaultActivities ) do
		local type, name = unpack( struct )
		activityInfo = C_WeeklyRewards.GetActivities( tonumber( type ) )
		for level, info in ipairs( activityInfo ) do
			Rested.maxActivities = Rested.maxActivities + 1
			if info.progress >= info.threshold then
				countActivities[name] = countActivities[name] and countActivities[name] + 1 or 1
				count = count + 1
			end
			if info.progress > 0 and info.progress < info.threshold then
				--  print( string.format( "Vault %s Rewards Rank %d: %i/%i", name, info.index, info.progress, info.threshold ) )
			end
		end
	end
	if count > 0 then
		Rested.me.weeklyActivity = countActivities
		Rested.me.weeklyResetAt = Rested.GetWeeklyQuestResetTime()
		-- print( "Weekly reset happens at: "..date( "%c", Rested.me.weeklyResetAt ) )
		Rested.autoCloseAfter = Rested_options.nagTimeOut and time()+Rested_options.nagTimeOut or nil
	end
	if Rested.me.weeklyRewards then
		Rested.Command( "vault" )
	end
end

function Rested.GetWeeklyQuestResetTime()
	local now = time()
	local region = GetCurrentRegion()
	local dayOffset = { 2, 1, 0, 6, 5, 4, 3 }
	local regionDayOffset = { { 2, 1, 0, 6, 5, 4, 3 }, { 4, 3, 2, 1, 0, 6, 5 }, { 3, 2, 1, 0, 6, 5, 4 }, { 4, 3, 2, 1, 0, 6, 5 }, { 4, 3, 2, 1, 0, 6, 5 } }
	local nextDailyReset = GetQuestResetTime()
	local utc = date( "!*t", now + nextDailyReset )
	local reset = regionDayOffset[region][utc.wday] * 86400 + now + nextDailyReset

	return reset, reset-604800
end

function Rested.Rewards_ItemChanged( ... )
	print( "WEEKLY_REWARDS_ITEM_CHANGED:" )
end

function Rested.CurrentWeekly_to_Rewards( realm, name, charStruct )
	if charStruct.weeklyResetAt and charStruct.weeklyResetAt <= Rested.previousWeekReset and charStruct.weeklyActivity then
		charStruct.weeklyRewards = true
		charStruct.weeklyResetAt = nil
		charStruct.weeklyActivity = nil
	end
end

-- function Rested.Rewards_Hide( ... )
-- 	print( "WEEKLY_REWARDS_HIDE:" )
-- end

Rested.EventCallback( "WEEKLY_REWARDS_UPDATE", Rested.Rewards_Update )
Rested.EventCallback( "ZONE_CHANGED_NEW_AREA", Rested.Rewards_Update )
Rested.EventCallback( "WEEKLY_REWARDS_ITEM_CHANGED", Rested.Rewards_ItemChanged )
-- Rested.EventCallback( "WEEKLY_REWARDS_HIDE", Rested.Rewards_Hide )

Rested.InitCallback( function()
		C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
		WeeklyRewardsFrame:Show()
		_, Rested.previousWeekReset = Rested.GetWeeklyQuestResetTime()
		Rested.ForAllChars( Rested.CurrentWeekly_to_Rewards, true )
		WeeklyRewardsFrame:Hide()
	end
)

function Rested.VaultHasRewards( realm, name, struct )
	returnStruct = {}
	reminderTime = time() + 60
	if( not returnStruct[reminderTime] ) then
		returnStruct[reminderTime] = {}
	end
	if( struct.weeklyRewards ) then
		table.insert( returnStruct[reminderTime],
				string.format( "%s has unclaimed vault items.",
							Rested.FormatName( realm, name ), 1
				)
		)
	end
	return returnStruct
end

Rested.ReminderCallback( Rested.VaultHasRewards )

Rested.dropDownMenuTable["Vault"] = "vault"
Rested.commandList["vault"] = { ["help"] = {"","Show vault info"}, ["func"] = function()
		Rested.reportName = "Vault Report"
		Rested.UIShowReport( Rested.VaultReport )
	end
}

function Rested.VaultReport( realm, name, charStruct )
	local rn = Rested.FormatName( realm, name )
	if charStruct.weeklyRewards then
		table.insert( Rested.charList, { 150, "Claim: "..rn } )
		return 1
	elseif charStruct.weeklyActivity then
		local rewardCount = {}
		table.insert( Rested.charList, {
				((charStruct.weeklyActivity[Rested.vaultActivities[1][2]] or 0)
					+ (charStruct.weeklyActivity[Rested.vaultActivities[2][2]] or 0)
					+ (charStruct.weeklyActivity[Rested.vaultActivities[3][2]] or 0))
					* (150 / Rested.maxActivities),
				string.format( "%i/%i/%i: %s",
						(charStruct.weeklyActivity[Rested.vaultActivities[1][2]] or 0),
						(charStruct.weeklyActivity[Rested.vaultActivities[2][2]] or 0),
						(charStruct.weeklyActivity[Rested.vaultActivities[3][2]] or 0), rn
				)}
		)
		return 1
	end
end

Rested.maxActivities = 9
