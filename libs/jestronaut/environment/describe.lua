local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local stateLib = require "jestronaut/environment/state"

--- @class Describe
local DESCRIBE_META = {
    isDescribe = true,
}

extendMetaTableIndex(DESCRIBE_META, stateLib.DESCRIBE_OR_TEST_META)

--- Creates a new describe.
--- @param name string
--- @param fn function
--- @param options DescribeOptions
--- @return Describe
local function _internalDescribe(name, fn, options)
    if (type(name) ~= "string") then
        error("describe name must be a string")
    end

    local describe = {
        name = name,
        fn = fn,

        children = {},
        childrenLookup = {},
    }

    if options then
        describe.isOnlyToRun = options.isOnlyToRun
        describe.toSkip = options.toSkip
    end

    setmetatable(describe, DESCRIBE_META)

    stateLib.registerDescribeOrTest(describe)

    return describe
end

--- Creates a new describe.
--- @param name string
--- @param fn function
--- @return Describe
local function describe(name, fn)
    return _internalDescribe(name, fn)
end

--- Creates a new describe that is the only one that will run.
--- @param self Describe
--- @param name string
--- @param fn function
--- @return Describe
local function describeOnly(self, name, fn)
    local _describe = _internalDescribe(name, fn, {
        isOnlyToRun = true,
    })

    return _describe
end

--- Creates a new describe that will be skipped.
--- @param self Describe
--- @param name string
--- @param fn function
--- @return Describe
local function describeSkip(self, name, fn)
    local _describe = _internalDescribe(name, fn, {
        toSkip = true,
    })

    return _describe
end

--- Creates a new describe that is transparent, meaning the user will
--- not see it, but it is used for internal purposes like marking root.
--- @param name string
--- @param fn function
--- @param arguments? table
--- @return Describe
local function describeTransparent(name, fn, arguments)
    arguments = arguments or {}
    arguments.isTransparent = true

    return _internalDescribe(name, fn, arguments)
end

return {
    describe = describe,

    describeOnly = describeOnly,
    fdescribe = describeOnly,

    describeSkip = describeSkip,
    xdescribe = describeSkip,

    describeTransparent = describeTransparent,
}
