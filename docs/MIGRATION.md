# Windows migration audit

Source root: `C:\Users\Dan\Documents\adhd`.

The primary implementation is SwiftUI under `adhd/adhd`; the Android Compose port lives under `android_port`. The Swift Rebuild planning identifies Capture + Today + Review + Rewards + Backup/Restore as the core MVP. A native C# Windows Forms implementation preserves that initial product scope and runs using the .NET Framework available on this machine.

## Keep

- Quest categories: School, Work, Home, Life, Fun.
- Optional due dates; daily and weekly recurrence; subquest breakdown.
- Positive completion rewards; quiet feedback; XP and coins.
- Today and overdue review; bulk actions; backup/restore.
- Original art catalog, equipment CSV, generation script and selected reference models/engines for the next migration phase.

## Defer

- Familiar progression, weekly bosses, item collection and gear bonuses need a dedicated behavior port and test parity with Swift regression cases.
- Native Apple integrations (Siri, EventKit) need Windows-specific designs.
- Mobile save formats need an explicit converter; Windows import intentionally rejects unsupported formats.
- Signed installer, auto-update and release packaging follow usability review.

## Copy policy

Preserve originals. Exclude Apple `._*` metadata, `.DS_Store`, build output, IDE state and personal save data. Source reference is documentation, not part of the Windows build. No files were removed from the original app.

## Acceptance checks

Build executable; run core regression tests for reward idempotency, recurring dates, streaks, archive behavior, atomic persistence and invalid-backup handling; exercise UI capture/edit/completion/restart/export. Record results in VALIDATION.md.
