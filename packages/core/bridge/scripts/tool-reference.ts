// Writes docs/reference/tools.md from the tools the MCP server lists. Run it
// with `npm run tool-reference`. It needs no game, because listing the tools
// calls none of them.

import { mkdir, writeFile } from "node:fs/promises";
import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { Logger } from "../src/log.js";
import { formatToolReference, type ToolListing } from "../src/mcp/reference.js";
import { createServer } from "../src/mcp/server.js";
import type { TunerClient } from "../src/tuner/client.js";

const OUTPUT = new URL("../../../../docs/reference/tools.md", import.meta.url);

const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
const client = new Client({ name: "tool-reference", version: "1.0.0" });
const server = createServer({
	client: {} as TunerClient,
	player: () => Promise.resolve({ ok: false, error: "The tool reference reads no game." }),
	logger: new Logger("error"),
});

await server.connect(serverSide);
await client.connect(clientSide);

const { tools } = await client.listTools();

await mkdir(new URL(".", OUTPUT), { recursive: true });
// The SDK types a schema as any JSON. The bridge's own zod schemas made these,
// so they hold only the parts that FieldSchema names, or ones it skips.
await writeFile(OUTPUT, formatToolReference(tools as ToolListing[]));
await client.close();
await server.close();
console.log(`Wrote ${tools.length} tools to docs/reference/tools.md.`);
