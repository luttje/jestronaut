-- .toThrowErrorMatchingSnapshot



local tests = {

	(function()
		-- For example, let's say you have a `drinkFlavor` function that throws whenever the flavor is `'octopus'`, and is coded like this:
		-- -- The test for this function will look this way:
		-- 
		-- ```js
		-- test('throws on octopus', () => {
		--   function drinkOctopus() {
		--     drinkFlavor('octopus');
		--   }
		-- 
		--   expect(drinkOctopus).toThrowErrorMatchingSnapshot();
		-- });
		-- ```
		-- 
		-- And it will generate the following snapshot:
		-- 
		-- ```js
		-- exports[`drinking flavors throws on octopus 1`] = `"yuck, octopus flavor"`;
		-- ```
		-- 
		-- Check out [React Tree Snapshot Testing](/blog/2016/07/27/jest-14) for more information on snapshot testing.
		local ____lualib = require("lualib_bundle")
		local __TS__New = ____lualib.__TS__New
		local function drinkFlavor(flavor)
		    if flavor == "octopus" then
		        error(
		            __TS__New(DisgustingFlavorError, "yuck, octopus flavor"),
		            0
		        )
		    end
		end
		
	
	end)(),
	

}

return tests