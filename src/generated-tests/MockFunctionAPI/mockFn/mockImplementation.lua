-- mockFn.mockImplementation

package.preload['SomeClass_js'] = function()
	-- `.mockImplementation()` can also be used to mock class constructors:
	-- 
	local ____lualib = require('lualib_bundle')
	local __TS__Class = ____lualib.__TS__Class
	local ____module_0 = module
	local SomeClass = __TS__Class()
	SomeClass.name = "SomeClass"
	function SomeClass.prototype.____constructor(self)
	end
	function SomeClass.prototype.method(self, a, b)
	end
	____module_0.exports = SomeClass
	
end

package.preload['SomeClass_test_js'] = function()
	
	local ____lualib = require('lualib_bundle')
	local __TS__New = ____lualib.__TS__New
	local SomeClass = require('SomeClass')
	jestronaut:mock("./SomeClass")
	local mockMethod = jestronaut:fn()
	SomeClass:mockImplementation(function()
	    return {method = mockMethod}
	end)
	local some = __TS__New(SomeClass)
	some:method("a", "b")
	print("Calls to method: ", mockMethod.mock.calls)
	
end



local tests = {

	(function()
		-- :::
		-- 
		local mockFn = jestronaut:fn(function(scalar) return 42 + scalar end)
		mockFn(0)
		mockFn(1)
		mockFn:mockImplementation(function(scalar) return 36 + scalar end)
		mockFn(2)
		mockFn(3)
		
	
	end)(),
	
	
	(function()
		-- `.mockImplementation()` can also be used to mock class constructors:
		-- 
		local ____lualib = require('lualib_bundle')
		local __TS__Class = ____lualib.__TS__Class
		local ____module_0 = module
		local SomeClass = __TS__Class()
		SomeClass.name = "SomeClass"
		function SomeClass.prototype.____constructor(self)
		end
		function SomeClass.prototype.method(self, a, b)
		end
		____module_0.exports = SomeClass
		
	
	end)(),
	
	
	(function()
		
		local ____lualib = require('lualib_bundle')
		local __TS__New = ____lualib.__TS__New
		local SomeClass = require('SomeClass')
		jestronaut:mock("./SomeClass")
		local mockMethod = jestronaut:fn()
		SomeClass:mockImplementation(function()
		    return {method = mockMethod}
		end)
		local some = __TS__New(SomeClass)
		some:method("a", "b")
		print("Calls to method: ", mockMethod.mock.calls)
		
	
	end)(),
	

}

return tests