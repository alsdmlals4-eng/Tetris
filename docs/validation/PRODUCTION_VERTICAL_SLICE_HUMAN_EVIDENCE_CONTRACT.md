# Production Vertical Slice Human Evidence Contract

> Status: **NOT_RUN**
>
> Claim ceiling: **FUN_HYPOTHESIS** until real Human evidence exists.
>
> Method: `OBSERVE_FIRST` → short non-leading probes → evidence classification.
>
> First-attempt rule: **DO_NOT_COACH_DURING_FIRST_ATTEMPT** except for device/accessibility help that the shipped game itself would provide.

## 1. Purpose and authority boundary

This contract defines how the first representative 6–10 minute Vertical Slice will be evaluated by real players. It does **not** create new gameplay rules and it does not promote unmerged implementation claims.

Current gameplay authority remains:

1. `TETRIS-TIME-025` — Shared Player Turn Budget, READY, timeout, time modifiers, Tempo.
2. `TETRIS-CORE-024` — ordered turn/combat and Enemy Telegraph.
3. `TETRIS-SKILL-026` — Vanguard ATK / DEF / SUP × Tier 1–6 tactical Technique identities.
4. `TETRIS-BALANCE-027` — Line Energy / Chain Stock opportunity cost and Tier exposure.
5. `TETRIS-VISUAL-020` — current Vertical Slice visual direction.

The older `docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md` remains a broader implementation handoff reference only. Its **superseded timing clauses** such as independent phase timers, 30/30/30 timer resets, or per-phase unused-time discard never override `TETRIS-TIME-025` and must not be copied into current Production behavior.

An open Draft BUILD PR is implementation evidence only for its verified branch state. Until exact-head merge and post-merge readback, it is not merged-main runtime truth.

## 2. What the session must represent

The target first-exposure session is one production-quality representative Slice:

```text
Title
→ Frontier Gate Arrival
→ first real Tutorial Turn
→ Gatebreaker live battle
→ Result
→ Fast Retry / next goal
```

Target total session: **6–10 minutes**.

Representative scope:

- one Vanguard;
- one Gatebreaker;
- one Frontier Gate;
- actual Production Line puzzle;
- actual Production Swap-Match Chain puzzle;
- current Telegraph and lower-priority visible Next Forecast where applicable;
- one **Shared Player Turn Budget** across Line → Chain → Action;
- Line Energy and Chain Stock as non-interchangeable resources;
- contextual Tier 1–6 Technique choices;
- result feedback that makes player-action and enemy-action consequences attributable.

A debug harness, static mockup, isolated subsystem scene, or designer explanation is not a substitute for this representative flow.

## 3. Research method

### OBSERVE_FIRST

Use the broadest prompt that still exposes the intended content, such as “이 구간을 평소 게임하듯 진행해 주세요.” Do not tell the player the intended solution, resource relationship, optimal Tier, or where to look for a UI answer.

During the first attempt:

- watch what the player actually does before asking why;
- record deviations from design intent rather than correcting them immediately;
- do not confirm whether an action is correct while the player is deciding;
- do not explain Telegraph, Energy, Stock, Tier, READY, Tempo, or forecast-control unless the shipped experience itself provides that explanation;
- only intervene when progress is otherwise impossible, accessibility/device operation requires it, or the session would produce no additional evidence;
- every intervention is itself evidence and must be recorded.

### OBSERVE_THEN_PROBE

After the relevant decision or after the first attempt, use short non-leading questions to understand motivation. Observation answers **what happened**; the probe helps distinguish **why it happened**.

Recommended probes:

1. “방금 적이 무엇을 하려고 했다고 생각했나요?”
2. “Line과 Chain에서 각각 무엇을 얻었다고 생각했나요?”
3. “왜 그 Technique와 Tier를 골랐나요?”
4. “시간을 어디에 더 썼고 왜 그렇게 했나요?”
5. “지금 위협과 다음 Forecast를 어떻게 구분했나요?”
6. “방금 선택이 결과를 어떻게 바꿨다고 생각하나요?”
7. “가장 늦게 찾았거나 헷갈린 정보는 무엇이었나요?”
8. “다시 한다면 무엇을 다르게 하겠나요?”

Avoid leading questions such as “Shared Timer가 이해됐나요?” or “낮은 Tier가 더 효율적인 상황인 걸 알았나요?”.

## 4. Directional A / B / C sessions

The initial Human gate uses **three independent first-exposure directional sessions: A, B, C** when feasible. This is a qualitative design-direction gate, not statistical population validation.

Prefer at least two familiarity profiles across the three sessions, for example:

- falling-block puzzle familiarity;
- match-3 / swap-match familiarity;
- tactical/turn-based combat familiarity;
- low familiarity with one or more of the above.

Participants should not read internal design/canon documents before first exposure. Record familiarity tags rather than treating one participant as representative of the whole market.

## 5. Evidence dimensions

### A. ONBOARDING_COMPREHENSION

Observe whether the player can move from Title → Gate Arrival → first real Turn without mechanic coaching and can form a usable first mental model from the shipped presentation.

Evidence questions:

- Do they know the immediate objective?
- Can they identify what must be acted on now?
- Can they proceed after a mistake without a moderator explaining the system?

### B. TELEGRAPH_RESPONSE

The current Enemy Telegraph must change or constrain a real player decision rather than acting as decorative information.

Evidence questions:

- Does the player notice the current threat before committing the Action?
- Can they explain, in their own words, what they expected the enemy to do?
- Does their resource/Tier choice ever respond to the threat?

### C. SHARED_BUDGET_COMPREHENSION

The player must experience one **Shared Player Turn Budget**, not three independent timers.

Evidence questions:

- Do they behave as though time spent in Line reduces time available for Chain/Action?
- Does READY read as an intentional “stop here and carry remaining time forward” decision?
- Do they mistake the timer for an enemy ETA, a phase-reset clock, or background Combat Clock?
- Does pressure create meaningful allocation rather than pure panic or paralysis?

Exact seconds and Tempo curve remain `TUNE_REQUIRED`.

### D. DUAL_RESOURCE_CHOICE

Both puzzle stages must matter to combat decisions.

Evidence questions:

- Does the player associate **Line Energy** with Line performance?
- Does the player associate **Chain Stock** with Chain performance and Tier access?
- Do they understand that Energy and Stock are not interchangeable?
- Does at least one decision expose a real tradeoff between spending more Shared time on Line versus Chain?

### E. TIER_VIABILITY

Tier is a tactical commitment band, not a linear “always pick the highest available” ladder.

Evidence questions:

- Can the player give a reason for choosing a lower Tier after tutorial exposure?
- Does a **lower Tier** remain understandable as an efficient, finishing, preserving, or immediate-response option?
- Does routine hoard-to-6 or instant-dump behavior become the only intelligible policy?
- Does Tier 6 feel like a signature commitment candidate rather than housekeeping?

Automated dominance fixtures can reject obvious impossible/strict-dominance states, but only Human evidence can validate actual choice comprehension.

### F. FORECAST_CONTROL

Current-vs-future response ownership must remain legible:

- DEF T5 `Rift Ward` responds to the **current** telegraphed resource-loss threat.
- ATK T5 / SUP T5 future control acts only on a qualifying **visible Next Forecast** and exact action id.

Evidence questions:

- Can the player distinguish “지금 막는 것” from “다음에 보이는 것을 준비해서 제어하는 것”?
- Does the lower-priority forecast remain findable without competing with the current Telegraph?

### G. VISUAL_READABILITY

`TETRIS-VISUAL-020` is validated here as **gameplay readability under the intended art direction**, not as a simple taste poll.

Critical hierarchy:

1. current Telegraph;
2. active phase and one Shared Timer;
3. active puzzle board and legal interaction;
4. Energy / Chain Stock / legal Tier-cost information;
5. Technique choice and target;
6. lower-priority Next Forecast;
7. decorative character, boss, VFX and background detail.

The current concept images — Battle Screen Composition Mockup, Frontier Shield Vanguard, and Asymmetric Breach Colossus — are visual references, not runtime proof and not final assets by themselves.

The Battle Screen Composition Mockup's historical `3.2s / 8.4s / 14.0s` enemy ETA-style labels are visual residue. They must not be interpreted as current timing authority or reproduced as independent enemy/phase timers.

Readability checks:

- current Telegraph remains more salient than the lower-priority Next Forecast;
- one Shared Timer cannot reasonably be mistaken for an enemy ETA or phase-reset timer;
- Line/Chain cells remain readable under character art, VFX, pixel-fracture accents, lighting and screen effects;
- active stage and legal Technique choices can be found without scanning the entire screen repeatedly;
- cost, target and disabled/legal state are distinguishable at decision time;
- damage, mitigation, resource loss/protection and enemy response are attributable after resolve;
- decorative motion/effects do not cover critical information during the moment it must be read.

A participant disliking anime/pixel styling is not automatically a `VISUAL_READABILITY` failure. Conversely, liking the art does not prove that the combat UI is readable.

### H. RESULT_FEEDBACK

The player should connect the puzzle/time/resource/Technique decision to its result.

Evidence questions:

- Can they explain what their Action changed?
- Can they separate Player Action Resolve from Enemy Resolve?
- After a bad outcome, can they state at least one actionable reason to change the next attempt?

## 6. Minimum evidence receipt

Each session receipt records, when available:

- session id `A`, `B`, or `C`;
- date;
- build/commit/PR SHA actually played;
- deterministic seed or encounter seed;
- device/input method;
- participant familiarity tags;
- whether internal design knowledge was absent before first exposure;
- completion / abandonment;
- every moderator intervention and timestamp;
- first major confusion and its consequence;
- READY / timeout behavior;
- meaningful Line Energy and Chain Stock state at key decisions;
- selected lane / Tier / Technique where relevant;
- current Telegraph and visible Next Forecast involved in the decision;
- result and player explanation;
- screen/video recording reference if consent and tooling allow it;
- timestamped observation notes.

Telemetry is useful once the representative runtime exists, but telemetry is not required to define this planning contract and cannot replace observation/interview evidence for comprehension.

## 7. Severity and gate

Every finding is classified by impact on the intended first-session experience.

### BLOCK

Use `BLOCK` when any core issue makes the representative Slice invalid as a Human proof, including:

- the player cannot progress without mechanic coaching that the shipped game would not provide;
- a core rule is repeatedly interpreted backwards in a way that changes decisions;
- current Telegraph / next Forecast / Shared Timer hierarchy causes repeated high-impact wrong decisions;
- critical puzzle/UI information is materially obscured by art or VFX;
- the player cannot attribute the combat result to their own Action and the enemy response;
- the test build does not actually represent the current canon being evaluated.

### REVISE

Use `REVISE` when there is no hard blocker, but a material issue repeats across independent sessions or reliably pushes core decisions in the wrong direction. Revise the smallest owning layer — tutorial, UI hierarchy, wording, timing seed, encounter seed, economy seed, visual treatment, or implementation — then re-run the affected evidence.

### PASS

Use directional `PASS` only when:

- no `BLOCK` finding remains;
- the player can complete the core representative flow without core-mechanic coaching;
- critical concepts are demonstrated by both behavior and post-play explanation, not questionnaire agreement alone;
- no same high-severity misunderstanding repeats unresolved across the directional sessions;
- any remaining issue is explicitly bounded and does not invalidate the core design hypothesis.

The gate is **PASS / REVISE / BLOCK**. `PASS` is directional evidence for the tested Slice/build; it is not statistical market proof, final commercial validation, or proof that all players will find the game fun.

## 8. Evidence ceiling / Implementation Reality Gate

Current state remains **NOT_RUN** until a real representative build is played and receipts exist.

Evidence classes must not be promoted:

- static canon/docs → proves approved design intent only;
- automated tests → can prove deterministic legality/state transitions/known dominance guards, not fun or comprehension;
- designer/developer self-play → can prove smoke/runtime behavior, not external first-time onboarding;
- concept art/mockups → can prove visual target intent, not runtime visual readability;
- Draft PR branch evidence → proves only that branch at its exact verified head;
- merged runtime + device receipt → proves callable/observed runtime behavior on that target;
- Human session receipt → may support the specific comprehension/readability/choice claims actually observed.

Until Human receipts exist, fun, tension, readability, Tier-choice comprehension and final balance remain **FUN_HYPOTHESIS** / `TUNE_REQUIRED` as appropriate.

## 9. What happens after the first Human gate

If `PASS`:

- retain the core model;
- tune exact seconds, Energy cost/gain, effect magnitude, encounter pressure and visual emphasis from observed evidence;
- do not use the pass as justification to add classes, bosses, biomes, currencies or new subsystems before the representative Slice is stable.

If `REVISE`:

- fix the smallest owning cause;
- preserve the raw receipt;
- re-run only enough scope to disprove/confirm the revised hypothesis, then do a representative regression pass.

If `BLOCK`:

- stop breadth expansion;
- resolve the blocking mental-model/readability/flow issue before treating the Slice as production-direction proof.

## 10. External method basis — discovery, not project canon

This procedure adapts standard Games User Research practice: start from design intent, prefer broad/undirected tasks, avoid teaching the solution through moderation, observe actual behavior, and use short neutral probes to understand motivation.

Reference reading:

- https://gamesuserresearch.com/find-usability-issues-in-games-with-playtests/
- https://gamesuserresearch.com/choose-the-right-playtest-method/
- https://gamesuserresearch.com/running-a-games-user-research-study/
- https://gamesuserresearch.com/how-to-run-unbiased-player-interviews/

These external references inform the research method only. They do not override Tetris gameplay canon.
