-- test.only.each



local tests = {

	(function()
		
		test.only:each({{1, 1, 2}, {1, 2, 3}, {2, 1, 3}})(
		    ".add(%i, %i)",
		    function(a, b, expected)
		        expect(a + b):toBe(expected)
		    end
		)
		test(
		    "will not be run",
		    function()
		        expect(1 / 0):toBe(math.huge)
		    end
		)
		
	
	end)(),
	

}

return tests