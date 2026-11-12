# Phase 3: Personalities and play quality

This phase makes agents distinct and better. It adds personalities, all sweat levels, civ notes, fuller memory, deep reviews, and the narrator and messaging panels.

**Gate.** In playtests, agents with different sweat levels and personalities play visibly different games. Compare the victory type pursued, wars declared, and districts built.

## Scope

- Personality files and concept guides
- Descriptions for all three sweat levels
- Civ notes for Gathering Storm civs, generation and cache for other civs, and the `overrides/` folder
- Relationships memory and journal compaction
- Deep strategic reviews with a stronger model
- Fill `models.yaml` from testing
- The decision support parts that the smoke test and MVP gate records point to, and the scenario tests that measure them. See [decision-support/](../../design/decision-support/README.md) and [testing.md](../../design/testing.md#scenario-tests)
- A tool that puts each policy in a slot of the right type, so the agent can call `setPolicies` without matching every slot itself
- Citizen focus and worked tiles in the state, with an action that changes them
- Each city's next border expansion in the state
- Trade routes in the state, and an action that sends a trader
- Gossip, spies, and climate and disasters in the state
- Diplomacy actions beyond answering a proposed deal, declaring war, and proposing peace, such as proposing other deals and sending gifts
- Messaging panel and `send_message`
- Narrator panel in the game UI
- Run the test matrix
- An action that joins or rejects an emergency, for `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION`, tested with Rise and Fall alone once the test matrix adds it. See [choices/emergencies.md](../../findings/choices/emergencies.md#questions)

Design: [knowledge-files.md](../../design/knowledge-files.md), [agents/sweat-level.md](../../design/agents/sweat-level.md), [agents/narration-and-messaging.md](../../design/agents/narration-and-messaging.md) (includes an open question for this phase), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md#test-matrix).

## Steps

Not broken down yet. When it is, the scope items become steps, and we remove this list.
