# Sprint 01 Class Notes Index

## Sprint Goal

Build deep intuition for the three digital atoms:

- Parameterized Counter
- Finite State Machine (Traffic Light Controller)
- UART Core (Tx/Rx)

## Working Assumptions

- Confidence baseline for this sprint: 1/5 for all listed knowledge gaps unless explicitly updated.
- Branch policy for major digital projects: run both Branch A (FPGA) and Branch B (ASIC) by default.

## Project Notes

- [Project A - Parameterized Counter](project-a-parameterized-counter.md)
- [Project B - Traffic Light Controller FSM](project-b-traffic-light-controller-fsm.md)
- [Project C - UART Core Tx/Rx](project-c-uart-core-tx-rx.md)

## Living Curriculum (Project ToC)

- [Sprint 01 Curriculum Index](../../curriculum/sprint-01/README.md)
- [Project A Curriculum - Parameterized Counter](../../curriculum/sprint-01/project-a-curriculum.md)
- [Project B Curriculum - Traffic Light Controller FSM](../../curriculum/sprint-01/project-b-curriculum.md)
- [Project C Curriculum - UART Core Tx/Rx](../../curriculum/sprint-01/project-c-curriculum.md)

## Required Note Structure (Per Project)

1. Objective.
2. Why this project matters.
3. Knowledge Gap Assessment (Mandatory Before Design) using the standard sprint list.
4. Detailed notes on each listed gap before architecture.
   - Format each gap with three lines: SWE analogy, Plain-English note, Project relevance.
5. Architecture view with diagram and explicit arrow-by-arrow walkthrough.
   - Add architecture interpretation notes so every major arrow is explained, not just shown.
6. Threat map.
7. Verification checklist.
8. Common failure modes and first debug signals.
9. Success criteria.
10. Self-check questions.

## Common Sprint 01 Threat Map

1. Confusing functional correctness with timing correctness.
2. Treating state transitions as obvious and failing to define transition guards precisely.
3. Writing happy-path-only tests and missing boundary behaviors.

## Additional Items To Document In Every Project Note

- Project objective and why it matters to later sprints.
- Knowledge-gap primer with SWE analogies and plain-English explanations.
- Architecture interpretation notes that explain every major diagram arrow.
- Branch A and Branch B evidence required for completion.
