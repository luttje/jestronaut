-- .toHaveBeenCalledWith



local tests = {

	(function()
		-- For example, let's say that you can register a beverage with a `register` function, and `applyToAll(f)` should apply the function `f` to all registered beverages. To make sure this works, you could write:
		-- 
		local ____lualib = require('lualib_bundle')
		local __TS__New = ____lualib.__TS__New
		test(
		    "registration applies correctly to orange La Croix",
		    function()
		        local beverage = __TS__New(LaCroix, "orange")
		        register(beverage)
		        local f = jestronaut:fn()
		        applyToAll(f)
		        expect(f):toHaveBeenCalledWith(beverage)
		    end
		)
		
	
	end)(),
	

}

return tests