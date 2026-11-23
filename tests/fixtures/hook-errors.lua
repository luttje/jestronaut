-- Hooks that fail, used to check which tests fail because of them.
HOOK_ERRORS_LOG = {}

describe("failing beforeAll", function()
    beforeAll(function() error("beforeAll broke") end)

    it("first test in failing beforeAll", function() table.insert(HOOK_ERRORS_LOG, "ran first") end)
    it("second test in failing beforeAll", function() table.insert(HOOK_ERRORS_LOG, "ran second") end)
end)

describe("failing beforeEach", function()
    beforeEach(function() error("beforeEach broke") end)
    afterEach(function() table.insert(HOOK_ERRORS_LOG, "afterEach after failing beforeEach") end)

    it("test with failing beforeEach", function() table.insert(HOOK_ERRORS_LOG, "ran with failing beforeEach") end)
end)

describe("failing afterEach", function()
    afterEach(function() error("afterEach broke") end)

    it("test with failing afterEach", function() end)
end)

it("test without failing hooks", function() end)
