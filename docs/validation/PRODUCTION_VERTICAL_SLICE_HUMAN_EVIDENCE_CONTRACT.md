# Production Vertical Slice Human Evidence Contract

> Status: **NOT_RUN**
>
> Core authority: `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause`
>
> Claim ceiling: **FUN_HYPOTHESIS** until real Human evidence exists.
>
> Method: `OBSERVE_FIRST` → short non-leading probes → evidence classification.
>
> First-attempt rule: **DO_NOT_COACH_DURING_FIRST_ATTEMPT** except for device/accessibility help that the shipped game itself would provide.

## 1. Purpose and authority boundary

This contract defines how a representative 6–10 minute CORE-029 Vertical Slice will be evaluated by real players. It does not create gameplay rules, promote unmerged branch claims, or treat concept art as runtime evidence.

Current authorities:

1. `TETRIS-CORE-029` — continuous real-time combat, persistent LINE↔CHAIN switching, full Skill tactical pause, enemy ETA/commit scheduling, 60/40 battle composition.
2. `TETRIS-SKILL-026` — retained ATK / DEF / SUP × Tier 1–6 Technique identity where not turn-bound.
3. `TETRIS-BALANCE-027` — retained Line Energy / Chain Stock opportunity cost and Tier commitment.
4. `TETRIS-VISUAL-028` — Hand-Drawn Mystic Fantasy + Clean Puzzle UI.
5. `TETRIS-IMAGE-030` — production images require a real runtime consumer.

`TETRIS-CORE-024` and `TETRIS-TIME-025` are historical provenance where they define ordered turns, Shared Player Turn Budget, READY, timeout/PASS, or Tempo.

## 2. Representative session

Target total session: **6–10 minutes**.

The tested Slice must contain the actual production interaction, not an explanatory sheet or isolated subsystem demo:

```text
Title / entry
→ Frontier Gate encounter starts
→ COMBAT_RUNNING
   ↔ LINE
   ↔ CHAIN
   ↔ TACTICAL_PAUSE_SKILL
→ Victory | Defeat
→ Result / Retry
```

Minimum representative scope:

- one Vanguard;
- one Gatebreaker;
- one Frontier Gate encounter;
- one large left Puzzle Surface switching between persistent LINE and CHAIN states;
- persistent right Combat/Threat/Resource/Skill surface;
- real-time enemy threat with current Telegraph + ETA and lower-priority Next Forecast where authored;
- Line Energy and Chain Stock as non-interchangeable resources;
- ATK / DEF / SUP → T1–T6 → detail → explicit USE;
- Skill opens `TACTICAL_PAUSE_SKILL` and fully pauses simulation;
- manual pause is distinct from Skill tactical pause;
- actual gameplay-consumed visual assets where available, never explanation-only sheets presented as runtime proof.

## 3. Measurement boundary

Record separate time classes when telemetry/runtime support exists:

- **wall-clock** encounter duration;
- **active combat simulation time**;
- **tactical-pause duration**;
- manual-pause duration.

Do not classify a player as slow merely because they read the paused Skill UI for longer. CORE-029 intentionally separates real-time execution pressure from paused tactical cognition.

## 4. Research method

### OBSERVE_FIRST

Use a broad prompt such as “이 구간을 평소 게임하듯 진행해 주세요.” Do not teach the intended solution, correct workspace order, resource relationship, ideal Tier, or where to look for a UI answer.

During first exposure:

- observe before asking why;
- record deviations instead of correcting them immediately;
- do not tell the player when to switch LINE/CHAIN;
- do not explain that switching preserves both board states unless the shipped experience itself communicates it;
- do not explain that Skill fully pauses simulation unless the shipped presentation communicates it;
- do not explain optimal Energy/Stock/Tier use;
- record every moderator intervention.

### OBSERVE_THEN_PROBE

After a decision or the first attempt, use non-leading questions such as:

1. “방금 적이 무엇을 하려고 했다고 생각했나요?”
2. “왜 LINE이나 CHAIN으로 전환했나요?”
3. “다시 돌아왔을 때 보드가 어떻게 될 거라고 예상했나요?”
4. “Skill 화면을 열었을 때 전투 시간이 어떻게 된다고 생각했나요?”
5. “Energy와 Chain Stock을 각각 어디서 얻는다고 생각했나요?”
6. “왜 그 Technique와 Tier를 골랐나요?”
7. “가장 늦게 찾았거나 헷갈린 정보는 무엇이었나요?”
8. “가장 기억에 남는 순간은 무엇이었나요? 왜 그랬나요?”
9. “다시 한다면 무엇을 다르게 하겠나요?”

## 5. Directional A / B / C sessions

**THREE_SESSIONS_REQUIRED_FOR_PASS**: directional `PASS` requires three valid, independent first-exposure receipts A/B/C.

- one or two sessions may produce preliminary findings only;
- `REVISE` or `BLOCK` may be issued earlier if evidence already supports it;
- invalidated sessions do not count;
- preserve participant familiarity tags instead of treating one player as representative of the market.

## 6. Evidence dimensions

### A. REALTIME_THREAT_READABILITY

Observe whether the player notices what the enemy is doing while actively solving the puzzle.

Check:

- Current Telegraph is noticed before consequences land;
- current ETA is understood as enemy action timing, not a player-turn timer;
- Next Forecast remains findable without competing with Current;
- the player sometimes changes what they are doing because the threat matters.

### B. WORKSPACE_SWITCH_COMPREHENSION

Observe whether free `LINE ↔ CHAIN` switching is understood as an intentional tactical tool rather than a stage order.

Check:

- the player discovers or understands both directions of switching;
- they do not wait for a nonexistent phase completion before switching;
- they can explain why they chose one workspace over the other at a real moment of pressure.

### C. WORKSPACE_STATE_PERSISTENCE

The player should understand that switching changes the visible/active workspace, not the identity of either board.

Check:

- after returning to LINE, they recognize the prior Line board as preserved;
- after returning to CHAIN, they recognize the prior Chain board as preserved;
- switch behavior does not create an expectation of reroll/reset/free recovery;
- state preservation supports planning rather than surprise.

### D. TACTICAL_PAUSE_COMPREHENSION

Skill must read as a full tactical pause.

Check:

- the player understands that enemy ETA stops while Skill is open;
- frozen puzzle/combat context remains legible;
- they are willing to read Technique details rather than rushing because they think combat is still advancing;
- cancel and USE resume the exact paused combat situation without hidden time progress.

### E. LINE_ENERGY_VS_CHAIN_STOCK

Check whether the dual-resource distinction is understood:

- Line produces **Energy**;
- Chain/Combo produces **Chain Stock** / Tier access;
- Energy and Chain Stock are not interchangeable;
- the player can describe a real reason to stay in one workspace longer or switch to the other.

### F. TECHNIQUE_DECISION_QUALITY

Check:

- ATK / DEF / SUP categories are understandable;
- T1–T6 reads as tactical commitment, not simply “highest number wins”;
- row selection/detail inspection does not feel like immediate resource spend;
- explicit USE is understood as the commit point;
- lower Tier remains a plausible choice in at least some contexts.

Turn-bound Techniques such as Haste/Battle Trance remain outside a positive Human claim until their CORE-029 realtime semantics are separately approved and implemented.

### G. SIXTY_FORTY_LAYOUT_READABILITY

`TETRIS-VISUAL-028` is evaluated as gameplay readability, not taste polling.

Target hierarchy:

1. large left Puzzle Surface remains the primary manipulation area;
2. right Combat/Threat surface remains continuously readable;
3. Current Telegraph + ETA is high priority;
4. HP / Energy / Chain Stock remain findable;
5. LINE / CHAIN / SKILL controls remain obvious;
6. Skill-open state prioritizes ATK / DEF / SUP → T1–T6 → detail → USE while frozen puzzle/threat context remains visible;
7. decorative character, boss, VFX, and background never obscure critical puzzle or threat information.

Target desktop composition is approximately **60/40**. This is a readability target, not a fixed pixel law.

Visual evidence must use actual runtime-consumed assets when making runtime-readability claims. A concept or explanation sheet cannot substitute for the screen the game actually renders.

### H. PLAYER_EXPERIENCE_SIGNAL / MEMORABLE_MOMENT

Look for at least one observable sequence of:

**pressure → deliberate switch/Skill decision → readable payoff**.

Record:

- what pressure caused the plan change;
- whether the choice was LINE, CHAIN, Skill, Technique, or Tier;
- what result the player attributed to that choice;
- what moment they recall without being told what the intended highlight was;
- whether failure produces an understandable “next time I would…” thought.

Use the token `MEMORABLE_MOMENT` in receipts for the first strong recall candidate.

This remains a directional experience signal, not proof of universal fun, retention, or market success.

## 7. Minimum evidence receipt

Each session receipt records when available:

- session id A/B/C;
- date;
- exact build/commit/PR SHA played;
- deterministic encounter/puzzle seed;
- device/input method;
- participant familiarity tags;
- whether internal design knowledge was absent before first exposure;
- completion / abandonment;
- moderator interventions with timestamps;
- first detected enemy threat and what the player thought it meant;
- first self-initiated LINE↔CHAIN switch and reason;
- evidence that both workspace states persisted across return;
- first Skill-open moment and whether the player understood full pause;
- key Energy / Chain Stock states;
- selected lane / Tier / Technique / USE outcome;
- wall-clock, active combat simulation time, tactical-pause duration if telemetry exists;
- first major confusion and consequence;
- `MEMORABLE_MOMENT` candidate and player explanation;
- screen/video reference if consent/tooling permit.

## 8. Gate

### BLOCK

Examples:

- real-time enemy threat cannot be read while solving the puzzle;
- switching appears to reset/reroll state or is repeatedly misunderstood as stage progression;
- Skill appears paused visually but hidden enemy/puzzle/status time continues;
- player cannot distinguish Energy and Chain Stock;
- critical 60/40 UI information is obscured;
- the build under test does not actually implement CORE-029;
- a concept/reference image is presented instead of the runtime screen whose readability is being claimed.

### REVISE

Use when a material issue repeats or pushes core decisions in the wrong direction without invalidating the whole Slice. Fix the smallest owning layer, then re-test affected evidence.

### PASS

Use directional PASS only when:

- three valid independent A/B/C first-exposure receipts exist;
- no BLOCK remains;
- core flow is completable without mechanic coaching;
- real-time threat, free switching, persistent state, tactical pause, dual resources, and Technique commit are demonstrated by behavior plus explanation;
- the 60/40 screen remains readable during representative pressure;
- at least one pressure → deliberate choice → readable payoff candidate is observed.

The gate is **PASS / REVISE / BLOCK**.

## 9. Implementation Reality Gate

Current state remains **NOT_RUN** until real Human receipts exist.

Evidence classes must not be promoted:

- static canon/docs → approved intent only;
- generated image/reference → visual candidate only;
- imported asset + actual runtime consumer → runtime wiring evidence;
- automated tests → deterministic behavior only, not fun/comprehension;
- Draft PR → exact-branch evidence only;
- merged runtime/device receipt → observed runtime behavior on that target;
- Human receipt → only the specific comprehension/readability/choice/experience claims observed.

Until Human receipts exist, fun, readability, memorable payoff, and final balance remain **FUN_HYPOTHESIS** / `TUNE_REQUIRED` as appropriate.
