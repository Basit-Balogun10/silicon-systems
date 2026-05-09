PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME ?= Traffic Light Controller FSM
RTL ?= rtl/traffic_light_controller_fsm.sv
TB ?= tb/sv/tb_traffic_light_controller_fsm.sv
COCOTB_DIR ?= tb/cocotb

.DEFAULT_GOAL := help

.PHONY: help lint sim wave e2e clean cocotb

help:
	@echo "Project scaffold for $(PROJECT_NAME)"
	@echo ""
	@echo "Docs:"
	@echo "  docs/design-spec.md"
	@echo "  docs/verification-plan.md"
	@echo ""
	@echo "Scaffolded targets:"
	@echo "  make lint     - placeholder until RTL and TB are added"
	@echo "  make sim      - placeholder until RTL and TB are added"
	@echo "  make wave     - placeholder until waveform artifacts exist"
	@echo "  make e2e      - placeholder until implementation lands"
	@echo "  make cocotb   - placeholder until the Python testbench exists"
	@echo "  make clean    - remove any generated simulation artifacts"
	@echo ""
	@echo "Reference structure follows the counter project under project-01-parameterized-n-bit-counter."

lint:
	@echo "Scaffold only: add $(RTL) and $(TB) before running lint."

sim:
	@echo "Scaffold only: add $(RTL) and $(TB) before running simulation."

wave:
	@echo "Scaffold only: add waveform artifacts before opening them."

e2e:
	@echo "Scaffold only: add RTL, TB, and cocotb assets before running end-to-end checks."

cocotb:
	@echo "Scaffold only: add Python tests under $(COCOTB_DIR) before running cocotb."

clean:
	@echo "Nothing to clean in the scaffold yet."