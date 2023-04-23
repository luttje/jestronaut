-- test.only



local tests = {

	(function()
		-- For example, let's say you had these tests:
		-- -- Only the "it is raining" test will run in that test file, since it is run with `test.only`.
		test:only(
		    "it is raining",
		    function()
		        expect(inchesOfRain()):toBeGreaterThan(0)
		    end
		)
		test(
		    "it is not snowing",
		    function()
		        expect(inchesOfSnow()):toBe(0)
		    end
		)
		
	
	end)(),
	

}

return tests