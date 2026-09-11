# R2 implementation plan and evidence

> For agentic workers: use superpowers:subagent-driven-development task-by-task. Project authority overrides generic skill ceremony. Exactly two complete final review loops; scoped task/fix reviews are not additional full loops.

**Goal:** Make the reviewed R2 first encounter playable without replacing the preserved production baseline.

**Architecture:** Isolated `src/replanned_r2` and `scenes/replanned_r2` consumers. Pure deterministic combat and puzzle models drive a separate Control scene; animation never owns damage. Reuse production LINE geometry/rotation, not its MP economy or production CHAIN diagonal matching.

**Tech stack:** Godot 4.7.1, existing GUT 9.7.1, HiGodot 3.2.0 persistent authoring, existing candidate PNG atlases.

**Spec:** `docs/design/REPLANNING_AUTOCAST_R2.md`, `docs/design/R2_COMPLETE_HUMAN_BLUEPRINT.md`, `docs/design/r2-complete-session.json`, `docs/design/autocast-r2-data.json` at `7340c7f1216b190f91264149e69c1304cbdc6c42`.

## Global constraints and authority

- Latest user `좋아 진행해` continues the completed blueprint handoff into implementation. This does not confer runtime, Human, balance or release approval.
- Existing production scenes/rules/assets, six unrelated draft PRs and historical PDF bytes are preserved. No automatic main-scene replacement.
- Base 9.4.4 stays pinned. No additional paid dependency or new authoring bridge.
- Persistent Godot writes use the existing project-dedicated HiGodot endpoint, not the app connector currently attached to other projects.
- LINE gives A/D/H/T rewards; CHAIN gives no direct tile resources and one automatic selected-category cast per simultaneous clear wave. No MP/manual USE/CONFIRM.
- One current boss ETA; next is order forecast only. Pause stops all simulation. Boss lethal damage wins over same-tick healing. Fixed 300000 microseconds per CHAIN wave.
- ATK `[4,6,8,11,14,18]` plus bank once; DEF max ward `[3,5,7,10,13,17]` tied to current uncommitted damaging action; SUP `[2,3,4,5,7,9]` capped healing.
- Left/right 50:50, one visible board, large transparent boss and 96px face. Reuse approved package images; do not generate substitute art.
- Save R2 separately, whole-state atomic stable boundaries only; never reinterpret baseline saves.

## Preflight and rulings

Start main and origin/main: `7340c7f1216b190f91264149e69c1304cbdc6c42`. Open draft PR100/85/46/33/23/19 read only, no overlap absorption.

| Current comparison/source | Observed pattern | Disposition / fit / risk |
| --- | --- | --- |
| Production LineBoard, ActiveTetromino, TetrominoCatalog, SevenBag | Existing collision, SRS-like kick data, HOLD cycle | REUSE geometry; ADAPT independent shape/resource bags and reward boundary. Preserve production economy. |
| Production ChainBoard/ChainResolver | Diagonal detection and immediate whole-cascade resolution | ADAPT storage/gravity idea, not direct resolver reuse: R2 requires H/V only, column-first refill and timed waves. |
| Production EnemyActionScheduler | Current action, commit boundary, exactly-once resolution | ADAPT separate R2 integer clock: existing scheduler advances next immediately and uses baseline director, incompatible with end-tick targeting rule. |
| [Godot processing](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html) | Fixed simulation independent of rendering | ADOPT explicit simulation steps and event-owned rendering. |
| [AtlasTexture](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html) | Shared source, clipped regions | ADOPT existing region/hash data, preserve aspect and alpha. |
| [SEGA rules](https://puyo.sega.jp/puyopuyotetris2/rule.html) | HP puzzle battle and scheduled swap precedents | REUSED_EVIDENCE; REJECT forced swap/manual MP for approved R2. |

Alternatives: modify production in place (REJECT regression/migration risk); isolated R2 using reusable geometry (ADOPT reversible comparison); rebuild all geometry (REJECT duplicate maintenance). No claim of proven fun.

Ruling: use a dedicated branch in the exact project checkout rather than a new worktree, because the adopted slot8 launcher hard-pins this path; no cross-project routing/settings migration is authorized. Cost if wrong: other users must not concurrently edit this checkout. Current unrelated editors/worktrees are preserved.

Baseline verification: 253/253 GUT tests, 2654 assertions, 53 scripts passed on Windows. Project editor PID31048, exact path Tetris, session `tetris@4202`, plugin/server3.2.0, Godot4.7.1, readiness ready. Direct standard MCP transport reuses the existing endpoint8008, no new server/client file installed. Startup generated import/UID metadata and a blank-line project setting serialization; these are not product implementation evidence.

## Task 1: Deterministic R2 combat transactions

Files: create `src/replanned_r2/r2_combat.gd`, `tests/replanned_r2/test_r2_combat.gd`. No other production files.

Interface: RefCounted, `new()` initialized standard encounter; public `hp:int`, `boss_hp:int`, `armor:int`, `attack_bank:int`, `ward:int`, `ward_target:String`, `eta_us:int`, `extension_us:int`, `action_index:int`, `paused:bool`, `outcome:String`. `action_id()->String`, `current_action()->Dictionary`, `next_action()->Dictionary`, `apply_line(event_id:String,cells:Array)->Dictionary`, `cast(event_id:String,category:String,wave:int)->Dictionary`, `tick(delta_us:int,line_events:Array=[],cast_events:Array=[])->Array`, `snapshot()->Dictionary`, `restore(snapshot:Dictionary)->bool`. Unique LINE cells are dictionaries `{id:String, kind:String}`. Tick casts contain `{id,category,wave}`. Dictionaries return explicit success/effect/reason rather than throwing for invalid input. Runtime outcome RUNNING/VICTORY/DEFEAT.

- [ ] Write GUT tests with literal expectations: A4/D2/H2/T2 at HP80 yields bank4/armor2/HP82/ETA+500000; duplicate event or duplicate cell pays once; invalid kind/cell payload changes nothing; bank7 ATK C1/C2/C3 deals25 total; DEF waves1..3 ward7, armor10, boss35 => HP18 loss; SUP caps; time20 at extension2500000 adds500000; committed/rest ward no-op; duplicate cast id no effect; lethal boss before SUP on same tick; old-action time cannot target next action; pause preserves exact snapshot; invalid restore atomic. Seed first encounter and data consumer match approved session file.
- [ ] Run focused GUT before implementation and record expected failure.
- [ ] Implement pure transactions with validate-before-mutate, integer time and next-action scheduling at tick end. Initial pattern probe10s12/slam14s35/probe10s12/rest8s0, maxHP100/boss240. Commit lead1000us, action cap3000000us. Gameplay consumer must use this owner, not duplicate formulas in UI.
- [ ] Run focused GUT and existing regression; self-review and commit only owned paths. Report exact tests and limits.

## Task 2: Persistent LINE and timed CHAIN models

Files: `src/replanned_r2/r2_line.gd`, `r2_chain.gd`, `r2_session.gd`; `tests/replanned_r2/test_r2_puzzles.gd`.

Consumes Task1 transactions. Produces session `command(action:String,args:Dictionary={})`, `tick(delta_us:int)`, `snapshot()`, `restore(data)` and inspectable `combat`, `line`, `chain`, `mode`, `selected_category`. UI must not mutate these fields directly.

- [ ] Tests first: exact two-wave fixture from session JSON, no diagonal match, failed swap unchanged, category frozen during cascade, C7+T6, safe delayed switch, inactive LINE freeze but boss progresses, shape/resource HOLD preserved, unique line clear resource cells, topout HP25 without armor, pause/resume identical continuation.
- [ ] Reuse existing LineBoard/ActiveTetromino/TetrominoCatalog with original shape seed; independent four-resource bag. Implement bounded initial board search/fallback and column-first refill.
- [ ] Run focused tests including the published fixture before integrating the view; then regression and task review.

## Task 3: First encounter screen, art, persistence and verification

Files: `src/replanned_r2/r2_screen.gd`, `r2_save.gd`, `r2_assets.gd`; `scenes/replanned_r2/main.tscn`; `tests/replanned_r2/test_r2_screen.gd`, `test_r2_save.gd`. Reuse atlas source paths and regions from approved session JSON without copying pixels or modifying source images.

- [ ] Test scene entry, 50:50 bounds, one board visible, category/preview/recent auto-skill states, no manual cast, asset role/region, pause and full snapshot roundtrip before implementing each consumer.
- [ ] Bind main/briefing/practice/standard-relaxed/settings/result/retry to session. Implement key-pose boss presentation and reduced motion; no damage from animation callbacks.
- [ ] Validate full stable save schema/checksum before atomically replacing separate R2 save; restore paused with held input cleared. Corrupt/partial/baseline save must not partially restore.
- [ ] Godot import/parse, all GUT/tooling/protected tests, actual normal UI path and screenshots; distinguish diagnostics from acceptance.
- [ ] Exactly two whole-result adversarial review loops, corrections and regression; reconcile latest main, own PR checks and safe publication. Do not claim full completion while any task remains.

## Progress / evidence ceiling

Implementation IN_PROGRESS. No R2 runtime/Human PASS yet. Historical preparation receipt/PDF remains unchanged as prior evidence. This file owns current implementation continuation status and must be updated at every handoff.

Publication boundary correction: Foundation now routes this approved implementation. The integrated PDF still verifies its exact published Foundation bytes at source commit, while remaining rule/asset inputs verify both current and historical bytes. RED: its original test failed solely on the added continuation routing paragraph; this is not permission to weaken asset/rule checks or relabel old PDF as runtime evidence.

| Shared interface | Check |
| --- | --- |
| Task1→Task2 combat tick + event dictionaries | Same-tick boss priority and end-tick next target explicit; no puzzle-owned combat arithmetic. |
| Task2→Task3 command/snapshot | View does not own damage, state save or randomization. |
| Task1/2/3 save | Whole snapshot includes RNG and simulation residuals; stable boundary only. |
| Task1 internal | Test values agree with R2 formulas and seed. |
| Task2 internal | Fixture is ordinary matcher/refill input, not hardcoded expected result. |
| Task3 internal | Screen accepts model outcome; rendering cannot accelerate simulation. |
