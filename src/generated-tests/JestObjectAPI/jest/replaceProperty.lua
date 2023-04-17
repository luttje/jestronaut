-- jest.replaceProperty



local tests = {

	(function()
		test("jest.replaceProperty 0", function()
			-- Example:
			-- 
			local utils = {isLocalhost = function(self)
			    return process.env.HOSTNAME == "localhost"
			end}
			local exports = utils
			
		
		end);
		
	
	end)(),
	
	
	(function()
		-- Example test:
		-- 
		local utils = require('utils')
		afterEach(function()
		    jestronaut:restoreAllMocks()
		end)
		test(
		    "isLocalhost returns true when HOSTNAME is localhost",
		    function()
		        jestronaut:replaceProperty(process, "env", {HOSTNAME = "localhost"})
		        expect(utils:isLocalhost()):toBe(true)
		    end
		)
		test(
		    "isLocalhost returns false when HOSTNAME is not localhost",
		    function()
		        jestronaut:replaceProperty(process, "env", {HOSTNAME = "not-localhost"})
		        expect(utils:isLocalhost()):toBe(false)
		    end
		)
		
	
	end)(),
	

}

return tests