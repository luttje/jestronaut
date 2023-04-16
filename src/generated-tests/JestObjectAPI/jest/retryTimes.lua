-- jest.retryTimes



local tests = {

	(function()
		-- Example in a test:
		-- -- If `logErrorsBeforeRetry` is enabled, Jest will log the error(s) that caused the test to fail to the console, providing visibility on why a retry occurred.
		jestronaut:retryTimes(3)
		test(
		    "will fail",
		    function()
		        expect(true):toBe(false)
		    end
		)
		
	
	end)(),
	
	
	(function()
		-- Returns the `jest` object for chaining.
		jestronaut:retryTimes(3, {logErrorsBeforeRetry = true})
		test(
		    "will fail",
		    function()
		        expect(true):toBe(false)
		    end
		)
		
	
	end)(),
	

}

return tests