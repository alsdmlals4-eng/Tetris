# POC Ruleset v0.1

Status: companion ruleset for `CORE_GAMEPLAY_GDD.md`; written-spec review pending.

## Purpose

This document fixes the minimum playable rules that should be tested before class-specific content is designed.

## Puzzle boards

### Line board

Benchmark starting geometry: **10 columns × 20 visible rows**.

POC mechanics:

- falling 4-cell pieces;
- move left/right;
- rotate clockwise/counterclockwise;
- soft drop;
- hard drop;
- Hold enabled;
- Next preview enabled;
- Single / Double / Triple / 4-Line Clear detection;
- Combo detection for consecutive piece placements that each clear at least one line;
- difficult-clear chain state for Back-to-Back-style rewards;
- Spin Clear recognition;
- Perfect Clear recognition.

The POC may use a modern SRS-like rotation/kick profile as an internal benchmark, but shipped terminology/presentation must remain project-owned.

### Chain board

Benchmark starting geometry: **6 columns × 12 visible rows**, with hidden/spawn space handled separately by implementation.

POC mechanics:

- falling 2-piece color pairs;
- 4-direction adjacency;
- a connected group of 4 or more same-color pieces clears;
- gravity resolves after each clear;
- repeated automatic clears create N-Chain;
- 4 colors in the first POC;
- All Clear recognition;
- multi-color and large-group events recorded for Score/telemetry.

## Active/inactive behavior

Only one board is the active main board.

- Active + `RUNNING` → puzzle advances.
- Active + `LOCKED` → puzzle freezes and accepts no puzzle manipulation.
- Inactive → `SUSPENDED`, fully frozen.
- Switching modes opens the destination board as `LOCKED`; player explicitly presses `RUN`.
- A switch/lock request made during atomic clear/chain resolution is queued until the board reaches a stable state.
- Skills may be activated while `RUNNING` or `LOCKED`.
- During `RESOLVING`, newly produced Energy/Chain Stock is committed only after resolution completes.
- Combat Clock continues in all normal puzzle states.

## Energy — POC values

Primary source is Line Clear.

| Line result | Energy |
|---|---:|
| Single | +10 |
| Double | +22 |
| Triple | +36 |
| 4-Line Clear | +52 |

Advanced technique modifiers for the first balance pass:

- Combo: +5% Energy per active Combo step, capped at +25%.
- Back-to-Back difficult clear: +15% Energy for that clear.
- Spin Clear: use the line-count Energy value, then +20%.
- Perfect Clear: +25 bonus Energy after the normal clear reward.

All percentages apply multiplicatively to the base clear reward and are rounded to the nearest integer after the total modifier is applied.

### Emergency Energy floor

- Baseline Tier-1 Skill cost: 15 Energy.
- If Energy is below 15, automatic recovery grants +1 Energy per second.
- Recovery stops immediately at 15 Energy.
- There is no automatic recovery above 15 in the core POC.

Purpose: prevent total defensive soft-lock without making Line mode optional.

## Chain Stock — POC values

Tier cap: **5**.

On completed N-Chain:

`Chain Stock = max(current Stock, min(N, 5))`

Stock is not additive.

Examples:

- Stock 0 + 2-Chain → 2
- Stock 4 + 2-Chain → remains 4
- Stock 2 + 5-Chain → 5
- Stock 5 → use Tier-3 Skill → 2
- Stock 2 + 3-Chain → 3
- returning from Stock 2 to Stock 5 requires a completed 5-Chain.

## Skill costs — neutral POC baseline

All three role families use the same Energy cost during the first systems test so class balance does not contaminate the puzzle-economy test.

| Tier | Stock cost | Energy cost |
|---|---:|---:|
| 1 | 1 | 15 |
| 2 | 2 | 25 |
| 3 | 3 | 40 |
| 4 | 4 | 60 |
| 5 | 5 | 85 |

Core roles:

- Attack
- Defense
- Heal

The first POC may use placeholder numerical effects. What matters first is whether the player has meaningful reasons to choose each role and alternate between Line and Chain.

## Score benchmark profiles

Score is never spent on combat.

### Line reference profile

- Single: 100 × level
- Double: 300 × level
- Triple: 500 × level
- 4-Line Clear: 800 × level
- Spin Single: 800 × level
- Spin Double: 1200 × level
- Spin Triple: 1600 × level
- difficult clear Back-to-Back: action score × 1.5
- Combo: 50 × Combo count × level
- Soft Drop: 1 per cell
- Hard Drop: 2 per cell

### Chain reference profile

Reference structure:

`Score = (10 × PiecesCleared) × (ChainPower + ColorBonus + GroupBonus)`

The exact benchmark ChainPower/ColorBonus/GroupBonus tables should be stored as data, not hard-coded into combat logic.

## Enemy test encounter

First test enemy should intentionally require both resources.

Example 45-second loop:

1. 10s: light attack — low pressure, lets player establish either board.
2. 20s: heavy attack — encourages Tier-2/3 Defense.
3. 30s: self-heal/charge — encourages timely Attack.
4. 40s: heavy attack — checks whether the player can rebuild resources after spending.

This is a systems test, not final encounter content.

## Success conditions for the first playtest

- Player switches modes for strategic reasons rather than because the game forces a timer swap.
- Line time and Chain time are both materially non-zero.
- A basic player can reach Tier 2 reliably and Tier 3 sometimes.
- Tier 4–5 feel aspirational but demonstrably attainable.
- Emergency Energy recovery prevents hard lock without replacing Line play.
- `LOCK` improves readability/decision-making but does not remove enemy time pressure.
- Continuous `RUNNING` Skill use gives an efficiency/mastery advantage without being mandatory.

## Benchmark sources

- SEGA Puyo Puyo Tetris 2 rules: https://asia.sega.com/puyopuyotetris2/kr/rule.html
- SEGA Puyo Puyo Tetris Swap: https://puyo.sega.com/tetris/rule/swap/index.html
- Tetris Effect: Connected beginner guide: https://www.tetriseffect.game/beginners-community-guide/
- TetrisWiki scoring: https://tetris.wiki/Scoring
- Puyo Nexus basic rules: https://puyonexus.com/wiki/Basic_rules
- Puyo Nexus scoring: https://puyonexus.com/wiki/Scoring
