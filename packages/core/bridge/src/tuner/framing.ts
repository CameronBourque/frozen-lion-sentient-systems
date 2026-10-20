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

// No real reply comes near this. The probe's largest output test prints 1,000,000 characters. A
// bigger length means the header is garbage, and waiting for that many bytes would never end.
export const MAX_PAYLOAD_BYTES = 64 * 1024 * 1024;

// Bytes that can't be a tuner frame. The connection drops the socket and starts over, because
// after a bad frame there's no way to find where the next one begins.
export class FrameError extends Error {
	override name = "FrameError";
}

export function encodeFrame(tag: number, strings: readonly string[]): Buffer {
	// A null inside a string would end it early, and the game would read two strings.
	if (strings.some((text) => text.includes("\0"))) {
		throw new FrameError("A tuner frame string can't contain a null byte");
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
// yet and returns each frame once all of its bytes have arrived. After it throws a FrameError,
// make a new decoder for the new connection.
export class FrameDecoder {
	private pending = Buffer.alloc(0);

	push(chunk: Buffer): Frame[] {
		// Copying on each read is fine at the sizes the game sends, which are a few KB per reply.
		this.pending = Buffer.concat([this.pending, chunk]);

		const frames: Frame[] = [];

		while (this.pending.length >= HEADER_BYTES) {
			const length = this.pending.readUInt32LE(0);

			// Checked as soon as the header arrives, so a bad length fails at once.
			if (length > MAX_PAYLOAD_BYTES) {
				throw new FrameError(`Tuner frame length ${length} is over the ${MAX_PAYLOAD_BYTES}-byte limit`);
			}

			const end = HEADER_BYTES + length;

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
	// Without the null, the last string would be dropped with no sign that anything was lost.
	if (payload.length > 0 && payload.at(-1) !== 0) {
		throw new FrameError("Tuner frame payload doesn't end in a null byte");
	}

	return payload.toString("utf8").split("\0").slice(0, -1);
}
