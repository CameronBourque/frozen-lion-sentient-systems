// The schema for the WMD launchers section of the state: the units and missile
// silos that can launch each device the player has. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateWmdLaunchers.lua.

import { z } from "zod";
import { POSITION } from "../schemas.js";

const LAUNCHERS = z.object({
	units: z.array(z.number()).optional().describe("The IDs of the units that can launch it now, as the unit panel enables it. Left out with none."),
	silos: z.array(POSITION).optional().describe(
		"The tiles of the player's missile silos that can launch it now, as the silo's banner enables it. Left out with none.",
	),
});

export const WMD_LAUNCHERS = z.record(z.string(), LAUNCHERS).describe(
	"What can launch each device now, by type, such as WMD_NUCLEAR_DEVICE. A device the player has none of, or that nothing can launch, is left out.",
);
