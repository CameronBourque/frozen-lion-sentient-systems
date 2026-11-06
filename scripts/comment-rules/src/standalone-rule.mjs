// The stray comment rule, shared by the Lua check and the ESLint rule. A
// comment block sits directly above the code it describes. The rule is in
// docs/rules/code.md.

import { hasOptOut } from "./opt-out.mjs";

// A block shorter than this can stand alone, as a one-line section label.
export const MIN_LINES = 2;

// Joins comments on touching lines into blocks.
function blocksOf(spans) {
	const blocks = [];

	for (const span of spans) {
		const last = blocks.at(-1);

		if (last && span.start <= last.end + 1) {
			last.end = span.end;
			last.texts.push(span.text ?? "");
		} else {
			blocks.push({ start: span.start, end: span.end, texts: [span.text ?? ""] });
		}
	}

	return blocks;
}

// Takes the full-line comments of a file as line spans with their text, in
// order, and the set of line numbers that hold code. Returns a problem for each
// block of MIN_LINES or more with no code on the line after it. The file
// header, the first block when it comes before any code, is left to
// checkHeader. A block that holds "comment-lint-ignore:" and a reason is left
// alone, for section comments.
export function findStandalone(spans, codeLines) {
	const firstCode = Math.min(...codeLines);

	return blocksOf(spans)
		.filter((block, index) => !(index === 0 && block.start < firstCode))
		.filter((block) => block.end - block.start + 1 >= MIN_LINES)
		.filter((block) => !codeLines.has(block.end + 1))
		.filter((block) => !block.texts.some(hasOptOut))
		.map((block) => ({ line: block.start, message: "comment block stands alone; put it directly above the code it describes" }));
}
