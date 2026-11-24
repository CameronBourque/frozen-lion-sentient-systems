// Tests for model/sign-in/id-token.ts: a good ID token passes, and each way a
// token can be wrong names its problem.

import { expect, test } from "vitest";
import { checkIdToken } from "../../../src/model/sign-in/id-token.js";
import { ISSUER, KID, OTHER_KEY, PUBLIC_JWK, signedToken } from "./fake-id-token.js";

const NOW = 1_000_000_000_000;
const EXPECTED = { issuer: ISSUER, audience: "oaiapp_1", nonce: "nonce-1", now: NOW };
const CLAIMS = { iss: ISSUER, aud: "oaiapp_1", exp: NOW / 1000 + 3600, nonce: "nonce-1" };

function problem(text: string) {
	return { ok: false, error: `The ChatGPT sign-in's ID token ${text}` };
}

test("passes a token OpenAI signed for this sign-in", () => {
	expect(checkIdToken(signedToken(CLAIMS), [PUBLIC_JWK], EXPECTED)).toEqual({ ok: true });
	expect(checkIdToken(signedToken({ ...CLAIMS, aud: ["other", "oaiapp_1"] }), [PUBLIC_JWK], EXPECTED)).toEqual({ ok: true });
});

test.each([
	["comes from another issuer", { ...CLAIMS, iss: "https://example.com" }],
	["is for another client", { ...CLAIMS, aud: "oaiapp_2" }],
	["has expired", { ...CLAIMS, exp: NOW / 1000 }],
	["is for another sign-in", { ...CLAIMS, nonce: "nonce-2" }],
])("fails a token that %s", (text, claims) => {
	expect(checkIdToken(signedToken(claims), [PUBLIC_JWK], EXPECTED)).toEqual(problem(text));
});

test("fails a token with a bad signature", () => {
	expect(checkIdToken(signedToken(CLAIMS, { alg: "RS256", kid: KID }, OTHER_KEY), [PUBLIC_JWK], EXPECTED)).toEqual(problem("has a bad signature"));
});

test("fails a token signed with a key OpenAI doesn't list", () => {
	expect(checkIdToken(signedToken(CLAIMS, { alg: "RS256", kid: "key-2" }), [PUBLIC_JWK], EXPECTED)).toEqual(problem("is signed with a key OpenAI doesn't list"));
});

test.each(["a.b", "a.b.c.d"])("fails %s, which isn't a JWT", (token) => {
	expect(checkIdToken(token, [PUBLIC_JWK], EXPECTED)).toEqual(problem("isn't a JWT"));
});

test.each([
	["another algorithm", signedToken(CLAIMS, { alg: "none", kid: KID })],
	["claims in the wrong shape", signedToken({ ...CLAIMS, exp: "soon" })],
	["a header that isn't JSON", `e30x.${signedToken(CLAIMS).split(".").slice(1).join(".")}`],
])("fails a token with %s", (_name, token) => {
	expect(checkIdToken(token, [PUBLIC_JWK], EXPECTED)).toMatchObject({ ok: false, error: expect.stringMatching(/ID token can't be read: /) as string });
});
