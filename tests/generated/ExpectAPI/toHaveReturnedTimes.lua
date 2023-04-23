-- .toHaveReturnedTimes



local tests = {

	(function()
		-- For example, let's say you have a mock `drink` that returns `true`. You can write:
		-- 
		test(
		    "drink returns twice",
		    function()
		        local drink = jestronaut:fn(function() return true end)
		        drink()
		        drink()
		        expect(drink):toHaveReturnedTimes(2)
		    end
		)
		
	
	end)(),
	

}

return tests