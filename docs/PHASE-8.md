# Windows 0.8 — iOS weekly bosses

The iOS import preview now understands the 18 shared weekly boss identities. When the mobile week label matches the current week under either the common Sunday-first or ISO Monday-first convention, Windows preserves the active boss index, current HP and maximum HP. Windows stores the current week as its Monday date after import.

iOS history contains a real date for each encounter. Windows uses that date to derive a stable Monday week rather than trusting the source's locale-dependent `year-Wweek` label. Defeated maps to Defeated; survived maps to Carried forward. Up to the Windows limit of 30 entries transfer in source order.

An active encounter resets when its boss ID is unknown, HP is impossible, or its week label does not match the current week under a supported convention. Invalid or excess history entries are skipped. The preview reports all resets and skips before Apply. This avoids moving old damage into the wrong calendar week.

The save schema remains format 5. 113 automated assertions pass, including current encounter transfer, dated history conversion and stale-week reset alongside all earlier migration and gameplay checks.
