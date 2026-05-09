# Project 02: Traffic Light Controller FSM

This folder is the working area for Sprint 01, Project B.

## Tree

```text
project-02-traffic-light-controller-fsm/
├── Makefile
├── README.md
├── docs/
│   ├── design-spec.md
│   └── verification-plan.md
├── rtl/
├── sim/
├── scripts/
└── tb/
    ├── cocotb/
    └── sv/
```

## Folder Roles

- `docs/` holds the authoritative contract and verification blueprint.
- `rtl/` will hold synthesizable SystemVerilog RTL.
- `tb/sv/` will hold SystemVerilog testbench assets and harness code.
- `tb/cocotb/` will hold Python verification helpers and tests.
- `sim/` will hold simulator outputs and waveform artifacts.
- `scripts/` will hold convenience scripts for local runs.

## Build Entry Point

The Makefile is the project entrypoint and is scaffolded to match the counter project's workflow shape. The implementation files are not added yet, so the build targets are currently staged for the next implementation step.

The design spec and verification plan in `docs/` are the source of truth for the project contract.
