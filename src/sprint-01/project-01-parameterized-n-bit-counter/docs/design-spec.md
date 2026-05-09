# Design Specification

## Project

Parameterized N-bit counter.

## Objective

Build a synthesizable parameterized counter that supports synchronous enable/hold behavior, an asynchronous active-low reset, and configurable width through a parameter.

## Parameter Contract

- `WIDTH` shall be a positive integer parameter.
- The default `WIDTH` shall be 4.
- The `count` output width shall exactly match `WIDTH`.

## Functional Requirements

| ID  | Requirement                                                                                     | Clarification                                          |
| --- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| FR1 | The design shall expose a clock input.                                                          | `clk` is the sampling clock for state updates.         |
| FR2 | The design shall expose an asynchronous active-low reset input.                                 | `reset_n` drives immediate clearing when asserted low. |
| FR3 | The design shall expose a synchronous enable input.                                             | `enable` decides whether the count advances or holds.  |
| FR4 | The design shall expose a positive integer width parameter with default 4.                      | `WIDTH` controls the bit-width of `count`.             |
| FR5 | The design shall output the current count value.                                                | `count[WIDTH-1:0]` is the sole state output.           |
| FR6 | On a falling edge of reset, the count shall clear to zero immediately.                          | Reset dominates the register regardless of enable.     |
| FR7 | On a rising clock edge with reset deasserted and enable high, the count shall increment by one. | Enabled cycles advance the state.                      |
| FR8 | On a rising clock edge with reset deasserted and enable low, the count shall hold its value.    | Disabled cycles preserve the previous state.           |
| FR9 | The count shall wrap modulo $2^{WIDTH}$.                                                        | Overflow from all-ones returns to zero.                |

## Control Contract

| Condition                   | Required Behavior                                     |
| --------------------------- | ----------------------------------------------------- |
| `reset_n = 0`               | Clear `count` immediately, regardless of `enable`.    |
| `reset_n = 1`, `enable = 0` | Hold the current `count` value on rising clock edges. |
| `reset_n = 1`, `enable = 1` | Increment `count` on each rising clock edge.          |

This control contract is part of the required behavior, not an optional optimization.

## Timing and Behavior

- Reset is asynchronous and dominates the count register.
- Enable is sampled only on the rising edge of `clk` when reset is not asserted.
- Deasserting `reset_n` or toggling `enable` between clock edges does not change `count` by itself.
- Hold behavior is deliberate and part of the contract, not an accidental side effect.
- Legal corner cases include `WIDTH = 1`, enable low for multiple cycles, reset assertion while enable is high or low, and wrap from the maximum count value back to zero.

## Interface

- `clk`: clock input.
- `reset_n`: active-low reset input.
- `enable`: synchronous enable input.
- `count[WIDTH-1:0]`: current count output.

## Non-Goals

- No CDC logic.
- No bus interface.
- No handshake protocol.
- No power, timing-closure, or physical implementation optimizations at this stage.

## Implementation Notes

- Keep the RTL synthesizable.
- Avoid driving a clock from inside the DUT.
- Keep testbench stimulus outside the DUT.
- Preserve parameterization so width changes do not require code duplication.

## Acceptance Criteria

- Reset clears the count immediately when asserted low.
- Hold cycles do not change the count when `enable` is low.
- Reset has priority over enable.
- Reset release does not cause a spurious increment before the next rising clock edge.
- The output increments by one on each rising clock edge while reset is deasserted and `enable` is high.
- The output matches the expected modulo behavior for the configured width.
- The design compiles cleanly in simulation and is structurally ready for synthesis flow.

## Traceability

- FR1 to FR5 are verified by interface-compile checks and the smoke tests.
- FR6 is verified by the asynchronous reset test and the reset-priority test.
- FR7 is verified by the increment and randomized reset-enable tests.
- FR8 is verified by the hold behavior test and the randomized reset-enable tests.
- FR9 is verified by the wrap and long-run enabled tests.

## Verification Coupling

- This spec is verified by the verification plan in `docs/verification-plan.md`.
- Smoke, directed, and randomized test intents should trace back to the requirements above.
