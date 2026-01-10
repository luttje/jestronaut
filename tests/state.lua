local timerLib = require("tests/support/timer")
JESTRONAUT_TIMER_LIBRARY = timerLib

-- Each test and describe have their own state. This is used to store
-- variables, like whether beforeAll has been run, how many assertions
-- are expected, etc.
local ranBeforeAllFile = 0

beforeAll(function()
    ranBeforeAllFile = ranBeforeAllFile + 1
end)

describe('test and describe states', function()
    describe('beforeAll', function()
        local ranBeforeAll = 0

        beforeAll(function()
            ranBeforeAll = ranBeforeAll + 1
        end)

        it("should test basic math", function()
            expect:assertions(1)

            expect(1 + 1):toEqual(2)
        end)

        test:failing("should fail Incorrect math", function()
            expect(1 + 1):toEqual(3)
        end)

        it("beforeAll should run only once before all tests", function()
            expect(ranBeforeAll):toEqual(1)
        end)
    end)

    describe('beforeAll Again', function()
        local ranBeforeAll = 0

        beforeAll(function()
            ranBeforeAll = ranBeforeAll + 1
        end)

        it("should not fail if assertions are expected and made", function()
            expect:hasAssertions()

            expect(1 + 1):toEqual(2)
        end)

        it:failing("should fail if assertions are expected but not made", function()
            expect:hasAssertions()

            -- No assertions made
        end)

        it("beforeAll should run only once before all tests, even if it ran in another describe this file", function()
            expect(ranBeforeAll):toEqual(1)
        end)
    end)

    describe('async', function()
        testAsync("Async test with delayed resolutions should match expected assertion count", function(done)
            expect:assertions(2)

            expect(1 + 1):toEqual(2)
            timerLib.setTimeout(1, function()
                expect(2 + 2):toEqual(4)
                done()
            end)
        end)

        itAsync:failing("Async test with delayed resolution should fail if assertion count is not met", function(done)
            expect:assertions(2)

            expect(1 + 1):toEqual(2)
            timerLib.setTimeout(1, function()
                done()
            end)
        end)
    end)

    describe('retrying', function()
        local count = 0
        jestronaut:retryTimes(3)

        it("should retry 3 times", function()
            count = count + 1
            expect(count):toEqual(3)
        end)
    end)
end)

it("beforeAll should run only once before all tests in the file", function()
    expect(ranBeforeAllFile):toEqual(1)
end)
