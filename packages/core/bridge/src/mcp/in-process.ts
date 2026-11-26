// Connects a client to the MCP server in the same process, turns the server's
// tools into the model client's tool definitions, and calls a tool.
// docs/design/core/mcp-server.md has the design.

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import type { McpServer } from "@modelcontextprotocol/server";
import type { JSONSchema7 } from "ai";
import packageJson from "../../package.json" with { type: "json" };
import type { ToolDefinition } from "../model/client.js";

export const CLIENT_NAME = "sentient-systems-agent";

// Closing the client closes the server's side too.
export async function connectClient(server: McpServer): Promise<Client> {
	const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
	const client = new Client({ name: CLIENT_NAME, version: packageJson.version });

	await server.connect(serverSide);
	await client.connect(clientSide);

	return client;
}

// The server's input schemas are already JSON Schema, which the SDK types as
// any JSON object. A tool with no description gets an empty one, which the
// model client still takes.
export async function toolDefinitions(client: Client): Promise<ToolDefinition[]> {
	const { tools } = await client.listTools();

	return tools.map(({ name, description, inputSchema }) => ({ name, description: description ?? "", inputSchema: inputSchema as JSONSchema7 }));
}

export interface ToolOutput {
	text: string;
	isError: boolean;
}

// The tools answer in text, and a tool the server doesn't have is an error
// result. A call that can't reach the server throws, and the model reads why.
export async function callTool(client: Client, name: string, args: unknown): Promise<ToolOutput> {
	try {
		const result = await client.callTool({ name, arguments: args as Record<string, unknown> });
		const blocks = result.content as { type: string; text?: string }[];

		return { text: blocks.flatMap((block) => block.text ?? []).join("\n"), isError: result.isError === true };
	} catch (error) {
		return { text: String(error), isError: true };
	}
}
