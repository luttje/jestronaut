-- test.failing.each



local tests = {

	(function()
		-- Example:
		-- 
		test.failing:each({{a = 1, b = 1, expected = 2}, {a = 1, b = 2, expected = 3}, {a = 2, b = 1, expected = 3}})(
		    ".add($a, $b)",
		    function(____bindingPattern0)
		        local expected
		        local b
		        local a
		        a = ____bindingPattern0.a
		        b = ____bindingPattern0.b
		        expected = ____bindingPattern0.expected
		        expect(a + b):toBe(expected)
		    end
		)
		
	
	end)(),
	

}

return tests