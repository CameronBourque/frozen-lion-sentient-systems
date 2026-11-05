// An ESLint rule that runs the shared text rules on every comment in a
// JavaScript or TypeScript file. The Lua check runs the same rules.

import { TEXT_RULES } from "./text-rules.mjs";

const textRules = {
	meta: {
		type: "suggestion",
		schema: [],
		messages: { broken: "{{message}}" },
	},
	create(context) {
		return {
			Program() {
				for (const comment of context.sourceCode.getAllComments()) {
					for (const rule of TEXT_RULES) {
						const message = rule.find(comment.value);

						if (message) context.report({ loc: comment.loc, messageId: "broken", data: { message } });
					}
				}
			},
		};
	},
};

export default { rules: { "text-rules": textRules } };
