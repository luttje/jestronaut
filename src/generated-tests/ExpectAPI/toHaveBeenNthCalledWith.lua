-- .toHaveBeenNthCalledWith



local tests = {

	(function()
		-- If you have a mock function, you can use `.toHaveBeenNthCalledWith` to test what arguments it was nth called with. For example, let's say you have a `drinkEach(drink, Array<flavor>)` function that applies `f` to a bunch of flavors, and you want to ensure that when you call it, the first flavor it operates on is `'lemon'` and the second one is `'octopus'`. You can write:
		-- -- :::note
		-- 
		-- The nth argument must be positive integer starting from 1.
		test(
		    "drinkEach drinks each drink",
		    function()
		        local drink = jestronaut:fn()
		        drinkEach(drink, {"lemon", "octopus"})
		        expect(drink):toHaveBeenNthCalledWith(1, "lemon")
		        expect(drink):toHaveBeenNthCalledWith(2, "octopus")
		    end
		)
		
	
	end)(),
	

}

return tests