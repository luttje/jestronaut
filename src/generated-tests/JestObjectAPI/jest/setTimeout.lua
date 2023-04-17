-- jest.setTimeout



local tests = {

	(function()
		test("jest.setTimeout 0", function()
			-- Example:
			-- -- :::tip
			-- 
			-- To set timeout intervals on different tests in the same file, use the [`timeout` option on each individual test](GlobalAPI.md#testname-fn-timeout).
			jestronaut:setTimeout(1000)
			
		
		end);
		
	
	end)(),
	

}

return tests