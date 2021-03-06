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

require "engine.krtrUtils"

newTalent{
	name = "Death Dance",
	kr_name = "죽음의 춤",
	type = {"technique/2hweapon-offense", 1},
	require = techs_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 30,
	tactical = { ATTACKAREA = { weapon = 3 } },
	range = 0,
	radius = 1,
	requires_target = true,
	is_melee = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 죽음의 춤을 출 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1.4, 2.1))
			end
		end)

		self:addParticles(Particles.new("meleestorm", 1, {}))

		return true
	end,
	info = function(self, t)
		return ([[한바퀴 돌면서, 주변 1 칸 반경의 모두에게 %d%% 의 무기 피해를 입힙니다.]]):format(100 * self:combatTalentWeaponDamage(t, 1.4, 2.1))
	end,
}

newTalent{
	name = "Berserker",
	kr_name = "광전사",
	type = {"technique/2hweapon-offense", 2},
	require = techs_req2,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	tactical = { BUFF = 2 },
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	getDam = function(self, t) return self:combatScale(self:getStr(7, true) * self:getTalentLevel(t), 5, 0, 40, 35)end,
	getAtk = function(self, t) return self:combatScale(self:getDex(7, true) * self:getTalentLevel(t), 5, 0, 40, 35) end ,
	getImmune = function(self, t) return self:combatTalentLimit(t, 1, 0.17, 0.5) end,
	activate = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 광전사 상태가 될 수 없습니다!")
			return nil
		end

		return {
			armor = self:addTemporaryValue("combat_armor", -10),
			stun = self:addTemporaryValue("stun_immune", t.getImmune(self, t)),
			pin = self:addTemporaryValue("pin_immune", t.getImmune(self, t)),
			dam = self:addTemporaryValue("combat_dam", t.getDam(self, t)),
			atk = self:addTemporaryValue("combat_atk", t.getAtk(self, t)),
			def = self:addTemporaryValue("combat_def", -10),
		}
	end,

	deactivate = function(self, t, p)
		self:removeTemporaryValue("stun_immune", p.stun)
		self:removeTemporaryValue("pin_immune", p.pin)
		self:removeTemporaryValue("combat_def", p.def)
		self:removeTemporaryValue("combat_armor", p.armor)
		self:removeTemporaryValue("combat_atk", p.atk)
		self:removeTemporaryValue("combat_dam", p.dam)
		return true
	end,
	info = function(self, t)
		return ([[공격적인 전투 자세를 취합니다. 회피도와 방어력이 10 씩 감소하는 대신, 정확도가 %d / 물리력이 %d 증가합니다.
		광전사 상태인 사람을 멈춰세우기란 거의 불가능하기 때문에, %d%% 만큼의 기절과 속박 면역력을 얻게 됩니다.
		정확도는 민첩, 물리력은 힘 능력치의 영향을 받아 증가합니다.]]):
		format( t.getAtk(self, t), t.getDam(self, t), t.getImmune(self, t)*100)
	end,
}

newTalent{
	name = "Warshout",
	kr_name = "전투함성",
	type = {"technique/2hweapon-offense",3},
	require = techs_req3,
	points = 5,
	random_ego = "attack",
	message = function(self) if self.subtype == "rodent" then return "@Source1@ 전투함성을 내지릅니다. 찍찍!" else return "@Source1@ 전투함성을 내지릅니다." end end ,
	stamina = 30,
	cooldown = 18,
	tactical = { ATTACKAREA = { confusion = 1 }, DISABLE = { confusion = 3 } },
	range = 0,
	radius = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 4, 8)) end,
	requires_target = true,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false}
	end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 전투함성을 내지를 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.CONFUSION, {
			dur=t.getDuration(self, t),
			dam=50+self:getTalentLevelRaw(t)*10,
			power_check=function() return self:combatPhysicalpower() end,
			resist_check=self.combatPhysicalResist,
		})
		game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "directional_shout", {life=8, size=3, tx=x-self.x, ty=y-self.y, distorion_factor=0.1, radius=self:getTalentRadius(t), nb_circles=8, rm=0.8, rM=1, gm=0.4, gM=0.6, bm=0.1, bM=0.2, am=1, aM=1})
		return true
	end,
	info = function(self, t)
		return ([[전방 %d 칸 반경에 전투함성을 내지릅니다. 범위 내의 대상들은 %d 턴 동안 혼란 상태에 빠집니다.]]):
		format(self:getTalentRadius(t), t.getDuration(self, t))
	end,
}

newTalent{
	name = "Death Blow",
	kr_name = "죽음의 일격",
	type = {"technique/2hweapon-offense", 4},
	require = techs_req4,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 15,
	requires_target = true,
	tactical = { ATTACK = { weapon = 1 } },
	is_melee = true,
	range = 1,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 죽음의 일격을 쓸 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end

		local inc = self.stamina / 2
		if self:getTalentLevel(t) >= 4 then
			self.combat_dam = self.combat_dam + inc
		end
		self.turn_procs.auto_phys_crit = true
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 0.8, 1.3))

		if self:getTalentLevel(t) >= 4 then
			self.combat_dam = self.combat_dam - inc
			self:incStamina(-self.stamina / 2)
		end
		self.turn_procs.auto_phys_crit = nil

		-- Try to insta-kill
		if hit then
			if target:checkHit(self:combatPhysicalpower(), target:combatPhysicalResist(), 0, 95, 5 - self:getTalentLevel(t) / 2) and target:canBe("instakill") and target.life > 0 and target.life < target.max_life * 0.2 then
				-- KILL IT !
				game.logSeen(target, "%s에게 죽음의 고통을 안겨줬습니다!", target.name:capitalize())
				target:die(self)
			elseif target.life > 0 and target.life < target.max_life * 0.2 then
				game.logSeen(target, "%s가 죽음의 고통을 저항했습니다!", target.name:capitalize())
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[적중시 무조건 치명타 효과가 발생하며, %d%% 의 무기 피해를 주는 즉사 공격을 시도합니다. 
		공격을 받은 대상이 빈사상태 (생명력 20%% 미만) 이며 대상이 저항하지 못했을 경우, 대상은 즉사합니다.
		기술 레벨이 4 이상일 경우 남은 체력의 절반을 쏟아부어, 소모한 체력 수치만큼 더 강력한 공격을 할 수 있게 됩니다.
		즉사 확률은 물리력의 영향을 받아 증가합니다.]]):format(100 * self:combatTalentWeaponDamage(t, 0.8, 1.3))
	end,
}

-----------------------------------------------------------------------------
-- Cripple
-----------------------------------------------------------------------------
newTalent{
	name = "Stunning Blow",
	kr_name = "기절시키기",
	type = {"technique/2hweapon-cripple", 1},
	require = techs_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 8,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 } },
	requires_target = true,
	is_melee = true,
	range = 1,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 3, 7)) end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 기절시키기를 쓸 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to stun !
		if hit then
			if target:canBe("stun") then
				target:setEffect(target.EFF_STUNNED, t.getDuration(self, t), {apply_power=self:combatPhysicalpower()})
			else
				game.logSeen(target, "%s 기절하지 않았습니다!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[대상의 머리를 무기로 내리쳐서 %d%% 의 무기 피해를 주고, 공격에 성공하면 %d 턴 동안 기절시킵니다.
		기절 확률은 물리력의 영향을 받아 증가합니다.]])
		:format(100 * self:combatTalentWeaponDamage(t, 1, 1.5), t.getDuration(self, t))
	end,
}

newTalent{
	name = "Sunder Armour",
	kr_name = "방어구 부수기",
	type = {"technique/2hweapon-cripple", 2},
	require = techs_req2,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 12,
	requires_target = true,
	is_melee = true,
	range = 1,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 } },
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	getShatter = function(self, t) return self:combatTalentLimit(t, 100, 10, 85) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	getArmorReduc = function(self, t) return self:combatTalentScale(t, 5, 25, 0.75) end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 방어구 부수기를 쓸 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to Sunder !
		if hit then
			target:setEffect(target.EFF_SUNDER_ARMOUR, t.getDuration(self, t), {power=t.getArmorReduc(self,t), apply_power=self:combatPhysicalpower()})

			if rng.percent(t.getShatter(self, t)) then
				local effs = {}

				-- Go through all shield effects
				for eff_id, p in pairs(target.tmp) do
					local e = target.tempeffect_def[eff_id]
					if e.status == "beneficial" and e.subtype and e.subtype.shield then
						effs[#effs+1] = {"effect", eff_id}
					end
				end

				for i = 1, 1 do
					if #effs == 0 then break end
					local eff = rng.tableRemove(effs)

					if eff[1] == "effect" then
						game.logSeen(self, "#CRIMSON#%s %s의 보호막을 부쉈습니다!", self.name:capitalize(), target.name)
						target:removeEffect(eff[2])
					end
				end
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[대상의 방어구를 무기로 내리쳐서 %d%% 의 무기 피해를 주고, 공격에 성공하면 %d 턴 동안 대상의 방어도와 모든 내성을 %d 감소시킵니다.
		또한 대상이 일시적인 피해 보호막에 의해 보호받고 있다면, %d%% 확률로 보호막을 분쇄해버립니다.
		방어도 감소 확률은 물리력의 영향을 받아 증가합니다.]])
		:format(100 * self:combatTalentWeaponDamage(t, 1, 1.5),t.getArmorReduc(self, t), t.getDuration(self, t), t.getShatter(self, t))
	end,
}

newTalent{
	name = "Sunder Arms",
	kr_name = "무기 부수기",
	type = {"technique/2hweapon-cripple", 3},
	require = techs_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 6,
	stamina = 12,
	tactical = { ATTACK = { weapon = 2 }, DISABLE = { stun = 2 } },
	requires_target = true,
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	range = 1,
	is_melee = true,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	action = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 무기 부수기를 쓸 수 없습니다!")
			return nil
		end

		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end
		local speed, hit = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1, 1.5))

		-- Try to Sunder !
		if hit then
			target:setEffect(target.EFF_SUNDER_ARMS, t.getDuration(self, t), {power=3*self:getTalentLevel(t), apply_power=self:combatPhysicalpower()})
		end

		return true
	end,
	info = function(self, t)
		return ([[대상의 무기를 내리쳐서 %d%% 의 무기 피해를 주고, 공격에 성공하면 %d 턴 동안 대상의 정확도를 %d 감소시킵니다.
		정확도 감소 확률은 물리력의 영향을 받아 증가합니다.]])
		:format(
			100 * self:combatTalentWeaponDamage(t, 1, 1.5), 3 * self:getTalentLevel(t), t.getDuration(self, t))
	end,
}

newTalent{
	name = "Blood Frenzy",
	kr_name = "피의 광란",
	type = {"technique/2hweapon-cripple", 4},
	require = techs_req4,
	points = 5,
	mode = "sustained",
	cooldown = 15,
	sustain_stamina = 70,
	no_energy = true,
	tactical = { BUFF = 1 },
	callbackOnActBase = function(self, t)
		if self.blood_frenzy > 0 then
			self.blood_frenzy = math.max(self.blood_frenzy - 2, 0)
		end
	end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "이 기술을 사용하려면 양손 무기가 필요합니다.") end return false end return true end,
	bonuspower = function(self,t) return self:combatTalentScale(t, 2, 10, 0.5, 0, 2) end, -- called by _M:die function in mod.class.Actor.lua
	activate = function(self, t)
		local weapon = self:hasTwoHandedWeapon()
		if not weapon then
			game.logPlayer(self, "양손 무기 없이는 피의 광란을 쓸 수 없습니다!")
			return nil
		end
		self.blood_frenzy = 0
		return {
			regen = self:addTemporaryValue("stamina_regen", -2),
		}
	end,
	deactivate = function(self, t, p)
		self.blood_frenzy = nil
		self:removeTemporaryValue("stamina_regen", p.regen)
		return true
	end,
	info = function(self, t)
		return ([[매 턴마다 체력이 2 씩 감소하는 피의 광란 상태에 빠지며, 이 상태에서는 적을 죽일 때마다 물리력이 %d 씩 상승하게 됩니다.
		물리력 상승 효과는 중첩되며 한계도 없지만, 추가로 얻은 물리력은 턴이 지날 때마다 2 씩 감소합니다.]]):
		format(t.bonuspower(self,t))
	end,
}
