-- jest.disableAutomock

generatedTestPreLoad('utils_js', function()
	-- ```js title="__tests__/disableAutomocking.js"
	-- import utils from '../utils';
	-- 
	-- jest.disableAutomock();
	-- 
	-- test('original implementation', () => {
	--   // now we have the original implementation,
	--   // even if we set the automocking in a jest configuration
	--   expect(utils.authorize()).toBe('token');
	-- });
	-- ```
	-- 
	-- This is usually useful when you have a scenario where the number of dependencies you want to mock is far less than the number of dependencies that you don't. For example, if you're writing a test for a module that uses a large number of dependencies that can be reasonably classified as "implementation details" of the module, then you likely do not want to mock them.
	local ____exports = {}
	____exports.default = {authorize = function()
	    return "token"
	end}
	return ____exports
	
end)



local tests = {

	(function()
		test("jest.disableAutomock 0", function()
			-- ```ts tab
			-- import type {Config} from 'jest';
			-- 
			-- const config: Config = {
			--   automock: true,
			-- };
			-- 
			-- export default config;
			-- ```
			-- 
			-- :::
			-- 
			-- After `disableAutomock()` is called, all `require()`s will return the real versions of each module (rather than a mocked version).
			---
			-- @type {import('jestronaut').Config}
			local config = {automock = true}
			local exports = config
			
		
		end);
		
	
	end)(),
	
	
	

}

return tests