﻿-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

load("/data/general/objects/objects-maj-eyal.lua")

for i = 1, 5 do
newEntity{ base = "BASE_LORE",
	define_as = "NOTE"..i,
	name = "daikara expedition note", lore="daikara-note-"..i,
	kr_display_name = "다이카라 탐험대의 기록",
	desc = [[어떤 모험가가 남긴 종이 조각입니다.]],
	rarity = false,
	encumberance = 0,
}
end

newEntity{ base = "BASE_RUNE", define_as = "RUNE_RIFT",
	power_source = {arcane=true},
	name = "Rune of the Rift", unique = true, identified = true, image = "object/artifact/rune_of_the_rift.png",
	kr_display_name = "균열의 룬",
	rarity = false,
	cost = 100,
	material_level = 3,

	inscription_data = {
		cooldown = 14,
	},
	inscription_talent = "RUNE_OF_THE_RIFT",
}
