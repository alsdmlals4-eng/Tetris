# Enemy visual consumer binding

Base main19092b89c0e788b101b4130dc33c66ef8cd47720. Existing five visual assets and all hashes preserved. Explicit known enemy IDs consume only complete six-pose R2-BOSS. Unknown IDs/portrait poses/incomplete state family fail closed. Battle and result share this owner. Shared-trial fallback is disclosed in the enemy HP tooltip; this is not finished enemy-specific art.

TDD missing-method test failed3/4 then4/4 passed72 assertions; screen consumer test1/1 passed11 assertions for intro and every expedition profile. Full GUT400/400,4175 assertions,65 scripts,52.764s exit0; tooling90/90,22.400s exit0. Diff whitespace check clean. User project.godot hash remains46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020.

Native run18 inspection script failed compile; no PASS claimed. Restarted run19 and used a bounded watchtower inspection: battle_match=true,result_match=true,tooltip="공용 적 시안 · 전용 상태별 그림 준비 중". Read-only in-memory session, persist=false; no user save write. Whole-suite tests cover all five profiles. This readback proves resource binding, not a new visual design.

Review1 found0 blockers. Review2/package pending. Revert presentation helper/hooks only for rollback; no save migration. NO_NEW_REUSE_LEARNING: existing owner/guard pattern reused, no Base changes.
