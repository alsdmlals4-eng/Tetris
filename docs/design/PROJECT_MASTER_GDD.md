# Tetris · Master GDD

- Status: `CURRENT_READER_GDD / CANONICAL_SYNTHESIS`, Issue #72; current visual-lock/evidence-gate correction tracked in Issue #78
- Fresh source snapshot: `origin/main` `f84939d0be5d7c248201628bc88bb7f7c6640fe1`, read 2026-08-29. It retains the prior gameplay snapshot `dec60706ab8fcec3986b01f279d9d60080a309f8` and the Master-GDD/visual-workflow snapshot `59c537f29ed0bebed8d40be5cecfd6ff5b89318b` as provenance.
- Purpose: make the currently approved game intelligible in one place without replacing the documents and runtime evidence that own individual facts.
- Public title: **FRACTURE FRONTIER** (`USER_APPROVED_TEXTUAL_TITLE`). The user locked its generated title-logo image; the exact approved file is registered and bound in the current worktree, while target-resolution render capture and Human/player readability remain separate `NOT_RUN` gates.
- Reader rule: a rule may be **approved** yet not be **implemented**; an implemented system may be automated-tested yet not be **Human/player validated**. This document preserves those distinctions.
- Current owner rule: GitHub repository documents, GitHub issue/PR history, and runtime evidence are the sole current project owners. Notion is `HISTORICAL_EXTERNAL_PROVENANCE_ONLY`; do not read, write, sync, or require it for current work.

> This is a navigation and synthesis owner, not a license to overwrite detailed owners. When a detailed source and this GDD disagree, resolve it at the detailed owner, correct this synthesis, and record the conflict.

## 1. Source registry and authority

| Owner | What it owns | Fresh-read state |
| --- | --- | --- |
| `docs/design/PRODUCTION_CANON_INDEX.json` | Current decision IDs, authority order, machine-readable current/actual boundary | `CURRENT` |
| `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` | `TETRIS-CORE-029`: continuous battle, workspace and pause grammar | `CURRENT` |
| `docs/design/CHAIN_COMBO_MP_CONTRACT.md` | `TETRIS-CHAIN-038`: CHAIN match, MP lock, Combo and recovery formula | `CURRENT` |
| `docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md` and `COMBO_STAGE_SKILL_CONTENT_GDD.md` | `TETRIS-SKILL-039` / `TETRIS-BALANCE-040` / `TETRIS-SKILL-042`: category-only preview/confirm, bounded fallback and the target-separated 12-second board-opportunity mechanism | `CURRENT / IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING` |
| `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` and `DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` | Older manual Tier matrix and its cost grammar | `SUPERSEDED_FOR_CURRENT_SELECTION_FLOW / HISTORICAL_EFFECT_PROVENANCE` |
| `docs/design/FIRST_SESSION_ONBOARDING_CONTRACT.md` | `TETRIS-ONBOARDING-037`: title, full-rule briefing and same-encounter safe live tutorial | `CURRENT / IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING` |
| `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md` | Runtime consumer and image-generation/lock workflow | `CURRENT` |
| `AGENTS.md` § `MANDATORY_CURRENT_TASK_EVIDENCE_GATE` | Fresh source read, targeted official research, feasibility classification, five adversarial loops and exact-head/destination readback | `CURRENT / PROCESS AUTHORITY` |
| `docs/design/FULL_GAME_SCREEN_SURFACE_INVENTORY.md` | Current and planned screen coverage | `CURRENT` |
| `scenes/production/battle.tscn`, `src/production/**`, `data/production/**` | Actual merged-main Godot scene, code and seed data | `CURRENT IMPLEMENTATION EVIDENCE` |
| `tests/production/**`, `tests/tooling/**`, exact-head CI/runtime receipts | Automated evidence only | `CURRENT / EVIDENCE-BOUNDED` |
| `docs/design/PROJECT_MASTER_GDD.md`, `VISUAL_BIBLE.md`, screen/asset manifests and GitHub issue/PR history | Human-facing project organization, visual direction and decision readback | `CURRENT REPOSITORY OWNER` |
| Previous Notion pages | External historical context only | `HISTORICAL_EXTERNAL_PROVENANCE_ONLY / DO_NOT_SYNC` |
| Open/draft PRs #19, #23, #33, #46 | Parallel historical/proposed workstreams | `READ_ONLY / NOT CURRENT TRUTH` |
| `CORE_GAMEPLAY_GDD.md`, POC rules and prior turn-time docs | Provenance only | `HISTORICAL` or `SUPERSEDED` as indexed |

### Canonical labels

| Label | Meaning in this GDD |
| --- | --- |
| `CURRENT` | Approved and current owner; not necessarily implemented. |
| `IMPLEMENTED` | Present on the fresh merged main. |
| `PARTIAL` | Some approved behavior exists, but a material remainder does not. |
| `HISTORICAL` | Useful provenance; not a current requirement. |
| `SUPERSEDED` | Explicitly replaced; must not re-enter UI, design, or implementation by accident. |
| `CONFLICT` | Current sources disagree or a current statement conflicts with actual evidence. |
| `UNKNOWN_UNVERIFIED` | Not proved by a fresh owner, code/data, test/runtime receipt, or Human/player receipt. |

### Resolved and remaining conflict register

| Class | Finding | Current disposition |
| --- | --- | --- |
| `SUPERSEDED` | Ordered LINE→CHAIN→enemy turns, shared player-turn budget, READY/pass flow, timeout and Tempo language | `TETRIS-CORE-024` / `TETRIS-TIME-025` are provenance only. CORE-029 continuous realtime replaces them. |
| `HISTORICAL` | `CORE_GAMEPLAY_GDD.md` describes earlier Energy/Stock and board concepts | Foundation reference only; it cannot define current player-facing rules. |
| `RESOLVED_IN_CURRENT_WORKTREE` | Approved CHAIN requires both diagonals, 1-MP lock, 60 MP cap, 10 Combo cap and per-wave formula. | The current worktree implements all-axis matching, explicit MP lock, caps and per-wave recovery. Exact-head full verification remains required before a merged-main claim. |
| `RESOLVED_IN_CURRENT_WORKTREE` | Old current documents and merged UI/data exposed manual `ATK/DEF/SUP × T1–T6`; the user-directed flow is category-only, current-Combo preview, explicit confirm and a bounded 5-MP fallback. | The current worktree uses category-only preview/confirm, current-Combo Stage resolution, bounded fallback and target-separated board opportunity. Exact-head full verification remains required before a merged-main claim. |
| `RESOLVED_IN_CURRENT_WORKTREE` | The historical parchment field-manual visual owner contradicted the latest user-directed dark fantasy combat reference. | `TETRIS-VISUAL-043` now owns obsidian/gold/violet presentation, large Gatebreaker framing, a face-focused Vanguard resource portrait and a rich read-only Skill detail surface. Existing image consumers are retained and recomposed inside their declared slots. |
| `PARTIAL` | The approved first session requires title → briefing → Deploy → short guided live practice → same encounter. | Title and accessible full-rule briefing now gate Deploy in the current worktree; the safe guided live-practice sequence remains to implement. |
| `UNKNOWN_UNVERIFIED` | Dedicated repository Audio Contract file | `VISUAL_BIBLE.md` is the repository visual owner. Audio has only pause-bridge support; a player-facing audio plan and evidence remain unknown. |
| `UNKNOWN_UNVERIFIED` | User-Windows play, target-resolution composite readability, first-exposure comprehension, tension, balance, accessibility and player appeal | **Human/player evidence: NOT_RUN**. Automated/scene-equivalent checks do not prove any of these. |

## 2. One-page game promise

### Player promise

**At a Frontier Gate, read a live Gatebreaker threat, decide whether to prepare MP with LINE or Combo with CHAIN, then pause only to make a deliberate Vanguard Technique commitment before the same danger resumes.**

Combat time is `CONTINUOUS_REALTIME`: the live clock begins at Deploy, and no ordered turn rail, shared player-turn budget or hidden READY handoff returns.

```text
Live Telegraph + ETA
→ choose a persistent puzzle workspace
→ LINE clear earns MP / CHAIN resolution earns shared Combo and MP recovery
→ decide: spend Combo on an urgent category response or preserve it for later CHAIN MP recovery and a higher resolved Stage
→ open Skill to fully pause, choose ATK / DEF / SUP and inspect one Combo-Resolved preview
→ explicit CONFIRM commits, feedback changes the battle, realtime resumes
→ read the next threat and revise the next preparation
```

| Link in the experience | Current intended meaning |
| --- | --- |
| Representative action | Switch freely between one large LINE or CHAIN workspace, manipulate it under pressure, then make an explicit Skill use. |
| Meaningful choice | Immediate MP versus future Combo; solve the current threat versus set up the next; pick attack, defense or support now versus preserve Combo for later CHAIN recovery and a higher resolved Stage; restore a failed swap versus spend fixed 1 MP to lock its setup. |
| Observable result | Clear/recovery, Combo change, telegraph/ETA, Technique outcome and the next enemy action are visible in the same battle context. |
| Reward and failure learning | Valid CHAINs grow the one shared Combo resource; a no-match restores by default and resets Combo, while MP lock deliberately keeps the board but also resets Combo with no immediate reward. Defeat/retry exists; causal learning quality is not yet Human-validated. |
| Target emotion and memory | “I spotted the threat, built the right resource and chose exactly when a strong move was worth it.” Pressure should feel readable, not like hidden turns or speed-only execution. |
| Next-action motive | A changed telegraph and resource state pose the next preparation/commitment question; planned result/meta loops are not yet proof. |
| Differentiation / sales hook | Not simply puzzle combat: two non-interchangeable puzzles create a live preparation dilemma, then a fair full pause turns reaction pressure into intentional tactical commitment. |

### Project goal and Work-5 position

| Work stage | Status | Evidence ceiling and next gate |
| --- | --- | --- |
| 1. Core promise, economy and visual direction | `CURRENT / USER_APPROVED` | CORE-029, CHAIN-038, SKILL-039/BALANCE-040, VISUAL-041 and ONBOARDING-037 are defined. |
| 2. Representative continuous-battle slice | `IMPLEMENTED / PARTIAL` | 50/50 battle, persistent workspaces, scheduler, pause, Combo-resolved skill preview/confirm, named art consumers, title/briefing entry, and a safe same-encounter guided-practice sequence exist in this worktree. Terminal reward/route remain incomplete. |
| 3. Human usability / player experience | `NOT_RUN` | The immediate required validation gate: target-resolution capture and first-exposure observation. |
| 4. First-session and session-completion loop | `DESIGNED / NOT_IMPLEMENTED` | Briefing/tutorial is approved; result/reward/route/meta remain planned. |
| 5. Production expansion and polish | `DEFERRED` | Start only after Stage 3 evidence identifies the smallest necessary correction. |

**Active Playable Slice:** `scenes/production/title.tscn` → `battle_briefing.tscn` → one Gatebreaker encounter in `battle.tscn`, with LINE, CHAIN, live telegraph/ETA, tactical Skill pause and retry. The title/briefing entry is implemented in the current worktree; the safe guided live practice is not yet implemented.

## 3. Core loop, systems and content

### Core, session and meta loops

| Loop | Status | Player flow |
| --- | --- | --- |
| Core combat loop | `CURRENT / IMPLEMENTED BASELINE` | Read ETA → choose LINE/CHAIN → gain/prep resource → pause for deliberate Technique commitment → resolve response → read next ETA. |
| Intended first-session loop | `CURRENT / PARTIAL` | Title → short Vanguard/Frontier Gate/Gatebreaker threat explanation → full economy-critical rule review → Deploy → safe live guided practice → seamless normal battle → result/retry. Title/briefing/Deploy and the four evidence-driven guide prompts are implemented in the current worktree; Human/player effectiveness remains unverified. |
| Full-session loop | `PARTIAL` | Planned title/loadout/route/briefing/battle/result surfaces exist as references; no route, persistence or reward data is implemented. |
| Progression/meta loop | `UNKNOWN_UNVERIFIED` | Route, workshop, persistent reward, unlock and long-run motivation must not be inferred from planned screen references. |

### System contract register

| System | Player-facing rule | Approved / actual state | Implementation owner |
| --- | --- | --- | --- |
| `SYS-CORE-029` Continuous battle | Enemy time runs after Deploy; encounter ends at victory/defeat; no old turn rail. | `CURRENT`; realtime runtime is implemented in the current worktree. | `src/production/runtime/production_combat_runtime.gd`, scheduler and battle scene. |
| `SYS-LINE-MP` | LINE no clear/Single/Double/Triple/Four gains `0/10/22/36/52 MP`; cap 60. | Rules current; reward seed exists; MP hard cap still not actual runtime proof. | `data/production/line_reward_seed.json`, line session/state. |
| `SYS-CHAIN-038` | Orthogonal adjacent swap; straight 3+ horizontal/vertical/diagonal matching. Failed swap restores, or fixed 1 MP locks a setup. | `IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING`. | `chain_board.gd`, `chain_resolver.gd`, `production_chain_session.gd`. |
| `SYS-COMBO-MP` | Each resolution wave grants Combo +1 (cap 10), then MP = `(sum maximal qualified line lengths − 3) + post-wave Combo`. | `IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING`. | CHAIN contract and `ProductionCombatState`. |
| `SYS-SKILL-039 / SKILL-042` | Skill fully pauses; choose ATK/DEF/SUP only, inspect the current Combo-resolved Stage, then explicitly CONFIRM. A player may deliberately stop at a lower Combo for a unique effect; player board-time and enemy ETA effects remain target-separated. Player board opportunity is a capped 12-second reserve which holds LINE gravity/lock while input remains available; enemy ETA continues in full real time. If MP is short, convert surplus Combo at 5 MP each and preview the highest feasible lower Stage. | `IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING`; manual Tier buttons are removed from the current battle scene. | [`COMBO_STAGE_SKILL_CONTENT_GDD.md`](COMBO_STAGE_SKILL_CONTENT_GDD.md), `production_skill_session.gd`, `production_skill_catalog.gd`, `production_battle.gd`, scheduler and skill seed. |
| `SYS-ENEMY` | Gatebreaker telegraph and ETA tell the player what is imminent. | `IMPLEMENTED` scheduling/preview; readability and tuning unknown. | `gatebreaker_*`, realtime timing/action/sequence seed. |
| `SYS-ONBOARDING-037` | Full rules before first Deploy; then short safe live practice in the actual encounter. | `IMPLEMENTED_IN_CURRENT_WORKTREE / FULL_VERIFICATION_PENDING`. | `title.tscn`, `battle_briefing.tscn`, `production_guided_practice_state.gd`, `production_combat_runtime.gd`, and `battle.tscn`. |
| `SYS-RESULT-RETRY` | Terminal outcome gives a visible retry path. | Retry exists; reward and explanatory result flow are planned. | battle UI / future Result surface. |
| `SYS-AUDIO` | Simulation audio should pause with the tactical simulation. | Pause bridge supports the `simulation_audio` group; no confirmed authored audio content or audio UX evidence. | `simulation_pause_bridge.gd`; dedicated content owner unknown. |

### Resource/economy example

The rules are deliberately one shared Combo resource—not an additional currency:

```text
Valid wave: two qualifying lines of length 5, current Combo 4
→ Combo becomes 5 first
→ MP recovery = (5 + 5 − 3) + 5 = 12 MP
→ player may later choose ATK/DEF/SUP; Combo 5 resolves that category’s Stage 5 unless an MP-shortage fallback shows a lower Stage, or retain Combo to improve a later CHAIN recovery.
```

This example describes approved CHAIN-038 intent, not current runtime behavior. At 60 MP, excess recovery has no conversion; at 10 Combo, excess Combo does not exceed the cap. Exact combat/MP technique tuning remains `TUNING_SEED_NOT_FINAL`.

### Current content slice

| Content ID | Purpose | Current evidence |
| --- | --- | --- |
| `CNT-VANGUARD` | Player combat identity and technique user. | Approved visual master and runtime cutout consumer; no biography beyond first-session immediate role. |
| `CNT-FRONTIER-GATE` | Immediate battleground and deployment context. | Current world-facing first-session fact; stage consumer is implemented. |
| `CNT-GATEBREAKER` | Enemy with readable forecast and combat phases. | Action/sequence seeds and runtime cutout/telegraph consumer exist. |
| `CNT-FRONTIER-GATEBREAKER-01` | The active vertical-slice encounter. | Title/briefing entry, direct continuous encounter, and same-encounter guided practice are implemented in the current worktree; target-resolution and Human evidence remain pending. |
| `CNT-COMBO-RESOLVED-TECHNIQUES` | ATK/DEF/SUP resolved from the player’s current Combo Stage 1–10. | Category/preview/confirm, bounded fallback and the C1–C10 content matrix are implemented in the current worktree; exact-head full verification remains required. |

## 4. UX, screen flow and first-time player learning

### Confirmed player flow

```mermaid
flowchart LR
  A[Title] --> B[Battle Briefing]
  B --> C[First visit: full rule review]
  C --> D[Explicit Deploy]
  D --> E[Safe live guided practice]
  E --> F[Same continuous battle]
  F --> G[Result / Retry]
  G --> H[Planned reward or route]
```

The current worktree starts at **A**, implements B–D, then enters E–F as one continuous battle. Safe guided practice E observes real reward/preview/CONFIRM evidence and releases to normal pressure without changing encounters.

| Surface | Consumer / state | Player goal | Necessary information and feedback |
| --- | --- | --- | --- |
| Title/Main Menu | `scenes/production/title.tscn` | Start with a clear promise. | Vanguard/Gatebreaker tension, one primary briefing action and re-openable core loop note. |
| Battle Briefing | `scenes/production/battle_briefing.tscn` | Understand where/why and what Deploy means. | Immediate threat plus complete critical rule review; acknowledgement enables Deploy. |
| Continuous Battle | `scenes/production/battle.tscn` | Select the right preparation under pressure. | Current Telegraph, next forecast, ETA, health, MP, Combo, active workspace and visible response. |
| Tactical Skill | Battle-owned `SkillFrame` | Compare category response versus saving Combo for later. | Same frozen threat/puzzle state, category→resolved Stage preview→CONFIRM; cancel returns to paused state. |
| Result/Retry | Existing retry plus planned `TETRIS-SREF-004` Result | Learn cause and choose a next action. | Outcome, causal feedback, retry; rewards/persistence unknown. |
| Codex/Manual | Planned `TETRIS-SREF-005` | Revisit a rule without loading battle with text. | Text/diagram explanation; no actual scene or content contract yet. |

### First session: short world explanation plus complete critical rules

The world explanation is intentionally minimal: **a Frontier Gate faces an immediate Gatebreaker threat; the Vanguard chooses to Deploy.** It must not invent factions, history, geography, named heroes or a larger narrative to make a short tutorial feel substantial.

Before a first Deploy, the user-approved rules disclose LINE MP recovery/cap, CHAIN’s all-axis 3+ match, Combo/shared resolved-Stage spend/cap, per-wave recovery, failed-swap restore or 1-MP lock/reset, the skill-only 5-MP-per-Combo shortage fallback, and tactical pause/explicit CONFIRM. In the live safe opening, the player then practices read threat → LINE reward → horizontal three-symbol CHAIN success → optional lock inspection → category preview → explicit CONFIRM → one unforced response. The first live ETA runs from Deploy but cannot terminally fail before the first explicit CONFIRM.

## 5. Visual direction and the Project Understanding Visual Pack

### Approved visual anchor

`TETRIS-VISUAL-043 · Obsidian Rift Tactics + Readable Puzzle Combat` is current. `VISUAL_BIBLE.md` owns the detailed repository visual contract. The latest user-directed references establish dark obsidian panels, antique-gold construction, contained violet-rift light, a dominant boss composition, a readable player face portrait and ornate Chain tiles as the battle language; their pictured legacy UI rules are not canon. `TETRIS-IMG-031`, `034`, `035`, `036`, the locked tile/portrait family `040`–`046`, and title logo `047` have named runtime consumers on this worktree. `TETRIS-IMG-033` remains retained but deliberately unbound until a distinct player-stage or loadout surface is approved.

| Layer | Keep | Avoid / Do Not Drift |
| --- | --- | --- |
| Global | Obsidian-black panels, antique-gold construction and contained violet-rift light; the board/ETA/resource state remains clearest | Decorative darkness, generic sci-fi glass, unreadable small text or excess VFX that competes with puzzle reading. |
| Character / environment | Frontier Vanguard silhouette, asymmetric Gatebreaker mass, central rift/stone frontier | Different-game character proportions, unrelated faction motifs, or lore not approved by the project. |
| UI / icon / VFX | Clean puzzle hierarchy; category seals reveal one resolved Combo-Stage preview; puzzle and ETA outrank backdrop | Dual-board sidecar, permanently expanded 3×6 skills/manual Tier buttons, image-only economy explanations, old turn rails or unconfirmed auto-cast. |
| Variation | Local threat/status/region differences may alter restrained rift, value and accent choices | Uniform sameness that erases functional region/status differences. |

### `PROJECT_CORE_SCENE_VISUAL_BOARD` — text legend owns exact meaning

![Project Core Scene Visual Board](/C:/Users/user/Documents/GitHub/Ninza/Tetris/docs/assets/reference/planned/tetris-project-core-scene-visual-board-v2.png)

`TETRIS-VIS-BOARD-002` is a **`USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`**. It records the historical `TETRIS-VISUAL-041` planning direction only. It has `runtime_consumer: NONE`, is not a project runtime asset, and has no Human/player UX PASS. The current runtime visual owner is `TETRIS-VISUAL-043`; the table below, not pixels, owns the exact rule meaning.

| Panel | Scene / screen | Player goal and action | Choice, feedback and flow | Fixed / unknown |
| --- | --- | --- | --- | --- |
| 1 | Frontier Gate / live combat context | Read Gatebreaker threat and ETA in the same field-manual composition as the board. | Context leads to current resource/board decision. | Wider lore is unknown. |
| 2 | CHAIN workspace | Swap two orthogonally adjacent symbols to make a straight line of three or more. | Combo and per-wave MP feedback establish a current Combo state. | All-axis/MP-lock/cap/formula are approved but runtime partial. |
| 3 | Tactical Skill | Pause, choose only ATK, DEF or SUP. | The chosen category opens one resolved current-Combo preview; selection is free. | `TETRIS-SKILL-039` documented, not implemented. |
| 4 | Resolved preview / confirm | Inspect one purpose, effect, target and resource result. | Explicit CONFIRM commits; no manual tier/card browse. | Legacy runtime still uses manual Tier 1–6. |
| 5 | MP-shortage fallback | Understand the lower stage before committing. | Surplus Combo converts at 5 MP each only to show the highest legal lower Stage. | Current design only; no runtime/data proof. |
| 6 | Return to threat | See impact and changed state before the live battle resumes. | The next telegraph starts the next Line/Chain/Skill decision. | Human learning, balance and fun unknown. |

### Generated visual workflow

Current user direction is `AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION`: do not pause to ask whether a bounded visual should be generated; generate it, inspect it against the current anchor and consumer (where applicable), then ask only whether to lock it. `TETRIS-VIS-BOARD-002` is now `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`.

Locking a planning board means **approved project planning reference**, not runtime asset, scene/UI implementation or human-readability proof. A runtime asset still requires its exact target `res://` path, scene/node consumer, geometry and import/use contract before generation, then user lock and runtime verification before promotion.

## 6. Actual Godot architecture and evidence

### Battle scene

`scenes/production/battle.tscn` provides one large `PuzzleColumn` (LINE/CHAIN/Skill mode buttons and `PuzzleHost`) and a persistent `CombatColumn`. The latter holds `ThreatPanel`, `CombatStage`, a visual-only `SharedActionFrame` driven by the active enemy ETA, resource state and `SkillFrame`.

`CombatStage` has current named texture consumers:

- `StageBackdrop` → `assets/production/backgrounds/fracture_frontier_combat_stage_v1.png`
- `GatebreakerReference` → `assets/production/bosses/gatebreaker_combat_cutout_v1.png`
- `VanguardAttackAccent` and `GatebreakerThreatTelegraph` → two bounded VFX textures

`CombatStage` is boss-only and clips its enlarged Gatebreaker to its own frame. The separate `ResourceRow/VanguardPortrait` uses `TETRIS-IMG-046`; it does not place a full-body player character in the enemy area. `SharedActionFrame` shows the same current `enemy_eta_seconds` that drives the telegraph as the player’s visual reaction window; it does not reintroduce a turn budget, READY, timeout, or PASS mechanic. These prove scene binding, not composition readability or art approval at a player’s target resolution.

### Runtime/data map

| Area | Actual paths | Verified scope |
| --- | --- | --- |
| Bootstrap and UI | `src/production/session/production_battle_bootstrap.gd`, `src/production/ui/production_battle.gd` | Construct and connect the production battle. |
| LINE | `src/production/line/**`, `data/production/line_*.json` | Persistent active LINE workspace and line reward seed. |
| CHAIN | `src/production/chain/**`, `data/production/chain_runtime_seed.json` | Active CHAIN board, orthogonal swaps, H/V/both-diagonal resolver, optional fixed 1 MP lock and per-wave Combo/MP recovery. Exact-HEAD full verification remains pending. |
| Combat/enemy | `src/production/combat/**`, `src/production/runtime/enemy_action_scheduler.gd`, `data/production/gatebreaker_*.json` | Forecasted Gatebreaker scheduling and responses. |
| Skill/pause | `src/production/skill/**`, `simulation_pause_*.gd`, `data/production/vanguard_skill_seed.json` | Full tactical pause, selection and explicit commit boundaries. |
| State boundary | `src/production/combat/production_combat_state.gd` | Current `energy`/`stock` internal fields, with `COMBO_CAP = 10` and bounded resource validation. Exact-HEAD full verification remains pending. |
| Persistence/audio | `manual_validation_tracker.gd`; `simulation_pause_bridge.gd` | Manual evidence file save and audio pause support only; no player save/profile or verified authored audio content. |

### Evidence ceiling

| Evidence | What it can support | What it cannot support |
| --- | --- | --- |
| Tooling/unit/scene contract tests | Structure, data values, node/resource references, explicit regression boundaries | Fun, comprehension, readability, balance or commercial appeal. |
| CI and scene-equivalent runtime render | A tested head can parse/load and consumes the named asset path | Player platform performance, final composition or Human approval. |
| Current project screenshots/reference images | Direction and planned screen composition | Runtime integration unless that exact file has a documented consumer. |
| Human first-exposure receipt | Understanding, legibility, tension and observable choice | General market demand without a separate study. |

## 7. Evidence-based SWOT

| Statement | Class | Evidence | Confidence | Player impact | Production impact | Disposition | Next validation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| The live telegraph + persistent two-workspace + full tactical-pause structure is specific and readable as a design contract. | `STRENGTH` | CORE-029, scene/code path and automated contracts. | `VERIFIED` for structure; not fun. | Gives a memorable decision vocabulary. | Focuses the slice. | `PROTECT` | Observe an uncoached first player. |
| The project now has a user-supplied dark tactical-combat reference and a concrete rule for what stays readable. | `STRENGTH` | `TETRIS-VISUAL-043`, user-provided combat/skill/character references and Visual Bible. | `PARTIAL` | Makes the intended mood, boss hierarchy and Skill detail hierarchy easier to distinguish. | Gives later art/UI work a narrower style target. | `PROTECT` | Inspect the target-resolution runtime composite and first-exposure readability after candidate assets are locked. |
| The new category preview/explicit-confirm presentation still has no exact-HEAD full runtime or Human/player evidence. | `WEAKNESS` | Current-worktree battle/UI/session sources and the evidence contract. | `VERIFIED` for the evidence gap. | Readability, timing pressure and the spend-or-save decision remain unproved. | Requires verification rather than another parallel Skill architecture. | `TEST` | Exact-head regression, target-resolution capture and first-exposure receipt. |
| The approved CHAIN economy is implemented in the current worktree but still awaits exact-HEAD full verification. | `WEAKNESS` | CHAIN-038, all-axis resolver, fixed 1 MP lock, Combo cap 10 and per-wave recovery sources. | `VERIFIED` for code presence; not runtime/UX validated. | Players have the intended choices in code, but their clarity and tuning are not yet proven. | Requires verification and focused tuning, not another CHAIN ruleset. | `TEST` | Exact-head regression and target-resolution first-play observation. |
| Human/player evidence is absent. | `WEAKNESS` | Human evidence index and reconciliation record. | `VERIFIED` | No reliable claim about comprehension, tension or balance. | Blocks safe polish prioritization. | `TEST` | Three first-exposure receipts at target resolution. |
| A concise explanation plus safe live practice can make the unusual economy marketable without a long lore layer. | `OPPORTUNITY` | Approved onboarding logic; inference, not market research. | `INFERENCE` | Could make the hook understandable in one session. | Reuses existing battle rather than creating a tutorial mode. | `TEST` | Compare comprehension after real onboarding runtime exists. |
| Earlier turn-era materials and open PRs can reintroduce obsolete terminology. | `THREAT` | Fresh conflict register and READ_ONLY open PR rule. | `VERIFIED` | Confuses player-facing UX and design intent. | Causes documentation/implementation churn. | `MITIGATE` | Fresh main + authority read before material work. |
| Planning images could be misrepresented as implementation. | `THREAT` | Reference/consumer contracts and this board’s no-consumer status. | `VERIFIED` | Creates false confidence. | Expands asset cost without usable runtime output. | `MONITOR` | Maintain explicit classification, destination and evidence ceiling. |

No market/competitor claim is made here: no material current market decision required an external research run for this synthesis.

## 8. Decisions, required work and implementation order

### Protected strengths and scope boundaries

- Protect the single large puzzle surface, free persistent LINE↔CHAIN switching, LINE-owned MP / CHAIN-owned Combo, readable ETA/telegraph, full tactical pause and explicit CONFIRM.
- Do not revive ordered turn rails, shared turn budgets, READY/timeout/PASS/Tempo, a dual-board sidecar, unreadable decorative darkness, unconfirmed auto-cast, manual Tier buttons or a permanently expanded skill matrix.
- Do not add route maps, save/profile, workshop/meta, broader lore, production image batches or CHAIN implementation under this documentation issue.

### Remaining required work, in dependency order

1. **Exact-HEAD verification gate:** run the full deterministic/runtime suite against the current worktree, then inspect the title, briefing, 50/50 battle, Chain feedback and category preview at target resolution.
2. **Human evidence gate:** observe first exposure. Validate threat reading, LINE→MP versus CHAIN→Combo, Combo spend-or-save, Skill/CONFIRM commitment and failure/retry causality.
3. **Verify the safe guided practice at target resolution:** the same-encounter triggers and non-terminal pre-CONFIRM guard are implemented; confirm the live ETA, prompt hierarchy, and unforced handoff with runtime and first-exposure evidence before tuning it.
4. **Correct evidence-backed UX problems:** prioritize by player value/risk, not by a generic feature list.
5. **Then evaluate session closure/meta:** result reward, route, loadout, save/profile and Codex/Manual only if core-loop evidence supports expansion.

### Historical fresh technical feasibility preflight — 2026-08-28

This snapshot records the pre-implementation starting point. It is retained as `HISTORICAL` feasibility evidence and does not override the current-worktree implementation/evidence status above.

| Question | Fresh evidence | Result and required boundary |
| --- | --- | --- |
| Can category-only selection and explicit confirmation fit the current UI architecture? | `production_battle.gd` already connects three category Buttons and a Use Button through Godot signals; the current [Godot Signals documentation](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html) describes that event model. | `FEASIBLE`. Remove the legacy TierGrid path only inside the later approved Phase 2 contract; it is not changed by this documentation issue. |
| Can the current tactical-pause session preserve preview-before-spend and atomic confirm? | `ProductionSkillSession` already separates category selection, selected detail, readiness and `commit_selected`, with a rollback path when resolution fails. | `PARTIAL`. The later resolver must make conversion + spend one derived transaction and prove that MP cap clipping/rollback cannot mutate preview or cancel. |
| Does the authored skill data support the current Combo Stage 1–10 promise? | `vanguard_skill_seed.json` has 18 legacy lane × Tier 1–6 entries; `ProductionSkillCatalog` rejects `tier > 6`. Godot [Resources documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) confirms project-owned data can remain validated data containers, but it does not create missing content. | `BLOCKED_UNVERIFIED` for implementation readiness until the user-approved Stage 7–10 effects/costs are authored and a data validator accepts them. No engine/add-on purchase or external service is required. |
| Does the current CHAIN resource implementation already support the Stage promise? | Fresh code/canon comparison: merged runtime still has Combo/Stock cap 6 and the legacy CHAIN reward model while the current promise requires cap 10, diagonal matching, MP lock and per-wave recovery. | `PARTIAL`. CHAIN-038 alignment is a prerequisite for a truthful integrated Stage 1–10 experience; do not call the Skill flow complete before that Phase 2 sequence passes exact-head tests and target-device runtime validation. |

The preflight is implementation-feasibility evidence, not a runtime/UX pass. The required ongoing process is `MANDATORY_CURRENT_TASK_EVIDENCE_GATE`: fresh project truth, targeted current official research, feasibility classification, five full adversarial loops and exact destination/head readback for every material task.

### Incident / Solution / Lesson

- **Incident:** the previous image contract asked for pre-generation approval, while the user’s current workflow direction is generate-first and lock-after-inspection. That timing conflict would slow visual review and leave future agents uncertain.
- **Solution:** `TETRIS-IMAGE-030` now records `AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION`. Runtime consumer-first requirements remain non-negotiable, and generated explorations remain non-runtime until explicitly locked and integrated.
- **Lesson:** `NO_BASE_PROMOTION`. The timing preference is a project/user collaboration policy; it is not evidence that every project should bypass its own art-production approval gate.

## 9. Validation and change log

### Validation required for this GDD change

- Parse/read the canonical JSON and planned screen-reference manifest.
- Run focused Master GDD, production-canon, screen inventory and runtime-image contract checks on the exact PR head.
- Read back the GitHub commit/PR, the repository Visual Bible, and the visual manifest after the documentation is merged.

### Current change log

| Date | Change | Classification |
| --- | --- | --- |
| 2026-08-28 | Added this reader-oriented Master GDD from fresh current sources. | `CURRENT SYNTHESIS` |
| 2026-08-28 | Stored `TETRIS-VIS-BOARD-001` with visual text legend and provenance. | `GENERATED_EXPLORATION / SUPERSEDED_BY_TETRIS-VIS-BOARD-002` |
| 2026-08-28 | Reconciled image workflow to generate first and ask only for user lock confirmation, preserving exact runtime consumer requirements. | `CURRENT USER WORKFLOW` |
| 2026-08-28 | Corrected current Skill grammar to `ATK/DEF/SUP → Combo-Resolved preview → explicit CONFIRM`; added a 5-MP-per-Combo bounded shortage fallback and recorded the legacy runtime/data conflict. | `TETRIS-SKILL-039 / TETRIS-BALANCE-040 / DOCUMENTED_NOT_IMPLEMENTED` |
| 2026-08-28 | Replaced the global planning visual direction with parchment field-manual, sepia ink and watercolor violet rift; old generated board superseded by v2 pending user lock. | `TETRIS-VISUAL-041 / GENERATED_EXPLORATION_NOT_RUNTIME` |
| 2026-09-01 | Superseded the historical parchment direction with the latest user-directed obsidian/gold/violet combat presentation; recomposed existing boss/portrait consumers and restored a visible non-interactive C1–C10 Skill detail surface. | `TETRIS-VISUAL-043 / IMPLEMENTED_IN_CURRENT_WORKTREE_PENDING_FULL_VERIFICATION` |
| 2026-08-28 | User locked v2 as a planning-only visual reference and added the mandatory fresh-read/research/feasibility/five-loop evidence gate. | `TETRIS-VIS-BOARD-002 / USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME / ISSUE-78` |
| 2026-08-28 | User approved intentional lower-Combo casting, target-separated player board-time / enemy current-ETA semantics and the C1–C10 content matrix; recorded the current implementation gap. | `TETRIS-SKILL-042 / ISSUE-80 / USER_APPROVED / DOCUMENTED_NOT_IMPLEMENTED` |

### Rollback

Reverting this documentation change removes the Master GDD, board reference record and image workflow amendment. It must not delete approved reference masters, runtime production assets, historical provenance or user-owned untracked Godot import/UID files.
