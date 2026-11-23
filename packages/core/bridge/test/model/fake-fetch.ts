// A fake fetch that answers each URL from a table of pages, for the model list
// tests.

import type { Fetch } from "../../src/model/list-models.js";

export interface Call {
	url: string;
	headers: Record<string, string>;
}

// Answers each URL with its page, and records the calls.
export function fakeFetch(pages: Record<string, unknown>, calls: Call[] = []): Fetch {
	return (url, init) => {
		calls.push({ url, headers: init.headers });

		return Promise.resolve(url in pages
			? new Response(JSON.stringify(pages[url]))
			: new Response("", { status: 404, statusText: "Not Found" }));
	};
}
