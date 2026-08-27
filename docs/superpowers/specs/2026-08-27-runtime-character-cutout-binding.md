# Runtime Character Cutout Binding Specification

**Issue:** #42  
**Canon:** `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` (CORE-029) and `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`

## Player-facing result

The production combat panel visibly reads as a confrontation: Vanguard occupies the foreground-left of the existing combat stage and Gatebreaker occupies the background-right. Both remain behind all interaction surfaces because the stage is above only the pre-existing resource and tactical-skill frames.

## Binding contract

- `VanguardReference` and `GatebreakerReference` are direct `TextureRect` children of `MainRow/CombatColumn/CombatStage`.
- Both use the approved transparent v1 cutouts, `mouse_filter = 2`, `expand_mode = 1`, and `stretch_mode = 5` (keep aspect centered).
- Vanguard anchors to horizontal `0.0–0.6` and z-index `2`; Gatebreaker anchors to `0.34–1.0` and z-index `1`.
- `StageBackdrop` remains below both; puzzle, forecast, ResourceFrame, and SkillFrame remain outside CombatStage and are unchanged.

## Acceptance and evidence boundary

Scene and asset tests prove the references and layout contract. A screenshot from the exact branch head must prove the visual placement. Human readability and commercial-art approval remain outside this machine-verifiable slice.
