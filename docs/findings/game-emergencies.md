# Game emergencies

Status: open. The `emergencies` key of `SentientSystems_GetChoices`, the emergency the player has to look at, matches the popup of an ongoing Betrayal Emergency in a running game with Gathering Storm. It isn't confirmed for the blocker's own case, with **Join** and **Reject**: the emergency started through a World Congress Special Session and showed no blocker. The choice reads only while `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION` is up, so it was checked with its gate bypassed.

The calls the emergency choice uses, as the emergency popup shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. When does `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION` come up, with **Join** and **Reject**? A Betrayal Emergency that passed in a Special Session began at once, with `HasBegun` true and only the popup's **OK**, and no blocker. Three attempts with a city-state captured or razed by another civilization started nothing.
2. Does a player who is the target see the same blocker and popup as a member? The popup has an **OK** button for the target's case in the files, with no **Join** or **Reject**.

## What we know now

### Emergency popup

`DLC/Expansion2/UI/Additions/WorldCrisisPopup.lua` draws the emergency popup, with `WorldCrisisSupport.lua` building its data, as Expansion1's copies do. `NotificationPanel_Expansion1.lua` opens it from the `EMERGENCY_NEEDS_ATTENTION` notification, which is the `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION` blocker, through `OnConsiderEmergency`. Confirmed in files.

- **Which emergency.** `Game.GetEmergencyManager():GetNextBlockingEmergency(playerID)` returns a table with `eTarget`, the target's player ID, and `eEmergencyType`, an index in `GameInfo.EmergencyAlliances`. `GetEmergencyInfoTable(playerID)` lists the player's emergencies, and `OnEmergencyAvailable`, lines 31 to 61, finds the one with that type and target. Confirmed in files. The manager is in the UI state only: GameCore has no emergency manager, so the tuner can't start or change one.
- **Entry.** Each entry has `EmergencyType`, `TargetID`, `TargetCityName`, `NameText`, a text key, `ShortDescriptionText`, `GoalDescription`, `TurnsLeft`, `HasBegun`, `bSuccess`, `CompletedText`, `MemberIDs`, `ScoresTables`, `MemberTiers`, `GoalsTable` and `TargetGoalsTable`, each a list of `Name` and `Completed`, `ScoreSourcesTable`, `BuffsText`, `ExtraBuffs`, `MemberRewardsTextFirst`, `Top`, `Bottom`, and `Extra`, `TargetRewardsText`, and `ExtraRewards`. Confirmed in files.
- **Buttons.** `ShowEmergency`, lines 70 to 165, shows **Join** and **Reject** when the emergency hasn't begun, `HasBegun` false, and **OK** otherwise. **Join** sends `PlayerOperations.ACCEPT_EMERGENCY` and **Reject** sends `REJECT_EMERGENCY`, each with `PARAM_OTHER_PLAYER` set to the target and `PARAM_EMERGENCY_TYPE` to the type's index. **OK** also sends `ACCEPT_EMERGENCY`, to mark it seen. Confirmed in files.
- **Text.** `ProcessEmergency_WorldCrisisPopup`, in `WorldCrisisSupport.lua`, lists the goals from `TargetGoalsTable` for the target and `GoalsTable` for anyone else, how to score for anyone but the target while turns are left, the buffs and extra buffs while turns are left, and the rewards: the members' first, top, bottom, and extra tiers, the extra rewards, and the target's, for a hostile emergency, `GameInfo.Emergencies_XP2[type].Hostile`. Confirmed in files.
- **Types.** `GameInfo.EmergencyAlliances` has Military, Settled City, Capture City-State, Religious, Nuclear, and Backstab, with Gathering Storm's World Congress ones. A military, city-state, religious, nuclear, or backstab emergency starts when a civilization captures an original capital or a city-state, converts a city, uses a nuke, or declares war. A member needs to meet its requirement set, such as envoys at the city-state. Confirmed in files.

## Method

1. Read the popup's files as above.
2. To try starting an emergency, from `GameCore_Tuner`, declare war with `Players[1]:GetDiplomacy():DeclareWarOn(35, WarTypes.FORMAL_WAR, true)`, damage the city's center with `SetDamage(DefenseTypes.DISTRICT_GARRISON, 199)`, give the player uranium with `GetResources():ChangeResourceAmount`, and spawn units with `UnitManager.InitUnit(1, "UNIT_GIANT_DEATH_ROBOT", x, y)`, then end turns. `Game_Emergencies.csv` in the game's logs lists each emergency that starts.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| Zulu captured Hong Kong, a city-state the player had 3 envoys at, in the Classical Era | No emergency. `GetEmergencyInfoTable` was empty for every player and `Game_Emergencies.csv` held only its header |
| The same after the first World Congress, which met on turn 401, with Zulu capturing Hong Kong | No emergency, the same results |
| Zulu razed Hunza, with 1 envoy of the player's at it | No emergency, the same results |
| `GetEmergencies()` of the World Congress | 0 |
| Vietnam, allied to the player at level 2, declared war on the player, after the World Congress had met | No emergency and no blocker on the next turn. The notification list had `NOTIFICATION_WORLD_CONGRESS_EMERGENCY_CAN_BE_CALLED`, "New Discussion Available for Proposal", "Due to recent world events, you now have new concerns to bring to the World Congress' attention in a Special Session.". `GetProposals()` and the table were empty, and the player had 142 Diplomatic Favor against `FAVOR_COST_FOR_EMERGENCY` of 30 |
| An alliance with Zulu from `SetHasAllied`, in `GameCore_Tuner` | The UI read the alliance type 0, level 1, and 960 turns to the next level, so `GameCore_Tuner` can't set an alliance's level, which a betrayal emergency needs |
| The Available Proposals tab of the World Congress, with no session yet, after the war | `Game.GetWorldCongress():GetEmergencies(playerID)`, with the player's ID, returned `Proposals`, five categories each with `FavorCost` 30 and `ProposalsOfType`, and a `Stage`. Two held one proposal: `WC_EMERGENCY_BACKSTAB`, Betrayal Emergency, with `Target` 10, the betrayer, `EmergencyType`, `Name`, `Description`, `Disabled` false, and `ProposalBlockerType` -1, and `WC_EMERGENCY_REQUEST_AID`, Aid Request, with `Target` 0. `GetProposals(playerID)` had five empty categories. Without the player's ID both returned nothing. No blocker was up |
| The Special Session on the turn after submitting the Betrayal Emergency, with the vote blocker up | `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION`, `IsInSession` true. `GetProposals(playerID)` held the proposal on the floor, with `Name`, `Description`, `Sender` 0, `Target` 10, `TypeName` `WC_EMERGENCY_BACKSTAB`, `EmergencyType`, `VotingRestriction`, and empty `FavoredPlayerIDs` and `DisfavoredPlayerIDs`. `GetEmergencies(playerID)` held only a `Stage`, `GetResolutions()` was empty, and `GetVotesandFavorCost(playerID)` was a cost by vote count, 0 to 8, with `MaxVotes` 8. `GetEmergencyInfoTable` was still empty |
| The Betrayal Emergency after it passed in the Special Session, turn 56 | `Game_Emergencies.csv` logged `56, EMERGENCY_BACKSTAB, STARTED, N/A, 10`. The popup read "Ongoing Competition", "Target: Bà Triệu", "Target City: Thăng Long", 39 turns remaining, the goal "Capture Thăng Long before the end of the Emergency.", how to score, the buffs, the 5 members, the rewards, and **OK**. No blocker was up. The entry in `GetEmergencyInfoTable(0)` had `EmergencyType` 5, `EMERGENCY_BACKSTAB`, `TargetID` 10, `TargetCityName` `LOC_CITY_HA_NOI`, a text key, `TurnsLeft` 39, `HasBegun` true, `MemberIDs` 0, 1, 3, 4, and 7, plus the fields listed above and `DescriptionText`, `FlavorText`, `ShortGoalDescription`, `TentativeDescription`, and `TargetShortGoalDescription`. `#` of the table read 0, so it needs `ipairs`. The choice's code, with its gate bypassed, built `type`, `name`, `description`, `goal`, `goals`, `hostile`, `members`, `options` `acknowledge`, `rewards`, `scoring`, `target`, `targetCity`, `turnsLeft`, and `buffs`, the same texts as the popup |

Date checked: game files on 2026-10-28. Running game on Windows on 2026-10-28.
