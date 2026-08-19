# Vertical-Slice-First Production Design

- Status: **PROPOSED_CANON / user-approved direction, written-spec review pending**
- Date: 2026-08-20
- Repository: `alsdmlals4-eng/Tetris`
- Scope: project-wide production and validation policy for the first complete playable slice
- Supersedes: any interpretation that a debug/system-only POC is a valid player-facing milestone

## 1. Decision

This project does **not** use a system-only player-facing POC as its primary validation milestone.

The first meaningful user playtest must be a **production-quality short Vertical Slice** in which the actual intended game experience is present together:

- production Line puzzle play;
- production Chain puzzle play;
- manual mode switching and board persistence;
- Energy / Chain Stock / Skill combat;
- enemy intent and time pressure;
- production UI and UX;
- approved visual direction and integrated game images/assets;
- animation and VFX;
- music, SFX, UI audio, and final-for-slice audio mix;
- tutorial/onboarding needed to understand the slice;
- title/start, pause/settings, encounter, and result flow needed to experience the slice as a small finished game;
- telemetry and verification needed to explain the playtest result.

The Vertical Slice is deliberately **short in content but complete in presentation and system integration**.

Initial duration target: **approximately 6–10 minutes for one complete run**. The exact duration may be tuned, but feature completeness may not be reduced merely to hit the time target.

## 2. Terminology and gate policy

### 2.1 Engineering verification

During development, automated tests, headless scenes, debug event sources, isolated harnesses, deterministic simulations, test fixtures, screenshot captures, and developer-only diagnostic UI are allowed.

They exist to verify implementation correctness and reduce integration risk.

They are called **engineering verification**, not POC and not player validation.

### 2.2 Vertical Slice playtest

The first user-facing evaluation milestone is **Vertical Slice Playtest**.

It may begin only after the Production Completeness Gate in this document is fully satisfied.

### 2.3 Forbidden milestone inflation

Do not report any of the following as a playable POC, Vertical Slice, or proof of game feel:

- buttons that simulate Line/Chain outcomes;
- placeholder rectangles in place of final-for-slice puzzle pieces;
- temporary debug HUD as production UX;
- silent gameplay where audio is part of the intended feedback loop;
- unstyled UI where final information hierarchy has not been implemented;
- isolated combat/resource simulation without real Line and Chain input;
- animation/VFX-free skill activation when final combat feedback depends on animation/VFX;
- gameplay screenshots with temporary art presented as proof of final visual readability.

## 3. Why this policy exists

The core game is not only a rules engine. The intended experience depends on simultaneous perception of:

- falling-piece readability;
- chain readability;
- mode identity and switching cost;
- enemy telegraph urgency;
- resource visibility;
- skill choice clarity;
- audiovisual reward for clears, chains, defense, healing, damage, and high-tier actions;
- pacing created by music/SFX/VFX and the Combat Clock.

A system-only build can verify logic but cannot reliably answer whether the game is immersive, legible, satisfying, or coherent as a product.

Therefore player feedback is postponed until the slice can represent the intended experience rather than a debug abstraction.

## 4. Approaches considered

### A. Full Vertical Slice first, staged engineering integration — **ADOPT**

Each production subsystem is implemented and verified independently, merged in controlled stages, then assembled into one complete short slice. User playtesting begins only after all production completeness gates pass.

Advantages:

- player feedback is about the intended game rather than placeholders;
- visual/audio/UX interactions are evaluated in their real context;
- each engine remains independently testable;
- production code can be integrated incrementally without calling incomplete builds POCs;
- avoids throwing away large amounts of temporary player-facing UI/art.

Cost:

- first user playtest occurs later;
- more production work happens before subjective validation.

Mitigation:

- aggressive internal automated and developer verification before the Vertical Slice;
- deterministic replay/seeds;
- subsystem-specific acceptance gates;
- continuous visual/audio integration rather than a late polish pass.

### B. System POC first, polish after gameplay validation — **REJECT**

This is efficient for pure rules validation, but it does not meet the project goal because the user cannot judge immersion, clarity, game feel, audiovisual reward, or the real cost of switching between Line and Chain.

### C. Systems and content/art developed mostly in parallel, late integration — **REJECT AS DEFAULT**

Parallel work can shorten schedule, but late integration creates high risk of mismatched UI dimensions, unreadable VFX, audio masking, timing conflicts, and duplicated assets.

Limited parallel asset production is allowed only after shared interface contracts, art direction, timing budgets, and asset specifications are approved.

## 5. Architecture

Use **two independent production puzzle engines plus a common combat adapter**.

```text
Production Line Engine ---- Line Events ----┐
                                            ├---- Puzzle/Combat Adapter ---- Combat State
Production Chain Engine --- Chain Events ---┘
```

The engines own puzzle mechanics and puzzle state only.

The combat layer owns:

- HP;
- Energy;
- Chain Stock;
- Score aggregation;
- Skill eligibility/spending;
- Attack / Defense / Heal resolution;
- enemy timeline;
- terminal battle state.

UI reads state and submits intent. It must not directly mutate combat resources or puzzle boards.

The existing debug event-source boundary may remain as an automated-test harness, but the shipping/Vertical-Slice scene must use production engines.

## 6. Production Line Engine completeness

The Line engine must be implemented as a complete modern falling-block experience before Vertical Slice playtesting.

Required for the first slice:

- 10 × 20 visible Matrix with appropriate hidden/spawn rows;
- seven tetromino gameplay set;
- deterministic seeded randomizer;
- 7-Bag piece generation;
- spawn rules;
- Next queue, target **5 visible**;
- Hold with one hold per active piece;
- Ghost piece;
- left/right movement;
- configurable DAS;
- configurable ARR;
- gravity;
- soft drop;
- hard drop;
- lock delay;
- bounded lock-delay reset behavior;
- SRS-style rotation state model;
- normal wall/floor kick data;
- I-piece-specific kick data;
- collision and placement validation;
- line detection and compaction;
- Single / Double / Triple / 4-Line clear;
- Combo tracking;
- Back-to-Back difficult-clear tracking;
- Spin recognition sufficient for the scoring profile used by the slice;
- Perfect Clear recognition;
- drop score support;
- Line Score event generation;
- Energy event generation;
- top-out / block-out handling defined for the combat layer;
- exact state freeze/resume across LOCK/SUSPENDED;
- exact preservation of active piece, queue, hold, timers, and board state when switching modes;
- deterministic replay/test fixture support.

Input feel parameters must be data-configurable rather than buried in control code.

## 7. Production Chain Engine completeness

The Chain engine must be implemented as a complete falling-pair chain puzzle experience before Vertical Slice playtesting.

Required for the first slice:

- 6 × 12 visible field with required spawn/hidden handling;
- deterministic seeded pair queue;
- initial four-color production profile;
- two-piece pair with pivot/child relationship;
- spawn rules;
- left/right movement;
- rotation in both directions;
- wall/floor collision behavior;
- narrow-space/quick-turn behavior where required by the approved control model;
- gravity;
- fast/soft drop;
- lock/placement timing;
- split landing when pair pieces settle at different heights;
- per-cell gravity after clears;
- orthogonal connected-component detection;
- clear groups of 4+ matching pieces;
- simultaneous multiple-group clear;
- simultaneous multi-color clear;
- cascade resolution;
- exact N-Chain counting;
- Large Group event data;
- Color Bonus event data;
- Group Bonus event data;
- All Clear recognition;
- reference Chain Score calculation profile;
- completed-chain event only after the full cascade stabilizes;
- Chain Stock update from the completed chain result;
- top-out handling defined for the combat layer;
- exact state freeze/resume across LOCK/SUSPENDED;
- mode-switch requests during RESOLVING queued until stable;
- deterministic replay/test fixture support.

Timing such as fall speed, clear delay, cascade delay, and input repeat must be data-configurable.

## 8. Dual-board integration

The existing core invariant remains canonical:

- exactly one active visible puzzle board;
- inactive board is `SUSPENDED` and does not advance;
- a mode switch lands the destination in `LOCKED`;
- explicit `RUN` is required to resume the destination;
- `LOCK` freezes only puzzle simulation/input;
- Combat Clock continues through LOCK, switching, and Skill selection;
- puzzle resolution is atomic;
- queued switch during RESOLVING applies only after stable resolution;
- state restoration must be frame/timer accurate enough that switching cannot create or destroy puzzle advantage.

The inactive board may have a compact visual preview, but it receives no puzzle input.

## 9. Combat slice completeness

The Vertical Slice must include at least one production-quality class kit and one production-quality encounter sequence.

The class name/fantasy is selected before art/audio production for the slice. The core API remains class-agnostic.

Required class kit:

- Attack option(s);
- Defense option(s);
- Heal/recovery option(s);
- Tier progression that visibly demonstrates low and high Skill Tiers;
- production iconography;
- production animation/VFX/SFX for each Skill used in the slice;
- clear insufficient-resource feedback.

Required enemy sequence:

- visible next-action countdown;
- at least one normal damage action;
- at least one high-pressure/heavy action;
- at least one action that changes puzzle/combat priority rather than merely dealing damage;
- a short climax pattern or phase transition;
- production telegraph visuals and audio;
- production hit/defense/heal feedback;
- clear victory/defeat state.

The slice must force meaningful use of both Line and Chain rather than allowing one board to dominate the entire encounter.

## 10. UI/UX production gate

No debug-button UI is accepted as player-facing slice UI.

Required flow:

1. title/start screen;
2. minimal slice setup/class presentation if needed;
3. concise tutorial/onboarding;
4. battle HUD;
5. pause/settings;
6. victory/defeat/result screen;
7. restart/return flow.

Battle HUD must make these readable without opening a menu:

- player HP;
- enemy HP/status;
- next enemy action and countdown;
- at least one following intent when the encounter design exposes it;
- Energy;
- Chain Stock / available Skill Tier;
- active mode;
- LINE/CHAIN board state (`RUNNING`, `LOCKED`, inactive/suspended state);
- Skill choices and unavailable reasons;
- Score;
- high-value Combo/Chain feedback.

UX requirements:

- switching modes must be visually unmistakable;
- the destination's LOCKED state must be obvious;
- the player must never mistake a frozen puzzle for a hung game;
- enemy time continuing during LOCK must remain visible/audible;
- UI hierarchy must remain readable during large VFX events;
- production keyboard controls are required for the PC slice;
- Android/mobile integration remains outside this Vertical Slice unless explicitly promoted later;
- gamepad support is a separate gate unless promoted into the slice scope.

Basic production options required for the slice:

- master volume;
- music volume;
- SFX volume;
- UI volume when separated;
- screen/window setting needed for reliable Windows play;
- reduced-flash/reduced-shake or equivalent safety option when effects use significant flashing/shake.

## 11. Art and image production policy

The project does not use placeholder art as Vertical Slice evidence.

Before asset production:

1. research current comparable games and successful presentation patterns;
2. produce at least three materially distinct art/UI direction alternatives;
3. compare readability, production cost, consistency, identity, and long-term class/content extensibility;
4. approve one direction;
5. define a compact art bible/style contract.

Then use this asset workflow:

```text
reference proposal
→ approval
→ asset creation/generation
→ cleanup
→ structural/layer decomposition where useful
→ reusable-component classification
→ import profile
→ in-game integration
→ consistency/readability review
```

Reusable asset classes should include, where appropriate:

- puzzle cell frames;
- Line pieces and highlights;
- Chain pieces and expressions/details if used;
- board frames;
- mode tabs;
- resource icons;
- Skill icons;
- enemy intent icons;
- status icons;
- panels/buttons;
- VFX sprites/materials;
- hit/shield/heal motifs;
- environment/background layers;
- result/rank elements.

The repository is the file/source truth for integrated assets. Do not add a Figma dependency. Project/decision tracking may use Notion where useful, but gameplay asset truth must remain reproducible from repository files and documented source masters.

For generated images, keep reusable source/layer information when practical so subsequent class, enemy, UI, and effect work can maintain consistency rather than regenerating unrelated-looking assets.

## 12. Visual effects and animation gate

Required production-feedback categories for the slice:

### Line

- piece movement/lock feedback;
- line-clear feedback;
- Combo escalation;
- difficult-clear/B2B feedback;
- Spin feedback when recognized;
- Perfect Clear climax feedback;
- Energy gain feedback.

### Chain

- settle feedback;
- group clear;
- cascading movement;
- increasing Chain count feedback;
- multi-color/large-group emphasis where applicable;
- All Clear climax;
- Chain Stock/Tier gain feedback.

### Combat

- Skill activation;
- damage;
- Defense/shield/avoidance response;
- Heal/recovery response;
- enemy telegraph;
- enemy attack impact;
- phase/climax transition;
- victory/defeat.

Effects must communicate state first and spectacle second. VFX may not obscure the active puzzle board or enemy countdown at critical decision moments.

## 13. Audio production gate

Audio is part of the Vertical Slice, not a post-POC polish step.

Use Godot's named audio-bus routing as the baseline architecture.

Initial bus structure:

- Master;
- Music;
- SFX;
- UI;
- Ambience if the chosen art direction needs it.

Required slice audio:

- one production-quality encounter music track or adaptive music set;
- Line movement/rotation/lock/clear feedback;
- high-value Line technique stingers;
- Chain drop/settle/clear/chain escalation feedback;
- Energy gain;
- Chain Stock/Tier gain;
- Skill activation per slice Skill;
- damage/defense/heal;
- enemy intent warning;
- enemy attack;
- mode switch;
- RUN/LOCK state feedback where audio materially improves clarity;
- UI confirm/cancel/navigation where used;
- victory/defeat/result.

Mixing requirements:

- puzzle-critical SFX and enemy warnings remain audible over music;
- no sustained master clipping;
- high-Chain/high-Combo layering has a defined voice/polyphony policy;
- repeated common actions have pitch/variant policy where repetition becomes fatiguing;
- music/SFX synchronization may be used when it improves feel but must not change deterministic gameplay timing.

## 14. Benchmark interpretation

Benchmarks are used as **adopt / transform / exclude**, not as identity copying.

### Tetris Effect: Connected — adopt principle

Official product material describes music, backgrounds, sound, effects, and pieces as synchronized with play. Adopt the principle that audiovisual response is part of puzzle feel, not decoration added after rules validation.

### Puyo Puyo Tetris 2 — adopt principle

Official product material integrates Skill Battle, HP/resources, BGM/SE, visual skins, player settings, and tutorial content. Adopt the principle that combat systems, presentation, settings, and onboarding must coexist in the player-facing build.

### Transform

- branded presentation → independent game identity;
- automatic/competitive puzzle framing → dual-resource single-player combat framing;
- copied audiovisual motifs → project-specific art, sound, UI, and VFX language.

### Exclude

- copying logos, characters, branded UI, sound effects, music, or trade dress;
- treating another title's exact audiovisual timings or economy values as final balance for this game.

Commercial-release IP review remains a separate pre-release gate.

## 15. Engineering and testing strategy before player playtest

Delaying the user-facing playtest does **not** mean delaying verification.

Every production subsystem gets continuous engineering verification.

Required automated/test support:

- TDD for deterministic puzzle rules;
- fixed seeds;
- board-state fixtures;
- replayable input sequences;
- exact event assertions;
- Line scoring fixtures;
- Chain scoring/chain-resolution fixtures;
- freeze/resume tests;
- mode-switch resolution tests;
- Skill/resource tests;
- enemy timeline tests;
- scene instantiate/import tests;
- strict test-collection guard;
- telemetry schema tests.

Required integration evidence before Vertical Slice playtest:

- Windows runtime launch;
- production scene, not debug harness;
- both production puzzle engines controllable;
- full title → encounter → result flow;
- UI at target desktop resolution;
- representative screenshots/video captures for visual review;
- audio bus/mix verification;
- no player-facing placeholder/debug controls;
- no known blocker/Critical defects;
- stable target framerate on the user's Windows validation machine for the slice encounter.

## 16. Production Completeness Gate

The Vertical Slice Playtest is **BLOCKED** until all items below are PASS.

### Gameplay

- production Line engine complete;
- production Chain engine complete;
- dual-board freeze/resume complete;
- scoring complete for slice-supported techniques;
- Energy/Stock integration complete;
- Skill combat complete;
- enemy encounter complete;
- top-out/combat interaction defined and implemented for the slice.

### Presentation

- approved art direction;
- final-for-slice puzzle piece art;
- final-for-slice board/environment art;
- final-for-slice combat art;
- final-for-slice UI;
- production VFX/animation;
- production music/SFX;
- audio mix;
- tutorial/onboarding;
- title/pause/settings/results.

### Quality

- automated full suite PASS;
- Godot import/parse PASS;
- Windows runtime PASS;
- target-resolution visual review PASS;
- audio routing/mix review PASS;
- no visible debug simulation controls;
- telemetry/replay evidence working;
- known defects triaged with no playtest-blocking defect open.

Only after this gate passes may the build be called the **Vertical Slice candidate**.

## 17. Vertical Slice playtest protocol

Replace the old 45-second debug POC validation with a real playtest protocol.

Minimum first evaluation:

### Run A — first-experience run

- start from title screen;
- use only the onboarding the game provides;
- complete or fail the full 6–10 minute slice naturally;
- record confusion, readability issues, mode-switch understanding, and emotional peaks.

### Run B — deliberate/LOCK play

- intentionally use LOCK for Skill decisions;
- verify Combat Clock pressure remains understandable;
- examine whether this play style is viable without being trivial.

### Run C — continuous/mastery play

- keep RUNNING more often;
- use both modes aggressively;
- test whether Line and Chain each have a meaningful strategic purpose;
- observe audiovisual overload/readability under higher Combo/Chain activity.

Capture at minimum:

- run duration;
- time per mode;
- time LOCKED;
- mode-switch count;
- Energy generation/spending;
- chain-length distribution;
- Skill Tier/use distribution;
- Attack/Defense/Heal use;
- enemy actions answered/missed;
- top-out/recovery incidents;
- death/victory;
- framerate/performance evidence;
- player qualitative notes after each run.

The initial user playtest is not considered successful merely because the game is technically completable. It must also be sufficiently readable, coherent, and engaging to justify continuing the full production direction.

## 18. Existing PR #3 disposition

PR #3 currently implements a debug event-source Core POC/foundation.

Under this new policy:

- its debug event sources remain useful engineering fixtures;
- its automated combat/state tests remain valuable;
- its 45-second human debug-button playtest is **no longer the project's player-validation milestone**;
- player-facing debug UI must not survive into the Vertical Slice production scene;
- PR #3 should be reclassified as **Core Combat Foundation / Engineering Harness**, not a completed POC;
- after this written policy is approved, PR #3 may be reviewed against the narrower foundation criteria and merged if its current foundation code is verified, without requiring the obsolete debug 45-second human test;
- production Line, production Chain, final presentation, and Vertical Slice integration proceed as subsequent separately verified stages.

## 19. Planned implementation stages

After this design is approved, implementation planning should use these major stages:

1. **Core Combat Foundation normalization** — reclassify/close the debug POC milestone and preserve reusable foundation/tests.
2. **Production Line Engine** — full mechanics, scoring, input feel, render integration hooks, tests.
3. **Production Chain Engine** — full mechanics, chain/scoring, input feel, render integration hooks, tests.
4. **Production Dual-Board Integration** — actual engines replace debug sources in the player scene.
5. **Vertical Slice Art/UI Direction** — benchmark alternatives, approve art bible and information hierarchy.
6. **Production Asset Pass** — puzzle art, UI, enemy/class/environment assets, reusable decomposition.
7. **VFX/Animation Pass** — integrated readability-first effects.
8. **Audio Pass** — music, SFX, buses, mix, gameplay sync.
9. **Vertical Slice Content/UX Pass** — tutorial, enemy sequence, title/pause/settings/results, final encounter pacing.
10. **Vertical Slice Verification** — automated, Windows, visual, audio, performance, defect gate.
11. **Vertical Slice Playtest** — Run A/B/C protocol above.
12. **Post-playtest adversarial review and production decision**.

Stages can contain internal parallel tasks, but the Vertical Slice Playtest gate does not move earlier.

## 20. Reconsideration conditions

Revisit this production policy only if one of the following occurs:

- production implementation reveals that a fundamental Line/Chain mechanic cannot be made technically stable within the chosen architecture;
- target Windows performance cannot support the approved visual/audio direction without changing scope;
- asset production cost/time becomes incompatible with the project's long-term solo-development plan;
- legal/IP review requires a gameplay/presentation change that materially affects the slice;
- after the first complete Vertical Slice playtest, evidence shows the dual-board resource split is not compelling even with final-for-slice presentation.

Do **not** revert to a player-facing placeholder POC merely because the first polished playtest takes longer to reach. Use internal engineering verification to manage that risk.

## 21. Source and benchmark references

Primary references used for this design:

- Tetris Effect: Connected official site — audiovisual elements synchronized with player actions: `https://www.tetriseffect.game/`
- Tetris Effect: Connected official game overview — stage themes, graphics, music and SFX synchronized to gameplay; Hold/Zone/Journey details: `https://www.tetriseffect.game/about-the-game/`
- Puyo Puyo Tetris 2 official Korean modes page — BGM/SE, skins, settings, Skill Battle/player configuration: `https://asia.sega.com/puyopuyotetris2/kr/mode.html`
- Puyo Puyo Tetris 2 official Korean rules page — HP/MP Skill Battle reference: `https://asia.sega.com/puyopuyotetris2/kr/rule.html`
- Godot stable documentation — audio buses and routing: `https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html`
- Godot stable documentation — audio effects: `https://docs.godotengine.org/en/stable/tutorials/audio/audio_effects.html`
- Godot stable documentation — 2D particles/effects capability: `https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html`
