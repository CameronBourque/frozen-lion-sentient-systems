// Prints the bridge's log lines, each with the local time in front, such as "14:05:09  connected".

export function formatLine(time: Date, text: string): string {
	return `${time.toLocaleTimeString("en-GB")}  ${text}`;
}

export function log(text: string): void {
	console.log(formatLine(new Date(), text));
}
