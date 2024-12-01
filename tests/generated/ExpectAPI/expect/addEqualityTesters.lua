-- expect.addEqualityTesters

generatedTestPreLoad('Volume_js', function()
    -- You can use `expect.addEqualityTesters` to add your own methods to test if two objects are equal. For example, let's say you have a class in your code that represents volume and can determine if two volumes using different units are equal. You may want `toEqual` (and other equality matchers) to use this custom equality method when comparing to Volume classes. You can add a custom equality tester to have `toEqual` detect and apply custom logic when comparing Volume classes:
    --
    local ____lualib = require("lualib_bundle")
    local __TS__Class = ____lualib.__TS__Class
    local ____exports = {}
    ____exports.Volume = __TS__Class()
    local Volume = ____exports.Volume
    Volume.name = "Volume"
    function Volume.prototype.____constructor(self, amount, unit)
        self.amount = amount
        self.unit = unit
    end

    function Volume.prototype.__tostring(self)
        return (("[Volume " .. tostring(self.amount)) .. tostring(self.unit)) .. "]"
    end

    function Volume.prototype.equals(self, other)
        if self.unit == other.unit then
            return self.amount == other.amount
        elseif self.unit == "L" and other.unit == "mL" then
            return self.amount * 1000 == other.unit
        else
            return self.amount == other.unit * 1000
        end
    end

    return ____exports
end)

generatedTestPreLoad('areVolumesEqual_js', function()
    local ____lualib = require("lualib_bundle")
    local __TS__InstanceOf = ____lualib.__TS__InstanceOf
    local ____exports = {}
    local ____globals = require("@jestronaut_globals")
    local expect = ____globals.expect
    local ____Volume_2Ejs = require("Volume_js")
    local Volume = ____Volume_2Ejs.Volume
    local function areVolumesEqual(a, b)
        local isAVolume = __TS__InstanceOf(a, Volume)
        local isBVolume = __TS__InstanceOf(b, Volume)
        if isAVolume and isBVolume then
            return a:equals(b)
        elseif isAVolume ~= isBVolume then
            return false
        else
            return nil
        end
    end
    expect:addEqualityTesters({ areVolumesEqual })
    return ____exports
end)

generatedTestPreLoad('__tests__/Volume_test_js', function()
    local ____lualib = require("lualib_bundle")
    local __TS__New = ____lualib.__TS__New
    local ____exports = {}
    local ____globals = require("@jestronaut_globals")
    local expect = ____globals.expect
    local test = ____globals.test
    local ____Volume_2Ejs = require("Volume_js")
    local Volume = ____Volume_2Ejs.Volume
    require("areVolumesEqual_js")
    test(
        "are equal with different units",
        function()
            expect(__TS__New(Volume, 1, "L")):toEqual(__TS__New(Volume, 1000, "mL"))
        end
    )
    return ____exports
end)



local tests = {







}

return tests
