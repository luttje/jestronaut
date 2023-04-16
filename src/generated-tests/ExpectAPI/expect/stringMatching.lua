-- expect.stringMatching



local tests = {

	(function()
		
		describe(
		    "stringMatching in arrayContaining",
		    function()
		        local expected = {
		            expect:stringMatching(nil),
		            expect:stringMatching(nil)
		        }
		        it(
		            "matches even if received contains additional elements",
		            function()
		                expect({"Alicia", "Roberto", "Evelina"}):toEqual(expect:arrayContaining(expected))
		            end
		        )
		        it(
		            "does not match if received does not contain expected elements",
		            function()
		                expect({"Roberto", "Evelina"})["not"]:toEqual(expect:arrayContaining(expected))
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests