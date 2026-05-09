# Project A Curriculum - Parameterized Counter (Living)

## Goal

Build full signal-level mastery of sequential counting, hold behavior, reset behavior, rollover, timing implications, and verification closure.

## Core Path (A to Z)

1. S01 - Baseline Calibration: establish confidence baseline and assumptions.
2. S02 - Timing Foundations: clock edge discipline and cycle-accurate tracing.
3. S03 - State Update Semantics: register storage, hold, reset, increment selection.
4. S04 - Boundary and Rollover Semantics: fixed-width arithmetic behavior at limits.
5. S05 - Architecture Decomposition: block diagram and arrow-by-arrow meaning.
6. S06 - Manual Trace Drills: multi-cycle trace with mixed enable/reset patterns.
7. S07 - Verification Strategy (Wave 1): non-code verification intent artifacts before RTL coding (scenario matrix, invariants, coverage plan, first-probe debug map).
8. S08 - RTL Structure and Executable Checks (Wave 2): implement RTL structure and execute Cocotb tests derived from S07 artifacts.
9. S09 - Branch A Closure Evidence: synthesis and timing closure expectations.
10. S10 - Branch B Closure Evidence: OpenLane and signoff expectations.
11. S11 - Final Readiness Review: failure-mode reflection and completion check.

## Adaptive Branch Rules

### Branch R1 - Remedial Timing Track

Trigger:

- Student confuses when state updates occur.

Action:

- Pause design progression.
- Run additional cycle-trace drills with explicit edge annotations.
- Re-enter Core Path at Stage 3 only after correct trace consistency.

### Branch R2 - Control Logic Precision Track

Trigger:

- Student misses hold/reset priority in mixed control patterns.

Action:

- Drill truth-table reasoning for reset and enable precedence.
- Add targeted invariant checks before continuing.

### Branch D1 - Deep-Dive Track

Trigger:

- Student answers quickly and correctly with signal-level detail.

Action:

- Add deeper topics: reset strategy tradeoffs, timing path thought experiment, counter-as-divider use case.

### Branch S1 - Skip Rule

Trigger:

- Student demonstrates mastery with accurate explanations and consistent trace results.

Action:

- Mark stage `skipped` only with brief justification and evidence.

## Evidence Requirements By Stage

- Stage 2: cycle timing explanation in student words.
- Stage 4: correct rollover explanation for width N.
- Stage 6: correct full trace for mixed enable/reset sequence.
- Stage 7: approved verification-intent pack (6-scenario matrix, 3 invariants, 4 coverage bins, first-probe debug mapping).
- Stage 8: executable verification evidence (Cocotb smoke + directed + randomized checks mapped back to Stage 7 artifacts).
- Stage 9 and 10: explicit success metric mapping for both branches.

## S07 to S08 Contract

- S07 output is design intent for verification, not full framework-heavy bench implementation.
- S08 output is executable verification aligned to S07 intent, alongside RTL structure review.
- Default executable flow in Sprint 1 to Sprint 4 remains Cocotb-first.
- UVM becomes a mandatory explicit project deliverable at Sprint 5, Project B (Bus Interconnect verification).

## Progress Tracker

| Stage                                 | Status  | Evidence                                                                                                                                                               | Notes                                                                                                    |
| ------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| S01 - Baseline Calibration            | done    | Confidence baseline set to 1/5                                                                                                                                         | Global noob assumption active                                                                            |
| S02 - Timing Foundations              | done    | Student attempted cycle trace; correction given                                                                                                                        | Hold-cycle miss detected and corrected                                                                   |
| S03 - State Update Semantics          | done    | Clean mixed-control trace through cycle 16; correctly applied holds at 5, 6, 9, and 14 plus reset priority at 11                                                       | Checkpoint passed; state-update law applied consistently                                                 |
| S04 - Boundary and Rollover Semantics | done    | Wrap rule and invalidity interval clarified: t_wrap = R + 2^N + H valid iff no reset in (R, t_wrap]                                                                    | Boundary semantics checkpoint accepted; ready for architecture decomposition                             |
| S05 - Architecture Decomposition      | done    | Corrected arrow classification and failure-symptom mapping submitted for all 10 arrows; OBS nuance clarified                                                           | Architecture decomposition checkpoint accepted                                                           |
| S06 - Manual Trace Drills             | done    | Integrated 6-cycle drill passed: first mismatch at C2 with arrow-6 diagnosis (source=HOLD, destination=INCREMENT, wrong increment observed)                            | S06 exit criteria met: modulo trace accuracy and path-level fault localization                           |
| S07 - Verification Strategy           | done    | Final S07 pack accepted: 6 scenario matrix (including wrap-shift C17->C19), 3 edge-precise invariants, 4 explicit-hit coverage bins, and external-first probe ordering | S07 exit criteria met; one editorial normalization applied to increment row timing label                 |
| S08 - RTL Structure Review            | active  | S08-C checker-flow pattern accepted via representative-row submission; student flagged SV/Cocotb implementation confidence gap before coding                           | Run S08-L0 micro-learning gate (SV basics + Cocotb basics), then start RTL/Cocotb implementation kickoff |
| S09 - Branch A Closure Evidence       | planned |                                                                                                                                                                        | Quartus available                                                                                        |
| S10 - Branch B Closure Evidence       | planned |                                                                                                                                                                        | OpenLane available                                                                                       |
| S11 - Final Readiness Review          | planned |                                                                                                                                                                        |                                                                                                          |

## Live Update Rules

- Update this file after each teaching exchange that changes progression.
- Do not delete prior branch decisions; append and annotate.
- If diverging, record trigger, action, and re-entry point.
