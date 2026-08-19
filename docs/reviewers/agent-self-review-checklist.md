# Agent self-review checklist

Run before reporting any code work as done. Items 1 to 8 come from `pr-review-patterns.md`; items 9 to 12 come from mistakes made on PRDV-16403.

- [ ] Every user-facing string comes from the i18n locale file
- [ ] No bare string literal in a comparison or switch
- [ ] Test doubles use the repo's typed mock helper, never an `as` cast
- [ ] Mirror implementations have matching test coverage on both sides
- [ ] No handler mixes three or more concerns inline
- [ ] Any removed try/catch or guard carries a one-line reason
- [ ] No comment names a person or references a ticket document
- [ ] Anything setting an org-wide pattern is flagged, not shipped quietly
- [ ] No scaffolding left modified for a test I did not write
- [ ] Existing specs of any class I added a dependency to were run
- [ ] Every new file is reachable by an import
- [ ] Each failing check is proven mine or pre-existing, with evidence
