# Feature-To-Art Dependency Matrix

This matrix defines what can ship with placeholders and what actually needs bespoke art for MVP.

| Feature | Final Art Required For MVP | Placeholder Safe | Notes |
| --- | --- | --- | --- |
| Quick Capture | No | Yes | Use typography and simple system styling first |
| Today / Quest List | No | Yes | High readability matters more than custom art |
| Morning Review | No | Yes | Reuse lightweight accent assets only |
| Reward Summary | No | Yes | Can ship with generic coin, chest, and rarity tokens |
| Item Preview | Partial | Yes | Generic placeholders work until final item set is ready |
| Pet Progression | No for MVP if deferred | Yes | If included early, use existing sheet-backed storybook art or simple symbolic fallback |
| Boss Map | No for MVP if deferred | Yes | Can ship with simple nodes and weekly monster placeholders |
| Avatar / Character | Partial | Yes | One primary style is enough for MVP; other styles can stay phase two |
| Settings / Backup | No | Yes | No art dependency |

## Recommended MVP Art Policy

- Primary style: `Storybook`
- Required bespoke MVP art:
  - one stable avatar style
  - basic reward/coin icon set
  - enough item preview art to support the core reward loop
- Placeholder-safe systems:
  - capture
  - quest list
  - morning review
  - backup/settings
  - boss map if held for phase two
  - pets if held for phase two

## Naming Baseline

- avatar: `avatar_[set]_[style]`
- item icon: `item_[item_key]_[style]`
- pet sheet: `familiar_sheet_[group_key]_[style]`
- boss sheet: `boss_weekly_[range]_[style]`
