// Replies from the Windows capture, as strings, for the fake game and the client tests. The
// bytes are in docs/findings/tuner-protocol.md#message-examples.

// The three strings the game sends back for APP:.
export const appReply = [
	"Civ6",
	"Sid Meier's Civilization 6",
	"E:\\SteamLibrary\\steamapps\\common\\Sid Meier's Civilization VI\\Base\\Binaries\\Debug",
];

// A few of the 124 states. The capture shows indexes 0, 1, 119, and 123. The two SaveGameMenu
// indexes are made up, because the findings list that name twice without its indexes.
export const states = [
	{ index: 0, name: "Main State" },
	{ index: 1, name: "DebugHotloadCache" },
	{ index: 40, name: "SaveGameMenu" },
	{ index: 41, name: "SaveGameMenu" },
	{ index: 119, name: "InGame" },
	{ index: 123, name: "InvitePopup" },
];

// The tag 3 reply to error("boom") in InGame. It's the only frame the game sent for it.
export const errorReply = "ERR:Runtime Error: [string \"_cmdr = {error(\"boom\")}\"]:1: boom\n"
	+ "stack traceback:\n"
	+ "\t[C]: in function 'error'\n"
	+ "\t[string \"_cmdr = {error(\"boom\")}\"]:1: in function '(main chunk)'\r\n"
	+ "Lua callstack:\r\n";
