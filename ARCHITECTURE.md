
## 1. The layering rule

Three layers, and one rule that keeps them apart: **anything decidable without a
screen lives in a pure module that never mentions `love`.**

```
pure rules  (no LÖVE, unit-tested)      card_defs, Card, Deck, trick_rules,
                                        envido_rules, truco_rules, flor_rules,
                                        match_rules, canto, envido_canto,
                                        flor_canto, tournament_bracket,
                                        opponent_names, ai_config + the 4 AI files
                                            ▲ called by, never the reverse
LÖVE-facing states                      HandLoopState, DealState, TrickState,
                                        HandScoreState, ChicoScoreState,
                                        MenuState, TournamentState, MatchEndState
                                            ▲
vendored scaffolding (from pokebowl)    Class{}, StateStack, StateMachine,
                                        BaseState, push.lua, knife/timer,
                                        knife/test, gui/Panel
```

That split is what makes the rules testable: `luajit` has no LÖVE, so a pure
module either has no LÖVE references or its test won't run. Every rules module
has a matching `src/<name>_test.lua`.

The state classes **call** the rules and never re-implement them. If you find
game logic inside a state file, that's a smell — the exceptions are documented
in place.

---

## 2. Two state mechanisms, deliberately

**`StateStack`** — top-level screens, push/pop. Renders bottom-to-top, updates
only the top.

```
MenuState ──▶ HandLoopState ──▶ MatchEndState ──▶ MenuState
    │
    └───────▶ TournamentState ──▶ HandLoopState ──▶ MatchEndState
                     ▲                                    │
                     └────────── onMatchEnd(won) ─────────┘
```

`TournamentState` does **not** pop itself when launching a match — it stays on
the stack underneath so the bracket survives. That's safe because every phase
state opens with `love.graphics.clear`, so the match paints over it.

Every arrow above is a **fade**, via `transition(fn)` in `src/transition.lua`: it
pushes `FadeInState` to cover the screen in black, runs `fn` (the original
push/pop, unchanged), then pushes `FadeOutState` to reveal. Two properties of the
stack make this work without any coordination — the fade renders over what's
beneath it because rendering is bottom-to-top, and the state beneath is frozen
and deaf while the fade is on top because only the top state updates, so a held
key or mouse button can't activate anything twice mid-transition. Note the
inherited names describe the *overlay*, not the scene: `FadeInState` fades the
black rect **in**, so it is the departure. Call sites never say so — they only
say `transition`.

**`StateMachine`** — phases *inside* one match, owned by `HandLoopState`:

```
deal ──▶ trick ──▶ score ──▶ deal ...
                     └─────▶ chico ──▶ (next chico | MatchEndState)
```

`HandLoopState` is the spine. It owns everything that survives across hands:
`playerScore`, `aiScore`, `chicosWon`, `chicoNumber`, `dealer`, `mano`, `deck`,
`matchFormat`, `aiName`, `onMatchEnd`. Its constructor takes an options table:

```lua
HandLoopState { matchFormat = 'best_of_3', aiName = 'Camila Torres',
                onMatchEnd = function(playerWon) ... end }
```

All three are optional — a bare `HandLoopState()` is a standalone best-of-3 vs
"AI" that returns to the menu.

---

## 3. `TrickState` — the one big file (677 lines)

Everything that happens *during* a hand lives here: flor, envido, truco, the
call buttons, the card picker, the table rendering. It is by far the largest
file and the first place to look if you want to refactor.

| Methods | Responsibility |
|---|---|
| `init`, `enter` | per-hand state; `enter` runs the mandatory flor pre-phase |
| `startTrick`, `playCard`, `tryResolve`, `resolve` | the trick cycle and card animation |
| `update` | the priority chain (below) |
| `canCallEnvido`, `canInterruptEnvido`, `callButtons`, `applyCallButton` | what you may say right now |
| `callTruco`, `resolveTrucoAccept/Raise/Reject`, `resolveFold` | truco stakes |
| `openCanto`, `aiRespondCanto`, `finishCanto`, `revealShowdown` | envido **and** flor, shared |
| `aiContext`, `updateAiTurn`, `aiRespondTruco` | the AI's turn |
| `updatePlayerSelection`, `cardAtMouse`, `render` | input and drawing |

`update` is a strict priority chain, and the order **is** the game's rules:

```
resolving?  →  both cards down?  →  a dialog box on screen?  →  a live canto?
→  flor unresolved?  →  a truco awaiting an answer?  →  normal turn
```

Each guard returns early, so "you can't play a card while a call is pending"
needs no separate flag.

### Per-hand vs per-trick state

`init` sets what lasts the whole hand (`wins`, `playedStack`, `envidoValue`,
`flor`, `trucoLevel`, `firstTrickWinner`). `startTrick` resets what's per-trick
(`currentPlayer`, `trickCards`, `anims`, `playCount`, `raised`). Getting a field
in the wrong one is the most likely source of a subtle bug here.

---

## 4. The shared call engine

`src/canto.lua` is a family-agnostic call/response/escalation machine. It tracks
the call list, who called, who owes an answer, and yields a structured
`outcome`. **Envido and flor both run on it** through config + award bindings:

| | ladder | accept pays | refuse pays |
|---|---|---|---|
| `envido_canto.lua` | envido / real / falta | cumulative pot, or `faltaEnvidoValue` at the ceiling | `rejectValue(...)` |
| `flor_canto.lua` | flor / contraflor / al resto | 3, 6, or `faltaEnvidoValue + 6` | the rung below (3 or 6) |

They share one negotiation slot in `TrickState` — `self.canto` plus
`self.cantoFamily` — which means one input path, one AI response path and one
reveal for both. Flor's levels are *fixed* rather than cumulative, so
`florAward` reads `outcome.lastCallValue` + `outcome.ceiling` and ignores
`cumulative` entirely (envido's falta ceiling already did the same).

**Truco deliberately does not use this engine.** Truco is level-based (2/3/4),
persists across tricks, is accept-before-raise, and its accepted level must
outlive the negotiation. Forcing it through `Canto` would use the abstraction's
shell but not its substance, so it's ~30 lines of state-local fields
(`trucoLevel`, `trucoLeader`, `trucoPending`) plus `truco_rules.lua`.

### Call interactions worth knowing

- **Envido primero** — answering a truco with any envido variant **discards**
  that truco outright. No quiero is owed; play resumes and either side may call
  truco afresh. `envidoUsed` is one-shot, so this can't loop.
- **Accepting a truco closes envido** for both sides, for the rest of the hand.
- **Flor cancels envido entirely** — `canCallEnvido` and `canInterruptEnvido`
  both require `not florHappened`.
- **Raising is an answer.** Facing a Truco you may say Retruco directly: it
  banks the pending level as the stake and puts the raise back on the caller,
  alternating, with no card played in between.

---

## 5. The AI

`src/ai_config.lua` is the single tuning surface:

```lua
AiConfig = { aggression = 0.5, bluffRate = 0.10, random = math.random }
```

The idea that keeps it small: **aggression and bluffing are the same
primitive** — both step a decision one rung along an ordered ladder
(`shiftTier`), which is how envido's numeric bands and truco's categorical
positions share one knob. `random` is an injectable seam so tests can kill the
coin flips; production leaves it alone.

Four decision files, each taking a `ctx` table built in one place,
`TrickState:aiContext()` (`against`, `myWins`, `theirWins`, `tricksPlayed`,
`cardsPlayed`, `trucoLevel`, `myScore`, `theirScore`):

| File | Decides |
|---|---|
| `AiStub.lua` | which card to play — cover minimally, prefer a tie to a loss, hold bravas until the hand can be decided |
| `EnvidoAiStub.lua` | open / respond / raise, on tiers at 20 / 27 / 31 |
| `TrucoAiStub.lua` | call / respond / raise / fold, on position (bravas + trick wins) |
| `FlorAiStub.lua` | whether to escalate a flor contest |

> **Naming note:** the `*Stub` filenames are historical. These were placeholders
> through PRD 5 and became the real heuristic AI in PRD 6; the filenames were
> kept so no call sites had to change.

Two behaviours that are easy to mistake for bugs: the AI won't open truco before
any card has been played unless it holds two bravas (you play one and see what
the other side has first), and it opens envido with a plain *Envido* almost
always — escalation happens in the response, not the opening.

---

## 6. Scoring: one funnel, two invariants

**`HandLoopState:awardPoints(side, points)` is the only place scores change.**
It exists because points arrive from two directions — envido/flor can pay out
mid-trick-1, while trick and truco points land at hand end — and a falta envido
crossing 30 would slip past an end-of-hand-only check. Every award runs
`chicoWinner`, so the chico can end at any moment.

Two non-obvious rules hang off that:

1. **Announce before award.** Any AI message that precedes a payout must own the
   payout in its callback. An award can end the chico, which swaps `TrickState`
   off the machine — a message set *after* one renders nowhere. (This was a real
   bug: "AI: No quiero" vanished only when the point crossed 30.)
2. **The abort guard.** A chico ending mid-hand leaves orphaned timers armed.
   `changePhase` no-ops while `handAborted`, so a stale timer can't drag a dead
   hand into the next chico. `Timer.clear()` is *not* usable here — we'd be
   calling it from inside a timer callback, which this library can't survive.

---

## 7. Rendering

Virtual resolution is 384×216, scaled by `push.lua`. `src/table_render.lua`
holds everything shared: `drawCardFront`, `drawCardFrontRot` (rotates about the
card's centre, with optional alpha), `drawCardBack`, `cardRowX`, `pointInRect`,
`drawButton`, `drawHud`.

Cards animate with `Timer.tween` from their hand slot to the table, and a trick
only resolves once **both** cards have landed. Each side's played cards stack
across the hand, fanning away from each other (AI left, player right) so the two
columns can't collide.

Message boxes are `gui/Panel` sized to their text, positioned by side, and every
one names its speaker (`AI: ` / `You: `) — without that, a bare number read as
the opponent's.

---

## 8. Testing

**Unit tests** cover the pure modules. Run with `luajit`, not `lua`:

```bash
luajit lib/knife/test.lua src/trick_rules_test.lua
```

> Homebrew's `lua` is 5.5, which makes `for` control variables `const` and
> breaks the vendored `lib/class.lua`. LÖVE embeds LuaJIT (5.1 semantics), so
> `luajit` is the matching runtime.

**Flow drivers** stub `love` and drive the *real* state objects frame by frame
(`smoke`, `rotation`, `envido`, `truco`, `flor`, `stack`, `match`, `menu`,
`tournament`). These caught most of the genuine bugs — the third-card soft-lock,
the swallowed announcement, the held-click that skipped the bracket.

Two rules of thumb that came out of this project: assert the *sequence* of what
appears on screen, not just the final score; and when a test and the code
disagree, check which one is wrong — several times it was the test.

---

## 9. File index

### Pure rules & model
| File | Lines | Exports |
|---|---|---|
| `card_defs.lua` | 48 | rank/suit tables, `trickTierFor`, `envidoValueFor` |
| `Card.lua` | 44 | `Card`, `Card.compareTrick` |
| `Deck.lua` | 56 | `Deck` (build/shuffle/deal/reset) |
| `trick_rules.lua` | 56 | `resolveTrick`, `nextLeader`, `isHandDecided` |
| `envido_rules.lua` | 38 | `envidoValue`, `envidoWinner`, `rejectValue`, `faltaEnvidoValue` |
| `truco_rules.lua` | 32 | `trucoRejectValue`, `trucoFoldValue`, `trucoRaiseCall`, `availableTrucoCall` |
| `flor_rules.lua` | 24 | `hasFlor`, `florValue`, `florWinner` |
| `match_rules.lua` | 21 | `chicoWinner`, `chicosNeeded`, `partidaWinner` |
| `canto.lua` | 58 | `Canto` — the shared call engine |
| `envido_canto.lua` | 40 | `ENVIDO_CANTO`, `envidoAward` |
| `flor_canto.lua` | 38 | `FLOR_CANTO`, `florAward` |
| `tournament_bracket.lua` | 67 | `buildBracket`, `advanceRound`, `matchWinner`, `playerOpponent` |
| `opponent_names.lua` | 54 | `randomName`, `generateNames`, `firstNameOf` |
| `ai_config.lua` | 49 | `AiConfig` + `chance`/`coin`/`bluffDelta`/`shiftTier` |
| `AiStub.lua` | 59 | `chooseCard` |
| `EnvidoAiStub.lua` | 64 | `tier`, `chooseOpen`, `chooseResponse` |
| `TrucoAiStub.lua` | 70 | `position`, `wantsToCall`, `respond`, `wantsToFold` |
| `FlorAiStub.lua` | 38 | `tier`, `chooseResponse` |

### States & presentation
| File | Lines | Role |
|---|---|---|
| `TrickState.lua` | 677 | the whole hand: calls, tricks, input, table render |
| `TournamentState.lua` | 186 | bracket tree, matchup screen, round advancement |
| `MenuState.lua` | 135 | title screen, falling-cards backdrop, menu |
| `HandLoopState.lua` | 78 | match spine: scores, chicos, phase machine, `awardPoints` |
| `MatchEndState.lua` | 54 | result screen; routes back to menu or tournament |
| `ChicoScoreState.lua` | 34 | chico banner, then next chico or match end |
| `HandScoreState.lua` | 28 | hand banner, then rotate dealer and deal |
| `DealState.lua` | 24 | deal 3+3, set mano |
| `FadeOutState.lua` | 35 | overlay that reveals a scene (opacity 1 → 0) |
| `FadeInState.lua` | 31 | overlay that covers a scene (opacity 0 → 1) |
| `table_render.lua` | 78 | shared drawing helpers |
| `transition.lua` | 9 | `transition(fn)` — cover, swap states, reveal |
| `sides.lua` | 3 | `otherSide` |

---

## 10. Where to change things

| To change | Edit |
|---|---|
| AI difficulty / bluff frequency | `src/ai_config.lua` — `aggression`, `bluffRate` |
| Envido / flor / truco thresholds | the four `*AiStub.lua` files |
| Think delay, message hold, reveal pacing | `Timer.after` constants in `TrickState` (0.6 / 1.5 / 2.0) |
| Table layout, card fan, dialog positions | the constants at the top of `TrickState.lua` |
| Opponent names | `src/opponent_names.lua` |
| Tournament round lengths | `TOURNAMENT_ROUND_FORMAT` in `src/tournament_bracket.lua` |
| Points needed to win a chico | `CHICO_TARGET` in `src/match_rules.lua` |
| Falling-cards density / speed | `FALL_ALPHA`, `SPEED_MIN/MAX` in `src/states/game/MenuState.lua` |
| Bracket column layout | `COL_W`, `ROW_H`, `BRACKET_Y` in `src/states/game/TournamentState.lua` |

---

## 11. Known rough edges

- **`TrickState` is 677 lines.** The obvious refactor: lift the call UI
  (`callButtons` / `applyCallButton` / the canto plumbing) into its own module.
- **`*Stub` filenames** no longer describe their contents (see §5).
- **`src/gui/Menu`, `ProgressBar`, `Selection`, `Textbox`** are vendored and
  unused — only `Panel` is wired up. They're commented out in
  `Dependencies.lua`; deleting them is safe.
- **`src/Util.lua` carries a wrong upstream header** ("Super Mario Bros. Remake
  / StartState Class"). Cosmetic.
- **`graphics/deck_sheet_numbered.png`** is a development reference, not used at
  runtime.
