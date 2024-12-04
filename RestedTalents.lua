-- RestedTalents.lua
RESTED_SLUG, Rested = ...

function Rested.TalentsGetStr()
	local activeConfigID = C_ClassTalents.GetActiveConfigID()
	if activeConfigID then
		local importString = C_Traits.GenerateImportString(activeConfigID)

		Rested.me.talentName = C_Traits.GetConfigInfo(activeConfigID).name
		Rested.me.talentHash = importString
	end
end

Rested.EventCallback( "SPELLS_CHANGED", Rested.TalentsGetStr )
Rested.EventCallback( "TRAIT_CONFIG_UPDATED", Rested.TalentsGetStr )

table.insert( Rested.CSVFields, {"TalentName", "talentName"} )
table.insert( Rested.CSVFields, {"TalentString", "talentHash"} )
