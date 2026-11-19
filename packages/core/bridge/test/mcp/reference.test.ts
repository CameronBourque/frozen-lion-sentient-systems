// Tests for mcp/reference.ts.

import { expect, test } from "vitest";
import { formatToolReference, type ToolListing } from "../../src/mcp/reference.js";

const FAKE_TOOL: ToolListing = {
	name: "fake_tool",
	description: "Does a fake thing.\n\n- one: The first way.",
	inputSchema: {
		type: "object",
		properties: {
			reason: { type: "string", description: "Why | how." },
			yield: { type: "string", enum: ["gold", "faith"] },
			order: { type: "string", enum: ["a", "b", "c", "d", "e", "f", "g", "h", "i"] },
			slots: { type: "array", items: { type: ["string", "null"] }, description: "One per\nslot." },
			votes: {
				type: "array",
				items: {
					type: "object",
					properties: { target: { type: "integer" }, against: { type: "boolean" } },
					required: ["target"],
				},
			},
			plot: { type: "object", properties: { x: { type: "integer" } }, required: ["x"] },
			anything: {},
		},
		required: ["reason", "yield", "votes"],
	},
};

test("a tool gets its description and a row for each field, with nested fields after their parent", () => {
	expect(formatToolReference([FAKE_TOOL])).toContain(`## \`fake_tool\`

Does a fake thing.

- one: The first way.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| \`reason\` | string | yes | Why \\| how. |
| \`yield\` | \`"gold"\` \\| \`"faith"\` | yes |  |
| \`order\` | one of 9 values | no |  |
| \`slots\` | (string or null)[] | no | One per slot. |
| \`votes\` | object[] | yes |  |
| \`votes[].target\` | integer | yes |  |
| \`votes[].against\` | boolean | no |  |
| \`plot\` | object | no |  |
| \`plot.x\` | integer | yes |  |
| \`anything\` | any | no |  |
`);
});

test("a tool with no fields or description says it takes no fields", () => {
	expect(formatToolReference([{ name: "bare_tool", inputSchema: { type: "object", properties: {} } }]))
		.toMatch(/## `bare_tool`\n\nIt takes no fields\.\n$/);
});

test("the page starts with its title and says how to regenerate it", () => {
	expect(formatToolReference([])).toMatch(/^# Tool reference\n\n.*`npm run tool-reference`/);
});

test("an array without an item schema reads as any[]", () => {
	expect(formatToolReference([{ name: "list_tool", inputSchema: { properties: { list: { type: "array" } } } }]))
		.toContain("| `list` | any[] | no |  |");
});
