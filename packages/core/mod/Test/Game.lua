-- Loads core mod files for tests, into an environment that matches the game's
-- Lua. The game runs Havok Script, which matches Lua 5.1.5 except for five
-- functions it doesn't have. See
-- docs/findings/lua/contexts.md#lua-51-comparison.

local Game = {}

-- The mod folder, with a trailing slash, from this file's path.
local MOD_ROOT = debug.getinfo(1, "S").source:match("^@(.*)Test[/\\][^/\\]*$")

-- The global functions and libraries a mod file can use. load, setfenv,
-- getfenv, _G, and io are missing in the game. debug is missing in UI states.
-- Functions the game has that aren't checked yet are left out until a test
-- needs them.
local GLOBALS = {
	"_VERSION", "assert", "collectgarbage", "error", "getmetatable", "ipairs", "loadstring", "next",
	"pairs", "pcall", "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber",
	"tostring", "type", "unpack", "xpcall", "coroutine", "math", "os",
}

-- The folder that records the JSON of each top-level call, for the bridge
-- tests. npm run test:lua makes it, with one folder per call.
local FIXTURES = MOD_ROOT .. "../bridge/test/lua-fixtures/"

-- The top-level calls to record.
local RECORDED = {
	"GetState", "GetChoices", "GetTechTree", "GetCivicTree", "GetGovernorTree", "GetPlacement", "MoveUnit",
}

-- How many JSON strings each test file has recorded for each call, by
-- "call/file".
local recorded = {}

-- Returns the paths in the mod folder from the File lines of each block that
-- the pattern matches in the .modinfo.
local function ReadPaths(pattern)
	local file = assert(io.open(MOD_ROOT .. "SentientSystemsCore.modinfo"))
	local text = file:read("*a")
	local paths = {}

	file:close()

	for block in text:gmatch(pattern) do
		for path in block:gmatch("<File>(.-)</File>") do
			paths[#paths + 1] = path
		end
	end

	return paths
end

-- Returns each imported file's path in the mod folder, by its name without the
-- extension, from the ImportFiles actions in the .modinfo. The game's include
-- finds only these files.
local function ReadImports()
	local imports = {}

	for _, path in ipairs(ReadPaths("<ImportFiles.-</ImportFiles>")) do
		imports[path:match("([^/]+)%.lua$")] = path
	end

	return imports
end

local IMPORTS = ReadImports()

local function Copy(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

-- Returns the name of the test file that is running, without .test.lua.
local function TestName()
	local level = 3

	while debug.getinfo(level, "S") do
		local name = debug.getinfo(level, "S").source:match("([^/\\]+)%.test%.lua$")

		if name then
			return name
		end

		level = level + 1
	end

	return "unknown"
end

-- Writes the JSON that a top-level call returned, named by the test file and
-- the call's order in it. Without the folder, as when busted runs on its own,
-- it writes nothing.
local function Record(call, json)
	local name = TestName()
	local key = call .. "/" .. name
	local count = (recorded[key] or 0) + 1
	local file = io.open(FIXTURES .. call .. "/" .. name .. "-" .. count .. ".json", "w")

	recorded[key] = count

	if file then
		file:write(json)
		file:close()
	end
end

-- Replaces each top-level call that the file defined with one that records its
-- JSON.
local function WrapRecorded(env)
	for _, call in ipairs(RECORDED) do
		local original = env["SentientSystems_" .. call]

		if original and not recorded[original] then
			local wrapper = function(...)
				local json = original(...)

				if type(json) == "string" then
					Record(call, json)
				end

				return json
			end

			recorded[wrapper] = true
			env["SentientSystems_" .. call] = wrapper
		end
	end
end

-- Returns a new environment. env.printed lists each line that print printed.
-- env.include(name) runs the file with that name from ImportFiles in the
-- .modinfo, in the same environment, and returns a list of its path, as include
-- does. For a name that ImportFiles doesn't list, it returns an empty list, as
-- the game does.
function Game.new()
	local env = { printed = {} }

	for _, name in ipairs(GLOBALS) do
		env[name] = _G[name]
	end

	env.string = Copy(string)
	env.string.gfind = nil
	env.table = Copy(table)
	env.table.getn = nil

	-- The game joins print's arguments with tabs, as Lua does.
	function env.print(...)
		local parts = {}

		for i = 1, select("#", ...) do
			parts[i] = tostring(select(i, ...))
		end

		env.printed[#env.printed + 1] = table.concat(parts, "\t")
	end

	function env.include(name)
		local path = IMPORTS[name]

		if path == nil then
			return {}
		end

		Game.run(env, path)

		return { MOD_ROOT .. path }
	end

	return env
end

-- Returns the paths in the mod folder from the .modinfo's ImportFiles actions
-- as imports, and from its Files list as files.
function Game.fileLists()
	return {
		imports = ReadPaths("<ImportFiles.-</ImportFiles>"),
		files = ReadPaths("<Files>.-</Files>"),
	}
end

-- Runs a mod file in env.
function Game.run(env, path)
	local chunk = assert(loadfile(MOD_ROOT .. path))

	setfenv(chunk, env)
	chunk()
	WrapRecorded(env)
end

return Game
