// The opt-out marker that the heuristic comment rules share. The marker is
// described in docs/rules/code.md.

const OPT_OUT = /comment-lint-ignore:\s*\S/;

// Returns true when a comment holds "comment-lint-ignore:" and a reason. A
// marker with no reason skips nothing.
export function hasOptOut(text) {
	return OPT_OUT.test(text);
}
