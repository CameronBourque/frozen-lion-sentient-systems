// Text for the errors the bridge reports, which several files share.

import type { z } from "zod";

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
