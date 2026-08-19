# Core Gameplay GDD — Dual-Board Puzzle Combat

- Status: **PROPOSED_CANON / user-approved design direction, written-spec review pending**
- Version: 0.1
- Date: 2026-08-19
- Repository: `alsdmlals4-eng/Tetris`
- Scope: first playable combat core only

## 1. Product thesis

The game combines two **separate, persistent puzzle boards** with a time-driven combat layer.

- **Line board**: creates **Energy** through line-clearing play.
- **Chain board**: creates access to higher **Skill Tiers** through completed chains.
- **Combat**: the player spends Energy and Chain Stock on class skills, choosing among **Attack / Defense / Heal** according to enemy intent and timing.
- **Mode switching**: the player manually switches which puzzle board is visible and playable. The other board is preserved and suspended.
- **Pressure**: enemy Combat Clock continues even while a puzzle board is locked or the player is choosing a skill.

Core player question:

> What do I need before the enemy acts — more Energy, a higher Skill Tier, or an immediate Attack/Defense/Heal?

The game should create tension from **decision timing**, not primarily from extreme piece speed.

---

## 2. World-agnostic terminology

Core systems must not use `Mana`, `Magic`, `Spell`, or other class/world-specific terms.

| System concept | Canon term | Meaning |
|---|---|---|
| survivability | HP | defeat resource |
| spendable skill resource | Energy | primarily earned by Line clears |
| chain result | Chain | native chain length on Chain board |
| stored skill access | Chain Stock | retained tier access created by completed Chains |
| character action | Skill | class-specific action |
| skill strength/access | Skill Tier | Tier 1–5 in POC |
| line streak | Combo | consecutive Line clears |
| performance record | Score | ranking/feedback; not a combat currency |

Class expression is separate from system vocabulary. For example, a Tier-3 Defense may be a shield stance for a warrior, an evasion technique for a rogue, or a guardian summon for a summoner.

---

## 3. Time model

There are three independent clocks/states.

### 3.1 Combat Clock

The Combat Clock belongs to the enemy/combat layer and **continues by default** during:

- Line board play
- Chain board play
- active-board `LOCKED` state
- mode switching
- skill selection UI
- skill activation

Normal player controls do **not** pause the Combat Clock.

Future skills may explicitly slow, delay, or stop the Combat Clock, but that is a special combat effect, not normal pause behavior.

### 3.2 Line board clock

The Line board advances only when:

1. Line is the active/visible mode, and
2. its state is `RUNNING`.

Otherwise its entire puzzle state is preserved and suspended.

### 3.3 Chain board clock

The Chain board follows the same rule:

1. Chain is active/visible, and
2. its state is `RUNNING`.

Otherwise it is preserved and suspended.

---

## 4. Puzzle-board state machine

Each puzzle board is persistent for the whole encounter.

### States

- `RUNNING`: visible, receives puzzle input, gravity/resolution advances.
- `LOCKED`: visible, puzzle simulation and puzzle input are frozen. Skill selection and mode switching remain available.
- `SUSPENDED`: not active/visible as the main board. State is frozen and preserved.
- `RESOLVING`: short atomic resolution for a Line clear or Chain reaction.

### Mode-switch rule

Switching from Line to Chain:

1. Line becomes `SUSPENDED`.
2. Chain becomes the visible board in `LOCKED` state.
3. The player inspects the board and explicitly presses `RUN` to resume it.

Chain to Line is symmetrical.

**Mode switch does not auto-run the destination board.** This prevents accidental piece movement when the player only wants to inspect the other state.

### Resolution rule

For POC clarity, mode-switch requests during `RESOLVING` are queued until the current clear/chain resolution reaches a stable board state.

Reasons:

- avoid half-resolved Chain states;
- avoid ambiguous reward timing;
- make replay/testing deterministic;
- prevent using mode switching to interrupt scoring/resolution windows.

---

## 5. Controls and difficulty self-selection

The player can use Skills in both `RUNNING` and `LOCKED` states.

This creates two legitimate play styles:

### Deliberate play

1. play puzzle;
2. press `LOCK`;
3. inspect enemy intent/resources;
4. choose Skill;
5. resume or switch mode.

### Continuous play

The player keeps the board `RUNNING` while simultaneously reading enemy intent and activating Skills.

The second style is faster and cognitively harder but is **not mandatory for core progression**. This is a built-in mastery gradient without requiring the base puzzle speed to become hostile to beginners.

`LOCK` freezes only the puzzle board. It never provides free combat thinking time because the Combat Clock continues.

---

## 6. Resource model

### 6.1 Energy — Line board

**Primary source:** successful Line clears.

Energy answers:

> How many / how expensive Skills can I use now?

POC starting values (tuning values, not final):

| Line action | Energy |
|---|---:|
| Single | +10 |
| Double | +22 |
| Triple | +36 |
| 4-Line Clear | +52 |

Advanced Line actions may modify Energy efficiency:

- Combo
- Back-to-Back
- Spin Clear
- Perfect Clear / All Clear

Initial policy:

- advanced actions reward mastery but are not required to earn basic Energy;
- Score bonuses can be much larger than Energy bonuses to prevent runaway Skill frequency;
- final Energy numbers are set from telemetry, not copied directly from another game's attack table.

#### Anti-soft-lock Energy recovery

Candidate default for POC:

- slow automatic recovery only when Energy is below the cheapest Tier-1 Skill cost;
- automatic recovery stops at that emergency floor;
- Line clears remain the only practical way to fund mid/high-tier Skills.

This preserves Line mode's purpose while preventing a player from becoming unable to perform any basic defensive action.

### 6.2 Chain Stock — Chain board

Chain answers:

> What is the highest Skill Tier I am currently allowed to access?

On a **completed** N-Chain:

`Chain Stock = max(current Chain Stock, min(N, Tier Cap))`

POC Tier Cap: **5**.

Examples:

- Stock 1 + completed 4-Chain → Stock 4
- Stock 4 + completed 2-Chain → Stock remains 4
- Stock 2 + completed 5-Chain → Stock 5

This is intentionally **not additive**. Repeating easy 1–2 Chains must not eventually simulate a genuine 5-Chain. A Tier-5 Skill requires the player to have actually demonstrated a Tier-5 chain result since spending down the stock.

Chain Stock is awarded only after the chain fully resolves.

---

## 7. Skill rule

POC supports Skill Tier 1–5.

A Tier-N Skill requires both:

1. `Chain Stock >= N`
2. `Energy >= Skill Energy Cost`

On activation:

- Energy decreases by the Skill's configured Energy cost.
- Chain Stock decreases by exactly N.

Example:

- Energy 70 / Stock 5
- activate Tier-3 Defense costing 40 Energy
- result: Energy 30 / Stock 2

### Why Tier equals Chain Stock cost

`Tier N → Stock -N` is intentionally simple and visible. Do not introduce fractional or per-skill Chain costs in the POC.

### Core Skill roles

Every initial class should be able to answer all three combat needs, although the fiction/mechanic can differ:

- **Attack** — improve enemy defeat progress / interrupt pressure.
- **Defense** — reduce, avoid, redirect, or counter incoming harm.
- **Heal** — recover HP or repair recent losses.

A class does not need literal magic or identical animations. Internal role and external fantasy are separate.

---

## 8. Enemy timeline and combat decision loop

Enemies act on a visible time schedule.

POC display target:

- exact countdown for the next action;
- preview at least one following action when the encounter design allows it;
- expected category/impact must be legible enough to support planning.

Core loop:

1. read enemy intent;
2. inspect Energy and Chain Stock;
3. choose Line if Energy is lacking;
4. choose Chain if Skill Tier access is lacking;
5. choose Attack / Defense / Heal;
6. spend Energy + Stock;
7. enemy acts;
8. repeat from the new board/combat state.

Enemy patterns should alter puzzle priorities rather than only deal damage.

Later encounter examples:

- Energy pressure: threatens Energy loss → player values Line mode.
- Chain pressure: threatens Stock reduction → player decides whether to spend now.
- heavy strike: encourages Defense preparation.
- enemy recovery: encourages timely Attack.

These are encounter-design hooks, not required POC enemies.

---

## 9. Score is separate from combat power

Score is a **performance/feedback metric**, not Energy and not Skill Tier.

Reasons:

- lets familiar puzzle scoring remain expressive without destabilizing combat economy;
- allows leaderboards/ranks/challenges later;
- allows advanced techniques to be strongly rewarded for mastery even when their combat-resource bonus is deliberately bounded.

### 9.1 Line scoring benchmark profile

The scoring engine should be data-driven enough to support a **recent Guideline-like reference profile** used by multiple modern Tetris-style games:

| Action | Reference score weight |
|---|---:|
| Single | 100 × level |
| Double | 300 × level |
| Triple | 500 × level |
| 4-Line Clear | 800 × level |
| Spin Single | 800 × level |
| Spin Double | 1200 × level |
| Spin Triple | 1600 × level |
| Back-to-Back difficult clear | action score × 1.5 |
| Combo | 50 × combo count × level |
| Soft Drop | 1 per cell |
| Hard Drop | 2 per cell |

Perfect Clear can use its own large bonus profile.

The project should treat these as a **benchmark scoring preset**, not as a requirement that every final score number match another game.

### 9.2 Chain scoring benchmark profile

The scoring engine should also support a **Puyo-style reference profile** where chain score depends on:

- number of pieces cleared;
- Chain Power;
- Color Bonus;
- Group Bonus.

Reference formula:

`Score = (10 × PiecesCleared) × (ChainPower + ColorBonus + GroupBonus)`

The multiplier term is bounded in the reference system. The project may later normalize or rescale this output for presentation.

### 9.3 Shared score layer

Both modes contribute to one encounter Score counter, but score events keep their origin/type so post-run analysis can separate:

- Line Score
- Chain Score
- total Score
- advanced-technique counts

Score never directly purchases a Skill.

---

## 10. Existing puzzle techniques supported as benchmark vocabulary

The POC rules/data model must not block later recognition of familiar techniques.

### Line-side events

- Single
- Double
- Triple
- 4-Line Clear
- Combo / REN-style consecutive clears
- Back-to-Back difficult clears
- Spin / Spin Clear
- Perfect Clear / All Clear
- Soft Drop
- Hard Drop
- Hold and Next-piece preview (control/usability features; final exact rules TBD)

### Chain-side events

- N-Chain
- multi-color clear
- large group clear
- All Clear
- fast drop bonus if later desired

**Important:** externally shipped names/art/trade dress must be reviewed independently. Brand-specific terms are benchmark/internal references unless explicitly cleared for product use.

---

## 11. UI information hierarchy

Only one puzzle board is large/interactive at a time.

Persistent combat HUD should show:

- enemy HP/status;
- next enemy action + countdown;
- Energy;
- Chain Stock / current maximum Skill Tier;
- selected class and Skill shortcuts;
- active mode (`LINE` / `CHAIN`);
- active board state (`RUNNING` / `LOCKED`).

Inactive-board preview should be small but sufficient to remember its strategic state. It must not accept puzzle input.

Mode tabs/buttons must show the corresponding resource at a glance:

- `LINE — Energy X`
- `CHAIN — Stock ★N`

This reinforces why the player would switch modes.

---

## 12. Failure and difficulty principles

POC difficulty should come primarily from:

- enemy action timing;
- deciding when to switch modes;
- Energy versus Chain Tier preparation;
- whether to keep playing while selecting Skills;
- choosing the correct Skill role.

Do **not** depend primarily on:

- extremely high gravity early;
- requiring advanced Spin/large-Chain techniques for basic survival;
- hidden rubber-band difficulty;
- punishing the player for using `LOCK` by deleting puzzle progress.

Field overflow / top-out behavior is intentionally not finalized in this document. It must later be designed so a single puzzle failure does not automatically invalidate the HP-based combat layer unless that is explicitly the encounter rule.

---

## 13. POC telemetry / balance contract

Record at minimum:

### Time

- encounter duration;
- time spent in Line `RUNNING`;
- time spent in Chain `RUNNING`;
- time spent `LOCKED`;
- number/frequency of mode switches.

### Line

- Singles/Doubles/Triples/4-Line Clears;
- Combo length;
- Back-to-Back count;
- Spin Clears;
- Perfect Clears;
- Energy generated per 30 seconds.

### Chain

- chain-length distribution;
- time to first 2/3/4/5-Chain;
- Chain Stock over time;
- Chain Stock wasted/overwritten.

### Skills

- Skill uses per Tier;
- Attack/Defense/Heal use rate;
- Energy spent per Tier;
- Stock spent per Tier;
- failed Skill attempts (insufficient Energy/Stock).

### Combat

- damage taken by enemy pattern;
- deaths;
- emergency/overflow recoveries when added;
- enemy actions successfully answered versus ignored.

Primary balance questions:

1. Does a player have a real reason to alternate between both modes?
2. Can beginners survive with basic clears and low-tier Skills?
3. Do higher Chains create meaningful access without making high Tier mandatory?
4. Is `LOCK` useful for deliberate play without removing Combat Clock pressure?
5. Does one mode dominate total play time because its resource is too scarce/valuable?

---

## 14. POC acceptance criteria

The first playable slice is successful when all are true:

1. Both puzzle boards preserve independent state across repeated switches.
2. Inactive board state never advances.
3. Active `LOCKED` board never advances or accepts puzzle manipulation.
4. Combat Clock continues during mode switch, `LOCKED`, and Skill UI.
5. Line clears generate Energy according to data-defined rules.
6. Completed Chains set Chain Stock according to chain result and do not additively fake higher Chains.
7. Tier-N Skill cannot activate unless both Energy and Stock requirements are met.
8. Tier-N Skill consumes N Stock and configured Energy.
9. Skill activation works in both `RUNNING` and `LOCKED` puzzle states.
10. Score is recorded independently of combat resources.
11. A test encounter forces at least one meaningful Line→Chain or Chain→Line decision.
12. Telemetry can explain why a player could/could not answer each enemy action.

---

## 15. Explicitly out of scope for this GDD

- final class roster or skill names;
- equipment/loot/skill trees;
- PvP;
- final enemy roster;
- final art/UI skin;
- final Energy/HP damage numbers;
- final top-out recovery rule;
- mobile/console input specifics;
- monetization;
- implementation architecture beyond state/data requirements needed by the design.

---

## 16. Benchmark decisions: adopt / transform / exclude

### Adopt

- persistent separate Puyo/Tetris-style boards as demonstrated by Swap-style play;
- familiar Line vocabulary: Combo, Back-to-Back, Spin, Perfect Clear;
- familiar Chain concepts: chain length, color/group bonuses, All Clear;
- visible HP/skill-resource combat precedent from puzzle skill-battle games;
- data-driven separation between score and combat resource.

### Transform

- automatic timed board swapping → **manual player-controlled mode switching**;
- equivalent competing puzzle attack systems → **different resource jobs** (Line=Energy, Chain=Tier access);
- puzzle pause → **board-only Lock while global Combat Clock continues**;
- chain score/attack power → **Chain Stock permission for higher Skill Tiers**.

### Exclude from core

- forcing both puzzle types onto one mixed board;
- hidden automatic difficulty adjustment as the primary difficulty solution;
- Score directly becoming damage/Skill currency;
- magic-specific universal terminology;
- copying branded presentation, characters, art, audio, or trade dress.

---

## 17. Reference notes

Primary/official references used for the design comparison:

- SEGA, Puyo Puyo Tetris 2 rules: https://asia.sega.com/puyopuyotetris2/kr/rule.html
- SEGA, Puyo Puyo Tetris Swap rule: https://puyo.sega.com/tetris/rule/swap/index.html
- Tetris Effect: Connected beginner/community guide: https://www.tetriseffect.game/beginners-community-guide/

Mechanics/scoring reference datasets:

- TetrisWiki scoring reference: https://tetris.wiki/Scoring
- Puyo Nexus scoring reference: https://puyonexus.com/wiki/Scoring

These references are used to benchmark established puzzle vocabulary, scoring relationships, and mode structure. The shipped game's final naming, numbers, visuals, and IP usage remain project decisions.

---

## 18. Revisit triggers

Re-open this design decision if telemetry shows any of the following:

- >70% of active puzzle time remains in one mode across comparable encounters;
- Tier 4–5 Skills are effectively inaccessible to the target non-expert player;
- Tier 4–5 Skills are so frequent that Chain preparation stops feeling meaningful;
- players can ignore enemy timing by overusing `LOCK`;
- automatic Energy floor makes Line mode strategically optional;
- mode switching during puzzle resolution feels unresponsive or confusing;
- the two-board cognitive load is materially worse than the strategic value it creates.

Rollback option for the dual-board experiment:

- retain the combat/Skill resource API;
- replace one live puzzle board with a simplified resource-generation interaction;
- do not couple Score directly into combat during rollback.

This keeps class/Skill design reusable even if the exact two-board interaction is later revised.
