local DESCRIBE_OR_TEST_META = require "jestronaut.environment.shared".DESCRIBE_OR_TEST_META

--- @class Describe
local DESCRIBE_META = {
  __index = DESCRIBE_OR_TEST_META,
}

--- Creates a new describe.
--- @param name string
--- @param fn function
--- @param parent Describe
--- @return Describe
local function describe(name, fn, parent)
  local describe = {
    name = name,
    fn = fn,
    parent = parent,
  }

  setmetatable(describe, DESCRIBE_META)

  return describe
end

--- Creates a new describe that is the only one that will run.
--- @param name string
--- @param fn function
--- @param parent Describe
--- @return Describe
local function describeOnly(name, fn, parent)
  local describe = describe(name, fn, parent)
  describe.only = true

  return describe
end

--- Creates a new describe that will be skipped.
--- @param name string
--- @param fn function
--- @param parent Describe
--- @return Describe
local function describeSkip(name, fn, parent)
  local describe = describe(name, fn, parent)
  describe.skip = true

  return describe
end

return {
  describe = describe,

  describeOnly = describeOnly,
  fdescribe = describeOnly,

  describeSkip = describeSkip,
  xdescribe = describeSkip,
}
