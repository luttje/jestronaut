-- jest.requireActual



local tests = {

	(function()
		test("jest.requireActual 0", function()
			
			local ____lualib = require('lualib_bundle')
			local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
			jestronaut:mock(
			    "../myModule",
			    function()
			        local originalModule = jestronaut:requireActual("../myModule")
			        return __TS__ObjectAssign(
			            {__esModule = true},
			            originalModule,
			            {getRandom = jestronaut:fn(function() return 10 end)}
			        )
			    end
			)
			local getRandom = require('myModule').getRandom
			getRandom()
			
		
		end);
		
	
	end)(),
	

}

return tests