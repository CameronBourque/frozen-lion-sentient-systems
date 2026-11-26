// Writes docs/reference/tools.md from the tools the MCP server lists. Run it
// with `npm run tool-reference`. It needs no game, because listing the tools
// calls none of them.

import { mkdir, writeFile } from "node:fs/promises";
import { Logger } from "../src/log.js";
import { connectClient } from "../src/mcp/in-process.js";
import { formatToolReference, type ToolListing } from "../src/mcp/reference.js";
import { createServer } from "../src/mcp/server.js";
import type { TunerClient } from "../src/tuner/client.js";

const OUTPUT = new URL("../../../../docs/reference/tools.md", import.meta.url);

const client = await connectClient(createServer({
	client: {} as TunerClient,
	player: () => Promise.resolve({ ok: false, error: "The tool reference reads no game." }),
	memory: () => "",
	logger: new Logger("error"),
}));

const { tools } = await client.listTools();

await mkdir(new URL(".", OUTPUT), { recursive: true });
// The SDK types a schema as any JSON. The bridge's own zod schemas made these,
// so they hold only the parts that FieldSchema names, or ones it skips.
await writeFile(OUTPUT, formatToolReference(tools as ToolListing[]));
// Closes the server's side too.
await client.close();
console.log(`Wrote ${tools.length} tools to docs/reference/tools.md.`);
