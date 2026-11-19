// The bridge's MCP server. The agent loop connects to it in process, and
// --mcp serves it over HTTP (src/mcp/http.ts). docs/design/core/mcp-server.md
// has the design.

import { McpServer } from "@modelcontextprotocol/server";
import packageJson from "../../package.json" with { type: "json" };
import { registerCityTools } from "./city-tools.js";
import type { ToolContext } from "./context.js";
import { registerDiplomacyTools } from "./diplomacy-tools.js";
import { registerEraTools } from "./era-tools.js";
import { registerEspionageTools } from "./espionage-tools.js";
import { registerGovernmentTools } from "./government-tools.js";
import { registerGovernorTools } from "./governor-tools.js";
import { registerGreatPeopleTools } from "./great-people-tools.js";
import { registerReligionTools } from "./religion-tools.js";
import { registerResearchTools } from "./research-tools.js";
import { registerStateTools } from "./state-tools.js";
import { registerTurnTools } from "./turn-tools.js";
import { registerUnitTools } from "./unit-tools.js";

export const SERVER_NAME = "sentient-systems";

// The HTTP handler builds a server for each request, so a server holds no
// state of its own. The context's player is the one every tool acts for.
export function createServer(context: ToolContext): McpServer {
	const server = new McpServer({ name: SERVER_NAME, version: packageJson.version });

	registerStateTools(server, context);
	registerUnitTools(server, context);
	registerCityTools(server, context);
	registerResearchTools(server, context);
	registerGovernmentTools(server, context);
	registerEraTools(server, context);
	registerReligionTools(server, context);
	registerGovernorTools(server, context);
	registerGreatPeopleTools(server, context);
	registerDiplomacyTools(server, context);
	registerEspionageTools(server, context);
	registerTurnTools(server, context);

	return server;
}
