-- jest.fn



local tests = {

	(function()
		-- :::tip
		-- 
		-- See the [Mock Functions](MockFunctionAPI.md#jestfnimplementation) page for details on TypeScript usage.
		local mockFn = jestronaut:fn()
		mockFn()
		expect(mockFn):toHaveBeenCalled()
		local returnsTrue = jestronaut:fn(function() return true end)
		print(returnsTrue())
		
	
	end)(),
	

}

return tests