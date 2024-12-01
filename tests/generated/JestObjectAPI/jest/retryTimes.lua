-- jest.retryTimes



local tests = {

	(function()
		-- If `logErrorsBeforeRetry` option is enabled, error(s) that caused the test to fail will be logged to the console.
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