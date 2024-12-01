-- describe.skip



local tests = {

	(function()
		-- You can use `describe.skip` if you do not want to run the tests of a particular `describe` block:
		-- -- Using `describe.skip` is often a cleaner alternative to temporarily commenting out a chunk of tests. Beware that the `describe` block will still run. If you have some setup that also should be skipped, do it in a `beforeAll` or `beforeEach` block.
		describe(
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
		describe:skip(
		    "my other beverage",
		    function()
		    end
		)
		
	
	end)(),
	

}

return tests