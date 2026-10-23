// Tests for link.mjs, on real folders in a temp folder. Off Windows, Node makes a
// symlink in place of a junction, so the same tests run in CI.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { gameFolder, linkMod, MOD_NAME } from "../src/link.mjs";

describe("linkMod", () => {
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

	test("leaves something already at the link path alone", () => {
		fs.mkdirSync(link, { recursive: true });

		expect(linkMod({ documents, target })).toEqual({ lines: [`${link} already exists. Not changing it.`], exitCode: 1 });
		expect(fs.lstatSync(link).isSymbolicLink()).toBe(false);
	});
});
