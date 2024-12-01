-- toBeLessThan



local tests = {

	(function()
		-- Use `toBeLessThan` to compare `received < expected` for number or big integer values. For example, test that `ouncesPerCan()` returns a value of less than 20 ounces:
		-- 
		test(
		    "ounces per can is less than 20",
		    function()
		        expect(ouncesPerCan()):toBeLessThan(20)
		    end
		)
		
	
	end)(),
	

}

return tests