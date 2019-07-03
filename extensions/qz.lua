--[[
	太阳神三国杀武将扩展包·乌有中学
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
module("extensions.qz", package.seeall)
extension = sgs.Package("qz", sgs.Package_GeneralPack)
json = require("json")
--翻译信息
sgs.LoadTranslationTable{
	["qz"] = "乌有中学",
}
--[[****************************************************************
	编号：QZ - 001
	武将：梁华
	称号：主人公
	势力：魏
	性别：男
	体力上限：4勾玉
]]--****************************************************************
LiangHua = sgs.General(extension, "qzLiangHua", "wei", 4)
--翻译信息
sgs.LoadTranslationTable{
	["qzLiangHua"] = "梁华",
	["&qzLiangHua"] = "梁华",
	["#qzLiangHua"] = "主人公",
	["designer:qzLiangHua"] = "DGAH",
	["cv:qzLiangHua"] = "无",
	["illustrator:qzLiangHua"] = "昵图网",
}
--[[
	技能：漫游
	描述：你的【杀】被【闪】抵消时，你可以进行一次判定。然后你可以令一名角色获得此判定牌并对其自己使用之。
]]--
ManYou = sgs.CreateTriggerSkill{
	name = "qzManYou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashMissed},
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke("qzManYou", data) then
			local room = player:getRoom()
			room:broadcastSkillInvoke("qzManYou") --播放配音
			room:notifySkillInvoked(player, "qzManYou") --显示技能发动
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.reason = "qzManYou"
			judge.pattern = "."
			room:judge(judge)
			local card = judge.card
			local id = card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_DiscardPile then
				local alives = room:getAlivePlayers()
				local prompt = string.format("@qzManYou:::%s:", card:objectName())
				local ai_data = sgs.QVariant()
				ai_data:setValue(judge)
				player:setTag("qzManYouData", ai_data)
				local target = room:askForPlayerChosen(player, alives, "qzManYou", prompt, true)
				player:removeTag("qzManYouData")
				if target then
					room:obtainCard(target, card, true)
					local owner = room:getCardOwner(id)
					if owner and owner:objectName() == target:objectName() then
						local can_use = true
						if target:isProhibited(target, card) then
							can_use = false
						elseif card:isKindOf("Jink") or card:isKindOf("Nullification") then
							can_use = false
						elseif card:isKindOf("Snatch") or card:isKindOf("Dismantlement") then
							if target:getHandcardNum() == 1 then
								if not target:hasEquip() then
									if target:getJudgingArea():isEmpty() then
										can_use = false
									end
								end
							end
						elseif card:isKindOf("Peach") then
							if target:getLostHp() == 0 then
								can_use = false
							end
						elseif card:isKindOf("Collateral") then
							if not target:getWeapon() then
								can_use = false
							end
						elseif card:isKindOf("DelayedTrick") then
							if target:containsTrick(card:objectName()) then
								can_use = false
							end
						end
						if can_use then
							if card:isKindOf("Collateral") then
								local victims = sgs.SPlayerList()
								local others = room:getOtherPlayers(target)
								for _,p in sgs.qlist(others) do
									if target:canSlash(p) then
										victims:append(p)
									end
								end
								if victims:isEmpty() then
									local msg = sgs.LogMessage()
									msg.type = "#qzManYouFail"
									msg.from = target
									msg.arg = "qzManYou"
									room:sendLog(msg) --发送提示信息
								else
									prompt = string.format("@qzManYouVictim:%s:", player:objectName())
									local victim = room:askForPlayerChosen(target, victims, "qzManYouVictim", prompt)
									local use = sgs.CardUseStruct()
									use.from = target
									use.to:append(target)
									use.to:append(victim)
									use.card = card
									room:useCard(use, false)
								end
							else
								local use = sgs.CardUseStruct()
								use.from = target
								if card:targetFixed() then
									room:setCardFlag(card, "qzManYouToSelf")
								else
									use.to:append(target)
								end
								use.card = card
								room:useCard(use, false)
							end
						else
							local msg = sgs.LogMessage()
							msg.type = "#qzManYouProhibit"
							msg.from = target
							msg.arg = "qzManYou"
							msg.arg2 = card:objectName()
							room:sendLog(msg) --发送提示信息
						end
					end
				end
			end
		end
		return false
	end,
}
ManYouEffect = sgs.CreateTriggerSkill{
	name = "#qzManYou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local trick = use.card
		if trick:hasFlag("qzManYouToSelf") then
			local room = player:getRoom()
			local source = use.from
			if source and source:objectName() == player:objectName() then
				room:setCardFlag(trick, "-qzManYouToSelf")
				if trick:isKindOf("AOE") or trick:isKindOf("GlobalEffect") then
					local newTargets = sgs.SPlayerList()
					newTargets:append(source)
					use.to = newTargets
					data:setValue(use)
					local msg = sgs.LogMessage()
					msg.type = "#qzManYouToSelf"
					msg.from = player
					msg.arg = trick:objectName()
					msg.arg2 = "qzManYou"
					room:sendLog(msg) --发送提示信息
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("qzManYou", "#qzManYou")
--添加技能
LiangHua:addSkill(ManYou)
LiangHua:addSkill(ManYouEffect)
--翻译信息
sgs.LoadTranslationTable{
	["qzManYou"] = "漫游",
	[":qzManYou"] = "你的【杀】被【闪】抵消时，你可以进行一次判定。然后你可以令一名角色获得此判定牌并对其自己使用之。",
	["@qzManYou"] = "您可以令一名角色获得此【%arg】并对其自己使用之",
	["#qzManYouProhibit"] = "%from 不能对自己使用此【%arg2】，取消“%arg”的后续效果",
	["#qzManYouFail"] = "%from 的范围内没有可以使用【杀】的目标角色，取消“%arg”的后续效果",
	["#qzManYouToSelf"] = "受“%arg2”的影响，将 %from 修改为此【%arg】的唯一目标",
	["qzManYouVictim"] = "漫游",
	["@qzManYouVictim"] = "%from 令你对你自己使用了【借刀杀人】，请指定你使用【杀】的目标",
}
--[[****************************************************************
	编号：QZ - 002
	武将：公孙木
	称号：好友
	势力：蜀
	性别：男
	体力上限：4勾玉
]]--****************************************************************
GongSunMu = sgs.General(extension, "qzGongSunMu", "shu", 4)
--翻译信息
sgs.LoadTranslationTable{
	["qzGongSunMu"] = "公孙木",
	["&qzGongSunMu"] = "公孙木",
	["#qzGongSunMu"] = "好友",
	["designer:qzGongSunMu"] = "DGAH",
	["cv:qzGongSunMu"] = "无",
	["illustrator:qzGongSunMu"] = "昵图网",
}
--[[
	技能：金兰
	描述：你跳过你的一个阶段时，你可以摸两张牌，然后你可以令一名角色使用一张【杀】、装备牌或锦囊牌。
]]--
JinLan = sgs.CreateTriggerSkill{
	name = "qzJinLan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseSkipping},
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke("qzJinLan", data) then
			local room = player:getRoom()
			room:broadcastSkillInvoke("qzJinLan") --播放配音
			room:notifySkillInvoked(player, "qzJinLan") --显示技能发动
			room:drawCards(player, 2, "qzJinLan")
			local alives = room:getAlivePlayers()
			local target = room:askForPlayerChosen(player, alives, "qzJinLan", "@qzJinLan", true)
			if target then
				room:askForUseCard(target, "Slash,EquipCard,TrickCard+^Nullification", "@qzJinLanUse")
			end
		end
		return false
	end,
}
--添加技能
GongSunMu:addSkill(JinLan)
--翻译信息
sgs.LoadTranslationTable{
	["qzJinLan"] = "金兰",
	[":qzJinLan"] = "你跳过你的一个阶段时，你可以摸两张牌，然后你可以令一名角色使用一张【杀】、装备牌或锦囊牌。",
	["@qzJinLan"] = "您可以发动“金兰”令一名角色使用一张【杀】、装备牌或锦囊牌",
	["@qzJinLanUse"] = "您可以使用一张【杀】、装备牌或锦囊牌",
}
--[[****************************************************************
	编号：QZ - 003
	武将：陈录
	称号：无存在感
	势力：吴
	性别：男
	体力上限：4勾玉
]]--****************************************************************
ChenLu = sgs.General(extension, "qzChenLu", "wu", 4)
--翻译信息
sgs.LoadTranslationTable{
	["qzChenLu"] = "陈录",
	["&qzChenLu"] = "陈录",
	["#qzChenLu"] = "无存在感",
	["designer:qzChenLu"] = "DGAH",
	["cv:qzChenLu"] = "无",
	["illustrator:qzChenLu"] = "昵图网",
}
--[[
	技能：通透
	描述：回合开始前，你可以摸两张牌将武将牌翻面。
]]--
TongTou = sgs.CreateTriggerSkill{
	name = "qzTongTou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke("qzTongTou", data) then
			local room = player:getRoom()
			room:broadcastSkillInvoke("qzTongTou") --播放配音
			room:notifySkillInvoked(player, "qzTongTou") --显示技能发动
			room:drawCards(player, 2, "qzTongTou")
			player:turnOver()
		end
		return false
	end,
}
--添加技能
ChenLu:addSkill(TongTou)
--翻译信息
sgs.LoadTranslationTable{
	["qzTongTou"] = "通透",
	[":qzTongTou"] = "回合开始前，你可以摸两张牌将武将牌翻面。",
	["$qzTongTou"] = "技能 通透 的台词",
}
--[[****************************************************************
	编号：QZ - 004
	武将：高傅（常备主公武将）
	称号：学霸班长
	势力：群
	性别：男
	体力上限：4勾玉
]]--****************************************************************
GaoFu = sgs.General(extension, "qzGaoFu$", "qun", 4)
--翻译信息
sgs.LoadTranslationTable{
	["qzGaoFu"] = "高傅",
	["&qzGaoFu"] = "高傅",
	["#qzGaoFu"] = "学霸班长",
	["designer:qzGaoFu"] = "DGAH",
	["cv:qzGaoFu"] = "无",
	["illustrator:qzGaoFu"] = "设计之家",
}
--[[
	技能：热肠（阶段技）
	描述：你可以弃置至少一张手牌，令一名其他角色摸等量的牌。若你弃置的牌均为不同花色，你回复1点体力。
]]--
ReChangCard = sgs.CreateSkillCard{
	name = "qzReChangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("qzReChang") --播放配音
		room:notifySkillInvoked(source, "qzReChang") --显示技能发动
		local subcards = self:getSubcards()
		local count = subcards:length()
		room:drawCards(targets[1], count, "qzReChang")
		if count > 1 and source:isWounded() then
			local suits = {}
			for _,id in sgs.qlist(subcards) do
				local card = sgs.Sanguosha:getCard(id)
				local suit = card:getSuitString()
				if suits[suit] then
					return
				else
					suits[suit] = true
				end
			end
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = 1
			room:recover(source, recover)
		end
	end,
}
ReChang = sgs.CreateViewAsSkill{
	name = "qzReChang",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = ReChangCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then 
			return false
		elseif player:hasUsed("#qzReChangCard") then
			return false
		end
		return true
	end,
}
--添加技能
GaoFu:addSkill(ReChang)
--翻译信息
sgs.LoadTranslationTable{
	["qzReChang"] = "热肠",
	[":qzReChang"] = "<font color=\"green\"><b>阶段技</b></font>，你可以弃置至少一张手牌，令一名其他角色摸等量的牌。若你弃置的牌均为不同花色，你回复1点体力。",
	["qzrechang"] = "热肠",
}
--[[
	技能：声誉（主公技）
	描述：一名群势力角色的判定阶段开始时，可以令你摸一张牌。
]]--
ShengYu = sgs.CreateTriggerSkill{
	name = "qzShengYu$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Judge then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				if source:hasLordSkill("qzShengYu") then
					local prompt = string.format("@qzShengYu:%s:", source:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(source)
					player:setTag("qzShengYuData", ai_data)
					local invoke = player:askForSkillInvoke("qzShengYu", sgs.QVariant(prompt))
					player:removeTag("qzShengYuData")
					if invoke then
						room:broadcastSkillInvoke("qzShengYu") --播放配音
						room:notifySkillInvoked(source, "qzShengYu") --显示技能发动
						room:drawCards(source, 1, "qzShengYu")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getKingdom() == "qun"
	end,
}
--添加技能
GaoFu:addSkill(ShengYu)
--翻译信息
sgs.LoadTranslationTable{
	["qzShengYu"] = "声誉",
	[":qzShengYu"] = "<font color=\"orange\"><b>主公技</b></font>, 一名群势力角色的判定阶段开始时，可以令你摸一张牌。",
	["qzShengYu:@qzShengYu"] = "您可以发动 %src 的主公技“声誉”，令 %src 摸一张牌",
}
--[[****************************************************************
	编号：QZ - 005
	武将：独孤易
	称号：潜伏的助教
	势力：神
	性别：男
	体力上限：4勾玉
]]--****************************************************************
DuGuYi = sgs.General(extension, "qzDuGuYi", "god", 4)
--翻译信息
sgs.LoadTranslationTable{
	["qzDuGuYi"] = "独孤易",
	["&qzDuGuYi"] = "独孤易",
	["#qzDuGuYi"] = "潜伏的助教",
	["designer:qzDuGuYi"] = "DGAH",
	["cv:qzDuGuYi"] = "无",
	["illustrator:qzDuGuYi"] = "红动中国",
}
--[[
	技能：幻像
	描述：一名角色使用一张锦囊牌前，你可以弃一张牌，将一张手牌当做同名锦囊牌使用。你以此法造成伤害均视为体力流失。每阶段限一次。
]]--
function getHXCard(skillcard, user)
	local subcards = skillcard:getSubcards()
	local id = subcards:first()
	local c = sgs.Sanguosha:getCard(id)
	local suit = c:getSuit()
	local point = c:getNumber()
	local name = user:property("qzHuanXiangCardName"):toString()
	local card = sgs.Sanguosha:cloneCard(name, suit, point)
	card:addSubcard(id)
	card:setSkillName("qzHuanXiang")
	return card
end
HuanXiangCard = sgs.CreateSkillCard{
	name = "qzHuanXiangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local card = getHXCard(self, sgs.Self)
		if card:targetFixed() then 
			return false 
		else
			local selected = sgs.PlayerList()
			for _,p in ipairs(targets) do
				selected:append(p)
			end
			return card:targetFilter(selected, to_select, sgs.Self)
		end
	end,
	feasible = function(self, targets)
		local card = getHXCard(self, sgs.Self)
		if card:targetFixed() then 
			return true
		else
			local selected = sgs.PlayerList()
			for _,p in ipairs(targets) do
				selected:append(p)
			end
			return card:targetsFeasible(selected, sgs.Self)
		end
	end,
	on_validate = function(self, use)
		local source = use.from
		local card = getHXCard(self, source)
		if card:isKindOf("Collateral") then
			local targets = use.to
			for _,target in sgs.qlist(targets) do
				local tag = target:getTag("collateralVictim")
				target:setTag("qzHuanXiangCollateralVictim", tag)
			end
		end
		return card
	end,
}
HuanXiangVS = sgs.CreateViewAsSkill{
	name = "qzHuanXiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then
			return false
		elseif to_select:isKindOf("DelayedTrick") and to_select:hasFlag("qzHuanXiangSource") then
			return false
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = HuanXiangCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@qzHuanXiang"
	end,
}
HuanXiang = sgs.CreateTriggerSkill{
	name = "qzHuanXiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.EventPhaseStart, sgs.CardEffect, sgs.CardFinished},
	view_as_skill = HuanXiangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local user = use.from
			if user and user:objectName() == player:objectName() then
				local trick = use.card
				if trick:getSkillName() == "qzHuanXiang" then
					return false
				elseif trick:isKindOf("TrickCard") and not trick:isKindOf("Nullification") then
					local alives = room:getAlivePlayers()
					for _,source in sgs.qlist(alives) do
						if source:hasSkill("qzHuanXiang") then
							if source:getMark("qzHuanXiangUsed") == 0 then
								if not source:isNude() then
									local prompt = string.format("@qzHuanXiang:%s::%s:", user:objectName(), trick:objectName())
									local card = room:askForCard(source, "..", prompt, data, "qzHuanXiang")
									if card then
										room:setCardFlag(trick, "qzHuanXiangSource")
										room:setPlayerMark(source, "qzHuanXiangUsed", 1)
										local name = trick:objectName()
										room:setPlayerProperty(source, "qzHuanXiangCardName", sgs.QVariant(name))
										prompt = string.format("@qzHuanXiangUse:::%s:", name)
										source:setTag("qzHuanXiangData", data) --For AI
										room:askForUseCard(source, "@@qzHuanXiang", prompt)
										source:removeTag("qzHuanXiangData") --For AI
										room:setPlayerProperty(source, "qzHuanXiangCardName", sgs.QVariant(""))
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local alives = room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				room:setPlayerMark(p, "qzHuanXiangUsed", 0)
			end
		elseif event == sgs.CardEffect then
			local effect = data:toCardEffect()
			local trick = effect.card
			if trick:hasFlag("qzHuanXiangSource") then
				local victim = effect.to
				if victim:isDead() then
					return true
				elseif trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement") then
					if victim:isAllNude() then
						return true
					end
				elseif trick:isKindOf("FireAttack") then
					if victim:isKongcheng() then
						return true
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local trick = use.card
			if trick:hasFlag("qzHuanXiangSource") then
				room:setCardFlag(trick, "-qzHuanXiangSource")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
HuanXiangEffect = sgs.CreateTriggerSkill{
	name = "#qzHuanXiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Predamage then
			local damage = data:toDamage()
			local trick = damage.card
			if trick and trick:getSkillName() == "qzHuanXiang" then
				local msg = sgs.LogMessage()
				msg.type = "#qzHuanXiang"
				msg.from = player
				msg.arg = "qzHuanXiang"
				msg.arg2 = trick:objectName()
				room:sendLog(msg) --发送提示信息
				local victim = damage.to
				local count = damage.damage
				room:loseHp(victim, count)
				return true
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local trick = use.card
			if trick:isKindOf("Collateral") then
				if trick:getSkillName() == "qzHuanXiang" then
					local targets = use.to
					for _,target in sgs.qlist(targets) do
						local tag = target:getTag("qzHuanXiangCollateralVictim")
						target:setTag("collateralVictim", tag)
						target:removeTag("qzHuanXiangCollateralVictim")
					end
				end
			end
		end
		return false
	end,
}
extension:insertRelatedSkills("qzHuanXiang", "#qzHuanXiang")
--添加技能
DuGuYi:addSkill(HuanXiang)
DuGuYi:addSkill(HuanXiangEffect)
--翻译信息
sgs.LoadTranslationTable{
	["qzHuanXiang"] = "幻像",
	[":qzHuanXiang"] = "一名角色使用一张锦囊牌前，你可以弃一张牌，将一张手牌当做同名锦囊牌使用。你以此法造成伤害均视为体力流失。每阶段限一次。",
	["@qzHuanXiang"] = "%src 使用了【%arg】，您可以弃一张牌（包括装备）发动技能“幻像”",
	["@qzHuanXiangUse"] = "您可以将一张手牌当做【%arg】使用",
	["~qzHuanXiang"] = "选择一些目标角色->点击“确定”",
	["#qzHuanXiang"] = "受 %from 的技能“%arg”的影响，此【%arg2】造成的伤害视为体力流失",
}
--[[****************************************************************
	编号：QZ - 006
	武将：马芝慧
	称号：班花
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
MaZhiHui = sgs.General(extension, "qzMaZhiHui", "wei", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["qzMaZhiHui"] = "马芝慧",
	["&qzMaZhiHui"] = "马芝慧",
	["#qzMaZhiHui"] = "班花",
	["designer:qzMaZhiHui"] = "DGAH",
	["cv:qzMaZhiHui"] = "无",
	["illustrator:qzMaZhiHui"] = "设计之家",
}
--[[
	技能：绝貌
	描述：你成为其他角色使用的【杀】的目标时，你可以选择一项：1、弃一张牌令此【杀】的使用者失去1点体力；2、摸一张牌。
]]--
JueMao = sgs.CreateTriggerSkill{
	name = "qzJueMao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local slash = use.card
		if slash:isKindOf("Slash") then
			local source = use.from
			if source and source:objectName() ~= player:objectName() then
				if use.to:contains(player) then
					local choices = {}
					if source:isAlive() and not player:isNude() then
						table.insert(choices, "discard")
					end
					table.insert(choices, "draw")
					table.insert(choices, "cancel")
					choices = table.concat(choices, "+")
					local room = player:getRoom()
					local choice = room:askForChoice(player, "qzJueMao", choices, data)
					if choice == "discard" then
						room:broadcastSkillInvoke("qzJueMao", 1) --播放配音
						room:notifySkillInvoked(player, "qzJueMao") --显示技能发动
						if room:askForDiscard(player, "qzJueMao", 1, 1, true, true) then
							room:loseHp(source, 1)
						end
					elseif choice == "draw" then
						room:broadcastSkillInvoke("qzJueMao", 2) --播放配音
						room:notifySkillInvoked(player, "qzJueMao") --显示技能发动
						room:drawCards(player, 1, "qzJueMao")
					end
				end
			end
		end
		return false
	end,
}
--添加技能
MaZhiHui:addSkill(JueMao)
--翻译信息
sgs.LoadTranslationTable{
	["qzJueMao"] = "绝貌",
	[":qzJueMao"] = "你成为其他角色使用的【杀】的目标时，你可以选择一项：1、弃一张牌令此【杀】的使用者失去1点体力；2、摸一张牌。",
	["qzJueMao:discard"] = "弃一张牌令来源失去1点体力",
	["qzJueMao:draw"] = "摸一张牌",
	["qzJueMao:cancel"] = "不发动“绝貌”",
}
--[[
	技能：指引
	描述：一名角色的判定牌生效前，你可以选择一名角色，令其打出一张手牌替换之。每阶段对每名角色的每个判定原因限一次。
]]--
ZhiYin = sgs.CreateTriggerSkill{
	name = "qzZhiYin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(alives) do
			if not p:isKongcheng() then
				targets:append(p)
			end
		end
		if targets:isEmpty() then
			return false
		end
		local judge = data:toJudge()
		local reason = judge.reason
		local victim = judge.who
		local records = player:getTag("qzZhiYinRecord"):toString() or ""
		records = records:split("|")
		for _,record in ipairs(records) do
			local details = record:split(":")
			local invoked, name = details[1], details[2]
			if invoked == reason and name == victim:objectName() then
				return false
			end
		end
		local prompt = string.format("@qzZhiYin:%s::%s:", victim:objectName(), reason)
		player:setTag("qzZhiYinData", data)
		local target = room:askForPlayerChosen(player, targets, "qzZhiYin", prompt, true, true)
		player:removeTag("qzZhiYinData")
		if target then
			room:broadcastSkillInvoke("qzZhiYin") --播放配音
			room:notifySkillInvoked(player, "qzZhiYin") --显示技能发动
			local record = string.format("%s:%s", reason, victim:objectName())
			table.insert(records, record)
			records = table.concat(records, "|")
			player:setTag("qzZhiYinRecord", sgs.QVariant(records))
			local msg = sgs.LogMessage()
			msg.type = "#qzZhiYin"
			msg.from = player
			msg.to:append(target)
			msg.arg = "qzZhiYin"
			room:sendLog(msg) --发送提示信息
			prompt = string.format("@qzZhiYinRetrial:%s::%s:", victim:objectName(), reason)
			local card = room:askForCard(target, ".", prompt, data, sgs.Card_MethodResponse, victim, true, "qzZhiYin", true)
			if card then
				room:retrial(card, target, judge, "qzZhiYin", true)
			end
		end
		return false
	end,
}
ZhiYinClear = sgs.CreateTriggerSkill{
	name = "#qzZhiYinClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		for _,source in sgs.qlist(alives) do
			if source:hasSkill("qzZhiYin") then
				source:removeTag("qzZhiYinRecord")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("qzZhiYin", "#qzZhiYinClear")
--添加技能
MaZhiHui:addSkill(ZhiYin)
MaZhiHui:addSkill(ZhiYinClear)
--翻译信息
sgs.LoadTranslationTable{
	["qzZhiYin"] = "指引",
	[":qzZhiYin"] = "一名角色的判定牌生效前，你可以选择一名角色，令其打出一张手牌替换之。每阶段对每名角色的每个判定原因限一次。",
	["@qzZhiYin"] = "您可以发动“指引”令一名角色更改 %src 的 %arg 判定",
	["#qzZhiYin"] = "%from 发动了“%arg”，指定 %to 更改本次判定",
	["@qzZhiYinRetrial"] = "您可以打出一张手牌修改 %src 的 %arg 判定",
}
--[[****************************************************************
	编号：QZ - 007
	武将：李茵妮
	称号：理论派
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
LiYinNi = sgs.General(extension, "qzLiYinNi", "shu", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["qzLiYinNi"] = "李茵妮",
	["&qzLiYinNi"] = "李茵妮",
	["#qzLiYinNi"] = "理论派",
	["designer:qzLiYinNi"] = "DGAH",
	["cv:qzLiYinNi"] = "无",
	["illustrator:qzLiYinNi"] = "设计之家",
}
--[[
	技能：律守
	描述：一名其他角色于其出牌阶段弃置的牌进入弃牌堆后，你可以获得之。
]]--
LvShou = sgs.CreateTriggerSkill{
	name = "qzLvShou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			local basic = bit32.band(sgs.CardMoveReason_S_MASK_BASIC_REASON, move.reason.m_reason)
			if basic == sgs.CardMoveReason_S_REASON_DISCARD then
				if move.to_place == sgs.Player_DiscardPile then
					local ids = sgs.IntList()
					for index, id in sgs.qlist(move.card_ids) do
						local from = move.from_places:at(index)
						if from == sgs.Player_PlaceHand or from == sgs.Player_PlaceEquip then
							ids:append(id)
						end
					end
					if ids:isEmpty() then
						return false
					end
					local room = player:getRoom()
					local others = room:getOtherPlayers(player)
					for _,p in sgs.qlist(others) do
						if p:hasSkill("qzLvShou") then
							if p:askForSkillInvoke("qzLvShou", data) then
								room:broadcastSkillInvoke("qzLvShou") --播放配音
								room:notifySkillInvoked(p, "qzLvShou") --显示技能发动
								local obtain = sgs.CardsMoveStruct()
								obtain.card_ids = ids
								obtain.to = p
								obtain.to_place = sgs.Player_PlaceHand
								obtain.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, p:objectName())
								room:moveCardsAtomic(obtain, true)
								return false
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target and target:isAlive() then
			return target:getPhase() == sgs.Player_Play
		end
		return false
	end,
}
--添加技能
LiYinNi:addSkill(LvShou)
--翻译信息
sgs.LoadTranslationTable{
	["qzLvShou"] = "律守",
	[":qzLvShou"] = "你可以获得一名其他角色于其出牌阶段弃置的牌。",
}
--[[
	技能：同步（阶段技）
	描述：你可以将X张手牌交给一名其他角色，然后若该角色与你的手牌数不同，视为你对其使用了一张火【杀】（X为你与该角色手牌数之差的一半且至少为1，结果向下取整）。
]]--
TongBuCard = sgs.CreateSkillCard{
	name = "qzTongBuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then
			return false
		else
			local delt = to_select:getHandcardNum() - sgs.Self:getHandcardNum()
			local x = math.max( 1, math.floor( math.abs(delt) / 2 ) )
			return self:subcardsLength() == x
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("qzTongBu") --播放配音
		room:notifySkillInvoked(source, "qzTongBu") --显示技能发动
		room:obtainCard(target, self, false)
		if target:getHandcardNum() ~= source:getHandcardNum() then
			local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("qzTongBu")
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(target)
			use.card = slash
			room:useCard(use, false)
		end
	end,
}
TongBu = sgs.CreateViewAsSkill{
	name = "qzTongBu",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = TongBuCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then
			return false
		elseif player:hasUsed("#qzTongBuCard") then
			return false
		end
		return true
	end,
}
--添加技能
LiYinNi:addSkill(TongBu)
--翻译信息
sgs.LoadTranslationTable{
	["qzTongBu"] = "同步",
	[":qzTongBu"] = "<font color=\"green\"><b>阶段技</b></font>，你可以将X张手牌交给一名其他角色，然后若该角色与你的手牌数不同，视为你对其使用了一张火【杀】（X为你与该角色手牌数之差的一半且至少为1，结果向下取整）。",
	["qztongbu"] = "同步",
}
--[[****************************************************************
	编号：QZ - 008
	武将：张雅晨
	称号：主监考
	势力：吴
	性别：女
	体力上限：4勾玉
]]--****************************************************************
ZhangYaChen = sgs.General(extension, "qzZhangYaChen", "wu", 4, false)
--翻译信息
sgs.LoadTranslationTable{
	["qzZhangYaChen"] = "张雅晨",
	["&qzZhangYaChen"] = "张雅晨",
	["#qzZhangYaChen"] = "主监考",
	["designer:qzZhangYaChen"] = "DGAH",
	["cv:qzZhangYaChen"] = "无",
	["illustrator:qzZhangYaChen"] = "设计之家",
}
--[[
	技能：音难
	描述：一名其他角色的回合结束时，你可以交给其一张牌。该角色的下个回合开始时，若其在你的攻击范围内且该牌为该角色的手牌，你令其失去1点体力。
]]--
YinNan = sgs.CreateTriggerSkill{
	name = "qzYinNan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			local others = room:getOtherPlayers(player)
			for _,source in sgs.qlist(others) do
				if source:hasSkill("qzYinNan") then
					if not source:isNude() then
						local prompt = string.format("@qzYinNan:%s:", player:objectName())
						local card = room:askForCard(
							source, "..", prompt, data, sgs.Card_MethodNone, player, false, "qzYinNan"
						)
						if card then
							room:broadcastSkillInvoke("qzYinNan", 1) --播放配音
							room:notifySkillInvoked(source, "qzYinNan") --显示技能发动
							room:obtainCard(player, card, true)
							local records = player:getTag("qzYinNanRecord"):toString()
							if records == "" then
								records = {}
							else
								records = records:split("|")
							end
							table.insert(records, source:objectName())
							local mark = string.format("qzYinNanID_%s", source:objectName())
							room:setPlayerMark(player, mark, card:getEffectiveId())
							records = table.concat(records, "|")
							player:setTag("qzYinNanRecord", sgs.QVariant(records))
							player:gainMark("@qzYinNanMark", 1) 
						end
					end
				end
			end
		elseif phase == sgs.Player_Start then
			if player:getMark("@qzYinNanMark") > 0 then
				local records = player:getTag("qzYinNanRecord"):toString():split("|")
				for _,record in ipairs(records) do
					player:loseMark("@qzYinNanMark", 1)
					local mark = string.format("qzYinNanID_%s", record)
					local id = player:getMark(mark)
					if id > 0 then
						room:setPlayerMark(player, mark, 0)
						local card = sgs.Sanguosha:getCard(id)
						local msg = sgs.LogMessage()
						local msgtype = nil
						local owner = room:getCardOwner(id)
						if owner and owner:objectName() == player:objectName() then
							if room:getCardPlace(id) == sgs.Player_PlaceHand then
								local alives = room:getAlivePlayers()
								local source = nil
								for _,p in sgs.qlist(alives) do
									if p:objectName() == record then
										source = p
										break
									end
								end
								if source then
									if source:inMyAttackRange(player) then
										room:broadcastSkillInvoke("qzYinNan", 2) --播放配音
										room:notifySkillInvoked(source, "qzYinNan") --显示技能发动
										room:loseHp(player, 1)
									else
										msgtype = "#qzYinNanSoFar"
										msg.to:append(source)
									end
								else
									msgtype = "#qzYinNanNoSource"
								end
							else
								msgtype = "#qzYinNanNotHold"
							end
						else
							msgtype = "#qzYinNanNotHold"
						end
						if msgtype then
							msg.type = msgtype
							msg.from = player
							msg.arg = card:objectName()
							msg.arg2 = "qzYinNan"
							room:sendLog(msg) --发送提示信息
						end
					end
				end
				player:removeTag("qzYinNanRecord")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
ZhangYaChen:addSkill(YinNan)
--翻译信息
sgs.LoadTranslationTable{
	["qzYinNan"] = "音难",
	[":qzYinNan"] = "一名其他角色的回合结束时，你可以交给其一张牌。该角色的下个回合开始时，若其在你的攻击范围内且该牌为该角色的手牌，你令其失去1点体力。",
	["@qzYinNan"] = "你可以发动“音难”交给 %src 一张牌（包括装备）",
	["@qzYinNanMark"] = "音难",
	["#qzYinNanSoFar"] = "由于 %from 不在“%arg2”来源角色 %to 的攻击范围内，取消“%arg2”的后续效果",
	["#qzYinNanNoSource"] = "由于 “%arg2”来源角色不存在或已阵亡，取消“%arg2”对 %from 的后续效果",
	["#qzYinNanNotHold"] = "由于卡牌【%arg】不在 %from 的手牌中，取消“%arg”的后续效果",
}
--[[****************************************************************
	编号：QZ - 009
	武将：王兴
	称号：副监考
	势力：群
	性别：男
	体力上限：5勾玉
]]--****************************************************************
WangXing = sgs.General(extension, "qzWangXing", "qun", 5)
--翻译信息
sgs.LoadTranslationTable{
	["qzWangXing"] = "王兴",
	["&qzWangXing"] = "王兴",
	["#qzWangXing"] = "副监考",
	["designer:qzWangXing"] = "DGAH",
	["cv:qzWangXing"] = "无",
	["illustrator:qzWangXing"] = "优优素材",
}
--[[
	技能：运衰（锁定技）
	描述：你或你攻击范围内的角色于其出牌阶段第一次使用【杀】或非延时性锦囊牌时，若该牌没有指定其自身为目标，该角色选择一项：成为该牌的目标，或失去1点体力。
]]--
YunShuai = sgs.CreateTriggerSkill{
	name = "qzYunShuai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			if player:hasFlag("qzYunShuaiInvoked") then
				return false 
			end
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") or card:isNDTrick() then
				local user = use.from
				if user and user:objectName() == player:objectName() then
					local room = player:getRoom()
					room:setPlayerFlag(player, "qzYunShuaiInvoked")
					local targets = use.to
					if targets:contains(player) then
						return false 
					end
					local alives = room:getAlivePlayers()
					local source = nil
					for _,p in sgs.qlist(alives) do
						if p:hasSkill("qzYunShuai") then
							if p:inMyAttackRange(player) or p:objectName() == player:objectName() then
								source = p
								break
							end
						end
					end
					if source then
						room:broadcastSkillInvoke("qzYunShuai") --播放配音
						room:notifySkillInvoked(source, "qzYunShuai") --显示技能发动
						local choice = "losehp"
						if not player:isProhibited(player, card) then
							choice = room:askForChoice(player, "qzYunShuai", "target+losehp", data)
						end
						if choice == "target" then
							local msg = sgs.LogMessage()
							msg.type = "#qzYunShuai"
							msg.from = player
							msg.arg = "qzYunShuai"
							msg.arg2 = card:objectName()
							room:sendLog(msg) --发送提示信息
							local can_add = true
							if card:isKindOf("Collateral") then
								local victims = sgs.SPlayerList()
								for _,victim in sgs.qlist(alives) do
									if player:canSlash(victim) then
										victims:append(victim)
									end
								end
								if victims:isEmpty() then
									can_add = false
									local msg = sgs.LogMessage()
									msg.type = "#qzYunShuaiFail"
									msg.from = player
									msg.arg = card:objectName()
									room:sendLog(msg) --发送提示信息
								else
									local victim = room:askForPlayerChosen(player, victims, "qzYunShuai", "@qzYunShuai")
									if victim then
										local tag = sgs.QVariant()
										tag:setValue(victim)
										player:setTag("collateralVictim", tag)
									end
								end
							end
							if can_add then
								targets:append(player)
								room:sortByActionOrder(targets)
								use.to = targets
								data:setValue(use)
							end
						elseif choice == "losehp" then
							room:loseHp(player, 1)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
WangXing:addSkill(YunShuai)
--翻译信息
sgs.LoadTranslationTable{
	["qzYunShuai"] = "运衰",
	[":qzYunShuai"] = "<font color=\"blue\"><b>锁定技</b></font>, 你或你攻击范围内的角色于其出牌阶段第一次使用【杀】或非延时性锦囊牌时，若该牌没有指定其自身为目标，该角色选择一项：成为该牌的目标，或失去1点体力。",
	["qzYunShuai:target"] = "自已也成为目标",
	["qzYunShuai:losehp"] = "失去1点体力",
	["#qzYunShuai"] = "因“%arg”的影响，%from 将自己添加为此【%arg2】的额外目标",
	["#qzYunShuaiFail"] = "%from 成为了此【%arg】的目标，但由于没有可以使用【杀】的目标，取消该【%arg】对 %from 的结算",
	["@qzYunShuai"] = "你对你自己使用了【借刀杀人】，请选择杀的目标",
}
--[[****************************************************************
	编号：QZ - 010
	武将：宁江
	称号：任课教师
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
NingJiang = sgs.General(extension, "qzNingJiang", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["qzNingJiang"] = "宁江",
	["&qzNingJiang"] = "宁江",
	["#qzNingJiang"] = "任课教师",
	["designer:qzNingJiang"] = "DGAH",
	["cv:qzNingJiang"] = "无",
	["illustrator:qzNingJiang"] = "设计之家",
}
--[[
	技能：信仰
	描述：你需要使用或打出一张基本牌时，你可以翻开牌堆顶的一张牌，若该牌不为基本牌，你将其作为此基本牌使用或打出，否则你将其置于你的武将牌上，称为“念”，且本阶段你不能再次发动“信仰”。回合结束时，若“念”不少于10张，你可以弃置所有的“念”，令一名角色增加或失去1点体力上限。
]]--
function getTurnOverID(room, player)
	local id = room:drawCard()
	local move = sgs.CardsMoveStruct()
	move.card_ids:append(id)
	move.to = nil
	move.to_place = sgs.Player_PlaceTable
	move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName())
	room:moveCardsAtomic(move, true)
	return id
end
function checkToPile(room, player, card)
	if card:isKindOf("BasicCard") then
		player:addToPile("qzNian", card, true)
		room:setPlayerFlag(player, "qzXinYangFailed")
		return true
	end
	return false
end
function throwToDiscardPile(room, player, id)
	local move = sgs.CardsMoveStruct()
	move.card_ids:append(id)
	move.to = nil
	move.to_place = sgs.Player_DiscardPile
	move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName())
	room:moveCardsAtomic(move, true)
end
function withManeuvering()
	local ban = sgs.Sanguosha:getBanPackages()
	for _,name in ipairs(ban) do
		if name == "maneuvering" then
			return false
		end
	end
	return true
end
function chooseToUse(room, player)
	local flag = withManeuvering()
	local choices = {}
	if sgs.Slash_IsAvailable(player) then
		table.insert(choices, "slash")
		if flag then
			table.insert(choices, "thunder_slash")
			table.insert(choices, "fire_slash")
		end
	end
	if player:isWounded() then
		table.insert(choices, "peach")
	end
	if flag then
		if sgs.Analeptic_IsAvailable(player) then
			table.insert(choices, "analeptic")
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		local choice = room:askForChoice(player, "qzXinYangUseCard", choices)
		return choice
	end
end
function chooseToResponse(room, player, pattern)
	local flag = withManeuvering()
	if pattern == "" then
		local dying = room:getCurrentDyingPlayer()
		if dying then
			if flag and dying:objectName() == player:objectName() then
				pattern = "peach+analeptic"
			else
				pattern = "peach"
			end
		end
	end
	if pattern == "peach+analeptic" then
		if player:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
	end
	local cards = nil
	if flag then
		cards = {"slash", "thunder_slash", "fire_slash", "jink", "peach", "analeptic"}
	else
		cards = {"slash", "jink", "peach"}
	end
	local choices = {}
	for _,name in ipairs(cards) do
		local card = sgs.Sanguosha:cloneCard(name)
		if card:match(pattern) then
			table.insert(choices, name)
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		local choice = room:askForChoice(player, "qzXinYangResponseCard", choices)
		return choice
	end
end
function askForSelectTarget(room, player, name, id, suit, point) 
	room:setPlayerFlag(player, "qzXinYangSelect")
	room:setPlayerMark(player, "qzXinYangCardID", id)
	room:setPlayerMark(player, "qzXinYangCardSuit", suit)
	room:setPlayerMark(player, "qzXinYangCardPoint", point)
	room:setPlayerProperty(player, "qzXinYangCardName", sgs.QVariant(name))
	local prompt = string.format("@qzXinYang:::%s:", name)
	local card = room:askForUseCard(player, "@@qzXinYang", prompt)
	room:setPlayerProperty(player, "qzXinYangCardName", sgs.QVariant())
	room:setPlayerMark(player, "qzXinYangCardPoint", 0)
	room:setPlayerMark(player, "qzXinYangCardSuit", 0)
	room:setPlayerMark(player, "qzXinYangCardID", 0)
	room:setPlayerFlag(player, "-qzXinYangSelect")
	if card then
		return true
	end
	return false
end
XinYangCard = sgs.CreateSkillCard{
	name = "qzXinYangCard",
	target_fixed = true,
	will_throw = false,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		room:broadcastSkillInvoke("qzXinYang", 1) --播放配音
		room:notifySkillInvoked(user, "qzXinYang") --显示技能发动
		local id = getTurnOverID(room, user)
		local card = sgs.Sanguosha:getCard(id)
		if checkToPile(room, user, card) then
			return nil
		end
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local choice = nil
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = self:getUserString() or sgs.Sanguosha:getCurrentCardUsePattern()
			choice = chooseToResponse(room, user, pattern)
		else
			choice = chooseToUse(room, user)
		end
		if choice then
			local suit = card:getSuit()
			local point = card:getNumber()
			local vs_card = sgs.Sanguosha:cloneCard(choice, suit, point)
			if vs_card:targetFixed() then
				vs_card:addSubcard(id)
				vs_card:setSkillName("qzXinYang")
				return vs_card
			end
			if askForSelectTarget(room, user, choice, id, suit, point) then
				return self
			end
		end
		throwToDiscardPile(room, user, id)
		return nil
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		room:broadcastSkillInvoke("qzXinYang", 1) --播放配音
		room:notifySkillInvoked(user, "qzXinYang") --显示技能发动
		local id = getTurnOverID(room, user)
		local card = sgs.Sanguosha:getCard(id)
		if checkToPile(room, user, card) then
			return nil
		end
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local pattern = self:getUserString() or sgs.Sanguosha:getCurrentCardUsePattern()
		local choice = chooseToResponse(room, user, pattern)
		if choice then
			local suit = card:getSuit()
			local point = card:getNumber()
			local vs_card = sgs.Sanguosha:cloneCard(choice, suit, point)
			vs_card:addSubcard(id)
			vs_card:setSkillName("qzXinYang")
			if vs_card:targetFixed() then
				return vs_card
			elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
				return vs_card
			end
			if askForSelectTarget(room, user, choice, id, suit, point) then
				return self
			end
		end
		throwToDiscardPile(room, user, id)
		return nil
	end,
	on_use = function(self, room, source, targets)
	end,
}
function createXYCard(player)
	local name = player:property("qzXinYangCardName"):toString()
	local suit = player:getMark("qzXinYangCardSuit")
	local point = player:getMark("qzXinYangCardPoint")
	local card = sgs.Sanguosha:cloneCard(name, suit, point)
	card:setSkillName("qzXinYang")
	local id = player:getMark("qzXinYangCardID")
	card:addSubcard(id)
	return card
end
function tableToPlayerList(targets)
	local selected = sgs.PlayerList()
	for _,target in ipairs(targets) do
		selected:append(target)
	end
	return selected
end
XinYangSelectCard = sgs.CreateSkillCard{
	name = "qzXinYangSelectCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local card = createXYCard(sgs.Self)
		local selected = tableToPlayerList(targets)
		return card:targetFilter(selected, to_select, sgs.Self)
	end,
	feasible = function(self, targets) 
		local card = createXYCard(sgs.Self)
		local selected = tableToPlayerList(targets)
		return card:targetsFeasible(selected, sgs.Self)
	end,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		local vs_card = createXYCard(user)
		room:setPlayerProperty(user, "qzXinYangCardName", sgs.QVariant())
		room:setPlayerMark(user, "qzXinYangCardPoint", 0)
		room:setPlayerMark(user, "qzXinYangCardSuit", 0)
		room:setPlayerMark(user, "qzXinYangCardID", 0)
		room:setPlayerFlag(user, "-qzXinYangSelect")
		return vs_card
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local vs_card = createXYCard(user)
		room:setPlayerProperty(user, "qzXinYangCardName", sgs.QVariant())
		room:setPlayerMark(user, "qzXinYangCardPoint", 0)
		room:setPlayerMark(user, "qzXinYangCardSuit", 0)
		room:setPlayerMark(user, "qzXinYangCardID", 0)
		room:setPlayerFlag(user, "-qzXinYangSelect")
		return vs_card
	end,
}
XinYangVS = sgs.CreateViewAsSkill{
	name = "qzXinYang",
	n = 0,
	view_as = function(self, cards)
		if sgs.Self:hasFlag("qzXinYangSelect") then
			return XinYangSelectCard:clone()
		else
			local card = XinYangCard:clone()
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			card:setUserString(pattern)
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Self:hasFlag("qzXinYangSelect") then
			return false
		elseif player:hasFlag("qzXinYangFailed") then
			return false
		end
		if sgs.Slash_IsAvailable(player) then
			return true
		elseif player:isWounded() then
			return true
		elseif sgs.Analeptic_IsAvailable(player) then
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Self:hasFlag("qzXinYangSelect") then
			return pattern == "@@qzXinYang"
		elseif player:hasFlag("qzXinYangFailed") then
			return false
		end
		local choices = {}
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			table.insert(choices, "slash")
		end
		table.insert(choices, "jink")
		if not player:hasFlag("Global_PreventPeach") then
			table.insert(choices, "peach")
		end
		table.insert(choices, "analeptic")
		for _,choice in ipairs(choices) do
			local card = sgs.Sanguosha:cloneCard(choice)
			if card:match(pattern) then
				return true
			end
		end
		return false
	end,
}
XinYang = sgs.CreateTriggerSkill{
	name = "qzXinYang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardAsked, sgs.EventPhaseStart},
	view_as_skill = XinYangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked then
			if not player:hasFlag("qzXinYangFailed") then
				local dataString = data:toStringList()
				local pattern = dataString[1]
				if pattern == "slash" or pattern == "jink" then
					if player:askForSkillInvoke("qzXinYang", data) then
						room:broadcastSkillInvoke("qzXinYang", 1) --播放配音
						room:notifySkillInvoked(player, "qzXinYang") --显示技能发动
						local prompt = string.format("@qzXinYang:::%s:", pattern)
						local id = getTurnOverID(room, player)
						local card = sgs.Sanguosha:getCard(id)
						if checkToPile(room, player, card) then
							return false
						else
							local suit = card:getSuit()
							local point = card:getNumber()
							local vs_card = sgs.Sanguosha:cloneCard(pattern, suit, point)
							vs_card:setSkillName("qzXinYang")
							vs_card:addSubcard(id)
							room:provide(vs_card)
							return true
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local pile = player:getPile("qzNian")
				if pile:length() >= 10 then
					local alives = room:getAlivePlayers()
					local target = room:askForPlayerChosen(player, alives, "qzXinYangEffect", "@qzXinYangEffect", true)
					if target then
						room:notifySkillInvoked(player, "qzXinYang") --显示技能发动
						player:removePileByName("qzNian")
						local ai_data = sgs.QVariant()
						ai_data:setValue(target)
						player:setTag("qzXinYangData", ai_data)
						local choice = room:askForChoice(player, "qzXinYang", "up+down", ai_data)
						player:removeTag("qzXinYangData")
						if choice == "up" then
							room:broadcastSkillInvoke("qzXinYang", 2) --播放配音
							local maxhp = target:getMaxHp() + 1
							room:setPlayerProperty(target, "maxhp", sgs.QVariant(maxhp))
							room:broadcastProperty(target, "maxhp")
						elseif choice == "down" then
							room:broadcastSkillInvoke("qzXinYang", 3) --播放配音
							room:loseMaxHp(target, 1)
						end
					end
				end
			end
		end
		return false
	end,
}
XinYangClear = sgs.CreateTriggerSkill{
	name = "#qzXinYangClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("qzXinYangFailed") then
				room:setPlayerFlag(p, "-qzXinYangFailed")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("qzXinYang", "#qzXinYangClear")
--添加技能
NingJiang:addSkill(XinYang)
NingJiang:addSkill(XinYangClear)
--翻译信息
sgs.LoadTranslationTable{
	["qzXinYang"] = "信仰",
	[":qzXinYang"] = "你需要使用或打出一张基本牌时，你可以翻开牌堆顶的一张牌，若该牌不为基本牌，你将其作为此基本牌使用或打出，否则你将其置于你的武将牌上，称为“念”，且本阶段你不能再次发动“信仰”。回合结束时，若“念”不少于10张，你可以弃置所有的“念”，令一名角色增加或失去1点体力上限。",
	["$qzXinYang1"] = "技能 信仰 产生基本牌时 的台词",
	["$qzXinYang2"] = "技能 信仰 增加体力上限时 的台词",
	["$qzXinYang3"] = "技能 信仰 失去体力上限时 的台词",
	["qzNian"] = "念",
	["qzXinYangEffect"] = "信仰",
	["@qzXinYangEffect"] = "您可以发动“信仰”令一名角色增加或失去1点体力上限",
	["qzXinYang:up"] = "增加1点体力上限",
	["qzXinYang:down"] = "失去1点体力上限",
	["qzXinYangUseCard"] = "信仰",
	["qzXinYangResponseCard"] = "信仰",
	["@qzXinYang"] = "信仰：请选择此【%arg】的目标",
	["~qzXinYang"] = "选择一些目标角色->点击“确定”",
	["qzxinyang"] = "信仰",
}
--[[
	太阳神三国杀卡牌扩展包·乌有中学
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	卡牌总数：2
	卡牌一览：
		1、神龙玉佩（装备牌·防具，方块9）
		2、杀（基本牌·进攻牌，黑桃2）
]]--
qz_package = sgs.Package("qz_card", sgs.Package_CardPack)
--翻译信息
sgs.LoadTranslationTable{
	["qz_card"] = "乌有中学",
}
--[[****************************************************************
	卡牌：神龙玉佩
	类别：装备牌·防具
	花色：方块
	点数：9
	效果：1、你装备【神龙玉佩】时，若你没有技能“享乐”，你获得技能“享乐”，否则你获得技能“神龙玉佩”
		2、你失去装备区中的【神龙玉佩】时，你失去因此牌获得的技能并回复1点体力。
]]--****************************************************************
ShenLongYuPei = sgs.CreateArmor{
	name = "qzShenLongYuPei",
	class_name = "qzShenLongYuPei",
	suit = sgs.Card_Diamond,
	number = 9,
	on_install = function(self, player)
		local room = player:getRoom()
		if player:hasSkill("xiangle") then
			room:setPlayerProperty(player, "qzShenLongYuPei", sgs.QVariant("qzShenLongYuPeiSkill"))
			room:handleAcquireDetachSkills(player, "qzShenLongYuPeiSkill")
		else
			room:setPlayerProperty(player, "qzShenLongYuPei", sgs.QVariant("xiangle"))
			room:handleAcquireDetachSkills(player, "xiangle")
		end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local skill = player:property("qzShenLongYuPei"):toString()
		room:setPlayerProperty(player, "qzShenLongYuPei", sgs.QVariant(""))
		if skill == "qzShenLongYuPeiSkill" then
			room:handleAcquireDetachSkills(player, "-qzShenLongYuPeiSkill", true)
		elseif skill == "xiangle" then
			room:handleAcquireDetachSkills(player, "-xiangle", true)
		end
		if player:getLostHp() > 0 then
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
			room:recover(player, recover)
		end
	end
}
--添加卡牌
ShenLongYuPei:setParent(qz_package)
--翻译信息
sgs.LoadTranslationTable{
	["qzShenLongYuPei"] = "神龙玉佩",
	[":qzShenLongYuPei"] = "装备牌·防具<br />防具效果：<br />1、<font color=\"blue\"><b>锁定技，</b></font>你装备【神龙玉佩】时，若你没有技能“享乐”，你获得技能“享乐”，否则你获得技能“神龙玉佩”。<br />2、<font color=\"blue\"><b>锁定技，</b></font>你失去装备区中的【神龙玉佩】时，你失去因此牌获得的技能并回复1点体力。<br />★<font color=\"blueviolet\"><b>神龙玉佩</b></font>（技能）：<font color=\"blue\"><b>锁定技，</b></font>你受到【杀】或【决斗】造成的伤害时，伤害来源须弃置一张基本牌，否则此伤害-1。",
}
--[[
	技能：神龙玉佩（锁定技）
	描述：你受到【杀】或【决斗】造成的伤害时，伤害来源须弃置一张基本牌，否则此伤害-1。
]]--
ShenLongYuPeiSkill = sgs.CreateTriggerSkill{
	name = "qzShenLongYuPeiSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") or card:isKindOf("Duel") then
				local msg = sgs.LogMessage()
				msg.type = "#qzShenLongYuPei"
				msg.from = player
				msg.arg = "qzShenLongYuPeiSkill"
				msg.arg2 = card:objectName()
				room:sendLog(msg) --发送提示信息
				local basic = nil
				local source = damage.from
				if source and not source:isNude() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					local prompt = string.format("@qzShenLongYuPeiSkill:%s::%s:", player:objectName(), card:objectName())
					basic = room:askForCard(source, ".Basic", prompt, ai_data)
				end
				if not basic then
					local count = damage.damage
					if count > 1 then
						local msg = sgs.LogMessage()
						msg.type = "#qzShenLongYuPeiEffect"
						msg.from = player
						msg.arg = count
						count = count - 1
						msg.arg2 = count
						room:sendLog(msg) --显示提示信息
						damage.damage = count
						data:setValue(damage)
					else
						local msg = sgs.LogMessage()
						msg.type = "#qzShenLongYuPeiAvoid"
						msg.from = player
						msg.arg = count
						room:sendLog(msg) --显示提示信息
						damage.damage = 0
						data:setValue(damage)
						return true
					end
				end
			end
		end
		return false
	end,
}
--添加技能
if not sgs.Sanguosha:getSkill("qzShenLongYuPeiSkill") then
	local newSkills = sgs.SkillList()
	newSkills:append(ShenLongYuPeiSkill)
	sgs.Sanguosha:addSkills(newSkills)
end
--翻译信息
sgs.LoadTranslationTable{
	["qzShenLongYuPeiSkill"] = "神龙玉佩",
	[":qzShenLongYuPeiSkill"] = "<font color=\"blue\"><b>锁定技</b></font>, 你受到【杀】或【决斗】造成的伤害时，伤害来源须弃置一张基本牌，否则此伤害-1。",
	["#qzShenLongYuPei"] = "%from 受到了【%arg2】造成的伤害，其技能“%arg”被触发",
	["@qzShenLongYuPeiSkill"] = "请弃置一张基本牌，否则此【%arg】对 %src 造成的伤害-1",
	["#qzShenLongYuPeiEffect"] = "%from 的技能“<font color=\"yellow\"><b>神龙玉佩</b></font>”被触发，受到的伤害-1，由 %arg 点下降至 %arg2 点",
	["#qzShenLongYuPeiAvoid"] = "%from 的技能“<font color=\"yellow\"><b>神龙玉佩</b></font>”被触发，防止了 %arg 点伤害",
}
--[[****************************************************************
	卡牌：杀
	类别：基本牌·进攻牌
	花色：黑桃
	点数：2
]]--****************************************************************
qz_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Spade, 2)
--添加卡牌
qz_slash:setParent(qz_package)
--添加卡牌扩展包
sgs.Sanguosha:addPackage(qz_package)