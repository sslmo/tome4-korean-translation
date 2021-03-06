﻿-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2014 Nicolas Casalini
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

-- Thought Forms really only differ in the equipment they carry, the talents they have, and stat weights
-- cancelThoughtForms is in psionic.lua since it's used a few other places
-- Here we'll use a few functions to build them.

-- Build our tile from the summoners tile
local function buildTile(e) 
	if e.summoner.female then
		e.female = true
	end
	e.image = e.summoner.image
	e.moddable_tile = e.summoner.moddable_tile and e.summoner.moddable_tile or nil
	e.moddable_tile_base = e.summoner.moddable_tile_base and e.summoner.moddable_tile_base or nil
	e.moddable_tile_ornament = e.summoner.moddable_tile_ornament and e.summoner.moddable_tile_ornament or nil
	if e.summoner.image == "invis.png" and e.summoner.add_mos then
		local summoner_image, summoner_h, summoner_y = e.summoner.add_mos[1].image or nil, e.summoner.add_mos[1].display_h or nil, e.summoner.add_mos[1].display_y or nil
		if summoner_image and summoner_h and summoner_y then
			e.add_mos = {{image=summoner_image, display_h=summoner_h, display_y=summoner_y}}
		end
	end
end

-- Set up our act function so we don't run all over the map
local function setupAct(self)
	self.on_act = function(self)
		local tid = self.summoning_tid
		if not game.level:hasEntity(self.summoner) or self.summoner.dead or not self.summoner:isTalentActive(tid) then
			self:die(self)
		end
		if game.level:hasEntity(self.summoner) and core.fov.distance(self.x, self.y, self.summoner.x, self.summoner.y) > 10 then
			local Map = require "engine.Map"
			local x, y = util.findFreeGrid(self.summoner.x, self.summoner.y, 5, true, {[engine.Map.ACTOR]=true})
			if not x then
				return
			end
			-- Clear it's targeting on teleport
			self:setTarget(nil)
			self:move(x, y, true)
			game.level.map:particleEmitter(x, y, 1, "generic_teleport", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})
		end
	end
end

-- And our die function to make sure our sustain is disabled properly
local function setupDie(self)
	self.on_die = function(self)
		local tid = self.summoning_tid
		game:onTickEnd(function() 
			if self.summoner:isTalentActive(tid) then
				self.summoner:forceUseTalent(tid, {ignore_energy=true})
			end
			if self.summoner:isTalentActive(self.summoner.T_OVER_MIND) then
				self.summoner:forceUseTalent(self.summoner.T_OVER_MIND, {ignore_energy=true})
			end
		end)
		-- Pass our summoner back as the target if we're controlled...  to prevent super cheese.
		if game.player == self then
			local tg = {type="ball", radius=10}
			self:project(tg, self.x, self.y, function(tx, ty)
				local target = game.level.map(tx, ty, engine.Map.ACTOR)
				if target and target.ai_target.actor == self then
					target:setTarget(self.summoner)
				end
			end)
		end
	end
end

-- Build our thought-form
function setupThoughtForm(self, m, x, y, t)
	-- Set up some basic stuff
	m.display = "p"
	m.blood_color = colors.YELLOW
	m.type = "thought-form"
	m.subtype = "thought-form"
	m.summoner_gain_exp=true
	m.faction = self.faction
	m.no_inventory_access = true
	m.rank = 2
	m.size_category = 3
	m.infravision = 10
	m.lite = 1
	m.no_breath = 1
	m.move_others = true

	-- Less tedium
	m.life_regen = 1
	m.stamina_regen = 1

	-- Make sure we don't gain anything from leveling
	m.autolevel = "none"
	m.unused_stats = 0
	m.unused_talents = 0
	m.unused_generics = 0
	m.unused_talents_types = 0
	m.exp_worth = 0
	m.no_points_on_levelup = true
	m.silent_levelup = true
	m.level_range = {self.level, self.level}

	-- Try to use stored AI talents to preserve tweaking over multiple summons
	m.ai_talents = self.stored_ai_talents and self.stored_ai_talents[m.name] or {}
	m.save_hotkeys = true

	-- Inheret some attributes
	if self:getTalentLevel(self.T_OVER_MIND) >=5 then
		m.inc_damage.all = (m.inc_damage.all) or 0 + (self.inc_damage.all or 0) + (self.inc_damage[engine.DamageType.MIND] or 0)
	end
	if self:getTalentLevel(self.T_OVER_MIND) >=3 then
		local save_bonus = self:combatMentalResist(fake)
		m:attr("combat_physresist", save_bonus)
		m:attr("combat_mentalresist", save_bonus)
		m:attr("combat_spellresist", save_bonus)
	end

	-- Add them to the party
	if game.party:hasMember(self) then
		m.remove_from_party_on_death = true
		game.party:addMember(m, {
			control="no",
			type="thought-form",
			title="thought-form", kr_title="생각의 구현",
			orders = {target=true, leash=true, anchor=true, talents=true},
		})
	end
	
	-- Build our act and die functions
	m.summoning_tid = t.id
	setupAct(m); setupDie(m)
	
	-- Add the thought-form to the level
	m:resolve() m:resolve(nil, true)
	m:forceLevelup(self.level)
	game.zone:addEntity(game.level, m, "actor", x, y)
	game.level.map:particleEmitter(x, y, 1, "generic_teleport", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})

	-- Summons never flee
	m.ai_tactic = m.ai_tactic or {}
	m.ai_tactic.escape = 0
	if self.name == "thought-forged bowman" then
		m.ai_tactic.safe_range = 2
	end
end

-- Thought-forms
newTalent{
	name = "Thought-Form: Bowman",
	kr_name = "생각의 구현 : 궁수",
	short_name = "TF_BOWMAN",
	type = {"psionic/other", 1},
	points = 5, 
	require = psi_wil_req1,
	sustain_psi = 20,
	mode = "sustained",
	no_sustain_autoreset = true,
	cooldown = 24,
	range = 10,
	no_unlearn_last = true,
	getStatBonus = function(self, t) 
		local t = self:getTalentFromId(self.T_THOUGHT_FORMS)
		return t.getStatBonus(self, t)
	end,
	activate = function(self, t)
		cancelThoughtForms(self, t.id)
		
		-- Find space
		local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "소환할 공간이 없습니다!")
			return
		end
		
		-- Do our stat bonuses here so we only roll for crit once	
		local stat_bonus = math.floor(self:mindCrit(t.getStatBonus(self, t)))
	
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			name = "thought-forged bowman", summoner = self,
			kr_name = "생각의 구현 궁수",
			color=colors.SANDY_BROWN, shader = "shadow_simulacrum",
			shader_args = { color = {0.8, 0.8, 0.8}, base = 0.8, time_factor = 4000 },
			desc = [[생각의 구현으로 만들어진 궁수입니다. 언제든지 전투에 임할 수 있을 것 같습니다.]],
			body = { INVEN = 10, MAINHAND = 1, BODY = 1, QUIVER=1, HANDS = 1, FEET = 1},

			ai = "summoned", ai_real = "tactical",
			ai_state = { ai_move="move_complex", talent_in=3, ally_compassion=10 },
			ai_tactic = resolvers.tactic("ranged"),
			
			max_life = resolvers.rngavg(100,110),
			life_rating = 12,
			combat_armor = 0, combat_def = 0,
			stats = { mag=self:getMag(), wil=self:getWil(), cun=self:getCun()},
			inc_stats = {
				str = stat_bonus / 2,
				dex = stat_bonus,
				con = stat_bonus / 2,
			},
			
			resolvers.generic(function(e) buildTile(e) end), -- Make a moddable tile
			resolvers.talents{ 
				[Talents.T_WEAPON_COMBAT]= math.ceil(self.level/10),
				[Talents.T_BOW_MASTERY]= math.ceil(self.level/10),
				
				[Talents.T_CRIPPLING_SHOT]= math.ceil(self.level/10),
				[Talents.T_STEADY_SHOT]= math.ceil(self.level/10),
				[Talents.T_RAPID_SHOT]= math.ceil(self.level/10),
				
				[Talents.T_PSYCHOMETRY]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_BIOFEEDBACK]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_LUCID_DREAMER]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
			},
			resolvers.equip{
				{type="weapon", subtype="longbow", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="ammo", subtype="arrow", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="light", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="hands", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="feet", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
			},
			resolvers.sustains_at_birth(),
			
			-- Hack to make sure we top off ammo after every battle
			on_move = function(self)
				if game.player ~= self then
					local a = self:hasAmmo()
					if not a then print("[Thought-Form Bowman Ammo] - ERROR, NO AMMO") end
					if a and a.combat.shots_left < a.combat.capacity and not self.ai_target.actor and not self:hasEffect(self.EFF_RELOADING) then
						self:forceUseTalent(self.T_RELOAD, {})
					end
				end
			end,
		}

		setupThoughtForm(self, m, x, y, t)
		game:playSoundNear(self, "talents/spell_generic")
		
		local ret = {
			summon = m
		}
		if self:knowTalent(self.T_TF_UNITY) then
			local t = self:getTalentFromId(self.T_TF_UNITY)
			ret.speed = self:addTemporaryValue("combat_mindspeed", t.getSpeedPower(self, t)/100)
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if p.summon and p.summon.summoner == self then
			p.summon:die(p.summon)
		end
		if p.speed then self:removeTemporaryValue("combat_mindspeed", p.speed) end
		return true
	end,
	info = function(self, t)
		local stat = t.getStatBonus(self, t)
		return ([[가죽 갑옷을 걸친 궁수를 생각해, 그것을 구현해냅니다. 궁수는 활 수련, 정확도 수련, 정밀 사격, 무력화 사격, 속사 기술을 사용할 수 있으며, 시전자의 레벨에 따라 기술 레벨이 달라집니다.
		추가적으로 궁수는 힘 %d / 민첩 %d / 체격 %d 만큼의 능력치를 얻으며, 궁수를 구현 중일 경우 다른 형태는 구현해낼 수 없습니다.
		능력치 상승량은 정신력의 영향을 받아 증가합니다.]]):format(stat/2, stat, stat/2)
	end,
}

newTalent{
	name = "Thought-Form: Warrior",
	kr_name = "생각의 구현 : 전사",
	short_name = "TF_WARRIOR",
	type = {"psionic/other", 1},
	points = 5, 
	require = psi_wil_req1,
	sustain_psi = 20,
	mode = "sustained",
	no_sustain_autoreset = true,
	cooldown = 24,
	range = 10,
	no_unlearn_last = true,
	getStatBonus = function(self, t) 
		local t = self:getTalentFromId(self.T_THOUGHT_FORMS)
		return t.getStatBonus(self, t)
	end,
	activate = function(self, t)
		cancelThoughtForms(self, t.id)
		
		-- Find space
		local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "소환할 공간이 없습니다!")
			return
		end
		
		-- Do our stat bonuses here so we only roll for crit once		
		local stat_bonus = math.floor(self:mindCrit(t.getStatBonus(self, t)))
	
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			name = "thought-forged warrior", summoner = self, 
			kr_name = "생각의 구현 전사",
			color=colors.ORANGE, shader = "shadow_simulacrum",
			shader_args = { color = {0.8, 0.8, 0.8}, base = 0.8, time_factor = 4000 },
			desc = [[무거운 갑옷과 망치를 든, 생각의 구현으로 만든 전사입니다. 언제든지 전투에 임할 수 있을 것 같습니다.]],
			body = { INVEN = 10, MAINHAND = 1, BODY = 1, HANDS = 1, FEET = 1},
		
			ai = "summoned", ai_real = "tactical",
			ai_state = { ai_move="move_complex", talent_in=3, ally_compassion=10 },
			ai_tactic = resolvers.tactic("melee"),
			
			max_life = resolvers.rngavg(100,110),
			life_rating = 15,
			combat_armor = 0, combat_def = 0,
			stats = { mag=self:getMag(), wil=self:getWil(), cun=self:getCun()},
			inc_stats = {
				str = stat_bonus,
				dex = stat_bonus / 2,
				con = stat_bonus / 2,
			},

			resolvers.generic(function(e) buildTile(e) end), -- Make a moddable tile
			resolvers.talents{ 
				[Talents.T_ARMOUR_TRAINING]= 2,
				[Talents.T_WEAPON_COMBAT]= math.ceil(self.level/10),
				[Talents.T_WEAPONS_MASTERY]= math.ceil(self.level/10),
				
				[Talents.T_RUSH]= math.ceil(self.level/10),
				[Talents.T_DEATH_DANCE]= math.ceil(self.level/10),
				[Talents.T_BERSERKER]= math.ceil(self.level/10),

				[Talents.T_PSYCHOMETRY]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_BIOFEEDBACK]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_LUCID_DREAMER]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
			},
			resolvers.equip{
				{type="weapon", subtype="battleaxe", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="heavy", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="hands", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="feet", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
			},
			resolvers.sustains_at_birth(),
		}

		setupThoughtForm(self, m, x, y, t)

		game:playSoundNear(self, "talents/spell_generic")
		
		local ret = {
			summon = m
		}
		if self:knowTalent(self.T_TF_UNITY) then
			local t = self:getTalentFromId(self.T_TF_UNITY)
			ret.power = self:addTemporaryValue("combat_mindpower", t.getOffensePower(self, t))
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if p.summon and p.summon.summoner == self then
			p.summon:die(p.summon)
		end
		if p.power then self:removeTemporaryValue("combat_mindpower", p.power) end
		return true
	end,
	info = function(self, t)
		local stat = t.getStatBonus(self, t)
		return ([[도끼를 든 전사를 생각해, 그것을 구현해냅니다. 전사는 무기 수련, 정확도 수련, 광전사, 죽음의 춤, 돌진 기술을 사용할 수 있으며, 시전자의 레벨에 따라 기술 레벨이 달라집니다.
		추가적으로 전사는 힘 %d / 민첩 %d / 체격 %d 만큼의 능력치를 얻으며, 전사를 구현 중일 경우 다른 형태는 구현해낼 수 없습니다.
		능력치 상승량은 정신력의 영향을 받아 증가합니다.]]):format(stat, stat/2, stat/2)
	end,
}

newTalent{
	name = "Thought-Form: Defender",
	kr_name = "생각의 구현 : 수호자",
	short_name = "TF_DEFENDER",
	type = {"psionic/other", 1},
	points = 5, 
	require = psi_wil_req1,
	sustain_psi = 20,
	mode = "sustained",
	no_sustain_autoreset = true,
	cooldown = 24,
	range = 10,
	no_unlearn_last = true,
	getStatBonus = function(self, t) 
		local t = self:getTalentFromId(self.T_THOUGHT_FORMS)
		return t.getStatBonus(self, t)
	end,
	activate = function(self, t)
		cancelThoughtForms(self, t.id)
		
		-- Find space
		local x, y = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "소환할 공간이 없습니다!")
			return
		end
		
		-- Do our stat bonuses here so we only roll for crit once	
		local stat_bonus = math.floor(self:mindCrit(t.getStatBonus(self, t)))
	
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			name = "thought-forged defender", summoner = self,
			kr_name = "생각의 구현 수호자",
			color=colors.GOLD, shader = "shadow_simulacrum", 
			shader_args = { color = {0.8, 0.8, 0.8}, base = 0.8, time_factor = 4000 },
			desc = [[무거운 갑옷을 걸친, 생각의 구현으로 만든 수호자입니다. 검과 방패를 들고 있으며, 언제든지 전투에 임할 수 있을 것 같습니다.]],
			body = { INVEN = 10, MAINHAND = 1, OFFHAND = 1, BODY = 1, HANDS = 1, FEET = 1},
			
			ai = "summoned", ai_real = "tactical",
			ai_state = { ai_move="move_complex", talent_in=3, ally_compassion=10 },
			ai_tactic = resolvers.tactic("tank"),
			
			max_life = resolvers.rngavg(100,110),
			life_rating = 15,
			combat_armor = 0, combat_def = 0,
			stats = { mag=self:getMag(), wil=self:getWil(), cun=self:getCun()},
			inc_stats = {
				str = stat_bonus / 2,
				dex = stat_bonus / 2,
				con = stat_bonus,
			},
			
			resolvers.generic(function(e) buildTile(e) end), -- Make a moddable tile
			resolvers.talents{ 
				[Talents.T_ARMOUR_TRAINING]= 2 + math.ceil(self.level/20),
				[Talents.T_WEAPON_COMBAT]= math.ceil(self.level/10),
				[Talents.T_WEAPONS_MASTERY]= math.ceil(self.level/10),
				
				[Talents.T_SHIELD_PUMMEL]= math.ceil(self.level/10),
				[Talents.T_SHIELD_WALL]= math.ceil(self.level/10),
				

				[Talents.T_PSYCHOMETRY]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_BIOFEEDBACK]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),
				[Talents.T_LUCID_DREAMER]= math.floor(self:getTalentLevel(self.T_TRANSCENDENT_THOUGHT_FORMS)),

			},
			resolvers.equip{
				{type="weapon", subtype="longsword", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="shield", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="massive", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="hands", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
				{type="armor", subtype="feet", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"} },
			},
			resolvers.sustains_at_birth(),
		}

		setupThoughtForm(self, m, x, y, t)

		game:playSoundNear(self, "talents/spell_generic")
		
		local ret = {
			summon = m
		}
		if self:knowTalent(self.T_TF_UNITY) then
			local t = self:getTalentFromId(self.T_TF_UNITY)
			ret.resist = self:addTemporaryValue("resists", {all= t.getDefensePower(self, t)})
		end
		return ret
	end,
	deactivate = function(self, t, p)
		if p.summon and p.summon.summoner == self then
			p.summon:die(p.summon)
		end
		if p.resist then self:removeTemporaryValue("resists", p.resist) end
		return true
	end,
	info = function(self, t)
		local stat = t.getStatBonus(self, t)
		return ([[검과 방패를 든 수호자를 생각해, 그것을 구현해냅니다. 수호자는 방어구 수련, 무기 수련, 정확도 수련, 방패 치기, 방패의 벽 기술을 사용할 수 있으며, 시전자의 레벨에 따라 기술 레벨이 달라집니다.
		추가적으로 수호자는 힘 %d / 민첩 %d / 체격 %d 만큼의 능력치를 얻으며, 수호자를 구현 중일 경우 다른 형태는 구현해낼 수 없습니다.
		능력치 상승량은 정신력의 영향을 받아 증가합니다.]]):format(stat/2, stat/2, stat)
	end,
}

newTalent{
	name = "Thought-Forms",
	kr_name = "생각의 구현",
	short_name = "THOUGHT_FORMS",
	type = {"psionic/thought-forms", 1},
	points = 5, 
	require = psi_wil_req1,
	mode = "passive",
	range = 10,
	getStatBonus = function(self, t) return self:combatTalentMindDamage(t, 5, 50) end,
	on_learn = function(self, t)
		if self:getTalentLevel(t) >= 1 and not self:knowTalent(self.T_TF_BOWMAN) then
			self:learnTalent(self.T_TF_BOWMAN, true)
		end
		if self:getTalentLevel(t) >= 3 and not self:knowTalent(self.T_TF_WARRIOR) then
			self:learnTalent(self.T_TF_WARRIOR, true)
		end
		if self:getTalentLevel(t) >= 5 and not self:knowTalent(self.T_TF_DEFENDER) then
			self:learnTalent(self.T_TF_DEFENDER, true)
		end
	end,	
	on_unlearn = function(self, t)
		if self:getTalentLevel(t) < 1 and self:knowTalent(self.T_TF_BOWMAN) then
			self:unlearnTalent(self.T_TF_BOWMAN)
		end
		if self:getTalentLevel(t) < 3 and self:knowTalent(self.T_TF_WARRIOR) then
			self:unlearnTalent(self.T_TF_WARRIOR)
		end
		if self:getTalentLevel(t) < 5 and self:knowTalent(self.T_TF_DEFENDER) then
			self:unlearnTalent(self.T_TF_DEFENDER)
		end
	end,
	info = function(self, t)
		local bonus = t.getStatBonus(self, t)
		local range = self:getTalentRange(t)
		return([[마음 속으로 자신을 보호할 수 있는 분신을 생각해내, 그것을 실제로 구현해냅니다. 
		분신의 마법, 교활함, 의지 능력치는 자신의 능력치와 같으며, 분신의 가장 중요한 능력치는 자신보다 %d 만큼, 두번째로 중요한 능력치들은 자신보다 %d 만큼 상승된 능력치가 적용됩니다.
		기술 레벨이 1 이상이면, 가죽 갑옷을 입은 궁수 형태의 분신을 구현화할 수 있습니다.
		기술 레벨이 3 이상이면, 대형도끼를 든 전사 형태의 분신을 구현화할 수 있습니다.
		기술 레벨이 5 이상이면, 검과 방패를 사용하는 수호자 형태의 분신을 구현화할 수 있습니다.
		구현된 분신은 주변 %d 칸 반경에서만 유지할 수 있으며, 범위를 벗어날 경우 시전자 근처로 순간이동합니다.
		한번에 하나의 분신만을 구현할 수 있으며, 능력치 상승량은 정신력의 영향을 받아 증가합니다.]]):format(bonus, bonus/2, range)
	end,
}

newTalent{
	name = "Transcendent Thought-Forms",
	kr_name = "탁월한 생각의 구현",
	short_name = "TRANSCENDENT_THOUGHT_FORMS",
	type = {"psionic/thought-forms", 2},
	points = 5, 
	require = psi_wil_req2,
	mode = "passive",
	info = function(self, t)
		local level = math.floor(self:getTalentLevel(t))
		return([[생각의 구현으로 만들어진 분신이 %d 레벨의 자각몽, 생체 반작용, 사이코메트리 기술을 사용할 수 있게 됩니다.]]):format(level)
	end,
}

newTalent{
	name = "Over Mind",
	kr_name = "정신 이동",
	type = {"psionic/thought-forms", 3},
	points = 5, 
	require = psi_wil_req3,
	sustain_psi = 50,
	mode = "sustained",
	no_sustain_autoreset = true,
	cooldown = 24,
	no_npc_use = true,
	getControlBonus = function(self, t) return self:combatTalentMindDamage(t, 5, 50) end,
--	getRangeBonus = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5)) end,
	on_pre_use = function(self, t, silent) if not game.party:findMember{type="thought-form"} then if not silent then game.logPlayer(self, "이 기술을 사용하기 위해서는 생각의 구현을 사용하는 중이어야 합니다!") end return false end return true end,
	activate = function(self, t)
		-- Find our thought-form
		local target = game.party:findMember{type="thought-form"}
		
		-- Modify the control permission
		local old_control = game.party:hasMember(target).control
		game.party:hasMember(target).control = "full"
				
		-- Store life bonus and heal value
		local life_bonus = target.max_life * (t.getControlBonus(self, t)/100)
		
		-- Switch on TickEnd so every thing applies correctly
		game:onTickEnd(function() 
			game.level.map:particleEmitter(self.x, self.y, 1, "generic_discharge", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})
			game.party:hasMember(target).on_control = function(self)
				self.summoner.over_mind_ai = self.summoner.ai
				self.summoner.ai = "none"
				self:hotkeyAutoTalents()
			end
			game.party:hasMember(target).on_uncontrol = function(self)
				self.summoner.ai = self.summoner.over_mind_ai
				if self.summoner:isTalentActive(self.summoner.T_OVER_MIND) then
					self.summoner:forceUseTalent(self.summoner.T_OVER_MIND, {ignore_energy=true})
				end
				game.level.map:particleEmitter(self.x, self.y, 1, "generic_discharge", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})
				game.level.map:particleEmitter(self.summoner.x, self.summoner.y, 1, "generic_discharge", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})
			end
			game.level.map:particleEmitter(target.x, target.y, 1, "generic_discharge", {rm=225, rM=255, gm=225, gM=255, bm=225, bM=255, am=35, aM=90})
			game.party:setPlayer(target)
			self:resetCanSeeCache()
		end)
		
		game:playSoundNear(self, "talents/teleport")
			
		local ret = {
			target = target, old_control = old_control,
			life = target:addTemporaryValue("max_life", life_bonus),
			speed = target:addTemporaryValue("combat_physspeed", t.getControlBonus(self, t)/100),
			damage = target:addTemporaryValue("inc_damage", {all=t.getControlBonus(self, t)}),
			target:heal(life_bonus, self),
		}
		
		return ret
	end,
	deactivate = function(self, t, p)
		if p.target then
			p.target:removeTemporaryValue("max_life", p.life)
			p.target:removeTemporaryValue("inc_damage", p.damage)
			p.target:removeTemporaryValue("combat_physspeed", p.speed)
		
			if game.party:hasMember(p.target) then
				game.party:hasMember(p.target).control = old_control
			end
		end
		return true
	end,
	info = function(self, t)
		local bonus = t.getControlBonus(self, t)
--		local range = t.getRangeBonus(self, t)
		return ([[생각의 구현으로 만들어진 분신을 직접 조종할 수 있게 됩니다. 또한 분신의 피해량, 공격 속도, 최대 생명력이 %d%% 늘어나게 됩니다. 하지만 분신을 조종하는 동안 시전자는 무력해집니다.
		기술 레벨이 1 이상이면, 분신이 얻는 반작용이 시전자에게도 적용됩니다.
		기술 레벨이 3 이상이면, 시전자의 정신 내성 수치만큼 분신의 모든 내성이 오릅니다.
		기술 레벨이 5 이상이면, 시전자의 정신 피해 추가량만큼 분신의 모든 피해량이 오릅니다.
		기술 레벨의 상승에 따라 얻는 효과는 정신 이동 기술의 유지 여부와 상관없이 항상 적용됩니다.
		분신의 피해량, 공격 속도, 최대 생명력 증가량은 정신력의 영향을 받아 증가합니다.]]):format(bonus)
	end,
}

newTalent{
	name = "Thought-Form Unity",
	kr_name = "생각의 구현체 연동",
	short_name = "TF_UNITY",
	type = {"psionic/thought-forms", 4},
	points = 5, 
	require = psi_wil_req4,
	mode = "passive",
	getSpeedPower = function(self, t) return self:combatTalentMindDamage(t, 5, 15) end,
	getOffensePower = function(self, t) return self:combatTalentMindDamage(t, 10, 30) end,
	getDefensePower = function(self, t) return self:combatTalentMindDamage(t, 1, 10) end,
	info = function(self, t)
		local offense = t.getOffensePower(self, t)
		local defense = t.getDefensePower(self, t)
		local speed = t.getSpeedPower(self, t)
		return([[궁수의 형태를 구현 중일 때 사고 속도가 %d%% / 전사의 형태를 구현 중일 때 정신력이 %d%% / 수호자의 형태를 구현 중일 때 전체 저항력이 %d%% 증가합니다.
		기술의 효과는 정신력의 효과를 받아 증가합니다.]]):format(speed, offense, defense, speed)
	end,
}