-- toContainEqual



local tests = {

	(function()
		
		describe(
		    "my beverage",
		    function()
		        test(
		            "is delicious and not sour",
		            function()
		                local myBeverage = {delicious = true, sour = false}
		                expect(myBeverages()):toContainEqual(myBeverage)
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests