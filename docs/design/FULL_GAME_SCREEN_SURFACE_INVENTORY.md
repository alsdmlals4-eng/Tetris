# Full Game Screen Surface Inventory

- Status: `CURRENT PLANNING INVENTORY / Issues #49, #54, #56, #66, #68, and #70`
- Authority: user-supplied screen-first inventory, `TETRIS-CORE-029`, `TETRIS-CHAIN-038`, `TETRIS-SKILL-039`, `TETRIS-BALANCE-040`, `TETRIS-VISUAL-041`, `TETRIS-IMAGE-030`, `TETRIS-ONBOARDING-037`, and actual merged `main`.
- Target: the eventual Tetris game flow, not a claim that every listed screen is currently implemented.
- Evidence rule: every player-facing row needs one whole-screen evidence item: approved screen design reference, target-resolution wireframe/mockup, Godot capture, prototype capture, or verified reuse evidence.

## Classification

| Consumer kind | Meaning |
| --- | --- |
| `GAME_RUNTIME` | A scene/surface already exists and can be checked in Godot. |
| `PLANNED_GAME_SURFACE` | Required for the planned game flow, but not yet a Godot scene or runtime asset. |
| `PLAYER_FACING_EXPLANATORY` | Player-visible learning/reference surface; it becomes runtime-required only when its scene is implemented. |
| `PRODUCT_DISTRIBUTION` | Store/marketing delivery; separate from in-game runtime assets. |

## Player flow

`BOOT → TITLE → RUN_SETUP → FRONTIER_ROUTE → BATTLE_BRIEFING → CONTINUOUS_BATTLE ↔ TACTICAL_SKILL → RESULT_REWARD → WORKSHOP_OR_ROUTE`

The intended first session is `TITLE → BATTLE_BRIEFING → SHORT_GUIDED_LIVE_PRACTICE → CONTINUOUS_BATTLE`: the briefing gives the minimum verified world/threat context and, on the first intended session only, requires the full rule region to reach its end or an equivalent accessible review action before Deploy unlocks. Deploy begins the real continuous clock. The first authored Telegraph/ETA is a shared live **28-second** guided opening; the safe opening guard prevents either terminal outcome until the first explicit CONFIRM, then the short practice hands off to normal authored pressure in the same encounter. Later-visit persistence is not yet implemented. The current worktree implements Title, Briefing, Deploy, and the embedded guide; route, result/reward, workshop and Codex arrows remain planned. A popup is recorded as a separate surface only when it changes player decision, focus, or input ownership.

## Approved first-session onboarding · `TETRIS-ONBOARDING-037`

`TETRIS-SCREEN-006` is required for the **intended first session** and implemented in the current worktree. It uses only the current Vanguard / Frontier Gate / Gatebreaker / immediate-threat relationship. On each current launch, the complete rule region must reach its end or an equivalent accessible review action before explicit Deploy enables and the CORE-029 clock can start; later-visit persistence is deliberately not claimed. `TETRIS-SCREEN-007` then gives a short **safe live authored opening**: Current Telegraph/ETA genuinely runs from Deploy, while the runtime prevents either terminal outcome before the first explicit CONFIRM. It practices LINE/MP → CHAIN/Combo → full Skill pause → category-resolved preview → explicit CONFIRM, then continues in the same encounter with normal authored pressure and one unforced response. CHAIN reads a straight horizontal, vertical, or diagonal 3+ run; an invalid swap restores by default and can optionally spend MP to remain as future Combo setup. The detailed rules and evidence gate live in `FIRST_SESSION_ONBOARDING_CONTRACT.md`, `CHAIN_COMBO_MP_CONTRACT.md` and `COMBO_RESOLVED_SKILL_CONTRACT.md`.

## Surface inventory

| ID | Family / name | Stage · priority | Player question and primary action | Entry → exit | Consumer / coverage | Whole-screen evidence requirement |
| --- | --- | --- | --- | --- | --- | --- |
| `TETRIS-SCREEN-001` | A · Boot / splash / loading | Planned · P2 | “Is the game ready, and is loading recoverable?” Wait, retry only if a failure state is shown. | App launch → Title or error. | `PLANNED_GAME_SURFACE`; no current async loader. `PLANNED_NO_RUNTIME_CONSUMER`. | 16:9 loading wireframe with progress/error state. |
| `TETRIS-SCREEN-002` | A · Title / main menu | Runtime current-worktree · P1 | “Deploy to the Frontier Gate or leave the current slice?” Start the fixed first encounter. | Boot → Battle Briefing. | `GAME_RUNTIME`: `scenes/production/title.tscn`; current text placeholder and a blank `TitleLogo` consumer slot. Candidate title art still needs explicit user lock. `IMPLEMENTED_IN_CURRENT_WORKTREE_PENDING_FULL_VERIFICATION`. | Godot target-resolution capture; candidate logo is not evidence until locked and bound. |
| `TETRIS-SCREEN-003` | A/B · Run profile / difficulty / mode | Planned · P1 | “Which run contract am I starting?” Select New/Continue slot, difficulty, and mode. | Title → Loadout/route or back. | `PLANNED_GAME_SURFACE`; save/profile data is not implemented. `GAP_BLOCKING_FOR_SAVE_FLOW`. | Form/slot state wireframe: empty, occupied, locked, conflict. |
| `TETRIS-SCREEN-004` | B · Vanguard loadout / technique selection | Planned · P1 | “Which retained Vanguard configuration changes this run?” Compare permitted techniques/equipment; confirm only legal choices. | Run setup → Route/briefing or back. | `PLANNED_GAME_SURFACE`; first slice presently has fixed Vanguard/loadout. `GAP_NONBLOCKING_FOR_CURRENT_SLICE`. | Loadout comparison wireframe; portrait can reuse `TETRIS-IMG-033` when implemented. |
| `TETRIS-SCREEN-005` | C · Frontier route / chapter map | Planned · P1 | “Which gate or threat should I enter next?” Select reachable route; read reward, risk, lock and completion state. | Loadout/result → Briefing or back. | `PLANNED_GAME_SURFACE`; only Frontier Gate encounter is currently implemented. `GAP_BLOCKING_FOR_MULTI-ENCOUNTER_LOOP`. | 16:9 route-map design reference, then node-state wireframe. |
| `TETRIS-SCREEN-006` | E · Battle briefing / first-session launch | Runtime current-worktree · P0 | “Where am I, why is this Gatebreaker a threat, and what rules will govern my choices?” Read the immediate Vanguard / Frontier Gate / Gatebreaker context and complete the full pre-Deploy LINE/CHAIN/Skill rule region before Deploy enables. | Title → Battle or back. | `GAME_RUNTIME`: `scenes/production/battle_briefing.tscn`; acknowledgement enables Deploy per current launch. `IMPLEMENTED_IN_CURRENT_WORKTREE_PENDING_FULL_VERIFICATION`. | Godot target-resolution capture with readable full rule region and Deploy focus. |
| `TETRIS-SCREEN-007` | D/E · Continuous battle / embedded tutorial | Runtime current-worktree · P0 | “Can I verify the rules under a real live threat, then continue the same encounter?” A short **safe live opening** begins the actual ETA from Deploy. Live reward/preview events advance the guide through Telegraph/ETA, LINE/MP (Single/Double/Triple/Four = 10/22/36/52; hard cap 60), pre-disclosed CHAIN orthogonal straight-3+ H/V/diagonal rule, category-resolved Skill preview and one explicit CONFIRM. The opening guard prevents either terminal outcome before that CONFIRM; it then hands off to normal authored pressure and an unforced response in the same encounter. MP lock remains optional; it never makes the tutorial longer by becoming mandatory. | Briefing/direct entry → Skill, terminal result. | `GAME_RUNTIME`: `scenes/production/battle.tscn`, `ProductionGuidedPracticeState`, current CHAIN/MP/Combo runtime and category-resolved Skill preview/confirm. `IMPLEMENTED_IN_CURRENT_WORKTREE_PENDING_FULL_VERIFICATION`; intended first-session learning remains `NOT_RUN`. | Godot target-resolution capture plus first-exposure receipt; planning board is not a tutorial PASS. |
| `TETRIS-SCREEN-008` | E · Tactical Skill overlay | Runtime current-worktree · P0 | “Which category answers this current threat, and is spending Combo now worth it?” Select ATK/DEF/SUP → inspect one current-Combo Stage/MP/fallback preview → CONFIRM or cancel. | Battle `K`/Skill → Battle. | `GAME_RUNTIME`: `SkillFrame`, category seals, one resolved preview and `ConfirmButton`; legacy `TierGrid` is absent from the current battle scene. Human comprehension is unverified. `IMPLEMENTED_IN_CURRENT_WORKTREE_PENDING_FULL_VERIFICATION`. | Target-resolution tactical-pause capture including frozen threat/puzzle context, category preview and shortage fallback. |
| `TETRIS-SCREEN-009` | E · Boss phase / decisive technique presentation | Planned overlay · P1 | “What changed, what is dangerous, and what response window remains?” Acknowledge phase or decisive result without hiding the playable board. | Battle phase/commit → Battle. | `PLANNED_GAME_SURFACE`; current telegraph remains an in-battle component, not a separate input surface. `GAP_NONBLOCKING`. | Overlay composition reference with safe HUD/puzzle bounds. |
| `TETRIS-SCREEN-010` | F/I · Result / reward / retry | Mixed · P0 | “Why did this end, what did I gain, and what next?” Read cause and summary; retry, route, or workshop. | Victory/Defeat → Retry/route/workshop. | `GAME_RUNTIME` terminal label/retry exists; reward recap is `PLANNED_GAME_SURFACE`. `GAP_BLOCKING_FOR_META_LOOP`, not for current retry slice. | Result summary wireframe plus terminal Godot capture. |
| `TETRIS-SCREEN-011` | F · Growth / workshop / inventory | Planned · P1 | “How do I spend or configure earned progress?” Compare upgrade/equipment effects; buy, craft, repair, or leave. | Result/hub → Route/briefing. | `PLANNED_GAME_SURFACE`; progression economy is out of current canon. `GAP_BLOCKING_FOR_PERSISTENT_GROWTH`. | Item/skill comparison wireframe with locked, affordable, equipped states. |
| `TETRIS-SCREEN-012` | G · Codex / archive / tutorial / controls | Planned explanatory · P1 | “How do LINE, CHAIN, ETA and tactical pause work after the first encounter?” Search/filter/read and return. | Any player request → prior surface. | `PLAYER_FACING_EXPLANATORY`; it supports, but does not replace, the first-session embedded tutorial. `GAP_NONBLOCKING`. | Manual/article layout wireframe with keyboard and gamepad legends. |
| `TETRIS-SCREEN-013` | H · Pause / settings | Mixed · P1 | “Is simulation safely paused and can I change options?” Resume, save, apply/revert audio/graphics/input/accessibility/language. | `P` → resume/title. | Manual simulation pause exists; settings scene does not. `GAP_NONBLOCKING_FOR_CURRENT_SLICE`. | Settings tab wireframe: normal, changed, apply, revert, reset. |
| `TETRIS-SCREEN-014` | I · Checkpoint / game-over / chapter complete / credits | Planned · P2 | “Can I recover, and has this chapter concluded?” Retry checkpoint, continue, or exit. | Terminal/meta event → route/title. | `PLANNED_GAME_SURFACE`; current terminal retry covers only immediate encounter recovery. `GAP_NONBLOCKING`. | Failure/chapter-complete composition reference and action hierarchy wireframe. |
| `TETRIS-SCREEN-015` | I · Transition / offline / error / empty state | Planned · P2 | “What failed or is unavailable, and how do I recover?” Retry, back, resolve conflict, or acknowledge. | Any failed flow → safe prior state. | `PLANNED_GAME_SURFACE`; no networking/save conflict path presently exists. `NOT_APPLICABLE_TO_CURRENT_RUNTIME`, planned for full product. | Error/empty-state wireframe with a single safe primary action. |
| `TETRIS-SCREEN-016` | Release · logo / icon / capsules / screenshots / key art | Planned distribution · P1 | “What is this game and why should I enter?” Store visitor reads identity and receives truthful gameplay proof. | Platform listing → store/game entry. | `PRODUCT_DISTRIBUTION`; final public title, platform, and legal package are undecided. `BLOCKED_UNVERIFIED_FOR_FINAL_ART`. | Store-spec-specific final files only after title/platform/legal gate. |

## Existing runtime visual reuse

| Existing item | Actual consumer | Role | Reuse disposition |
| --- | --- | --- | --- |
| `TETRIS-IMG-031` stage background | `CombatStage/StageBackdrop` | Battle environment | `REUSE_AS_IS` for current battle only. |
| `TETRIS-IMG-033` Vanguard cutout | `CombatStage/VanguardReference` | Player identity | `VARIANT_SEED` for future portrait/loadout work; no unapproved mutation. |
| `TETRIS-IMG-034` Gatebreaker cutout | `CombatStage/GatebreakerReference` | Enemy identity | `VARIANT_SEED` for briefing/result references only after a named surface exists. |
| `TETRIS-IMG-035` attack accent | `CombatStage/VanguardAttackAccent` | Committed attack feedback | `REUSE_AS_IS` for battle only. |
| `TETRIS-IMG-036` rift telegraph | `CombatStage/GatebreakerThreatTelegraph` | Active threat feedback | `REUSE_AS_IS` for battle only. |

## Cross-check: visual state families

| Family | Current treatment | Missing-file policy |
| --- | --- | --- |
| Puzzle/input | LINE, CHAIN, Hold/Next, board selection and state feedback | Godot drawing/theme; no bitmap UI queue. |
| Combat targeting/telegraph | ETA text, current threat, rift telegraph, skill pause | Existing VFX/UI; phase overlay is planned. |
| Character/enemy | Battle cutouts and stage layering | Current combat needs covered; animation/portrait families wait for a consumer. |
| Buttons/slots/gauges | Normal/selected/disabled layout states | Godot Theme/StyleBox/Control, not raster files by default. |
| Result/meta | Retry exists; reward, save, growth states planned | Create structured UI and data consumer before any runtime image. |
| Accessibility/input | Current keyboard prompts; gamepad, language and reduced-motion settings planned | Text/icon/UI first; image only if a named surface needs one. |

## Required record fields and destinations

The machine-readable rows live in `SCREEN_SURFACE_INVENTORY.json`. Human-facing records belong in this repository's `PROJECT_MASTER_GDD.md`, `VISUAL_BIBLE.md`, and screen-reference manifests. Runtime facts remain in scene/code/tests; this inventory never upgrades a planned surface to runtime proof.

## Generated planning-reference package · Issue #49

The following five textless 16:9 images are **user-approved planning references**. They establish screen-level composition, empty localized-UI regions, hierarchy, and material language for named planned surfaces. They are not Godot runtime assets, implementation proof, a public title decision, or store-ready art.

| Reference | Screen | Local path | Status / QA decision |
| --- | --- | --- | --- |
| `TETRIS-SREF-001` | `TETRIS-SCREEN-002` Title | `docs/assets/reference/planned/tetris-title-main-menu-screen-reference-v1.png` | `PROJECT_SCREEN_REFERENCE_APPROVED`; left title/menu safe area and right Gate focal mass verified. |
| `TETRIS-SREF-002` | `TETRIS-SCREEN-005` Route | `docs/assets/reference/planned/tetris-frontier-route-map-screen-reference-v1.png` | `PROJECT_SCREEN_REFERENCE_APPROVED`; node shape, lock, reward, danger and current-location roles remain distinguishable without text. |
| `TETRIS-SREF-003` | `TETRIS-SCREEN-006` Briefing | `docs/assets/reference/planned/tetris-battle-briefing-screen-reference-v1.png` | `PROJECT_SCREEN_REFERENCE_APPROVED`; enemy threat and launch decision reserve information space ahead of spectacle. |
| `TETRIS-SREF-004` | `TETRIS-SCREEN-010` Result | `docs/assets/reference/planned/tetris-result-reward-screen-reference-v1.png` | `PROJECT_SCREEN_REFERENCE_APPROVED`; outcome, reward and next-action hierarchy are separate editable regions. |
| `TETRIS-SREF-005` | `TETRIS-SCREEN-012` Manual | `docs/assets/reference/planned/tetris-codex-manual-screen-reference-v1.png` | `PROJECT_SCREEN_REFERENCE_APPROVED`; topic navigation, instructional diagrams and input legend have isolated zones. |

Each file is 1672×941 PNG and is registered in `SCREEN_REFERENCE_MANIFEST.json`. They must be recreated or replaced through a new candidate/version rather than overwritten.

## Immediate next production order

1. Convert the approved `006 Briefing` planning reference and `TETRIS-ONBOARDING-037` full pre-Deploy rules section into a Phase 2 Godot screen/data contract; do not generate a runtime bitmap by default.
2. Implement and validate the smallest first-session flow extension one screen at a time: briefing/rules/Deploy, then battle practice and verification triggers.
3. Obtain first-exposure evidence before expanding route, result, or Codex implementation.
4. Create store assets only after public title, platform target, and rights/package criteria are fixed.
