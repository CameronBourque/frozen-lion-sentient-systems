// What the bridge does when a game loads: a new log file, and a fresh state
// list. docs/design/core/bridge.md has the design.

import type { CoreEvent } from "./events.js";
import type { Logger } from "./log.js";
import type { TunerClient } from "./tuner/client.js";

// newLogFile gives the path for the new game's log file.
export function onLoadEvent(event: CoreEvent, client: TunerClient, logger: Logger, newLogFile: () => string): void {
	if (event.type === "load_ready") {
		// A quit to the main menu doesn't disconnect, so a reconnect can't
		// mark a new game.
		logger.openFile(newLogFile());
	} else if (event.type === "game_ready") {
		// A load that keeps the socket leaves the old state list.
		client.forgetStates();
	}
}
