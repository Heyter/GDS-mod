ModPlusPlus = {}

contractor.MILESTONE_EARLY_COMPLETION_BONUS_BASE_AMOUNT = 5000
contractor.MILESTONE_EARLY_COMPLETION_BONUS_PER_SCALE = 15000
contractor.MILESTONE_DEADLINE_REDUCE_AMOUNT = 0.75

gameProject.QA_BASE_COST = 1499

activities.AUTO_ORGANIZE_TIME_PERIOD = timeline.DAYS_IN_MONTH * 29
activities.AUTO_ORGANIZE_MINIMUM_PEOPLE = 4
activities.AUTO_ORGANIZE_CHANCE = 20

gameProject.PRICE_POINTS = {
	2,
	5,
	10,
	20,
	25,
	30,
	35,
	40,
	45,
	50,
	55,
	60
}

gameProject.SUBSCRIPTION_PRICE_POINTS = {
	2,
	5,
	10,
	12,
	14,
	17,
	19,
	22,
	24,
	26,
	30
}

translation.addBulk("ru", {
	['THEME_LIFE'] = 'Жизнь',
	['THEME_CONSTRUCTION'] = 'Строительство',
	['THEME_DEMONS'] = 'Демоны',
	['GO_OFF_MARKET'] = 'Убрать с рынка',
	['A_DISCOUNT'] = 'Скидка',
	['discount_rate'] = 'Скидка: DISCOUNT%',
	['A_DISCOUNT_DESC'] = 'Установить скидку для игры',
	['DISCOUNT_MISCELLANEOUS_LABEL'] = 'Разное',
	['TAX_PERCENTAGE_DYNAMIC'] = "Процентный налог TEXT на VALUE%.",
	['TAX_PERCENTAGE_DYNAMIC_TEXT_INC'] = "вырос",
	['TAX_PERCENTAGE_DYNAMIC_TEXT_DEC'] = "снизился"
	-- ['preferences_modplusplus_bank'] = 'Автоплатеж кредита',
	-- ['preferences_modplusplus_bank_desc'] = 'Автоплатеж кредита каждый месяц',
})

--[[---------------------------------------------------------
	Name: Clamp( in, low, high )
	Desc: Clamp value between 2 values
------------------------------------------------------------]]
function math.Clamp( _in, low, high )
	return math.min( math.max( _in, low ), high )
end

require('gui/discount')
require('scripts/bank')

local function ADD_ARRAY(obj, name, value)
	if not value then return end
	
	local array = obj:getFact('DISCOUNT_ARRAY') or {}
	array[name] = value
	obj:setFact('DISCOUNT_ARRAY', array)
	array = nil
end

function ModPlusPlus.OfferDiscount(value, obj)
	math.randomseed(timeline.curTime + 1)
	
	value = math.Clamp(tonumber(value), 0, 100)
	
	if not obj:getFact('DISCOUNT_PRICE') then
		if value > 0 then
			obj:setFact('DISCOUNT_PRICE', obj:getPrice())
			
			if not obj:getFact('DISCOUNT_OLD_PRICE') then
				obj:setFact('DISCOUNT_OLD_PRICE', obj:getPrice())
			end
		end
	else
		if value < 1 then
			obj:setFact('DISCOUNT_PRICE', nil)
			obj:setPrice(obj:getFact('DISCOUNT_OLD_PRICE') or obj:getPrice())
			return
		end
	end
	
	local old_discount_value = obj:getFact('DISCOUNT_VALUE')
	
	if not obj:getFact('DISCOUNT_TIME') and obj:getFact('DISCOUNT_PRICE') and old_discount_value ~= value then
		if obj:getFact('DISCOUNT_INIT') and (value < old_discount_value or math.random(1, 3) == 2) then
			obj:setFact("DISCOUNT_DECREASE", (obj:getFact('DISCOUNT_DECREASE') or 0) + 2)
		end
		
		local lowA, lowB = math.random(1, 100), math.random(2, 6)
		local lowC = math.Clamp(tonumber((obj:getFact('DISCOUNT_DECREASE') or 0)-0.15), 0, 1000)
		obj:changeTimeSaleAffector(-math.Clamp(tonumber((value+lowA) * 100) / lowC, gameProject.MAX_TIME_SALE_AFFECTOR_FROM_POPULARITY, 5000 * lowB))
		
		local game_price = math.round(tonumber(obj:getFact('DISCOUNT_PRICE')) * (1 - (tonumber(value) / 100)), 2)
		if obj:setPrice(game_price) then
			obj:setFact("DISCOUNT_VALUE", value)
			obj:setFact("DISCOUNT_INIT", true)
			
			if math.random(1, 100) <= math.random(1, 100) then
				obj:setFact("DISCOUNT_DECREASE", (obj:getFact('DISCOUNT_DECREASE') or 0) + 1)
			end
		end
		game_price = nil
		
		ADD_ARRAY(studio, obj:getUniqueID(), true)
		obj:setFact('DISCOUNT_TIME', timeline.curTime + (timeline.DAYS_IN_MONTH + 7))
	end
end

local handler = {
	events = {
		gameProject.EVENTS.OPENED_INTERACTION_MENU,
		timeline.EVENTS.NEW_DAY,
		gameProject.EVENTS.GAME_OFF_MARKET,
		gameProject.EVENTS.FILL_GAME_INFO_SCROLLER
	}
}

function handler:handleEvent(event, gameProj, data)
	if event == gameProject.EVENTS.OPENED_INTERACTION_MENU then
		if gameProj.releaseDate and not gameProj.contractor and not gameProj.publisher and not gameProj.offMarket then
			if gameProj:getDaysSinceRelease() > 7 then
				local option = interactionController:getComboBox():addOption(0, 0, 0, 24, _T("GO_OFF_MARKET", "Go off market"), fonts.get("pix20"), gameProject.goOffmarketCallbackDEBUG)
				option.project = gameProj
			end
			
			if gameProj:getDaysSinceRelease() > 14 and not gameProj:getFact('DISCOUNT_TIME') then
				local option = interactionController:getComboBox():addOption(0, 0, 0, 24, _T("A_DISCOUNT", "A discount"), fonts.get("pix20"), function()
					local frame = gui.create("Frame")
					frame:setFont("pix24")
					frame:setTitle(_T("A_DISCOUNT", "A discount"))
					frame:setSize(400, 140)
					
					local frameH = 35
					
					local label = gui.create("Label", frame)
					label:setPos(_S(5), _S(30))
					label:setFont("pix20")
					label:wrapText(frame.w - _S(10), _T('A_DISCOUNT_DESC', 'Set a discount for the game'))
					
					frameH = frameH + _US(label.h)
					
					local buttonWidth = (frame.rawW - 15) / 2
					local buttonHeight = 28
					
					frame:setHeight(frameH + buttonHeight + 45)
					
					local textBox = gui.create("TextBox", frame)
					textBox:setNumbersOnly(true)
					textBox:setFont(fonts.get("bh22"))
					textBox:setGhostText(gameProj:getFact('DISCOUNT_VALUE') or 0)
					textBox:setMaxText(3)
					textBox:setMaxValue(100)
					textBox:setMinValue(0)
					textBox:setSize(frame.rawW - 10, 38)
					textBox:setPos(_S(5), label.h + label.y + _S(5))
					
					local DiscountBtn = gui.create("DiscountBtn", frame)
					DiscountBtn:setSize(buttonWidth, buttonHeight)
					DiscountBtn:setFont("bh24")
					DiscountBtn:setText(_T("ACCEPT_OFFER", "Accept offer"))
					DiscountBtn:setProject(textBox, gameProj)
					DiscountBtn:setPos(_S(5), frame.h - DiscountBtn.h - _S(5))
					
					local cancelButton = gui.create("GenericFrameControllerPopButton", frame)
					cancelButton:setSize(buttonWidth, buttonHeight)
					cancelButton:setFont("bh24")
					cancelButton:setText(_T("CANCEL", "Cancel"))
					cancelButton:setPos(frame.w - _S(5) - cancelButton.w, DiscountBtn.y)
					
					frame:center()
					frameController:push(frame)
				end)
				option.project = gameProj
			end
		end
	elseif event == timeline.EVENTS.NEW_DAY then
		for k in pairs(studio:getFact('DISCOUNT_ARRAY') or {}) do
			local project = studio:getGameByUniqueID(k)
			if project and project:getFact('DISCOUNT_TIME') and project:getFact('DISCOUNT_TIME') <= timeline.curTime then
				project:setFact('DISCOUNT_TIME', nil)
				ADD_ARRAY(studio, project, nil)
				project = nil
			end
		end
	elseif event == gameProject.EVENTS.GAME_OFF_MARKET and studio:getFact('DISCOUNT_ARRAY') and studio:getFact('DISCOUNT_ARRAY')[gameProj:getUniqueID()] then
		gameProj:setFact('DISCOUNT_TIME', nil)
		gameProj:setFact('DISCOUNT_VALUE', nil)
		ADD_ARRAY(studio, gameProj, nil)
	elseif event == gameProject.EVENTS.FILL_GAME_INFO_SCROLLER and gameProj:getFact('DISCOUNT_VALUE') then
		local financialCat = gui.create("Category")
		financialCat:setFont("bh24")
		financialCat:setText(_T('DISCOUNT_MISCELLANEOUS_LABEL', 'Miscellaneous'))
		financialCat:assumeScrollbar(data)
		data:addItem(financialCat)
		
		local w, h = data:getSize()
		w = w - 20
	
		local discount = gameProj:_createTextPanel("game_copy_price", "bh20", w, 22, nil, 24, _format(_T("discount_rate", "A discount: DISCOUNT%"), "DISCOUNT", gameProj:getFact('DISCOUNT_VALUE')))
		financialCat:addItem(discount)
	end
end
events:addDirectReceiver(handler, handler.events)