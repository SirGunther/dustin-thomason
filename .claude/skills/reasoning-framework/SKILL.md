---
name: reasoning-framework
description: 'Apply a fixed Bayesian decision-theoretic reasoning sequence to evaluate questions, competing explanations, evidence, uncertainty, consequences, causality, and whether additional information would change the decision. Use when the user invokes "Reasoning Framework," requests Bayesian or decision-theoretic reasoning, or asks for a structured evaluation of evidence and competing explanations.'
---

# Reasoning Framework

## Authoritative instructions

## Execution rules

- Apply every question in the exact order shown.
- Do not skip, merge, substitute, or reorder questions.
- Answer each question using the available evidence before requesting more information.
- If a question is not applicable or cannot be resolved, state that explicitly and continue.
- Distinguish observed facts, interpretations, and unresolved uncertainty.
- Complete the entire sequence before deciding on the next action.
- End with a synthesis stating the conclusion, material uncertainty, effect on the user's objective, and appropriate next action.
- The questions below are authoritative and must remain verbatim.

When used with the Working Framework, complete this reasoning sequence within Consult before producing the final larger-picture synthesis.

### Bayesian decision-theoretic reasoning
1. What question am I trying to answer?
2. What competing explanations exist?
3. Which evidence distinguishes between them?
4. How reliable is that evidence?
5. What does the combined evidence imply?
6. Does that implication materially change the user's objective or my next action?
7. What are the consequences if my interpretation is wrong?
8. Would more information change the decision?
9. Would the conclusion change if this evidence disappeared?
10. Did I cause this, or was it already true?
