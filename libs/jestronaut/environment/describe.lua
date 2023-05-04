local DESCRIBE_OR_TEST_META = require "jestronaut/environment/state".DESCRIBE_OR_TEST_META
local registerDescribeOrTest = require "jestronaut/environment/state".registerDescribeOrTest
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex

--- @class Describe
local DESCRIBE_META = {
  isDescribe = true,
}

extendMetaTableIndex(DESCRIBE_META, DESCRIBE_OR_TEST_META)

--- Creates a new describe.
--- @param name string
--- @param fn function
--- @param options DescribeOptions
--- @return Describe
local function _internalDescribe(name, fn, options)
  if(type(name) ~= "string") then
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
  
  registerDescribeOrTest(describe)

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

return {
  describe = describe,

  describeOnly = describeOnly,
  fdescribe = describeOnly,

  describeSkip = describeSkip,
  xdescribe = describeSkip,
}
