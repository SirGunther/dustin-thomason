# {{PROJECT}} Capability Catalog

This catalog describes {{PROJECT}} as it exists on {{DATE}}. It separates what actually works
from what is simulated, so a working-looking prototype is not mistaken for a working tool.

**_The single most important caveat about this project, stated plainly. If a reader takes one
sentence away, it should be this one._**

## Status legend

- **Working** — implemented and verified against a real check.
- **UI POC** — implemented, but the behavior is simulated, in-memory, or stubbed.
- **Specified** — documented or styled, but not connected end to end.
- **Deferred** — deliberately reserved for a later slice.

## _Area_

| Surface or control | Status | Current behavior | Implementation reference |
| --- | --- | --- | --- |
| _Control or behavior_ | Working | _What it does now, including limits and caps. State the real numbers._ | _Function, selector, or file_ |
| _Not-yet-built thing_ | Deferred | _What does not exist. Say "not implemented" rather than describing an intention._ | _`DECISIONS-PENDING.md` → `XXX-001`_ |

## Verification posture

| Aspect | Status | Detail |
| --- | --- | --- |
| Automated regression suite | _status_ | _What exists, or plainly that nothing does_ |
| Ad-hoc verification | _status_ | _The exact command, what it covers_ |
| Formatting gate | _status_ | _Command and scope_ |
| Lint / audit gates | _status_ | _Applicable, or why not — name the reason_ |

## Known limitations

_A flat list, bluntly worded. This is the section a reader checks before trusting the tool
with something real, so it is the wrong place for optimism._

- _Limitation_
