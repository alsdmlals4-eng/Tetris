# Battle music verification

Source baseline b7f52f6171a297f46d7d9ab94b1f116130185d89. No gameplay, clock or save schema changes. Separate background player reuses existing music setting; original effects/jingle retain their channels. Original source/hash and CC0 declaration are in audio/SOURCES.md. Final listening/mix/rights approval remains separate.

TDD: new owner test failed (3/4 pass, missing set_battle_state); after implementation and editor asset scan, focused 9/9 passed. First green attempt failed because the new Ogg was not imported; no false pass recorded. Full GUT 398/398,4109 assertions,64 scripts,50.224 seconds,exit0. Python tooling90/90,22.110 seconds,exit0.

Native Godot4.7.1 run17, test session only, process stopped to avoid gameplay timing; actual audio renderer still advances. Seek10s then wait0.3s:10.29025. Pause and wait0.3s:10.29896 (8.7ms audio-buffer margin). Resume0.3s:10.62113. Mute0.3s:10.62984; unmute0.3s:10.94041. Seek96.9 and wait0.8s:0.36776, crossing the97.333s loop boundary. Main stops background; new battle starts0.00290s. Six bounded player nodes. These verify engine playback continuity, not audible loop quality or device listening.

Independent review1: no blocking finding; requested temporal checks above. Review2 and packaged export pending. Whole game is not declared complete by these checks.
