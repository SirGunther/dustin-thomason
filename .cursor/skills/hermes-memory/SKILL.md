---
name: hermes-memory
description: Log internal capabilities and self-queries for efficiency.
---

This skill allows Hermes to track its own capabilities, limitations, and answers to self-posed questions to improve efficiency and reduce redundant explanations.

**Logging Convention:**
When learning a new capability, a limitation, or a complex answer to a self-query, log it to the repository.

**Format:**
- [YYYY-MM-DD] | [Type: Capability/Limitation/Self-Query] | [Content]

**Example:**
- [2026-09-25] | [Capability] | Can interact with local servers via browser_navigate(http://localhost:PORT) and use browser_vision for visual confirmation.
- [2026-09-25] | [Limitation] | Cannot see the user's physical screen or windows not navigated to via browser tools.

**Update Process:**
1. Identify the new information.
2. Append to the repository file.
3. Use skill_view to quickly reference this knowledge in future turns.
