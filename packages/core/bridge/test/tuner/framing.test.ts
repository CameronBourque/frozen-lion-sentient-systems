// Tests for framing.ts. The expected bytes are the Windows capture in
// docs/findings/tuner-protocol.md#message-examples.

import { describe, expect, test } from "vitest";
import { encodeFrame, Tag } from "../../src/tuner/framing.js";

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
		expect(() => encodeFrame(Tag.Command, ["CMD:0:a\0b"])).toThrow("can't contain a null byte");
	});
});
