# Vertical-Slice-First Production Design

- Status: **PROPOSED_CANON / user-approved direction, written-spec review pending**
- Date: 2026-08-20
- Repository: `alsdmlals4-eng/Tetris`
- Scope: project-wide production and player-validation policy
- Replaces: system-only/debug POC as a player-facing milestone

## 1. Core decision

The project will not ask the user to judge game feel from a system-only POC.

The first meaningful user playtest must be a **short but production-complete Vertical Slice** containing the actual intended experience together:

- production Line puzzle;
- production Chain puzzle;
- dual-board switching, RUN/LOCK/SUSPENDED behavior, and state preservation;
- Energy / Chain Stock / Skill combat;
- enemy intent and Combat Clock pressure;
- production UI/UX;
- approved art direction and integrated game assets/images;
- animation and VFX;
- music, SFX, UI audio, and slice-quality mix;
- tutorial/onboarding;
- title/start, pause/settings, battle, result/restart flow;
- telemetry and deterministic verification.

The Vertical Slice is **short in content, not incomplete in quality**.

Initial one-run content target: approximately **6–10 minutes**. Duration may change after production pacing work, but required systems/presentation may not be removed merely to shorten the slice.

## 2. Milestone vocabulary

### Engineering verification

Allowed throughout production:

- unit/integration tests;
- headless scenes;
- debug event sources;
- deterministic simulations;
- developer-only diagnostic UI;
- screenshot/video capture;
- seeded replay fixtures;
- performance and audio probes.

These are **engineering verification**, not POC and not player validation.

### Vertical Slice Playtest

The first user-facing evaluation milestone.

It is blocked until the Production Completeness Gate in this spec passes.

### Forbidden milestone inflation

Do not call any of the following a POC/Vertical Slice/player-feel validation:

- buttons that simulate Line or Chain results;
- placeholder rectangles instead of slice-quality puzzle visuals;
- debug HUD used as production UX;
- silent gameplay when sound is intended feedback;
- combat/resource simulation without real puzzle input;
- skill actions without their intended visual/audio feedback;
- temporary art screenshots presented as final readability evidence.

## 3. Approaches considered

### A. Production Vertical Slice first, staged engineering integration — **ADOPT**

Production subsystems are completed and verified in controlled stages, while visual/audio/UX contracts are defined early and integrated continuously. User playtesting begins only when the whole short slice is representative.

Why:

- feedback concerns the intended product, not placeholders;
- puzzle feel, UI, effects, sound, enemy pressure, and combat decisions are judged together;
- temporary player-facing work is minimized;
- subsystem correctness is still tested early through engineering verification.

### B. System POC first, polish later — **REJECT**

Useful for pure logic, but insufficient for immersion, readability, feel, and audiovisual reward. Debug harnesses may still exist internally, but they are not the player milestone.

### C. Build systems and art separately, integrate near the end — **REJECT AS DEFAULT**

Late integration risks unreadable VFX, wrong UI dimensions, input/animation timing conflicts, audio masking, and duplicated assets.

Parallel work is allowed only after common contracts are approved.

## 4. Architecture

Use two independent production puzzle engines feeding the existing combat boundary.

```text
Production Line Engine ---- Line Events ----┐
                                            ├---- Puzzle/Combat Adapter ---- Combat State
Production Chain Engine --- Chain Events ---┘
```

Puzzle engines own puzzle rules/state. They do not mutate HP, Energy, Chain Stock, Skills, or enemy state directly.

Combat owns:

- HP;
- Energy;
- Chain Stock;
- Score aggregation;
- Skill eligibility/spending;
- Attack / Defense / Heal resolution;
- enemy timeline;
- battle terminal state.

UI reads state and submits player intent. It does not directly mutate puzzle/combat internals.

Existing debug event sources remain permitted as automated fixtures only. The Vertical Slice scene must use production engines.

## 5. Production Line Engine gate

Required before player testing:

- 10×20 visible Matrix plus required hidden/spawn rows;
- seven-tetromino gameplay set;
- deterministic seeds;
- 7-Bag generation;
- spawn rules;
- Next queue, initially 5 visible;
- Hold, once per active piece;
- Ghost;
- left/right movement;
- configurable DAS/ARR;
- gravity;
- soft drop;
- hard drop;
- lock delay;
- bounded lock-reset behavior;
- SRS-style rotation state model;
- normal kick data;
- I-piece-specific kick data;
- collision/placement validation;
- line detection/compaction;
- Single / Double / Triple / 4-Line;
- Combo;
- Back-to-Back difficult clears;
- Spin recognition sufficient for the slice scoring profile;
- Perfect Clear;
- soft/hard-drop score support;
- Line Score events;
- Energy events;
- slice top-out/block-out behavior;
- exact LOCK/SUSPENDED freeze;
- exact restoration of active piece, board, timers, hold, queue, and randomizer state;
- deterministic replay fixtures.

Input-feel parameters belong in data/config, not hidden constants.

## 6. Production Chain Engine gate

Required before player testing:

- 6×12 visible field plus required hidden/spawn handling;
- deterministic pair queue;
- initial four-color production profile;
- pivot/child falling pair;
- spawn rules;
- left/right movement;
- rotate both directions;
- wall/floor collision behavior;
- approved narrow-space/quick-turn behavior;
- gravity;
- fast/soft drop;
- placement timing;
- split landing where pair pieces settle at different heights;
- per-cell gravity after clears;
- orthogonal connected-component detection;
- 4+ matching clear;
- simultaneous multiple-group clear;
- multi-color clear;
- cascades;
- exact N-Chain counting;
- Large Group data;
- Color Bonus data;
- Group Bonus data;
- All Clear;
- reference Chain Score profile;
- completed-chain event emitted only after the full cascade stabilizes;
- Chain Stock update from the completed chain result;
- slice top-out behavior;
- exact LOCK/SUSPENDED freeze;
- queued mode switch during RESOLVING;
- deterministic replay fixtures.

Fall speed, repeat timing, placement delay, clear delay, and cascade delay are configurable data.

## 7. Dual-board invariants

These remain canonical:

- only one board is active/large/interactive;
- inactive board is `SUSPENDED` and does not advance;
- switching lands the destination in `LOCKED`;
- explicit `RUN` is required;
- `LOCK` freezes puzzle simulation/input only;
- Combat Clock continues during LOCK, switch, and Skill selection;
- puzzle resolution is atomic;
- switch requests during RESOLVING apply only after stability;
- switching may not create or destroy puzzle advantage;
- inactive preview may display state but accepts no puzzle input.

## 8. Presentation direction is decided before engine completion

UI/UX/art/audio are **not** a late polish phase.

Before production-engine implementation gets deep enough to lock rendering dimensions/timing, complete this preproduction package:

1. current market/genre presentation research;
2. at least three materially distinct art/UI direction alternatives;
3. readability/cost/consistency/identity/long-term-class-expansion comparison;
4. one approved direction;
5. compact art bible;
6. UI information hierarchy and responsive layout contract;
7. puzzle cell/piece size and safe VFX bounds;
8. animation timing budgets that cannot alter deterministic puzzle logic;
9. audio event taxonomy and bus structure;
10. asset naming/import/reuse contract.

This allows Line/Chain engines, UI, visuals, effects, and sound to integrate continuously rather than meeting for the first time near the end.

## 9. Art/image production workflow

No placeholder art is accepted as Vertical Slice evidence.

Workflow:

```text
benchmark/reference proposal
→ user approval
→ source asset creation/generation
→ cleanup
→ structure/layer decomposition where useful
→ reusable-component classification
→ import profile
→ in-game integration
→ consistency/readability review
```

Reusable categories should include where appropriate:

- Line pieces/cell frames/highlights;
- Chain pieces/cell frames;
- board frames;
- mode tabs;
- Energy/Stock icons;
- Skill icons;
- enemy intent/status icons;
- panels/buttons;
- VFX sprites/materials;
- hit/defense/heal motifs;
- enemy/class art;
- background/environment layers;
- result/rank elements.

The repository is integrated-asset truth. **Do not add a Figma dependency.** Notion may track decisions/tasks where useful, but game asset truth must remain reproducible from repository source masters and imported assets.

Generated imagery should retain reusable source/layer information when practical so later classes/enemies/screens stay consistent rather than being regenerated as unrelated one-offs.

## 10. UI/UX production gate

Player flow required for the slice:

1. title/start;
2. slice setup/class presentation if needed;
3. concise onboarding/tutorial;
4. battle HUD;
5. pause/settings;
6. victory/defeat/results;
7. restart/return.

Battle HUD must expose without menu digging:

- player HP;
- enemy HP/status;
- next enemy action/countdown;
- following intent when exposed by encounter design;
- Energy;
- Chain Stock / available Skill Tier;
- active mode;
- board state (`RUNNING`, `LOCKED`, inactive/suspended);
- Skills and unavailable reasons;
- Score;
- important Combo/Chain feedback.

UX rules:

- mode switch is visually unmistakable;
- destination LOCKED state is obvious;
- frozen board cannot look like a hung game;
- Combat Clock pressure stays visually/audibly clear during LOCK;
- large VFX may not hide the puzzle or critical enemy intent;
- Windows PC slice requires production keyboard controls;
- Android remains deferred until the previously agreed later release phase;
- gamepad is not a slice blocker unless explicitly promoted later.

Slice settings minimum:

- master volume;
- music volume;
- SFX volume;
- UI volume if separately routed;
- necessary window/display setting for Windows validation;
- reduced-flash/reduced-shake or equivalent safety option when applicable.

## 11. Combat/content production gate

The slice includes at least one production-quality class kit and one production-quality encounter sequence.

The class fantasy is selected before its art/audio asset pass. Core APIs stay class-agnostic.

Class kit must show:

- Attack;
- Defense;
- Heal/recovery;
- meaningful low/high Tier use;
- production icons;
- production animation/VFX/SFX;
- clear insufficient-resource feedback.

Encounter must show:

- readable next-action countdown;
- normal damage pressure;
- a high-pressure/heavy action;
- at least one action that changes resource/puzzle priority rather than only dealing damage;
- a short climax/phase transition;
- production telegraphs;
- production impact/defense/heal feedback;
- clear victory/defeat.

The encounter must make both Line and Chain strategically necessary.

## 12. VFX and animation gate

### Line feedback

- movement/lock response;
- line clear;
- Combo escalation;
- difficult clear/B2B;
- Spin when supported;
- Perfect Clear climax;
- Energy gain.

### Chain feedback

- settle;
- clear;
- cascade;
- Chain escalation;
- multi-color/large-group emphasis;
- All Clear climax;
- Stock/Tier gain.

### Combat feedback

- Skill activation;
- damage;
- defense/shield/avoidance;
- healing;
- enemy telegraph;
- enemy impact;
- phase/climax;
- victory/defeat.

Effects communicate state first, spectacle second.

## 13. Audio gate

Audio is part of the slice, not post-playtest polish.

Godot named buses are the baseline:

- Master;
- Music;
- SFX;
- UI;
- Ambience if needed by the approved direction.

Required slice audio:

- production encounter music/adaptive set;
- Line move/rotate/lock/clear;
- high-value Line stingers;
- Chain drop/settle/clear/escalation;
- Energy gain;
- Stock/Tier gain;
- Skill activation;
- damage/defense/heal;
- enemy warning/attack;
- mode switch;
- RUN/LOCK feedback where useful;
- UI confirm/cancel/navigation where used;
- victory/defeat/results.

Mix rules:

- puzzle-critical SFX and enemy warnings remain audible over music;
- no sustained master clipping;
- high-Combo/high-Chain layering has polyphony limits;
- common repeated actions may use pitch/variant rules to reduce fatigue;
- audiovisual synchronization may improve feel but may not alter deterministic gameplay timing.

## 14. Benchmark decisions

### Tetris Effect: Connected — **adopt principle**

Official product material describes music, backgrounds, sounds, special effects and pieces as synchronized with play. Adopt the principle that audiovisual response is part of puzzle feel, not decoration added after rule validation.

### Puyo Puyo Tetris 2 — **adopt principle**

Official product material integrates Skill Battle/HP/resources with BGM, SE, skins, settings, and lessons. Adopt the principle that combat, presentation, settings, and onboarding coexist in the player build.

### Transform

- branded presentation → independent project identity;
- competitive puzzle framing → dual-resource combat framing;
- copied audiovisual motifs → project-specific art/UI/sound/VFX language.

### Exclude

- logos/characters/branded UI/music/SFX/trade-dress copying;
- treating another game's exact economy or audiovisual timing as final balance.

Commercial-release IP review remains a later gate.

## 15. Engineering verification before player playtest

Postponing user playtesting does not postpone correctness testing.

Required continuous verification:

- TDD for deterministic puzzle rules;
- fixed seeds;
- board fixtures;
- replayable input sequences;
- exact event assertions;
- Line scoring fixtures;
- Chain scoring/cascade fixtures;
- freeze/resume tests;
- mode-switch resolution tests;
- combat/resource tests;
- enemy timeline tests;
- scene instantiate/import tests;
- strict test-collection guard;
- telemetry schema tests.

Required integrated evidence before the Vertical Slice Playtest:

- Windows runtime launch;
- production scene, not debug harness;
- both production puzzle engines controllable;
- complete title→battle→results flow;
- target-resolution screenshots/video for visual review;
- audio routing/mix verification;
- no visible debug simulation controls;
- no known Critical/playtest-blocking defect;
- stable target framerate on the user's Windows validation machine.

## 16. Production Completeness Gate

Vertical Slice Playtest is **BLOCKED** until all categories pass.

### Gameplay

- production Line complete;
- production Chain complete;
- freeze/resume complete;
- slice scoring complete;
- Energy/Stock complete;
- Skills complete;
- enemy encounter complete;
- top-out/combat interaction complete.

### Presentation

- approved art direction;
- final-for-slice puzzle art;
- final-for-slice board/environment art;
- class/enemy/combat art;
- production UI;
- VFX/animation;
- music/SFX;
- audio mix;
- onboarding;
- title/pause/settings/results.

### Quality

- full automated suite PASS;
- Godot import/parse PASS;
- Windows runtime PASS;
- target-resolution visual review PASS;
- audio review PASS;
- no player-facing placeholders/debug simulation UI;
- telemetry/replay working;
- defects triaged with no blocker open.

Only then may the build be named a **Vertical Slice candidate**.

## 17. Vertical Slice playtest protocol

The previous 45-second debug-button validation is not the player milestone.

First player evaluation consists of at least three complete slice runs.

### Run A — first experience

- start at title;
- rely on in-game onboarding only;
- finish/fail naturally;
- record confusion, readability, mode understanding, and emotional peaks.

### Run B — deliberate LOCK style

- intentionally use LOCK for decisions;
- verify enemy-time pressure remains understandable;
- test whether deliberate play is viable without trivializing combat.

### Run C — continuous/mastery style

- keep RUNNING more often;
- switch modes aggressively;
- exercise both resources and higher activity;
- inspect audiovisual overload/readability at higher Combo/Chain levels.

Record at minimum:

- run duration;
- Line/Chain RUNNING time;
- LOCK time;
- switches;
- Energy generated/spent;
- chain distribution;
- Skill Tier/use distribution;
- Attack/Defense/Heal use;
- enemy actions answered/missed;
- top-out/recovery incidents;
- result;
- performance evidence;
- qualitative notes after each run.

Technical completion alone is not a successful playtest. The slice must also be readable, coherent, and engaging enough to justify the production direction.

## 18. Existing PR #3 disposition

PR #3 is a useful **Core Combat Foundation / Engineering Harness**, not the player-facing POC.

Under this policy:

- keep reusable state/combat/telemetry tests;
- keep debug event sources as test fixtures;
- retire the 45-second debug-button human test as a project milestone;
- do not ship the debug player UI as the Vertical Slice scene;
- once this policy is approved, review PR #3 only against foundation criteria;
- if foundation CI is green, it may merge without the obsolete debug human-play gate;
- production Line/Chain/presentation work follows as separately verified stages.

## 19. Implementation sequence

The order explicitly avoids a late presentation pass.

1. **Core Combat Foundation normalization** — reclassify PR #3 and preserve only reusable foundation/harness responsibilities.
2. **Vertical Slice Experience Preproduction** — benchmark at least 3 art/UI alternatives; approve art bible, UI hierarchy, puzzle sizing, VFX readability bounds, animation timing budgets, audio taxonomy/buses, asset pipeline, slice class/enemy presentation target.
3. **Production Line Engine + continuous presentation integration** — full rules/input/scoring plus actual approved piece/board rendering hooks and Line feedback integration as it matures.
4. **Production Chain Engine + continuous presentation integration** — full rules/input/chain scoring plus actual approved piece/board rendering hooks and Chain feedback integration.
5. **Production Asset Build** — approved UI, puzzle, class, enemy, background, icons and reusable source decomposition; may overlap stages 3–4 only within approved contracts.
6. **Production Dual-Board Integration** — actual engines replace debug sources in the player scene; inactive preview and production switching UX complete.
7. **Combat/VFX/Animation/Audio Integration** — slice Skills, enemy telegraphs, impacts, music, SFX, buses and final-for-slice feedback integrated in-context.
8. **Vertical Slice Content & UX Completion** — title, tutorial, pause/settings, encounter pacing, results, restart flow, final short content sequence.
9. **Vertical Slice Verification** — automated, Windows runtime, visual, audio, performance and defect gates.
10. **Vertical Slice Playtest** — Run A/B/C protocol.
11. **Post-playtest adversarial review** — decide whether to continue, tune, or revise production direction.

Internal verification runs continuously throughout. The user-facing Vertical Slice Playtest gate never moves earlier.

## 20. Reconsideration conditions

Revisit this policy only if:

- a fundamental Line/Chain mechanic cannot be stabilized in the architecture;
- target Windows performance cannot support the approved presentation;
- asset production cost/time becomes incompatible with the long-term solo-development plan;
- legal/IP review forces material gameplay/presentation change;
- the completed Vertical Slice shows that the dual-board resource split is not compelling even with intended presentation.

Do not revert to a player-facing placeholder POC merely because reaching the polished slice takes longer. Manage that risk with internal engineering verification.

## 21. Primary references

- Tetris Effect: Connected official site: `https://www.tetriseffect.game/`
- Tetris Effect: Connected official game overview: `https://www.tetriseffect.game/about-the-game/`
- Puyo Puyo Tetris 2 official Korean modes: `https://asia.sega.com/puyopuyotetris2/kr/mode.html`
- Puyo Puyo Tetris 2 official Korean rules: `https://asia.sega.com/puyopuyotetris2/kr/rule.html`
- Godot stable audio buses: `https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html`
- Godot stable audio effects: `https://docs.godotengine.org/en/stable/tutorials/audio/audio_effects.html`
- Godot stable 2D particles reference: `https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html`
