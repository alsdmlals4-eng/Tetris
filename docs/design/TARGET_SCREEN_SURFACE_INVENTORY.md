# Target Screen Surface Inventory

- Status: CURRENT / Issue #45
- Canon: `TETRIS-CORE-029`, `TETRIS-IMAGE-030`, and actual `scenes/production/battle.tscn`
- Target build: direct-entry CORE-029 vertical slice; first meaningful loop is Battle Start → LINE/CHAIN choice → tactical Skill pause → USE → Victory/Defeat → Retry.
- Boundary: this inventory uses the historical Base screen-first contract as a reference and the current Base Visual Asset Coverage Checklist as the canonical coverage owner. It does not authorize image generation.

## Current target flow

`BATTLE_COMBAT` → `SPECIAL_ACTION_OVERLAY` (SKILL tactical pause) → `RESULT_REWARD` (Victory/Defeat/Retry) → `BATTLE_COMBAT`.

| Screen ID | Family | Priority | Entry → Exit | Player goal / question | Consumer and evidence | Coverage status / blocker |
| --- | --- | --- | --- | --- | --- | --- |
| TETRIS-SCREEN-001 | MAIN_TITLE_MENU | P1 | App launch → direct Battle entry | Start, settings, or exit? | No title scene on current main. Direct battle entry is deliberate for this vertical slice. | NOT_APPLICABLE — no title/menu is in the approved current slice. |
| TETRIS-SCREEN-002 | BATTLE_COMBAT | P0 | Battle Start → Skill, result | Which puzzle workspace and resource should I prepare under ETA pressure? | `scenes/production/battle.tscn`; 960×540 Godot scene-tree-equivalent render; CORE-029. | COVERED_EXISTING — Human readability remains NOT_RUN. |
| TETRIS-SCREEN-003 | SPECIAL_ACTION_OVERLAY | P0 | `K` / Skill button → cancel or USE | Which ATK/DEF/SUP Tier is worth committing while time is frozen? | `SkillFrame`, `PauseState`, category controls, TierGrid, UseButton in Battle. | COVERED_EXISTING — exact Skill detail/readability needs Human evidence. |
| TETRIS-SCREEN-004 | RESULT_REWARD | P0 | Victory/Defeat → Retry | What ended the encounter and how do I retry? | Battle-owned terminal Result/Retry contract. No reward/progression screen is implemented. | GAP_NONBLOCKING — retry exists; reward recap is outside the current slice. |
| TETRIS-SCREEN-005 | PAUSE_SETTINGS | P1 | `P` / system pause → resume | Is simulation paused and how do I safely return? | CORE-029 manual pause; no settings panel scene. | GAP_NONBLOCKING — pause behavior exists; settings surface deferred. |
| TETRIS-SCREEN-006 | BOOT_SPLASH_LOADING | P2 | App start/transition → scene ready | Is the game loading or recoverable? | No player-facing loading surface in this direct local slice. | NOT_APPLICABLE — no asynchronous content flow in current target. |
| TETRIS-SCREEN-007 | NEW_GAME_PROFILE_SAVE_LOAD | P2 | title → game state | Which persistent run/profile should I load? | No save/meta system in current canon. | NOT_APPLICABLE — save/meta explicitly out of scope. |
| TETRIS-SCREEN-008 | CHARACTER_BUILD_LOADOUT_SELECT | P2 | pre-battle → Battle | What Vanguard build should I take? | Fixed Vanguard and tactical matrix; no loadout selection consumer. | NOT_APPLICABLE — fixed first-slice loadout. |
| TETRIS-SCREEN-009 | HUB_HOME_MAP_ROUTE | P2 | post-result → next encounter | Where should I go next? | Single Frontier Gate encounter only. | NOT_APPLICABLE — no hub/map in current slice. |
| TETRIS-SCREEN-010 | DIALOGUE_EVENT_STORY | P2 | event → choice/result | What narrative choice should I make? | No dialogue/event consumer. | NOT_APPLICABLE — narrative surface not in current slice. |
| TETRIS-SCREEN-011 | PREPARATION_BRIEFING_PARTY_EQUIPMENT | P2 | selection → Battle | What encounter risk and equipment should I confirm? | Fixed encounter direct entry. | NOT_APPLICABLE — no pre-battle setup flow. |
| TETRIS-SCREEN-012 | PROGRESSION_UPGRADE_SHOP_CRAFT_REST | P2 | result → upgrade → next play | How should I spend earned growth? | No progression/shop/craft system. | NOT_APPLICABLE — explicit non-scope. |
| TETRIS-SCREEN-013 | CODEX_ARCHIVE_MANUAL_TUTORIAL_HELP | P1 | player request → return | How do controls, resources, and pause work? | In-scene LINE controls/Hold/NEXT; no dedicated help surface. | GAP_NONBLOCKING — current control rail covers immediate inputs only. |
| TETRIS-SCREEN-014 | FAILURE_RETRY_ENDING_CREDITS | P1 | terminal state → retry/exit | Can I recover from defeat? | Result/Retry is in Battle; no ending/credits. | COVERED_EXISTING for retry; NOT_APPLICABLE for ending/credits. |
| TETRIS-SCREEN-015 | LOADING_TRANSITION_ERROR | P2 | failure/transition → recovery | What failed and how can I recover? | No networking, save, or multi-scene transition consumer. | NOT_APPLICABLE — no applicable runtime path. |
| TETRIS-SCREEN-016 | DEBUG_DEVELOPMENT_ONLY | P2 | developer invocation | Diagnose runtime state without shipping UI. | Godot/GUT/tooling diagnostics. | NOT_APPLICABLE for player-facing coverage. |

## P0 decisions and ceilings

- `TETRIS-SCREEN-002` is the only full player-facing gameplay composition currently implemented. Its screen reference is the approved Battle composition mockup; runtime components are independently assembled by Godot rather than using the mockup bitmap as UI.
- `TETRIS-SCREEN-003` changes input and timing semantics, therefore remains a separate overlay surface even though it is a Battle child tree.
- P0 blocking gaps: **0 for the direct-entry vertical slice**. P1/P2 missing surfaces are neither silently complete nor approved for automatic implementation or image generation.
- Godot/runtime evidence verifies wiring and layout only. Human first-exposure, usability, balance, accessibility, and final art/readability remain `NOT_RUN`.
