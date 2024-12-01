-- .toHaveBeenCalledTimes



local tests = {

    (function()
        -- For example, let's say you have a `drinkEach(drink, Array<flavor>)` function that takes a `drink` function and applies it to array of passed beverages. You might want to check that drink function was called exact number of times. You can do that with this test suite:
        --
        test(
            "drinkEach drinks each drink",
            function()
                local drink = jestronaut:fn()
                drinkEach(drink, { "lemon", "octopus" })
                expect(drink):toHaveBeenCalledTimes(2)
            end
        )
    end)(),


}

return tests
