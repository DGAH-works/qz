--[[
	太阳神三国杀武将扩展包·乌有中学（AI部分）
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	武将总数：10
	武将一览：
		1、梁华（漫游）
		2、公孙木（金兰）
		3、陈录（通透）
		4、高傅（热肠、声誉）
		5、独孤易（幻像）
		6、马芝慧（绝貌、指引）
		7、李茵妮（律守、同步）
		8、张雅晨（音难）
		9、王兴（运衰）
		10、宁江（信仰）
]]--
function SmartAI:useSkillCard(card, use)
	local name
	if card:isKindOf("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:getClassName()
	end
	if sgs.ai_skill_use_func[name] then
		sgs.ai_skill_use_func[name](card, use, self)
		if use.to then
			if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
				for _, target in sgs.qlist(use.to) do
					if self:damageIsEffective(target) then return end
				end
				use.card = nil
			end
		end
		return
	end
	if self["useCard"..name] then
		self["useCard"..name](self, card, use)
	end
end
--[[****************************************************************
	编号：QZ - 001
	武将：梁华
	称号：主人公
	势力：魏
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：漫游
	描述：你的【杀】被【闪】抵消时，你可以进行一次判定。然后你可以令一名角色获得此判定牌并对其自己使用之。
]]--
--player:askForSkillInvoke("qzManYou", data)
sgs.ai_skill_invoke["qzManYou"] = true
--room:askForPlayerChosen(player, alives, "qzManYou", prompt, true)
sgs.ai_skill_playerchosen["qzManYou"] = function(self, targets)
	local data = self.player:getTag("qzManYouData")
	local judge = data:toJudge()
	if judge then
		local card = judge.card
		local friends, enemies = {}, {}
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				table.insert(friends, p)
			else
				table.insert(enemies, p)
			end
		end
		self:sort(friends, "defense")
		self:sort(enemies, "defense")
		if card:isKindOf("BasicCard") then
			if card:isKindOf("Slash") then
				for _,enemy in ipairs(enemies) do
					if enemy:isProhibited(enemy, card) then
					elseif self:slashIsEffective(card, enemy, enemy) then
						return enemy
					end
				end
			elseif card:isKindOf("Jink") then
				for _,friend in ipairs(friends) do
					if hasManjuanEffect(friend) then
					elseif friend:isKongcheng() and self:needKongcheng(friend) then
					else
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					if not hasManjuanEffect(friend) then
						return friend
					end
				end
			elseif card:isKindOf("Peach") then
				local needHelp, notNeedHelp = self:getWoundedFriend(false, true)
				if #needHelp > 0 then
					return needHelp[1]
				end
				for _,friend in ipairs(friends) do
					if friend:getLostHp() == 0 then
						if not hasManjuanEffect(friend) then
							return friend
						end
					end
				end
				if #notNeedHelp > 0 then
					return notNeedHelp[1]
				end
				return friends[1]
			elseif card:isKindOf("Analeptic") then
				if self:hasCrossbowEffect() then
					return self.player
				end
				for _,enemy in ipairs(enemies) do
					if enemy:getHp() <= 1 then
						return enemy
					end
				end
			end
		elseif card:isKindOf("EquipCard") then
			if card:isKindOf("Weapon") then
				local range = sgs.weapon_range[card:getClassName()] or 0 
				for _,friend in ipairs(friends) do
					if friend:getWeapon() then
					elseif friend:hasSkill("zhengfeng") and friend:getHp() > range then
					elseif friend:hasSkill("shenji") and range <= 1 then
					else
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					local weapon = friend:getWeapon()
					if weapon then
						if self:evaluateWeapon(weapon, friend) < self:evaluateWeapon(card, friend) then
							return friend
						end
					end
				end
			elseif card:isKindOf("Armor") then
				for _,friend in ipairs(friends) do
					local armor = friend:getArmor()
					local value = 0
					if armor then
						value = self:evaluateArmor(armor, friend) or 0
					end
					if self:evaluateArmor(card, player) > value then
						return friend
					end
				end
				for _,enemy in ipairs(enemies) do
					local armor = enemy:getArmor()
					local value = 0
					if armor then
						if self:hasSkills(sgs.lose_equip_skill, enemy) then
							continue
						end
						value = self:evaluateArmor(armor, enemy) or 0
					end
					if self:evaluateArmor(card, enemy) < value then
						return enemy
					end
				end
			elseif card:isKindOf("DefensiveHorse") then
				for _,friend in ipairs(friends) do
					if not friend:getDefensiveHorse() then
						return friend
					end
				end
			elseif card:isKindOf("OffensiveHorse") then
				for _,friend in ipairs(friends) do
					if not friend:getOffensiveHorse() then
						return friend
					end
				end
			elseif card:isKindOf("Treasure") then
				for _,friend in ipairs(friends) do
					if not friend:getTreasure() then
						return friend
					end
				end
			end
			for _,friend in ipairs(friends) do
				if not hasManjuanEffect(friend) then
					if self:hasSkills(sgs.lose_equip_skill, friend) then
						return friend
					end
				end
			end
		elseif card:isKindOf("TrickCard") then
			if card:isKindOf("AmazingGrace") then
				return self:findPlayerToDraw(true, 1)
			elseif card:isKindOf("GodSalvation") then
				local needHelp, notNeedHelp = self:getWoundedFriend(false, true)
				if #needHelp > 0 then
					return needHelp[1]
				end
				for _,friend in ipairs(friends) do
					if friend:getLostHp() == 0 then
						if not hasManjuanEffect(friend) then
							return friend
						end
					end
				end
				if #notNeedHelp > 0 then
					return notNeedHelp[1]
				end
				return friends[1]
			elseif card:isKindOf("AOE") then
				local rest = {}
				for _,enemy in ipairs(enemies) do
					if self:hasTrickEffective(card, enemy, enemy) then
						if self:hasSkills(sgs.masochism_skill, enemy) and enemy:getHp() > 1 then
							table.insert(rest, enemy)
						else
							return enemy
						end
					end
				end
				if #rest > 0 then
					return rest[1]
				end
				for _,friend in ipairs(friends) do
					if self:needToLoseHp(friend, friend, false) and not self:isWeak(friend) then
						return friend
					end
				end
			elseif card:isKindOf("Duel") then
				local rest = {}
				for _,enemy in ipairs(enemies) do
					if self:hasTrickEffective(card, enemy, enemy) then
						if self:hasSkills(sgs.masochism_skill, enemy) and enemy:getHp() > 1 then
							table.insert(rest, enemy)
						else
							return enemy
						end
					end
				end
				if #rest > 0 then
					return rest[1]
				end
				for _,friend in ipairs(friends) do
					if self:needToLoseHp(friend, friend, false) and not self:isWeak(friend) then
						return friend
					end
				end
			elseif card:isKindOf("FireAttack") then
				for _,friend in ipairs(friends) do
					if self:hasSkills("jizhi|nosjizhi|jilve", friend) then
						return friend
					elseif friend:isKongcheng() and not self:needKongcheng(friend) then
						return friend
					end
				end
				for _,enemy in ipairs(enemies) do
					if enemy:isKongcheng() then
					elseif self:hasSkills("jizhi|nosjizhi|jilve", enemy) then
					else
						return enemy
					end
				end
			elseif card:isKindOf("IronChain") then
				for _,friend in ipairs(friends) do
					if friend:isChained() then
						return friend
					end
				end
				for _,enemy in ipairs(enemies) do
					if enemy:isChained() then
					elseif enemy:isProhibited(enemy, card) then
					else
						return enemy
					end
				end
			elseif card:isKindOf("Collateral") then
				for _,friend in ipairs(friends) do
					if friend:getWeapon() and self:hasSkills(sgs.lose_equip_skill, friend) then
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					local slash = 0
					if friend:objectName() == self.player:objectName() then
						slash = self:getCardsNum("Slash")
					else
						slash = getCardsNum("Slash", friend, self.player)
					end
					if slash > 0 then
						return friend
					end
				end
			elseif card:isKindOf("Snatch") then
				for _,friend in ipairs(friends) do
					if hasManjuanEffect(friend) then
					elseif friend:getArmor() and self:needToThrowArmor(friend) then
						return friend
					elseif self:hasSkills("jizhi|nosjizhi|jilve", friend) then
						return friend
					elseif friend:containsTrick("YanxiaoCard") then
					elseif friend:containsTrick("supply_shortage") or friend:containsTrick("indulgence") then
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					if not hasManjuanEffect(friends) then
						return friend
					end
				end
			elseif card:isKindOf("Dismantlement") then
				for _,friend in ipairs(friends) do
					if hasManjuanEffect(friend) then
					elseif friend:getArmor() and self:needToThrowArmor(friend) then
						return friend
					elseif friend:containsTrick("YanxiaoCard") then
					elseif friend:containsTrick("supply_shortage") or friend:containsTrick("indulgence") then
						return friend
					end
				end
				local e_targets = {}
				for _,enemy in ipairs(enemies) do
					if enemy:isProhibited(enemy, card) then
					elseif enemy:containsTrick("supply_shortage") or enemy:containsTrick("indulgence") then
					else
						table.insert(e_targets, enemy)
					end
				end
				for _,enemy in ipairs(e_targets) do
					if enemy:getArmor() and self:needToThrowArmor(enemy) then
					elseif self:hasLoseHandcardEffective(enemy) then
						return enemy
					end
				end
				if #e_targets > 0 then
					return e_targets[1]
				end
			elseif card:isKindOf("ExNihilo") then
				for _,friend in ipairs(friends) do
					if hasManjuanEffect(friend) then
					elseif self:hasSkills("jizhi|nosjizhi|jilve", friend) then
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					if not hasManjuanEffect(friend) then
						return friend
					end
				end
			elseif card:isKindOf("Nullification") then
				for _,friend in ipairs(friends) do
					if hasManjuanEffect(friend) then
					elseif friend:isKongcheng() and self:needKongcheng(friend) then
					else
						return friend
					end
				end
				for _,friend in ipairs(friends) do
					if not hasManjuanEffect(friend) then
						return friend
					end
				end
			elseif card:isKindOf("DelayedTrick") then
				if card:isKindOf("Indulgence") then
					self:sort(enemies, "handcard")
					enemies = sgs.reverse(enemies)
					local target = nil
					for _,enemy in ipairs(enemies) do
						if enemy:containsTrick("YanxiaoCard") then
						elseif enemy:containsTrick(card:objectName()) then
						elseif enemy:isProhibited(enemy, card) then
						elseif self:getOverflow(enemy) > 0 then
							return enemy
						elseif not target then
							target = enemy
						end
					end
					if target then
						return target
					end
				elseif card:isKindOf("SupplyShortage") then
					self:sort(enemies, "handcard")
					for _,enemy in ipairs(enemies) do
						if enemy:containsTrick("YanxiaoCard") then
						elseif enemy:containsTrick(card:objectName()) then
						elseif enemy:isProhibited(enemy, card) then
						else
							return enemy
						end
					end
				elseif card:isKindOf("Lightning") then
					local no_retrial = false
					local has_enemy = false
					local rest = {}
					for _,enemy in ipairs(enemies) do
						if enemy:containsTrick("YanxiaoCard") then
						elseif enemy:containsTrick("lightning") then
						elseif self:hasSkills("hongyan|wuyan", enemy) then
						elseif enemy:isProhibited(enemy, card) then
						else
							has_enemy = true
							if no_retrial then
								table.insert(rest, enemy)
							else
								local final, wazard = self:getFinalRetrial(enemy, "lightning")
								if final == 0 then
									no_retrial = true
									table.insert(rest, enemy)
								elseif final == 1 then
									if enemy:hasArmorEffect("silver_lion") then
										table.insert(rest, enemy)
									elseif enemy:hasSkill("tiandu") then
										table.insert(rest, enemy)
									else
										return enemy
									end
								end
							end
						end
					end
					if has_enemy and not no_retrial then
						for _,friend in ipairs(friends) do
							if getFinalRetrial(friend, "lightning") == 1 then
								return friend
							end
						end
					end
					if #rest > 0 then
						return rest[1]
					end
				elseif card:isKindOf("Volcano") then
					local no_retrial = false
					local has_enemy = false
					local rest = {}
					for _,enemy in ipairs(enemies) do
						if enemy:containsTrick("YanxiaoCard") then
						elseif enemy:containsTrick("volcano") then
						elseif self:hasSkills("shixin|wuyan", enemy) then
						elseif enemy:isProhibited(enemy, card) then
						else
							has_enemy = true
							if no_retrial then
								table.insert(rest, enemy)
							else
								local final, wazard = self:getFinalRetrial(enemy, "volcano")
								if final == 0 then
									no_retrial = true
									table.insert(rest, enemy)
								elseif final == 1 then
									if enemy:hasArmorEffect("silver_lion") then
										table.insert(rest, enemy)
									elseif enemy:hasSkill("tiandu") then
										table.insert(rest, enemy)
									else
										return enemy
									end
								end
							end
						end
					end
					if has_enemy and not no_retrial then
						for _,friend in ipairs(friends) do
							if getFinalRetrial(friend, "volcano") == 1 then
								return friend
							end
						end
					end
					if #rest > 0 then
						return rest[1]
					end
				elseif card:isKindOf("Disaster") then
					for _,friend in ipairs(friends) do
						if self:hasSkills("jizhi|nosjizhi|jilve|tiandu", friend) then
							return friend
						end
					end
					local dummy_use = {
						isDummy = true,
					}
					self:useTrickCard(card, dummy_use)
					if dummy_use.card then
						if #friends > 0 then
							return friends[1]
						end
						for _,enemy in ipairs(enemies) do
							if self:hasSkills("jizhi|nosjizhi|jilve|tiandu", enemy) then
							elseif enemy:isProhibited(enemy, card) then
							elseif enemy:containsTrick("YanxiaoCard") then
							elseif enemy:containsTrick(card:objectName()) then
							else
								return enemy
							end
						end
					end
				end
				for _,friend in ipairs(friends) do
					if friend:containsTrick("YanxiaoCard") then
						return friend
					elseif friend:containsTrick(card:objectName()) then
						return friend
					end
				end
			end
		end
		for _,friend in ipairs(friends) do
			if friend:isProhibited(friend, card) then
				return friend
			end
		end
	end
end
--room:askForPlayerChosen(target, victims, "qzManYouVictim", prompt)
sgs.ai_skill_playerchosen["qzManYouVictim"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
--相关信息
sgs.ai_playerchosen_intention["qzManYou"] = function(self, from, to)
	if from:objectName() == to:objectName() then
		return 
	end
	local data = self.player:getTag("qzManYouData")
	local judge = data:toJudge()
	local card = judge.card
	local intention = 0
	if card then
		if to:isProhibited(to, card) then
			intention = -50
			if hasManjuanEffect(to) then
			elseif to:isKongcheng() and self:needKongcheng(to) then
				intention = 0
			end
		elseif card:isKindOf("BasicCard") then
			if card:isKindOf("Jink") or card:isKindOf("Peach") then
				intention = -20
			elseif card:isKindOf("Slash") then
				if self:slashIsEffective(card, to, to) then
					if self:needToLoseHp(to, to, true) then
						intention = 0
					else
						intention = 30
					end
				else
					intention = 0
				end
			end
		elseif card:isKindOf("TrickCard") then
			if card:isKindOf("Duel") or card:isKindOf("AOE") or card:isKindOf("FireAttack") then
				intention = 80
				if self:hasTrickEffective(card, to, to) then
					if self:needToLoseHp(to, to, false) then
						intention = 0
					elseif self:hasSkills("jizhi|nosjizhi|jilve", to) then
						intention = 0
					end
				else
					if self:hasSkills("jizhi|nosjizhi|jilve", to) then
						intention = -20
					else
						intention = 0
					end
				end
			elseif card:isKindOf("ExNihilo") or card:isKindOf("Nullification") then
				intention = 50
			elseif card:isKindOf("Snatch") then
				if hasManjuanEffect(to) then
					intention = 0
				elseif to:getArmor() and self:needToThrowArmor(to) then
					intention = -10
				elseif to:hasEquip() and self:hasSkills(sgs.lose_equip_skill, to) then
					intention = 0
				elseif to:containsTrick("YanxiaoCard") then
				elseif to:containsTrick("supply_shortage") or to:containsTrick("indulgence") then
					intention = -30
				end
			elseif card:isKindOf("Dismantlement") then
				if to:getArmor() and self:needToThrowArmor(to) then
				elseif to:hasEquip() and self:hasSkills(sgs.lose_equip_skill, to) then
				elseif to:containsTrick("YanxiaoCard") then
				elseif to:containsTrick("supply_shortage") or to:containsTrick("indulgence") then
					intention = -30
				elseif to:getHandcardNum() == 1 and self:needKongcheng(to) then
				else
					intention = 40
				end
			elseif card:isKindOf("IronChain") then
				if to:isChained() then
					intention = -40
				else
					intention = 0
				end
			end
		elseif card:isKindOf("EquipCard") then
			intention = -40
			if card:isKindOf("Weapon") then
				local weapon = to:getWeapon()
				local value = self:evaluateWeapon(card, to)
				if weapon then
					if value < 0 then
						if self:hasSkills(sgs.lose_equip_skill, to) then
							intention = 0
						else
							intention = 80
						end
					elseif value < self:evaluateWeapon(weapon, to) then
						intention = 0
					end
				elseif to:hasSkill("shenji") then
					if value < 0 then
						intention = 80
					else
						intention = 0
					end
				end
			elseif card:isKindOf("Armor") then
				local armor = to:getArmor()
				local value = self:evaluateArmor(card, to)
				if armor then
					if value < 0 then
						if self:hasSkills(sgs.lose_equip_skill, to) then
							intention = 0
						else
							intention = 80
						end
					elseif value < self:evaluateArmor(armor, to) then
						intention = 0
					end
				elseif self:hasSkills("bazhen|yizhong", to) then
					if value < 0 then
						intention = 80
					else
						intention = 0
					end
				end
			end
		end
	end
	if intention ~= 0 then
		sgs.updateIntention(from, to, intention)
	end
end
--[[****************************************************************
	编号：QZ - 002
	武将：公孙木
	称号：好友
	势力：蜀
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：金兰
	描述：你跳过你的一个阶段时，你可以摸两张牌，然后你可以令一名角色使用一张【杀】、装备牌或锦囊牌。
]]--
--player:askForSkillInvoke("qzJinLan", data)
sgs.ai_skill_invoke["qzJinLan"] = true
--room:askForPlayerChosen(player, alives, "qzJinLan", "@qzJinLan", true)
sgs.ai_skill_playerchosen["qzJinLan"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "handcard")
		friends = sgs.reverse(friends)
		for _,friend in ipairs(friends) do
			if self:getOverflow(friend) > 0 then
				return friend
			end
		end
		return friends[1]
	end
end
--room:askForUseCard(target, "Slash,EquipCard,TrickCard+^Nullification", "@qzJinLanUse")
sgs.ai_skill_use["Slash,EquipCard,TrickCard+^Nullification"] = function(self, prompt, method)
	local handcards = self.player:getHandcards()
	local can_use = {}
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			table.insert(can_use, c)
		elseif c:isKindOf("EquipCard") then
			table.insert(can_use, c)
		elseif c:isKindOf("TrickCard") and not c:isKindOf("Nullification") then
			table.insert(can_use, c)
		end
	end
	if #can_use > 0 then
		self:sortByUseValue(can_use)
		for _,c in ipairs(can_use) do
			local dummy_use = {
				isDummy = true,
				to = sgs.SPlayerList(),
			}
			if c:isKindOf("Slash") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card and dummy_use.card:objectName() == c:objectName() then
				local card_str = c:toString()
				if not dummy_use.to:isEmpty() then
					local names = {}
					for _,target in sgs.qlist(dummy_use.to) do
						table.insert(names, target:objectName())
					end
					card_str = card_str .. "->" .. table.concat(names, "+")
				end
				return card_str
			end
		end
	end
	return "."
end
--相关信息
sgs.ai_playerchosen_intention["qzJinLan"] = -40
--[[****************************************************************
	编号：QZ - 003
	武将：陈录
	称号：无存在感
	势力：吴
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：通透
	描述：回合开始前，你可以摸两张牌将武将牌翻面。
]]--
--player:askForSkillInvoke("qzTongTou", data)
sgs.ai_skill_invoke["qzTongTou"] = true
--[[****************************************************************
	编号：QZ - 004
	武将：高傅（常备主公武将）
	称号：学霸班长
	势力：群
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：热肠（阶段技）
	描述：你可以弃置至少一张手牌，令一名其他角色摸等量的牌。若你弃置的牌均为不同花色，你回复1点体力。
]]--
--ReChangCard:Play
local rechang_skill = {
	name = "qzReChang",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() then
			return nil
		elseif self.player:hasUsed("#qzReChangCard") then
			return nil
		end
		return sgs.Card_Parse("#qzReChangCard:.:")
	end,
}
table.insert(sgs.ai_skills, rechang_skill)
sgs.ai_skill_use_func["#qzReChangCard"] = function(card, use, self)
	local NeedRecover = false
	if self.player:isWounded() then
		if self:isWeak() then
			NeedRecover = true
		end
	end
	local handcards = self.player:getHandcards()
	if NeedRecover and handcards:length() >= 2 then
		local spades, hearts, clubs, diamonds = {}, {}, {}, {}
		for _,c in sgs.qlist(handcards) do
			if not c:isKindOf("Peach") then
				local suit = c:getSuit()
				if suit == sgs.Card_Spade then
					table.insert(spades, c)
				elseif suit == sgs.Card_Heart then
					table.insert(hearts, c)
				elseif suit == sgs.Card_Club then
					table.insert(clubs, c)
				elseif suit == sgs.Card_Diamond then
					table.insert(diamonds, c)
				end
			end
		end
		local to_use = {}
		if #spades > 0 then
			self:sortByUseValue(spades, true)
			table.insert(to_use, spades[1])
		end
		if #hearts > 0 then
			self:sortByUseValue(hearts, true)
			table.insert(to_use, hearts[1])
		end
		if #clubs > 0 then
			self:sortByUseValue(clubs, true)
			table.insert(to_use, clubs[1])
		end
		if #diamonds > 0 then
			self:sortByUseValue(diamonds, true)
			table.insert(to_use, diamonds[1])
		end
		if #to_use >= 2 then
			local target = self:findPlayerToDraw(false, #to_use)
			if target then
				local ids = {}
				for _,c in ipairs(to_use) do
					local id = c:getEffectiveId()
					table.insert(ids, id)
				end
				local card_str = "#qzReChangCard:"..table.concat(ids, "+")..":->"..target:objectName()
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then
					use.to:append(target)
				end
				return 
			end
		end
	end
	handcards = sgs.QList2Table(handcards)
	self:sortByUseValue(handcards, true)
	local to_use = {}
	--local peachNum = self:getCardsNum("Peach")
	--local jinkNum = self:getCardsNum("Jink")
	local keepPeach = 1
	local keepJink = 1
	for _,friend in ipairs(self.friends) do
		if self:isWeak(friend) then
			local delt = getBestHp(friend) - friend:getHp()
			keepPeach = keepPeach + math.max(0, delt)
		end
	end
	for _,c in ipairs(handcards) do
		local dummy_use = {
			isDummy = true,
		}
		if c:isKindOf("BasicCard") then
			self:useBasicCard(c, dummy_use)
		elseif c:isKindOf("EquipCard") then
			self:useEquipCard(c, dummy_use)
		elseif c:isKindOf("TrickCard") then
			self:useTrickCard(c, dummy_use)
		end
		if not dummy_use.card then
			if c:isKindOf("Peach") and keepPeach > 0 then
				keepPeach = keepPeach - 1
			elseif c:isKindOf("Jink") and keepJink > 0 then
				keepJink = keepJink - 1
			else
				table.insert(to_use, c:getEffectiveId())
			end
		end
	end
	if #to_use > 0 then
		local target = self:findPlayerToDraw(false, #to_use)
		if target then
			local card_str = "#qzReChangCard:"..table.concat(to_use, "+")..":->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--相关信息
sgs.ai_card_intention["qzReChangCard"] = -80
--[[
	技能：声誉（主公技）
	描述：一名群势力角色的判定阶段开始时，可以令你摸一张牌。
]]--
--player:askForSkillInvoke("qzShengYu", sgs.QVariant(prompt))
sgs.ai_skill_invoke["qzShengYu"] = function(self, data)
	local ai_data = self.player:getTag("qzShengYuData")
	local source = ai_data:toPlayer()
	if source then
		if self:isFriend(source) then
			if source:isKongcheng() and self:needKongcheng(source) then
				return false
			end
			return true
		end
	end
	return false
end
--相关信息
sgs.ai_choicemade_filter["skillInvoke"].qzShengYu = function(self, player, promptlist)
	local data = player:getTag("qzShengYuData")
	local target = data:toPlayer()
	if target and target:objectName() ~= player:objectName() then
		if target:isKongcheng() and self:needKongcheng(target) then
		else
			sgs.updateIntention(player, target, -50)
		end
	end
end
--[[****************************************************************
	编号：QZ - 005
	武将：独孤易
	称号：潜伏的助教
	势力：神
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：幻像
	描述：一名角色使用一张锦囊牌前，你可以弃一张牌，将一张手牌当做同名锦囊牌使用。你以此法造成伤害均视为体力流失。每阶段限一次。
]]--
--room:askForCard(source, "..", prompt, data, "qzHuanXiang")
sgs.ai_skill_cardask["@qzHuanXiang"] = function(self, data, pattern, target, target2, arg, arg2)
	local handcards = self.player:getHandcards()
	if handcards:isEmpty() then
		return "."
	end
	local can_use = {}
	local original = nil
	for _,c in sgs.qlist(handcards) do
		if c:hasFlag("qzHuanXiangSource") then
			original = c
		else
			table.insert(can_use, c)
		end
	end
	local trick = sgs.Sanguosha:cloneCard(arg, sgs.Card_SuitToBeDecided, 0)
	trick:deleteLater()
	if trick:isKindOf("DelayedTrick") and #can_use == 0 then
		return "."
	end
	local weapon, armor = self.player:getWeapon(), self.player:getArmor()
	local dhorse, ohorse = self.player:getDefensiveHorse(), self.player:getOffensiveHorse()
	local treasure = self.player:getTreasure()
	local equips = {}
	if weapon then
		table.insert(equips, weapon)
	end
	if armor then
		table.insert(equips, armor)
	end
	if dhorse then
		table.insert(equips, dhorse)
	end
	if ohorse then
		table.insert(equips, ohorse)
	end
	if treasure then
		table.insert(equips, treasure)
	end
	if #can_use <= 1 and #equips == 0 then
		return "."
	end
	local dummy_use = {
		isDummy = true,
	}
	self:useTrickCard(trick, dummy_use)
	if not dummy_use.card then
		return "."
	end
	local to_discard = nil
	if original and not trick:isKindOf("DelayedTrick") then
		to_discard = original
	elseif armor and self:needToThrowArmor() then
		to_discard = armor
	else
		local may_discard = {}
		local to_use = nil
		if self.player:getPhase() == sgs.Player_Play then
			self:sortByUseValue(can_use, true)
			local value = self:getUseValue(trick)
			for _,c in ipairs(can_use) do
				if not self.player:isJilei(c) then
					if self:getUseValue(c) <= value then
						if not to_use then
							to_use = c
						else
							to_discard = c
							break
						end
					else
						table.insert(may_discard, c)
					end
				end
			end
		else
			self:sortByKeepValue(can_use)
			for _,c in ipairs(can_use) do
				if not self.player:isJilei(c) then
					if self:getKeepValue(c) <= 4.1 then
						if not to_use then
							to_use = c
						else
							to_discard = c
							break
						end
					else
						table.insert(may_discard, c)
					end
				end
			end
		end
		local overflow = self:getOverflow()
		if not to_use and #may_discard > 0 then
			if overflow > 0 then
				to_use = may_discard[1]
				table.remove(may_discard, 1)
				overflow = overflow - 1
			end
		end
		if not to_use then
			return "."
		end
		if not to_discard then
			self:sortByKeepValue(equips)
			if self:hasSkills(sgs.lose_equip_skill) then
				to_discard = equips[1]
			end
		end
		if not to_discard and #may_discard > 0 then
			if overflow > 0 then
				to_discard = may_discard[1]
			end
		end
		if not to_discard and #equips > 0 then
			if not self:isWeak() then
				to_discard = equips[1]
			end
		end
	end
	if to_discard then
		return "$"..to_discard:getEffectiveId()
	end
	return "."
end
--room:askForUseCard(source, "@@qzHuanXiang", prompt)
sgs.ai_skill_use["@@qzHuanXiang"] = function(self, prompt, method)
	local name = self.player:property("qzHuanXiangCardName"):toString()
	local handcards = self.player:getHandcards()
	local can_use = nil
	local trick = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
	trick:deleteLater()
	if trick:isKindOf("DelayedTrick") then
		can_use = {}
		for _,c in sgs.qlist(handcards) do
			if not c:hasFlag("qzHuanXiangSource") then
				table.insert(can_use, c)
			end
		end
	else
		can_use = sgs.QList2Table(handcards)
	end
	if #can_use == 0 then
		return "."
	end
	if self.player:getPhase() == sgs.Player_Play then
		self:sortByUseValue(can_use, true)
	else
		self:sortByKeepValue(can_use)
	end
	local to_use = can_use[1]
	local id = to_use:getEffectiveId()
	local suit = to_use:getSuit()
	local point = to_use:getNumber()
	trick = sgs.Sanguosha:cloneCard(name, suit, point)
	trick:setSkillName("qzHuanXiang")
	trick:addSubcard(id)
	trick:deleteLater()
	local data = self.player:getTag("qzHuanXiangData")
	local use = data:toCardUse()
	if trick:isKindOf("IronChain") then
		for _,target in sgs.qlist(use.to) do
			local state = target:isChained()
			target:setChained(not state)
		end
	end
	local dummy_use = {
		isDummy = true,
		to = sgs.SPlayerList(),
	}
	self:useTrickCard(trick, dummy_use)
	if trick:isKindOf("IronChain") then
		for _,target in sgs.qlist(use.to) do
			local state = target:isChained()
			target:setChained(not state)
		end
	end
	if dummy_use.card then
		local targets = {}
		for _,p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets == 0 then
			return "#qzHuanXiangCard:"..id..":->."
		else
			return "#qzHuanXiangCard:"..id..":->"..table.concat(targets, "+")
		end
	end
	return "."
end
--[[****************************************************************
	编号：QZ - 006
	武将：马芝慧
	称号：班花
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：绝貌
	描述：你成为其他角色使用的【杀】的目标时，你可以选择一项：1、弃一张牌令此【杀】的使用者失去1点体力；2、摸一张牌。
]]--
--room:askForChoice(player, "qzJueMao", choices, data)
sgs.ai_skill_choice["qzJueMao"] = function(self, choices, data)
	local withDiscard = string.find(choices)
	if not withDiscard then
		return "draw"
	end
	local use = data:toCardUse()
	local source = use.from
	if self:isFriend(source) then
		return "draw"
	elseif source:hasSkill("zhaxiang") then
		return "draw"
	end
	if self:canHit(self.player, source) then
		return "discard"
	elseif self:getCardsNum("Jink") > 0 and self.player:getCardCount(true) > 1 then
		return "discard"
	end
	return "draw"
end
--room:askForDiscard(player, "qzJueMao", 1, 1, true, true)
--[[
	技能：指引
	描述：一名角色的判定牌生效前，你可以选择一名角色，令其打出一张手牌替换之。每阶段对每名角色的每个判定原因限一次。
]]--
--room:askForPlayerChosen(player, targets, "qzZhiYin", prompt, true, true)
sgs.ai_skill_playerchosen["qzZhiYin"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "handcard")
		friends = sgs.reverse(friends)
		local data = self.player:getTag("qzZhiYinData")
		local judge = data:toJudge()
		if judge then
			if self:needRetrial(judge) then
				for _,friend in ipairs(friends) do
					local handcards = friend:getHandcards()
					local can_use = nil
					local self_card = false
					if friend:objectName() == self.player:objectName() then
						can_use = sgs.QList2Table(handcards)
						self_card = true
					else
						can_use = {}
						local flag = string.format("visible_%s_%s", self.player:objectName(), friend:objectName())
						for _,c in sgs.qlist(handcards) do
							if c:hasFlag("visible") or c:hasFlag(flag) then
								table.insert(can_use, c)
							end
						end
					end
					local id = self:getRetrialCardId(can_use, judge, self_card)
					if id > 0 then
						return friend
					end
				end
			else
				return nil
			end
		end
		for _,friend in ipairs(friends) do
			if hasManJuanEffect(friend) then
				if friend:getHandcardNum() == 1 and self:needKongcheng(friend) then
					return friend
				end
			else
				return friend
			end
		end
		return friends[1]
	end
end
--room:askForCard(target, ".", prompt, data, sgs.Card_MethodResponse, victim, true, "qzZhiYin", true)
sgs.ai_skill_cardask["@qzZhiYinRetrial"] = function(self, data, pattern, target, target2, arg, arg2)
	if self.player:isKongcheng() then
		return "."
	end
	local judge = data:toJudge()
	if judge then
		if self:needRetrial(judge) then
			local handcards = self.player:getHandcards()
			handcards = sgs.QList2Table(handcards)
			local id = self:getRetrialCardId(handcards, judge, true)
			if id > 0 then
				return "$"..id
			end
		end
	end
	return "."
end
--相关信息
sgs.ai_playerchosen_intention["qzZhiYin"] = -50
--[[****************************************************************
	编号：QZ - 007
	武将：李茵妮
	称号：理论派
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：律守
	描述：一名其他角色于其出牌阶段弃置的牌进入弃牌堆后，你可以获得之。
]]--
--p:askForSkillInvoke("qzLvShou", data)
sgs.ai_skill_invoke["qzLvShou"] = function(self, data)
	local move = data:toMoveOneTime()
	local ids = move.card_ids
	if ids:length() == 1 and self.player:isKongcheng() and self:needKongcheng() then
		return false
	end
	return true
end
--[[
	技能：同步（阶段技）
	描述：你可以将X张手牌交给一名其他角色，然后若该角色与你的手牌数不同，视为你对其使用了一张火【杀】（X为你与该角色手牌数之差的一半且至少为1，结果向下取整）。
]]--
--TongBuCard:Play
local tongbu_skill = {
	name = "qzTongBu",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() then
			return nil
		elseif self.player:hasUsed("#qzTongBuCard") then
			return nil
		end
		return sgs.Card_Parse("#qzTongBuCard:.:")
	end,
}
table.insert(sgs.ai_skills, tongbu_skill)
sgs.ai_skill_use_func["#qzTongBuCard"] = function(card, use, self)
	local mynum = self.player:getHandcardNum()
	local good = false
	local target = nil
	if #self.friends_noself > 0 then
		self:sort(self.friends_noself, "defense")
		for _,friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) then
				if not self:willSkipPlayPhase(friend) then
					local num = friend:getHandcardNum()
					local delt = mynum - num
					if delt > 0 then
						local x = math.max(1, math.floor( delt / 2 ))
						local mynumX = mynum - x
						local numX = num + x
						if mynumX == numX then
							target = friend
							good = true
							break
						end
					end
				end
			end
		end
	end
	if not target and #self.enemies > 0 then
		self:sort(self.enemies, "defense")
		local fs = sgs.Sanguosha:cloneCard("fire_slash")
		fs:deleteLater()
		for _,enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, fs, false) then
				if not self:slashProhibit(fs, enemy, self.player) then
					local num = enemy:getHandcardNum()
					local delt = mynum - num
					if delt ~= 0 then
						local x = math.max( 1, math.floor( math.abs(delt / 2 ) ) )
						if x == 1 then
							local mynumX = mynum - x
							local numX = num + x
							if hasManjuanEffect(enemy) then
								numX = num
							end
							if numX ~= mynumX then
								target = enemy
								good = false
								break
							end
						end
					end
				end
			end
		end
	end
	if target then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		self:sortByKeepValue(handcards, good)
		local delt = target:getHandcardNum() - mynum
		local x = math.max(1, math.floor( math.abs( delt / 2) ) ) 
		local to_use = {}
		for index, c in ipairs(handcards) do
			local flag = true
			if not good then
				if isCard("Jink", c, target) then
					flag = false
				end
			end
			if flag then
				if index <= x then
					table.insert(to_use, c:getEffectiveId())
				else
					break
				end
			end
		end
		if #to_use == x then
			local card_str = "#qzTongBuCard:"..table.concat(to_use, "+")..":->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--相关信息
sgs.ai_card_intention["qzTongBuCard"] = function(self, card, from, tos)
	local to = tos[1]
	local x = card:subcardsLength()
	local mynum = from:getHandcardNum() - x
	local num = to:getHandcardNum() + x
	if mynum == num then
		if num == 1 and to:isKongcheng() and self:needKongcheng(to) then
		else
			sgs.updateIntention(from, to, -70)
		end
		return 
	end
	if x > 2 and not hasManjuanEffect(to) then
		sgs.updateIntention(from, to, -40)
		return 
	end
	local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if self:slashIsEffective(slash, to, from) then
		if self:needToLoseHp(to, from, true) then
		else
			sgs.updateIntention(from, to, 60)
		end
	else
		if num == 1 and to:isKongcheng() and self:needKongcheng(to) then
		else
			sgs.updateIntention(from, to, -15)
		end
	end
end
--[[****************************************************************
	编号：QZ - 008
	武将：张雅晨
	称号：主监考
	势力：吴
	性别：女
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：音难
	描述：一名其他角色的回合结束时，你可以交给其一张牌。该角色的下个回合开始时，若其在你的攻击范围内且该牌为该角色的手牌，你令其失去1点体力。
]]--
--room:askForCard(source, "..", prompt, data, sgs.Card_MethodNone, player, false, "qzYinNan")
sgs.ai_skill_cardask["@qzYinNan"] = function(self, data, pattern, target, target2, arg, arg2)
	if self.player:isNude() then
		return "."
	end
	if target then
		if self.player:inMyAttackRange(target) then
			if self:isFriend(target) then
			elseif self:isEnemy(target) then
				local handcards = self.player:getHandcards()
				handcards = sgs.QList2Table(handcards)
				self:sortByKeepValue(handcards)
				for _,c in ipairs(handcards) do
					if isCard("Peach", c, target) then
					elseif isCard("Jink", c, target) then
					elseif target:getHp() <= 1 and isCard("Analeptic", c, target) then
					elseif isCard("ExNihilo", c, target) then
					else
						return c:getEffectiveId()
					end
				end
			elseif self:getOverflow() > 0 then
				local to_discard = self:askForDiscard("dummy", 1, 1, false, true)
				return to_discard[1]
			end
		else
			if self:isFriend(target) then
				if self:getOverflow() > 0 then
					local to_discard = self:askForDiscard("dummy", 1, 1, false, true)
					return to_discard[1]
				end
			end
		end
	end
	return "."
end
--[[****************************************************************
	编号：QZ - 009
	武将：王兴
	称号：副监考
	势力：群
	性别：男
	体力上限：5勾玉
]]--****************************************************************
--[[
	技能：运衰（锁定技）
	描述：你或你攻击范围内的角色于其出牌阶段第一次使用【杀】或非延时性锦囊牌时，若该牌没有指定其自身为目标，该角色选择一项：成为该牌的目标，或失去1点体力。
]]--
--room:askForChoice(player, "qzYunShuai", "target+losehp", data)
sgs.ai_skill_choice["qzYunShuai"] = function(self, choices, data)
	local withLoseHp = string.find(choices, "losehp")
	local withTarget = string.find(choices, "target")
	if withLoseHp then
		if self:needToLoseHp() then
			return "losehp"
		end
	end
	if withTarget then
		return "target"
	end
	if withLoseHp then
		return "losehp"
	end
end
--room:askForPlayerChosen(player, victims, "qzYunShuai", "@qzYunShuai")
sgs.ai_skill_playerchosen["qzYunShuai"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
--[[****************************************************************
	编号：QZ - 010
	武将：宁江
	称号：任课教师
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：信仰
	描述：你需要使用或打出一张基本牌时，你可以翻开牌堆顶的一张牌，若该牌不为基本牌，你将其作为此基本牌使用或打出，否则你将其置于你的武将牌上，称为“念”，且本阶段你不能再次发动“信仰”。回合结束时，若“念”不少于10张，你可以弃置所有的“念”，令一名角色增加或失去1点体力上限。
]]--
--room:askForChoice(player, "qzXinYangUseCard", choices)
sgs.ai_skill_choice["qzXinYangUseCard"] = function(self, choices, data)
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	end
	if string.find(choices, "peach") then
		return "peach"
	elseif string.find(choices, "analeptic") then
		return "analeptic"
	end
	return items[math.random(1, #items)]
end
--room:askForChoice(player, "qzXinYangResponseCard", choices)
sgs.ai_skill_choice["qzXinYangResponseCard"] = function(self, choices, data)
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	end
	if string.find(choices, "analeptic") then
		return "analeptic"
	elseif string.find(choices, "peach") then
		return "peach"
	end
	return items[math.random(1, #items)]
end
--room:askForUseCard(player, "@@qzXinYang", prompt)
sgs.ai_skill_use["@@qzXinYang"] = function(self, prompt, method)
	local id = self.player:getMark("qzXinYangCardID")
	local suit = self.player:getMark("qzXinYangCardSuit")
	local point = self.player:getMark("qzXinYangCardPoint")
	local name = self.player:property("qzXinYangCardName"):toString()
	local card = sgs.Sanguosha:cloneCard(name, suit, point)
	card:addSubcard(id)
	card:setSkillName("qzXinYang")
	card:deleteLater()
	local dummy_use = {
		isDummy = true,
		to = sgs.SPlayerList(),
	}
	self:useBasicCard(card, dummy_use)
	if dummy_use.to:isEmpty() then
		return "."
	end
	local targets = {}
	for _,p in sgs.qlist(dummy_use.to) do
		table.insert(targets, p:objectName())
	end
	return "#qzXinYangSelectCard:.:->"..table.concat(targets, "+")
end
--XinYangCard:Play
local xinyang_skill = {
	name = "qzXinYang",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasFlag("qzXinYangFailed") then
			return nil
		elseif sgs.Slash_IsAvailable(self.player) then
			return sgs.Card_Parse("#qzXinYangCard:.:")
		elseif self.player:getLostHp() > 0 then
			return sgs.Card_Parse("#qzXinYangCard:.:")
		elseif sgs.Analeptic_IsAvailable(self.player) then
			return sgs.Card_Parse("#qzXinYangCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xinyang_skill)
sgs.ai_skill_use_func["#qzXinYangCard"] = function(card, use, self)
	use.card = card
end
--XinYangCard:Response
sgs.ai_cardsview_valuable["qzXinYang"] = function(self, class_name, player)
	if player:hasFlag("qzXinYangFailed") then
	elseif class_name == "Slash" then
		return "#qzXinYangCard:.:slash"
	elseif class_name == "Jink" then
		return "#qzXinYangCard:.:jink"
	elseif class_name == "Peach" then
		return "#qzXinYangCard:.:peach"
	elseif class_name == "Analeptic" then
		return "#qzXinYangCard:.:analeptic"
	elseif class_name == "ThunderSlash" then
		return "#qzXinYangCard:.:thunder_slash"
	elseif class_name == "FireSlash" then
		return "#qzXinYangCard:.:fire_slash"
	end
end
--player:askForSkillInvoke("qzXinYang", data)
sgs.ai_skill_invoke["qzXinYang"] = true
--room:askForPlayerChosen(player, alives, "qzXinYangEffect", "@qzXinYangEffect", true)
sgs.ai_skill_playerchosen["qzXinYangEffect"] = function(self, targets)
	local friends, unknowns, enemies = {}, {}, {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		elseif self:isEnemy(p) then
			table.insert(enemies, p)
		else
			table.insert(unknowns, p)
		end
	end
	local skills = "yingzi|zaiqi|yinghun|hunzi|juejing|ganlu|zishou|miji|chizhong|xueji"..
						"|quji|xuehen|shude|neojushou|tannang|fangzhu|nosshangshi|nosmiji"
	if #enemies > 0 then
		self:sort(enemies, "threat")
		for _,enemy in ipairs(enemies) do
			if self:hasSkills(skills, enemy) then
				return enemy
			end
		end
	end
	if #friends > 0 then
		self:sort(friends, "threat")
		for _,friend in ipairs(friends) do
			if self:hasSkills(skills, friend) then
				return friend
			end
		end
	end
	if #enemies > 0 then
		local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
		for _,enemy in ipairs(enemies) do
			if enemy:getMaxHp() == 1 then
				if flag and enemy:isLord() then
				else
					return enemy
				end
			end
		end
	end
	if #friends > 0 then
		local compare_func = function(a, b)
			return a:getMaxHp() < b:getMaxHp()
		end
		table.sort(friends, compare_func)
		return friends[1]
	end
	if #unknowns > 0 then
		self:sort(unknowns, "threat")
		local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
		for _,enemy in ipairs(unknowns) do
			if enemy:getMaxHp() > 1 then
				return enemy
			elseif flag and enemy:isLord() then
			else
				return enemy
			end
		end
	end
end
--room:askForChoice(player, "qzXinYang", "up+down", ai_data)
sgs.ai_skill_choice["qzXinYang"] = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return "up"
	end
	return "down"
end
--相关信息
sgs.ai_choicemade_filter["skillChoice"].qzXinYang = function(self, player, promptlist)
	local data = player:getTag("qzXinYangData")
	local target = data:toPlayer()
	if target and target:objectName() ~= player:objectName() then
		local choice = promptlist[#promptlist]
		if choice == "up" then
			sgs.updateIntention(player, target, -100)
		elseif choice == "down" then
			sgs.updateIntention(player, target, 100)
		end
	end
end
--[[
	太阳神三国杀卡牌扩展包·乌有中学（AI部分）
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	卡牌总数：2
	卡牌一览：
		1、神龙玉佩（装备牌·防具，方块9）
		2、杀（基本牌·进攻牌，黑桃2）
]]--
--[[****************************************************************
	卡牌：神龙玉佩
	类别：装备牌·防具
	花色：方块
	点数：9
	效果：1、你装备【神龙玉佩】时，若你没有技能“享乐”，你获得技能“享乐”，否则你获得技能“神龙玉佩”
		2、你失去装备区中的【神龙玉佩】时，你失去因此牌获得的技能并回复1点体力。
]]--****************************************************************
sgs.ai_armor_value["qzShenLongYuPei"] = function(player, self)
	if player:hasSkill("xiangle") then
		return 5
	end
	if player:getLostHp() > 0 then
		return 1.2
	end
	return 4.2
end
local system_needToThrowArmor = SmartAI.needToThrowArmor
function SmartAI:needToThrowArmor(player)
	if system_needToThrowArmor(self, player) then
		return true
	end
	player = player or self.player
	local armor = player:getArmor()
	if armor and armor:isKindOf("qzShenLongYuPei") and player:hasArmorEffect("qzShenLongYuPei") then
		if player:getLostHp() > 0 then
			if player:objectName() == self.player:objectName() then
				return true
			elseif self:isWeak(player) then
				local skills = "longhun|noslonghun|noslijian|lijian|jujian|nosjujian|zhiheng|mingce|yongsi|fenxun"..
				"|gongqi|jilve|qingcheng|neoluoyi|diyyicong|jijiu"
				if not self:hasSkills(skills, player) then
					return true
				end
			end
		end
	end
	return false
end
--[[
	技能：神龙玉佩（锁定技）
	描述：你受到【杀】或【决斗】造成的伤害时，伤害来源须弃置一张基本牌，否则此伤害-1。
]]--
--room:askForCard(source, ".Basic", prompt, ai_data)
sgs.ai_skill_cardask["@qzShenLongYuPeiSkill"] = function(self, data, pattern, target, target2, arg, arg2)
	local victim = data:toPlayer()
	if self:isFriend(victim) then
		return "."
	end
end
--[[****************************************************************
	卡牌：杀
	类别：基本牌·进攻牌
	花色：黑桃
	点数：2
]]--****************************************************************