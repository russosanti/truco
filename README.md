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

## What came from pokebowl, unchanged

- `lib/class.lua` -- the `Class{}` constructor pattern used throughout
- `lib/knife/*` -- utility library; `timer.lua` (tweens and delays) and `event.lua` are the ones wired up
- `lib/push.lua` -- resolution-independent rendering
- `src/StateMachine.lua`, `src/states/BaseState.lua`, `src/states/StateStack.lua` -- the state management pattern
- `src/states/game/FadeInState.lua` / `FadeOutState.lua` -- generic color-fade transitions, no game-specific content
- `src/utils/Util.lua` -- `GenerateQuads` (sprite sheet slicing) and `print_r`
- `src/gui/Panel.lua` -- generic bordered panel, used as the backing for the in-hand message boxes
- `src/gui/Menu.lua`, `src/gui/Selection.lua` -- generic widgets, still unused
- `main.lua` / `src/Dependencies.lua` / `src/constants.lua` -- same shape (LÖVE lifecycle, central require + global asset tables), content trimmed to match this project

## What started as pokebowl code and was rewritten

- `src/gui/Textbox.lua` -- began as the pokebowl paginated dialogue box. The
  pagination, its `update`/`next`/`isClosed` input handling and the upstream
  header are gone; what remains is this project's message box (auto-sized to its
  text, screen-centred, dismissed by the caller's timer rather than a keypress).
  Only the `Panel` composition and the `getWrap` width clamp survive from
  upstream. Treat it as project code.

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
