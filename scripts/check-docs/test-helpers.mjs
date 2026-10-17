// Helpers that the check-docs tests share.

// Joins rows into a file's text, with a final newline.
export const lines = (...rows) => rows.join("\n") + "\n";

// Formats problems the way index.mjs prints them, so a test reads like the output.
export const messages = (problems) => problems.map((p) => `${p.file}:${p.line}: ${p.rule}: ${p.message}`);

// A file's text with the given number of lines.
export const textOfLength = (count) => Array.from({ length: count }, (_, i) => `Line ${i}.`).join("\n");
