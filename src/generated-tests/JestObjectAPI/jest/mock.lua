-- jest.mock

package.preload['banana_js'] = function()
	-- Mocks a module with an auto-mocked version when it is being required. `factory` and `options` are optional. For example:
	-- -- ```js title="__tests__/test.js"
	-- jest.mock('../banana');
	-- 
	-- const banana = require('../banana'); // banana will be explicitly mocked.
	module.exports = function() return "banana" end
	
end

package.preload['banana'] = package.preload['banana_js']



local tests = {

	(function()
		test("jest.mock 0", function()
			-- Mocks a module with an auto-mocked version when it is being required. `factory` and `options` are optional. For example:
			-- -- ```js title="__tests__/test.js"
			-- jest.mock('../banana');
			-- 
			-- const banana = require('../banana'); // banana will be explicitly mocked.
			module.exports = function() return "banana" end
			
		
		end);
		
	
	end)(),
	
	
	(function()
		test("jest.mock 1", function()
			-- The second argument can be used to specify an explicit module factory that is being run instead of using Jest's automocking feature:
			-- -- ```ts tab
			-- // The optional type argument provides typings for the module factory
			-- jest.mock<typeof import('../moduleName')>('../moduleName', () => {
			--   return jest.fn(() => 42);
			-- });
			-- 
			-- // This runs the function specified as second argument to `jest.mock`.
			-- const moduleName = require('../moduleName');
			-- moduleName(); // Will return '42';
			-- ```
			-- 
			-- When using the `factory` parameter for an ES6 module with a default export, the `__esModule: true` property needs to be specified. This property is normally generated by Babel / TypeScript, but here it needs to be set manually. When importing a default export, it's an instruction to import the property named `default` from the export object:
			-- 
			-- ```js
			-- import moduleName, {foo} from '../moduleName';
			-- 
			-- jest.mock('../moduleName', () => {
			--   return {
			--     __esModule: true,
			--     default: jest.fn(() => 42),
			--     foo: jest.fn(() => 43),
			--   };
			-- });
			-- 
			-- moduleName(); // Will return 42
			-- foo(); // Will return 43
			-- ```
			-- 
			-- The third argument can be used to create virtual mocks – mocks of modules that don't exist anywhere in the system:
			-- 
			-- ```js
			-- jest.mock(
			--   '../moduleName',
			--   () => {
			--     /*
			--      * Custom implementation of a module that doesn't exist in JS,
			--      * like a generated module or a native module in react-native.
			--      */
			--   },
			--   {virtual: true},
			-- );
			-- ```
			-- 
			-- :::caution
			-- 
			-- Importing a module in a setup file (as specified by [`setupFilesAfterEnv`](Configuration.md#setupfilesafterenv-array)) will prevent mocking for the module in question, as well as all the modules that it imports.
			jestronaut:mock(
			    "../moduleName",
			    function()
			        return jestronaut:fn(function() return 42 end)
			    end
			)
			local moduleName = require('moduleName')
			moduleName()
			
		
		end);
		
	
	end)(),
	

}

return tests