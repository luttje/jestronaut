--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
  children = {},
  parent = nil,
  name = nil,
  fn = nil,
  only = false,
  skip = false,

  --- Adds a child.
  --- @param child DescribeOrTest
  --- @return DescribeOrTest
  addChild = function(self, child)
    table.insert(self.children, child)
    return child
  end,
}

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
}