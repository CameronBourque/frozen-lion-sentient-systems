# Map format

How the bridge shows the map to the model. The state holds the map as a JSON list of tiles, and that list is the largest part of the state. This doc lists the candidate formats that cut its size, and the map quiz that picks between them.

## Why

The `tiles` section is 63% of the state on both turns measured in [testing.md](../testing.md#state-size). On a Huge map, it is 154,859 bytes on turn 24 and 178,084 bytes on turn 403. Sending it on every model turn costs more than any other part of the state.

Size is half the problem. Models are weak at spatial reasoning over a list of coordinates. Civ VI uses a hex grid with offset coordinates, so even the distance between two tiles takes a calculation that models often get wrong.

Three parts of this design already take load off the map:

- [Decision helpers](helpers.md) do most of the spatial work, such as picking settle sites and district tiles, so the model needs less of the map.
- The [state diff](standing-orders.md#state-diff) sends only the tiles that changed.
- Code does every hex calculation. Each format gives distances and directions that code computed, and never asks the model to compute them.

## Candidate formats

The map quiz tests each format. A format can also be a mix, such as region summaries for the whole map and full tiles near the agent's cities.

**JSON tiles.** The current format, one object for each revealed tile. It is the baseline for the quiz.

**Character codes.** Each tile is a short code from a legend, such as `Gh+r` for grassland, hill, and river. The codes sit in rows, in the shape of the map, or in a list with coordinates. The legend goes in the system prompt, so the prompt cache holds it after the first call. A code of a few characters carries what a JSON object spells out with a key for each field.

**Region summaries.** Code splits the map into regions, such as the land around each city and each cluster of unclaimed land. Each region becomes one line of counts:

	North of Rome, unclaimed: 12 grassland, 4 hills, 2 iron, 1 wine, river, 6 to 9 tiles from Rome

A summary loses the position of each tile, but many decisions need only the counts. The agent reads the full tiles of one region through a tool when it needs them.

**Packed bits.** Each tile is a set of bit fields from a legend we define, written as hex or base64 text. We expect this format to fail. The model must decode bit fields in its head, it gets that kind of exact work wrong without saying so, and hex and base64 split into tokens unevenly, so the saving over character codes is small. It is in the quiz because a test costs little, and the result settles the question.

**Image.** A rendered picture of the visible map, for models that read images. An image costs a fixed number of tokens whatever the map holds, but models read exact positions from images poorly. The quiz checks how poorly.

## Map quiz

The map quiz is an automatic test of each format. It needs no judgment, because each question has one right answer.

1. Load a set of saves, such as the turn 24 and turn 403 saves that the state sizes use.
2. For each save, code writes questions from the state, with their answers. For example: how many luxuries are within 3 tiles of a named city, which unclaimed tile with iron is nearest to the capital, or which of a city's tiles touch a river.
3. Each format, at each [model tier](model-routing.md#tiers), answers every question.
4. The quiz scores each pair of format and tier on correct answers, tokens, and cost.

The quiz may pick a different format for each tier. A light model may need region summaries, where a strong model reads character codes well.

## Code

Every format is a pure function in the bridge, in TypeScript, over the serialized tiles. The core mod does not change, and the bridge can send a different format to each tier.

## Open questions

- Which questions go in the quiz, and how many saves does it need?
- What score is good enough to replace the JSON tiles?
- Where do region borders go on land that no city has claimed?

## Decisions

| Decision | Reason |
| --- | --- |
| The map format is picked by the map quiz | Each question has one right answer, so the quiz is automatic and repeatable |
| Code does every hex calculation | Models often get hex distances wrong, and code gets them right at no cost |
| The formats run in the bridge, over the serialized tiles | The core mod stays one format, and each tier can get its own |
| Packed bits stay in the quiz, though we expect them to fail | A test costs little, and the result settles the question |
| The legend goes in the system prompt | The prompt cache holds it, so the legend costs full price once |
