// Encodes and decodes FireTuner frames. Each frame is a 4-byte little-endian payload length, a 4-byte
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

// Turns a TCP byte stream back into frames. TCP keeps no message boundaries, so one read can
// end partway through a frame or hold several frames. The decoder keeps the bytes it can't use
// yet and returns each frame once all of its bytes have arrived.
export class FrameDecoder {
	private pending = Buffer.alloc(0);

	push(chunk: Buffer): Frame[] {
		// Copying on each read is fine at the sizes the game sends, which are a few KB per reply.
		this.pending = Buffer.concat([this.pending, chunk]);

		const frames: Frame[] = [];

		while (this.pending.length >= HEADER_BYTES) {
			const end = HEADER_BYTES + this.pending.readUInt32LE(0);

			if (this.pending.length < end) {
				break;
			}

			frames.push({
				tag: this.pending.readInt32LE(4),
				strings: splitStrings(this.pending.subarray(HEADER_BYTES, end)),
			});
			this.pending = this.pending.subarray(end);
		}

		return frames;
	}
}

// "O\0hello\0" becomes ["O", "hello"]. The null after the last string leaves an empty piece at
// the end, which isn't a string. Decoding before splitting is safe, because no UTF-8 character
// holds a null byte.
function splitStrings(payload: Buffer): string[] {
	return payload.toString("utf8").split("\0").slice(0, -1);
}
