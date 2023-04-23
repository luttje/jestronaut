-- describe.only



local tests = {

	(function()
		-- You can use `describe.only` if you want to run only one describe block:
		-- 
		describe:only(
		    "my beverage",
		    function()
		        test(
		            "is delicious",
		            function()
		                expect(myBeverage.delicious):toBeTruthy()
		            end
		        )
		        test(
		            "is not sour",
		            function()
		                expect(myBeverage.sour):toBeFalsy()
		            end
		        )
		    end
		)
		describe(
		    "my other beverage",
		    function()
		    end
		)
		
	
	end)(),
	

}

return tests