# Project C Curriculum - UART Core Tx/Rx (Living)

## Goal

Build robust protocol-level reasoning for UART TX/RX timing, framing correctness, and verification completeness under nominal and error conditions.

## Core Path (A to Z)

1. S01 - Baseline Calibration: establish confidence baseline and assumptions.
2. S02 - Dual-Domain Timing: system-clock domain versus baud domain.
3. S03 - Frame Semantics: start/data/stop interpretation.
4. S04 - TX/RX FSM Responsibilities: phase ownership and interactions.
5. S05 - Divisor and Drift Semantics: counter/divisor accuracy and phase drift risk.
6. S06 - Architecture Decomposition: arrow-by-arrow data/control walkthrough.
7. S07 - Verification Strategy: deterministic, randomized, and error-path tests.
8. S08 - Assertions and Coverage Closure: protocol invariants and state-space closure.
9. S09 - Branch A Closure Evidence: timing and implementation expectations.
10. S10 - Branch B Closure Evidence: physical-flow expectations.
11. S11 - Final Readiness Review: residual risk assessment and completion check.

## Adaptive Branch Rules

### Branch R1 - Sampling Alignment Remediation

Trigger:

- Confusion about when RX should sample each bit.

Action:

- Run bit-center timing exercises and frame-level sampling drills.

### Branch R2 - Divisor Accuracy Remediation

Trigger:

- Inability to reason about baud error accumulation.

Action:

- Add divisor math walkthrough and long-frame drift thought experiment.

### Branch D1 - Deep-Dive Track

Trigger:

- Strong protocol reasoning with consistent correctness.

Action:

- Expand into noise tolerance, oversampling rationale, and advanced error detection.

## Progress Tracker

|Stage|Status|Evidence|Notes|
|---|---|---|---|
|S01 - Baseline Calibration|planned|||
|S02 - Dual-Domain Timing|planned|||
|S03 - Frame Semantics|planned|||
|S04 - TX/RX FSM Responsibilities|planned|||
|S05 - Divisor and Drift Semantics|planned|||
|S06 - Architecture Decomposition|planned|||
|S07 - Verification Strategy|planned|||
|S08 - Assertions and Coverage Closure|planned|||
|S09 - Branch A Closure Evidence|planned|||
|S10 - Branch B Closure Evidence|planned|||
|S11 - Final Readiness Review|planned|||

## Live Update Rules

- Keep branch triggers and re-entry points explicit and versioned in this file.
- If a section is skipped, include why and what evidence justified skipping.
