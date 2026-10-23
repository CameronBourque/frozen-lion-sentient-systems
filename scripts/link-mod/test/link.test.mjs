// Tests for link.mjs, on real folders in a temp folder. Off Windows, Node makes a
// symlink in place of a junction, so the same tests run in CI.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { gameFolder, linkMod, MOD_NAME, samePath, unlinkMod } from "../src/link.mjs";

let root, documents, target, mods, link;

beforeEach(() => {
	root = fs.mkdtempSync(path.join(os.tmpdir(), "link-mod-"));
	documents = path.join(root, "Documents");
	target = path.join(root, "mod");
	mods = path.join(gameFolder(documents), "Mods");
	link = path.join(mods, MOD_NAME);
	fs.mkdirSync(target);
	fs.mkdirSync(gameFolder(documents), { recursive: true });
});

afterEach(() => {
	fs.rmSync(root, { recursive: true, force: true });
});

describe("samePath", () => {
	test("on Windows, ignores case and a trailing separator", () => {
		expect(samePath("C:\\Users\\A\\mod\\", "c:\\users\\a\\mod", "win32")).toBe(true);
	});

	test("on Windows, tells different folders apart", () => {
		expect(samePath("C:\\a\\mod", "C:\\b\\mod", "win32")).toBe(false);
	});

	test("elsewhere, keeps case", () => {
		expect(samePath("/a/Mod", "/a/mod", "linux")).toBe(false);
		expect(samePath("/a/mod/", "/a/mod", "linux")).toBe(true);
	});
});

describe("linkMod", () => {
	test("makes the Mods folder and links the mod", () => {
		expect(linkMod({ documents, target })).toEqual({ lines: [`Linked ${link} to ${target}.`], exitCode: 0 });
		expect(fs.realpathSync(link)).toBe(fs.realpathSync(target));
	});

	test("links into a Mods folder that exists", () => {
		fs.mkdirSync(mods);

		expect(linkMod({ documents, target }).exitCode).toBe(0);
	});

	test("stops when the game folder is missing", () => {
		fs.rmSync(gameFolder(documents), { recursive: true });

		expect(linkMod({ documents, target })).toEqual({ lines: [`${gameFolder(documents)} doesn't exist. Start the game once, then run this again.`], exitCode: 1 });
		expect(fs.existsSync(mods)).toBe(false);
	});

	test("a second run says the link is in place and exits 0", () => {
		linkMod({ documents, target });

		expect(linkMod({ documents, target })).toEqual({ lines: [`${link} already links to ${target}.`], exitCode: 0 });
	});

	test("leaves a link to another folder alone", () => {
		const other = path.join(root, "other");

		fs.mkdirSync(other);
		linkMod({ documents, target: other });

		expect(linkMod({ documents, target }).exitCode).toBe(1);
		expect(fs.realpathSync(link)).toBe(fs.realpathSync(other));
	});

	test("leaves a real folder alone", () => {
		fs.mkdirSync(link, { recursive: true });

		expect(linkMod({ documents, target })).toEqual({ lines: [`${link} is a real folder, not a link. Not changing it.`], exitCode: 1 });
		expect(fs.lstatSync(link).isSymbolicLink()).toBe(false);
	});
});

describe("unlinkMod", () => {
	test("removes the link and keeps the mod folder", () => {
		fs.writeFileSync(path.join(target, "file.txt"), "kept");
		linkMod({ documents, target });

		expect(unlinkMod({ documents })).toEqual({ lines: [`Removed ${link}.`], exitCode: 0 });
		expect(fs.existsSync(link)).toBe(false);
		expect(fs.readFileSync(path.join(target, "file.txt"), "utf8")).toBe("kept");
	});

	test("exits 0 when there is no link", () => {
		expect(unlinkMod({ documents })).toEqual({ lines: [`${link} doesn't exist. Nothing to remove.`], exitCode: 0 });
	});

	test("leaves a real folder alone", () => {
		fs.mkdirSync(link, { recursive: true });

		expect(unlinkMod({ documents })).toEqual({ lines: [`${link} is a real folder, not a link. Not removing it.`], exitCode: 1 });
		expect(fs.existsSync(link)).toBe(true);
	});
});
