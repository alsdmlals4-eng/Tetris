# First-Session Briefing and Embedded Tutorial Contract

- Decision: `TETRIS-ONBOARDING-037`
- Status: `USER_APPROVED / PHASE 1 CANON / DOCUMENTED_NOT_IMPLEMENTED`
- Issue: #54
- Authority: `TETRIS-CORE-029`, `TETRIS-CHAIN-038`, the current Screen Surface Inventory, and the user's 2026-08-28 approvals.
- Scope boundary: this is the intended first-session learning contract. It does not claim a Godot scene, runtime asset, localized final copy, Human/player validation, or a broader world-history canon.

## Player promise at first contact

The player should understand, before pressure begins, that a Vanguard is responding to the immediate Gatebreaker threat at a Frontier Gate. The first encounter then proves the distinctive promise: a live threat can be read, two different puzzle workspaces create different resources, and a tactical Skill pause enables a deliberate Technique commitment.

The only approved world-facing facts for this first explanation are the existing current names and their immediate relationship: **Vanguard**, **Frontier Gate**, **Gatebreaker**, and an imminent threat. Do not invent factions, history, geography, named characters, or a public title to fill this moment.

## Intended first-session flow

```text
Start
→ Battle Briefing (short world/threat explanation; simulation is not running)
→ explicit Deploy
→ Continuous Battle (CORE-029; embedded contextual tutorial)
→ Result / Retry
```

The present direct-entry runtime slice still begins at `CONTINUOUS_BATTLE`; that is an implementation fact, not the intended full first-session entry. The briefing is a planned `BattleBriefing` consumer and the embedded tutorial is a planned extension of the existing battle surface.

## Briefing contract

The briefing answers three questions in one concise, skippable/re-readable presentation:

1. **Where and why?** A Frontier Gate is under immediate Gatebreaker threat; the Vanguard is deploying to answer it.
2. **What will happen next?** The encounter begins only when the player chooses **Deploy**; the enemy threat starts after that explicit action.
3. **What is the player being asked to learn?** Read the threat, prepare the right resource, then decide whether a Technique is worth committing.

It reserves the existing `TETRIS-SREF-003` briefing reference's threat and launch space. It is not a cinematic, a lore database, a route-map substitute, or a second combat ruleset.

## Embedded tutorial sequence

| Step | Player question | Required feedback | Guardrail |
| --- | --- | --- | --- |
| 1. Read threat | “What is about to happen, and how long do I have?” | Current Telegraph and ETA remain visible while the player can still act. | Explain live pressure without a Shared Turn Timer or phase rail. |
| 2. Recover MP | “What does LINE prepare?” | A clear LINE result visibly changes MP and points to an affordable response. At 60 MP, show that MP is full before another LINE reward can overflow. | Do not use hidden grants or imply LINE is the only correct workspace. |
| 3. Earn Combo | “What does CHAIN prepare that LINE cannot?” | A straight horizontal, vertical, or diagonal 3+ CHAIN match visibly changes Combo and the reachable Technique Tier. A failed swap visibly reverts. | Keep LINE and CHAIN non-interchangeable; do not force an old Line→Chain order. |
| 3b. Optional setup | “Can I keep a useful failed swap?” | When affordable, explain that spending fixed **1 MP** may keep a no-match swap for a later Combo setup, with no immediate clear or Combo. | Do not require this transaction in the first tutorial or imply it is a third resource. |
| 4. Commit deliberately | “When should I stop time and which Technique is worth the cost?” | Skill opening visibly freezes the same threat/puzzle state; category → selected lane → T1–T6 → detail → explicit **USE** makes the commit and result legible. | Cancel returns to the exact paused state. Do not show an always-visible 3×6 matrix or auto-commit on selection. |
| 5. Apply learning | “What do I prepare or commit before this next threat?” | The player makes one unforced response using the visible ETA, MP, Combo/Tier, and Technique result. | The encounter may be forgiving, but it must not be a non-interactive demonstration. |

## Scope and production gates

- Keep the explanation short, contextual, and revisit-able through the planned Codex/Manual surface; do not front-load all 18 Technique identities.
- Preserve `CORE-029`: continuous real-time battle after Deploy, free persistent `LINE ↔ CHAIN`, full tactical pause only through Skill/manual pause, and explicit `USE` commit.
- This decision creates no runtime image need. `TETRIS-SREF-003` and `TETRIS-SREF-005` remain approved planning references, not implementation or Human-readability evidence.
- Phase 2 may create the BattleBriefing scene/data contract and the minimum battle tutorial triggers only after its implementation review. It must not silently add a route, save, progression, production-asset batch, or broader narrative system.

## Required human validation

Before the tutorial can be marked effective, first-exposure receipts must show that a player can, without coaching:

1. state the immediate threat and why Deploy starts it;
2. identify the Current Telegraph/ETA before acting;
3. distinguish LINE → MP from CHAIN → Combo/Tier access, including why MP can optionally preserve a failed CHAIN setup without awarding Combo;
4. explain that Skill pauses the simulation and that **USE**, not row selection, commits; and
5. make and explain one resource/Technique response to a visible threat.

Failure evidence must be recorded as a tutorial/readability finding, not masked by more lore, an unapproved timer, or a false runtime-PASS claim.
