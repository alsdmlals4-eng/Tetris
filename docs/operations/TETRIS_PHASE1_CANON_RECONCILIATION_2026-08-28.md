# Tetris Phase 1 Canon Reconciliation — 2026-08-28

Issue: #52
Repository baseline: `main` `1367f76491af54df77b5079ef21231be6547d4d5`
Mode: REVIEW → documentation reconciliation; no Godot implementation or asset production

## Authority result

| Classification | Evidence | Disposition |
| --- | --- | --- |
| CURRENT | `TETRIS-CORE-029`; `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md`; `PRODUCTION_CANON_INDEX.json`; `scenes/production/battle.tscn` | Current gameplay/runtime authority. |
| CURRENT | `TETRIS-VISUAL-028 · Hand-Drawn Mystic Fantasy + Clean Puzzle UI` and approved reference manifest | Visual direction is retained. Reference images are not runtime proof unless their exact documented consumer is present. |
| CURRENT | Battle stage, Vanguard/Gatebreaker cutouts, and attack/telegraph VFX have named nodes in `scenes/production/battle.tscn` and pass consumer-contract tests. | Implemented consumer binding only. Human readability remains unverified. |
| CURRENT | `FULL_GAME_SCREEN_SURFACE_INVENTORY.md` and `SCREEN_SURFACE_INVENTORY.json` | Battle and tactical Skill are runtime surfaces; title/setup/route/briefing/result/workshop/codex remain planned or mixed. |
| CURRENT | `TETRIS-ONBOARDING-037`; `FIRST_SESSION_ONBOARDING_CONTRACT.md` | User approved the intended first-session structure: short verified world/threat briefing → explicit Deploy → CORE-029 battle with contextual tutorial. It is documented, not implemented or Human-validated. |
| CURRENT | `TETRIS-CHAIN-038`; `CHAIN_COMBO_MP_CONTRACT.md` | User confirmed the cross-workspace resource loop: LINE recovers MP and CHAIN earns Combo. CHAIN matches straight horizontal/vertical/both-diagonal 3+ runs; a no-match normally restores, while optional MP may retain the swap for later setup without immediate Combo. It is documented, not implemented or Human-validated. |
| HISTORICAL | `CORE_GAMEPLAY_GDD.md`, `POC_RULESET_V0_1.md`, core POC tests and PR #3 | Engineering foundation/provenance; not CORE-029 gameplay proof. |
| SUPERSEDED | `TETRIS-CORE-024`, `TETRIS-TIME-025`; ordered phase rail, Shared Player Turn Timer, READY, timeout/PASS, Tempo | Preserve as provenance only; never use as current UX, visual, or runtime requirement. |
| CONFLICT_FIXED | Notion Home, Visual Bible, and Flow Map contained present-tense references to unmerged PR #24, no image slots, Shared Turn Timer, and ordered-phase UX. | Current-truth correction blocks and targeted text corrections were written and read back in Notion. |
| UNKNOWN_UNVERIFIED | User-Windows runtime, target-resolution composite inspection, first-exposure player comprehension, fun/tension, balance, audio, accessibility | No PASS claim. Needs real receipts under `PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`. |

## Current project understanding

**Player promise.** Read a live enemy threat, choose which of two non-interchangeable puzzle workspaces to invest in, then stop time only long enough to make an intentional Technique commitment before returning to the exact live situation.

```text
Current Telegraph + ETA
→ choose LINE (MP recovery) or CHAIN (Combo / Tier access)
→ operate the active persistent workspace under live pressure
→ SKILL pauses the whole simulation
→ ATK / DEF / SUP → T1–T6 → detail → explicit USE
→ visible combat result and the next threat
→ revise the next puzzle/resource/Technique choice
```

The differentiated hook is not “Tetris plus combat.” It is the tension between two different puzzle preparations, a continuously advancing readable threat, and a fair tactical pause that converts reaction pressure into deliberate commitment rather than a hidden turn system.

### Core-experience status

| Item | Status | Evidence / boundary |
| --- | --- | --- |
| Project goal and player promise | CURRENT | CORE-029 and Tetris Home agree. |
| Pointed fun | PARTIAL | Design intent is explicit; no first-exposure receipts demonstrate that it is felt. |
| Core and session loop | CURRENT | Continuous combat loop above is canonical; full 6–10 minute first session framing is planned. |
| Progression / meta loop | UNKNOWN_UNVERIFIED | Route, workshop, and long-term reward surfaces are planned; no implemented loop is current proof. |
| Core systems | CURRENT | Persistent LINE/CHAIN, LINE→MP / CHAIN→Combo dual resources, straight-3+ CHAIN grammar, telegraph/ETA, full tactical pause, explicit Technique commit. |
| Supporting systems | PARTIAL | Forecast, terminal retry, stage/character/VFX consumers exist; onboarding, rewards, audio, and meta systems lack runtime/player proof. |
| Meaningful choice and trade-off | CURRENT as design; PARTIAL as experience | Time/attention between MP and Combo, present response vs future preparation, optional MP board-shaping versus skill capacity, and Tier commitment. Tuning/understanding are unverified. |
| Failure learning / reattempt motivation | PARTIAL | Terminal retry exists; clear causal learning and reward-loop evidence are not yet present. |
| First impression / sales point | PARTIAL | Visual North Star and five planned screen references exist; no target-resolution player response or store validation. |
| Protected strengths | CURRENT | One large readable puzzle surface; two non-substitutable resources; threat hierarchy; explicit-use pause; visual clarity over spectacle. |
| Riskiest Vertical Slice hypothesis | NOT_RUN | New players can understand switching, two resources, pause/USE, and threat priority quickly enough for the loop to feel tense rather than overloaded. |

## User-approved first-session correction · Issue #54

The prior state had planned title/briefing/manual surfaces but no accepted first-session learning order. The user approved a small world explanation and tutorial. `TETRIS-ONBOARDING-037` therefore fixes the intended entry as `TITLE → BATTLE_BRIEFING → CONTINUOUS_BATTLE → RESULT/RETRY` and restricts its world text to the verified Vanguard / Frontier Gate / Gatebreaker / immediate-threat relationship. The tutorial occurs in actual CORE-029 battle: Telegraph/ETA → LINE/MP → CHAIN/Combo/Tier → optional MP lock as later setup → full Skill pause and explicit USE → one unforced response.

This correction does not add a scene, a runtime asset, a separate turn mode, or Human/player proof. It also does not impose the later full route/setup/meta path on the current direct-entry slice.

## User correction · MP / Combo ownership and CHAIN grammar · Issue #56

- **Incident:** the prior user-facing restatement incorrectly placed MP recovery in CHAIN. Current documentation still exposed implementation-oriented `Energy / Chain Stock` labels, while the approved player economy is `LINE → MP` and `CHAIN → Combo`. The merged CHAIN resolver also proves only horizontal/vertical matching and compulsory no-match restore, so treating the newly approved diagonal/MP-lock rule as runtime-complete would be false.
- **Solution:** `TETRIS-CHAIN-038` creates one player-facing contract: orthogonal swaps, straight horizontal/vertical/both-diagonal 3+ runs, default restore for no-match, and optional MP lock that preserves the swapped setup without immediate Combo. The current `energy` / `stock` fields remain explicitly mapped rather than duplicated as a third resource. Canon, onboarding, screen inventory, Human evidence criteria, README, and `AGENTS.md` now point to the same owner.
- **Lesson:** no Base promotion. The `MP → failed-swap lock → later Combo setup` economy and its labels are project-specific; the reusable lesson is already covered by Base's canonical freshness and evidence-ceiling contracts.
- **Evidence ceiling:** `PARTIAL_HV_ONLY_NO_MP_LOCK`. Documentation and tooling contracts are verified; Phase 2 Godot implementation, target-resolution UI composition, balance tuning, and Human/player comprehension remain unimplemented or `NOT_RUN`.

### Incident / Solution / Lesson

- **Incident:** the screen inventory named Briefing and Manual surfaces, but no accepted first-session order connected the world/threat explanation to the existing CORE-029 learning loop. Direct-entry runtime proof could therefore be mistaken for a complete player entry.
- **Solution:** `TETRIS-ONBOARDING-037` makes the minimal briefing/Deploy and embedded tutorial sequence explicit, marks it planned, and preserves all realtime supersession boundaries.
- **Lesson:** a planned explanatory screen is not onboarding until its player question, live-system handoff, unforced application step, and Human evidence gate are recorded together. `NO_BASE_PROMOTION`: this is one project-specific reconciliation result, not yet reusable cross-project evidence.

## Evidence-based SWOT

| Class | Statement | Evidence | Confidence | Player / production impact | Disposition | Next validation |
| --- | --- | --- | --- | --- | --- | --- |
| STRENGTH | The core loop has a legible distinct structure: live telegraph, persistent two-workspace choice, and full tactical pause. | CORE-029 canonical rules, runtime classes, and automated contracts. | VERIFIED for implementation; not fun. | Gives a clear decision vocabulary; requires onboarding proof. | PROTECT | First-exposure observation with no coaching. |
| STRENGTH | Visual grammar separates puzzle/HUD clarity from character/stage spectacle. | VISUAL-028, approved anchors, named battle consumers. | PARTIAL | Protects play readability and limits art production cost. | PROTECT | Target-resolution composite capture and human readability session. |
| WEAKNESS | Human/player evidence is absent. | Human evidence index/contract remains `NOT_RUN`. | VERIFIED | Cannot claim comprehension, tension, or balance; delays safe tuning. | TEST | Three independent first-exposure A/B/C receipts. |
| WEAKNESS | Meta progression and many entry/exit screens are only planned. | Screen inventory classifies title/setup/route/briefing/workshop as planned. | VERIFIED | The full session promise and repeat motivation are incomplete. | IMPROVE | Decide the smallest post-battle reward and route return loop after core-loop proof. |
| OPPORTUNITY | The project can sell readable “real-time pressure, deliberate choice” rather than speed alone. | Inference from the implemented mechanic and visual hierarchy; no market validation run. | INFERENCE | Clear positioning if the first encounter teaches the contrast. | TEST | Compare onboarding variants only after runtime capture exists. |
| THREAT | Stale human-facing material can revive superseded turn rules. | Fresh Notion audit found current-looking TIME-025/PR #24 statements. | VERIFIED | Players/designers could receive contradictory instructions; implementation drift risk. | MITIGATE | Keep a current-truth header and require fresh GitHub read before material changes. |
| THREAT | Visual reference can be mistaken for runtime/readability proof. | Approved and planned manifests deliberately classify reference vs runtime separately. | VERIFIED | Prevents false completion and unplanned asset cost. | MONITOR | Maintain consumer/evidence status in every new asset record. |

## Project understanding visual pack

This is a planning/understanding pack, not a list of runtime assets or a usability pass.

| Scene or screen | Current consumer / state | Player goal and meaningful choice | Information / feedback | Unknown to resolve |
| --- | --- | --- | --- | --- |
| `TETRIS-SCREEN-002` Title / Main Menu | Planned reference `TETRIS-SREF-001`; future Title scene | Start a run; understand the game’s threat/puzzle identity at a glance. | Title, start affordance, Gate silhouette, visual North Star. | Final title copy, input, actual scene consumer. |
| `TETRIS-SCREEN-005` Frontier Route | Planned reference `TETRIS-SREF-002`; future RouteMap | Choose a risk/reward route. | Current/reachable/locked/danger/reward shapes. | Actual map rules, rewards, progression meaning. |
| `TETRIS-SCREEN-006` Battle Briefing | Planned reference `TETRIS-SREF-003`; future BattleBriefing | Read the upcoming Gatebreaker threat and launch with intent. | Enemy identity, first Telegraph, launch action. | Briefing data contract and no-surprise onboarding. |
| `TETRIS-SCREEN-008` Continuous Battle | Runtime `scenes/production/battle.tscn` | Switch LINE/CHAIN, prepare the right resource, survive the live threat. | Current Telegraph + ETA, HP/MP/Combo, active workspace, stage/character/VFX feedback. | Target-resolution capture, first-use comprehension, tuning. |
| `TETRIS-SCREEN-009` Tactical Skill | Battle-owned runtime overlay | Pause, compare Technique cost/fit, explicitly commit or cancel. | Frozen threat/puzzle context, family/tier/detail/USE distinction. | Human comprehension of pause and affordability. |
| `TETRIS-SCREEN-010` Result / Reward | Planned reference `TETRIS-SREF-004`; retry is runtime-existing | Understand outcome; retry or take a reward/next-route action. | Outcome, causal feedback, reward/next action regions. | Reward data, loss learning, persistence. |
| `TETRIS-SCREEN-012` Codex / Manual | Planned reference `TETRIS-SREF-005` | Resolve a misunderstanding without burying the core loop in text. | Topics, diagrams, input legend. | Trigger/context/help content and scene consumer. |

## Current Work-5 position and next order

1. **Intent / core direction:** CURRENT and approved (CORE-029, VISUAL-028).
2. **Representative runtime slice:** IMPLEMENTED with automated-contract evidence, but `TETRIS-CHAIN-038` is only `PARTIAL_HV_ONLY_NO_MP_LOCK`; player-evidence ceiling remains `NOT_RUN`.
3. **Human usability / player experience validation:** next required gate.
4. **First-session and meta-loop completion:** first-session design is now user-approved and documented; its runtime implementation remains gated behind Phase 2 review and first-exposure evidence. Title/route/result/meta screens remain planning-only.
5. **Production expansion / polish:** defer until the first-exposure findings choose the smallest corrective slice.

Priority order: (1) obtain a target-resolution runtime capture and real first-exposure receipts; (2) correct any demonstrated comprehension/readability failure; (3) Phase 2-review the approved briefing/embedded-tutorial implementation contract; (4) only then expand planned screen implementation or production-asset batches.

## Notion destination readback

- Home: `https://app.notion.com/p/3c41b237eb1c819985b3e798e938c80b`
- Visual Bible: `https://app.notion.com/p/3c11b237eb1c81508ebed297639a021a`
- Puzzle Battle Flow Map: `https://app.notion.com/p/3c11b237eb1c819dbad7d0227473fd73`

All three were re-fetched after their current-truth correction blocks were written. The audit did not alter approved reference binaries, runtime assets, code, or open PRs.

## Validation

Executed on the repository baseline:

```text
python -m unittest tests.tooling.test_production_canon_contract \
  tests.tooling.test_runtime_character_assets \
  tests.tooling.test_runtime_combat_vfx_assets \
  tests.tooling.test_screen_surface_inventory -v

18 tests passed.
```

This validates structured authority, runtime-consumer contracts, and screen-reference classification. It does not validate runtime play, UX, art readability, audio, balance, or player enjoyment.

## Reuse learning and rollback

`REUSED_EVIDENCE`: existing canonical index, runtime consumer contracts, screen inventory, approved anchor manifest, and Human evidence contract were reused. No new Base-general rule was proven; `NO_BASE_PROMOTION` because the stale-current finding is project-specific and a single reconciliation does not establish a reusable Base pattern.

Rollback: revert this audit record and remove the three Notion correction blocks/targeted wording. Do not delete or alter historical provenance, approved references, or runtime assets.
