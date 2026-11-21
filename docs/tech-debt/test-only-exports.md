# Test-only exports

Many bridge files export their inner helpers only so tests can call them. Test each file through its public calls instead, and make the helpers private, so a file's insides can change without a change to its tests.

## Now

A scan of `packages/core/bridge/src/` found 97 exports that no other source file or script uses. Some are fine as they are:

- the schemas that `test/contract.test.ts` checks the Lua fixtures with, such as `STATE` and `SEARCH`,
- the exports of `src/agents/prompt.ts`, which the agent loop will call,
- types that only describe a public function's parameters or result.

The rest are helpers behind a public call that already takes its input and output as parameters, so a test can reach them through it:

| File | Public call | Helpers that tests call |
| --- | --- | --- |
| `src/events.ts` | `readLine` | `parseLine`, `stripState`, `TAG` |
| `src/log.ts` | `Logger` | `makeRecord`, `hideHome`, `writesLevel`, `formatConsole` |
| `src/load-config.ts` | `startConfig` | `findConfigPath`, `loadConfig`, `CONFIG_NAME`, `EXAMPLE_CONFIG` |
| `src/model/client.ts` | `callModel` | `modelFailure`, `MAX_RETRIES` |
| `src/model/model-facts.ts` | `cachedFacts` | `fetchFacts`, `MODELS_URL`, `CACHE_MAX_AGE_MS` |
| `src/model/usage.ts` | `logModelCall` | `callCost` |
| `src/tuner/client.ts` | `TunerClient` | `parseStates`, `TunerStateError` |
| `src/tuner/framing.ts` | `encodeFrame`, `FrameDecoder` | `HEADER_BYTES`, `MAX_PAYLOAD_BYTES`, `FrameError` |
| `src/lookup/lookup.ts` | `lookup` and the other readers | `luaString` |
| `src/mcp/http.ts` | `startMcpHttp` | `mcpUrl`, `MCP_HOST`, `MCP_PATH` |
| `src/mcp/action.ts` | `registerAction` | `actionResult`, `TOOK_REQUEST`, `REASON_MAX_LENGTH` |

`src/model/menu.ts` exports `startMenu`, `moveMenu`, `menuLines`, and `keyAction`, because `askMenu` needs a terminal. [code.md](../rules/code.md#conventions) asks for that split, so it stays.

## Proposal

For each file in the table, rewrite its tests to call the public call with fakes for its input and output, such as a `Logger` that writes to a list, then drop `export` from the helpers. One commit per file.

Add a check to `npm run lint`, in `scripts/`, that fails on an export that no other source file or script uses, with an allow list for the kinds of export above that stay.

## Questions

- Does a helper with many cases, such as `parseLine` with every event kind, read better through `readLine` with a fake logger, or does it keep its own tests?
- Does the check read imports with the TypeScript compiler API, or is a search for each name enough?

## Done when

No file in the table exports a helper that only its tests use, the tests reach the same cases through the public calls, and `npm run lint` fails on a new export that only tests use.
