# Verification Plan
## Project: Parameterized N-bit Up/Down Counter
### Sprint 1 — Project A

---

## Scope

Simulation-based verification of the up/down counter RTL covering:
synchronous increment and decrement, hold behaviour, wrap in both
directions, reset priority, and parameter boundary conditions.
Verification uses a SystemVerilog testbench for harness/smoke tests
and CocoTB for directed and randomized scenarios.

---

## Environment

- **Default simulator:** Verilator
- **Alternate simulator:** Icarus Verilog (portability check)
- **SV testbench:** `tb/sv/tb_counter.sv` + `tb/sv/tb_pkg.sv` — harness,
  smoke tests, and shared utilities
- **CocoTB testbench:** `tb/cocotb/test_counter.py` — directed, boundary,
  and randomized tests with Python reference model
- **Waveforms:** FST (Verilator `--trace-fst`) / VCD (Icarus `-DWAVE_VCD`)
- **Sampling:** Rising edge of `clk`
- **Reset:** Asynchronous, active-low

---

## Verification Strategy

Both the SV testbench and CocoTB run all scenarios S01–S15. The
randomized scenarios S16–S17 are CocoTB only.

**SV testbench** runs first — if it fails, CocoTB does not run.
Proves the DUT is alive and the harness is wired correctly.

**CocoTB** runs after SV passes. Uses the Python reference model as
oracle, handles randomization, and exercises WIDTH boundary cases via
pytest parametrize.

| Layer        | Owns                                                              |
|--------------|-------------------------------------------------------------------|
| SV           | Clock gen, reset sequencing, waveform setup, seed init            |
| SV           | `tb_pkg` utilities: `wait_cycles`, `check_count`, `setup`, `teardown` |
| SV           | S01–S15: all scenarios written as tasks                           |
| CocoTB       | S01–S15: same scenarios written as `@cocotb.test()` coroutines    |
| CocoTB only  | S16–S17: randomized tests with Python reference model             |

---

## Reference Model

The reference model is a plain Python class that mirrors the RTL exactly.
You will implement this yourself in `tb/cocotb/reference_model.py`.

**Behavioural contract — what the model must do:**

- On instantiation: accept `width` as a parameter, initialise count to 0.
- On reset: set count to 0 immediately.
- On each rising edge where reset is deasserted: apply the same
  increment/decrement/hold/wrap rules as the RTL based on `enable`
  and `up_down` inputs.
- Expose a method that returns the current expected count value.
- Wrap behaviour must match the RTL exactly — natural unsigned arithmetic
  modulo 2^WIDTH in both directions.

**Usage contract:**
- Call reset immediately when `reset_n` falls — before any clock edge.
- Call the step method after each rising edge where `reset_n` is high.
- Compare the expected value against `dut.count.value` after every edge.
- The model is the ground truth. If DUT and model diverge, the RTL is wrong.

---

## Scenario Matrix

| ID  | Scenario                        | Type       | Testbench    | Pass Condition                                                                |
|-----|---------------------------------|------------|--------------|-------------------------------------------------------------------------------|
| S01 | Reset from power-on             | Smoke      | SV + CocoTB  | count = 0 immediately on reset_n falling. enable and up_down irrelevant.      |
| S02 | Hold — up direction selected    | Smoke      | SV + CocoTB  | enable=0, up_down=1 → count unchanged across multiple rising edges.           |
| S03 | Hold — down direction selected  | Smoke      | SV + CocoTB  | enable=0, up_down=0 → count unchanged across multiple rising edges.           |
| S04 | Increment                       | Smoke      | SV + CocoTB  | enable=1, up_down=1 → count increases by 1 each rising edge.                 |
| S05 | Decrement                       | Smoke      | SV + CocoTB  | enable=1, up_down=0 → count decreases by 1 each rising edge.                 |
| S06 | Wrap up                         | Directed   | SV + CocoTB  | Count reaches max (2^WIDTH-1), next edge with up_down=1 → count = 0.         |
| S07 | Wrap down                       | Directed   | SV + CocoTB  | Count is 0, next edge with up_down=0 → count = 2^WIDTH-1.                    |
| S08 | Reset priority over enable      | Directed   | SV + CocoTB  | reset_n asserted while enable=1 → count = 0 immediately, ignores enable.      |
| S09 | Reset priority over up_down     | Directed   | SV + CocoTB  | reset_n asserted while enable=1, up_down=1 → count = 0, no increment occurs. |
| S10 | Direction change mid-run        | Directed   | SV + CocoTB  | Switch up_down mid-sequence → count reverses direction from next edge onward. |
| S11 | Reset mid-count, then resume    | Directed   | SV + CocoTB  | Reset then release → count resumes from 0, direction and enable preserved.    |
| S12 | WIDTH=1 counting up             | Boundary   | SV + CocoTB  | count toggles 0→1→0→1 each enabled up edge. No other values appear.          |
| S13 | WIDTH=1 counting down           | Boundary   | SV + CocoTB  | count toggles 0→1→0→1 each enabled down edge (same toggle, opposite intent). |
| S14 | WIDTH=1 wrap up                 | Boundary   | SV + CocoTB  | From 1, one up step → 0. From 0, one up step → 1.                            |
| S15 | WIDTH=1 wrap down               | Boundary   | SV + CocoTB  | From 0, one down step → 1. From 1, one down step → 0.                        |
| S16 | Randomized up/down sequence     | Randomized | CocoTB only  | Random enable, up_down, and reset_n for 10,000+ cycles. DUT matches model.   |
| S17 | Long-run up then down           | Randomized | CocoTB only  | Count up for 3× full cycles, then down for 3× full cycles. DUT matches model.|

---

## Randomized Test Detail

**S16 — what "random" means precisely:**

Each cycle, independently randomize:
- `enable` — Bernoulli(0.7) biased high (counter is usually enabled)
- `up_down` — Bernoulli(0.5) equal probability each direction
- `reset_n` — Bernoulli(0.05) rare reset events (5% chance per cycle)

The low reset probability keeps the test from spending most of its time
in reset, which would reduce directional coverage. The bias toward
`enable=1` ensures the counter actually counts rather than holding most
of the time.

After each rising edge, compare `dut.count.value` against `model.expected()`.
Any mismatch is an immediate failure with full state logged.

**Seed handling:**
- Pass seed via plusarg: `+verilator+seed+$(date +%s)`
- Log the seed at test start so any failure can be reproduced exactly.
- If a failure occurs, re-run with the logged seed to reproduce it.

---

## Safety Assertions (Always On)

**SV testbench** — run via `always @(posedge clk)` background monitor:

```systemverilog
// Reset dominance
always @(negedge reset_n)
    assert (count == '0) else $error("Reset failed: count=%0d", count);

// Hold: count unchanged when enable is low
always @(posedge clk) begin
    if (reset_n && !enable)
        assert (count == $past(count))
        else $error("Hold violated: count changed while enable=0");
end
```

**CocoTB** — checked after every rising edge in the checker coroutine:

```python
# count stays within range
assert 0 <= dut.count.value <= (1 << WIDTH) - 1

# hold: count unchanged when enable is low
if not enable and not reset_asserted:
    assert dut.count.value == count_before_edge

# reset dominance: count is 0 immediately after reset_n falls
if reset_just_asserted:
    assert dut.count.value == 0
```

---

## Checker Hooks

- Sample `enable`, `up_down`, and `reset_n` **before** the rising edge.
- Check `count` **after** the rising edge, aligned with register update.
- Check reset output **immediately** when `reset_n` falls — no clock
  edge needed.
- On any mismatch log: cycle number, pre-edge count, expected count,
  actual count, enable, up_down, reset_n. This is enough to triage
  any failure without opening the waveform.

---

## Pass/Fail Rules

- A scenario passes only when every check within it passes.
- Any mismatch between DUT count and model expected count is a failure.
- Any count value outside `[0, 2^WIDTH-1]` is a failure.
- Any hold violation (count changed when enable was low) is a failure.
- Any reset violation (count nonzero when reset_n was asserted) is a failure.
- First failure log must identify which rule was violated: reset, hold,
  increment, decrement, or wrap.

---

## Coverage

### Code Coverage (Tool — Verilator)

Measures which RTL lines, branches, and conditions were exercised.
No additional code needed — enabled by a compile flag.

```makefile
# Add to VERILATOR_SIM_FLAGS
--coverage
```

Verilator generates `coverage.dat` which you view with:

```bash
verilator_coverage --annotate coverage_annotated/ coverage.dat
```

**Targets:**
- 100% line coverage of `counter.sv`
- 100% branch coverage — both arms of every `if` hit
- All four conditions in the always_ff block hit:
  reset path, hold path, increment path, decrement path

---

### Functional Coverage (Written — SV covergroup)

Measures whether meaningful scenarios were actually exercised.
Add to `tb_counter.sv` or a dedicated `tb_coverage.sv` file.

```systemverilog
covergroup cg_counter @(posedge clk);

    // Direction
    cp_up_down: coverpoint up_down {
        bins counting_up   = {1};
        bins counting_down = {0};
    }

    // Enable
    cp_enable: coverpoint enable {
        bins enabled  = {1};
        bins disabled = {0};
    }

    // Direction × enable cross
    cx_dir_en: cross cp_up_down, cp_enable;

    // Count value boundaries
    cp_count_boundary: coverpoint count {
        bins zero    = {0};
        bins max_val = {{WIDTH{1'b1}}};
        bins mid     = {(1 << (WIDTH-1))};
        bins others  = default;
    }

    // Wrap events
    cp_wrap_up:   coverpoint (count == '1 && enable && up_down);
    cp_wrap_down: coverpoint (count == '0 && enable && !up_down);

    // Reset events
    cp_reset_while_enabled: coverpoint (!reset_n && enable);

endgroup
```

**Targets — all bins must be hit at least once:**
- `counting_up` and `counting_down` both hit
- `enabled` and `disabled` both hit
- All four cross combinations: up×enabled, up×disabled,
  down×enabled, down×disabled
- `zero` and `max_val` count values observed
- Wrap up event (count=max, enable=1, up_down=1) observed
- Wrap down event (count=0, enable=1, up_down=0) observed
- Reset while enabled observed

---

### Functional Coverage (Written — CocoTB)

CocoTB has no native covergroup syntax. Track coverage manually
using a coverage dict that you populate during tests, then assert
completeness at the end of S16 (randomized run).

You will implement this yourself in `tb/cocotb/test_counter.py`.

**Required bins to track:**
- Wrap up observed
- Wrap down observed
- Reset while counting up observed
- Reset while counting down observed
- Direction change while counting observed
- Hold with up_down=1 observed
- Hold with up_down=0 observed
- COUNT=0 observed
- COUNT=max observed

Assert all bins are non-zero at the end of the randomized test.
If any bin is zero, the test fails with a coverage report showing
which scenario was never hit.

---

### Assertion Coverage (Automatic — Verilator)

SVA assertions in `tb_counter.sv` are tracked automatically.
Verilator reports which assertions fired and how many times.

**Required assertions to add to testbench:**

```systemverilog
// Reset dominance — fires on every negedge reset_n
property p_reset_clears;
    @(negedge reset_n) ##1 (count == '0);
endproperty
assert property(p_reset_clears);

// Hold — count must not change when enable is low
property p_hold;
    @(posedge clk) disable iff (!reset_n)
    (!enable) |=> (count == $past(count));
endproperty
assert property(p_hold);

// No count change on same edge as reset assertion
property p_reset_priority;
    @(posedge clk)
    (!reset_n) |-> (count == '0);
endproperty
assert property(p_reset_priority);
```

**Targets:**
- `p_reset_clears` triggered at least once
- `p_hold` triggered at least 10 consecutive cycles
- `p_reset_priority` triggered at least once with enable=1

---

## Traceability

| Requirement | Scenarios                          |
|-------------|------------------------------------|
| FR1         | All scenarios (interface check)    |
| FR2         | S01, S08, S09, S11                 |
| FR3         | S02, S03, S16                      |
| FR4         | S12, S13, S14, S15                 |
| FR5         | S04, S06, S17                      |
| FR6         | S05, S07, S17                      |
| FR7         | S06, S14                           |
| FR8         | S07, S15                           |
| FR9         | S08, S09, S16                      |

---

## Exit Criteria

- SV testbench: S01–S15 pass with default WIDTH=4.
- SV testbench: S01–S15 pass with WIDTH=1.
- CocoTB: S01–S15 pass with default WIDTH=4.
- CocoTB: S01–S15 pass with WIDTH=1.
- CocoTB: S16–S17 pass with default WIDTH=4.
- All SVA assertions pass and fire at least the required number of times.
- Verilator code coverage: 100% line and branch coverage on `counter.sv`.
- SV functional coverage: all covergroup bins hit at least once.
- CocoTB functional coverage: all manual coverage bins non-zero after S16.
- No unresolved checker mismatches in logs from either testbench.
- Design compiles cleanly on both Verilator and Icarus.
- Waveform file generated and opens correctly in GTKWave/Surfer.