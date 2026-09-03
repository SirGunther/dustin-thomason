# Rules for writing Ai prompts

1. **Audience** - Specify who will be reading the output

2. Operational Definitions - see [S1](#Operational-Definitions)

---

### S1-Operational-Definitions

Claude behaves almost like a blank slate when instructions define behavior without clearly defining what that behavior means. When an instruction is ambiguous, it tends to satisfy the literal wording by modifying its default behavior rather than inferring the user’s intended outcome. This makes operational definitions important: expectations need to specify what the desired behavior actually looks like in practice. Without that definition, Claude is likely to resolve ambiguity using its existing patterns rather than adapting to the user’s needs.
