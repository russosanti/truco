# Truco Argentino

A 2-player Truco Argentino game built in Lua with LÖVE as my final project for CS50's Introduction to Game Development.

The game follows the rules of Argentine Truco and includes an AI opponent, full betting/call mechanics, match progression, and a tournament mode.

## Features

- Spanish 40-card deck and Truco card ranking
- Envido, Real Envido and Falta Envido
- Flor, Contraflor and Contraflor al Resto
- Truco, Retruco and Vale Cuatro
- Irse al Mazo
- Chicos to 30 points
- Best-of-3 matches
- 16-player tournament mode
- AI opponents with configurable aggression and bluffing
- Voice lines for player and opponent calls
- Mouse and keyboard controls

The implementation follows `reglamento-truco.pdf` for rule decisions and edge cases.

## Running

Requires LÖVE 11.5.

```bash
love .
```

From the main menu:

- **Play Match** — best-of-3 chicos
- **Quick Chico** — single chico
- **Tournament** — 16-player tournament

Use the arrow keys and Enter or the mouse to navigate and play.

## Technical Details

The game separates the core Truco rules from the gameplay and rendering code.

### Project Structure

```text
main.lua               LÖVE entry point

src/
├── ai/                AI card and call decisions
├── gui/               UI components
├── objects/           Card, Deck and canto objects
├── rules/             Truco, Envido, Flor and match rules
├── states/            Menu, gameplay and tournament states
└── utils/             Shared utilities

sound/                  Music, effects and voices
graphics/               Card and game assets
fonts/
lib/
tools/
```

The modules under `src/rules/` contain the game rules without depending on LÖVE or the current game state.

This includes:

- Trick resolution
- Envido scoring and payouts
- Truco escalation and rejection values
- Flor scoring
- Chico and match winners

## State Management

Screens are managed using a `StateStack`.

Main states include:

- `MenuState`
- `TournamentState`
- `HandLoopState`
- `MatchEndState`
- `FadeInState`
- `FadeOutState`

`HandLoopState` manages the flow of a match using a `StateMachine`.

The main phases are:

```text
Deal → Trick → Score → Deal
```

with separate states for:

- `DealState`
- `TrickState`
- `HandScoreState`
- `ChicoScoreState`

This keeps the match flow separate from individual rule calculations and UI rendering.

## AI

The opponent AI is split into different responsibilities:

- Card selection
- Envido decisions
- Truco decisions
- Flor decisions

AI behavior can be adjusted through aggression and bluffing parameters.

## Audio

The game includes:

- Menu and match music
- Card sound effects
- Voice lines for player and opponent calls

Voice lines cover fixed calls as well as dynamically combined Envido and Flor values.

## Credits

Built as the final project for **CS50's Introduction to Game Development**.

Some utility and state-management code is based on the CS50 Games distribution by Colton Ogden.

Spanish card artwork is based on the Basquetteur deck from Wikimedia Commons, licensed under CC BY-SA 3.0.

Music used in the project is licensed through Artlist and is not covered by this repository's MIT license.

## License

Project code is licensed under the MIT License. See `LICENSE` for details.