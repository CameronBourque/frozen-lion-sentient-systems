// Tests for tiles.ts: the schema for the tiles the player has revealed.

import { describe, expect, test } from "vitest";
import { TILE } from "../../src/state/tiles.js";

const FARM = {
	x: 1,
	y: 2,
	terrain: "TERRAIN_GRASS",
	feature: "FEATURE_FLOODPLAINS_GRASSLAND",
	resource: "RESOURCE_WHEAT",
	owner: 1,
	district: "DISTRICT_CAMPUS",
	improvement: "IMPROVEMENT_FARM",
	improvementPillaged: true as const,
	route: "ROUTE_ANCIENT_ROAD",
	routePillaged: true as const,
	visible: true,
};

describe("TILE", () => {
	test("accepts a tile with every field", () => {
		expect(TILE.parse(FARM)).toEqual(FARM);
	});

	test("accepts a tile with only its position, terrain, and visibility", () => {
		expect(TILE.safeParse({ x: 0, y: 0, terrain: "TERRAIN_OCEAN", visible: false }).success).toBe(true);
	});

	test("rejects a pillaged flag that is false, which the core mod never sends", () => {
		expect(TILE.safeParse({ ...FARM, improvementPillaged: false }).success).toBe(false);
	});

	test("rejects a tile without its visibility", () => {
		expect(TILE.safeParse({ x: 0, y: 0, terrain: "TERRAIN_OCEAN" }).success).toBe(false);
	});
});
