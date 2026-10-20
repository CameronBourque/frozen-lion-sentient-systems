// Encodes FireTuner frames. Each frame is a 4-byte little-endian payload length, a 4-byte
// little-endian signed tag, then null-terminated UTF-8 strings. Both directions use this format.
// docs/findings/tuner-protocol.md#frame-format has the captured bytes.

// The tag says what kind of message a frame is. A reply carries the tag of its request.
export const Tag = {
	StateList: 0,
	Command: 3,
	App: 4,
	Output: -1,
} as const;

export interface Frame {
	tag: number;
	strings: string[];
}

export const HEADER_BYTES = 8;

export function encodeFrame(tag: number, strings: readonly string[]): Buffer {
	// A null inside a string would end it early, and the game would read two strings.
	if (strings.some((text) => text.includes("\0"))) {
		throw new Error("A tuner frame string can't contain a null byte");
	}

	const payload = Buffer.from(strings.map((text) => `${text}\0`).join(""), "utf8");
	const header = Buffer.alloc(HEADER_BYTES);

	// The length counts payload bytes, not characters, so multibyte text is counted right.
	header.writeUInt32LE(payload.length, 0);
	header.writeInt32LE(tag, 4);

	return Buffer.concat([header, payload]);
}
