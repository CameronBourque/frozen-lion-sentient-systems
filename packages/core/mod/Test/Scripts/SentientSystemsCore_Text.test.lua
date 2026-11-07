local FakeGame = require("FakeGame")
local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Text.lua")
end)

describe("SentientSystems_GetTooltipLines", function()
	it("splits a tooltip at [NEWLINE] and drops the empty lines", function()
		local lines = env.SentientSystems_GetTooltipLines("MINE[NEWLINE][NEWLINE]Generating +1 [ICON_Tourism] Tourism[NEWLINE]  Lifetime: 30 [ICON_Tourism]")

		assert.same({ "MINE", "Generating +1 Tourism", "Lifetime: 30 Tourism" }, lines)
	end)

	it("drops the color tags", function()
		assert.same({ "Damaged district" }, env.SentientSystems_GetTooltipLines("[COLOR_RED]Damaged district[ENDCOLOR]"))
	end)

	it("drops a list marker, without the dash", function()
		assert.same({ "+5 from Menelik II" }, env.SentientSystems_GetTooltipLines("[NEWLINE] [ICON_Bullet]+5 from Menelik II"))
	end)

	it("returns no lines for an empty tooltip", function()
		assert.same({}, env.SentientSystems_GetTooltipLines(""))
	end)
end)

describe("SentientSystems_CleanText", function()
	local function Clean(text)
		return env.SentientSystems_CleanText(text)
	end

	it("returns nil for no text, and for text that is empty once cleaned", function()
		assert.is_nil(Clean(nil))
		assert.is_nil(Clean(""))
		assert.is_nil(Clean("[ICON_Checkmark]"))
	end)

	it("leaves text without icons as it is", function()
		assert.equal("Gain 2 Gold.[NEWLINE]Then wait.", Clean("Gain 2 Gold.[NEWLINE]Then wait."))
	end)

	it("drops an icon that its own name follows, and its plural", function()
		assert.equal("Not enough Gold in treasury", Clean("Not enough [ICON_Gold] Gold in treasury"))
		assert.equal("+33 from Envoys", Clean("+33 from [ICON_Envoy] Envoys"))
		assert.equal("excess Great Person points", Clean("excess [ICON_GREATPERSON] Great Person points"))
	end)

	it("drops an icon that its name follows after an amount", function()
		assert.equal("1 Envoy", Clean("[ICON_Envoy] 1 Envoy"))
		assert.equal("+3 Gold per turn", Clean("[ICON_Gold] +3 Gold per turn"))
	end)

	it("names an icon that no name follows", function()
		assert.equal("You need 18 more Gold in order to purchase this plot", Clean("You need 18 more [ICON_Gold] in order to purchase this plot"))
		assert.equal("Make a Trade Route.", Clean("Make a [ICON_TradeRoute]."))
	end)

	it("does not take a longer word for the icon's name", function()
		assert.equal("Gold Goldsmith", Clean("[ICON_Gold] Goldsmith"))
	end)

	it("splits the capitals of a name, and gives a name in capitals the game's words", function()
		assert.equal("Great Person", Clean("[ICON_GREATPERSON]"))
		assert.equal("Favor", Clean("[ICON_FAVOR]"))
		assert.equal("Oil", Clean("[ICON_RESOURCE_OIL]"))
		assert.equal("City Center", Clean("[ICON_DISTRICT_CITY_CENTER]"))
		assert.equal("Gold", Clean("[ICON_GoldLarge]"))
		assert.equal("Great Work Portrait", Clean("[ICON_GreatWork_Portrait]"))
	end)

	it("drops an icon that a given word follows, and names it otherwise", function()
		assert.equal("This city needs at least 2 Population.", Clean("This city needs at least 2 [ICON_Citizen] Population."))
		assert.equal("Citizen", Clean("[ICON_Citizen]"))
		assert.equal("Rising", Clean("[ICON_PressureUp] Rising"))
		assert.equal("+5 Combat Strength.", Clean("+5 [ICON_Strength] Combat Strength."))
	end)

	it("drops the color tags, whichever way they are written", function()
		assert.equal("-3 Unfavorable Terrain and 5 Rising", Clean("[COLOR_RED]-3 Unfavorable Terrain[ENDCOLOR] and [COLOR:ResCultureLabelCS]5[ENDCOLOR] [COLOR_GREEN][ICON_PressureUp] Rising[ENDCOLOR]"))
	end)

	it("drops a checkmark", function()
		assert.equal("Done", Clean("[ICON_CheckmarkBlue] Done"))
	end)

	it("writes a dash for a list marker at the start of a line, with the game's spacing", function()
		assert.equal("-The city-state follows you.[NEWLINE]- 1 from Wonders[NEWLINE] -+5 from Menelik II", Clean("[ICON_Bolt]The city-state follows you.[NEWLINE][ICON_Bolt] 1 from Wonders[NEWLINE] [ICON_Bullet]+5 from Menelik II"))
	end)

	it("drops a list marker in the middle of a line", function()
		assert.equal("Gain 2 more", Clean("Gain 2 [ICON_Bullet] more"))
	end)
end)

describe("SentientSystems_LookupText", function()
	it("looks up a text key with its arguments and cleans the text", function()
		FakeGame.Install(env, { text = { LOC_TEST = "You need [ICON_Gold] [COLOR_RED]more[ENDCOLOR]" } })
		Game.run(env, "Scripts/SentientSystemsCore_Text.lua")

		assert.equal("You need Gold more(18)", env.SentientSystems_LookupText("LOC_TEST", 18))
	end)

	it("returns empty text for a blank text", function()
		FakeGame.Install(env, { text = { LOC_BLANK = "" } })
		Game.run(env, "Scripts/SentientSystemsCore_Text.lua")

		assert.equal("", env.SentientSystems_LookupText("LOC_BLANK"))
	end)
end)
