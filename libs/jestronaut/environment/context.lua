--- @class TestContext
--- @field retrySettings? table
--- @field beforeAll? fun()
--- @field beforeEach? fun()
--- @field afterAll? fun()
--- @field afterEach? fun()
local LOCAL_STATE_META = {}

--- @type TestContext[]
local testFileContexts = {}

--- Returns the context local to the test file.
--- @param testFilePath string
--- @return TestContext
local function getTestFileContext(testFilePath)
    local fileContext = testFileContexts[testFilePath]

    if not fileContext then
        fileContext = {}
        testFileContexts[testFilePath] = fileContext
    end

    return fileContext
end

--- Traverses all test contexts up to the file. Useful for calling beforeAll and beforeEach functions.
--- If the callback returns a non-nil value, the traversal will stop and return that value.
--- @param describeOrTest DescribeOrTest
--- @param callback fun(context: TestContext, object: DescribeOrTest?): boolean?
--- @return boolean? # The result of the callback
local function traverseTestContexts(describeOrTest, callback)
    local relevantContexts = {}
    local parent = describeOrTest.parent

    table.insert(relevantContexts, {
        context = describeOrTest.context,
        object = describeOrTest,
    })

    while parent do
        if parent.context then
            table.insert(relevantContexts, {
                context = parent.context,
                object = parent,
            })
        end

        parent = parent.parent
    end

    table.insert(relevantContexts, {
        context = getTestFileContext(describeOrTest.filePath),
        object = nil,
    })

    -- Reverse the loop, so outer contexts are called first
    -- TODO: Is that what Jest does?
    -- for _, context in ipairs(relevantContexts) do
    for i = #relevantContexts, 1, -1 do
        local contextInfo = relevantContexts[i]
        local result = callback(contextInfo.context, contextInfo.object)

        if result ~= nil then
            return result
        end
    end
end

return {
    getTestFileContext = getTestFileContext,

    traverseTestContexts = traverseTestContexts,
}
