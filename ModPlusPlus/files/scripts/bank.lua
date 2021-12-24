monthlyCost.MAX_LOAN = 250000

local pref_modplusplus_bank = "pref_modplusplus_bank"

preferences:registerNew({
	id = pref_modplusplus_bank,
	display = _T("preferences_modplusplus_bank", "Autopay loan"),
	description = _T("preferences_modplusplus_bank_desc", "Autopay loan every month.")
})

ModPlusPlus.difficulty_loan = {
	['ultra_easy'] = 500000,
	['very_easy'] = 250000,
	['easy'] = 100000,
	['normal'] = 50000,
}

ModPlusPlus.difficulty_sale_tax = {
	['ultra_easy'] = 0.95,
	['very_easy'] = 0.9,
	['easy'] = 0.85,
	['normal'] = 0.8,
}

ModPlusPlus.sale_tax_max = 0.4 -- 60% tax
ModPlusPlus.sale_tax_random_max = 15

local handler = {
	events = {
		timeline.EVENTS.NEW_TIMELINE,
		timeline.EVENTS.NEW_YEAR,
		timeline.EVENTS.NEW_MONTH,
		studio.EVENTS.CHANGED_LOAN,
		game.EVENTS.NEW_GAME_STARTED,
		game.EVENTS.GAME_LOGIC_STARTED
	}
}

eventBoxText:registerNew({
	id = "tax_percentage_dynamic",
	getText = function(self, data)		
		return _format(_T("TAX_PERCENTAGE_DYNAMIC", "Interest tax TEXT on VALUE%."), "TEXT", data.text, "VALUE", data.value)
	end
})

function handler:handleEvent(event)
	if event == timeline.EVENTS.NEW_TIMELINE then
		if ModPlusPlus.difficulty_loan[game.difficultyID] then
			local value = timeline:getYear() - timeline.baseYear
			if value <= 0 then value = 1 end
			monthlyCost.MAX_LOAN = math.floor(value * ModPlusPlus.difficulty_loan[game.difficultyID])
		end
	elseif event == timeline.EVENTS.NEW_YEAR and math.random(1, 5) > 3 then
		local random = math.random(1, 2)
		local old_tax = gameProject.SALE_POST_TAX_PERCENTAGE

		-- shitty code.
		if random == 1 then -- bad
			gameProject.SALE_POST_TAX_PERCENTAGE = math.Clamp(gameProject.SALE_POST_TAX_PERCENTAGE - (math.random(1, ModPlusPlus.sale_tax_random_max) / 100), ModPlusPlus.sale_tax_max, ModPlusPlus.difficulty_sale_tax[game.difficultyID])
			studio:setFact("SALE_POST_TAX_PERCENTAGE_ModPlusPlus", gameProject.SALE_POST_TAX_PERCENTAGE)

			if gameProject.SALE_POST_TAX_PERCENTAGE ~= old_tax then
				game.addToEventBox("tax_percentage_dynamic", {text = _T('TAX_PERCENTAGE_DYNAMIC_TEXT_INC', 'increased'), value = math.round((1 - gameProject.SALE_POST_TAX_PERCENTAGE) * 100, 1)}, 1)
			end
		elseif random == 2 then -- good
			gameProject.SALE_POST_TAX_PERCENTAGE = math.Clamp(gameProject.SALE_POST_TAX_PERCENTAGE + (math.random(1, ModPlusPlus.sale_tax_random_max) / 100), ModPlusPlus.sale_tax_max, ModPlusPlus.difficulty_sale_tax[game.difficultyID])
			studio:setFact("SALE_POST_TAX_PERCENTAGE_ModPlusPlus", gameProject.SALE_POST_TAX_PERCENTAGE)

			if gameProject.SALE_POST_TAX_PERCENTAGE ~= old_tax then
				game.addToEventBox("tax_percentage_dynamic", {text = _T('TAX_PERCENTAGE_DYNAMIC_TEXT_DEC', 'decreased'), value = math.round((1 - gameProject.SALE_POST_TAX_PERCENTAGE) * 100, 1)}, 1)
			end
		end
	elseif event == timeline.EVENTS.NEW_MONTH then
		if preferences:get(pref_modplusplus_bank) and studio:getLoan() > 0 then
			local loan_amount = monthlyCost.LOAN_CHANGE_AMOUNT
			-- local funds = studio:getFunds()

--[[ 			if (funds > 0 and not studio:hasFunds(loan_amount)) then
				loan_amount = math.Clamp(loan_amount - funds, 0, funds)
				print("noFunds")
			end ]] -- @todo если нехватка денег, смотрим сколько можно оплатить

			if (loan_amount > 0 and studio:hasFunds(loan_amount)) then
				studio:changeLoan(-loan_amount)
			end
		end
	elseif event == game.EVENTS.NEW_GAME_STARTED and ModPlusPlus.difficulty_sale_tax[game.difficultyID] then
		gameProject.SALE_POST_TAX_PERCENTAGE = ModPlusPlus.difficulty_sale_tax[game.difficultyID]
		studio:setFact("SALE_POST_TAX_PERCENTAGE_ModPlusPlus", gameProject.SALE_POST_TAX_PERCENTAGE)
	elseif event == game.EVENTS.GAME_LOGIC_STARTED and studio:getFact("SALE_POST_TAX_PERCENTAGE_ModPlusPlus") then
		gameProject.SALE_POST_TAX_PERCENTAGE = studio:getFact("SALE_POST_TAX_PERCENTAGE_ModPlusPlus")
	elseif event == studio.EVENTS.CHANGED_LOAN and studio:getLoan() <= 0 then
		studio.loan = 0
	end
end

events:addDirectReceiver(handler, handler.events)

function studio:changeLoan(change)
--[[ 	if (not b) then
		local a = math.abs(change)

		if (a == monthlyCost.LOAN_CHANGE_AMOUNT and a > self.loan) then
			change = self.loan
		end
	end ]] --@todo

	self.loan = math.Clamp(self.loan + change, 0, monthlyCost.MAX_LOAN)
	self:addFunds(change, true, "loans")
	events:fire(studio.EVENTS.CHANGED_LOAN, change)
end