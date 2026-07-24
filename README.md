# Truco Argentino (starter skeleton)

A 2-player (vs AI) Truco Argentino card game in Lua/LÖVE, modeled on CS50's
Games final project brief. Design doc and PRDs are tracked separately;
this repo starts from a stripped-down copy of the [pokebowl](.) project so
the reusable scaffolding doesn't have to be rebuilt from scratch.

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

Boots to a placeholder start state that confirms the card sheet loads
correctly. See PRD 1 (`prd-01-card-deck-model.md`) for the next piece to
implement -- the `Card`/`Deck` data model and trick-rank comparator.
