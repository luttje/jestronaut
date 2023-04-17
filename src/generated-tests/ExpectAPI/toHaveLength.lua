-- .toHaveLength



local tests = {

	(function()
		test(".toHaveLength 0", function()
			
			expect({1, 2, 3}):toHaveLength(3)
			expect("abc"):toHaveLength(3)
			expect("")["not"]:toHaveLength(5)
			
		
		end);
		
	
	end)(),
	

}

return tests