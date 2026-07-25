# CLAUDE.md — dev log & decisions

> Temporary working notes for the PRD implementation. **Delete before final delivery** (along with `*_test.lua` and the scratchpad harnesses).

## Toolchain

- **Run unit tests with `luajit`, not `lua`.** Homebrew's `lua` is 5.5, which makes `for` control variables `const` and breaks the vendored `lib/class.lua` (`k = include_helper(...)`). LÖVE embeds LuaJIT (5.1 semantics), so `luajit` is the correct match.
  - `luajit lib/knife/test.lua src/<file>_test.lua`
- LÖVE 11.5 installed via `brew install --cask love` (cask is deprecated/Gatekeeper-flagged but the 11.5 binary works). Run: `love .`

## PRD 1 — card & deck model

- `Card` / `Deck` / `card_defs` live flat under `src/` (Dependencies.lua already scaffolded flat require paths; PRD's `src/truco/` was optional).
- Trick tiers, envido values, sprite-quad index all resolved from `card_defs` lookup tables.

## PRD 2 — hand loop

- Phases sequenced by an internal `StateMachine` inside `HandLoopState`: deal → cantos (empty hook) → trick → score → deal.
- **`isHandDecided` — prose vs. table reconciliation.** PRD §5 prose only decides on a tie "if the trick that just finished was a tie," which does NOT settle the `tie → P1 wins` row after trick 2 as the (authoritative) worked-examples table requires. Fix: the number of pardas so far is inferable as `tricksPlayed - wins.human - wins.ai`, so "a parda occurred AND one side leads on clean wins → decide now" closes the gap. Matches every table row + the ordinary 1-1-then-win-on-3 case. See comment in `src/trick_rules.lua`.
- **AI think delay:** AI move scheduled via `Timer.after(0.6, ...)` behind an `aiThinking` one-shot guard, so its card doesn't land on the same frame as the human's.

## PRD 2 addendum — trick rendering polish

- **Play animation:** each played card is a `{card,x,y,rot,done}` object tweened (`Timer.tween`, 0.2s) from its hand slot to its table slot with a ±7° random settle tilt. `drawCardFrontRot` (in `table_render.lua`) rotates about the card center.
- **Resolve gating:** `resolve()` is deferred until BOTH cards' tweens finish, via `tryResolve()` (called from each tween's `:finish`).
- **Input gating (gotcha):** deferring resolve opened a window where both cards are down (`playCount==2`) but `resolving` is still false and `currentPlayer` has flipped back — `update` happily accepted a *third* card, draining the hand and soft-locking. Fixed with an explicit `if self.playCount >= 2 then return end` guard in `update` (turn-flipping alone was NOT enough, contrary to the first plan). Caught by the headless smoke harness.
- **Played-card position (item 3):** Y-only split — AI up (`AI_PLAYED_Y=60`), human down (`HUMAN_PLAYED_Y=92`), ~18px overlap; X unchanged (`cardRowX(1,2)` / `cardRowX(2,2)`).
- **Item 4 decision:** removed BOTH the "AI" and "You" played-slot labels (and the empty-slot outline rects), not just "You" — with item 3's positioning, owner is conveyed by position, and the label/outline block under the AI hand was what read as a stray face-down "You" row. Top area is now strictly the AI's 3 backs.
- **Asset swap (item 1):** alpha-correct `graphics/deck_sheet.png` / `card_back.png` are a user-provided drop-in; no code change (same grid/cells/quad formula). Code draws at full opacity, so transparent corners render rounded automatically.
- **Human input (replaced 1/2/3):** raise-only picker, no highlight ring — the lifted card (`HUMAN_HAND_RAISE=12`) is the only cue. State is a **nilable** `self.raised` (index or nil; nothing raised at trick start) plus `self.prevHovered`. Mouse drives the lift on *transitions* only: entering a card raises it; leaving a card it was over lowers it; moving through empty space (hovered nil→nil) leaves a keyboard-raised card alone (the one non-obvious rule — the only mouse-driven lower is the `hovered==nil and prevHovered~=nil` exit edge). Arrows lift card 1 when none is up, else move ±1. Enter plays the raised card (no-op if none); left-click plays the card under the mouse (`cardAtMouse` via `push.toGame`, hit band spans raised+resting Y; `mouseWasDown` edge detection). Verified headless in `scratchpad/input.lua` (arrow-lifts-first, enter/exit, empty-space keeps lift, Enter-no-op, click). `smoke.lua`/`rotation.lua` drive with Right+Enter (Right lifts card 1, Enter plays it) with the mouse stubbed outside the game area (`push.toGame` overridden).
- **Asset alpha bug + fix:** the dropped-in PNGs had a broken alpha channel — the card's white *background* was keyed to transparent across the right ~35% of every cell (only ink/border stayed opaque), so the green table showed through and the art appeared to float. The underlying RGB there was already white. Fixed programmatically (PIL): rebuilt each cell's alpha from a rounded-rectangle mask (130×200, radius 6) — opaque card body, only the true outer corners transparent. Applied to all 40 cells + `card_back.png`; originals backed up in scratchpad (`deck_sheet.ORIG.png`, `card_back.ORIG.png`). Same dimensions/format (1300×800 RGBA). Verified by compositing cells over the table green and eyeballing.

## PRD 3 — envido

- **Pure math** in `src/envido_rules.lua` (`envidoValue`/`envidoWinner`/`rejectValue`/`faltaEnvidoValue`); throwaway `EnvidoAiStub` (open if ≥27, quiero if ≥24, never raises).
- **Falta modeling (not spelled out in the PRD):** `cumulative` tracks only envido(2)/real(3); falta is a ceiling that adds nothing. Accept-falta pays `faltaEnvidoValue` (ignores cumulative); reject-falta pays `max(cumulative,1)` = the pre-falta pot floored at 1 (direct falta→1, Envido→Falta rejected→2). Non-falta reject uses `rejectValue(cumulative,lastCallValue)`.
- **Reusable call engine (user asked for Truco-ready code):** `src/canto.lua` is a family-agnostic call/response/escalation state machine (`Canto`), config-driven — tracks calls/cumulative/caller/responder and yields a structured `outcome`. `src/envido_canto.lua` binds it to envido: the `ENVIDO_CANTO` ladder config + `envidoAward(outcome, mano, ...)` → (side, points) via envido_rules. **PRD 4's Truco plugs a truco config + resolver into the same engine.** Tested in `src/canto_test.lua`.
- **Envido lives inside trick 1, NOT a separate phase.** The old `CantosState` was **deleted**; machine is now `deal → trick → score`. Rationale (user): "play a card = pass" only makes sense if the envido window and the first trick are the same moment. In `TrickState`: envido is callable while `tricksPlayed==0 and not envidoUsed`, at each side's turn before it plays its first card — mano first, and the **pie can still call after mano's card** (correct reglamento; verified in the flow driver). Opening a call sets `self.canto`; while set, it owns input/render (Quiero/No quiero/raises) and pauses card play; `finishCanto` applies points **immediately**, shows a 1.5s banner, then clears `self.canto` and the *same* `currentPlayer` resumes to play their card. AI envido decisions reuse the 0.6s think guard.
- **No Pass button (user):** to decline envido you just play a card. Human open turn shows Envido/Real/Falta buttons **and** the playable hand; clicking a card plays it (declines). Buttons are mouse+keyboard (`[n]` shortcut), reusing `pointInRect`/`drawButton`.
- **Harness impact:** `driveKeys` in `smoke.lua`/`rotation.lua` now detects TrickState (`cur.tricksPlayed`) and answers an AI call with No quiero (`'2'`), else plays a card (Right+Enter) which also declines the human's own envido. Flow verified in `scratchpad/envido.lua` (human open accept/reject, AI-opens + human raises Real, falta malas, both-play-to-decline, click-driven open).
