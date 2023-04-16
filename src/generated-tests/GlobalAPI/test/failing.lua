-- test.failing



local tests = {

	(function()
		-- Example:
		-- 
		test:failing(
		    "it is not equal",
		    function()
		        expect(5):toBe(6)
		    end
		)
		test:failing(
		    "it is equal",
		    function()
		        expect(10):toBe(10)
		    end
		)
		
	
	end)(),
	

}

return tests