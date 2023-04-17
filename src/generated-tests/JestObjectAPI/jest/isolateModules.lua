-- jest.isolateModules



local tests = {

	(function()
		test("jest.isolateModules 0", function()
			
			local myModule
			jestronaut:isolateModules(function()
			    myModule = require('myModule')
			end)
			local otherCopyOfMyModule = require('myModule')
			
		
		end);
		
	
	end)(),
	

}

return tests