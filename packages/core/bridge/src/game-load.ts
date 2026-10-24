// What the bridge does when a game loads. LOAD_READY starts a new log file, so each game's file
// begins at its loading screen. A quit to the main menu doesn't disconnect, so a reconnect can't
// mark a new game. GAME_READY drops the state list, so the next command lists the states again.
// The socket resets right after the click, and the client lists the states again after a
// reconnect anyway, so GAME_READY covers a load that keeps the socket. docs/design/core/bridge.md
// has the design.

import type { CoreEvent } from "./events.js";
import type { Logger } from "./log.js";
import type { TunerClient } from "./tuner/client.js";

// newLogFile gives the path for the new game's log file.
export function onLoadEvent(event: CoreEvent, client: TunerClient, logger: Logger, newLogFile: () => string): void {
	if (event.type === "load_ready") {
		logger.openFile(newLogFile());
	} else if (event.type === "game_ready") {
		client.forgetStates();
	}
}
