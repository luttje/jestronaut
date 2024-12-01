-- expect.objectContaining



local tests = {

    (function()
        -- For example, let's say that we expect an `onPress` function to be called with an `Event` object, and all we need to verify is that the event has `event.x` and `event.y` properties. We can do that with:
        --
        test(
            "onPress gets called with the right thing",
            function()
                local onPress = jestronaut:fn()
                simulatePresses(onPress)
                expect(onPress):toHaveBeenCalledWith(expect:objectContaining({
                    x = expect:any(Number),
                    y = expect:any(Number)
                }))
            end
        )
    end)(),


}

return tests
