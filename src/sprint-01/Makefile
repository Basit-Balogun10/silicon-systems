SPRINT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_DIRS := $(sort $(wildcard $(SPRINT_ROOT)project-*))
PROJECT ?=
TARGET ?= help

.DEFAULT_GOAL := help

.PHONY: help list lint sim wave e2e clean cocotb project-% %

define run_sprint_action
	@set -eu; \
	resolve_project_path() { \
		project_spec="$$1"; \
		case "$$project_spec" in \
			project-*) : ;; \
			[0-9][0-9]-[0-9][0-9]) project_spec="project-$${project_spec##*-}" ;; \
			[0-9][0-9]) project_spec="project-$$project_spec" ;; \
			*) project_spec="project-$$project_spec" ;; \
		esac; \
		find "$(SPRINT_ROOT)" -maxdepth 1 -type d -name "$$project_spec*" | sort | head -n 1; \
	}; \
	if [ -n "$(PROJECT)" ]; then \
		project_path="$$(resolve_project_path "$(PROJECT)")"; \
		if [ -z "$$project_path" ]; then \
			echo "Could not resolve project $(PROJECT)."; \
			exit 2; \
		fi; \
		$(MAKE) -C "$$project_path" $(1); \
	else \
		for project_dir in $(PROJECT_DIRS); do \
			$(MAKE) -C "$$project_dir" $(1); \
		done; \
	fi
endef

help:
	@set -eu; \
	resolve_project_path() { \
		project_spec="$$1"; \
		case "$$project_spec" in \
			project-*) : ;; \
			[0-9][0-9]-[0-9][0-9]) project_spec="project-$${project_spec##*-}" ;; \
			[0-9][0-9]) project_spec="project-$$project_spec" ;; \
			*) project_spec="project-$$project_spec" ;; \
		esac; \
		find "$(SPRINT_ROOT)" -maxdepth 1 -type d -name "$$project_spec*" | sort | head -n 1; \
	}; \
	if [ -n "$(PROJECT)" ]; then \
		project_path="$$(resolve_project_path "$(PROJECT)")"; \
		if [ -z "$$project_path" ]; then \
			echo "Could not resolve project $(PROJECT)."; \
			exit 2; \
		fi; \
		$(MAKE) -C "$$project_path" help; \
	else \
		echo "Sprint workspace targets:"; \
		echo "  make lint                     - run lint across all projects in this sprint"; \
		echo "  make lint PROJECT=project-01  - run one project by prefix"; \
		echo "  make lint PROJECT=project-02  - run Project B by prefix"; \
		echo "  make lint PROJECT=01          - run one project shorthand"; \
		echo "  make project-01 TARGET=sim    - dispatch one project from this sprint"; \
		echo "  make project-02 TARGET=sim    - dispatch Project B from this sprint"; \
		echo "  make 01 TARGET=sim            - single-project shorthand within this sprint"; \
		echo "  make 02 TARGET=sim            - single-project shorthand for Project B"; \
		echo ""; \
		echo "Flags and options are forwarded to nested make calls."; \
		echo "Examples:"; \
		echo "  make sim TOOL=iverilog"; \
		echo "  make e2e PROJECT=project-02 SIM_FLAGS='--trace-fst'"; \
		echo ""; \
		echo "Available projects: $(notdir $(PROJECT_DIRS))"; \
	fi

list:
	@printf '%s\n' $(notdir $(PROJECT_DIRS))

lint:
	$(call run_sprint_action,lint)

sim:
	$(call run_sprint_action,sim)

wave:
	$(call run_sprint_action,wave)

e2e:
	$(call run_sprint_action,e2e)

clean:
	$(call run_sprint_action,clean)

cocotb:
	$(call run_sprint_action,cocotb)

project-%:
	$(MAKE) $(TARGET) PROJECT="$(if $(PROJECT),$(PROJECT),$*)"

%:
	@case "$@" in \
		[0-9][0-9]) \
			$(MAKE) $(TARGET) PROJECT="$(if $(PROJECT),$(PROJECT),$@)"; \
			;; \
		*) \
			echo "Unknown target '$@'. Use 'make help'."; \
			exit 2; \
			;; \
	esac