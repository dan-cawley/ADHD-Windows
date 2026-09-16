# Validation — September 16, 2026

## Passed

- Compiled Windows preview 0.17.1 with the installed .NET Framework compiler.
- The built executable's `--self-test` exits 0 with 139 assertions.
- Coverage includes quests, recurrence, streak boundaries, XP and coins, familiar/boss progression, equipment, atomic persistence, formats 1–11 migration, iOS import boundaries, daily templates, milestone rewards, pending-reward uniqueness, avatar unlocking/assets, identity, and opt-in reminder background preferences.
- Found and fixed a format-11 save failure caused by awarding or selling equipment already reserved in pending rewards.
- Launched with `--preview-test`; confirmed the native 0.17.1 window opened, exited cleanly, and created an isolated format-11 save containing four generated daily quests with startup and tray settings disabled.

## Still to validate

Actual Windows sign-in startup, notification-area Open/Exit interaction, real balloon delivery, quiet-hour timing, interactive export/restore, extended keyboard navigation, other display scales, and installer behavior. This remains an unsigned portable preview.

## Test data

The desktop test session was launched with `--preview-test`, which writes to `dist/test-state/save.json`. Tests do not modify the user's regular `%LOCALAPPDATA%\AdhdWarrior` save. Close the test window and launch normally for regular use. The isolated test data is retained locally and excluded from Git by `dist/`.
