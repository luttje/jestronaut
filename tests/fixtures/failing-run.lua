-- A test run that is meant to fail. CI runs this to verify that Jestronaut exits with a non-zero status code
-- when a test fails. It is not part of the regular test suite.
package.path = "./libs/?.lua;" .. package.path
require "jestronaut":withGlobals()

jestronaut
    :configure({
        roots = {
            "./tests/fixtures/",
        },
    })
    :registerTests(function()
        it("fails on purpose", function()
            expect(1 + 1):toBe(3)
        end)
    end)
    :runTests()
