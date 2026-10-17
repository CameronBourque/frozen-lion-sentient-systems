// Check 4: the writing patterns from docs/rules/writing.md. The rules themselves
// are in writing-rules.mjs. writing.md is skipped, because it quotes the patterns.

import { problem } from "./parse.mjs";
import { buildLineRules } from "./writing-rules.mjs";

export const WRITING_RULES_PATH = "docs/rules/writing.md";

export function checkWriting(repo) {
	const writingRules = repo.docs.get(WRITING_RULES_PATH);

	if (!writingRules) throw new Error(`${WRITING_RULES_PATH} is missing`);

	const rules = buildLineRules(writingRules.lines.join("\n"));
	const lowercase = lowercaseWords(repo);
	const problems = [];

	for (const doc of repo.docs.values()) {
		if (doc.path === WRITING_RULES_PATH) continue;

		doc.text.forEach((line, i) => problems.push(...checkLine(doc.path, i + 1, line, rules)));

		for (const heading of doc.headings) {
			if (isTitleCase(heading.text, lowercase)) {
				problems.push(problem(doc.path, heading.line, "heading-case", `"${heading.text}" is in Title Case. Use sentence case`));
			}
		}
	}

	return problems;
}

function checkLine(file, lineNumber, text, rules) {
	const prose = proseOnly(text);
	const found = [];

	for (const rule of rules) {
		const line = rule.source === "text" ? text : prose;

		if (rule.appliesTo && !rule.appliesTo(line)) continue;

		for (const match of line.matchAll(rule.pattern)) {
			if (rule.allow?.(line, match)) continue;

			const message = typeof rule.message === "function" ? rule.message(match) : rule.message;
			found.push(problem(file, lineNumber, rule.rule, message));
		}
	}
	return found;
}

// Removes what isn't prose, so words in URLs and comments don't trip the rules.
function proseOnly(line) {
	return line
		.replace(/\]\([^)]*\)/g, "]") // Link targets
		.replace(/^\s*\[[^\]]+\]:\s*\S+/, "") // Reference link definitions
		.replace(/<?https?:\/\/[^\s>)]+>?/g, "") // Bare URLs
		.replace(/<!--.*?-->/g, ""); // HTML comments
}

const smallWords = new Set(["a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into", "nor", "of", "on", "or", "over", "per", "the", "to", "up", "via", "vs", "with"]);

// Every word that the docs write in lowercase somewhere. A capitalized word that
// is never written in lowercase, such as "Lua", is a proper noun.
function lowercaseWords(repo) {
	const words = new Set();

	for (const doc of repo.docs.values()) {
		for (const line of doc.text) for (const word of line.match(/\b\p{Ll}[\p{L}'-]*/gu) ?? []) words.add(word);
	}

	return words;
}

// A heading is in Title Case when every ordinary word after the first is
// capitalized. Small words such as "of", proper nouns, acronyms, and names with
// inner capitals such as "FireTuner" don't count.
function isTitleCase(heading, lowercase) {
	const plain = heading
		.replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1") // A link keeps only its text.
		.replace(/`[^`]*`/g, " ")
		.replace(/[*_]+/g, "");

	// After a colon or a period, a new part starts with a capital, as in "Phase 0: Prove the bridge".
	for (const part of plain.split(/[:.?!]\s+/)) {
		const laterWords = part.split(/\s+/).filter(Boolean).slice(1);
		const ordinary = laterWords.filter(
			(word) => /^\p{L}[\p{Ll}'-]*$/u.test(word) && !smallWords.has(word.toLowerCase()) && lowercase.has(word.toLowerCase()),
		);

		if (ordinary.length > 0 && ordinary.every((word) => /^\p{Lu}/u.test(word))) return true;
	}
	
	return false;
}
