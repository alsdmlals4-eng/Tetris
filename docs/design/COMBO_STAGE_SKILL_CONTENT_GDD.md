# Combo Stage Skill Content GDD

- Decision: `TETRIS-SKILL-042 · Deliberate Combo Stop + Target-Separated Time Control`
- Status: `USER_APPROVED_DIRECTION / PHASE 1 CONTENT DRAFT / USER_REVIEW_REQUIRED / DOCUMENTED_NOT_IMPLEMENTED`
- Issue: [#80](https://github.com/alsdmlals4-eng/Tetris/issues/80)
- Date: 2026-08-28
- Extends: `TETRIS-SKILL-039`, `TETRIS-BALANCE-040`, `TETRIS-CHAIN-038`, and `TETRIS-CORE-029`.
- Does not supersede: category-only selection, full tactical pause, explicit `CONFIRM`, the 5-MP bounded shortage fallback, or the shared Combo cap of 10.

## 1. Player promise

High Combo is stronger, but it is not always correct to chase it. Every lower Combo stage has a **contextual, independently useful response**. A player may intentionally stop preparing at the Combo that solves the visible problem, rather than risking time and board state solely to reach C10.

```text
Visible Gatebreaker threat + player HP/MP/Combo
→ decide whether to keep chaining for a stronger future stage
   or resolve now at the desired current Combo
→ open SKILL (full tactical pause)
→ choose ATK / DEF / SUP
→ inspect exactly one current-Combo-resolved effect
→ explicit CONFIRM spends and resolves it
→ the same battle resumes with the changed board-time or enemy-ETA state visible
```

Example: the player can prepare a path toward C10, but a C5 answer is the right response to the current state. They intentionally finish the CHAIN at C5, open Skill, choose the appropriate category, inspect that category's C5 preview, and confirm. They do **not** reach C10 and manually browse down to C5.

This preserves the small, readable `ATK / DEF / SUP` vocabulary while making the decision to stop or continue a real strategy rather than a failure to optimize.

## 2. Locked interaction and resource rules

1. The current Combo stage resolves the technique. A category press is a preview; `CONFIRM` is the only spend point.
2. The player cannot manually select a lower stage while they hold a higher Combo. Deliberate low-stage use happens by committing the CHAIN earlier.
3. The only exception remains the approved MP-shortage fallback: if the current stage lacks MP, surplus opening Combo may convert at 5 MP each solely to reach the highest legal lower stage. This is not voluntary down-ranking.
4. Combo spent on a technique still lowers future CHAIN MP recovery. No new currency, cooldown, Tier grid, or automatic cast is introduced.
5. Numerical MP costs, damage, healing, mitigation, seconds, and duration values are `TUNING_SEED_NOT_FINAL`. This GDD locks effect identity and selection meaning, not final balance numbers.

## 3. Two target-separated time domains

"Acceleration" and "deceleration" are not generic speed modifiers. Every preview, data entry, combat log and later test must name its **target**, **time domain**, **direction**, **magnitude**, and the state that remains unchanged.

| Target | Time domain | Acceleration | Deceleration | Never changes |
| --- | --- | --- | --- | --- |
| Player | Player board-play opportunity | Increases the time/opportunity available to play the player's board. | Reduces the time/opportunity available to play the player's board. | The Gatebreaker's current ETA. |
| Enemy | Visible current-pattern ETA | Shortens the time until the Gatebreaker's current displayed pattern resolves. | Lengthens the time until the Gatebreaker's current displayed pattern resolves. | The player's board-play opportunity. |

The player-facing words are intentionally direct:

```text
Target: Player  | Board play opportunity: +N seconds | Enemy ETA unchanged
Target: Enemy   | Current pattern ETA: +N seconds    | Player board time unchanged
```

### Current-telegraph boundary

- Enemy ETA effects bind only to the **visible current Telegraph action** and its exact action id. They never modify a hidden sequence or a merely forecast next action.
- A decelerated enemy ETA cannot cross into an already-resolved action; an accelerated enemy ETA cannot retroactively resolve an action inside tactical pause. The scheduler's commit boundary remains authoritative.
- Tactical pause freezes both domains. A preview never advances, shortens or restores any clock. The approved effect begins only after `CONFIRM` and battle resume.
- Player board-play opportunity is a player-side effect, not a global `Engine.time_scale` change. It must not slow or speed enemy ETA, status ticking, VFX, audio or the inactive workspace.
- The active runtime has no player board-time controller. The Phase 2 contract must define its exact delivery mechanism and duration ownership before implementation. The player-facing semantic above is locked; the mechanism is `PARTIAL / NOT IMPLEMENTED`, not an existing Haste translation.

This explicitly replaces the unsafe historical interpretation of `Haste`, `Battle Trance`, turn-only duration and Tempo. They remain `REALTIME_MIGRATION_REQUIRED` and are not silently re-enabled.

## 4. Proposed content matrix for user review

The user-approved direction is that lower Combo stages must retain independently useful effects. The following names and stage placement are the GPT-recommended first content matrix; they do not become an approved runtime/data content lock until the user reviews this written GDD. Later stages may combine more than one effect, but a higher Combo number must not make every lower contextual response irrelevant.

| Combo | ATK — pressure / breach | DEF — current-threat protection | SUP — recovery / setup | Intentional stop decision |
| --- | --- | --- | --- | --- |
| C1 | **First Edge**: reliable immediate single-target damage. | **Brace**: fixed mitigation against the visible direct hit. | **First Aid**: immediate self-heal. | End a near-fatal or near-finish state without risking a second chain. |
| C2 | **Rift Snare**: decelerate the visible enemy pattern ETA; no hidden future control. | **Supply Guard**: protect against the current visible MP/Combo-loss pattern. | **Rally Step**: accelerate player board-play opportunity. | Buy a readable answer to an imminent timer/resource threat rather than gambling for damage. |
| C3 | **Fracture Cut**: stronger single-target breach damage. | **Riposte Guard**: return a portion of prevented damage to the current attacker. | **Second Wind**: medium self-heal. | Convert a stable but injured state into a safe next board decision. |
| C4 | **Shieldbreaker**: decisive direct damage against the Gatebreaker. | **Bulwark**: substantial current-direct mitigation. | **Anchor Pulse**: small self-heal plus enemy current-ETA deceleration. | Answer the current pattern with certainty while retaining the C5–C10 opportunity cost. |
| C5 | **Severing Drive**: direct damage plus player board-play acceleration. | **Last Guard**: one current-pattern lethal-safety response. | **Field Mend**: large immediate self-heal. | C5 is deliberately attractive: it solves survival or gives enough board opportunity to rebuild, even when C10 was attainable. |
| C6 | **Execution Edge**: high deterministic direct burst; no unresolved multiplier claim. | **Aegis Relay**: current direct mitigation plus resource-loss protection when the displayed pattern supports both. | **Breather**: player board-play acceleration plus enemy current-ETA deceleration. | Spend on a compound tactical reset instead of exposing the board to chase C7+. |
| C7 | **Rift Lancer**: high breach damage plus a small enemy-ETA deceleration. | **Counterwall**: mitigation plus a stronger counter on the exact current attack. | **Vanguard Refresh**: substantial heal plus player board-play acceleration. | First high-stage compound response; powerful, but not a replacement for C2 slow or C5 lethal safety. |
| C8 | **Sundering Chain**: high direct burst plus player board-play acceleration. | **Preservation Field**: strong resource ward plus player board-play acceleration. | **Suspension Chant**: strong enemy-ETA deceleration plus a recovery pulse. | Reward long preparation with a broad answer, while low-stage emergency identity remains intact. |
| C9 | **Gatebreak Sequence**: very high single-target damage with an enemy-ETA deceleration rider. | **Bastion Return**: lethal safety plus a high counter against the visible direct pattern. | **Rift Renewal**: major healing plus enemy-ETA deceleration. | A late-stage swing that still loses to a C1/C2/C5 response when that earlier response is the one the state needs. |
| C10 | **Frontier Verdict**: maximum direct breach plus the largest approved current-ETA deceleration. | **Vanguard Aegis**: strongest current-threat package—mitigation, counter and resource protection where legally applicable. | **Second Dawn**: strongest recovery package—major healing, player board-play acceleration and enemy-ETA deceleration. | The payoff for safe long preparation, not the default answer to every danger. |

### Content rules

- C2 `Rift Snare`, C5 `Last Guard`, C1/C3/C5 healing and C6 `Breather` are protected examples of lower-stage identity. A future numerical pass must not make them obsolete through raw C7–C10 damage alone.
- An entry may contain multiple data-driven effects only if each has a clear preview line and the visible current state makes the compound meaningful. Empty riders and hidden conditional math are forbidden.
- A response tied to the displayed enemy action is unavailable or clearly labeled when that action kind cannot consume it. For example, direct-hit mitigation must not pretend to protect a resource-loss pattern.
- The first vertical slice has one Gatebreaker. `DAMAGE_AOE` or multi-enemy language cannot pretend to create value it does not have in that slice.
- A stage cannot rely on a new enemy roster, a card collection system, passive cooldowns, or a future meta loop to be useful.

## 5. Preview, feedback and teaching

The Skill preview must show structured text, not merely an icon or generated image:

```text
C2 ATK · Rift Snare
Target: Enemy
Effect: Current Gatebreaker pattern ETA +N seconds (deceleration)
Unaffected: Your board-play opportunity
Cost on CONFIRM: 2 Combo + N MP
```

```text
C2 SUP · Rally Step
Target: Player
Effect: Board-play opportunity +N seconds (acceleration)
Unaffected: Gatebreaker current-pattern ETA
Cost on CONFIRM: 2 Combo + N MP
```

After confirmation, the combat surface must show the same target-separated result beside the unchanged comparison value: enemy ETA moves while board time stays marked unchanged, or board-play opportunity changes while enemy ETA stays marked unchanged. These messages must remain visible long enough to explain the consequence before normal battle pressure returns.

The first-session briefing teaches this in one contrast: **"Slow the Gatebreaker to gain pattern time; accelerate yourself to gain board time. They are different effects."** The safe tutorial may demonstrate one, but must not imply that an unshown effect already works in runtime.

## 6. Fresh feasibility classification

| Surface | Current evidence | Classification | Required Phase 2 boundary |
| --- | --- | --- | --- |
| Category → resolved preview → explicit confirm | Existing pause token, category selection, preview/commit split and rollback in `ProductionSkillSession`. | `PARTIAL` | Replace manual technique-id/Tier-grid selection with the deterministic C1–C10 lane resolver and bounded fallback transaction. |
| Enemy current-ETA acceleration/deceleration | `EnemyActionScheduler` owns `_remaining_seconds`, current action id and a commit boundary. | `FEASIBLE_WITH_NEW_EFFECT_PRIMITIVE` | Add an exact-action-id ETA adjustment primitive; clamp safely at the scheduler commit boundary and log before/after ETA. |
| Player board-play acceleration/deceleration | Current runtime ticks the active workspace but owns no player-side board-time window or duration state. | `PARTIAL` | Create a bounded player board-time controller; its state must persist through workspace switching, pause exactly with simulation, and never mutate enemy ETA. |
| Existing data-driven effects | JSON definitions already use effect arrays; the catalog and executor validate a finite effect vocabulary. | `PARTIAL` | Add only the required target/time-domain primitives and data validation. Do not create per-skill scripts. |
| Existing `CONDITIONAL_MULTIPLIER` claim | The catalog accepts it, but `ProductionTechniqueResolver` skips it during resolution. | `CONFLICT` | Do not author a Stage effect that depends on it until it is either implemented with tests or removed from authored content. |
| Current Stage 1–10 player promise | Runtime catalog, combat state and CHAIN config still cap Tier/Stock at 6; data is legacy manual Tier 1–6. | `BLOCKED_UNVERIFIED` for runtime | Align CHAIN-038 and SKILL-039 first; this document does not promote content into data or runtime. |

The technical assessment is grounded in the current scheduler and pause implementation plus the official Godot documentation: [pausing and process modes](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html), [SceneTree timers](https://docs.godotengine.org/en/stable/classes/class_scenetree.html), and [Engine time scale](https://docs.godotengine.org/en/stable/classes/class_engine.html). Godot supports timer/process separation, but a global time scale would affect delta-driven simulation broadly, so it is explicitly rejected for this feature.

## 7. Phase 2 acceptance contract, not authorization

Before any implementation begins, one bounded implementation contract must specify data schema, exact seed values, UI nodes, telemetry names, controller ownership and tests. It must prove at least:

1. C1–C10 resolves from actual Combo and no manual lower-stage browse exists.
2. A player can intentionally stop at C5 and receive the C5 effect; the MP-shortage fallback is not used in that case.
3. Player acceleration/deceleration changes only player board-play opportunity; enemy ETA is byte-for-byte unchanged over the same simulated interval.
4. Enemy acceleration/deceleration changes only the visible current action ETA; player board-play opportunity is unchanged, unknown future actions are untouched and the commit boundary stays valid.
5. Pause/preview/cancel make no timing or resource mutation; `CONFIRM` applies the displayed effect exactly once and resumes the same battle state.
6. Legacy `CONDITIONAL_MULTIPLIER` cannot silently produce a weaker cast than its preview.
7. CHAIN cap-10/diagonal/MP-lock/per-wave reward and Skill C1–C10 alignment pass deterministic tests before target-resolution runtime and Human first-exposure validation.

No Godot scene, runtime asset, production seed, test result, target-device render, Human usability result or player-experience result is created by this GDD.

## 8. Adversarial review closeout

| Loop | Attack | Resulting correction |
| --- | --- | --- |
| 1 — canon drift | Could high Combo manually choose C5 and recreate the rejected Tier browser? | No. Deliberate C5 is only reached by stopping the CHAIN at C5; manual down-selection remains forbidden. |
| 2 — time-axis bleed | Could player haste/slow change the enemy timer through global time scale? | No. Target and domain are separate; global `Engine.time_scale` is prohibited. |
| 3 — hidden-information abuse | Could an ETA skill change a future unseen pattern? | No. It binds only to the displayed current Telegraph action id. |
| 4 — false runtime claim | Could the legacy multiplier or status system make an authored effect appear to work when it is skipped/unwired? | No. The multiplier conflict is recorded and new time-control content remains not implemented until a resolver/test path exists. |
| 5 — low-stage dominance failure | Could C7–C10 numerical strength erase the reason to use C1–C6? | No. Protected low-stage identities and later Human observation are explicit balance gates; numerical values remain tuning seeds. |

Document-only evidence was rerun on the GDD branch: canonical-reference scan (Loop 1), actual cap/multiplier contradiction scan (Loop 2), player-flow/time-axis scan (Loop 3), full changed-path boundary scan including untracked files (Loop 4), and JSON/local-link/review-gate scan (Loop 5). All five passed. Two validation-command defects—an overly specific prohibition literal and a shell-escaped link-check regex—were corrected in the validation commands before a pass was accepted; neither was a repository-content defect.

`CLEAN_REVIEW_EXIT` applies to this Phase 1 document only. Runtime feasibility is `PARTIAL`, and Human/player evidence remains `NOT_RUN`.

## 9. Decision log

| Date | Change | Status |
| --- | --- | --- |
| 2026-08-28 | User approved intentional early Combo spend: prepare and resolve at the desired current Combo rather than manually down-select from a higher Combo. | `USER_APPROVED` |
| 2026-08-28 | User defined acceleration/deceleration by target: player affects board-play opportunity; enemy affects the visible next-pattern action timer. | `USER_APPROVED` |
| 2026-08-28 | Recorded the approved direction, plus a proposed content matrix, target-separated preview language, feasibility limits and Phase 2 gates. | `USER_REVIEW_REQUIRED / DOCUMENTED_NOT_IMPLEMENTED` |
