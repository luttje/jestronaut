-- .toHaveNthReturnedWith



local tests = {

	(function()
		-- For example, let's say you have a mock `drink` that returns the name of the beverage that was consumed. You can write:
		-- -- :::note
		-- 
		-- The nth argument must be positive integer starting from 1.
		test(
		    "drink returns expected nth calls",
		    function()
		        local beverage1 = {name = "La Croix (Lemon)"}
		        local beverage2 = {name = "La Croix (Orange)"}
		        local drink = jestronaut:fn(function(beverage) return beverage.name end)
		        drink(beverage1)
		        drink(beverage2)
		        expect(drink):toHaveNthReturnedWith(1, "La Croix (Lemon)")
		        expect(drink):toHaveNthReturnedWith(2, "La Croix (Orange)")
		    end
		)
		
	
	end)(),
	

}

return tests