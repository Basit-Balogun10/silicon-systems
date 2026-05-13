# Verification Plan
## Project: Adaptive Traffic Light Controller FSM
### Sprint 1 — Project B

---

## Scope

Simulation-based verification of the traffic light controller RTL covering:
adaptive green timing, conflict monitoring, reset behaviour, and output
exclusivity. Verification uses a SystemVerilog testbench for structural/smoke
tests and CocoTB for directed and randomized scenarios.

---

## Environment

- **Default simulator:** Verilator
- **Alternate simulator:** Icarus Verilog (portability check)
- **Test authoring:** CocoTB (`@cocotb.test()` coroutines, one suite file)
- **Waveforms:** FST via `$dumpfile` / `--trace-fst`
- **Sampling:** Rising edge of `clk`
- **Reset:** Asynchronous, active-low

---

## Verification Strategy

1. Smoke tests — prove reset, output decode, and basic state holding work
   before anything else runs.
2. Directed tests — target each timing rule and sensor interaction
   independently.
3. Boundary tests — test MIN_GREEN=1, MAX_GREEN=MIN_GREEN+1, sensor
   transitions exactly at boundaries.
4. Randomized tests — stress sensor noise and random timing across long
   runs with a reference model as oracle.
5. Safety assertions — run throughout all tests, not just dedicated scenarios.

---

## Reference Model Contract

The Python reference model is the oracle for all CocoTB tests.

- Stores: current state, phase timer count.
- On reset: state → NS_GREEN, timer → 0.
- On each rising edge: advances timer, evaluates sensor inputs, applies
  the same timing rules as the RTL (MIN_GREEN, MAX_GREEN, EXTENSION,
  ABS_MAX_GREEN, YELLOW_CYCLES).
- Produces: expected ns_green, ns_yellow, ns_red, ew_green, ew_yellow,
  ew_red, conflict for each cycle.
- Checker compares all DUT outputs against model after every sampled edge.

---

## Scenario Matrix

| ID  | Scenario                              | Type       | Pass Condition                                                                   |
|-----|---------------------------------------|------------|----------------------------------------------------------------------------------|
| S01 | Reset from power-on                   | Smoke      | State goes to NS_GREEN, timer=0, safe output decode.                             |
| S02 | Reset mid-phase (all four states)     | Directed   | Reset dominates from any state. Returns to NS_GREEN immediately.                 |
| S03 | Green hold before MIN_GREEN           | Smoke      | Active green does not exit before MIN_GREEN regardless of sensor values.         |
| S04 | Sensor-triggered early exit           | Directed   | After MIN_GREEN, other_sensor=1 causes transition to yellow on next edge.        |
| S05 | No early exit when other sensor low   | Directed   | Between MIN_GREEN and MAX_GREEN, other_sensor=0 → green continues.               |
| S06 | Extension granted at MAX_GREEN        | Directed   | At MAX_GREEN, other_sensor=0 → state stays green for EXTENSION more cycles.      |
| S07 | No extension when other sensor high   | Directed   | At MAX_GREEN, other_sensor=1 → transition to yellow, no extension.               |
| S08 | ABS_MAX_GREEN forces transition       | Directed   | At ABS_MAX_GREEN, transition occurs regardless of sensor state.                  |
| S09 | Yellow fixed duration                 | Smoke      | Yellow lasts exactly YELLOW_CYCLES. Sensor changes during yellow have no effect. |
| S10 | Full legal cycle                      | Directed   | NS_GREEN→NS_YELLOW→EW_GREEN→EW_YELLOW→NS_GREEN completes correctly.              |
| S11 | Phase skip check                      | Directed   | No state is ever observed that is not in the legal four-state sequence.          |
| S12 | Output mutual exclusion               | Smoke      | ns_green and ew_green are never simultaneously high across all scenarios.        |
| S13 | Conflict flag assertion               | Directed   | Inject illegal state to verify conflict fires immediately (combinational check). |
| S14 | MIN_GREEN boundary = 1 cycle          | Boundary   | With MIN_GREEN=1, sensor can trigger exit after a single cycle.                  |
| S15 | Sensor transitions exactly at boundary| Boundary   | other_sensor goes high on exactly cycle MIN_GREEN → exit occurs that cycle.      |
| S16 | Randomized sensor sequence            | Randomized | Reference model and DUT stay aligned across 10,000+ cycles of random inputs.    |
| S17 | Long-run round trip                   | Randomized | DUT matches model through 100+ complete NS_GREEN→...→EW_YELLOW cycles.           |

---

## Safety Assertions (Always On)

These run as background checks across every scenario:

```python
# Output mutual exclusion
assert not (dut.ns_green.value and dut.ew_green.value)

# Conflict flag correctness
expected_conflict = dut.ns_green.value and dut.ew_green.value
assert dut.conflict.value == expected_conflict

# Legal state sequence — no skips
assert current_state in [NS_GREEN, NS_YELLOW, EW_GREEN, EW_YELLOW]

# Minimum green not violated
if state_just_changed_to_green:
    assert phase_timer == 0  # fresh timer on entry
```

---

## Checker Hooks

- Sample sensor inputs **before** the rising edge so the model sees what
  the DUT will see.
- Check all outputs **after** the rising edge so comparisons align with
  registered state.
- Check reset outputs **immediately** when `reset_n` falls — no clock
  edge needed.
- On any mismatch: log current state, expected state, phase timer value,
  sensor values, and all output values. This is enough to diagnose any
  failure without opening the waveform.

---

## Pass/Fail Rules

- A scenario passes only when every check within it passes.
- Any output mismatch against the reference model is a failure.
- Any illegal output combination (two greens at once) is a failure even
  if the state eventually recovers.
- Any phase skip is a failure.
- The first failure log must identify which rule was violated: timing,
  sensor response, or output decode.

---

## Coverage Targets

**State coverage:**
- NS_GREEN entered
- NS_YELLOW entered
- EW_GREEN entered
- EW_YELLOW entered

**Transition coverage:**
- NS_GREEN → NS_YELLOW (sensor-triggered)
- NS_GREEN → NS_YELLOW (MAX_GREEN-triggered)
- NS_GREEN → NS_YELLOW (ABS_MAX_GREEN-triggered)
- NS_GREEN → NS_YELLOW (extension expired)
- NS_YELLOW → EW_GREEN
- EW_GREEN → EW_YELLOW (all four trigger types as above)
- EW_YELLOW → NS_GREEN

**Timing boundary coverage:**
- Exit at exactly MIN_GREEN
- Exit between MIN_GREEN and MAX_GREEN
- Exit at exactly MAX_GREEN
- Extension granted
- Exit at exactly ABS_MAX_GREEN

**Sensor coverage:**
- other_sensor=0 during active green (no early exit)
- other_sensor=1 during active green (early exit)
- Sensor transition during yellow (no effect)
- Sensor goes high exactly at MIN_GREEN boundary

**Reset coverage:**
- Reset from NS_GREEN
- Reset from NS_YELLOW
- Reset from EW_GREEN
- Reset from EW_YELLOW

---

## Traceability

| Requirement | Scenarios                          |
|-------------|------------------------------------|
| FR1         | All scenarios (interface check)    |
| FR2         | S01, S02                           |
| FR3         | S10, S11                           |
| FR4         | S03, S14                           |
| FR5         | S04, S15                           |
| FR6         | S06, S07                           |
| FR7         | S08                                |
| FR8         | S09                                |
| FR9         | S12, always-on assertion           |
| FR10        | S13, always-on assertion           |
| FR11        | All scenarios (checker timing)     |
| FR12        | S10, S11, always-on assertion      |

---

## Exit Criteria

- All 17 scenarios pass with default parameters.
- All safety assertions pass across every scenario.
- All coverage targets hit at least once.
- No unresolved checker mismatches in logs.
- Design compiles cleanly on both Verilator and Icarus.
- Waveform file generated and opens correctly in GTKWave/Surfer.