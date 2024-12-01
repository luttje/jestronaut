-- .toHaveReturnedWith



local tests = {

    (function()
        -- For example, let's say you have a mock `drink` that returns the name of the beverage that was consumed. You can write:
        --
        test(
            "drink returns La Croix",
            function()
                local beverage = { name = "La Croix" }
                local drink = jestronaut:fn(function(beverage) return beverage.name end)
                drink(beverage)
                expect(drink):toHaveReturnedWith("La Croix")
            end
        )
    end)(),


}

return tests
