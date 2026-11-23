-- A test run that doesn't put anything in the global environment. CI runs this to verify that tests can be written
-- with the functions from require "jestronaut". It is not part of the regular test suite.
package.path = "./libs/?.lua;" .. package.path

local jestronaut = require "jestronaut"
local describe, it, expect, beforeEach = jestronaut.describe, jestronaut.it, jestronaut.expect, jestronaut.beforeEach

local globalNames = { "describe", "it", "test", "expect", "beforeAll", "beforeEach", "afterAll", "afterEach", "jestronaut" }

jestronaut
    :configure({
        roots = {
            "./tests/fixtures/",
        },
    })
    :registerTests(function()
        describe("without globals", function()
            local count = 0

            beforeEach(function()
                count = count + 1
            end)

            it("has no globals", function()
                for _, name in ipairs(globalNames) do
                    expect(rawget(_G, name)):toBeNil()
                end
            end)

            it("runs hooks", function()
                expect(count):toBe(2)
            end)

            it:skip("supports modifiers", function()
                error("skipped tests don't run")
            end)

            it("supports mocks and asymmetric matchers", function()
                local mockFn = jestronaut:fn()
                mockFn("value")

                expect(mockFn):toHaveBeenCalledWith(expect:any("string"))
            end)
        end)
    end)
    :runTests()
