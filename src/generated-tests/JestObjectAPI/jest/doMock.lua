-- jest.doMock



local tests = {

	(function()
		-- One example when this is useful is when you want to mock a module differently within the same file:
		-- -- ```ts tab
		-- beforeEach(() => {
		--   jest.resetModules();
		-- });
		-- 
		-- test('moduleName 1', () => {
		--   // The optional type argument provides typings for the module factory
		--   jest.doMock<typeof import('../moduleName')>('../moduleName', () => {
		--     return jest.fn(() => 1);
		--   });
		--   const moduleName = require('../moduleName');
		--   expect(moduleName()).toBe(1);
		-- });
		-- 
		-- test('moduleName 2', () => {
		--   jest.doMock<typeof import('../moduleName')>('../moduleName', () => {
		--     return jest.fn(() => 2);
		--   });
		--   const moduleName = require('../moduleName');
		--   expect(moduleName()).toBe(2);
		-- });
		-- ```
		-- 
		-- Using `jest.doMock()` with ES6 imports requires additional steps. Follow these if you don't want to use `require` in your tests:
		-- 
		-- - We have to specify the `__esModule: true` property (see the [`jest.mock()`](#jestmockmodulename-factory-options) API for more information).
		-- - Static ES6 module imports are hoisted to the top of the file, so instead we have to import them dynamically using `import()`.
		-- - Finally, we need an environment which supports dynamic importing. Please see [Using Babel](GettingStarted.md#using-babel) for the initial setup. Then add the plugin [babel-plugin-dynamic-import-node](https://www.npmjs.com/package/babel-plugin-dynamic-import-node), or an equivalent, to your Babel config to enable dynamic importing in Node.
		beforeEach(function()
		    jestronaut:resetModules()
		end)
		test(
		    "moduleName 1",
		    function()
		        jestronaut:doMock(
		            "../moduleName",
		            function()
		                return jestronaut:fn(function() return 1 end)
		            end
		        )
		        local moduleName = require('moduleName')
		        expect(moduleName()):toBe(1)
		    end
		)
		test(
		    "moduleName 2",
		    function()
		        jestronaut:doMock(
		            "../moduleName",
		            function()
		                return jestronaut:fn(function() return 2 end)
		            end
		        )
		        local moduleName = require('moduleName')
		        expect(moduleName()):toBe(2)
		    end
		)
		
	
	end)(),
	
	
	(function()
		-- Returns the `jest` object for chaining.
		local ____lualib = require('lualib_bundle')
		local __TS__Promise = ____lualib.__TS__Promise
		beforeEach(function()
		    jestronaut:resetModules()
		end)
		test(
		    "moduleName 1",
		    function()
		        jestronaut:doMock(
		            "../moduleName",
		            function()
		                return {__esModule = true, default = "default1", foo = "foo1"}
		            end
		        )
		        local ____self_0 = __TS__Promise.resolve(require('moduleName'))
		        return ____self_0["then"](
		            ____self_0,
		            function(____, moduleName)
		                expect(moduleName.default):toBe("default1")
		                expect(moduleName.foo):toBe("foo1")
		            end
		        )
		    end
		)
		test(
		    "moduleName 2",
		    function()
		        jestronaut:doMock(
		            "../moduleName",
		            function()
		                return {__esModule = true, default = "default2", foo = "foo2"}
		            end
		        )
		        local ____self_1 = __TS__Promise.resolve(require('moduleName'))
		        return ____self_1["then"](
		            ____self_1,
		            function(____, moduleName)
		                expect(moduleName.default):toBe("default2")
		                expect(moduleName.foo):toBe("foo2")
		            end
		        )
		    end
		)
		
	
	end)(),
	

}

return tests