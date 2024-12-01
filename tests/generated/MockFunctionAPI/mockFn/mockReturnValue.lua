-- mockFn.mockReturnValue



local tests = {

	(function()
		test("mockFn.mockReturnValue 0", function()
			-- Shorthand for:
			-- -- Accepts a value that will be returned whenever the mock function is called.
			jestronaut:fn():mockImplementation(function() return value end)
			
		
		end);
		
	
	end)(),
	
	
	(function()
		test("mockFn.mockReturnValue 1", function()
			
			local mock = jestronaut:fn()
			mock:mockReturnValue(42)
			mock()
			mock:mockReturnValue(43)
			mock()
			
		
		end);
		
	
	end)(),
	

}

return tests