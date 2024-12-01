local ASYMMETRIC_MATCHER_META = require "jestronaut/expect/asymmetricmatchers/asymmetricmatcher".ASYMMETRIC_MATCHER_META
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex

--- @class Anything
local ANYTHING_META
ANYTHING_META = {
    new = function(sample, inverse)
        local instance = {
            sample = sample,
            inverse = inverse or false,
        }

        setmetatable(instance, ANYTHING_META)
        return instance
    end,

    asymmetricMatch = function(self, actual)
        return actual ~= nil
    end,

    __tostring = function(self)
        return 'Anything'
    end,

    getExpectedType = function(self)
        return 'any'
    end,
}

extendMetaTableIndex(ANYTHING_META, ASYMMETRIC_MATCHER_META)

return {
    ANYTHING_META = ANYTHING_META,
    default = function(expect, sample)
        return ANYTHING_META.new(sample, expect.inverse)
    end,
}
