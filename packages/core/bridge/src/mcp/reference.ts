// Writes the tool reference, docs/reference/tools.md*, from the tools the MCP
// server lists. scripts/tool-reference.ts lists them and writes the file.

// The parts of a tool's JSON Schema that the reference shows.
export interface FieldSchema {
	type?: string | string[];
	description?: string;
	enum?: unknown[];
	items?: FieldSchema;
	properties?: Record<string, FieldSchema>;
	required?: string[];
}

export interface ToolListing {
	name: string;
	description?: string;
	inputSchema: FieldSchema;
}

interface FieldRow {
	path: string;
	field: FieldSchema;
	required: boolean;
}

// A longer list of values goes in the tool's description instead, as
// unit_action's orders do.
const MAX_INLINE_VALUES = 8;

const HEADER = `# Tool reference

The MCP tools that the bridge serves, with the descriptions and fields that the model reads. \`npm run tool-reference\` generates this file from the tool schemas, so change a tool in its code, not here.`;

// One row per field, with the fields of an object or a list of objects
// after it, so votes[].type follows votes.
function fieldRows(schema: FieldSchema, prefix = ""): FieldRow[] {
	const required = new Set(schema.required);

	return Object.entries(schema.properties ?? {}).flatMap(([name, field]) => {
		const path = `${prefix}${name}`;
		const child = field.items?.properties === undefined ? field : field.items;
		const childPrefix = child === field ? `${path}.` : `${path}[].`;

		return [{ path, field, required: required.has(name) }, ...fieldRows(child, childPrefix)];
	});
}

function formatType(field: FieldSchema): string {
	if (field.enum !== undefined) {
		return field.enum.length > MAX_INLINE_VALUES
			? `one of ${field.enum.length} values`
			: field.enum.map((value) => `\`${JSON.stringify(value)}\``).join(" \\| ");
	}

	if (field.type === "array") {
		const item = field.items === undefined ? "any" : formatType(field.items);

		// Brackets keep (string or null)[] from reading as string or null[].
		return item.includes(" ") ? `(${item})[]` : `${item}[]`;
	}

	return [field.type ?? "any"].flat().join(" or ");
}

// Keeps a table cell on one row.
function formatCell(text: string): string {
	return text.replaceAll("|", "\\|").replaceAll(/\s*\n\s*/g, " ");
}

function formatFields(schema: FieldSchema): string {
	const rows = fieldRows(schema);

	if (rows.length === 0) {
		return "It takes no fields.";
	}

	const lines = rows.map(({ path, field, required }) => (
		`| \`${path}\` | ${formatType(field)} | ${required ? "yes" : "no"} | ${formatCell(field.description ?? "")} |`
	));

	return ["| Field | Type | Required | Description |", "| --- | --- | --- | --- |", ...lines].join("\n");
}

function formatTool(tool: ToolListing): string {
	return [`## \`${tool.name}\``, tool.description ?? "", formatFields(tool.inputSchema)].filter((part) => part !== "").join("\n\n");
}

export function formatToolReference(tools: ToolListing[]): string {
	return `${[HEADER, ...tools.map(formatTool)].join("\n\n")}\n`;
}
