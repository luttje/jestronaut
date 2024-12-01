-- toBeUndefined



local tests = {

	(function()
		-- Use `.toBeUndefined` to check that a variable is undefined. For example, if you want to check that a function `bestDrinkForFlavor(flavor)` returns `undefined` for the `'octopus'` flavor, because there is no good octopus-flavored drink:
		-- -- You could write `expect(bestDrinkForFlavor('octopus')).toBe(undefined)`, but it's better practice to avoid referring to `undefined` directly in your code.
		test(
		    "the best drink for octopus flavor is undefined",
		    function()
		        expect(bestDrinkForFlavor("octopus")):toBeUndefined()
		    end
		)
		
	
	end)(),
	

}

return tests