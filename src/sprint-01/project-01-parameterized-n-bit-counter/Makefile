PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
RTL ?= rtl/counter.sv
TB_PKG ?= tb/sv/tb_pkg.sv
TB ?= tb/sv/tb_counter.sv
TOP ?= tb_counter
TOOL ?= verilator
SIM_TOOL ?= $(TOOL)
VERILATOR ?= verilator
IVERILOG ?= iverilog
BUILD_DIR ?= sim_build
LINT_FLAGS ?=
SIM_FLAGS ?=
WAVEFILE ?= sim/waveforms/counter.fst
WAVEFILE_VCD ?= sim/waveforms/counter.vcd
WAVE_VIEWER ?= code
VERILATOR_LINT_FLAGS ?= --lint-only --sv -Wall
VERILATOR_SIM_FLAGS ?= --binary --sv --trace-fst -Wall -j 0 --top $(TOP)
IVERILOG_LINT_FLAGS ?= -g2012 -Wall
IVERILOG_SIM_FLAGS ?= -g2012 -Wall
COCOTB_DIR ?= tb/cocotb

ifeq ($(SIM_TOOL),verilator)
LINT_CMD = $(VERILATOR) $(VERILATOR_LINT_FLAGS) $(LINT_FLAGS) $(RTL) $(TB_PKG) $(TB)
SIM_CMD = cd $(PROJECT_ROOT) && mkdir -p $(dir $(WAVEFILE)) && $(VERILATOR) $(VERILATOR_SIM_FLAGS) $(SIM_FLAGS) $(RTL) $(TB_PKG) $(TB) && ./obj_dir/V$(TOP) +verilator+seed+$(shell date +%s)
WAVE_TARGET := $(WAVEFILE)
else ifeq ($(SIM_TOOL),iverilog)
LINT_CMD = $(IVERILOG) $(IVERILOG_LINT_FLAGS) $(LINT_FLAGS) -t null $(RTL) $(TB_PKG) $(TB)
SIM_CMD = cd $(PROJECT_ROOT) && mkdir -p $(BUILD_DIR) $(dir $(WAVEFILE_VCD)) && $(IVERILOG) $(IVERILOG_SIM_FLAGS) $(SIM_FLAGS) -DWAVE_VCD -o $(BUILD_DIR)/$(TOP).vvp $(RTL) $(TB_PKG) $(TB) && vvp $(BUILD_DIR)/$(TOP).vvp +seed+$(shell date +%s)
WAVE_TARGET := $(WAVEFILE_VCD)
else
$(error Unsupported SIM_TOOL '$(SIM_TOOL)'. Use verilator or iverilog)
endif

.DEFAULT_GOAL := help

.PHONY: help lint sim wave e2e clean cocotb

help:
	@echo "Targets:"
	@echo "  make help     - show this help"
	@echo "  make lint     - syntax/lint check the RTL and SV TB"
	@echo "  make sim      - build and run the selected simulator"
	@echo "  make wave     - open the waveform in VS Code"
	@echo "  make e2e      - run lint, sim, then wave"
	@echo "  make cocotb   - cocotb entrypoint for $(COCOTB_DIR)"
	@echo "  make clean    - remove generated simulation artifacts"
	@echo ""
	@echo "Options:"
	@echo "  TOOL=verilator|iverilog      - select the simulator toolchain"
	@echo "  SIM_TOOL=verilator|iverilog  - alias for TOOL"
	@echo "  LINT_FLAGS=...               - extra flags appended to lint"
	@echo "  SIM_FLAGS=...                - extra flags appended to sim"
	@echo "  WAVE_VIEWER=code|...         - waveform viewer command"
	@echo "  COCOTB_DIR=tb/cocotb         - location of the Python test suite"
	@echo ""
	@echo "Examples:"
	@echo "  make lint"
	@echo "  make sim TOOL=iverilog"
	@echo "  make wave WAVE_VIEWER=code"
	@echo "  make e2e SIM_TOOL=verilator"
	@echo "  make cocotb"

lint:
	$(LINT_CMD)

sim:
	$(SIM_CMD)

wave:
	$(WAVE_VIEWER) $(WAVE_TARGET)

e2e: lint sim wave

cocotb:
	@echo "Run Cocotb tests from $(COCOTB_DIR)/reference_model.py and $(COCOTB_DIR)/test_counter.py"

clean:
	rm -rf obj_dir $(BUILD_DIR) sim/waveforms/*.fst sim/waveforms/*.vcd
