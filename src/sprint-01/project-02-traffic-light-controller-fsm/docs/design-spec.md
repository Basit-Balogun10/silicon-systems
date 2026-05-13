# Design Specification
## Project: Adaptive Traffic Light Controller FSM
### Sprint 1 — Project B

---

## What This Is

A synthesizable FSM that controls a single 4-way intersection with two roads:
North-South (NS) and East-West (EW). At any moment, one direction has green
and the other is implicitly red. The controller adapts how long each direction
holds green based on whether vehicles are waiting on the other side.

---

## The Four States

```
NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN → ...
```

There is no explicit RED state. When NS has green, EW lights are red by
output decode — not by a separate state. This simplifies the FSM without
losing any behaviour.

---

## Parameters

| Parameter         | Type             | Default | Purpose                                                    |
|-------------------|------------------|---------|------------------------------------------------------------|
| `MIN_GREEN`       | positive integer | 10      | Cycles a direction must hold green before any exit is allowed |
| `MAX_GREEN`       | positive integer | 30      | Cycles at which a sensor-triggered exit is allowed         |
| `EXTENSION`       | positive integer | 10      | Extra cycles granted if other direction has no waiting cars |
| `ABS_MAX_GREEN`   | positive integer | 50      | Hard ceiling — transition happens here regardless          |
| `YELLOW_CYCLES`   | positive integer | 5       | Fixed yellow duration — no sensor logic applies            |

Constraint: `MIN_GREEN < MAX_GREEN < ABS_MAX_GREEN`.
Constraint: `MAX_GREEN + EXTENSION <= ABS_MAX_GREEN`.

---

## Interface

| Signal          | Direction | Description                                              |
|-----------------|-----------|----------------------------------------------------------|
| `clk`           | input     | System clock. All state updates on rising edge.          |
| `reset_n`       | input     | Asynchronous active-low reset.                           |
| `ns_sensor`     | input     | High when a vehicle is waiting on the NS road.           |
| `ew_sensor`     | input     | High when a vehicle is waiting on the EW road.           |
| `ns_green`      | output    | High when NS direction has green.                        |
| `ns_yellow`     | output    | High when NS direction is in yellow.                     |
| `ns_red`        | output    | High when NS direction is red (EW has green or yellow).  |
| `ew_green`      | output    | High when EW direction has green.                        |
| `ew_yellow`     | output    | High when EW direction is in yellow.                     |
| `ew_red`        | output    | High when EW direction is red (NS has green or yellow).  |
| `conflict`      | output    | Safety flag. High if both directions show green at once. |

---

## Green Phase Timing Logic

This is the core adaptive behaviour. The same rules apply symmetrically
to NS_GREEN and EW_GREEN — just swap which sensor is "active side" and
which is "other side."

```
Phase timer starts at 0 on state entry.

timer < MIN_GREEN:
  → Stay. No exits allowed regardless of sensors.

MIN_GREEN <= timer < MAX_GREEN:
  → Stay, UNLESS other_sensor = 1 (cars waiting on the other side).
  → If other_sensor = 1: transition to yellow immediately.

timer == MAX_GREEN:
  → Check other_sensor.
  → If other_sensor = 0 (nobody waiting): grant EXTENSION, stay for
    up to EXTENSION more cycles.
  → If other_sensor = 1: transition to yellow now.

timer == ABS_MAX_GREEN:
  → Transition to yellow regardless. Hard cutoff. No further extension.
```

In plain English: serve at least the minimum, respond to waiting traffic
after the minimum, extend if the other side is empty, but never exceed
the absolute maximum.

---

## Yellow Phase Timing Logic

Yellow is fixed duration. No sensor logic applies.

```
timer < YELLOW_CYCLES: stay in yellow.
timer == YELLOW_CYCLES: transition to the next green phase.
```

NS_YELLOW → EW_GREEN.
EW_YELLOW → NS_GREEN.

---

## Conflict Monitor

The `conflict` output is a purely combinational safety check:

```
conflict = ns_green & ew_green
```

If both directions ever show green simultaneously, this flag fires
immediately — no clock edge required. In a real system, this output
would cut power to all lamps. In this project it is an observable
output for assertion checking.

---

## Output Decode

| State      | ns_green | ns_yellow | ns_red | ew_green | ew_yellow | ew_red |
|------------|----------|-----------|--------|----------|-----------|--------|
| NS_GREEN   | 1        | 0         | 0      | 0        | 0         | 1      |
| NS_YELLOW  | 0        | 1         | 0      | 0        | 0         | 1      |
| EW_GREEN   | 0        | 0         | 1      | 1        | 0         | 0      |
| EW_YELLOW  | 0        | 0         | 1      | 0        | 1         | 0      |

On reset: all outputs go to a safe state — ns_red and ew_red both high,
all other outputs low.

---

## Reset Behaviour

- Reset is asynchronous and active-low.
- On reset: state → NS_GREEN (initial state), phase timer → 0, conflict → 0.
- Reset dominates everything — no timer or sensor value can prevent it.

---

## Functional Requirements

| ID   | Requirement                                                                              |
|------|------------------------------------------------------------------------------------------|
| FR1  | Controller shall have clk, reset_n, ns_sensor, ew_sensor inputs.                        |
| FR2  | Reset shall be asynchronous, active-low, and return state to NS_GREEN immediately.       |
| FR3  | Controller shall cycle NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN only.     |
| FR4  | No green phase shall exit before MIN_GREEN cycles have elapsed.                          |
| FR5  | After MIN_GREEN, the active green shall exit early if the other direction sensor is high.|
| FR6  | At MAX_GREEN, if other sensor is low, grant one EXTENSION period.                        |
| FR7  | At ABS_MAX_GREEN, transition to yellow regardless of sensor state.                       |
| FR8  | Yellow duration shall be fixed at YELLOW_CYCLES. Sensors do not affect yellow.           |
| FR9  | ns_green and ew_green shall never be high simultaneously.                                |
| FR10 | conflict output shall go high immediately if FR9 is ever violated.                       |
| FR11 | All outputs shall be stable between clock edges except on asynchronous reset.            |
| FR12 | Output decode shall be a pure function of state — no transition logic in decode.         |

---

## Non-Goals

- No pedestrian crossing phases.
- No emergency vehicle preemption.
- No flashing yellow maintenance mode.
- No sensor debounce inside the controller.
- No sensor fault detection. Fault detection requires either a heartbeat
  protocol from the sensor hardware (which this RTL cannot generate or
  simulate) or a toggle watchdog (which cannot distinguish a stuck-high
  sensor from a real traffic jam). Both approaches require hardware
  assumptions outside the scope of this project.
- No inter-intersection coordination.
- No physical lamp driver circuitry.
- No display output (countdown timer display is a future extension).

---

## Architecture

```
clk, reset_n ──────────────────────┐
                                    ▼
ns_sensor ──────────────────► next-state logic ──► state register
ew_sensor ──────────────────►        ▲                    │
                                     │                    ▼
                                phase timer ◄──── state register
                                                          │
                                                          ▼
                                                   output decode
                                                          │
                         ┌────────────────────────────────┤
                         ▼          ▼          ▼          ▼
                      ns_green  ns_yellow  ew_green  ew_yellow
                         │                    │
                         └────────────────────┘
                                   │
                                   ▼
                               conflict
```

---

## Acceptance Criteria

- Reset returns the controller to NS_GREEN with timer cleared.
- No green phase exits before MIN_GREEN.
- Sensor-triggered early exit works correctly between MIN_GREEN and MAX_GREEN.
- Extension is granted when other sensor is low at MAX_GREEN.
- ABS_MAX_GREEN forces transition regardless of sensor state.
- Yellow always lasts exactly YELLOW_CYCLES.
- ns_green and ew_green are never simultaneously high.
- conflict asserts immediately if both greens are ever high.
- Design compiles cleanly and is structurally ready for synthesis.