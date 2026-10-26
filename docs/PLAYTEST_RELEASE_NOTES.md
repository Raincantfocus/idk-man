# ZERO-LINE playable test

This is the real warehouse wave game with the new human review model, authored animation playback and the existing ragdoll. Run `zero-line.exe` and choose **Enter the Trial** or **Movement Lab**.

All five roles currently share one unpolished soldier fallback. New-body severing/caps are **not ready**: these enemies use wounds and blood. **F9** switches to old enemies with legacy dismemberment. Expect dark clothing, missing role gear, reused animation fallbacks and high geometry costs.

Debug keys: **F1–F5** spawn roles; **F6** kill nearest; **Shift+F6** lethal head hit; **F7** choose death clip; **F8** gore; **F9** old/new; **F10** clear corpses; **F11** slow motion. Gore defaults to Reduced and saves between runs. The release executable omits debug controls.

Verified: ten real-map waves, all five roles, 20 death-direction cases, reward parity with gore Off/Full, pause and restart checks. Linux export smoke passes. Windows executables are produced but not run on this Linux host. Software-rendered performance is not a PC-GPU benchmark.

Read `PLAYTEST_NOTES.md` for exact results, export commands, ranked known issues and the ten-item playtest checklist.
