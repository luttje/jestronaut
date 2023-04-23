-- test



local tests = {

	(function()
		-- All you need in a test file is the `test` method which runs a test. For example, let's say there's a function `inchesOfRain()` that should be zero. Your whole test could be:
		-- -- The first argument is the test name; the second argument is a function that contains the expectations to test. The third argument (optional) is `timeout` (in milliseconds) for specifying how long to wait before aborting. The default timeout is 5 seconds.
		test(
		    "did not rain",
		    function()
		        expect(inchesOfRain()):toBe(0)
		    end
		)
		
	
	end)(),
	
	
	(function()
		-- If a **promise is returned** from `test`, Jest will wait for the promise to resolve before letting the test complete. For example, let's say `fetchBeverageList()` returns a promise that is supposed to resolve to a list that has `lemon` in it. You can test this with:
		-- -- Even though the call to `test` will return right away, the test doesn't complete until the promise resolves. For more details, see [Testing Asynchronous Code](TestingAsyncCode.md) page.
		test(
		    "has lemon in it",
		    function()
		        local ____self_0 = fetchBeverageList()
		        return ____self_0["then"](
		            ____self_0,
		            function(list)
		                expect(list):toContain("lemon")
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests