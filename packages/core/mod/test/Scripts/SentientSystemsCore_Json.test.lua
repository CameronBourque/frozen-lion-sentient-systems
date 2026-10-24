local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Json.lua")
end)

local function Encode(value)
	return env.SentientSystems_EncodeJson(value)
end

describe("SentientSystems_EncodeJson", function()
	it("encodes booleans and nil", function()
		assert.equal("true", Encode(true))
		assert.equal("false", Encode(false))
		assert.equal("null", Encode(nil))
	end)

	it("encodes whole numbers with every digit", function()
		assert.equal("3", Encode(3))
		assert.equal("-12", Encode(-12))
		assert.equal("65536", Encode(65536))
		assert.equal("9007199254740992", Encode(2 ^ 53))
	end)

	it("encodes other numbers with 14 significant digits", function()
		assert.equal("3.5", Encode(3.5))
		assert.equal("0.1", Encode(0.1))
		assert.equal("1e+20", Encode(1e20))
	end)

	it("encodes infinity and NaN as null", function()
		assert.equal("null", Encode(1 / 0))
		assert.equal("null", Encode(-1 / 0))
		assert.equal("null", Encode(0 / 0))
	end)

	it("quotes a string and escapes quotes, backslashes, and control characters", function()
		assert.equal("\"Aduatuca\"", Encode("Aduatuca"))
		assert.equal("\"say \\\"hi\\\" C:\\\\Mods\"", Encode("say \"hi\" C:\\Mods"))
		assert.equal("\"a\\nb\\rc\\td\\be\\ff\"", Encode("a\nb\rc\td\be\ff"))
		assert.equal("\"\\u0001\\u001f\\u007f\"", Encode("\1\31\127"))
	end)

	it("passes UTF-8 text through", function()
		assert.equal("\"Kraków\"", Encode("Kraków"))
	end)

	it("encodes a table with keys 1 to n as a list", function()
		assert.equal("[1,\"two\",true]", Encode({ 1, "two", true }))
	end)

	it("encodes an empty table as an empty list", function()
		assert.equal("[]", Encode({}))
	end)

	it("encodes other tables as objects, with sorted keys", function()
		assert.equal("{\"id\":65536,\"name\":\"Aduatuca\",\"x\":42}", Encode({ x = 42, name = "Aduatuca", id = 65536 }))
	end)

	it("encodes a table with a hole as an object with number keys", function()
		assert.equal("{\"1\":\"a\",\"3\":\"c\"}", Encode({ [1] = "a", [3] = "c" }))
	end)

	it("encodes a list with a string key as an object", function()
		assert.equal("{\"1\":\"a\",\"n\":1}", Encode({ "a", n = 1 }))
	end)

	it("writes number keys as text and sorts them as text", function()
		assert.equal("{\"131073\":true,\"65536\":false}", Encode({ [65536] = false, [131073] = true }))
	end)

	it("encodes nested lists and objects", function()
		local state = {
			cities = { { id = 65536, districts = { "DISTRICT_CITY_CENTER" } } },
			units = {},
		}

		assert.equal("{\"cities\":[{\"districts\":[\"DISTRICT_CITY_CENTER\"],\"id\":65536}],\"units\":[]}", Encode(state))
	end)

	it("encodes the same table twice when it doesn't hold itself", function()
		local shared = { 1 }

		assert.equal("[[1],[1]]", Encode({ shared, shared }))
	end)

	it("returns one line for text with newlines", function()
		assert.is_nil(Encode({ name = "line one\nline two" }):find("\n"))
	end)

	it("raises an error that names where a function is", function()
		assert.has_error(function()
			Encode({ cities = { { name = print } } })
		end, "can't encode a function, at value.cities[1].name")
	end)

	it("raises an error for a key that isn't a string or number", function()
		assert.has_error(function()
			Encode({ list = { [true] = 1 } })
		end, "can't encode a boolean key, at value.list")
	end)

	it("raises an error for a table that holds itself", function()
		local loop = {}

		loop.self = loop

		assert.has_error(function()
			Encode(loop)
		end, "can't encode a table that holds itself, at value.self")
	end)
end)

describe("SentientSystems_PrintChunks", function()
	it("prints text shorter than one piece as one line", function()
		env.SentientSystems_PrintChunks("{\"cities\":[]}")

		assert.same({ "{\"cities\":[]}" }, env.printed)
	end)

	it("prints empty text as one empty line", function()
		env.SentientSystems_PrintChunks("")

		assert.same({ "" }, env.printed)
	end)

	it("prints exactly one piece as one line", function()
		local text = string.rep("a", 1000000)

		env.SentientSystems_PrintChunks(text)

		assert.equal(1, #env.printed)
		assert.equal(text, env.printed[1])
	end)

	it("prints longer text in pieces of 1,000,000 bytes that join to the text", function()
		local text = string.rep("a", 1000000) .. string.rep("b", 1000000) .. string.rep("c", 500000)

		env.SentientSystems_PrintChunks(text)

		assert.equal(3, #env.printed)
		assert.equal(1000000, #env.printed[1])
		assert.equal(1000000, #env.printed[2])
		assert.equal(500000, #env.printed[3])
		assert.equal(text, table.concat(env.printed))
	end)

	it("never ends a piece inside a UTF-8 character", function()
		-- "é" is 2 bytes, 195 and 169, at bytes 1,000,000 and 1,000,001, across the cut.
		local text = string.rep("a", 999999) .. "é" .. "b"

		env.SentientSystems_PrintChunks(text)

		assert.equal(2, #env.printed)
		assert.equal(999999, #env.printed[1])
		assert.equal("éb", env.printed[2])
	end)

	it("keeps a UTF-8 character that ends at the cut in the piece", function()
		-- "é" is at bytes 999,999 and 1,000,000, so the cut doesn't move.
		local text = string.rep("a", 999998) .. "é" .. "b"

		env.SentientSystems_PrintChunks(text)

		assert.equal(2, #env.printed)
		assert.equal(1000000, #env.printed[1])
		assert.equal("b", env.printed[2])
	end)
end)
