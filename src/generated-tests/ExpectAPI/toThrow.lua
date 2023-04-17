-- .toThrow



local tests = {

	(function()
		-- Use `.toThrow` to test that a function throws when it is called. For example, if we want to test that `drinkFlavor('octopus')` throws, because octopus flavor is too disgusting to drink, we could write:
		-- -- :::tip
		-- 
		-- You must wrap the code in a function, otherwise the error will not be caught and the assertion will fail.
		test(
		    "throws on octopus",
		    function()
		        expect(function()
		            drinkFlavor("octopus")
		        end):toThrow()
		    end
		)
		
	
	end)(),
	
	
	(function()
		test(".toThrow 1", function()
			-- For example, let's say that `drinkFlavor` is coded like this:
			-- 
			local ____lualib = require('lualib_bundle')
			local __TS__New = ____lualib.__TS__New
			local function drinkFlavor(flavor)
			    if flavor == "octopus" then
			        error(
			            __TS__New(DisgustingFlavorError, "yuck, octopus flavor"),
			            0
			        )
			    end
			end
			
		
		end);
		
	
	end)(),
	
	
	(function()
		-- We could test this error gets thrown in several ways:
		-- 
		local ____lualib = require('lualib_bundle')
		local Error = ____lualib.Error
		local RangeError = ____lualib.RangeError
		local ReferenceError = ____lualib.ReferenceError
		local SyntaxError = ____lualib.SyntaxError
		local TypeError = ____lualib.TypeError
		local URIError = ____lualib.URIError
		local __TS__New = ____lualib.__TS__New
		test(
		    "throws on octopus",
		    function()
		        local function drinkOctopus()
		            drinkFlavor("octopus")
		        end
		        expect(drinkOctopus):toThrow(nil)
		        expect(drinkOctopus):toThrow("yuck")
		        expect(drinkOctopus):toThrow(nil)
		        expect(drinkOctopus):toThrow(__TS__New(Error, "yuck, octopus flavor"))
		        expect(drinkOctopus):toThrow(DisgustingFlavorError)
		    end
		)
		
	
	end)(),
	

}

return tests