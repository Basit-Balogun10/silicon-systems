# Design Specification
## Project: Parameterized N-bit Up/Down Counter
### Sprint 1 — Project A

---

## Objective

Build a synthesizable parameterized counter that supports synchronous
enable/hold behaviour, an asynchronous active-low reset, configurable
width, and runtime-selectable count direction (up or down).

---

## Parameters

| Parameter | Type             | Default | Purpose                          |
|-----------|------------------|---------|----------------------------------|
| `WIDTH`   | positive integer | 4       | Bit-width of the count output.   |

The `count` output width shall exactly match `WIDTH`.

---

## Interface

| Signal          | Direction | Description                                              |
|-----------------|-----------|----------------------------------------------------------|
| `clk`           | input     | Sampling clock. All state updates on rising edge.        |
| `reset_n`       | input     | Asynchronous active-low reset.                           |
| `enable`        | input     | Synchronous enable. Low = hold, High = count.            |
| `up_down`       | input     | Direction select. High = count up, Low = count down.     |
| `count[WIDTH-1:0]` | output | Current count value.                                  |

---

## Control Contract

| Condition                                    | Required Behaviour                                        |
|----------------------------------------------|-----------------------------------------------------------|
| `reset_n = 0`                                | Clear `count` to zero immediately, regardless of enable.  |
| `reset_n = 1`, `enable = 0`                  | Hold current `count` on every rising clock edge.          |
| `reset_n = 1`, `enable = 1`, `up_down = 1`  | Increment `count` by 1 on each rising clock edge.         |
| `reset_n = 1`, `enable = 1`, `up_down = 0`  | Decrement `count` by 1 on each rising clock edge.         |

---

## Wrap Behaviour

The counter wraps in both directions using natural unsigned arithmetic:

```
Counting up:   ...→ (2^WIDTH - 1) → 0 → 1 → ...
Counting down: ...→ 0 → (2^WIDTH - 1) → (2^WIDTH - 2) → ...
```

No saturation. No error flag. Wrap is always defined.

---

## Timing and Behaviour

- Reset is asynchronous and dominates the count register.
- `enable` and `up_down` are sampled on the rising edge of `clk`
  when reset is not asserted.
- Changing `up_down` between clock edges has no effect until the
  next rising edge.
- Deasserting `reset_n` or toggling `enable` mid-cycle does not
  change `count` by itself.

---

## Functional Requirements

| ID  | Requirement                                                                                          |
|-----|------------------------------------------------------------------------------------------------------|
| FR1 | The design shall expose clk, reset_n, enable, up_down inputs and count output.                       |
| FR2 | reset_n shall be asynchronous, active-low, and clear count to zero immediately.                      |
| FR3 | enable shall be synchronous. When low, count shall hold its value on rising edges.                   |
| FR4 | WIDTH shall be a positive integer parameter with default 4. count width shall equal WIDTH.           |
| FR5 | When enable is high and up_down is high, count shall increment by 1 on each rising edge.             |
| FR6 | When enable is high and up_down is low, count shall decrement by 1 on each rising edge.              |
| FR7 | Count shall wrap on overflow (up) from 2^WIDTH-1 to 0.                                              |
| FR8 | Count shall wrap on underflow (down) from 0 to 2^WIDTH-1.                                           |
| FR9 | reset_n shall dominate enable and up_down. Reset clears count regardless of other inputs.            |

---

## Non-Goals

- No saturation mode (count stops at max/min without wrapping).
- No load/preset input.
- No carry/borrow output.
- No CDC logic.
- No bus interface.
- No physical implementation optimizations at this stage.

---

## Implementation Notes

- Use `always_ff` for the count register.
- Keep the RTL synthesizable — avoid latches and combinational loops.
- The up/down direction is purely combinational input to the next-state
  logic — no state register needed for direction.
- Wrap is free: unsigned arithmetic in `always_ff` wraps naturally at
  2^WIDTH without any explicit check.

---

## Acceptance Criteria

- Reset clears count immediately when reset_n is asserted low.
- Hold cycles do not change count when enable is low, regardless of up_down.
- reset_n has priority over enable and up_down.
- Count increments by 1 each enabled up cycle.
- Count decrements by 1 each enabled down cycle.
- Count wraps correctly from max to 0 (up direction).
- Count wraps correctly from 0 to max (down direction).
- Design compiles cleanly and is structurally ready for synthesis.

---

## Traceability

| Requirement | Verification Intent                                           |
|-------------|---------------------------------------------------------------|
| FR1         | Interface compile check, all scenarios.                       |
| FR2         | Async reset test, reset priority test.                        |
| FR3         | Hold behaviour test, randomized enable sequence.              |
| FR4         | WIDTH=1 boundary test, parameter compile check.               |
| FR5         | Increment test, long-run up sequence.                         |
| FR6         | Decrement test, long-run down sequence.                       |
| FR7         | Wrap up test.                                                 |
| FR8         | Wrap down test.                                               |
| FR9         | Reset priority test, randomized reset/enable/direction stress.|