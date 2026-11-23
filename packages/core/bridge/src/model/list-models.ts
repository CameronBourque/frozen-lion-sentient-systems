// Lists a provider's models through its own API, which shows the models the
// user's key can use. The picker keeps the ones that call tools.
// docs/design/core/model-client.md has the design.

import { z } from "zod";
import type { Provider } from "../config.js";

export interface ModelInfo {
	id: string;
	name: string;
}

export type ListResult =
	| { ok: true; models: ModelInfo[] }
	| { ok: false; error: string };

export type Fetch = (url: string, init: { headers: Record<string, string> }) => Promise<Response>;

// One page of a list, and the URL of the next page, if any.
interface Page {
	models: ModelInfo[];
	next?: string;
}

// How one provider's API lists its models. Each provider file has its own.
export interface Lister {
	url: string;
	headers: (apiKey: string) => Record<string, string>;
	parse: (body: unknown, url: string) => Page;
}

// Replaces one query parameter, for the next page.
export function withParam(url: string, name: string, value: string): string {
	const next = new URL(url);

	next.searchParams.set(name, value);

	return next.toString();
}

// All three providers answer a failure with an error message in this shape.
const ERROR_BODY = z.object({ error: z.object({ message: z.string() }) });

// Names the status, and the provider's reason when its answer has one. A
// reply over HTTP/2 has no status text.
async function describeFailure(provider: Provider, response: Response): Promise<string> {
	let reason: string | undefined;

	try {
		reason = ERROR_BODY.parse(await response.json()).error.message;
	} catch {
		reason = response.statusText === "" ? undefined : response.statusText;
	}

	return `${provider} answered the model list with ${response.status}${reason === undefined ? "" : `: ${reason}`}`;
}

// Fetches every page. A failed request or an unexpected answer fails the
// whole list, with a reason the picker can show.
export async function listModels(provider: Provider, lister: Lister, apiKey: string, fetchPage: Fetch = fetch): Promise<ListResult> {
	const models: ModelInfo[] = [];
	let url: string | undefined = lister.url;

	try {
		while (url !== undefined) {
			const response = await fetchPage(url, { headers: lister.headers(apiKey) });

			if (!response.ok) {
				return { ok: false, error: await describeFailure(provider, response) };
			}

			const page = lister.parse(await response.json(), url);

			models.push(...page.models);
			url = page.next;
		}
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't list the ${provider} models: ${(error as Error).message}` };
	}

	return { ok: true, models };
}
