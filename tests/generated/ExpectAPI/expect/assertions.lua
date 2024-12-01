-- expect.assertions



local tests = {

    (function()
        -- For example, let's say that we have a function `doAsync` that receives two callbacks `callback1` and `callback2`, it will asynchronously call both of them in an unknown order. We can test this with:
        -- -- The `expect.assertions(2)` call ensures that both callbacks actually get called.
        test(
            "doAsync calls both callbacks",
            function()
                expect:assertions(2)
                local function callback1(data)
                    expect(data):toBeTruthy()
                end
                local function callback2(data)
                    expect(data):toBeTruthy()
                end
                doAsync(callback1, callback2)
            end
        )
    end)(),


}

return tests
