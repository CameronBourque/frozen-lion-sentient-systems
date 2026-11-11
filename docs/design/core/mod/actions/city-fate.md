# City fate action

How the core mod runs the action that decides what happens to a captured or rebelled city, as the raze and disloyal city screens do. Part of the [action API](README.md).

## Decide a city

`SentientSystems_DecideCity(playerID, cityID, directive)` in `Scripts/Actions/SentientSystemsCore_ActionsCityFate.lua` keeps, razes, liberates, or refuses a city. The city is a `city` from the `cityFates` choice, and the directive is the `type` of one of its `options`, such as `RAZE` or `REJECT`.

Both screens send one `DESTROY` city command with the directive, so the action does too.

The game takes a liberation the raze screen hides, so the action checks the choice's options first. See [city-fate.md](../../../../findings/actions/city-fate.md).

Its reasons, in order, name no city waiting for a decision, a city that isn't one of the waiting ones, and a directive that isn't one of the city's options. A raze option the screen turns off gives the screen's own reason, and the list of options in a reason leaves it out.

On the bridge, `decideCity` in `src/actions/city-fate.ts` sends the call.

## Shared rules

The choice and the action both read the waiting cities and their options, so the rules are in `Scripts/SentientSystemsCore_CityFate.lua`. `SentientSystems_GetCityFates` returns the next captured city, then the next rebelled one, each with its kind and options.

## Decisions

| Decision | Reason |
| --- | --- |
| One action covers both screens | Both send the same command with a directive, so every call takes the same city and directive |
| The action takes the directive's name, not its number | The agent copies an option's `type` from the choice, and the action turns it into the number the request needs |
| The choice and the action share one function for the options | The choice can't list an option the action refuses |
