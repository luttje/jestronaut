local ASYMMETRIC_MATCHER_META = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher".ASYMMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex

--- @class StringContaining
local STRING_CONTAINING_META
STRING_CONTAINING_META = {
    new = function(sample, inverse)
        local instance = {
            sample = sample,
            inverse = inverse or false,
        }

        setmetatable(instance, STRING_CONTAINING_META)
        return instance
    end,

    -- matches the received value if it is a string that contains the exact expected string.
    asymmetricMatch = function(self, actual)
        local result = type(actual) == 'string' and string.find(actual, self.sample);

        return self.inverse and not result or result;
    end,

    __tostring = function(self)
        return 'String' .. (self.inverse and 'Not' or '') .. 'Containing'
    end,

    getExpectedType = function(self)
        return 'string'
    end,
}

extendMetaTableIndex(STRING_CONTAINING_META, ASYMMETRIC_MATCHER_META)

return {
    STRING_CONTAINING_META = STRING_CONTAINING_META,
    default = function(expect, sample)
        return STRING_CONTAINING_META.new(sample, expect.inverse)
    end,
}
