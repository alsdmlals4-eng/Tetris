# Production Battle Surface Polish Design

**Issue:** #30
**Status:** USER_APPROVED / implementation authorized
**Decision:** retain the CORE-029 gameplay contract while making the existing battle surface read as the approved dark-fantasy/rift production direction.

## Goal

Give the current 60/40 battle scene a clear three-level visual hierarchy without introducing a new image, gameplay rule, balance value, or user-evidence claim.

## Player-facing result

The player can identify, in this order: the active puzzle workspace and its controls, the immediate enemy threat/ETA, their resources, and the tactical or terminal action. The existing Fracture Frontier stage remains a restrained environmental strip behind the combat side.

## Chosen approach

Use a reusable Godot `Theme` resource plus a small number of semantic `PanelContainer` frames. This preserves all runtime ownership in `ProductionBattle`; the scene only gains presentation structure. Theme tokens use charcoal/navy foundations, restrained violet focus, ember-crimson threat, ice-blue defense information, and readable off-white text derived from the approved references.

## Alternatives considered

1. **Theme + semantic frames (adopt):** visual hierarchy is reusable, does not need raster generation, and keeps the runtime consumer boundary intact.
2. **New background/icon raster set (reject now):** no missing runtime consumer has been specified; it would add asset-review work before proving this layout needs it.
3. **Large scene re-layout (reject now):** risks the approved 60/40 reading and established input paths without improving a proven rule gap.

## Scope

- Add `res://resources/production/production_battle_theme.tres` and assign it to the battle root.
- Frame the mode controls, threat, resources, and tactical/terminal panel with named, semantic containers.
- Keep the existing StageBackdrop exact asset path, crop behavior, and ignored mouse input.
- Preserve LINE/CHAIN/SKILL behavior, pause behavior, terminal retry, node-level runtime ownership, and 60/40 column ratios.
- Add regression assertions for the theme and semantic visual hierarchy.

## Exclusions

- No generated or downloaded images, no audio binaries, no gameplay/balance/data changes, no copy rewrite beyond state labels, no save/meta, and no PR #19 work.
- Human readability, appeal, and balance remain `NOT_RUN` until real receipts exist.

## Acceptance criteria

1. The battle scene loads a named theme resource and exposes semantic Mode, Threat, Resource, and Tactical/Result frame nodes.
2. The existing stage texture remains the only battle raster consumer and stays input-transparent.
3. The 60/40 ratios and existing named runtime controls still exist and operate through the same script bridge.
4. A focused GUT UI test, the full GUT suite, tooling tests, and Godot 4.7.1 headless parse pass.
