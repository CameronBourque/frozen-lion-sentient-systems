// Turns the repo's files into the view every check works from. Nothing here reads
// the disk, so tests can pass in Markdown as strings.

import path from "node:path";

const posix = path.posix;

// Builds the repo view. `files` maps each repo path to its text for Markdown
// files, and to null for other files.
export function buildRepo(files) {
	const repo = { files: new Set(), dirs: new Set([""]), docs: new Map() };

	for (const [filePath, text] of Object.entries(files)) {
		repo.files.add(filePath);

		for (let dir = posix.dirname(filePath); dir !== "."; dir = posix.dirname(dir)) repo.dirs.add(dir);

		if (filePath.endsWith(".md")) repo.docs.set(filePath, parse(filePath, text));
	}

	return repo;
}

export function parse(filePath, source) {
	const lines = source.replace(/\r\n/g, "\n").replace(/\n$/, "").split("\n");
	const text = blankCode(lines);
	const headings = findHeadings(lines, text);

	return { path: filePath, lines, text, headings, anchors: anchorsFor(headings), links: findLinks(text) };
}

export function problem(file, line, rule, message) {
	return { file, line, rule, message };
}

// Returns the lines with fenced code blocks emptied and inline code replaced by
// spaces, so the text rules skip code. Line numbers and columns stay the same.
function blankCode(lines) {
	const text = [];
	let fence = null; // The open fence, such as "```", while inside a code block.

	for (const line of lines) {
		const marker = line.match(/^\s*(`{3,}|~{3,})/)?.[1];

		if (fence) {
			if (isClosingFence(line, fence)) fence = null;

			text.push("");
		} else if (marker) {
			fence = marker;
			text.push("");
		} else {
			text.push(line.replace(/(`+)(.+?)\1/g, (code) => " ".repeat(code.length)));
		}
	}

	return text;
}

// A closing fence uses the same character as the opening one, is at least as
// long, and has nothing after it.
function isClosingFence(line, fence) {
	const marker = line.trim().match(/^(`+|~+)$/)?.[1];

	return marker !== undefined && marker[0] === fence[0] && marker.length >= fence.length;
}

// Headings come from the raw lines, so their inline code stays in the text and
// in the anchor. Lines inside code blocks are skipped.
function findHeadings(lines, text) {
	const headings = [];

	lines.forEach((line, i) => {
		if (text[i] === "") return;

		const match = line.match(/^(#{1,6})\s+(.*?)(?:\s+#+)?\s*$/);

		if (match) headings.push({ level: match[1].length, text: match[2], line: i + 1 });
	});

	return headings;
}

// GitHub adds -1, -2, and so on to repeated anchors in one file.
function anchorsFor(headings) {
	const anchors = new Set();
	const seen = new Map();

	for (const heading of headings) {
		const base = slug(heading.text);
		const count = seen.get(base) ?? 0;

		seen.set(base, count + 1);
		anchors.add(count === 0 ? base : `${base}-${count}`);
	}

	return anchors;
}

// GitHub's heading anchor: the rendered text, lowercased, with punctuation
// removed and spaces turned into hyphens. "Step 2: Turn on" becomes "step-2-turn-on".
export function slug(heading) {
	return heading
		.replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1") // A link keeps only its text.
		.replace(/<[^>]+>/g, "") // HTML tags have no text.
		.toLowerCase()
		.replace(/[^\p{L}\p{M}\p{N}\p{Pc} -]/gu, "")
		.replace(/ /g, "-");
}

const inlineLink = /\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g; // [text](target "optional title")
const referenceLink = /^\s*\[[^\]]+\]:\s*<?([^\s>]+)>?/; // [label]: target

function findLinks(text) {
	const links = [];

	text.forEach((line, i) => {
		for (const match of line.matchAll(inlineLink)) links.push({ target: match[1], line: i + 1 });
		const reference = line.match(referenceLink);

		if (reference) links.push({ target: reference[1], line: i + 1 });
	});

	return links;
}

// Returns the repo path and anchor that a link points to, or null for an
// external link such as https: or mailto:. A folder's path has no trailing slash,
// and the repo root is "".
export function resolveLink(fromPath, target) {
	if (/^[a-z][a-z0-9+.-]*:/i.test(target) || target.startsWith("//")) return null;

	const [linkPath, anchor] = target.split("#");
	let resolved;

	if (linkPath === "") {
		resolved = fromPath; // "#anchor" points into this file.
	} else if (linkPath.startsWith("/")) {
		resolved = posix.normalize(decodeURIComponent(linkPath.slice(1)) || "."); // From the repo root.
	} else {
		resolved = posix.join(posix.dirname(fromPath), decodeURIComponent(linkPath));
	}

	resolved = resolved.replace(/\/$/, "");

	return {
		path: resolved === "." ? "" : resolved,
		anchor: anchor === undefined ? undefined : decodeURIComponent(anchor),
	};
}
