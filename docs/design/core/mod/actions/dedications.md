# Dedication action

How the core mod runs the action that makes an era's dedications, as the dedication popup does. Part of the [action API](README.md).

## Choose dedications

`SentientSystems_ChooseDedications(playerID, dedications)` in `Scripts/Actions/SentientSystemsCore_ActionsDedications.lua` makes the dedications for the era that began.

Each is the `type` of one of the `options` of the `dedications` choice, and there are as many as its `picks`: 1, or 3 in a heroic age.

The popup's **Confirm** sends one `COMMEMORATE` request for each pick, with the row's index, so the action does too. See [dedications.md](../../../../findings/actions/dedications.md).

Its reasons, in order, name no dedication waiting, dedications that aren't a list, a dedication that isn't offered, with those that are, one chosen twice, and a number of dedications other than the picks.

On the bridge, `chooseDedications` in `src/actions/dedications.ts` sends the call.

## Shared rules

The choice and the action both read the waiting dedication, so the rules are in `Scripts/SentientSystemsCore_Eras.lua`. `SentientSystems_GetPendingDedication` returns the picks, the age, and the offered rows while the blocker is up, and nil otherwise.

## Decisions

| Decision | Reason |
| --- | --- |
| One call makes every dedication of the era | The popup sends them together on **Confirm**, and only once the player has picked the full number |
| A dedication is named by its type, not its index | The agent copies the type from the choice, and the action finds the index the request needs |
