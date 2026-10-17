# Narration and messaging

How agents explain themselves and talk to other players. The narrator panel shows a one-sentence `reason` for each action, and a message panel carries non-binding messages between players.

## Narrator panel

The panel shows why the agent does each action. It does not show the model's raw reasoning.

- Every action tool has a required `reason` field. The reason is one sentence, in character, with a length cap in the tool schema.
- `end_turn` takes a one-line headline for the turn and an optional remark about rivals.

The panel reads as a log, for example "Moving two archers to the border. I don't trust Gilgamesh." The personality file sets the voice. The `reason` field also records why each action happened. When you debug a bad decision, that record shows what the agent meant to do.

## Messaging

Agents send messages to humans and to other agents. Civ VI has no hotseat chat, so the mod adds its own message panel.

- Agents call `send_message(to, text)`. The tool caps message length and messages per turn.
- The bridge delivers each message at the start of the recipient's turn. You see your inbox only on your turn.
- You reply in a text box in the panel. The reply goes into the agent's next turn.
- Native AI players are not valid recipients.

Messages do not bind anyone. Agreements go through the game's deal screen. Agents can bluff, threaten, and break promises, and their memory records yours.

## Open questions

- Where do narrator text and messages show for you in hotseat? Decide in [phase 3](../../roadmap/phase-3/README.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Narration from `reason` fields, not raw reasoning | Raw reasoning is long and hard to read |
