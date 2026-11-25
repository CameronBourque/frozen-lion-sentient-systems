// Opens a URL in the user's default browser.

import { type ChildProcess, type SpawnOptions, spawn } from "node:child_process";

export type Spawn = (command: string, args: string[], options: SpawnOptions) => ChildProcess;

// On Windows, start would go through cmd, which reads each & in the URL as a
// new command. rundll32 hands the URL to the default browser as it is.
export function browserCommand(platform: NodeJS.Platform): [string, string[]] {
	if (platform === "win32") {
		return ["rundll32", ["url.dll,FileProtocolHandler"]];
	}

	return platform === "darwin" ? ["open", []] : ["xdg-open", []];
}

// The caller prints the URL too, so a browser that doesn't open only costs a
// copy and paste.
export function openBrowser(url: string, platform: NodeJS.Platform = process.platform, run: Spawn = spawn): void {
	const [command, args] = browserCommand(platform);
	const child = run(command, [...args, url], { detached: true, stdio: "ignore" });

	child.on("error", () => undefined);
	child.unref();
}
