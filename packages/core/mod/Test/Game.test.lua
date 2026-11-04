local Game = require("Game")

describe("Game.new", function()
	it("leaves out the functions the game's Lua doesn't have", function()
		local env = Game.new()

		assert.is_nil(env.load)
		assert.is_nil(env.setfenv)
		assert.is_nil(env.getfenv)
		assert.is_nil(env._G)
		assert.is_nil(env.io)
		assert.is_nil(env.debug)
		assert.is_nil(env.string.gfind)
		assert.is_nil(env.table.getn)
	end)

	it("keeps the functions the game's Lua has", function()
		local env = Game.new()

		assert.is_function(env.loadstring)
		assert.is_function(env.unpack)
		assert.is_table(env.os)
		assert.is_function(env.string.format)
		assert.is_function(env.table.concat)
	end)

	it("leaves the test's own libraries alone", function()
		Game.new()

		assert.is_function(string.gfind)
		assert.is_function(table.getn)
	end)

	it("joins print's arguments with tabs", function()
		local env = Game.new()

		env.print("a", nil, 1)

		assert.same({ "a\tnil\t1" }, env.printed)
	end)
end)

describe("the .modinfo file lists", function()
	-- Returns the paths in a that b doesn't have.
	local function Missing(a, b)
		local have = {}
		local missing = {}

		for _, path in ipairs(b) do
			have[path] = true
		end

		for _, path in ipairs(a) do
			if not have[path] then
				missing[#missing + 1] = path
			end
		end

		return missing
	end

	it("has every ImportFiles file in Files", function()
		local lists = Game.fileLists()

		assert.is_true(#lists.imports > 0)
		assert.same({}, Missing(lists.imports, lists.files))
	end)

	it("has every script in Files in ImportFiles", function()
		local lists = Game.fileLists()
		local scripts = {}

		for _, path in ipairs(lists.files) do
			if path:find("^Scripts/") then
				scripts[#scripts + 1] = path
			end
		end

		assert.is_true(#scripts > 0)
		assert.same({}, Missing(scripts, lists.imports))
	end)
end)

describe("Game.run", function()
	it("runs a mod file in the environment, where include loads files from Scripts", function()
		local env = Game.new()

		env.include("SentientSystemsCore_Common")

		assert.equal("[SENTIENTSYSTEMS]", env.SENTIENTSYSTEMS_TAG)
		assert.is_nil(SENTIENTSYSTEMS_TAG)
	end)

	it("returns the path of each file include loads", function()
		local loaded = Game.new().include("SentientSystemsCore_Common")

		assert.equal(1, #loaded)
		assert.truthy(loaded[1]:find("Scripts/SentientSystemsCore_Common%.lua$"))
	end)

	it("finds a file in a subfolder of Scripts through the .modinfo", function()
		local loaded = Game.new().include("SentientSystemsCore_StateCities")

		assert.truthy(loaded[1]:find("Scripts/State/SentientSystemsCore_StateCities%.lua$"))
	end)

	it("returns an empty list from include for a file that ImportFiles doesn't list", function()
		assert.same({}, Game.new().include("SentientSystemsCore_UI"))
	end)

	it("returns an empty list from include for a name with no file, as the game does", function()
		local env = Game.new()

		assert.same({}, env.include("SentientSystemsCore_Missing"))
		assert.is_nil(env.SENTIENTSYSTEMS_TAG)
	end)

	it("raises an error for a file that doesn't exist", function()
		assert.has_error(function()
			Game.run(Game.new(), "Scripts/Missing.lua")
		end)
	end)
end)
