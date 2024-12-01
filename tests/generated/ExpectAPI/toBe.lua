-- toBe



local tests = {

	(function()
		-- For example, this code will validate some properties of the `can` object:
		-- -- Don't use `.toBe` with floating-point numbers. For example, due to rounding, in JavaScript `0.2 + 0.1` is not strictly equal to `0.3`. If you have floating point numbers, try `.toBeCloseTo` instead.
		local can = {name = "pamplemousse", ounces = 12}
		describe(
		    "the can",
		    function()
		        test(
		            "has 12 ounces",
		            function()
		                expect(can.ounces):toBe(12)
		            end
		        )
		        test(
		            "has a sophisticated name",
		            function()
		                expect(can.name):toBe("pamplemousse")
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests