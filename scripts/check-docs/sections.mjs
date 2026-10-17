// Check 3: each kind of doc has the sections that docs/rules/docs.md requires.

import { problem } from "./parse.mjs";

const isReadme = (p) => p.endsWith("/README.md");

const kinds = [
	{
		name: "design file",
		matches: (p) => p.startsWith("docs/design/") && !isReadme(p),
		endsWith: { heading: "Decisions", columns: ["Decision", "Reason"] },
	},
	{
		name: "finding",
		matches: (p) => p.startsWith("docs/findings/") && !isReadme(p),
		headings: ["Questions", "What we know now", "Method", "Results"],
		lines: [
			{ label: "a Status: line", pattern: /^Status:/ },
			{ label: "a Date checked: line", pattern: /^Date checked:/ },
		],
	},
	{
		name: "roadmap step",
		matches: (p) => /^docs\/roadmap\/phase-\d+\/\d\d-[^/]+\.md$/.test(p),
		headings: ["Tasks", "Done when", "Record"],
		lines: [{ label: "a Part of [phase N](...) link", pattern: /Part of \[phase \d+\]\(/ }],
	},
];

export function checkSections(repo) {
	const problems = [];
	
	for (const doc of repo.docs.values()) {
		for (const kind of kinds) {
			if (kind.matches(doc.path)) problems.push(...checkKind(doc, kind));
		}
	}

	return problems;
}

function checkKind(doc, kind) {
	const found = [];
	const sections = doc.headings.filter((h) => h.level === 2);
	const names = new Set(sections.map((h) => h.text));

	for (const heading of kind.headings ?? []) {
		if (!names.has(heading)) found.push(problem(doc.path, 1, "sections", `${kind.name} is missing ## ${heading}`));
	}

	for (const { label, pattern } of kind.lines ?? []) {
		if (!doc.text.some((line) => pattern.test(line))) found.push(problem(doc.path, 1, "sections", `${kind.name} is missing ${label}`));
	}

	if (kind.endsWith) found.push(...checkLastSection(doc, sections, kind));

	return found;
}

// The last ## section must be the given heading, and the first table in it must
// have the given columns.
function checkLastSection(doc, sections, kind) {
	const { heading, columns } = kind.endsWith;
	const last = sections.at(-1);

	if (last?.text !== heading) {
		return [problem(doc.path, last?.line ?? 1, "sections", `${kind.name} must end with ## ${heading}`)];
	}

	const header = doc.text.slice(last.line).find((line) => line.trim().startsWith("|"));
	const cells = header ? tableCells(header) : [];
	
	if (cells.join(" | ") !== columns.join(" | ")) {
		return [problem(doc.path, last.line, "sections", `## ${heading} table header must be ${columns.join(" | ")}`)];
	}

	return [];
}

function tableCells(row) {
	return row.trim().replace(/^\||\|$/g, "").split("|").map((cell) => cell.trim());
}
