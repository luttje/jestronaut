-- .toHaveReturned



local tests = {

	(function()
		-- If you have a mock function, you can use `.toHaveReturned` to test that the mock function successfully returned (i.e., did not throw an error) at least one time. For example, let's say you have a mock `drink` that returns `true`. You can write:
		-- 
		test(
		    "drinks returns",
		    function()
		        local drink = jestronaut:fn(function() return true end)
		        drink()
		        expect(drink):toHaveReturned()
		    end
		)
		
	
	end)(),
	

}

return tests