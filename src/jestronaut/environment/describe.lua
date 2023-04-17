local DESCRIBE_OR_TEST_META = require "jestronaut.environment.shared".DESCRIBE_OR_TEST_META
local registerDescribeOrTest = require "jestronaut.environment.state".registerDescribeOrTest
local extendMetaTableIndex = require "jestronaut.utils.metatables".extendMetaTableIndex

--- @class Describe
local DESCRIBE_META = {
  isDescribe = true,
}

extendMetaTableIndex(DESCRIBE_META, DESCRIBE_OR_TEST_META)

--- Creates a new describe.
--- @param name string
--- @param fn function
--- @return Describe
local function describe(name, fn)
  if(type(name) ~= "string") then
    error("describe name must be a string")
  end

  local describe = {
    name = name,
    fn = fn,
    
    children = {},
    childrenLookup = {},
  }

  setmetatable(describe, DESCRIBE_META)
  
  registerDescribeOrTest(describe)

  return describe
end

--- Creates a new describe that is the only one that will run.
--- @param describe Describe
--- @param name string
--- @param fn function
--- @return Describe
local function describeOnly(describe, name, fn)
  describe.isOnly = true
  describe(name, fn)

  return describe
end

--- Creates a new describe that will be skipped.
--- @param describe Describe
--- @param name string
--- @param fn function
--- @return Describe
local function describeSkip(describe, name, fn)
  describe.isSkipping = true
  describe(name, fn)

  return describe
end

return {
  describe = describe,

  describeOnly = describeOnly,
  fdescribe = describeOnly,

  describeSkip = describeSkip,
  xdescribe = describeSkip,
}
