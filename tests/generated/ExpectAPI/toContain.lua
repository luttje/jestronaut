-- .toContain



local tests = {

	(function()
		-- For example, if `getAllFlavors()` returns an array of flavors and you want to be sure that `lime` is in there, you can write:
		-- -- This matcher also accepts others iterables such as strings, sets, node lists and HTML collections.
		test(
		    "the flavor list contains lime",
		    function()
		        expect(getAllFlavors()):toContain("lime")
		    end
		)
		
	
	end)(),
	

}

return tests