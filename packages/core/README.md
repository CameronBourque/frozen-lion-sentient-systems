# Core

Core is the bridge and the core mod. They share one version and release together. Core is the only code that talks to the game.

| Folder | Contents |
| --- | --- |
| [bridge/](bridge/README.md) | The external TypeScript program |
| [mod/](mod/README.md) | The in-game Lua and `.modinfo` |

Design: [docs/design/core/](../../docs/design/core/README.md).

## Parts of a state section

A state section is one key of the table that `SentientSystems_GetState` returns. Paths are relative to this folder, and `<Name>` is the section's name. A missed part fails a test, except for the `.modinfo` lists, which a test only checks against each other, and the finding.

| Part | Where |
| --- | --- |
| Lua file | `mod/Scripts/State/SentientSystemsCore_State<Name>.lua` |
| Include line | `SentientSystems_Include` in `mod/Scripts/State/SentientSystemsCore_State.lua` |
| Key | The table in the same file |
| Import | `<ImportFiles>` in `mod/SentientSystemsCore.modinfo` |
| File entry | `<Files>` in the same file |
| Fake game feature | `mod/Test/FakeGame/<Name>.lua` |
| Register line | `FakeGame.Register` in `mod/Test/FakeGame.lua` |
| Lua test | `mod/Test/Scripts/State/SentientSystemsCore_State<Name>.test.lua` |
| Schema | `bridge/src/state/<name>.ts` |
| Schema key | The import and the key in `bridge/src/state/state.ts` |
| Key table | The key table in [design/core/mod/state.md](../../docs/design/core/mod/state.md) |
| Finding | The finding for the screen, and its row in the [findings index](../../docs/findings/README.md) |

The contract test checks the schema against the JSON that the Lua test records, so a section needs no TypeScript test.

## Parts of an action

An action is one Lua function that the bridge calls to run a request function of the game's own UI. Paths are relative to this folder. Each action step adds its rows.

| Part | Where |
| --- | --- |
| Result format | `SentientSystems_RunAction` in `mod/Scripts/Actions/SentientSystemsCore_Actions.lua`, and `ACTION_RESULT` in `bridge/src/actions/actions.ts` |
| Lua test | `mod/Test/Scripts/Actions/SentientSystemsCore_Actions.test.lua` |
| Typed function | `bridge/src/actions/<area>.ts`, which calls `sendAction` |
| Test | `bridge/test/actions/<area>.test.ts`, with a fake client |
| Recorded call | The action's name in `RECORDED` in `mod/Test/Game.lua`, in `calls` in `scripts/clean-lua-fixtures/src/index.mjs`, and in `CALLS` in `bridge/test/contract.test.ts`, which checks its JSON against `ACTION_RESULT` |
| Fake game feature | `mod/Test/FakeGame/<Name>.lua`, and its `FakeGame.Register` line in `mod/Test/FakeGame.lua` |
| Player request fake | `env.UI.RequestPlayerOperation` and `env.PlayerOperations` in `mod/Test/FakeGame/PlayerOperations.lua`, which put each request in `env.requests` |
| Research kinds | `SENTIENTSYSTEMS_RESEARCH_KINDS` in `mod/Scripts/SentientSystemsCore_Research.lua`, which the research choices, trees, and actions share |
| Government rules | The change rules, the policy check, and the unlock in `mod/Scripts/SentientSystemsCore_Government.lua`, which the government choices and the policy and government actions share |
| Religion rules | `SentientSystems_IsBeliefTaken` in `mod/Scripts/SentientSystemsCore_Religion.lua`, which the religion choices and actions share |
| Great people rules | `SENTIENTSYSTEMS_PATRONAGE` and `SentientSystems_GetPatronage` in `mod/Scripts/SentientSystemsCore_GreatPeople.lua`, which the great people state and actions share |
| Policy request fake | `RequestPolicyChanges` and `RequestChangeGovernment` on the culture in `mod/Test/FakeGame/Governments.lua`, which put each change in `env.requests` |

## Parts of a choice

A choice is one key of the table that `SentientSystems_GetChoices` returns. It has the same parts as a state section, in other folders.

| Part | Where |
| --- | --- |
| Lua file | `mod/Scripts/Choices/SentientSystemsCore_Choices<Name>.lua` |
| Include line | `SentientSystems_Include` in `mod/Scripts/Choices/SentientSystemsCore_Choices.lua` |
| Key | The table in the same file |
| Import, file entry | The `<ImportFiles>` and `<Files>` lists in `mod/SentientSystemsCore.modinfo` |
| Fake game feature | `mod/Test/FakeGame/<Name>.lua`, and its `FakeGame.Register` line in `mod/Test/FakeGame.lua` |
| Lua test | `mod/Test/Scripts/Choices/SentientSystemsCore_Choices<Name>.test.lua` |
| Schema | `bridge/src/choices/<name>.ts` |
| Schema key | The import and the key in `bridge/src/choices/choices.ts` |
| Key table | The key table in [design/core/mod/choices.md](../../docs/design/core/mod/choices.md) |
| Finding | The finding for the screen, and its row in the [findings index](../../docs/findings/README.md) |
