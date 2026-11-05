// Empties the folder that Test/Game.lua records the Lua JSON in, and makes one
// folder per call. It runs first in test:lua and coverage:lua, so a fixture
// from a deleted test doesn't stay for the bridge tests to read.

import fs from "node:fs";
import path from "node:path";

const folder = path.resolve(import.meta.dirname, "../../../packages/core/bridge/test/lua-fixtures");
// The top-level calls that Test/Game.lua records, which it names the same way.
const calls = ["GetState", "GetChoices", "GetTechTree", "GetCivicTree", "GetGovernorTree", "GetPlacement", "MoveUnit"];

fs.rmSync(folder, { recursive: true, force: true });

for (const call of calls) fs.mkdirSync(path.join(folder, call), { recursive: true });
