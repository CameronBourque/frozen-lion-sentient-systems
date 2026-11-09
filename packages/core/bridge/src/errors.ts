// Text for the errors the bridge reports, which several files share.

import type { z } from "zod";
import { CORE_STATE } from "./connect.js";
import { TunerLuaError, TunerMissingStateError, TunerTimeoutError } from "./tuner/client.js";

// Returns one line for a schema issue: its path, or whole when the issue is
// about the whole value, and the message. One issue lists every unknown field
// in an object, so each field gets a line of its own.
export function describeIssue(issue: z.core.$ZodIssue, whole: string): string[] {
	const path = issue.path.join(".");

	if (issue.code === "unrecognized_keys") {
		return issue.keys.map((key) => `${path === "" ? key : `${path}.${key}`}: Unknown field`);
	}

	return [`${path === "" ? whole : path}: ${issue.message}`];
}

// Returns why a request to the core mod failed, as text. request names the
// request, and retry, when given, follows the text for a missing state or a
// timeout, which a later try may not have.
export function explainFailure(error: unknown, request: string, retry = ""): string {
	if (error instanceof TunerMissingStateError) {
		return `The core mod's state ${CORE_STATE} isn't loaded. Turn on Sentient Systems Core in Additional Content, then load a game${retry}`;
	}

	if (error instanceof TunerTimeoutError) {
		return `The game didn't answer the ${request} in time, maybe because a game is loading${retry}`;
	}

	if (error instanceof TunerLuaError) {
		return `The ${request} failed in the game: ${error.message.split("\n")[0]}`;
	}

	return `The ${request} failed: ${error instanceof Error ? error.message : String(error)}`;
}
