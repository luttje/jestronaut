-- Tests that are retried, used to check that each test gets its own retries.
RETRY_ATTEMPTS = {}

local function attempt(name)
    RETRY_ATTEMPTS[name] = (RETRY_ATTEMPTS[name] or 0) + 1
    return RETRY_ATTEMPTS[name]
end

jestronaut:retryTimes(2)

it("passes on the third attempt", function()
    expect(attempt("third")):toBe(3)
end)

it("passes on the second attempt", function()
    expect(attempt("second")):toBe(2)
end)

it("always fails", function()
    attempt("always")
    error("always fails")
end)

describe("without retries", function()
    jestronaut:retryTimes(0)

    it("fails without retrying", function()
        attempt("noRetry")
        error("fails")
    end)
end)
