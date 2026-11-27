# Tool reference

The MCP tools that the bridge serves, with the descriptions and fields that the model reads. `npm run tool-reference` generates this file from the tool schemas, so change a tool in its code, not here.

## `get_state`

Read your empire and everything you can see, as JSON. It's large, so call it at the start of a turn, and again only when a decision needs something your actions changed.

It holds your cities, units, revealed tiles, rivals you can see, diplomacy, religion, great people, governors, trade, espionage, the scoreboard, and victory progress. Fog of war applies: rivals' units are only those you see now, and tiles are only those you have revealed.

Positions are x and y on a hex map. x grows to the east and y grows to the north, so a bigger y is farther north. Odd rows sit half a tile east of even rows, so a tile's neighbours in the rows above and below are at x and x + 1 on an odd row, and at x - 1 and x on an even row.

turn is the current turn. When it hasn't changed since your last end_turn, the game cancelled the end of your turn, such as when a unit's move stopped short, so finish the turn and end it again.

blockers.list holds what stops the turn from ending, first one first. Each has choice, the key in get_choices that resolves it. blockers.units holds the IDs of units that still need orders.

It takes no fields.

## `get_choices`

Read the legal options for every decision you can make now, as JSON.

It covers what each city can produce or buy, techs and civics, policies and governments, pantheon and religion beliefs, envoys, great people, governor titles, spy missions, trade routes, artifacts, dedications, emergencies, city fates, and the World Congress.

Pick from these options when you act. A key that a blocker in get_state names is the choice that resolves it. An option the game greys out has blocked, with the game's reasons.

production and purchases have an entry for each city, which makes them the largest part. Give cityID to list only that city in them, such as when you choose one city's production.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `cityID` | integer | no | One of your cities' id, from get_state. Leave it out for every city. |

## `get_placement`

Read where a city can place one district or wonder, as JSON. Call it before you build a district or wonder.

tiles are the city's own tiles where it can go now. purchaseTiles are tiles the city could buy for it. A district's tile has adjacency, its bonus by yield. Wonders and tiles with no bonus leave adjacency out.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `cityID` | integer | yes | The city's id, from get_state. |
| `type` | string | yes | The district or wonder, such as DISTRICT_CAMPUS or BUILDING_STONEHENGE. |

## `get_tech_tree`

Read the whole tech tree as the tree screen shows it, as JSON. Use it to plan research further ahead than get_choices, which lists only the techs you can pick now.

Each node has its status: researched, current, ready, or blocked. turns is the turns left at your current rate. In Tech and Civic Shuffle mode, a node you haven't revealed shows as ? and a number.

players lists you and each player you have met, with how many nodes they have researched.

It takes no fields.

## `get_civic_tree`

Read the whole civic tree as the tree screen shows it, as JSON. Use it to plan civics further ahead than get_choices, which lists only the civics you can pick now.

Each node has its status: researched, current, ready, or blocked. turns is the turns left at your current rate. In Tech and Civic Shuffle mode, a node you haven't revealed shows as ? and a number.

players lists you and each player you have met, with how many nodes they have researched.

It takes no fields.

## `get_trade_routes`

Read every trade route one of your cities could start, as JSON, as the Trade Overview's Available Routes tab lists them. Use it to plan where to build or send a trader. It needs no trader in the city.

Your own cities come first. Each destination has its distance, what the origin and the destination each receive, any religious pressure, and whether a city-state quest completes. get_choices lists the routes only for traders that stand idle in a city.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `cityID` | integer | yes | The id of one of your cities, from get_state. |

## `get_great_work_moves`

Read the slots one of your great works can move to, as JSON, as the Great Works screen lights them up when you pick the work up. Call it before you move a great work.

from is the work's slot now. A move with swap trades places with the work already there. moves is empty when the work can't move, such as art that is still locked.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `workIndex` | integer | yes | The work's index, from greatWorks.slots[].work.index in get_state. |

## `search_civilopedia`

Search the Civilopedia for a rule, unit, building, district, improvement, civilization, leader, belief, policy, or concept, as JSON. Returns up to 10 pages, best match first, each with its sectionID, pageID, title, and a snippet.

Open a result with read_civilopedia and its pageID. A game object's pageID is its type, such as UNIT_SETTLER, so you can also read a type from the state directly.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `query` | string | yes | Words to find, such as campus adjacency or Gilgamesh. |

## `read_civilopedia`

Open the Civilopedia by ID, as JSON. Use it for exact stats, costs, requirements, and rules instead of guessing.

- pageID: returns that page's text, as the Civilopedia shows it. A game object's pageID is its type, such as UNIT_SETTLER or DISTRICT_CAMPUS. Add sectionID only when a pageID is in more than one section, such as INTRO.
- sectionID alone: lists that section's pages by group.
- Neither: lists the sections.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `pageID` | string | no | The page to open, such as UNIT_SETTLER. |
| `sectionID` | string | no | The section, such as UNITS or CONCEPTS. |

## `move_unit`

Move one of your units to a tile at x and y, by the game's own path, over as many turns as it takes. It never attacks and never declares war, so attack with unit_action.

The game may finish a move after the call returns, so read get_state for the unit's new position.

A path through unrevealed tiles assumes they can be crossed. If a revealed tile blocks the way, the move is cancelled, the events say so, and the unit needs new orders.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `unitID` | integer | yes | The unit's id, from get_state. |
| `x` | integer | yes |  |
| `y` | integer | yes |  |

## `unit_action`

Give one of your units an order. A failed order returns the game's reason, or the core mod's when the game gives none, such as which units can join a formation.

- fortify: Fortify until woken.
- sleep: Sleep until woken.
- skip: Skip this turn.
- alert: Sleep until an enemy comes into view.
- heal: Fortify until healed.
- explore: Explore on its own each turn until woken, as the game's auto-explore does.
- wake: Wake a sleeping or fortified unit.
- delete: Disband the unit.
- found_city: Found a city on the unit's tile.
- pillage: Pillage the improvement or district on the unit's tile, then the road on a second order.
- plunder: Plunder the enemy trade route on the unit's tile.
- concert: Start a rock band's concert on its tile.
- activate: Use a great person's ability on its tile, such as a great engineer's production for a wonder.
- harvest_wonder: The game's harvest wonder command for a great person.
- found_religion: Found a religion with a prophet on its Holy Site. Then choose its name and beliefs.
- spread_religion: Spread the unit's religion from the city it is in. It needs a charge left.
- remove_heresy: Remove other religions from the city with an inquisitor.
- heal_followers: Heal the wounded religious units on the unit's tile or next to it.
- evangelize_belief: Earn one more belief with an apostle. Then choose the belief.
- launch_inquisition: Launch an inquisition with an apostle.
- condemn_heretic: The game's condemn heretic command, with which a military unit kills an enemy religious unit.
- remove_feature: Remove the feature on the unit's tile with a builder.
- harvest: Harvest the resource on the unit's tile with a builder.
- repair: Repair the pillaged improvement, or the road, on the unit's tile.
- remove_improvement: Remove the improvement on the unit's tile.
- clear_fallout: Clear the nuclear fallout on the unit's tile for a build charge.
- add_production: Add a builder's or engineer's production to what the city builds, from the city or the district's tile.
- upgrade: Upgrade the unit, for gold and any resources.
- exit_formation: Split a corps or an army.
- form_corps: Join the unit in with to form a corps. Without with, the reason lists the units that can join.
- form_army: Join the unit in with to form an army. Without with, the reason lists the units that can join.
- enter_formation: Join the formation of the unit in with.
- promote: Take the promotion in promotion, such as PROMOTION_BATTLECRY.
- build_road: Build a road with a military engineer. route is optional, and the game builds the best route you have.
- improve: Build the improvement in improvement, such as IMPROVEMENT_FARM, on the unit's tile with a builder.
- attack: Attack the tile at x and y, as melee, ranged, air, or a ship's coastal raid. It never declares war. A refusal lists the targets.
- priority_target: Hit the support or civilian unit escorted on the tile at x and y.
- rebase: Move an air unit to another base at x and y. A refusal names the nearest tiles that work.
- deploy: The game's deploy command for an air unit, to the tile at x and y.
- airlift: Airlift a land unit to the tile at x and y.
- paradrop: Drop a land unit on the tile at x and y.
- wmd_strike: Launch the device in device, such as WMD_NUCLEAR_DEVICE, at the tile at x and y.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `unitID` | integer | yes | The unit's id, from get_state. |
| `action` | one of 42 values | yes |  |
| `x` | integer | no | The target tile, for the orders that take one. |
| `y` | integer | no |  |
| `with` | integer | no | The other unit's id, for form_corps, form_army, and enter_formation. |
| `promotion` | string | no | For promote. |
| `improvement` | string | no | For improve. |
| `route` | string | no | For build_road, such as ROUTE_MODERN_ROAD. |
| `device` | string | no | For wmd_strike, such as WMD_NUCLEAR_DEVICE. |

## `start_trade_route`

Start a trade route from the city a trader stands in, to a destination from get_choices' tradeRoutes for that trader. A destination is named by its owner and id. The trader then travels the route.

get_trade_routes lists a city's destinations before a trader is there. A refusal names why, such as a trader that already has a route or no free route slot.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `unitID` | integer | yes | The trader's id, from tradeRoutes. |
| `owner` | integer | yes | The destination city's owner. |
| `cityID` | integer | yes | The destination city's id. |

## `set_production`

Set what one of your cities produces, from the type of an option in get_choices' production for that city, such as UNIT_BUILDER. A unit is a standard unit, not a corps or an army.

A district or a wonder also needs its tile, x and y, from get_placement's tiles, unless the city has placed it already. With queue, the item goes to the end of the city's queue instead, and a full queue is refused.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityID` | integer | yes | The city's id, from get_state. |
| `item` | string | yes | The option's type, such as UNIT_BUILDER or DISTRICT_CAMPUS. |
| `x` | integer | no | The tile of a district or a wonder. |
| `y` | integer | no |  |
| `queue` | boolean | no | Add to the end of the queue instead of replacing the current item. |

## `purchase`

Buy a unit or a building in one of your cities, from the type of an option in get_choices' purchases for that city, such as UNIT_BUILDER. yield is the key it is listed under, gold or faith. No tool buys the districts that purchases lists yet, so produce them with set_production.

A refusal gives the game's reasons, such as gold that falls short.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityID` | integer | yes | The city's id, from get_state. |
| `item` | string | yes | The option's type, such as UNIT_BUILDER. |
| `yield` | `"gold"` \| `"faith"` | yes |  |

## `purchase_tile`

Buy a tile for one of your cities with gold, from the tiles in get_choices' purchases.gold for that city.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityID` | integer | yes | The city's id, from get_state. |
| `x` | integer | yes |  |
| `y` | integer | yes |  |

## `city_attack`

Have one of your cities shoot at the tile at x and y in its range. Ok means the game took the order, not that the shot landed.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityID` | integer | yes | The city's id, from get_state. |
| `x` | integer | yes |  |
| `y` | integer | yes |  |

## `silo_strike`

Launch a nuclear device from one of your missile silos at the tile at x and y. get_state's wmdLaunchers lists, for each device, the silos that can launch it now.

It checks the device and your stockpile, the silo, the tile, the range, and the war check, in that order. A refusal gives how many tiles the silo can hit and how far, not the list.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `siloX` | integer | yes | The silo's tile, from get_state's wmdLaunchers. |
| `siloY` | integer | yes |  |
| `x` | integer | yes | The target tile. |
| `y` | integer | yes |  |
| `device` | string | yes | Such as WMD_NUCLEAR_DEVICE or WMD_THERMONUCLEAR_DEVICE. |

## `decide_city`

Decide the fate of a captured or rebelled city, from get_choices' cityFates. The game offers one city at a time.

directive is the type of one of that city's options: KEEP, RAZE, LIBERATE_FOUNDER, or LIBERATE_PREVIOUS_OWNER for a captured city, and KEEP or REJECT for a rebelled one. A refusal lists the city's options.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityID` | integer | yes | The city in cityFates. |
| `directive` | `"LIBERATE_FOUNDER"` \| `"LIBERATE_PREVIOUS_OWNER"` \| `"KEEP"` \| `"RAZE"` \| `"REJECT"` | yes |  |

## `set_research`

Research a tech and the prerequisites it needs, as a click on the tree screen does. The type is from get_choices' techs or from get_tech_tree, such as TECH_MINING, so you can plan several techs ahead.

Without queue, the path replaces the queue. With queue, it goes to the end, and anything already queued is skipped. A refusal names a tech you have already, one the tree doesn't reveal yet, or one with no path.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `type` | string | yes | The tech's type, such as TECH_MINING. |
| `queue` | boolean | no | Add to the end of the queue instead of replacing it. |

## `set_civic`

Research a civic and the prerequisites it needs, as a click on the tree screen does. The type is from get_choices' civics or from get_civic_tree, such as CIVIC_MYSTICISM, so you can plan several civics ahead.

Without queue, the path replaces the queue. With queue, it goes to the end, and anything already queued is skipped. A refusal names a civic you have already, one the tree doesn't reveal yet, or one with no path.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `type` | string | yes | The civic's type, such as CIVIC_MYSTICISM. |
| `queue` | boolean | no | Add to the end of the queue instead of replacing it. |

## `set_policies`

Set the policy in every slot of your government, as the government screen's confirm does. slots lists every slot of get_choices' government by its number, from 0, with a policy type or null for an empty slot. A slot left out is refused, so no slot is emptied by mistake.

A policy is the type of one in get_choices' policies, or of one already in a slot, which can stay or move. You can change them when policies.canChange is true. A refusal names the rule, or the slot and policy that don't fit.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `slots` | (string or null)[] | yes | A policy type, such as POLICY_DISCIPLINE, or null, for each slot from 0. |

## `unlock_policies`

Pay the cost of the unlock in get_choices' policies and governments, as the unlock button does. It lets you change policies and the government on a turn with no civic completed. A refusal says why, such as a cost you can't afford.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |

## `set_government`

Change your government to a type from get_choices' governments, such as GOVERNMENT_AUTOCRACY, as the government screen's confirm does. A government with anarchy turns starts after them.

You can change it when governments.canChange is true. A refusal names the rule, such as a change made this turn already, or a turn with no civic completed, which points at the unlock when governments shows one.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `government` | string | yes | The government's type, such as GOVERNMENT_AUTOCRACY. |

## `choose_dedications`

Make the dedications of the era that began, as the dedication popup's confirm does. Each is the type of one of get_choices' dedications.options, such as COMMEMORATION_SCIENTIFIC.

Give as many as dedications.picks: 1, or 3 in a heroic age. A refusal names the dedications offered.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `dedications` | string[] | yes | The dedications' types, as many as the picks. |

## `found_pantheon`

Found your pantheon with a belief, a type from get_choices' pantheon, such as BELIEF_RELIGIOUS_SETTLEMENTS, as the pantheon chooser's confirm does.

A refusal names the rule, such as a pantheon you have already or a belief another player took.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `belief` | string | yes | The belief's type, such as BELIEF_TITHE. |

## `found_religion`

Found your religion and add its beliefs, as the religion screen's confirm does. First a great prophet uses unit_action's found_religion on its Holy Site, which earns the belief picks. Then this tool picks the religion, its beliefs, and any name.

religion is a type from get_choices' religion.religions, such as RELIGION_BUDDHISM. beliefs are types from religion.beliefs, as many as religion.picks, with a follower belief first. Give name only for a religion whose customName is true.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `religion` | string | yes | The religion's type, such as RELIGION_BUDDHISM. |
| `beliefs` | string[] | yes | The beliefs' types, a follower belief first. |
| `name` | string | no | The religion's name, only when its customName is true. |

## `add_belief`

Add one belief to your founded religion, a type from get_choices' religion.beliefs, which lists beliefs once the religion has a pick left. An apostle's evangelize_belief order earns a pick.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `belief` | string | yes | The belief's type, such as BELIEF_TITHE. |

## `appoint_governor`

Spend a governor title to appoint a governor from get_choices' governors.appoint, such as GOVERNOR_THE_DEFENDER. governors.appoint is there only with a title to spend.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `governor` | string | yes | The governor's type, such as GOVERNOR_THE_DEFENDER. |

## `promote_governor`

Spend a governor title on a promotion for an appointed governor, from get_choices' governors.promote, which lists the promotions each can earn now.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `governor` | string | yes | The governor's type, such as GOVERNOR_THE_DEFENDER. |
| `promotion` | string | yes | The promotion's type, from governors.promote. |

## `assign_governor`

Send an appointed governor to a city from get_choices' governors.assign, by the city's owner and id. The same call places a governor with no city and moves one to another city.

governors.assign lists your cities, then for an Ambassador the city-states you have met, then for a governor that can go abroad the capitals of the players you have met. A city the panel turns off lists the game's reasons as blocked.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `governor` | string | yes | The governor's type, such as GOVERNOR_THE_DEFENDER. |
| `owner` | integer | yes | The city's owner, from governors.assign. |
| `cityID` | integer | yes | The city's id, from governors.assign. |

## `recruit_great_person`

Act on a great person on the Great People screen, a type such as GREAT_PERSON_INDIVIDUAL_ARYABHATA.

- recruit, the default: recruit with your points, a great person from get_choices' greatPeople.
- pass: pass on a great person from greatPeople.
- patronize: recruit with gold or faith in yield, when get_state's greatPeople entry has patronage with can true for that yield.

A refusal gives the screen's Cannot Recruit text, or the cost and your points.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `greatPerson` | string | yes | The great person's type, such as GREAT_PERSON_INDIVIDUAL_ARYABHATA. |
| `action` | `"recruit"` \| `"pass"` \| `"patronize"` | no |  |
| `yield` | `"gold"` \| `"faith"` | no | For patronize. |

## `move_great_work`

Move one of your great works to a slot, as the Great Works screen does. A move into a filled slot swaps the two works.

Take the cityID, building, and slot from a move that get_great_work_moves gives for the work. A refusal names why, such as a work that is locked or a slot that doesn't take its kind.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `workIndex` | integer | yes | The work's index, from get_state's greatWorks. |
| `cityID` | integer | yes | The slot's city id, from get_great_work_moves. |
| `building` | string | yes | The slot's building, such as BUILDING_MUSEUM_ART. |
| `slot` | integer | yes | The slot's index in its building. |

## `choose_artifact`

Choose whose artifact your digging archaeologist uncovers, a player from the options of get_choices' artifacts.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `player` | integer | yes | The player, from the artifact's options. |

## `send_envoys`

Send envoys to a city-state, a player id from get_choices' envoys.cityStates, as the City-States screen does. count is 1 when left out, and at most envoys.tokens.

The envoy blocker stays up until you send every envoy. To keep some for later, end the turn with force.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `cityState` | integer | yes | The city-state's player id. |
| `count` | integer | no | How many envoys, 1 when left out. |

## `respond_to_deal`

Accept or reject the deal another player has put to you, from get_state's proposals, by the player in from. The answer covers the whole deal, and the session then closes. A deal whose valid is false can only be rejected.

Read asks and offers before you accept. Accepting a deal with a joint war declares that war.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `player` | integer | yes | The player who proposed the deal, from in proposals. |
| `accept` | boolean | yes |  |

## `respond_to_session`

Answer a leader screen another player has open with you, other than a deal, from get_state's sessions, such as a request, a promise, or a first meeting. option is the key of one of its options, such as CHOICE_POSITIVE. CHOICE_EXIT is the goodbye and closes the session.

The session may go on with another statement, which the next get_state lists. An open session stops end_turn, so answer each one.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `player` | integer | yes | The player with the session open, from in sessions. |
| `option` | string | yes | An option's key, such as CHOICE_POSITIVE or CHOICE_EXIT. |

## `declare_war`

Declare a surprise war on a major civilization or a city-state you have met. A refusal gives the game's reasons when it doesn't allow the war.

Moves and attacks never declare war on their own, so declare it first.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `player` | integer | yes | The other player's id. |

## `propose_peace`

Propose peace to a major civilization or a city-state you are at war with, then wait up to 5 seconds for the answer. Ok means peace is in place.

A refusal gives the game's reasons when peace isn't allowed yet, such as the turns to wait after a war is declared, or says the war goes on, which is how an AI's no shows. The game may add what a peace needs, such as an occupied city ceded back.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `player` | integer | yes | The other player's id. |

## `spy_mission`

Start a mission in the city a spy stands in, the type of one of its missions in get_choices' spyMissions, such as UNITOPERATION_SPY_SIPHON_FUNDS. A counterspy mission also takes the district to guard, such as DISTRICT_CAMPUS.

Ok means the mission has begun, not that it has finished. A refusal lists the missions the spy can start, or the game's reasons for a disabled one.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `unitID` | integer | yes | The spy's unit id, from spyMissions. |
| `mission` | string | yes | The mission's type, such as UNITOPERATION_SPY_SIPHON_FUNDS. |
| `district` | string | no | For a counterspy mission, the district to guard. |

## `spy_travel`

Send a spy to a city from its destinations in get_choices' spyMissions, named by the city's owner and id. Ok means the spy has set out, not that it has arrived.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `unitID` | integer | yes | The spy's unit id, from spyMissions. |
| `owner` | integer | yes | The destination city's owner. |
| `cityID` | integer | yes | The destination city's id. |

## `choose_escape_route`

Choose how your escaping spy leaves its city, the type of one of its routes in get_choices' spies, such as DISTRICT_HARBOR. The game offers one escaping spy at a time, so the route names no spy.

Ok means the game took the route, not that the spy got away. A route with blocked can't be taken.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `route` | string | yes | The route's type, such as DISTRICT_HARBOR. |

## `vote_in_congress`

Cast every vote of a World Congress session from get_choices' worldCongress, submit them, and end your turn, as the congress screen's accept does. Call it last in the turn, because it ends the turn.

- A resolution from resolutions needs a vote: its type, option A or B, target, the index of one of its targets, and votes.
- A proposal from proposals is voted on by its type and target, with votes, and against true to oppose it. A proposal left out is an abstention.

votes is from 1 to the most the session allows, and voteCosts gives the total Favor for each count. Votes that cost more than your favor are refused.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `votes` | object[] | yes |  |
| `votes[].type` | string | yes | The resolution's or proposal's type. |
| `votes[].option` | `"A"` \| `"B"` | no | For a resolution: A or B. |
| `votes[].target` | integer | yes | For a resolution, a target's index. For a proposal, its target. |
| `votes[].votes` | integer | yes | How many votes. |
| `votes[].against` | boolean | no | For a proposal: true to oppose it. |

## `propose_in_congress`

Call a Special Session for proposals from get_choices' worldCongress.available, each by its type and target, as the congress screen does out of a session. Each costs Favor, and a disabled one is refused.

Give an empty list to only mark the congress as looked at, which clears the blocker to look at the congress.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `proposals` | object[] | yes |  |
| `proposals[].type` | string | yes | The proposal's type. |
| `proposals[].target` | integer | yes | The proposal's target. |

## `end_turn`

End your turn, as the Next Turn button does. Call it when get_state's blockers.list and blockers.units are empty.

Without force, it fails while a blocker is left or a unit needs orders, and names each blocker with the choice that resolves it and the ids of those units. It fails while a diplomacy session is open, even with force, and for a second call in one turn.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `reason` | string | yes | One sentence, in your own voice, on why you take this action. The narrator panel shows it, and the log keeps it. |
| `force` | boolean | no | End the turn anyway, skipping the blockers and the units that need orders. Use it only when a blocker has no tool. |

## `update_plan`

Replace your plan with a new one. Your plan is your current strategy in a few lines: your victory goal, what you are building toward, and the threats you watch. Each turn starts with it, since you remember nothing else between turns.

Change it when your strategy changes, not every turn. Write the whole plan, because it replaces the last one.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `plan` | string | yes | Your whole plan. |

## `add_journal_entry`

Add an entry to your journal for this turn. The journal is your log of what happened: wars, deals, promises, surprises, and lessons. Each turn starts with your newest entries.

Write what a later turn needs to know and can't read from get_state, such as why a rival turned hostile or what you promised. Skip routine moves.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `entry` | string | yes | The entry's text. |

## `record_decision`

Record an important decision you made this turn, with your reason, such as a war, a new city's site, a government, or a pantheon. Skip routine moves.

Next turn starts by listing these decisions with their ids, and asks you for each one's result.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `decision` | string | yes | What you decided, in one sentence. |
| `reason` | string | yes | Why, in one sentence. |

## `record_result`

Record the short-term result of one of last turn's decisions, by the id that the turn message gives it. Say what happened and whether the decision worked, in a sentence or two.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `id` | integer | yes | The decision's id. |
| `result` | string | yes | What happened, and whether the decision worked. |
