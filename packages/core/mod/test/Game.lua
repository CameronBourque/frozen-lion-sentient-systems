-- Loads core mod files for tests, into an environment that matches the game's Lua. The game runs
-- Havok Script, which matches Lua 5.1.5 except for five functions it doesn't have. See
-- docs/findings/lua-contexts.md#lua-51-comparison. Example:
-- local env = Game.new()
-- Game.run(env, "Scripts/SentientSystemsCore_Tag.lua")
-- env.SentientSystems_Print("AGENT_TURN", 0)
-- env.printed[1] is "[SENTIENTSYSTEMS] AGENT_TURN 0".

local Game = {}

-- The mod folder, with a trailing slash, from this file's path.
local MOD_ROOT = debug.getinfo(1, "S").source:match("^@(.*)test[/\\][^/\\]*$")

-- The global functions and libraries a mod file can use. load, setfenv, and io are missing in the
-- game. debug is missing in UI states. Functions the game has that aren't checked yet, such as
-- require, are left out until a test needs them.
local GLOBALS = {
	"_VERSION", "assert", "collectgarbage", "error", "getmetatable", "ipairs", "loadstring", "next",
	"pairs", "pcall", "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber",
	"tostring", "type", "unpack", "xpcall", "coroutine", "math", "os",
}

local function Copy(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

-- Returns a new environment. env.printed lists each line that print printed. env.include(name)
-- runs Scripts/<name>.lua in the same environment, as include does for a file in ImportFiles.
function Game.new()
	local env = { printed = {} }

	for _, name in ipairs(GLOBALS) do
		env[name] = _G[name]
	end

	env._G = env
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
		Game.run(env, "Scripts/" .. name .. ".lua")
	end

	return env
end

-- Runs a mod file, such as "Scripts/SentientSystemsCore_Tag.lua", in env.
function Game.run(env, path)
	local chunk = assert(loadfile(MOD_ROOT .. path))

	setfenv(chunk, env)
	chunk()
end

return Game
