# Tetris · Master GDD

- Status: `CURRENT_READER_GDD / CANONICAL_SYNTHESIS`, Issue #72; current visual-lock/evidence-gate correction tracked in Issue #78
- Fresh source snapshot: `origin/main` `f84939d0be5d7c248201628bc88bb7f7c6640fe1`, read 2026-08-29. It retains the prior gameplay snapshot `dec60706ab8fcec3986b01f279d9d60080a309f8` and the Master-GDD/visual-workflow snapshot `59c537f29ed0bebed8d40be5cecfd6ff5b89318b` as provenance.
- Purpose: make the currently approved game intelligible in one place without replacing the documents and runtime evidence that own individual facts.
- Reader rule: a rule may be **approved** yet not be **implemented**; an implemented system may be automated-tested yet not be **Human/player validated**. This document preserves those distinctions.
- Current owner rule: GitHub repository documents, GitHub issue/PR history, and runtime evidence are the sole current project owners. Notion is `HISTORICAL_EXTERNAL_PROVENANCE_ONLY`; do not read, write, sync, or require it for current work.

> This is a navigation and synthesis owner, not a license to overwrite detailed owners. When a detailed source and this GDD disagree, resolve it at the detailed owner, correct this synthesis, and record the conflict.

## 1. Source registry and authority

| Owner | What it owns | Fresh-read state |
| --- | --- | --- |
| `docs/design/PRODUCTION_CANON_INDEX.json` | Current decision IDs, authority order, machine-readable current/actual boundary | `CURRENT` |
| `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` | `TETRIS-CORE-029`: continuous battle, workspace and pause grammar | `CURRENT` |
| `docs/design/CHAIN_COMBO_MP_CONTRACT.md` | `TETRIS-CHAIN-038`: CHAIN match, MP lock, Combo and recovery formula | `CURRENT` |
| `docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md` and `COMBO_STAGE_SKILL_CONTENT_GDD.md` | `TETRIS-SKILL-039` / `TETRIS-BALANCE-040` / `TETRIS-SKILL-042`: category-only preview/confirm, bounded fallback and the target-separated 12-second board-opportunity mechanism | `CURRENT / IMPLEMENTED_MACHINE_VERIFIED_PENDING_RUNTIME_AND_HUMAN_EVIDENCE` |
| `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` and `DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` | Older manual Tier matrix and its cost grammar | `SUPERSEDED_FOR_CURRENT_SELECTION_FLOW / HISTORICAL_EFFECT_PROVENANCE` |
| `docs/design/FIRST_SESSION_ONBOARDING_CONTRACT.md` | `TETRIS-ONBOARDING-037`: briefing and safe live tutorial | `IMPLEMENTED_MACHINE_VERIFIED / RUNTIME_AND_HUMAN_PENDING` |
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
| `RESOLVED_IMPLEMENTATION_GAP` | CHAIN required both diagonals, a 1-MP lock, MP 60, Combo 10 and a per-wave formula. | `TETRIS-CHAIN-038` now has `CHAIN_RESOURCE_ALIGNMENT_IMPLEMENTED_MACHINE_VERIFIED`; target-device, balance and Human evidence remain `NOT_RUN`. |
| `RESOLVED_IMPLEMENTATION_GAP` | Old current documents exposed manual `ATK/DEF/SUP × T1–T6`; the user-directed flow is category-only, current-Combo preview, explicit confirm and a bounded 5-MP fallback. | `TETRIS-SKILL-039` / `TETRIS-BALANCE-040` now run through one resolved preview and atomic CONFIRM. Target-device and Human evidence remain `NOT_RUN`. |
| `CONFLICT` | Current runtime backgrounds/cutouts use a dark pixel-rendered combat treatment, while the current user reference requires a parchment field-manual presentation. | `TETRIS-VISUAL-041` supersedes the global planning direction. Existing image consumers remain preserved until a separately contracted runtime art pass. |
| `RESOLVED_IMPLEMENTATION_GAP` | The approved first session requires briefing → Deploy → short guided live practice → same encounter. | `BattleBriefing`, one-bit review completion, 45-second live safe opening and first-CONFIRM handoff are machine verified; Human/player evidence is `NOT_RUN`. |
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
| 2. Representative continuous-battle slice | `IMPLEMENTED / PARTIAL` | 50/50 battle, persistent workspaces, scheduler, pause, skill and named art consumers exist. CHAIN-038 and onboarding remain incomplete. |
| 3. Human usability / player experience | `NOT_RUN` | The immediate required validation gate: target-resolution capture and first-exposure observation. |
| 4. First-session and session-completion loop | `DESIGNED / NOT_IMPLEMENTED` | Briefing/tutorial is approved; result/reward/route/meta remain planned. |
| 5. Production expansion and polish | `DEFERRED` | Start only after Stage 3 evidence identifies the smallest necessary correction. |

**Active Playable Slice:** `scenes/production/battle_briefing.tscn` → one Gatebreaker encounter in `scenes/production/battle.tscn`, with full-rule first-visit gating, live LINE/CHAIN/telegraph/ETA, tactical Skill pause and retry. Its target-device visual and Human learning evidence remain `NOT_RUN`.

## 3. Core loop, systems and content

### Core, session and meta loops

| Loop | Status | Player flow |
| --- | --- | --- |
| Core combat loop | `CURRENT / IMPLEMENTED BASELINE` | Read ETA → choose LINE/CHAIN → gain/prep resource → pause for deliberate Technique commitment → resolve response → read next ETA. |
| Intended first-session loop | `IMPLEMENTED / MACHINE_VERIFIED` | Short Vanguard/Frontier Gate/Gatebreaker threat explanation → full economy-critical rule review → Deploy → safe live guided practice → seamless normal battle → result/retry. Human understanding remains `NOT_RUN`. |
| Full-session loop | `PARTIAL` | Planned title/loadout/route/briefing/battle/result surfaces exist as references; no route, persistence or reward data is implemented. |
| Progression/meta loop | `UNKNOWN_UNVERIFIED` | Route, workshop, persistent reward, unlock and long-run motivation must not be inferred from planned screen references. |

### System contract register

| System | Player-facing rule | Approved / actual state | Implementation owner |
| --- | --- | --- | --- |
| `SYS-CORE-029` Continuous battle | Enemy time runs after Deploy; encounter ends at victory/defeat; no old turn rail. | `CURRENT`; direct-entry realtime runtime is implemented. | `src/production/runtime/production_combat_runtime.gd`, scheduler and battle scene. |
| `SYS-LINE-MP` | LINE no clear/Single/Double/Triple/Four gains `0/10/22/36/52 MP`; cap 60. | Rule and hard cap are implemented and machine-verified; balance and target-device evidence are not yet available. | `data/production/line_reward_seed.json`, line session/state. |
| `SYS-CHAIN-038` | Orthogonal adjacent swap; straight 3+ horizontal/vertical/diagonal matching. Failed swap restores, or fixed 1 MP locks a setup. | `IMPLEMENTED / MACHINE_VERIFIED`; deterministic board/session and visible decision prompt are covered. | `chain_board.gd`, `chain_resolver.gd`, `production_chain_session.gd`, `production_battle.gd`. |
| `SYS-COMBO-MP` | Each resolution wave grants Combo +1 (cap 10), then MP = `(sum maximal qualified line lengths − 3) + post-wave Combo`. | `IMPLEMENTED / MACHINE_VERIFIED`; each wave commits once and cap overflow is explicit. Balance and Human evidence remain unverified. | CHAIN contract and `ProductionCombatState`. |
| `SYS-SKILL-039 / SKILL-042` | Skill fully pauses; choose ATK/DEF/SUP only, inspect the current Combo-resolved Stage, then explicitly CONFIRM. If MP is short, surplus Combo converts at 5 MP each to the highest feasible lower Stage. Player board opportunity and current enemy ETA remain target-separated. | `IMPLEMENTED_MACHINE_VERIFIED`; C1–C10 category preview, bounded fallback, all-or-nothing owner rollback, one explicit confirm and the four-second changed/unchanged timing feedback are covered by automated tests. Target-device and Human evidence are `NOT_RUN`. | `production_skill_session.gd`, `production_technique_resolver.gd`, `production_combat_runtime.gd`, `production_battle.gd`. |
| `SYS-ENEMY` | Gatebreaker telegraph and ETA tell the player what is imminent. | `IMPLEMENTED` scheduling/preview; readability and tuning unknown. | `gatebreaker_*`, realtime timing/action/sequence seed. |
| `SYS-ONBOARDING-037` | Full rules before first Deploy; then short safe live practice in the actual encounter. | `IMPLEMENTED_MACHINE_VERIFIED`; one-bit review completion, re-openable reference and one-shot 45-second/nonterminal handoff exist. | `battle_briefing.tscn`, first-session state, bootstrap, runtime and battle UI. |
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
| `CNT-FRONTIER-GATEBREAKER-01` | The active vertical-slice encounter. | `BattleBriefing` opens the intended first session, then Deploy reaches the same current Gatebreaker encounter. |
| `CNT-COMBO-RESOLVED-TECHNIQUES` | ATK/DEF/SUP resolved from the player’s current Combo Stage 1–10. | Current category preview/explicit confirm, bounded fallback and C1–C10 content are machine verified; Tier 1–6 remains historical effect provenance only. |

## 4. UX, screen flow and first-time player learning

### Confirmed player flow

```mermaid
flowchart LR
  A[Planned Title] --> B[Battle Briefing]
  B --> C[First visit: full rule review]
  C --> D[Explicit Deploy]
  D --> E[Safe live guided practice]
  E --> F[Same continuous battle]
  F --> G[Result / Retry]
  G --> H[Planned reward or route]
```

The implemented vertical slice presently starts at **B**, not at A. Title, setup, route and meta remain planned; this is an intentional evidence distinction, not a missing detail to invent.

| Surface | Consumer / state | Player goal | Necessary information and feedback |
| --- | --- | --- | --- |
| Title/Main Menu | Planned `TETRIS-SREF-001`, future Title scene | Start with a clear promise. | Vanguard/Gatebreaker tension, one primary start action. |
| Battle Briefing | `scenes/production/battle_briefing.tscn` | Understand where/why and what Deploy means. | Only Vanguard, Frontier Gate, Gatebreaker and immediate threat; first visit requires the complete rule review. |
| Continuous Battle | `scenes/production/battle.tscn` | Select the right preparation under pressure. | Current Telegraph, next forecast, ETA, health, MP, Combo, active workspace and visible response. |
| Tactical Skill | Battle-owned `SkillFrame` | Compare category response versus saving Combo for later. | Same frozen threat/puzzle state, category→resolved Stage preview→CONFIRM; cancel returns to paused state. |
| Result/Retry | Existing retry plus planned `TETRIS-SREF-004` Result | Learn cause and choose a next action. | Outcome, causal feedback, retry; rewards/persistence unknown. |
| Codex/Manual | Planned `TETRIS-SREF-005` | Revisit a rule without loading battle with text. | Text/diagram explanation; no actual scene or content contract yet. |

### First session: short world explanation plus complete critical rules

The world explanation is intentionally minimal: **a Frontier Gate faces an immediate Gatebreaker threat; the Vanguard chooses to Deploy.** It must not invent factions, history, geography, named heroes or a larger narrative to make a short tutorial feel substantial.

Before a first Deploy, the user-approved rules disclose LINE MP recovery/cap, CHAIN’s all-axis 3+ match, Combo/shared resolved-Stage spend/cap, per-wave recovery, failed-swap restore or 1-MP lock/reset, the skill-only 5-MP-per-Combo shortage fallback, and tactical pause/explicit CONFIRM. In the live safe opening, the player then practices read threat → LINE reward → horizontal three-symbol CHAIN success → optional lock inspection → category preview → explicit CONFIRM → one unforced response. The first live ETA runs from Deploy but cannot terminally fail before the first explicit CONFIRM.

## 5. Visual direction and the Project Understanding Visual Pack

### Approved visual anchor

`TETRIS-VISUAL-041 · Parchment Field Manual + Readable Puzzle Tactics` is current. `VISUAL_BIBLE.md` owns the detailed repository visual contract. The user-provided comparison established warm ivory parchment, sepia ink and watercolor violet rift as the planning style; its pictured old UI rules are not canon. Current runtime visual evidence (`TETRIS-IMG-031`, `033`, `034`, `035`, `036`) remains preserved dark/pixel consumer evidence only, not proof that the new presentation is implemented.

| Layer | Keep | Avoid / Do Not Drift |
| --- | --- | --- |
| Global | Warm ivory parchment, sepia ink, field-note construction marks and watercolor violet rift; the board/ETA/resource state remains clearest | Dark metal-card density, pixel/CRT treatment, generic sci-fi HUD or decoration that competes with puzzle reading. |
| Character / environment | Frontier Vanguard silhouette, asymmetric Gatebreaker mass, central rift/stone frontier | Different-game character proportions, unrelated faction motifs, or lore not approved by the project. |
| UI / icon / VFX | Clean puzzle hierarchy; category seals reveal one resolved Combo-Stage preview; puzzle and ETA outrank backdrop | Dual-board sidecar, permanently expanded 3×6 skills/manual Tier buttons, image-only economy explanations, old turn rails or unconfirmed auto-cast. |
| Variation | Local threat/status/region differences may alter restrained rift, value and accent choices | Uniform sameness that erases functional region/status differences. |

### `PROJECT_CORE_SCENE_VISUAL_BOARD` — text legend owns exact meaning

![Project Core Scene Visual Board](/C:/Users/user/Documents/GitHub/Ninza/Tetris/docs/assets/reference/planned/tetris-project-core-scene-visual-board-v2.png)

`TETRIS-VIS-BOARD-002` is a **`USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`**. It is generated from `TETRIS-VISUAL-041` to test whether the category-resolved Skill flow is understandable. It has `runtime_consumer: NONE`, is not a project runtime asset, and has no Human/player UX PASS. The image intentionally avoids relying on pseudo-text; the table below, not pixels, owns the exact rule meaning. `TETRIS-VIS-BOARD-001` is superseded because it did not make the right style or the new flow legible.

| Panel | Scene / screen | Player goal and action | Choice, feedback and flow | Fixed / unknown |
| --- | --- | --- | --- | --- |
| 1 | Frontier Gate / live combat context | Read Gatebreaker threat and ETA in the same field-manual composition as the board. | Context leads to current resource/board decision. | Wider lore is unknown. |
| 2 | CHAIN workspace | Swap two orthogonally adjacent symbols to make a straight line of three or more. | Combo and per-wave MP feedback establish a current Combo state; a no-match offers a visible 1-MP keep-or-revert choice. | CHAIN/resource behavior is machine-verified; target-resolution readability and balance are unknown. |
| 3 | Tactical Skill | Pause, choose only ATK, DEF or SUP. | The chosen category opens one resolved current-Combo preview; selection is free. | `TETRIS-SKILL-039` is implemented and machine-verified; target-device and Human evidence remain pending. |
| 4 | Resolved preview / confirm | Inspect one purpose, effect, target and resource result. | Explicit CONFIRM commits; no manual tier/card browse. | Category-only preview, atomic confirmation and rollback are implemented and machine-verified. |
| 5 | MP-shortage fallback | Understand the lower stage before committing. | Surplus Combo converts at 5 MP each only to show the highest legal lower Stage. | C1–C10 fallback runtime is implemented and machine-verified; balance and Human evidence remain pending. |
| 6 | Return to threat | See impact and changed state before the live battle resumes. | The next telegraph starts the next Line/Chain/Skill decision. | Human learning, balance and fun unknown. |

### Generated visual workflow

Current user direction is `USER_STANDING_IMAGE_APPROVAL_2026-09-02`: do not pause to ask whether a necessary bounded visual should be generated or separately locked. Generate it, inspect it against the current anchor and consumer (where applicable), preserve earlier approved sources, and record exact provenance. `TETRIS-VIS-BOARD-002` remains a historical `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`.

The older planning-board lock remains a planning-reference classification, not runtime asset, scene/UI implementation or human-readability proof. A runtime asset still requires its exact target `res://` path, scene/node consumer, geometry and import/use contract before generation, then inspected versioned registration, scene binding and runtime verification before promotion.

## 6. Actual Godot architecture and evidence

### Battle scene

`scenes/production/battle.tscn` provides a balanced 50/50 `PuzzleColumn` (LINE/CHAIN/Skill mode buttons and `PuzzleHost`) and persistent `CombatColumn`. The latter holds `ThreatPanel`, a boss-dominant `CombatStage`, a shared action-timer presentation, Vanguard resource HUD and `SkillFrame`.

`CombatStage` has current named texture consumers:

- `StageBackdrop` → `assets/production/backgrounds/fracture_frontier_combat_stage_v1.png`
- `VanguardPortrait` → `assets/production/characters/vanguard_combat_cutout_v1.png` as an AtlasTexture HUD portrait in `ResourceRow`
- `GatebreakerReference` → `assets/production/bosses/gatebreaker_combat_cutout_v1.png` as the boss-focused AtlasTexture crop in `CombatStage`
- `VanguardAttackAccent` and `GatebreakerThreatTelegraph` → two bounded VFX textures

These prove scene binding, not composition readability or art approval at a player’s target resolution.

### Runtime/data map

| Area | Actual paths | Verified scope |
| --- | --- | --- |
| Bootstrap and UI | `src/production/session/production_battle_bootstrap.gd`, `src/production/ui/production_battle.gd` | Construct and connect the production battle. |
| LINE | `src/production/line/**`, `data/production/line_*.json` | Persistent active LINE workspace and line reward seed. |
| CHAIN | `src/production/chain/**`, `data/production/chain_runtime_seed.json` | Active all-axis CHAIN board, deterministic resolver/session snapshots and board-generation seed without legacy depth rewards. |
| Combat/enemy | `src/production/combat/**`, `src/production/runtime/enemy_action_scheduler.gd`, `data/production/gatebreaker_*.json` | Forecasted Gatebreaker scheduling and responses. |
| Skill/pause | `src/production/skill/**`, `simulation_pause_*.gd`, `data/production/vanguard_skill_seed.json` | Full tactical pause, selection and explicit commit boundaries. |
| State boundary | `src/production/combat/production_combat_state.gd` | Internal `energy` / `stock` fields expose player-facing MP 60 / Combo 10 and atomic CHAIN-wave / shortage-transaction operations. |
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
| The project now has a user-supplied parchment/ink/watercolor reference and a concrete rule for what stays readable. | `STRENGTH` | `TETRIS-VISUAL-041`, two user-provided comparison images and Visual Bible. | `PARTIAL` | Makes the intended mood and UI hierarchy easier to distinguish. | Gives later art/UI work a narrower style target. | `PROTECT` | Inspect the new planning board, then target-resolution runtime composite after a consumer-specific art pass. |
| The category Skill grammar is implemented, but target-resolution visual hierarchy and player readability are unobserved. | `WEAKNESS` | Fresh merged `production_battle.gd`, skill catalog/seed, actual runtime image files versus SKILL-039/VISUAL-041. | `MACHINE_VERIFIED`; target-device/Human evidence not run. | The current player-facing hierarchy may still need correction after observation. | Preserve mechanics and prioritize bounded presentation evidence before new feature expansion. | `TEST` | Capture target-resolution category preview/confirm and observe first exposure. |
| The CHAIN resource implementation now matches its core board/economy promise, but its player-facing readability and balance have not been observed. | `PARTIAL_STRENGTH` | All-axis board/session/resource/UI prompt tests and the Phase 2 PR-A implementation. | `MACHINE_VERIFIED`; not Human-verified. | Players can use the promised all-axis/setup/combo strategy in source/runtime logic. | Preserves a bounded next step: target-resolution observation before balance changes. | `TEST` | Capture and observe the actual prompt, rewards and overflow state at target resolution. |
| Human/player evidence is absent. | `WEAKNESS` | Human evidence index and reconciliation record. | `VERIFIED` | No reliable claim about comprehension, tension or balance. | Blocks safe polish prioritization. | `TEST` | Three first-exposure receipts at target resolution. |
| A concise explanation plus safe live practice can make the unusual economy marketable without a long lore layer. | `OPPORTUNITY` | Approved onboarding logic; inference, not market research. | `INFERENCE` | Could make the hook understandable in one session. | Reuses existing battle rather than creating a tutorial mode. | `TEST` | Compare comprehension after real onboarding runtime exists. |
| Earlier turn-era materials and open PRs can reintroduce obsolete terminology. | `THREAT` | Fresh conflict register and READ_ONLY open PR rule. | `VERIFIED` | Confuses player-facing UX and design intent. | Causes documentation/implementation churn. | `MITIGATE` | Fresh main + authority read before material work. |
| Planning images could be misrepresented as implementation. | `THREAT` | Reference/consumer contracts and this board’s no-consumer status. | `VERIFIED` | Creates false confidence. | Expands asset cost without usable runtime output. | `MONITOR` | Maintain explicit classification, destination and evidence ceiling. |

No market/competitor claim is made here: no material current market decision required an external research run for this synthesis.

## 8. Decisions, required work and implementation order

### Protected strengths and scope boundaries

- Protect the single large puzzle surface, free persistent LINE↔CHAIN switching, LINE-owned MP / CHAIN-owned Combo, readable ETA/telegraph, full tactical pause and explicit CONFIRM.
- Do not revive ordered turn rails, shared turn budgets, READY/timeout/PASS/Tempo, a dual-board sidecar, dark metal-card/pixel/CRT style, unconfirmed auto-cast, manual Tier buttons or a permanently expanded skill matrix.
- Do not add route maps, save/profile, workshop/meta, broader lore, production image batches or CHAIN implementation under this documentation issue.

### Remaining required work, in dependency order

1. **Human evidence gate:** capture the current runtime at target resolution and observe first exposure. Validate threat reading, LINE→MP versus CHAIN→Combo, Combo spend-or-save, Skill/USE commitment and failure/retry causality.
2. **Correct evidence-backed UX problems:** prioritize by player value/risk, not by a generic feature list; do not label a device or Human observation as machine proof.
3. **Then evaluate session closure/meta:** result reward, route, loadout, save/profile and Codex/Manual only if core-loop evidence supports expansion.

### Fresh technical feasibility preflight — 2026-08-28

| Question | Fresh evidence | Result and required boundary |
| --- | --- | --- |
| Can category-only selection and explicit confirmation fit the current UI architecture? | `production_battle.gd` wires three category buttons to one preview, explicit `ConfirmButton`, `CancelButton` and target-separated feedback. | `IMPLEMENTED_MACHINE_VERIFIED`; TierGrid/manual selection is absent. Target-device readability remains `NOT_RUN`. |
| Can tactical pause preserve preview-before-spend and atomic confirm? | `ProductionSkillSession` preflights before spend, captures checked resource/effect checkpoints, and returns `ROLLBACK_FAILED` without closing tactical pause when a checked restore fails. | `IMPLEMENTED_MACHINE_VERIFIED`; a failing action rollback is covered by automated tests, while player comprehension remains `NOT_RUN`. |
| Does authored C1–C10 data support the current Combo promise? | `vanguard_skill_seed.json` has 30 lane/stage entries and `ProductionSkillCatalog` resolves legal action variants. | `IMPLEMENTED_MACHINE_VERIFIED`; no engine/add-on purchase or external service was introduced. |
| Does the CHAIN resource implementation support the stage promise? | `ChainBoard`, resolver/session, `ProductionCombatState`, runtime bridge and battle prompt implement diagonal matching, fixed MP lock, per-wave recovery, MP 60 and Combo 10 with deterministic tests. | `MACHINE_VERIFIED` prerequisite and Skill/onboarding integration are implemented; target-device runtime validation remains separate. |

The preflight is implementation-feasibility evidence, not a runtime/UX pass. The required ongoing process is `MANDATORY_CURRENT_TASK_EVIDENCE_GATE`: fresh project truth, targeted current official research, feasibility classification, five full adversarial loops and exact destination/head readback for every material task.

### Incident / Solution / Lesson

- **Incident:** the previous image contract asked for pre-generation approval, while the user’s current workflow direction is generate-first and lock-after-inspection. That timing conflict would slow visual review and leave future agents uncertain.
- **Solution:** `TETRIS-IMAGE-030` first recorded `AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION`; the newer `USER_STANDING_IMAGE_APPROVAL_2026-09-02` removes the per-candidate lock request while preserving runtime consumer, provenance, scene-binding and evidence gates.
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
| 2026-08-28 | User locked v2 as a planning-only visual reference and added the mandatory fresh-read/research/feasibility/five-loop evidence gate. | `TETRIS-VIS-BOARD-002 / USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME / ISSUE-78` |
| 2026-08-28 | User approved intentional lower-Combo casting, target-separated player board-time / enemy current-ETA semantics and the C1–C10 content matrix; recorded the current implementation gap. | `TETRIS-SKILL-042 / ISSUE-80 / USER_APPROVED / DOCUMENTED_NOT_IMPLEMENTED` |
| 2026-09-01 | Implemented CHAIN all-axis matching, per-wave Combo/MP recovery, MP 60 / Combo 10 caps, the 1-MP keep-or-revert prompt and atomic resource bridge. | `TETRIS-CHAIN-038 / IMPLEMENTED_MACHINE_VERIFIED / BALANCE_AND_HUMAN_EVIDENCE_NOT_RUN` |
| 2026-09-01 | Replaced legacy Skill seed data with validated C1–C10 lane/stage definitions and adaptive current-threat packages; the player-facing resolver remains pending. | `TETRIS-SKILL-039 / PARTIALLY_IMPLEMENTED_DATA_ONLY / MACHINE_VERIFIED` |
| 2026-09-01 | Implemented the capped LINE-only board-opportunity reserve and exact-current-ETA adjustment, with full scheduler delta preserved and temporary Skill-executor wiring. | `TETRIS-SKILL-042 / PARTIALLY_IMPLEMENTED_DATA_AND_TIME_PRIMITIVES / MACHINE_VERIFIED` |
| 2026-09-02 | Replaced manual Tier selection with category-only Combo preview/atomic confirm, then added BattleBriefing, one-bit rule review and a safe real-time first-session handoff. | `TETRIS-SKILL-039 / TETRIS-BALANCE-040 / TETRIS-SKILL-042 / TETRIS-ONBOARDING-037 / IMPLEMENTED_MACHINE_VERIFIED_PENDING_RUNTIME_AND_HUMAN_EVIDENCE` |
| 2026-09-02 | Reconciled the human-facing visual legend with the merged category-only Skill runtime and adopted user-standing approval for necessary bounded images; consumer/provenance/runtime evidence gates remain separate. | `TETRIS-IMAGE-030 / USER_STANDING_IMAGE_APPROVAL_2026-09-02 / CURRENT SYNTHESIS` |

### Rollback

Reverting this documentation change removes the Master GDD, board reference record and image workflow amendment. It must not delete approved reference masters, runtime production assets, historical provenance or user-owned untracked Godot import/UID files.
