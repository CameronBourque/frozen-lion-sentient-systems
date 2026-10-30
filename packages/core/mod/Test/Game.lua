-- Loads core mod files for tests, into an environment that matches the game's Lua. The game runs
-- Havok Script, which matches Lua 5.1.5 except for five functions it doesn't have. See
-- docs/findings/lua-contexts.md#lua-51-comparison. Example:
-- local env = Game.new()
-- Game.run(env, "Scripts/SentientSystemsCore_Common.lua")
-- env.SentientSystems_Print("AGENT_TURN", 0)
-- env.printed[1] is "[SENTIENTSYSTEMS] AGENT_TURN 0".

local Game = {}

-- The mod folder, with a trailing slash, from this file's path.
local MOD_ROOT = debug.getinfo(1, "S").source:match("^@(.*)Test[/\\][^/\\]*$")

-- The global functions and libraries a mod file can use. load, setfenv, getfenv, _G, and io are
-- missing in the game. debug is missing in UI states. Functions the game has that aren't checked yet, such as
-- require, are left out until a test needs them.
local GLOBALS = {
	"_VERSION", "assert", "collectgarbage", "error", "getmetatable", "ipairs", "loadstring", "next",
	"pairs", "pcall", "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber",
	"tostring", "type", "unpack", "xpcall", "coroutine", "math", "os",
}

-- Returns each imported file's path in the mod folder, by its name without the extension, from the
-- ImportFiles actions in the .modinfo. The game's include finds only these files.
local function ReadImports()
	local file = assert(io.open(MOD_ROOT .. "SentientSystemsCore.modinfo"))
	local text = file:read("*a")
	local imports = {}

	file:close()

	for action in text:gmatch("<ImportFiles.-</ImportFiles>") do
		for path in action:gmatch("<File>(.-)</File>") do
			imports[path:match("([^/]+)%.lua$")] = path
		end
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

-- Returns a new environment. env.printed lists each line that print printed. env.include(name)
-- runs the file with that name from ImportFiles in the .modinfo, in the same environment, and
-- returns a list of its path, as include does. For a name that ImportFiles doesn't list, it returns
-- an empty list, as the game does.
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

-- Runs a mod file, such as "Scripts/SentientSystemsCore_Common.lua", in env.
function Game.run(env, path)
	local chunk = assert(loadfile(MOD_ROOT .. path))

	setfenv(chunk, env)
	chunk()
end

return Game
