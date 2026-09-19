# Validation — September 19, 2026

## Passed

- Compiled Windows preview 0.23.0 and its installer with the installed .NET Framework compiler.
- The built executable's `--self-test` exits 0 with 154 assertions.
- Coverage includes quests, recurrence, streak boundaries, XP and coins, familiar/boss progression, equipment, atomic persistence and validated backup recovery, formats 1–11 migration, calendar parsing and recurring instances, iOS import boundaries, daily templates, milestone rewards, avatar unlocking/assets, identity, and reminder preferences.
- The required `--render-test` paints every primary page at 1000×680, 1240×860, and 1600×1000. It verifies responsive quest-grid flow, vertical detail-page flow, buffered painting, and that visible action buttons stay inside their containers.
- The release build runs both test modes and stops packaging if either fails.
- Installer setup, installed-executable assertions, and asynchronous uninstall cleanup are smoke-tested in an isolated directory without touching the normal install or user save.

## Still to validate

Actual Windows sign-in startup, notification-area Open/Exit interaction, real balloon delivery, quiet-hour timing, Start menu/desktop shortcuts, Apps & Features presentation, interactive export/restore, extended keyboard navigation, other display scales, and Windows reputation prompts. Portable and installer builds remain unsigned.

## Test data

Automated UI tests use `--preview-test` state under `dist/test-state/save.json`. They do not modify the regular `%LOCALAPPDATA%\AdhdWarrior` save. Build output and isolated test data remain excluded from Git.
