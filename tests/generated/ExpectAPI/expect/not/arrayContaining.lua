-- expect.not.arrayContaining



local tests = {

	(function()
		
		describe(
		    "not.arrayContaining",
		    function()
		        local expected = {"Samantha"}
		        it(
		            "matches if the actual array does not contain the expected elements",
		            function()
		                expect({"Alice", "Bob", "Eve"}):toEqual(expect["not"]:arrayContaining(expected))
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests