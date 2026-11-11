# Great People screen actions

How the core mod runs the actions on the Great People screen: recruit, pass, and patronize. Activating a great person unit is in [unit-jobs.md](unit-jobs.md). Part of the [action API](README.md).

## Recruit and pass

`SentientSystems_RecruitGreatPerson(playerID, greatPerson)` and `SentientSystems_PassGreatPerson(playerID, greatPerson)` in `Scripts/Actions/SentientSystemsCore_ActionsGreatPeople.lua` send the screen's **Recruit** and **Pass** requests.

The great person is a `type` from the `greatPeople` choice, such as `GREAT_PERSON_INDIVIDUAL_ARYABHATA`.

Both are one-line wrappers around one action, `ClaimGreatPerson`, which reads the capability, the game's check, and the request from its `CLAIMS` table.

The game takes a request the screen wouldn't offer, so the action checks first. See [great-people-screen.md](../../../../findings/actions/great-people-screen.md).

Its reasons, in order, name a type that is no great person, one who isn't on offer, and a game that turns the button off. Then they give the screen's **Cannot Recruit** text, such as after a pass, or the cost and the player's points.

## Patronize

`SentientSystems_PatronizeGreatPerson(playerID, greatPerson, yield)` in the same file recruits the great person with `gold` or `faith`, as the screen's patronage buttons do. The yield names match the `patronage` keys of the great people state.

`SentientSystems_GetPatronage` in `Scripts/SentientSystemsCore_GreatPeople.lua` builds the state's `patronage`, and the action reads its costs from it. So the action patronizes exactly when the state shows the yield's `can` as `true`.

Its reasons, in order, name a type that is no great person, one who isn't on offer, and a yield that isn't gold or faith. Then they name a great person the player has the points for, and the screen's **Cannot Recruit** text or a yield with no patronage.

Last, they name a World Congress in session, and a cost the player can't afford.

On the bridge, `src/actions/great-people.ts` has `recruitGreatPerson`, `passGreatPerson`, and `patronizeGreatPerson`, which share one helper, `sendGreatPerson`.

## Decisions

| Decision | Reason |
| --- | --- |
| The great person task covers recruit, pass, and patronize | The state shows every button the screen has, so the agent can act on each one. Patronage is the way to a great person without the points, such as a Great Prophet for faith |
| Recruit and pass share one table and one action | The screen's two buttons differ only in the check and the request, as the research kinds do |
| A failure gives the screen's **Cannot Recruit** text before the points | The text covers cases the points don't explain, such as a pass this turn or no coastal city |
| Patronage reads its checks from the state's `SentientSystems_GetPatronage` | The state and the action can't disagree on when patronage is open |
