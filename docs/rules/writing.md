# Writing rules

How to write the sentences in a doc. [docs.md](docs.md) says where docs go and which sections they have. These rules apply to every doc, package README, and `AGENTS.md`, and to pull request descriptions and commit messages.

The goal is text that a tired engineer understands on the first read.

## Principles

- **Cut every word that does no work.** "In order to" is "to". "It is important to note that" is nothing.
- **Use the short, everyday word.** "Use", not "utilize" or "leverage". "Help", not "facilitate". "Many", not "numerous". "If", not "in the event that".
- **Use the real name.** Write the actual symbol, file, flag, or command, such as `SentientSystems_Resync()`, not a synonym or a description of it.
- **Say what it does, not how it feels.** Name the mechanism or a number: "a failed action returns the game's reason", not "the agent stays informed". If a sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
- **Don't reword what didn't change.** Every rewording makes a reader check whether the meaning changed.
- **When a rule makes a sentence worse, fix the sentence another way or leave it alone.** The rules serve the reader.

## Write each doc in one mode

Each kind of doc has one job. Keep to it, and link out instead of mixing in another kind.

| Doc | Mode | How to write it |
| --- | --- | --- |
| [design/](../design/README.md) | Explanation | Say how a part works and why. Weigh trade-offs and say which way they fall. The `## Decisions` table holds the reasons |
| [findings/](../findings/README.md) | Reference | State facts, limits, and their status, dry and complete, with no hedging. The status line carries the uncertainty |
| A finding's `## Method` | How-to | Commands only. It stays in the finding file, because it answers that file's questions |
| [roadmap/](../roadmap/README.md) step files | How-to | Commands that reach the "Done when". Assume competence, skip teaching, and link background |
| [rules/](README.md), indexes, and READMEs | Reference | Facts and rules only. No persuasion |

A how-to has no explanation beyond one clause and a link. Reference has no instructions or opinions. Opinion belongs only in design docs.

## Address the reader

- Talk to the reader as "you", in the present tense. "We" means the project team. Use "will" only for things that happen later.
- Name the actor: "the bridge parses the line", not "the line is parsed". Use the passive only when the actor is unknown or doesn't matter.
- Write instructions as commands: "Set `EnableTuner 1`." Never "should be done". Write checks as "Check that the log shows `turn 0`", not "The log should show `turn 0`".
- Put the condition before the instruction: "To test, end a turn."
- Put the common case first and the exceptions after it.
- Write one instruction per sentence and one thought per sentence everywhere else. Split instructions longer than about 20 words and other sentences longer than about 25. Keep a long sentence that carries one thought.
- Mix sentence lengths. A short sentence lands a point. A longer one carries a fact with its condition or result.
- Never write "simply", "just", "easy", "quickly", or "please" in a procedure.
- Don't announce plans as if they were features, such as "we will soon support". Put plans in [roadmap/](../roadmap/README.md).
- Make link text name where the link goes, such as the file name or the page title. Never "click here".

## Leave one reading

- Make every "it", "they", "this", "that", and "which" point at one noun. Never point at a whole clause. Repeat the noun when in doubt.
- Keep "only" and "not" next to the word they change. "Only fails on growth" and "fails only on growth" mean different things.
- Break up long noun strings: "the script that checks the import budget", not "the import budget check script".
- Write whole sentences, with their verbs and articles. "Remove backup file" reads two ways. "Remove the backup file" reads one.
- Don't use arrows, symbols, or abbreviations in place of words. "Parse the line, then exit with code 2", not "parse → exit 2".
- Repeat the article for two separate things: "the client and the host".
- Call each thing by one name everywhere. [glossary.md](../glossary.md) lists the names. Add a term there before you use it. Write "phase 0" in lowercase in running text, and capitalize it only at the start of a sentence or a title.
- Pick one word for each action and keep it. Don't write "start" in one place and "initiate" in another.
- Skip idioms, metaphors, and Latin abbreviations such as "e.g.", "i.e.", "etc.", and "via". If a list is partial, say so before it starts.

## Punctuation and formatting

- End sentences with periods. Don't use semicolons, em dashes, or en dashes. Write ranges with "to", as in "steps 7 to 9".
- Use a colon only before a list, an example, code, or a table, or after a field label such as `Status:`. Never use one to join two sentences.
- Text in parentheses is a full grammatical unit, or it becomes its own sentence. Don't form plurals with "(s)", and don't use slashes such as "and/or".
- Use serial commas and straight quotes. Don't use emojis.
- Write dates in ISO 8601 form, such as `2026-10-16`.
- Use sentence-case headings, one `#` heading per file, and no skipped levels. Concept headings are noun phrases ("Turn signal"). Task headings are verb phrases ("Turn on the tuner"). Keep the fixed section names that [docs.md](docs.md) sets, such as `## Decisions`.
- Use numbered lists for sequences and bullets for everything else. Introduce a list with a complete sentence, and keep its items parallel.
- Put code, paths, commands, and settings in code font. Put UI elements and defined terms, such as **Agent**, in bold.
- The only other bold is a lead-in that ends in a period, followed by new detail: "**Tuner client.** It connects to the FireTuner socket." Don't bold words for emphasis, and don't write a bold label with a colon.
- Indent code snippets with tabs, except in YAML, which doesn't allow them.
- Make every count, path, and line number true at the commit that adds it.

## Patterns to cut

These patterns make text read as machine-written. Rewrite them.

- **Inflated words.** Additionally, crucial, delve, enduring, enhance, foster, garner, interplay, intricate, landscape, pivotal, robust, seamless, showcase, tapestry, testament, underscore, vibrant. Use the plain word.
- **Fancy ways to say "is".** "Serves as", "stands as", "boasts", and "features" become "is" or "has".
- **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, primitive, harness, surface, bedrock, scaffolding, modality, paradigm, gold-plating, ratchet, evacuate, endgame, north star, flywheel. Use the concrete word: "base", "add", "way", "more than the job needs", "a limit that only tightens", "move out", "the last phase".
- **Mannered prose.** Aphorisms ("wire it or delete it"), rhetorical fragments, code described as if it were a person ("the plan holds it"), and figurative verbs ("rides along"). Say the literal thing.
- **Empty "-ing" phrases.** "Highlighting...", "ensuring...", "reflecting...". Delete them, or make them a sentence that says what happens.
- **Vague sources.** "Experts believe" or "some users report". Name the source, or delete the claim.
- **Forced shapes.** "Not just X, but Y", ideas forced into groups of three, and "from X to Y" where X and Y aren't on one scale. State the point, and use the natural number of items.
- **Adverbs that prop up a weak verb.** "Runs quickly" becomes the number. "Significantly improves" becomes the measured change.
- **Hedging.** "Could potentially be argued that it might" becomes "may". In findings, the status line carries the uncertainty, so the sentences don't need to.
- **Generic endings.** "The future looks bright." State a plan or a fact, or stop.
- **Chat phrases.** "I hope this helps", "Let me know if", "Great question". Remove them.

## Pull requests and commits

Every rule above applies except the mode table. A PR description is a briefing that a reviewer reads in under a minute. Link logs and long tables instead of pasting them. The title format is in [commits.md](commits.md).

## Sources

These rules come from [Diátaxis](https://diataxis.fr/), the [Google developer documentation style guide](https://developers.google.com/style), ASD-STE100 Simplified Technical English, and *The Global English Style Guide* by John Kohl.
