// The schema for the tech and civic choices, as the research and civics
// choosers list them. A tech's prerequisites come from the tech tree.

import { z } from "zod";
import { RESEARCH_ITEM } from "../schemas.js";

export const RESEARCH_OPTION = RESEARCH_ITEM.extend({
	current: z.literal(true).optional().describe("True for the one in research. Left out otherwise."),
});
