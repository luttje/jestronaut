package.path = "./libs/?.lua;" .. package.path -- Try our local version first
require "jestronaut":withGlobals()

jestronaut
    :configure({
        bail = 1,
        roots = {
            "./tests/",
        },

        -- reporter = require "jestronaut.reporter-minimal".newMinimalReporter(),
        verbose = true,
        slowDown = 50,
    })
    :registerTests(function()
        -- Setup and register the tests:
        package.path = package.path .. ";./?.lua;./?/init.lua"
        require "tests.state"
        require "tests.async"
    end)
    :runTests()
