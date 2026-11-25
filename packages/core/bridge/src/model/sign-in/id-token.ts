// Checks the ID token from a ChatGPT sign-in: OpenAI's signature, and that it
// was made for this sign-in. docs/design/core/subscription-token.md has the
// design.

import crypto from "node:crypto";
import { z } from "zod";

export const JWKS = z.object({ keys: z.array(z.looseObject({ kid: z.string() })) });

export type Jwk = z.infer<typeof JWKS>["keys"][number];

const HEADER = z.object({ alg: z.literal("RS256"), kid: z.string() });

const CLAIMS = z.object({
	iss: z.string(),
	aud: z.union([z.string(), z.array(z.string())]),
	exp: z.number().describe("Seconds since 1970"),
	nonce: z.string(),
});

type Claims = z.infer<typeof CLAIMS>;

export interface Expected {
	issuer: string;
	audience: string;
	nonce: string;
	now: number;
}

export type CheckResult =
	| { ok: true }
	| { ok: false; error: string };

const CLAIM_RULES: { problem: string; holds: (claims: Claims, expected: Expected) => boolean }[] = [
	{ problem: "comes from another issuer", holds: ({ iss }, { issuer }) => iss === issuer },
	{ problem: "is for another client", holds: ({ aud }, { audience }) => [aud].flat().includes(audience) },
	{ problem: "has expired", holds: ({ exp }, { now }) => exp * 1000 > now },
	{ problem: "is for another sign-in", holds: ({ nonce }, expected) => nonce === expected.nonce },
];

function decodePart(part: string): unknown {
	return JSON.parse(Buffer.from(part, "base64url").toString("utf8"));
}

function failed(problem: string): CheckResult {
	return { ok: false, error: `The ChatGPT sign-in's ID token ${problem}` };
}

export function checkIdToken(token: string, keys: Jwk[], expected: Expected): CheckResult {
	const [header, payload, signature, ...rest] = token.split(".");

	if (signature === undefined || rest.length > 0) {
		return failed("isn't a JWT");
	}

	try {
		const { kid } = HEADER.parse(decodePart(header));
		const jwk = keys.find((key) => key.kid === kid);

		if (jwk === undefined) {
			return failed("is signed with a key OpenAI doesn't list");
		}

		// A key in the wrong shape throws here.
		const key = crypto.createPublicKey({ key: jwk, format: "jwk" } as crypto.JsonWebKeyInput);

		if (!crypto.verify("RSA-SHA256", Buffer.from(`${header}.${payload}`), key, Buffer.from(signature, "base64url"))) {
			return failed("has a bad signature");
		}

		const claims = CLAIMS.parse(decodePart(payload));
		const broken = CLAIM_RULES.find(({ holds }) => !holds(claims, expected));

		return broken === undefined ? { ok: true } : failed(broken.problem);
	} catch (error) {
		// JSON, zod, and crypto throw only errors.
		return failed(`can't be read: ${(error as Error).message}`);
	}
}
