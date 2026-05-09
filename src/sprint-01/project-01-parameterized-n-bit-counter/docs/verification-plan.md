# Verification Plan

## Scope

This plan covers simulation-based verification for the parameterized N-bit counter using both SystemVerilog testbench scaffolding and Cocotb-based tests.

## Environment and Assumptions

- Verilator is the default simulation toolchain.
- Icarus Verilog is supported as an alternate compile/simulation path for compatibility checks.
- Verilator generates FST waveforms; Icarus Verilog generates VCD waveforms.
- The testbench owns clock generation, reset sequencing, enable sequencing, and waveform setup.
- The DUT is expected to expose `clk`, `reset_n`, `enable`, and `count`.

## Verification Strategy

- Use a small number of smoke tests to prove the design is alive and basic reset behavior works.
- Use directed tests to prove explicit corner cases such as wrap, hold behavior, parameter width edge cases, and reset priority behavior.
- Use randomized tests to exercise longer sequences and catch reset/enable edge cases that are hard to enumerate manually.
- Keep a shared reference model so all tests compare actual DUT behavior against the same expected behavior.

## Harness Contract

- One DUT wrapper is used for the counter.
- One top-level SystemVerilog testbench module is sufficient for clock, reset, enable, and waveform setup.
- Cocotb testcases are split into multiple `@cocotb.test()` coroutines inside one Python test suite.
- Shared helpers should live in Python modules such as a reference model, drivers, and fixtures.
- A single testbench does not need one file per testcase; it needs one reusable harness and many focused test functions.

## Reference Model Contract

- The reference model is the test's independent prediction of correct behavior.
- For this counter, it stores the expected count as plain software state.
- When `reset_n` is low, the model forces the expected count to zero.
- When `reset_n` is high, `enable` is low, and a rising clock edge occurs, the model holds the expected count.
- When `reset_n` is high, `enable` is high, and a rising clock edge occurs, the model increments and wraps modulo $2^{WIDTH}$.
- Each checker hook compares the DUT output against the reference model after the relevant event.
- If the DUT and model diverge, the test failure tells you the design, not the checker, is wrong.

## Control Sequencing Contract

- Reset has priority over enable at every observation point.
- `enable` must be sampled before the rising edge and interpreted on that edge.
- `enable = 0` holds the current value across the edge.
- `enable = 1` advances the count across the edge.
- Toggling `enable` between edges has no effect until the next rising edge.

## Test Matrix

| Scenario                  | Test Type  | Purpose                                                           | Pass Condition                                                   |
| ------------------------- | ---------- | ----------------------------------------------------------------- | ---------------------------------------------------------------- |
| Async reset assertion     | Smoke      | Prove reset clears the counter immediately, independent of enable | Count becomes zero as soon as `reset_n` falls                    |
| Hold behavior             | Smoke      | Prove enable low holds the counter across rising edges            | Count stays unchanged while `enable` is low                      |
| Increment behavior        | Smoke      | Prove the counter advances under normal operation                 | Count increments by one modulo $2^{WIDTH}$                       |
| Reset priority            | Directed   | Prove reset overrides enable and clears state first               | Reset wins and count clears immediately                          |
| Wrap behavior             | Directed   | Prove wrap occurs at the maximum value                            | Maximum value rolls to zero                                      |
| WIDTH=1 corner case       | Directed   | Prove the smallest legal width behaves correctly                  | Count toggles cleanly between 0 and 1                            |
| Long-run enabled behavior | Directed   | Prove repeated enabled cycles remain correct over multiple edges  | Observed count matches the reference model for all sampled edges |
| Randomized sequence       | Randomized | Stress random reset and enable timing over longer runs            | Invariants hold for all sampled edges                            |

## Checker Hooks

- Sample the inputs before the active edge so the test knows what the DUT should see.
- Check the output immediately after the edge so the comparison aligns with the register update.
- Check asynchronous reset immediately after `reset_n` falls, even if `enable` is low.
- Record failure with actual count, expected count, pre-count, `reset_n`, `enable`, and a triage hint.
- Use the same checker hook shape across smoke, directed, and randomized tests so debug behavior stays consistent.

## Pass/Fail Rules

- A test passes only when every required check in its scenario passes.
- Any required mismatch is a failure.
- The first failure should identify whether the mismatch came from control behavior, state capture, or expectation calculation.

## Coverage Targets

- Async reset hit.
- Enable high hit.
- Increment hit.
- Hold hit.
- Reset priority hit.
- Wrap hit.
- WIDTH=1 hit.
- Random segment hit.
- Reset-enable transition hit.

## Traceability Matrix

| Requirement | Scenario Coverage                                       |
| ----------- | ------------------------------------------------------- |
| FR1         | Interface compile, all scenarios                        |
| FR2         | Async reset assertion, randomized reset timing          |
| FR3         | Hold behavior, reset priority                           |
| FR4         | WIDTH=1 corner case, width-specific instantiation smoke |
| FR5         | Interface compile, all scenarios                        |
| FR6         | Async reset assertion, reset priority                   |
| FR7         | Increment behavior, long-run enabled behavior           |
| FR8         | Hold behavior, randomized reset-enable sequence         |
| FR9         | Wrap behavior, long-run enabled behavior                |

## Exit Criteria

- `make e2e` passes with the default simulator toolchain.
- All smoke, directed, and randomized tests pass.
- Every coverage target listed above is hit at least once.
- No unresolved expectation mismatches remain in the checker logs.
