-- jest.enableAutomock

package.preload['utils_js'] = function()
	-- Example:
	-- -- ```js title="__tests__/enableAutomocking.js"
	-- jest.enableAutomock();
	-- 
	-- import utils from '../utils';
	-- 
	-- test('original implementation', () => {
	--   // now we have the mocked implementation,
	--   expect(utils.authorize._isMockFunction).toBeTruthy();
	--   expect(utils.isAuthorized._isMockFunction).toBeTruthy();
	-- });
	-- ```
	-- 
	-- Returns the `jest` object for chaining.
	local ____exports = {}
	____exports.default = {
	    authorize = function()
	        return "token"
	    end,
	    isAuthorized = function(secret) return secret == "wizard" end
	}
	return ____exports
	
end

package.preload['utils'] = package.preload['utils_js']



local tests = {

	(function()
		-- Example:
		-- -- ```js title="__tests__/enableAutomocking.js"
		-- jest.enableAutomock();
		-- 
		-- import utils from '../utils';
		-- 
		-- test('original implementation', () => {
		--   // now we have the mocked implementation,
		--   expect(utils.authorize._isMockFunction).toBeTruthy();
		--   expect(utils.isAuthorized._isMockFunction).toBeTruthy();
		-- });
		-- ```
		-- 
		-- Returns the `jest` object for chaining.
		local ____exports = {}
		____exports.default = {
		    authorize = function()
		        return "token"
		    end,
		    isAuthorized = function(secret) return secret == "wizard" end
		}
		return ____exports
	
	end)(),
	
	

}

return tests