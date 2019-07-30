local discountBtn = {}

function discountBtn:setProject(textbox, this)
	self.discount = textbox
	self.this_project = this
end

function discountBtn:onClick(x, y, key)
	if key == gui.mouseKeys.LEFT then
		if not self.discount:getText() or self.discount:getText() == '' then return end
		OfferDiscount(self.discount:getText(), self.this_project)
		frameController:pop()
	end
end

gui.register("DiscountBtn", discountBtn, "Button")