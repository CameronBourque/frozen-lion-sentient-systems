local Helpers = require("Helpers")

describe("Helpers.With", function()
	it("copies the table with the changes on top, and leaves the original alone", function()
		local original = { id = 1, x = 10 }

		assert.same({ id = 1, x = 11, y = 5 }, Helpers.With(original, { x = 11, y = 5 }))
		assert.same({ id = 1, x = 10 }, original)
	end)
end)

describe("Helpers.Failed", function()
	it("gives the JSON of a failed action", function()
		assert.equal("{\"ok\":false,\"reason\":\"No moves left.\"}", Helpers.Failed("No moves left."))
	end)
end)

describe("Helpers.Entry", function()
	local JSON = "[{\"player\":1,\"score\":3},{\"player\":12,\"score\":4},{\"unmet\":true,\"score\":5}]"

	it("finds a player's entry, not one whose ID starts the same", function()
		assert.equal("{\"player\":1,\"score\":3}", Helpers.Entry(JSON, 1))
	end)

	it("finds the unmet entry for nil, and nothing for a player with none", function()
		assert.equal("{\"unmet\":true,\"score\":5}", Helpers.Entry(JSON, nil))
		assert.is_nil(Helpers.Entry(JSON, 7))
	end)
end)
