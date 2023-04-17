-- .toBeFalsy



local tests = {

	(function()
		-- Use `.toBeFalsy` when you don't care what a value is and you want to ensure a value is false in a boolean context. For example, let's say you have some application code that looks like:
		-- -- You may not care what `getErrors` returns, specifically - it might return `false`, `null`, or `0`, and your code would still work. So if you want to test there are no errors after drinking some La Croix, you could write:
		-- 
		-- ```js
		-- test('drinking La Croix does not lead to errors', () => {
		--   drinkSomeLaCroix();
		--   expect(getErrors()).toBeFalsy();
		-- });
		-- ```
		-- 
		-- In JavaScript, there are six falsy values: `false`, `0`, `''`, `null`, `undefined`, and `NaN`. Everything else is truthy.
		drinkSomeLaCroix()
		if not getErrors() then
		    drinkMoreLaCroix()
		end
		
	
	end)(),
	

}

return tests