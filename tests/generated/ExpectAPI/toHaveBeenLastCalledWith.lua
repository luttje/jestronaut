-- .toHaveBeenLastCalledWith



local tests = {

    (function()
        -- If you have a mock function, you can use `.toHaveBeenLastCalledWith` to test what arguments it was last called with. For example, let's say you have a `applyToAllFlavors(f)` function that applies `f` to a bunch of flavors, and you want to ensure that when you call it, the last flavor it operates on is `'mango'`. You can write:
        --
        test(
            "applying to all flavors does mango last",
            function()
                local drink = jestronaut:fn()
                applyToAllFlavors(drink)
                expect(drink):toHaveBeenLastCalledWith("mango")
            end
        )
    end)(),


}

return tests
