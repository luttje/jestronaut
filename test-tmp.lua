package.path = "./libs/?.lua;" .. package.path -- Try our local version first
require "jestronaut":withGlobals()

jestronaut
    :configure({
        roots = {
            "./tests/",
        },

        reporter = require "jestronaut.reporter-minimal".newMinimalReporter(),
    })
    :registerTests(function()
        -- Setup and register the tests:
        package.path = package.path .. ";./?.lua;./?/init.lua"
        require "tests.async"
    end)
    :runTests()
