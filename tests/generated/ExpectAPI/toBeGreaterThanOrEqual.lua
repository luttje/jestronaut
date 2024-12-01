-- toBeGreaterThanOrEqual



local tests = {

	(function()
		-- Use `toBeGreaterThanOrEqual` to compare `received >= expected` for number or big integer values. For example, test that `ouncesPerCan()` returns a value of at least 12 ounces:
		-- 
		test(
		    "ounces per can is at least 12",
		    function()
		        expect(ouncesPerCan()):toBeGreaterThanOrEqual(12)
		    end
		)
		
	
	end)(),
	

}

return tests