// An ESLint rule that runs the shared comment rules on every comment in a
// JavaScript or TypeScript file. The Lua check runs the same rules.

import path from "node:path";
import { findDocPathProblems, repoDocs } from "./doc-path-rule.mjs";
import { checkHeader } from "./header-rule.mjs";
import { findText } from "./text-rules.mjs";

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
