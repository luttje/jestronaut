-- expect.not.stringContaining



local tests = {

	(function()
		
		describe(
		    "not.stringContaining",
		    function()
		        local expected = "Hello world!"
		        it(
		            "matches if the received value does not contain the expected substring",
		            function()
		                expect("How are you?"):toEqual(expect["not"]:stringContaining(expected))
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests