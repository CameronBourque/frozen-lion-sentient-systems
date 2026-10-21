// Tests for wrapper.ts.

import { describe, expect, test } from "vitest";
import { parseMarker, wrap } from "../../src/tuner/wrapper.js";

describe("wrap", () => {
	test("puts the markers and the state check around the Lua", () => {
		expect(wrap(7, "InGame", "print(1)").split("\n")).toEqual([
			"(function()",
			"print(\"@@ss:begin:7\")",
			"if ContextPtr and ContextPtr:GetID() ~= \"InGame\" then print(\"@@ss:end:7:state:\" .. ContextPtr:GetID()) return end",
			"local ok, err = pcall(function()",
			"print(1)",
			"end)",
			"print(\"@@ss:end:7:\" .. (ok and \"ok\" or \"error:\" .. tostring(err)))",
			"end)()",
		]);
	});

	test("keeps the Lua on lines of its own, so a trailing comment ends there", () => {
		expect(wrap(1, "InGame", "print(1) -- done").split("\n")[4]).toBe("print(1) -- done");
	});

	test("escapes quotes and backslashes in the state name", () => {
		expect(wrap(1, "A \"B\" \\C", "print(1)")).toContain("~= \"A \\\"B\\\" \\\\C\" then");
	});
});

describe("parseMarker", () => {
	const cases = [
		{ text: "InGame: @@ss:begin:7", marker: { kind: "begin", id: 7 } },
		{ text: "InGame: @@ss:end:7:ok", marker: { kind: "end", id: 7, ending: { kind: "ok" } } },
		{ text: "InGame: @@ss:end:7:error:boom", marker: { kind: "end", id: 7, ending: { kind: "error", message: "boom" } } },
		{ text: "InGame: @@ss:end:7:error:a\nb", marker: { kind: "end", id: 7, ending: { kind: "error", message: "a\nb" } } },
		{ text: "InGame: @@ss:end:7:error:", marker: { kind: "end", id: 7, ending: { kind: "error", message: "" } } },
		{ text: "InGame: @@ss:end:7:state:PlotInfo", marker: { kind: "end", id: 7, ending: { kind: "state", actual: "PlotInfo" } } },
		// Main State prints have no prefix.
		{ text: "@@ss:begin:7", marker: { kind: "begin", id: 7 } },
		{ text: "@@ss:end:7:ok", marker: { kind: "end", id: 7, ending: { kind: "ok" } } },
	];

	test.each(cases)("reads $text", ({ text, marker }) => {
		expect(parseMarker(text)).toEqual(marker);
	});

	const ordinary = [
		"InGame: hello",
		// An ending that wrap() never prints.
		"InGame: @@ss:end:7:maybe",
		"InGame: @@ss:end:7",
		"InGame: @@ss:begin:seven",
		// A marker in the middle of a line was printed by the Lua, not by the wrapper.
		"InGame: said @@ss:begin:7",
	];

	test.each(ordinary)("leaves %s as an ordinary line", (text) => {
		expect(parseMarker(text)).toBeUndefined();
	});
});
