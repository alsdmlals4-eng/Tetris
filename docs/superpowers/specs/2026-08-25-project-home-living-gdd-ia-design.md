# Tetris Project Home · Living GDD + Visual Dashboard IA Design

> Status: **DESIGN / USER-APPROVED ARCHITECTURAL DIRECTION**
>
> Scope: Notion information architecture and Human/AI responsibility boundaries only. This design does **not** change gameplay canon, visual canon, balance rules, Production runtime, or Draft BUILD PR #19.

## 1. Goal

Reconstruct `Tetris · Home` as a self-contained **Project Living GDD + Visual Dashboard** that lets a human understand the game by scrolling one page, while preserving detailed operational/schema/evidence data in the existing Tetris System Record and its linked AI/Production surfaces.

The acceptance criterion is:

> **A person should be able to judge what game is being made and how it is intended to work from Tetris · Home alone; an AI should be able to implement and validate that game without losing any required schema/evidence/detail through the System Record + detail canon + GitHub.**

The Home is not a link hub, but it also must not become a second mutable canon or a copy of AI operational data.

## 2. Current project truth that this IA must preserve

### Gameplay authority

- `TETRIS-TIME-025`: one Shared Player Turn Budget across Line → Chain → Action; READY carries remaining time; settle/forced transition/System Pause/Enemy Resolve do not consume player input budget.
- `TETRIS-CORE-024`: Enemy Telegraph → Line → Line Settle → Chain → Chain Settle → Action → Player Action Resolve → Enemy Action Resolve.
- `TETRIS-SKILL-026`: Vanguard ATK / DEF / SUP × Tier 1–6; Tier is tactical Stock commitment, not a linear power ladder.
- `TETRIS-BALANCE-027`: Line produces Energy; Chain produces non-interchangeable Stock; Tier N consumes Stock N; lower Tier viability is required.
- Representative Slice: one Vanguard + one Gatebreaker + one Frontier Gate, first-exposure target 6–10 minutes.

### Visual authority

- Current runtime visual direction is `TETRIS-VISUAL-020 · Tactical Anime Pixel Rift Fantasy`.
- `Focus Stage + Compact Tactical Sidecar` remains the desktop HUD structure.
- Gameplay readability has priority over texture/spectacle.
- Current reference images on Home are visual references / North-Star material, not runtime proof or final asset approval.
- Old `3.2s / 8.4s / 14.0s` enemy ETA-style labels in the Battle Screen Composition Mockup are historical visual residue and must never be presented as current timing authority.
- The Asset Library currently does not establish those images as final approved runtime Project Assets; Home must not silently promote them.

### Evidence boundary

- Human Evidence remains `NOT_RUN` until valid independent first-exposure receipts exist.
- Fun, tension, runtime readability, lower-Tier comprehension, memorable payoff, and final tuning remain hypotheses/evidence-dependent.
- Draft Production BUILD PR #19 is a separate branch workstream and not merged-main truth.

## 3. Reference-image interpretation

The user-provided images are **layout/information-density references**, not Tetris art-direction replacements and not asset-generation requests.

The common useful pattern is not “put a pretty image at the top”. The useful pattern is:

1. show the product fantasy or representative screen;
2. use **Visual GDD** material that explains systems, flow, screen composition, progression, or interaction;
3. place dense structured data near its visual explanation;
4. let a human understand relationships without opening five child pages;
5. keep implementation/evidence metadata out of the main presentation layer.

Therefore Tetris Home prioritizes **explanatory visual material** over decorative concept art.

## 4. Architectural alternatives

### A · Keep current learning-document Home and only move images upward

**Pros**
- smallest edit;
- low migration risk.

**Cons**
- Home remains text-first and reads like onboarding documentation rather than a project design surface;
- core data such as Tier techniques, Energy/Stock economy, Gatebreaker intents, visual HUD rules, and Slice scope remain hidden behind detail pages;
- does not satisfy the user’s “Main Home alone should be enough to judge the game” acceptance criterion.

**Decision:** reject.

### B · Living GDD Home + existing System Record as AI Workspace root — **ADOPT**

**Pros**
- one strong Human Home without creating a second project authority;
- reuses the existing Tetris System Record, which already owns repository/runtime/sync metadata and an AI/System detailed index;
- detailed owner pages remain canonical while Home exposes their human-relevant data directly;
- operational state remains separated from presentation;
- zero new service/tooling cost and low long-term drift risk.

**Cons**
- requires deliberate projection discipline so Home does not become a manually duplicated second canon;
- some information must be summarized or linked-viewed from owner pages/databases rather than copied blindly.

**Decision:** adopt.

### C · Create a new standalone `Tetris · AI Workspace` plus rebuild Home

**Pros**
- visually explicit Human/AI separation.

**Cons**
- creates another root and likely another synchronization surface beside the existing System Record;
- risks duplicated PR/SHA/evidence/schema state;
- higher maintenance burden with no proven project need.

**Decision:** reject unless the existing System Record later proves structurally insufficient.

## 5. Responsibility model

### `Tetris · Home` — Human Project Living GDD + Visual Dashboard

Owns the **human-facing projection** of current approved design:

- game identity and player fantasy;
- representative gameplay appearance;
- core turn/puzzle/combat relationship;
- first-run and full loop flow;
- current visual/HUD language;
- the important technique/resource/encounter data a designer needs to judge the game;
- concise Development Reality meaning, without raw PR/SHA/CI logs;
- links to deeper canonical owner pages.

Home does **not** own raw schema IDs, implementation provenance, workflow receipts, issue/PR logs, machine routing, local tool binding, or internal handoff metadata.

### Detail canon / owner pages — Human detailed truth

Existing pages continue to own the detail they already own:

- Direction / Planning;
- Combat Design / Data;
- Visual / UX / Assets;
- Vanguard Tactical Tier Matrix;
- Resource Economy / Tier Exposure;
- Gatebreaker Encounter;
- First Run Flow;
- Production Content Lock;
- Human Evidence Gate;
- related detailed design pages.

Home must not reinterpret them into new rules.

### Tetris System Record — AI Workspace root

The existing `PROJECT REGISTRY · Master` Tetris record is promoted conceptually to the **AI Workspace root**, not replaced.

It owns or routes:

- repository identity, current main SHA, sync state;
- local/project/tool binding metadata;
- implementation/evidence status;
- machine-readable routing/schema location;
- PR/issue/test/CI/runtime/Human evidence references;
- assumptions, unresolved conflicts, provenance, handoff links;
- links to Human Home and domain owner pages.

The System Record should expose an explicit AI Workspace responsibility statement so future agents do not recreate another workspace.

### GitHub — implementation and machine truth

GitHub remains owner for:

- current structured gameplay canon;
- machine-readable indexes/data;
- code/scenes/resources/tests;
- exact implementation evidence and CI;
- PR/issue history.

Notion does not replace GitHub implementation truth.

## 6. Tetris Home target reading order

The Home must read correctly from top to bottom without requiring navigation.

### 01 · PROJECT NORTH STAR

Purpose: answer “what is this game?” immediately.

Include:

- one-line game definition;
- core fantasy / player promise;
- representative Slice scope: Vanguard vs Gatebreaker at Frontier Gate;
- current style label `Tactical Anime Pixel Rift Fantasy`;
- **visual-first North Star block** using existing relevant reference images.

Visual priority:

1. Battle Screen Composition / UI North Star reference;
2. Vanguard reference;
3. Gatebreaker reference.

Each image gets a clear state label: **Visual Reference / North Star — not runtime proof / not final asset by itself**.

Do not place operational status or CI metadata in this first section.

### 02 · HOW THE GAME WORKS

Purpose: explain the system relationship, not only the chronological flow.

Include:

- system relationship diagram:
  `Enemy Telegraph → Shared Time allocation → Line/Energy → Chain/Stock → Technique/Tier → Player Resolve → Enemy Resolve`;
- full turn Flow Map;
- the five core player decisions:
  time allocation, dual-resource preparation, Tier commitment, current-vs-future response, Tempo/resolve consequence;
- READY and non-consuming settle behavior.

This section replaces a text-only tutorial feel with a **Visual GDD-style systems explanation**.

### 03 · CORE GAMEPLAY DATA

Purpose: expose the data a human needs to judge whether the design is coherent.

Include compact but real current data, sourced from the existing owner pages:

#### Resource model

| Source | Resource | Role | Persistence / constraint |
| --- | --- | --- | --- |
| Line | Energy | Technique throughput / utility cost | persists across turns; not interchangeable with Stock |
| Chain | Stock | Tier access / commitment | persists; cap 6; Tier N costs N |

#### Vanguard tactical technique matrix

Expose ATK / DEF / SUP × T1–T6 with Technique name + tactical role. The Home should show the actual matrix rather than only saying “there are 18 techniques”.

Do not copy every implementation primitive/status stacking detail into Home; those remain in the detail owner page.

#### Gatebreaker intent table

Expose current representative intents and what player decision each is designed to create:

- Light Smash;
- Gatebreaker Slam;
- Rift Siphon;
- Chain Fracture;
- Rift Repair;
- Siege Charge.

Exact tuning values remain clearly labeled seed/TUNE_REQUIRED where applicable.

### 04 · FIRST 6–10 MINUTES / FULL PLAYER FLOW

Purpose: answer “what will the player actually experience?”

Include:

- Title → Gate Arrival → first real Tutorial Turn → Gatebreaker battle → Result → fast Retry/next goal;
- first-turn learning sequence;
- authored production-board seed principle;
- contextual non-modal hints;
- victory/defeat and retry behavior;
- one diagram for session flow and one concise explanation of intended emotional arc:
  **read threat → prepare → commit → see payoff → update next plan**.

### 05 · HOW IT SHOULD LOOK

Purpose: make the current approved visual direction visible and actionable.

Include:

- current style definition and retained readability/layering rules;
- HUD hierarchy;
- Focus Stage + Compact Tactical Sidecar explanation;
- current vs Next Forecast hierarchy;
- Line/Chain differentiation;
- Energy vs Stock/Tier visual-language distinction;
- ATK/DEF/SUP lane distinction;
- combat-art/VFX occlusion negative contract;
- existing visual reference images with state labels.

Important: do not use the user-provided cross-project reference images as Tetris assets. They only inform information density / explanatory layout.

### 06 · VERTICAL SLICE CONTENT LOCK

Purpose: answer “what exactly are we building now?” without showing project-management noise.

Show a human-readable Must-Build / Not-Now table.

Must Build includes:

- Production Line;
- Production Swap-Match Chain;
- Shared Turn combat;
- Vanguard technique set;
- Gatebreaker encounter;
- representative HUD/visual/audio/VFX/onboarding/result/settings needed for the Slice;
- deterministic/evidence-ready flow.

Not Now includes broad classes/biomes/meta systems/content expansion that are outside the representative Slice.

This is design scope, not implementation progress.

### 07 · DEVELOPMENT REALITY

Purpose: prevent a beautiful design page from implying that everything exists in runtime.

Show only human-readable evidence categories:

- Design canon: documented/approved;
- Visual direction: approved direction/reference, runtime validation pending;
- Production representative runtime: not proven on merged main until actual merge/readback;
- Human first-exposure validation: NOT_RUN;
- exact balance/readability/fun: evidence-dependent.

Do **not** show raw SHA, PR number, workflow run ID, local path, port, tool binding, or CI transcript here. Provide one link/mention to Production Validation / System Record for operational evidence.

### 08 · DETAIL LIBRARY

Purpose: navigation only after the self-contained content has already been presented.

Group the existing owner pages by:

- Direction / Scope;
- Combat / Economy / Skills / Encounter;
- Visual / UX / Assets / Audio;
- First Run / Validation;
- Reference / Benchmark.

This section is a library, not the core content of Home.

## 7. Projection and anti-duplication rules

1. **No new mutable gameplay authority is created on Home.** Owner pages/GitHub structured canon remain authority.
2. Human-relevant data may be rendered directly on Home, but every section names or links its owner.
3. When a true Notion database exists and the same rows must appear on Home, prefer a linked view rather than a copied table.
4. When current truth exists only as a structured owner page/table and no database exists, Home may carry a concise projection, but the owner page remains explicitly authoritative.
5. Raw PR/SHA/CI/runtime/schema/ID state never migrates upward merely to make Home “complete”.
6. Detail pages must not be deleted merely because their important data is projected on Home.
7. Historical/superseded material is not projected as current unless it is clearly labeled provenance.

## 8. Stale-current cleanup required during implementation

The IA migration must also remove or quarantine current-facing statements that would mislead a future human/AI while Home is being elevated.

Known examples to verify and fix in the implementation pass:

- old independent `30/30/30` phase timer language where it appears as current rather than historical;
- old `TETRIS-SKILL-022` current-owner wording superseded by `TETRIS-SKILL-026`;
- stale “no open PR” / BUILD-deferred operational statements in detail/Production pages when current System Record/GitHub says otherwise;
- any Home wording that calls current reference images “approved runtime assets” rather than reference/North-Star material.

Only stale-state corrections are allowed. New gameplay decisions are not.

## 9. System Record / AI Workspace target

The System Record keeps its database properties and gains a clear in-page AI Workspace contract:

### AI WORKSPACE · TETRIS

- **Human Home:** one direct link to `Tetris · Home`.
- **Current authority routing:** GitHub canon index + relevant Notion domain owners.
- **Implementation evidence:** GitHub current main/open PRs/tests/runtime.
- **Validation evidence:** Production Validation / Human Evidence Gate.
- **Machine detail:** schema/mapping/IDs/tool binding/local execution metadata.
- **Handoff/provenance:** planning/build/evidence documents and unresolved gates.

A future agent must be told explicitly: **do not create another AI Workspace root unless this record lacks a required capability.**

## 10. No-image-generation rule for this migration

The user-provided images are examples. This IA migration does not generate, edit, or replace Tetris art.

Existing Tetris visual references may be repositioned/reused on Home. Any new Tetris explanatory visual requiring image generation remains a separate explicit image task.

Mermaid/system tables can be used as non-generated explanatory diagrams.

## 11. Verification / acceptance tests

### Human Home acceptance

A first-time reader should be able to answer from Home alone:

1. What is the game?
2. What does the player repeatedly do?
3. Why do Line and Chain both matter?
4. How does Shared Time create a decision?
5. What are Energy and Stock used for?
6. Why is the highest Tier not always correct?
7. What does the Gatebreaker telegraph change?
8. What does the representative 6–10 minute Slice contain?
9. What should the combat screen and visual language look like?
10. What is approved design versus unproven runtime/Human evidence?

### AI Workspace acceptance

An AI starting from the System Record should be able to locate without relying on Home text duplication:

- current gameplay authority;
- current visual authority;
- current machine-readable indexes;
- implementation/runtime evidence;
- Human evidence contract/status;
- open PR protection state;
- project tool/binding metadata;
- detailed owner pages and provenance.

### Drift guard

After migration, search/readback must confirm:

- Home does not expose raw PR/SHA/CI/log metadata in the top design surface;
- System Record remains operational truth;
- current timing is one Shared Player Turn Budget;
- current skill owner is SKILL-026;
- current images are reference/North-Star material, not silently promoted final runtime assets;
- PR #19 remains untouched unless explicitly authorized;
- Human evidence remains NOT_RUN until real receipts exist.

## 12. Implementation boundary

The implementation plan following this design may modify:

- `Tetris · Home` content/order;
- Tetris System Record in-page AI Workspace wording/index;
- existing Notion owner-page projection wording where needed to preserve Human/AI boundary;
- stale-current Notion statements encountered inside this exact IA scope;
- GitHub documentation/tests that guard the IA/evidence contract.

It must not modify:

- gameplay rules or tuning;
- runtime code or Production assets;
- Draft BUILD PR #19;
- visual style direction;
- actual project image assets or image-generation pipeline;
- Human evidence state without real session receipts.
