-- .toBeNull



local tests = {

	(function()
		
		local function bloop()
		    return nil
		end
		test(
		    "bloop returns null",
		    function()
		        expect(bloop()):toBeNull()
		    end
		)
		
	
	end)(),
	

}

return tests