# Repository instructions

Read `README.md` and `docs/FUTURE-VERSION-PROMPT.md` before changing this project.

The iOS implementation preserved under `reference/` is the source of truth for shared gameplay behavior. Preserve save compatibility and the original mobile files.

Before every GitHub push, update both:

- `README.md`
- `docs/FUTURE-VERSION-PROMPT.md`

Both files must accurately describe the code being pushed, its current version, validation status, known gaps, and recommended next work. Update `CHANGELOG.md` whenever user-visible behavior changes.

Compile before pushing. Run relevant checks unless the owner explicitly asks to skip them, and report exactly what was run. Never commit `dist/`, shortcuts, user saves, backups, personal exports, credentials, or secrets.

For a new clone, enable the repository push guard with:

```powershell
git config core.hooksPath .githooks
```
