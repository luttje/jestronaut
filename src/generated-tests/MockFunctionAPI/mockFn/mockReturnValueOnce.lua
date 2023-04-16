-- mockFn.mockReturnValueOnce



local tests = {

	(function()
		-- Shorthand for:
		-- -- Accepts a value that will be returned for one call to the mock function. Can be chained so that successive calls to the mock function return different values. When there are no more `mockReturnValueOnce` values to use, calls will return a value specified by `mockReturnValue`.
		jestronaut:fn():mockImplementationOnce(function() return value end)
		
	
	end)(),
	
	
	(function()
		
		local mockFn = jestronaut:fn():mockReturnValue("default"):mockReturnValueOnce("first call"):mockReturnValueOnce("second call")
		mockFn()
		mockFn()
		mockFn()
		mockFn()
		
	
	end)(),
	

}

return tests