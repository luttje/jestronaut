-- expect.not.objectContaining



local tests = {

	(function()
		
		describe(
		    "not.objectContaining",
		    function()
		        local expected = {foo = "bar"}
		        it(
		            "matches if the actual object does not contain expected key: value pairs",
		            function()
		                expect({bar = "baz"}):toEqual(expect["not"]:objectContaining(expected))
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests