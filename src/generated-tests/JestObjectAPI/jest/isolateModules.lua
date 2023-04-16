-- jest.isolateModules



local tests = {

	(function()
		
		local myModule
		jestronaut:isolateModules(function()
		    myModule = require('myModule')
		end)
		local otherCopyOfMyModule = require('myModule')
		
	
	end)(),
	

}

return tests