-- jest.useRealTimers



local tests = {

	(function()
		-- Instructs Jest to restore the original implementations of the global date, performance, time and timer APIs. For example, you may call `jest.useRealTimers()` inside `afterEach` hook to restore timers after each test:
		-- -- Returns the `jest` object for chaining.
		afterEach(function()
		    jestronaut:useRealTimers()
		end)
		test(
		    "do something with fake timers",
		    function()
		        jestronaut:useFakeTimers()
		    end
		)
		test(
		    "do something with real timers",
		    function()
		    end
		)
		
	
	end)(),
	

}

return tests