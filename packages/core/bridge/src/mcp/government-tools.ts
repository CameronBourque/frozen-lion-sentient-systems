// The MCP tools that set the policies, pay the unlock, and change the
// government. Each description is written for the model.
// docs/design/core/mod/actions/government.md has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { setGovernment, setPolicies, unlockPolicies } from "../actions/policies.js";
import { registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SET_POLICIES = `Set the policy in every slot of your government, as the government screen's confirm does. slots lists every slot of get_choices' government by its number, from 0, with a policy type or null for an empty slot. A slot left out is refused, so no slot is emptied by mistake.

A policy is the type of one in get_choices' policies, or of one already in a slot, which can stay or move. You can change them when policies.canChange is true. A refusal names the rule, or the slot and policy that don't fit.`;

const UNLOCK_POLICIES = `Pay the cost of the unlock in get_choices' policies and governments, as the unlock button does. It lets you change policies and the government on a turn with no civic completed. A refusal says why, such as a cost you can't afford.`;

const SET_GOVERNMENT = `Change your government to a type from get_choices' governments, such as GOVERNMENT_AUTOCRACY, as the government screen's confirm does. A government with anarchy turns starts after them.

You can change it when governments.canChange is true. A refusal names the rule, such as a change made this turn already, or a turn with no civic completed, which points at the unlock when governments shows one.`;

export function registerGovernmentTools(server: McpServer, context: ToolContext): void {
	registerAction(server, context, "set_policies", SET_POLICIES, z.object({
		slots: z.array(z.string().nullable()).describe("A policy type, such as POLICY_DISCIPLINE, or null, for each slot from 0."),
	}), (playerID, { slots }) => setPolicies(context.client, playerID, slots));
	registerAction(server, context, "unlock_policies", UNLOCK_POLICIES, z.object({}), (playerID) => unlockPolicies(context.client, playerID));
	registerAction(server, context, "set_government", SET_GOVERNMENT, z.object({
		government: z.string().describe("The government's type, such as GOVERNMENT_AUTOCRACY."),
	}), (playerID, { government }) => setGovernment(context.client, playerID, government));
}
