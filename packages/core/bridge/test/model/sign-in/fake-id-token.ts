// A key pair that stands in for OpenAI's, and ID tokens signed with it, for the
// sign-in tests.

import crypto from "node:crypto";
import type { Jwk } from "../../../src/model/sign-in/id-token.js";

export const ISSUER = "https://auth.openai.com";
export const KID = "key-1";

const { privateKey, publicKey } = crypto.generateKeyPairSync("rsa", { modulusLength: 2048 });

export const OTHER_KEY = crypto.generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey;

export const PUBLIC_JWK: Jwk = { ...publicKey.export({ format: "jwk" }), kid: KID, alg: "RS256", use: "sig" };

function part(value: unknown): string {
	return Buffer.from(JSON.stringify(value)).toString("base64url");
}

export function signedToken(claims: Record<string, unknown>, header: Record<string, unknown> = { alg: "RS256", kid: KID }, key = privateKey): string {
	const unsigned = `${part(header)}.${part(claims)}`;

	return `${unsigned}.${crypto.sign("RSA-SHA256", Buffer.from(unsigned), key).toString("base64url")}`;
}
