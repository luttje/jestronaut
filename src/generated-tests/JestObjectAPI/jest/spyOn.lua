-- jest.spyOn



local tests = {

	(function()
		test("jest.spyOn 0", function()
			-- Example:
			-- 
			local video = {}
			module.exports = video
			local audio = {_volume = false}
			module.exports = audio
			
		
		end);
		
	
	end)(),
	
	
	(function()
		-- Example test:
		-- 
		local audio = require('audio')
		local video = require('video')
		afterEach(function()
		    jestronaut:restoreAllMocks()
		end)
		test(
		    "plays video",
		    function()
		        local spy = jestronaut:spyOn(video, "play", "get")
		        local isPlaying = video:play()
		        expect(spy):toHaveBeenCalled()
		        expect(isPlaying):toBe(true)
		    end
		)
		test(
		    "plays audio",
		    function()
		        local spy = jestronaut:spyOn(audio, "volume", "set")
		        audio.volume = 100
		        expect(spy):toHaveBeenCalled()
		        expect(audio.volume):toBe(100)
		    end
		)
		
	
	end)(),
	

}

return tests