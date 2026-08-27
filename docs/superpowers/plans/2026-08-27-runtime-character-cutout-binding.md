# Runtime Character Cutout Binding Plan

**Issue:** #42

## Steps

- [x] Re-read CORE-029, the runtime consumer contract, merged asset manifest, and actual `battle.tscn`.
- [x] Add failing contract coverage for the exact scene resource and node bindings.
- [x] Bind both approved cutouts to the existing CombatStage with an aspect-preserving, non-interactive layout.
- [x] Update manifest and consumer documentation only to `IMPLEMENTED_ON_BRANCH`; do not claim runtime render proof yet.
- [x] Run the scene/asset contract and Godot parse, then capture a Godot 4.7.1 GUI render of the scene-tree-equivalent branch content. Both cutouts and the existing stage backdrop are visible; Human readability remains outside this evidence boundary.
- [ ] Run independent review, exact-head CI, merge only after required review/check/thread gates, and perform post-merge readback.
