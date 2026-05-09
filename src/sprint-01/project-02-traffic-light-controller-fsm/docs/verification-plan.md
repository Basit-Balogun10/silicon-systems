# Verification Plan

## Scope

This plan covers simulation-based verification for the Traffic Light Controller FSM, including the internal dwell timer behavior, the legal phase sequence, reset recovery, and output exclusivity. The plan assumes the RTL will be verified with a reusable hardware testbench plus Cocotb scenarios.

## Environment and Assumptions

- Verilator is the default simulator.
- Icarus Verilog is supported as an alternate compile path for portability checks.
- Cocotb is the primary test authoring layer for directed and randomized scenarios.
- The controller is sampled on the rising edge of `clk`.
- `vehicle_request` is treated as a synchronous demand input for the purpose of this project.
- Reset is asynchronous and active-low.
- The dwell timer is internal to the controller and counts clock cycles while a phase is active.

## Verification Strategy

- Start with smoke tests that prove reset, output decode, and basic phase holding work.
- Add directed tests that target each legal transition independently.
- Add randomized request sequences that prove request noise does not break phase legality.
- Add boundary-value tests for the minimum dwell parameters, especially when they equal 1.
- Use a reference model that mirrors the intended phase and dwell behavior cycle by cycle.
- Use assertions for safety rules that should never fail, especially output mutual exclusion and legal-state stability.

## Harness Contract

- One top-level hardware testbench is sufficient for the project.
- The harness shall own clock generation, reset sequencing, and waveform setup.
- Cocotb tests shall live in multiple `@cocotb.test()` coroutines inside one suite, not one file per scenario.
- Shared helpers should be kept in reusable Python modules such as a reference model and small stimulus helpers.
- The harness should be reusable across smoke, directed, and randomized tests so the debug story stays consistent.

## Reference Model Contract

- The reference model is the software oracle for the controller.
- It shall store the current phase and the current dwell count as plain Python state.
- On reset, the model shall immediately return to RED and clear the dwell count.
- While in RED, the model shall increment its dwell count until the RED minimum is met, then transition to GREEN only if `vehicle_request` is present.
- While in GREEN, the model shall increment its dwell count until the GREEN minimum is met, then transition to YELLOW.
- While in YELLOW, the model shall increment its dwell count until the YELLOW minimum is met, then transition to RED.
- The model shall produce the expected red, yellow, and green outputs from the current phase.
- The checker should compare DUT outputs against this model after each sampled edge and on each reset assertion.

## Scenario Matrix

| Scenario                        | Type       | Purpose                                                 | Pass Condition                                                     |
| ------------------------------- | ---------- | ------------------------------------------------------- | ------------------------------------------------------------------ |
| Reset to RED                    | Smoke      | Prove asynchronous reset dominates all behavior.        | Outputs return to RED immediately and dwell count clears.          |
| RED hold before dwell expiry    | Smoke      | Prove RED cannot exit early.                            | Phase stays RED until minimum dwell is satisfied.                  |
| RED to GREEN with demand        | Directed   | Prove legal exit from RED.                              | Transition occurs only when dwell is complete and request is high. |
| RED hold without demand         | Directed   | Prove request is required for RED exit.                 | Controller stays in RED even after dwell expiry if request is low. |
| GREEN hold before dwell expiry  | Smoke      | Prove GREEN cannot exit early.                          | Phase stays GREEN until minimum dwell is satisfied.                |
| GREEN to YELLOW                 | Directed   | Prove legal GREEN exit path.                            | Transition occurs exactly when GREEN dwell expires.                |
| YELLOW hold before dwell expiry | Smoke      | Prove YELLOW cannot exit early.                         | Phase stays YELLOW until minimum dwell is satisfied.               |
| YELLOW to RED                   | Directed   | Prove legal YELLOW exit path.                           | Transition occurs exactly when YELLOW dwell expires.               |
| Request toggling in GREEN       | Directed   | Prove request does not preempt GREEN.                   | GREEN behavior is unchanged by request noise.                      |
| Request toggling in YELLOW      | Directed   | Prove request does not preempt YELLOW.                  | YELLOW behavior is unchanged by request noise.                     |
| Minimum dwell equals 1          | Boundary   | Prove the smallest legal dwell values behave correctly. | The controller transitions after a single eligible cycle.          |
| Randomized request sequence     | Randomized | Stress timing and request noise across long runs.       | Reference model and DUT remain aligned for every sampled edge.     |
| Reset in every phase            | Directed   | Prove reset recovery from all states.                   | Reset returns the machine to RED from RED/GREEN/YELLOW.            |
| Long-run round trip             | Directed   | Prove repeated legal cycling stays correct.             | DUT matches the model through multiple RED->GREEN->YELLOW cycles.  |

## Checker Hooks

- Sample `vehicle_request` before the rising edge so the model knows what the DUT should see.
- Check outputs immediately after the edge so comparisons align with registered state updates.
- Check asynchronous reset immediately when `reset_n` falls, even if the controller is mid-phase.
- Record the current phase, expected phase, dwell count, actual outputs, and the request value when a mismatch occurs.
- Keep the same checker shape across all test types so a failure in one scenario is easy to compare against another.

## Pass/Fail Rules

- A test passes only when every required check in its scenario passes.
- Any mismatch between expected and actual outputs is a failure.
- Any illegal light combination is a failure, even if the phase transition eventually recovers.
- Any observed phase skip is a failure.
- The first failure should identify whether the issue was reset behavior, dwell counting, request gating, or output decode.

## Coverage Targets

- RED state hit.
- GREEN state hit.
- YELLOW state hit.
- RED hold hit.
- GREEN hold hit.
- YELLOW hold hit.
- RED to GREEN transition hit.
- GREEN to YELLOW transition hit.
- YELLOW to RED transition hit.
- Reset recovery from all states hit.
- Request-low hold in RED hit.
- Request-high gating in RED hit.
- Minimum-dwell boundary hit.
- Randomized request segment hit.

## Traceability Matrix

| Requirement | Scenario Coverage                                                              |
| ----------- | ------------------------------------------------------------------------------ |
| FR1         | Clocked harness, all scenarios                                                 |
| FR2         | Reset to RED, reset in every phase                                             |
| FR3         | RED hold without demand, RED to GREEN with demand, randomized request sequence |
| FR4         | Output decode checks, illegal light combination assertions                     |
| FR5         | Minimum dwell equals 1, long-run round trip                                    |
| FR6         | RED hold before dwell expiry, RED hold without demand                          |
| FR7         | RED to GREEN with demand                                                       |
| FR8         | GREEN hold before dwell expiry, request toggling in GREEN                      |
| FR9         | GREEN to YELLOW                                                                |
| FR10        | YELLOW hold before dwell expiry, request toggling in YELLOW                    |
| FR11        | YELLOW to RED                                                                  |
| FR12        | Reset to RED, reset in every phase                                             |
| FR13        | Output decode checks, illegal light combination assertions                     |
| FR14        | Long-run round trip, randomized request sequence                               |
| FR15        | Checker timing hooks, randomized request sequence                              |

## Exit Criteria

- The project runs cleanly with the default simulator once RTL is added.
- All smoke, directed, boundary, and randomized tests pass.
- Every coverage target listed above is hit at least once.
- No unresolved expectation mismatches remain in the checker logs.
- The controller is ready for the next-step FPGA and ASIC workflow once implementation lands.
