-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2015 Nicolas Casalini
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

--32 chambers
startx = 0
starty = 1

setStatusAll{no_teleport=true}
rotates = {"default", "90", "180", "270", "flipx", "flipy"}
defineTile('%', "WALL")
defineTile('.', "FLOOR")
defineTile('#', "HARDWALL")
defineTile('X', "DOOR_VAULT")
defineTile('*', "FLOOR", {random_filter={type="gem"}})
defineTile('L', "FLOOR", {random_filter={add_levels=15, tome_mod="gvault"}})
defineTile('D', "FLOOR", nil, {random_filter={name="greater multi-hued wyrm", add_levels=30}})
defineTile('c', "FLOOR", {random_filter={add_levels=15, tome_mod="vault"}}, {random_filter={add_levels=20}})

return {

[[#########################]],
[[X.c#..%..%..%..#L*#..#*L#]],
[[#..#.c#.c#.c#.c#*D%.c%D*#]],
[[##%##%#######%######%####]],
[[#..#..#..%..%..#..%..#..#]],
[[#.c%.c#.c#.c#.c#.c#.c%.c#]],
[[########%########%#####%#]],
[[#..%..#..#LL#..%..#..#..#]],
[[#.c#.c%.c#DD#.c#.c#.c%.c#]],
[[##%########%##%##########]],
[[#..%..%..%..#..%..%..#..#]],
[[#.c#.c#.c#.c#.c#.c#.c%.cX]],
[[#########################]],

}