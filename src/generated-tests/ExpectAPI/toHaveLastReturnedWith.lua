-- .toHaveLastReturnedWith



local tests = {

	(function()
		-- For example, let's say you have a mock `drink` that returns the name of the beverage that was consumed. You can write:
		-- 
		test(
		    "drink returns La Croix (Orange) last",
		    function()
		        local beverage1 = {name = "La Croix (Lemon)"}
		        local beverage2 = {name = "La Croix (Orange)"}
		        local drink = jestronaut:fn(function(beverage) return beverage.name end)
		        drink(beverage1)
		        drink(beverage2)
		        expect(drink):toHaveLastReturnedWith("La Croix (Orange)")
		    end
		)
		
	
	end)(),
	

}

return tests