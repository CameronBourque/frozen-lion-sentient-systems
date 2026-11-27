# Decision records

How the agent records its important decisions and their results during testing. Part of the [turn loop](README.md).

During testing, the agent records each important decision with its reason. It adds the short-term result on the next turn and the long-term result at its next deep strategic review.

The records are noisy, and that is acceptable. You review them over time and turn useful patterns into [knowledge files](../../knowledge-files.md).

- **`record_decision`** appends `{ schemaVersion, id, turn, decision, reason }` to the agent's `decisions.jsonl`, in its [memory folder](../../memory.md#files-on-disk). `id` counts from 1, and the tool returns it. The decision and the reason are capped at 300 characters each.
- **Next turn.** The turn message lists the records from the agent's last turn before this one that have no `result` yet, each with its id, and asks for each short-term result. When there are none, the [prompt](../prompt.md#two-calls) leaves the part out.
- **`record_result`** sets `result` on the record with the id, and rewrites the file. The file holds a few lines per turn, so the rewrite costs little, and each record keeps its result on its own line.

The long-term result at a deep strategic review comes in a later phase.

## Decisions

| Decision | Reason |
| --- | --- |
| Record decisions and their results during testing | Noisy records still show which patterns belong in knowledge files |
| The model names a record by an id that the bridge gives it | The turn and the text can repeat, and a number costs the fewest tokens |
