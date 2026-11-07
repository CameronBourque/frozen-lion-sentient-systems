# Phase 1: setup steps

The finished setup steps of [phase 1](../README.md): the mod link, the config file, logs and errors, and the load signal. The step table's `#` column sets their order.

## Link the core mod

Pull request: [chore(core): add the mod link script](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/26).

It added a script in place of the manual junction steps. The steps are in the [core mod README](../../../../packages/core/mod/README.md#install-for-testing).

## Config file

Pull request: [feat(core): add the config file and structured logs](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/27), shared with the logs and errors step.

It added the log level and the provider keys. The file is described in [settings.md](../../../design/core/settings.md).

## Logs and errors

Pull request: [feat(core): add the config file and structured logs](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/27), shared with the config file step.

It added structured logs at five levels, a log file per game, and `ERROR` lines from the core mod.

- The logs are in [logs.md](../../../design/core/logs.md).
- The `ERROR` line is under **Errors** in [design/core/mod/lines.md](../../../design/core/mod/lines.md#errors).
- The Lua facts are in [lua/contexts.md](../../../findings/lua/contexts.md#the-core-mods-states).

## Load signal

Pull request: [feat(core): add the load signal](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/29).

It lets the bridge tell when a load has finished.

- The lines are under **Load signal** in [design/core/mod/lines.md](../../../design/core/mod/lines.md#load-signal).
- The reset is under **Load reset** in [bridge.md](../../../design/core/bridge.md), and under **Log files** in [logs.md](../../../design/core/logs.md).
- The Lua facts are in [lua/state-list.md](../../../findings/lua/state-list.md#state-list-over-a-session).
