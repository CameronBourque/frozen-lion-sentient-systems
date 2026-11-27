# Agent prompt

How the bridge builds an agent's prompt: a system prompt from the parts that stay the same for the whole game, and a turn message from the parts that change each turn. The code is `src/agents/prompt.ts` in the bridge.

## Two calls

The file exports two functions, and everything else in it is private.

- **`systemPrompt(knowledge, profile)`** runs once per agent. It joins `rules/play.md`, the personality file, and the sweat level file from the [knowledge files](../knowledge-files.md#file-layout), in that order. It returns the text and any warnings.
- **`turnMessage({ state, memory, journalEntries, again })`** runs each turn. It joins these parts, in order:
  1. the turn number, and on a [turn started again](turn-loop/README.md#one-turn), a line that says it is still the same turn and asks for `end_turn` again,
  2. the plan from [memory](../memory.md#memory-files),
  3. the newest journal entries, oldest first, up to the config file's `journalEntries`, with a line that says how many it left out,
  4. last turn's [decision records](turn-loop/decision-records.md) that have no result yet, each with its id,
  5. each end-turn blocker with the `get_choices` key that resolves it, and the units that need orders,
  6. the rest of the state as compact JSON. The state part leaves out the turn and the blockers, so each fact appears once.

  An empty plan or journal names the tool that fills it. With no open decision records, the message leaves their part out.

The agent loop passes them to `callModel` as the system prompt and the first message.

Later steps add these parts:

- the concept guides, civ notes, and chosen opening, as more files in the system prompt,
- the wake triggers from [standing orders](../decision-support/standing-orders.md#wake-triggers), in the turn message.

## System prompt

`systemPrompt` takes no state, so the system prompt is the same on every turn, and the provider's prompt cache keeps it between calls.

## One state per turn

The turn message holds the state from the start of the turn, and the bridge sends it once.

Each later model call in the turn sends the same conversation with the new tool calls and their results added at the end. The system prompt and the turn message stay the same, so the provider's prompt cache keeps the state for the whole turn.

The bridge doesn't replace the state or add a new copy after each action. A state that changes in place would end the cache at the state on every call, and a new copy after each action would add a full state per action.

The agent reads the state again with `get_state` only when a decision needs something its actions changed, as the rules of play say.

## Profile

An agent's profile is the names of its personality and sweat level files. The [setup screen](slot-type.md) will set them, and resolves **Random** to a personality when the game starts. Until it has its dropdowns, every agent gets `neutral` and `balanced`.

A name with no file gets a warning and falls back to `neutral` or `balanced`.

## Rules of play

The rules of play name tools, such as `end_turn`. A test checks that each tool name in `rules/play.md` exists on the MCP server, so a renamed tool fails the test.

## Decisions

| Decision | Reason |
| --- | --- |
| Two public calls, one for the system prompt and one for the turn message | They change at different rates, so the loop builds the system prompt once and warns once. The tests go through the two calls, so the parts inside can change freely |
| `systemPrompt` takes no state | A system prompt that changes each turn loses the prompt cache |
| The system prompt is a list of knowledge files | Each later part, such as a concept guide or a civ note, is one more file in the list |
| The rules of play are a knowledge file | Tuning them is a text change with no code change, like a personality |
| A missing personality or sweat level falls back to the default with a warning | A typo or a removed file shouldn't stop a game |
| The state goes into the turn message as the same JSON `get_state` returns | The model reads one format. A more compact format can replace the one part later |
| The state part leaves out the turn and the blockers | Each fact appears once in the turn message |
| A turn started again says so in the turn message | The turn number stays the same, and a model that isn't told takes it for the next turn and counts every later turn one too high |
| Memory goes in the turn message, not the system prompt | The plan and journal change during a game. In the system prompt, each change would end the prompt cache for the rules and the profile |
| The journal part holds the newest entries up to a cap set in the config file | The whole journal grows every turn, and every entry costs tokens on every later turn. Users can trade tokens for more of the agent's past |
| The state goes in once per turn, and the agent reads it again only when it needs to | The provider's prompt cache keeps one unchanged state for the whole turn. A state per action costs a full state each time |
