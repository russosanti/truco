# Truco Argentino

A 2-player (vs AI) Truco Argentino card game in Lua/LÖVE, modeled on CS50's
Games final project brief. Design doc and PRDs are tracked separately;
this repo starts from a stripped-down copy of the [pokebowl](.) project so
the reusable scaffolding doesn't have to be rebuilt from scratch.

Full rules: 3 tricks per hand with the Spanish 40-card ranking, envido (real
and falta), flor (contraflor, al resto), truco (retruco, vale cuatro), going
to the mazo, chicos to 30 and best-of-3 partidas, plus a 16-player
single-elimination tournament against named opponents.

## Running it

```
love .
```

Requires LÖVE 11.5. From the title screen: **Play Match** (best-of-3),
**Quick Chico** (a single chico), or **Tournament**. Arrows + Enter, or the
mouse, work everywhere.

In a hand: hover or arrow onto a card to lift it, Enter or click to play it.
Calls appear as buttons on the right — playing a card instead is how you
decline an envido.

## Tests

Unit tests cover the pure rules modules. Use `luajit`, not `lua` — Homebrew's
Lua is 5.5, which makes `for` control variables `const` and breaks the vendored
`lib/class.lua`; LÖVE embeds LuaJIT, so it's also the matching runtime.

```
for f in src/*_test.lua; do luajit lib/knife/test.lua $f; done
```

## Code layout

See [ARCHITECTURE.md](ARCHITECTURE.md) for how the code is organised, where
each rule lives, and which constants to change to tune behaviour.

## What came from pokebowl, unchanged

- `lib/class.lua` -- the `Class{}` constructor pattern used throughout
- `lib/knife/*` -- utility library, including `test.lua`, the unit-test runner PRD 1 uses
- `lib/push.lua` -- resolution-independent rendering
- `src/StateMachine.lua`, `src/states/BaseState.lua`, `src/states/StateStack.lua` -- the state management pattern
- `src/states/game/FadeInState.lua` / `FadeOutState.lua` -- generic color-fade transitions, no game-specific content
- `src/Util.lua` -- `GenerateQuads` (sprite sheet slicing) and `print_r`
- `src/gui/*` -- generic Menu/Panel/ProgressBar/Selection/Textbox widgets (not wired up yet; kept in case they're useful for call prompts like envido/truco later)
- `main.lua` / `src/Dependencies.lua` / `src/constants.lua` -- same shape (LÖVE lifecycle, central require + global asset tables), content trimmed to match this project

## What was dropped

Everything Pokemon/RPG-specific: `graphics/pokemon/`, `sounds/`, battle and
catch states, party management, the overworld/tilemap system, entity
movement states, `Pokemon.lua` / `pokemon_defs.lua`. None of it applies to
a card game.

## Card art

`graphics/deck_sheet.png`, `graphics/deck_sheet_numbered.png` (dev
reference only), and `graphics/card_back.png` are rasterized from:

```
Spanish playing card artwork by Basquetteur (Wikimedia Commons)
Licensed under CC BY-SA 3.0
https://creativecommons.org/licenses/by-sa/3.0/
Vectorized collection: https://github.com/gjenkins20/spanish-playing-cards-svg
```

If these are edited further and redistributed, the edits must carry the
same license (CC BY-SA 3.0's share-alike term).

## License

This project's own code is MIT-licensed (see `LICENSE`), carried over from
the pokebowl project.

## Status

Feature-complete: all nine PRDs implemented (card model, hand loop, envido,
truco, chico/partida scoring, heuristic AI, menu, tournament bracket, flor).
