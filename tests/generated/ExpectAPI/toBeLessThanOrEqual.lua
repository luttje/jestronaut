-- toBeLessThanOrEqual



local tests = {

	(function()
		-- Use `toBeLessThanOrEqual` to compare `received <= expected` for number or big integer values. For example, test that `ouncesPerCan()` returns a value of at most 12 ounces:
		-- 
		test(
		    "ounces per can is at most 12",
		    function()
		        expect(ouncesPerCan()):toBeLessThanOrEqual(12)
		    end
		)
		
	
	end)(),
	

}

return tests