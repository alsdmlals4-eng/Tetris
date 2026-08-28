# First-Session Briefing and Embedded Tutorial Contract

- Decision: `TETRIS-ONBOARDING-037`
- Status: `USER_APPROVED / PHASE 1 CANON / DOCUMENTED_NOT_IMPLEMENTED`
- Issue: #54
- Rule-delivery amendment: **Full rules before Deploy**, Issue #66
- Rule-delivery mode: `FULL_PRE_DEPLOY_BRIEFING`
- First-visit Deploy gate: `RULES_REGION_END_OR_ACCESSIBLE_EQUIVALENT`, Issue #68
- Post-Deploy handoff: `SHORT_GUIDED_LIVE_PRACTICE_THEN_SEAMLESS_CONTINUOUS_ENCOUNTER`, Issue #68
- Tutorial pressure mode: `SAFE_LIVE_AUTHORED_OPENING`, Issue #70
- Tutorial clock: `CONTINUOUS_FROM_DEPLOY`; opening guardrail: `SUFFICIENT_ETA_AND_NONTERMINAL_UNTIL_FIRST_EXPLICIT_CONFIRM`, Issue #70
- Post-tutorial pressure: `NORMAL_AUTHORED_ENCOUNTER_AFTER_GUIDED_HANDOFF`, Issue #70
- Authority: `TETRIS-CORE-029`, `TETRIS-CHAIN-038`, the current Screen Surface Inventory, and the user's 2026-08-28 approvals.
- Scope boundary: this is the intended first-session learning contract. It does not claim a Godot scene, runtime asset, localized final copy, Human/player validation, or a broader world-history canon.

## Player promise at first contact

The player should understand, before pressure begins, that a Vanguard is responding to the immediate Gatebreaker threat at a Frontier Gate. The first encounter then proves the distinctive promise: a live threat can be read, two different puzzle workspaces create different resources, and a tactical Skill pause enables a deliberate Technique commitment.

The only approved world-facing facts for this first explanation are the existing current names and their immediate relationship: **Vanguard**, **Frontier Gate**, **Gatebreaker**, and an imminent threat. Do not invent factions, history, geography, named characters, or a public title to fill this moment.

## Intended first-session flow

```text
Start
→ Battle Briefing (short world/threat explanation + full first-slice rules; first-visit read gate; simulation is not running)
→ explicit Deploy
→ short guided live practice in the actual CORE-029 battle
→ seamless Continuous Battle in the same encounter
→ Result / Retry
```

The present direct-entry runtime slice still begins at `CONTINUOUS_BATTLE`; that is an implementation fact, not the intended full first-session entry. The briefing is a planned `BattleBriefing` consumer and the embedded tutorial is a planned extension of the existing battle surface.

## Briefing contract

The briefing answers three world/threat questions, then a separate full-rules section, in one re-readable presentation. On the **first intended session only**, the full-rule region is not skippable as a route to live combat: Deploy remains disabled until the player reaches the end of that region or completes an equivalent accessible review action. This is a single readable boundary, not six checkboxes or a quiz. On later entries, Deploy is immediately enabled and the same rule summary remains re-openable.

1. **Where and why?** A Frontier Gate is under immediate Gatebreaker threat; the Vanguard is deploying to answer it.
2. **What will happen next?** The encounter begins only when the player chooses **Deploy**; the enemy threat starts after that explicit action.
3. **What is the player being asked to learn?** Read the threat, prepare the right resource, then decide whether a Technique is worth committing.

It reserves the existing `TETRIS-SREF-003` briefing reference's threat and launch space. It is not a cinematic, a lore database, a route-map substitute, or a second combat ruleset.

### Full rules before Deploy

Before Deploy becomes the available explicit start action on the first intended session, the player completes the full structured-text review of every economy-critical first-slice rule. The battle tutorial practices these disclosed rules; it does not conceal an economic penalty or formula for discovery after combat has already begun.

1. **LINE / MP:** no clear / Single / Double / Triple / Four recovers `0 / 10 / 22 / 36 / 52 MP`; MP has a hard cap of 60 and excess recovery has no conversion.
2. **CHAIN match:** swap only orthogonally adjacent symbols. A valid match is a contiguous straight same-symbol line of 3+ horizontally, vertically, diagonally down-right, or diagonally down-left.
3. **Valid CHAIN reward:** each resolved wave gives Combo +1, capped at 10, then recovers MP by `(sum of maximal qualified line lengths − 3) + post-wave Combo`.
4. **Failed CHAIN outcome:** no-match normally restores the board and resets Combo. The player may instead spend fixed 1 MP to keep the swapped board for a later setup; this MP lock also resets Combo and grants no immediate clear, cascade, Combo, or MP recovery.
5. **Spend-or-save choice:** choose ATK/DEF/SUP, then current Combo resolves one Stage in that category. If its MP is insufficient, only surplus Combo may convert at **5 MP per Combo** to preview the highest feasible lower Stage. Spending Combo can solve the current threat but lowers later CHAIN MP recovery; saving it preserves future recovery and a higher resolved Stage.
6. **Tactical commitment:** opening Skill fully pauses simulation. Category selection previews without cost; only explicit CONFIRM commits the displayed technique/conversion. Cancel returns to the same paused state.

This is complete for the current vertical slice, not a full catalog explanation: the briefing names the resource rules and commitment grammar but does not front-load all 18 Technique identities, final MP costs, effect magnitudes, route/progression, or future content.

## Embedded tutorial sequence

After Deploy, the tutorial is a **short guided practice inside the actual continuous encounter**. It does not use a fake board, a separate economy, or an old ordered-turn rail. The guided portion ends after the player has read the live threat, seen one disclosed LINE reward, verified one disclosed valid CHAIN reward, selected a category, inspected its resolved preview, and committed one explicit CONFIRM; optional MP-lock inspection is never mandatory. Prompting then ends and the same encounter continues as normal CORE-029 play, beginning with the existing unforced-response step rather than a terminal tutorial result.

### Safe live authored opening

Deploy starts the real continuous combat clock. Tutorial prompts must not silently freeze the enemy; only the already-approved Skill/manual pause may stop the simulation. The first authored Telegraph/ETA supplies enough real-time room for the required guided actions, and its outcome may communicate light pressure but cannot cause a terminal or forced-failure result before the first explicit CONFIRM. After that guided handoff, the same encounter uses its normal authored pressure with no separate tutorial ruleset or invulnerability mode.

| Step | Player question | Required feedback | Guardrail |
| --- | --- | --- | --- |
| 1. Read threat | “What is about to happen, and how long do I have?” | Current Telegraph and ETA remain visible while the player can still act. | The ETA is genuinely counting down from Deploy; do not freeze it for a prompt or use a Shared Turn Timer/phase rail. |
| 2. Practice MP | “Can I see the disclosed LINE reward happen?” | A Single LINE visibly grants the pre-briefed **10 MP**; Double/Triple/Four grant 22/36/52 MP. At 60 MP, show the full state before another LINE reward could overflow. | Do not use hidden grants or imply LINE is the only correct workspace. |
| 3. Practice Combo | “Can I verify the disclosed CHAIN rule and reward?” | A valid straight 3+ CHAIN visibly uses horizontal, vertical, or either diagonal alignment, gives Combo +1, then displays `line total − 3 + current Combo = MP recovery`. The same Combo can later resolve a stronger ATK/DEF/SUP Stage or be saved to improve a later CHAIN MP recovery, up to 10. | Keep LINE and CHAIN non-interchangeable; reinforce the pre-Deploy rule with structured feedback, not image-only labels; do not force an old Line→Chain order. |
| 3b. Verify optional setup | “When would I use the pre-briefed MP lock?” | When affordable, the player can inspect that fixed **1 MP** keeps a no-match swap for a later setup, resets Combo, and gives no immediate clear, cascade, Combo, or MP recovery. | Do not require this transaction in the first tutorial or imply it is a third resource. The later Manual may repeat it. |
| 4. Commit deliberately | “Which category is worth spending Combo on now?” | Skill opening visibly freezes the same threat/puzzle state; `ATK / DEF / SUP → one resolved current-Combo preview → explicit CONFIRM` makes the category, effect and fallback consequence legible. | Cancel returns to the exact paused state. Do not show an always-visible 3×6 matrix, manual Tier choice or auto-commit on selection. |
| 5. Apply learning | “What do I prepare or commit before this next threat?” | The player makes one unforced response using the visible ETA, MP, Combo/Tier, and Technique result. | The encounter may be forgiving, but it must not be a non-interactive demonstration. |

## Scope and production gates

- Keep the world explanation short. The separate rules section is intentionally complete for economy-critical first-slice rules and revisit-able through the planned Codex/Manual surface; do not front-load all 18 Technique identities.
- The first-visit gate guarantees one complete rule review before Deploy without requiring a quiz. Later visits may Deploy immediately, while retaining a re-openable rule summary. The short guided battle tutorial must hand off to free play in the **same encounter**; it must not restart, terminate, or introduce a separate tutorial ruleset.
- Use a **safe live authored opening**: continuous time begins at Deploy, the first authored ETA is sufficient for the guided actions, and its pre-first-CONFIRM result is nonterminal. This does not authorize tutorial-time auto-pause, a separate board/economy, or permanent safety; normal authored pressure resumes after the guided handoff.
- Preserve `CORE-029`: continuous real-time battle after Deploy, free persistent `LINE ↔ CHAIN`, full tactical pause only through Skill/manual pause, and explicit `CONFIRM` commit.
- This decision creates no runtime image need. `TETRIS-SREF-003` and `TETRIS-SREF-005` remain approved planning references, not implementation or Human-readability evidence.
- Phase 2 may create the BattleBriefing scene/data contract and the minimum battle tutorial triggers only after its implementation review. It must not silently add a route, save, progression, production-asset batch, or broader narrative system.

## Required human validation

Before the tutorial can be marked effective, first-exposure receipts must show that a player can, without coaching:

1. state the immediate threat and why Deploy starts it;
2. identify the Current Telegraph/ETA before acting;
3. distinguish LINE → MP from CHAIN → shared Combo/Tier access, including why spending Combo trades a stronger Technique against later CHAIN MP recovery, and why a failed CHAIN swap/MP lock resets Combo without a reward;
4. explain that Skill pauses the simulation and that **CONFIRM**, not category selection, commits; and
5. make and explain one resource/Technique response to a visible threat.
6. recognize that the ETA was live from Deploy, while explaining why the first opening gave enough room to learn without a forced loss.

Failure evidence must be recorded as a tutorial/readability finding, not masked by more lore, an unapproved timer, or a false runtime-PASS claim.
