// Tests for documents.mjs: reading the registry output and expanding its variables.

import path from "node:path";
import { describe, expect, test } from "vitest";
import { expandVariables, findDocuments, parseRegQuery } from "../src/documents.mjs";

// `reg query` output for a Documents folder that OneDrive moved.
const oneDriveOutput = [
	"",
	"HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders",
	"    Personal    REG_EXPAND_SZ    %USERPROFILE%\\OneDrive\\Documents",
	"",
].join("\r\n");

describe("parseRegQuery", () => {
	test("reads a REG_EXPAND_SZ value", () => {
		expect(parseRegQuery(oneDriveOutput)).toBe("%USERPROFILE%\\OneDrive\\Documents");
	});

	test("reads a REG_SZ value with spaces", () => {
		expect(parseRegQuery("    Personal    REG_SZ    D:\\My Docs\r\n")).toBe("D:\\My Docs");
	});

	test("returns null without a Personal row", () => {
		expect(parseRegQuery("    Desktop    REG_EXPAND_SZ    %USERPROFILE%\\Desktop\r\n")).toBeNull();
	});
});

describe("expandVariables", () => {
	test("replaces a variable whatever its case", () => {
		expect(expandVariables("%userprofile%\\Documents", { USERPROFILE: "C:\\Users\\a" })).toBe("C:\\Users\\a\\Documents");
	});

	test("leaves an unknown variable as it is", () => {
		expect(expandVariables("%NOPE%\\Documents", {})).toBe("%NOPE%\\Documents");
	});
});

describe("findDocuments", () => {
	const env = { USERPROFILE: "C:\\Users\\a" };
	const homedir = "/home/a";
	const fallback = path.join(homedir, "Documents");

	test("uses the registry value with its variables expanded", () => {
		expect(findDocuments({ readRegistry: () => oneDriveOutput, env, homedir })).toEqual({ documents: "C:\\Users\\a\\OneDrive\\Documents", warnings: [] });
	});

	test("warns and falls back when the registry can't be read", () => {
		const readRegistry = () => {
			throw new Error("reg failed");
		};

		expect(findDocuments({ readRegistry, env, homedir })).toEqual({ documents: fallback, warnings: [`Couldn't read the registry (reg failed). Using ${fallback}.`] });
	});

	test("warns and falls back when the value is missing", () => {
		expect(findDocuments({ readRegistry: () => "", env, homedir })).toEqual({ documents: fallback, warnings: [`The registry has no Personal value. Using ${fallback}.`] });
	});
});
