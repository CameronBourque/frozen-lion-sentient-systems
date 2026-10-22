# Step 7: Minimal core mod

Create the smallest core mod that loads, prints a tagged turn signal, and reports its version. Part of [phase 0](README.md).

## Tasks

In `packages/core/mod/`:

1. **Mod file.** Create `SentientSystemsCore.modinfo` with:
   - a fixed mod GUID, a name, and a `<Version>`. Generate the GUID once and never change it. Put the full version, such as `0.1.0`, in both the `version` attribute and `<Properties><Version>`, as [game-api.md](../../findings/game-api.md#mod-metadata) shows.
   - `<InGameActions>`:
     - `AddGameplayScripts`, pointing to `Scripts/SentientSystemsCore_Gameplay.lua`
     - `ImportFiles`, pointing to `Scripts/SentientSystemsCore_Version.lua`, so each script can load it with `include("SentientSystemsCore_Version")`
     - `AddUserInterfaces` (context `InGame`), pointing to `UI/SentientSystemsCore_UI.lua` and `UI/SentientSystemsCore_UI.xml`. This gives you a UI Lua state of your own. `RequestOperation` needs that state.
   - Check the structure against an official example in the SDK `Examples\` folder, or a DLC `.modinfo` under the game's `DLC\` folder.
2. **Turn signal.** Use the turn event that matches the state the code runs in (see [lua-contexts.md](../../findings/lua-contexts.md#turn-events-differ-by-script-type)). Call `Players[playerID]:IsHuman()`, and print `AGENT_TURN <playerID>` only for human slots. Test the signal in both the gameplay state and the UI state.
3. **Version report.** Add a global function `SentientSystems_GetVersion()` that prints `CORE_VERSION <CORE_VERSION>`.
4. **Tag format.** Pick one prefix for every machine-readable line, such as `[SENTIENTSYSTEMS] AGENT_TURN 0`, so the bridge can tell those lines apart from other game output.
5. **Install for testing.** Link `packages/core/mod/` into the user `Mods\` folder with a directory junction (`mklink /J`), so you don't have to copy the folder after each change. Then enable the mod under **Additional Content**.

## Done when

The mod appears in **Additional Content**, the game loads with the mod on, and FireTuner lists the mod's Lua state or states.

## Record

- Which state fires the turn signal reliably, and whether a UI state sees the `SentientSystemsCore_Version.lua` global, in [lua-contexts.md](../../findings/lua-contexts.md#results), questions 3 to 5.
- The tag format, in [game-api.md](../../findings/game-api.md).
