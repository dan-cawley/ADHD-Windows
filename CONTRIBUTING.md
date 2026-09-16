# Contributing

ADHD Warrior is currently developed as a local-first Windows migration with the iOS app as the behavioral reference.

Before making a change, read the root README, `AGENTS.md`, and `docs/FUTURE-VERSION-PROMPT.md`. Keep changes small enough to leave a working build and preserve existing saves.

Every push must include an accurate update to both `README.md` and `docs/FUTURE-VERSION-PROMPT.md`. User-visible changes also require a `CHANGELOG.md` entry. Pull requests use the same checklist, and GitHub Actions verifies the documentation pair.

Build with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

Run the in-process regression suite with the generated executable's `--self-test` option when validation is in scope. Use `--preview-test` for isolated UI work; it writes beneath the ignored `dist/` folder rather than the normal save location.

Do not commit build output, local shortcuts, personal saves, backup files, mobile exports, credentials, or secrets.
