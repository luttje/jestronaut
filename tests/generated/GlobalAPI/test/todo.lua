-- test.todo



local tests = {

	(function()
		test("test.todo 0", function()
			-- :::tip
			-- 
			-- `test.todo` will throw an error if you pass it a test callback function. Use [`test.skip`](#testskipname-fn) instead, if you already implemented the test, but do not want it to run.
			local function add(a, b)
			    return a + b
			end
			test:todo("add should be associative")
			
		
		end);
		
	
	end)(),
	

}

return tests