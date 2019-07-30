monthlyCost.MAX_LOAN = 250000

local pref_modplusplus_bank = "pref_modplusplus_bank"

preferences:registerNew({
	id = pref_modplusplus_bank,
	display = _T("preferences_modplusplus_bank", "Autopay loan"),
	description = _T("preferences_modplusplus_bank_desc", "Autopay loan every month.")
})

local difficulty = {
	['ultra_easy'] = 500000,
	['very_easy'] = 250000,
	['easy'] = 100000,
	['normal'] = 50000,
}

local handler = {
	events = {
		timeline.EVENTS.NEW_TIMELINE,
		timeline.EVENTS.NEW_MONTH,
		studio.EVENTS.CHANGED_LOAN
	}
}

function handler:handleEvent(event)
	if event == timeline.EVENTS.NEW_TIMELINE then
		if difficulty[game.difficultyID] then
			local value = timeline:getYear() - timeline.baseYear
			if value <= 0 then value = 1 end
			monthlyCost.MAX_LOAN = math.floor(value * difficulty[game.difficultyID])
		end
	elseif event == studio.EVENTS.CHANGED_LOAN then
		if studio:getLoan() <= 0 then
			studio.loan = 0
		end
	else
		if preferences:get(pref_modplusplus_bank) and studio:getLoan() > 0 then
			studio:changeLoan(-monthlyCost.LOAN_CHANGE_AMOUNT)
		end
	end
end

events:addDirectReceiver(handler, handler.events)

function studio:changeLoan(change)
	self.loan = math.Clamp(self.loan + change, 0, monthlyCost.MAX_LOAN)
	self:addFunds(change, true, "loans")
	events:fire(studio.EVENTS.CHANGED_LOAN, change)
end