// Measures how many bytes each section of the state or of the choices takes as JSON, for `npm run
// state`. docs/design/testing.md#state-size has the sizes of a game.

export type SectionSize = { name: string; bytes: number; share: number };

// Returns the size of each section of value, largest first. share is the section's part of total,
// the size of the whole as the game sent it, which is a little more than the sections add up to.
export function sectionSizes(value: object, total: number): SectionSize[] {
	const sizes: SectionSize[] = [];

	for (const [name, section] of Object.entries(value)) {
		const json = JSON.stringify(section);

		if (json !== undefined) {
			const bytes = Buffer.byteLength(json);

			sizes.push({ name, bytes, share: bytes / total });
		}
	}

	return sizes.sort((a, b) => b.bytes - a.bytes);
}

// Returns one line for each section, with its name, bytes, and share as a whole percent, lined up in
// columns.
export function formatSectionSizes(sizes: SectionSize[]): string {
	const bytes = sizes.map((size) => size.bytes.toLocaleString("en-US"));
	const nameWidth = Math.max(...sizes.map((size) => size.name.length));
	const bytesWidth = Math.max(...bytes.map((text) => text.length));

	return sizes
		.map((size, i) => `  ${size.name.padEnd(nameWidth)}  ${bytes[i]!.padStart(bytesWidth)}  ${Math.round(size.share * 100)}%`)
		.join("\n");
}
