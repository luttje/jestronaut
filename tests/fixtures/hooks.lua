-- Hooks at the file level and in nested describes, used to check the order in which hooks run.
-- Every hook and test appends to HOOK_LOG, which tests/integration.lua compares to the order Jest uses.
HOOK_LOG = {}

local function log(entry)
    table.insert(HOOK_LOG, entry)
end

beforeAll(function() log("file beforeAll") end)
afterAll(function() log("file afterAll") end)
beforeEach(function() log("file beforeEach") end)
afterEach(function() log("file afterEach") end)

it("top", function() log("top") end)

describe("outer", function()
    beforeAll(function() log("outer beforeAll") end)
    afterAll(function() log("outer afterAll") end)
    beforeEach(function() log("outer beforeEach 1") end)
    beforeEach(function() log("outer beforeEach 2") end)
    afterEach(function() log("outer afterEach") end)

    it("outer test", function() log("outer test") end)

    describe("inner", function()
        beforeAll(function() log("inner beforeAll") end)
        afterAll(function() log("inner afterAll") end)
        beforeEach(function() log("inner beforeEach") end)
        afterEach(function() log("inner afterEach") end)

        it("inner test", function() log("inner test") end)
    end)

    it:skip("skipped outer test", function() log("skipped outer test") end)
end)

describe("only skipped tests", function()
    beforeAll(function() log("beforeAll of a describe without tests to run") end)
    afterAll(function() log("afterAll of a describe without tests to run") end)

    it:skip("skipped test", function() log("skipped test") end)
end)
