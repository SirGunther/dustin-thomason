# Templates

| Template                                 | Consumed by                        | Purpose                                                        |
| ---------------------------------------- | ---------------------------------- | -------------------------------------------------------------- |
| `TICKET-changelog.template.md`           | `scripts/new-ticket-changelog.ps1` | Per-`PRDV` ticket changelog                                    |
| `project-docs-README.template.md`        | `scripts/new-project-docs.ps1`     | Canonical-record index for a project                           |
| `PROJECT-changelog.template.md`          | `scripts/new-project-docs.ps1`     | Project session log                                            |
| `PROJECT-capabilities.template.md`       | `scripts/new-project-docs.ps1`     | What works vs what is simulated                                |
| `PROJECT-roadmap.template.md`            | `scripts/new-project-docs.ps1`     | Scope, status, **Decisions resolved**                          |
| `PROJECT-decisions-pending.template.md`  | `scripts/new-project-docs.ps1`     | Deferred choices with triggers                                 |
| `POC-SNAPSHOT.template.md`               | `scripts/new-poc-snapshot.ps1`     | Frozen-baseline identity and narrative                         |
| `PHASE-implementation-brief.template.md` | **nothing — filled by hand**       | The brief handed to an agent to implement one phase end to end |

The phase brief has no script because every field is a judgement call: which files to read,
what must not regress, which decisions stay open. Generating it would mean guessing those,
and a guessed Preserve list is worse than none.

## Placeholders

`{{TOKEN}}`. The scripts substitute them; a hand-filled template should have none left. To
check:

```powershell
Select-String -Path <file> -Pattern '\{\{'
```
