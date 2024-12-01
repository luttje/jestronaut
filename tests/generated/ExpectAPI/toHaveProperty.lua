-- .toHaveProperty



local tests = {

    (function()
        local houseForSale = {
            bath = true,
            bedrooms = 4,
            kitchen = { amenities = { "oven", "stove", "washer" }, area = 20, wallColor = "white", ["nice.oven"] = true },
            livingroom = { amenities = { { couch = { { "large", { dimensions = { 20, 20 } } }, { "small", { dimensions = { 10, 10 } } } } } } },
            ["ceiling.height"] = 2
        }
        test(
            "this house has my desired features",
            function()
                expect(houseForSale):toHaveProperty("bath")
                expect(houseForSale):toHaveProperty("bedrooms", 4)
                expect(houseForSale)["not"]:toHaveProperty("pool")
                expect(houseForSale):toHaveProperty("kitchen.area", 20)
                expect(houseForSale):toHaveProperty("kitchen.amenities", { "oven", "stove", "washer" })
                expect(houseForSale)["not"]:toHaveProperty("kitchen.open")
                expect(houseForSale):toHaveProperty({ "kitchen", "area" }, 20)
                expect(houseForSale):toHaveProperty({ "kitchen", "amenities" }, { "oven", "stove", "washer" })
                expect(houseForSale):toHaveProperty({ "kitchen", "amenities", 1 }, "oven")
                expect(houseForSale):toHaveProperty("livingroom.amenities[1].couch[1][2].dimensions[1]", 20)
                expect(houseForSale):toHaveProperty({ "kitchen", "nice.oven" })
                expect(houseForSale)["not"]:toHaveProperty({ "kitchen", "open" })
                expect(houseForSale):toHaveProperty({ "ceiling.height" }, 2)
            end
        )
    end)(),


}

return tests
