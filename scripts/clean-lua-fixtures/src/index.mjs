// Empties the folder that Test/Game.lua records the Lua JSON in, and makes one
// folder per call. Usage: npm run test:lua and npm run coverage:lua run it
// first. A leftover fixture from a deleted test would otherwise stay, and the
// bridge tests would still read it.

import fs from "node:fs";
import path from "node:path";

const folder = path.resolve(import.meta.dirname, "../../../packages/core/bridge/test/lua-fixtures");
// The top-level calls that Test/Game.lua records, which it names the same way.
const calls = ["GetState", "GetChoices", "GetTechTree", "GetCivicTree", "GetGovernorTree", "GetPlacement", "MoveUnit"];

fs.rmSync(folder, { recursive: true, force: true });

for (const call of calls) fs.mkdirSync(path.join(folder, call), { recursive: true });
