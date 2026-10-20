// Tests for framing.ts. The expected bytes are the Windows capture in
// docs/findings/tuner-protocol.md#message-examples.

import { describe, expect, test } from "vitest";
import { encodeFrame, FrameDecoder, FrameError, MAX_PAYLOAD_BYTES, Tag } from "../../src/tuner/framing.js";

// Turns a dump such as "05000000 04000000 4150503a00" into bytes.
function hex(dump: string): Buffer {
	return Buffer.from(dump.replaceAll(" ", ""), "hex");
}

// Each captured message, with the tag and strings that make it.
const capturedFrames = [
	{ name: "connect", tag: Tag.App, strings: ["APP:"], bytes: "05000000 04000000 4150503a00" },
	{ name: "state list request", tag: Tag.StateList, strings: ["LSQ:"], bytes: "05000000 00000000 4c53513a00" },
	{
		name: "command in Main State",
		tag: Tag.Command,
		strings: ["CMD:0:print(\"hello\")"],
		bytes: "15000000 03000000 434d443a303a7072696e74282268656c6c6f222900",
	},
	{
		name: "command in InGame",
		tag: Tag.Command,
		strings: ["CMD:119:print(\"hello\")"],
		bytes: "17000000 03000000 434d443a3131393a7072696e74282268656c6c6f222900",
	},
	// Output frames hold two strings, and their tag of -1 is all four header bytes set.
	{ name: "output", tag: Tag.Output, strings: ["O", "hello"], bytes: "08000000 ffffffff 4f0068656c6c6f00" },
	// A command that succeeds ends with one empty string.
	{ name: "command success", tag: Tag.Command, strings: [""], bytes: "01000000 03000000 00" },
];

describe("encodeFrame", () => {
	test.each(capturedFrames)("matches the captured $name frame", ({ tag, strings, bytes }) => {
		expect(encodeFrame(tag, strings)).toEqual(hex(bytes));
	});

	test("counts payload bytes, not characters", () => {
		// "é" is two bytes in UTF-8, so the payload is 3 bytes with its null.
		expect(encodeFrame(Tag.Command, ["é"])).toEqual(hex("03000000 03000000 c3a900"));
	});

	test("writes an empty payload for no strings", () => {
		expect(encodeFrame(Tag.Command, [])).toEqual(hex("00000000 03000000"));
	});

	test("rejects a string with a null byte", () => {
		expect(() => encodeFrame(Tag.Command, ["CMD:0:a\0b"])).toThrow(FrameError);
	});
});

describe("FrameDecoder", () => {
	// All the captured frames back to back, as if they arrived on one connection.
	const stream = Buffer.concat(capturedFrames.map(({ bytes }) => hex(bytes)));
	const expected = capturedFrames.map(({ tag, strings }) => ({ tag, strings }));

	test.each(capturedFrames)("decodes the captured $name frame", ({ tag, strings, bytes }) => {
		expect(new FrameDecoder().push(hex(bytes))).toEqual([{ tag, strings }]);
	});

	test("decodes several frames from one read", () => {
		// The game sent an output frame and its tag 3 reply in one TCP segment.
		expect(new FrameDecoder().push(stream)).toEqual(expected);
	});

	test("decodes frames that arrive one byte at a time", () => {
		// One byte per read splits every header, every payload, and every boundary between frames.
		const decoder = new FrameDecoder();
		const frames = [...stream].flatMap((byte) => decoder.push(Buffer.from([byte])));

		expect(frames).toEqual(expected);
	});

	test("decodes a frame split at each offset", () => {
		// The shape of the connect reply, whose full bytes the findings don't list.
		const strings = ["Civ6", "Sid Meier's Civilization 6", "E:\\Base\\Binaries\\Debug\\"];
		const bytes = encodeFrame(Tag.App, strings);

		for (let offset = 0; offset < bytes.length; offset++) {
			const decoder = new FrameDecoder();

			expect(decoder.push(bytes.subarray(0, offset))).toEqual([]);
			expect(decoder.push(bytes.subarray(offset))).toEqual([{ tag: Tag.App, strings }]);
		}
	});

	test("keeps a multibyte character that is split across reads", () => {
		const decoder = new FrameDecoder();
		const bytes = encodeFrame(Tag.Output, ["O", "é"]);

		// Byte 10 is the first byte of "é", so this read ends inside the character.
		expect(decoder.push(bytes.subarray(0, 11))).toEqual([]);
		expect(decoder.push(bytes.subarray(11))).toEqual([{ tag: Tag.Output, strings: ["O", "é"] }]);
	});

	test("decodes an empty payload as no strings", () => {
		expect(new FrameDecoder().push(hex("00000000 03000000"))).toEqual([{ tag: Tag.Command, strings: [] }]);
	});

	test("rejects a payload that doesn't end in a null byte", () => {
		// "O\0hello" with the last null missing.
		expect(() => new FrameDecoder().push(hex("07000000 ffffffff 4f0068656c6c6f"))).toThrow(FrameError);
	});

	test("waits for a frame at the length limit", () => {
		const header = Buffer.alloc(8);

		header.writeUInt32LE(MAX_PAYLOAD_BYTES, 0);

		expect(new FrameDecoder().push(header)).toEqual([]);
	});

	test("rejects a length over the limit as soon as the header arrives", () => {
		const header = Buffer.alloc(8);

		header.writeUInt32LE(MAX_PAYLOAD_BYTES + 1, 0);

		expect(() => new FrameDecoder().push(header)).toThrow(FrameError);
	});
});
