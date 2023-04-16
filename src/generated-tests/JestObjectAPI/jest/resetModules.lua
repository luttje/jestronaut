-- jest.resetModules



local tests = {

	(function()
		-- Example:
		-- -- Example in a test:
		-- 
		-- ```js
		-- beforeEach(() => {
		--   jest.resetModules();
		-- });
		-- 
		-- test('works', () => {
		--   const sum = require('../sum');
		-- });
		-- 
		-- test('works too', () => {
		--   const sum = require('../sum');
		--   // sum is a different copy of the sum module from the previous test.
		-- });
		-- ```
		-- 
		-- Returns the `jest` object for chaining.
		local sum1 = require('sum')
		jestronaut:resetModules()
		local sum2 = require('sum')
		local ____ = sum1 == sum2
		
	
	end)(),
	

}

return tests