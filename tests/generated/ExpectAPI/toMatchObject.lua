-- toMatchObject



local tests = {

	(function()
		
		local houseForSale = {bath = true, bedrooms = 4, kitchen = {amenities = {"oven", "stove", "washer"}, area = 20, wallColor = "white"}}
		local desiredHouse = {
		    bath = true,
		    kitchen = {
		        amenities = {"oven", "stove", "washer"},
		        wallColor = expect:stringMatching("white")
		    }
		}
		test(
		    "the house has my desired features",
		    function()
		        expect(houseForSale):toMatchObject(desiredHouse)
		    end
		)
		
	
	end)(),
	
	
	(function()
		
		describe(
		    "toMatchObject applied to arrays",
		    function()
		        test(
		            "the number of elements must match exactly",
		            function()
		                expect({{foo = "bar"}, {baz = 1}}):toMatchObject({{foo = "bar"}, {baz = 1}})
		            end
		        )
		        test(
		            ".toMatchObject is called for each elements, so extra object properties are okay",
		            function()
		                expect({{foo = "bar"}, {baz = 1, extra = "quux"}}):toMatchObject({{foo = "bar"}, {baz = 1}})
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests