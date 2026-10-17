// The writing rules from docs/rules/writing.md that a pattern can check.
//
// Each rule has a name, an example it catches, a global pattern, and a message,
// which is a string or a function of the match. Optional fields:
// - `source: "text"` checks the line with its URLs. Other rules see the line
//   with URLs and link targets removed.
// - `appliesTo(line)` limits the rule to some lines.
// - `allow(line, match)` lets one match through.

const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const monthName = `(?:${[...months, ...months.map((m) => m.slice(0, 3)), "Sept"].join("|")})\\.?`; // "October", "Oct", or "Oct."
const day = "\\d{1,2}(?:st|nd|rd|th)?"; // "14" or "14th"
const year = "\\d{4}";
const dateMessage = "Use ISO 8601, such as 2026-10-16";

const unicodeArrow = "[\\u2190-\\u21FF\\u27F5-\\u27FF]"; // The arrows blocks, such as → and ⟶
const asciiArrow = "(?<!-)->|=>|<-(?!-)"; // ->, =>, and <-, but not the ends of an HTML comment

export const fixedRules = [
	{ rule: "dash", example: "one — two", pattern: /—/g, message: "em dash" },
	{
		rule: "dash",
		example: "pages 1–2",
		pattern: /–/g,
		// An en dash may join two capitalized words in a name, as in "Indonesia–Khmer".
		allow: (line, match) => /\p{Lu}\p{L}*$/u.test(line.slice(0, match.index)) && /^\p{Lu}/u.test(line.slice(match.index + 1)),
		message: 'en dash. Use "to" for ranges',
	},
	{ rule: "quotes", example: "“quoted”", pattern: /[‘’“”]/g, message: "curly quote. Use straight quotes" },
	{ rule: "arrow", example: "parse → exit", pattern: new RegExp(`${unicodeArrow}|${asciiArrow}`, "g"), message: "arrow. Use words" },
	{ rule: "emoji", example: "Done 🎉", pattern: /[\p{Emoji_Presentation}\u{2600}-\u{27BF}]/gu, message: "emoji" },
	{
		rule: "phase-case",
		example: "We start Phase 0 now.",
		pattern: /\bPhase \d+/g,
		allow: (line, match) => startsSentence(line.slice(0, match.index)),
		message: (match) => `"${match[0]}" mid-sentence. Write "${match[0].toLowerCase()}"`,
	},
	{ rule: "date", example: "Oct 14, 2026", pattern: new RegExp(`\\b${monthName} ${day},? ${year}\\b`, "g"), message: dateMessage },
	{ rule: "date", example: "14 October 2026", pattern: new RegExp(`\\b${day} ${monthName},? ${year}\\b`, "g"), message: dateMessage },
	// The lookbehind skips "October 2026" inside "14 October 2026", which the rule above reports.
	{ rule: "date", example: "October 2026", pattern: new RegExp(`(?<!\\b${day} )\\b${monthName} ${year}\\b`, "g"), message: dateMessage },
	{ rule: "date", example: "10/14/2026", pattern: /\b\d{1,2}\/\d{1,2}\/\d{2,4}\b/g, message: dateMessage },
	{
		rule: "pinned-source",
		example: "https://github.com/owner/repo/blob/main/README.md",
		source: "text",
		pattern: /github\.com\/[^/\s)]+\/[^/\s)]+\/(?:blob|tree)\/([^/\s)#]+)/g,
		allow: (line, match) => isPinned(match[1]),
		message: (match) => `GitHub link uses ${match[1]}. Link a commit or release`,
	},
	{
		rule: "procedure-word",
		example: "1. Simply run it.",
		pattern: /(?<![\w-])(?:simply|easy|quickly|please)\b/gi, // The lookbehind skips "Release-please".
		appliesTo: (line) => /^\s*\d+\.\s/.test(line),
		message: (match) => `"${match[0]}" in a numbered step`,
	},
];

// "Phase 1" may start a sentence, a list item, a table cell, or a heading.
function startsSentence(before) {
	const trimmed = before.replace(/[\s*_[(]+$/, ""); // Skip bold, link brackets, and parentheses that open the sentence.

	return trimmed === "" || /(^#+|^\s*[-*+]|^\s*\d+\.|[.!?:|>])$/.test(trimmed);
}

// A commit ID, or a release tag such as v1.2.0.
function isPinned(ref) {
	return /^[0-9a-f]{7,40}$/.test(ref) || /^v?\d+(\.\d+)*$/.test(ref);
}

// The word rules read their lists from writing.md, so the lists have one home.
export function wordRules(writingText) {
	const inflated = listAfter(writingText, "Inflated words.", "Use the plain word");
	const metaphors = listAfter(writingText, "Abstract metaphor nouns.", "Use the concrete word");

	return [
		{ rule: "inflated-word", example: inflated[0], pattern: wordPattern(inflated), message: (match) => `"${match[0]}". Use the plain word` },
		{ rule: "metaphor-noun", example: metaphors[0], pattern: wordPattern(metaphors), message: (match) => `"${match[0]}". Use the concrete word` },
	];
}

export function buildLineRules(writingText) {
	return [...fixedRules, ...wordRules(writingText)];
}

// Reads the comma-separated list after a bold lead-in in writing.md, such as
// "**Inflated words.** Additionally, crucial, delve. Use the plain word."
function listAfter(text, leadIn, end) {
	const start = text.indexOf(`**${leadIn}**`);
	const stop = text.indexOf(end, start);

	if (start === -1 || stop === -1) throw new Error(`docs/rules/writing.md has no "**${leadIn}** ... ${end}" list`);

	return text
		.slice(start + leadIn.length + 4, stop)
		.split(",")
		.map((word) => word.trim().replace(/\.$/, "").toLowerCase())
		.filter(Boolean);
}

// Matches each word and its common forms: "enhance" also matches "enhances",
// "enhanced", and "enhancing". A space or hyphen in an entry, as in "north star",
// matches either.
function wordPattern(words) {
	const forms = words.map((word) => {
		const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/[\s-]+/g, "[\\s-]+");
		const withoutE = word.endsWith("e") ? `|${escaped.slice(0, -1)}(?:ing|ed)` : "";

		return `${escaped}(?:s|es|d|ed|ing)?${withoutE}`;
	});

	return new RegExp(`\\b(?:${forms.join("|")})\\b`, "gi");
}
