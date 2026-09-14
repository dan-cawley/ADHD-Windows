# Legacy Audit Recommendations

Initial keep/copy/discard guidance based on the current codebase shape and the rebuild notes.

## Keep

- Pure engines with regression tests
- Coordinator-style mutation helpers that already isolate state transitions
- CSV/import-export logic that is mostly UI-independent
- Asset lookup tables and naming maps that can be wrapped behind a smaller API

## Copy And Clean

- Quest list behavior once it is separated from the giant root view
- Reward queue behavior after state mutation and presentation concerns are split
- Pet progression rules after art lookup and UI concerns are removed
- Boss progression logic after route and prompt side effects are peeled off
- Calendar import flow after dependencies are reduced to models and adapters

## Discard Or Rebuild

- Giant root-view composition in `ContentView.swift`
- Heavy tab preloading assumptions that keep too much mounted
- UI code that mixes persistence, mutation, and presentation in the same path
- Any feature branch experiments that increase memory cost without daily utility

## First Safe Copy Targets

- `QuestMutationEngine`
- `QuestCompletionEngine`
- `RewardQueueEngine`
- `BossFamiliarProgressionEngine`
- `InventoryMutationEngine`

These should be copied only after each gets a rebuild-facing interface and smaller model surface.

## Audit Notes

### `QuestMutationEngine`

- Status: `CopyAndClean`
- Why it qualifies:
  - mostly pure mutation logic
  - small and understandable surface area
  - existing regression coverage
- What to keep:
  - manual quest creation rules
  - completion blocking message behavior
  - enqueue behavior
  - delete/ignore imported-title behavior
- What to drop from the first rebuild copy:
  - direct dependency on legacy `Quest`, `Subquest`, and `QuestRefactorSupport`
  - legacy UI message phrasing beyond the core behavior contract
  - calendar import engine coupling except for a caller-supplied normalization function
