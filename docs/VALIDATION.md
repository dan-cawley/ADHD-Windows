# Validation — September 14, 2026

## Passed

- Compiled `ADHD Warrior.exe` with the installed Windows .NET Framework C# compiler.
- Final executable's `--self-test` exits 0: 12 assertions cover rewards, step completion, duplicate completion, archived quests, daily and weekly recurrence, streak boundaries, save round trip, previous-save retention and malformed-backup rejection.
- Launched the native desktop window; visually inspected the main layout and quest editor at the machine's current display scale.
- Entered a smoke-test quest through the desktop UI. It appeared in Today and was written to the isolated test save.
- Observed the same quest completed in the UI with 50 XP, 10 coins and a one-day streak; confirmed these values in its saved JSON.
- Original artwork copied with a SHA-256 manifest.
- Local Git repository points to `https://github.com/dan-cawley/ADHD-Windows.git`; the remote was verified empty in the signed-in browser.

## Still to validate

Full interactive export/restore, extended keyboard navigation, other display scales, and installer behavior. Automated persistence tests pass; an interactive close/reopen test was not completed while the user was trying the preview. This is an unsigned, portable preview, not a packaged production release.

## Test data

The desktop test session was launched with `--preview-test`, which writes to `dist/test-state/save.json`. Tests do not modify the user's regular `%LOCALAPPDATA%\AdhdWarrior` save. Close the test window and launch normally for regular use. The isolated test data is retained locally and excluded from Git by `dist/`.
