// An ESLint rule that runs the shared comment rules on every comment in a
// JavaScript or TypeScript file. The Lua check runs the same rules.

import path from "node:path";
import { findDocPathProblems, repoDocs } from "./doc-path-rule.mjs";
import { checkHeader } from "./header-rule.mjs";
import { findStandalone } from "./standalone-rule.mjs";
import { findText } from "./text-rules.mjs";

// Returns the line numbers that hold part of a token, which is code.
function codeLinesOf(tokens) {
	const lines = new Set();

	for (const token of tokens) {
		for (let line = token.loc.start.line; line <= token.loc.end.line; line++) lines.add(line);
	}

	return lines;
}

const textRules = {
	meta: {
		type: "suggestion",
		schema: [],
		messages: { broken: "{{message}}" },
	},
	create(context) {
		return {
			Program(program) {
				const comments = context.sourceCode.getAllComments().filter((comment) => comment.type !== "Shebang");
				const firstCode = context.sourceCode.getFirstToken(program);

				for (const comment of comments) {
					for (const message of findText(comment.value)) {
						context.report({ loc: comment.loc, messageId: "broken", data: { message } });
					}
				}

				const leading = comments.filter((comment) => !firstCode || comment.range[0] < firstCode.range[0]);
				const header = checkHeader(leading.map((comment) => ({ start: comment.loc.start.line, end: comment.loc.end.line })));

				if (header) context.report({ loc: leading[0].loc, messageId: "broken", data: { message: header.message } });

				const codeLines = codeLinesOf(context.sourceCode.ast.tokens);
				const fullLine = comments.filter((comment) => {
					for (let line = comment.loc.start.line; line <= comment.loc.end.line; line++) if (codeLines.has(line)) return false;

					return true;
				});
				const spans = fullLine.map((comment) => ({ start: comment.loc.start.line, end: comment.loc.end.line, text: comment.value }));

				for (const problem of findStandalone(spans, codeLines)) {
					const comment = fullLine.find((c) => c.loc.start.line === problem.line);

					context.report({ loc: comment.loc, messageId: "broken", data: { message: problem.message } });
				}
			},
		};
	},
};

// Reports a path to a doc that doesn't exist. `docs` says which files exist.
export function docPathsRule(docs) {
	return {
		meta: {
			type: "problem",
			schema: [],
			messages: { broken: "{{message}}" },
		},
		create(context) {
			return {
				Program() {
					for (const comment of context.sourceCode.getAllComments()) {
						for (const message of findDocPathProblems(comment.value, docs)) {
							context.report({ loc: comment.loc, messageId: "broken", data: { message } });
						}
					}
				},
			};
		},
	};
}

const root = path.resolve(import.meta.dirname, "../../..");

export default { rules: { "text-rules": textRules, "doc-paths": docPathsRule(repoDocs(root)) } };
