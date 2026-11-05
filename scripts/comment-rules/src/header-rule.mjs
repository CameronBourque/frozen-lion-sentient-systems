// The file header rule, shared by the Lua check and the ESLint rule. The rule
// is in docs/rules/code.md.

export const HEADER_LIMIT = 3;

// Takes the line spans of the comments before the first code. The header ends
// at the first blank line. Returns a message when it is over HEADER_LIMIT.
export function checkHeader(spans) {
	if (spans.length === 0) return;

	let end = spans[0].end;

	for (const span of spans.slice(1)) {
		if (span.start > end + 1) break;
		end = span.end;
	}

	const lines = end - spans[0].start + 1;

	if (lines > HEADER_LIMIT) return { line: spans[0].start, message: `file header is ${lines} lines, over ${HEADER_LIMIT}` };
}
