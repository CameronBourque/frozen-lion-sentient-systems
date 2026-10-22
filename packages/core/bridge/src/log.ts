// Prints the bridge's log lines, each with the local time in front, such as "2:05:09 PM  connected".

export function formatLine(time: Date, text: string): string {
	return `${time.toLocaleTimeString("en-US")}  ${text}`;
}

export function log(text: string): void {
	console.log(formatLine(new Date(), text));
}
