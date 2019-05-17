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


Rested.EventCallback( "UNIT_INVENTORY_CHANGED", Rested.SaveProfessionInfo )
Rested.EventCallback( "PLAYER_ENTERING_WORLD", Rested.SaveProfessionInfo )

table.insert( Rested.filterKeys, "prof1" )
table.insert( Rested.filterKeys, "prof2" )
table.insert( Rested.filterKeys, "prof3" )
table.insert( Rested.filterKeys, "prof4" )
table.insert( Rested.filterKeys, "prof5" )


--[[

prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
^^^^ Indexes to be passed to:

name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset,
    skillLine, skillModifier, specializationIndex,
    specializationOffset = GetProfessionInfo(index)


This also seems to return some kind of data on the talent trees and guild perks.

Skill Line may be useful in internationalization using the number to check the profession rather than the text (which changes with localization).

The skill lines known are: Archaeology (794), Alchemy (171), Blacksmith (164), Cooking (184), Enchanting (333), Engineer (202), First Aid (129), Fishing (356), Herbalism (182), Inscription (773), Jewelcrafting (755), Leatherworking (165), Mining (186), Skinning (393), and Tailoring (197).

Alchemy Specializations known are: Elixir (2), Potion (3), Transmute (4)

]]