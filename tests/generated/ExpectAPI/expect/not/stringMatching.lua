-- expect.not.stringMatching



local tests = {

	(function()
		
		describe(
		    "not.stringMatching",
		    function()
		        local expected = "Hello world!"
		        it(
		            "matches if the received value does not match the expected regex",
		            function()
		                expect("How are you?"):toEqual(expect["not"]:stringMatching(expected))
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests