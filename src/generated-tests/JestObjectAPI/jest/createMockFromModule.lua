-- jest.createMockFromModule

package.preload['utils_js'] = function()
	-- This is useful when you want to create a [manual mock](ManualMocks.md) that extends the automatic mock's behavior:
	-- 
	module.exports = {
	    authorize = function()
	        return "token"
	    end,
	    isAuthorized = function(secret) return secret == "wizard" end
	}
	
end

package.preload['__tests__/createMockFromModule_test_js'] = function()
	
	local utils = jestronaut:createMockFromModule("../utils")
	utils.isAuthorized = jestronaut:fn(function(secret) return secret == "not wizard" end)
	test(
	    "implementation created by jestronaut.createMockFromModule",
	    function()
	        expect(jestronaut:isMockFunction(utils.authorize)):toBe(true)
	        expect(utils:isAuthorized("not wizard")):toBe(true)
	    end
	)
	
end



local tests = {

	(function()
		-- This is useful when you want to create a [manual mock](ManualMocks.md) that extends the automatic mock's behavior:
		-- 
		module.exports = {
		    authorize = function()
		        return "token"
		    end,
		    isAuthorized = function(secret) return secret == "wizard" end
		}
		
	
	end)(),
	
	
	(function()
		
		local utils = jestronaut:createMockFromModule("../utils")
		utils.isAuthorized = jestronaut:fn(function(secret) return secret == "not wizard" end)
		test(
		    "implementation created by jestronaut.createMockFromModule",
		    function()
		        expect(jestronaut:isMockFunction(utils.authorize)):toBe(true)
		        expect(utils:isAuthorized("not wizard")):toBe(true)
		    end
		)
		
	
	end)(),
	

}

return tests