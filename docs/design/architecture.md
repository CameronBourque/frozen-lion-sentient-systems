# Architecture

An agent action passes through six hops between the model and the game engine. Only core, which is the core mod and the bridge, talks to the game. The feature mods go through the core API.

## The six hops

This project builds the boxes with a solid border. The dashed boxes already exist.

&#91;embedded content: Architecture and the six hops from agent to game\]

The numbers in the diagram match these hops:

1. The agent loop sends the model a prompt with the state, memory, and personality. The model returns tool calls, each with a `reason`.
2. The agent loop passes each tool call to the MCP server.
3. The MCP server turns the call into a Lua command for the tuner client.
4. The tuner client sends the Lua over the FireTuner socket.
5. The game runs the Lua in the core mod's action API.
6. The action API calls the game's own request function. The engine applies the action if it is legal.

## Turn signal

The turn signal runs the other way. At turn start, the core mod prints a tagged line. The socket carries it to the tuner client, and the tuner client starts the agent loop for that player.

## Core boundary

Core is the only code that talks to the game. The agent players mod and the advisors mod reach the game through the core API and never call FireTuner or game Lua directly. With that boundary, the feature mods stay independent, and moving a feature into core takes a small refactor. The advisors mod will have an advisor module in the bridge next to the agent loop.

A feature moves into core when a second mod needs it. It does not move because a mod might need it later.

## Decisions

| Decision | Reason |
| --- | --- |
| Feature mods reach the game only through core | Moving a feature into core stays a small refactor |
| Move a feature into core when a second mod needs it | No speculative shared code |
| Use FireTuner as the bridge channel | Civ VI Lua has no sockets, and there is no gameplay DLL source |
| No reverse engineering or custom DLL for now | The bridge covers every action a person can take. Save it for a gap the bridge can't fill |
| Event-driven turn tracking from the start | No polling phase to replace later |
