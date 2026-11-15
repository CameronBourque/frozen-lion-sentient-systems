# Phase 1: popups

The finished step of [phase 1](../README.md) that closes the popups an agent player can't see. The index is in [README.md](README.md).

## Popups for agent players

Pull request: feat(core): close the popups for agent players.

For an agent as the local player, the core mod closes each popup and screen that waits for a click, as the batch of game events ends, a load ends, or the interface goes idle. Where the game has a switch, it turns the popup off instead, as for the tech, civic, and boost popups.

- **Close button.** Popups that hold the engine's event queue are closed with their own `Close` button: the wonder built, natural wonder, natural disaster, project built, and rock band movie popups. The natural wonder's fly-around gets a camera stop after.
- **Dequeue or hide.** The popups that hold nothing are dequeued or hidden: hero, Secret Society, historic moment, era review, World Congress intro, emergency, spy mission, rock band result, and great work popups.
- **Own close.** The congress voting screen and an overview-only leader screen close through their own close, and the unit captured dialog through its button.
- **Vote ends the turn.** The congress vote now ends the turn, as the screen's **Submit** does.
- **Events section.** A new `events` state section keeps what the closed capture and concert popups said, through the agent's next turn.
- **Concert action.** A new `concert` unit order starts a rock band's concert.

- How the core mod closes popups, in [design/core/mod/README.md](../../../design/core/mod/README.md#popups). The events section, in [design/core/mod/state.md](../../../design/core/mod/state.md#state-serializer), and the concert, in [design/core/mod/actions/units.md](../../../design/core/mod/actions/units.md#orders-on-the-units-tile).
- What each popup holds and how it closes, in [actions/popups.md](../../../findings/actions/popups.md), [actions/plain-popups.md](../../../findings/actions/plain-popups.md), [actions/congress-popups.md](../../../findings/actions/congress-popups.md), and [actions/in-game-dialogs.md](../../../findings/actions/in-game-dialogs.md).
- The spy mission popup, in [actions/spies.md](../../../findings/actions/spies.md#mission-popup), and the leader screen, in [actions/war-and-peace.md](../../../findings/actions/war-and-peace.md#the-leader-screen).
