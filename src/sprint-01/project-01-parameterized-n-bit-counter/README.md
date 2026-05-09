# Project 01: Parameterized N-Bit Counter

This folder is the working area for the counter project.

## Tree

```text
project-01-parameterized-n-bit-counter/
├── Makefile
├── README.md
├── docs/
│   ├── design-spec.md
│   └── verification-plan.md
├── rtl/
│   └── counter.sv
├── sim/
├── scripts/
└── tb/
    ├── cocotb/
    │   ├── __init__.py
    │   ├── conftest.py
    │   ├── reference_model.py
    │   └── test_counter.py
    └── sv/
        └── tb_counter.sv
```

## Folder Roles

- `rtl/` holds synthesizable SystemVerilog RTL only.
- `tb/cocotb/` holds Python-based verification.
- `tb/sv/` holds any future SystemVerilog testbench assets.
- `sim/` holds simulator-facing build/support files.
- `scripts/` holds convenience scripts for running checks.

## Build Entry Point

The Makefile is the project entrypoint. It exposes `help`, `lint`, `sim`, `wave`, `e2e`, `cocotb`, and `clean`, and defaults to Verilator unless `TOOL=iverilog` or `SIM_TOOL=iverilog` is supplied.

The cocotb suite lives in `tb/cocotb/` and uses a small reference model to compare the DUT count against expected behavior.
