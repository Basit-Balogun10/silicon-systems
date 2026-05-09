ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SPRINT_DIRS := $(sort $(wildcard $(ROOT)src/sprint-*))
DEFAULT_SPRINT_DIR := $(firstword $(SPRINT_DIRS))
PROJECT ?=
SPRINT ?=
TARGET ?= help

.DEFAULT_GOAL := help

.PHONY: help list lint sim wave e2e clean cocotb sprint-% project-% %

define run_root_action
	@set -eu; \
	resolve_sprint_path() { \
		sprint_spec="$$1"; \
		case "$$sprint_spec" in \
			sprint-*) : ;; \
			[0-9][0-9]) sprint_spec="sprint-$$sprint_spec" ;; \
			*) sprint_spec="sprint-$$sprint_spec" ;; \
		esac; \
		find "$(ROOT)src" -maxdepth 1 -type d -name "$$sprint_spec" | sort | head -n 1; \
	}; \
	if [ -n "$(PROJECT)" ]; then \
		sprint_spec="$(SPRINT)"; \
		project_spec="$(PROJECT)"; \
		case "$$project_spec" in \
			[0-9][0-9]-[0-9][0-9]) \
				sprint_spec="sprint-$${project_spec%%-*}"; \
				project_spec="project-$${project_spec##*-}"; \
				;; \
			project-*) : ;; \
			[0-9][0-9]) project_spec="project-$$project_spec" ;; \
			*) project_spec="project-$$project_spec" ;; \
		esac; \
		if [ -z "$$sprint_spec" ]; then \
			if [ "$(words $(SPRINT_DIRS))" -eq 1 ]; then \
				sprint_path="$(DEFAULT_SPRINT_DIR)"; \
			else \
				echo "Set SPRINT=... when targeting PROJECT=$(PROJECT) from the repo root."; \
				exit 2; \
			fi; \
		else \
			sprint_path="$$(resolve_sprint_path "$$sprint_spec")"; \
		fi; \
		if [ -z "$$sprint_path" ]; then \
			echo "Could not resolve sprint for PROJECT=$(PROJECT)."; \
			exit 2; \
		fi; \
		$(MAKE) -C "$$sprint_path" $(1) PROJECT="$$project_spec"; \
	elif [ -n "$(SPRINT)" ]; then \
		sprint_path="$$(resolve_sprint_path "$(SPRINT)")"; \
		if [ -z "$$sprint_path" ]; then \
			echo "Could not resolve sprint $(SPRINT)."; \
			exit 2; \
		fi; \
		$(MAKE) -C "$$sprint_path" $(1); \
	else \
		for sprint_path in $(SPRINT_DIRS); do \
			$(MAKE) -C "$$sprint_path" $(1); \
		done; \
	fi
endef

help:
	@echo "Workspace targets:"
	@echo "  make lint                                           - run lint across every sprint"
	@echo "  make lint SPRINT=sprint-01                          - run one sprint"
	@echo "  make lint PROJECT=project-01                        - run one project when only one sprint exists"
	@echo "  make lint PROJECT=project-02                        - run Sprint 1 Project B by prefix"
	@echo "  make lint PROJECT=01-01                             - run one sprint+project shorthand"
	@echo "  make lint PROJECT=01-02                             - run Sprint 1 Project B shorthand"
	@echo "  make project-01 TARGET=sim SPRINT=sprint-01         - run a project by prefix"
	@echo "  make project-02 TARGET=sim SPRINT=sprint-01         - run Project B by prefix"
	@echo "  make sprint-01 TARGET=lint                          - run a sprint directly"
	@echo "  make 01-01 TARGET=sim                               - run sprint-01 / project-01 shorthand"
	@echo "  make 01-02 TARGET=sim                               - run sprint-01 / project-02 shorthand"
	@echo ""
	@echo "Flags and options are forwarded to nested make calls."
	@echo "Examples:"
	@echo "  make sim SPRINT=sprint-01 TOOL=iverilog"
	@echo "  make wave SPRINT=sprint-01 PROJECT=project-02 SIM_TOOL=verilator"
	@echo "  make e2e SPRINT=sprint-01 PROJECT=01-02 SIM_FLAGS='--trace-fst'"

list:
	@for sprint_path in $(SPRINT_DIRS); do \
		echo "$${sprint_path##*/}"; \
		find "$${sprint_path}" -maxdepth 1 -type d -name 'project-*' | sort; \
		done

lint:
	$(call run_root_action,lint)

sim:
	$(call run_root_action,sim)

wave:
	$(call run_root_action,wave)

e2e:
	$(call run_root_action,e2e)

clean:
	$(call run_root_action,clean)

cocotb:
	$(call run_root_action,cocotb)

sprint-%:
	$(MAKE) -C "$(ROOT)src/sprint-$*" $(TARGET) PROJECT="$(PROJECT)"

project-%:
	@set -eu; \
	resolve_sprint_path() { \
		sprint_spec="$$1"; \
		case "$$sprint_spec" in \
			sprint-*) : ;; \
			[0-9][0-9]) sprint_spec="sprint-$$sprint_spec" ;; \
			*) sprint_spec="sprint-$$sprint_spec" ;; \
		esac; \
		find "$(ROOT)src" -maxdepth 1 -type d -name "$$sprint_spec" | sort | head -n 1; \
	}; \
	project_spec="$(if $(PROJECT),$(PROJECT),$*)"; \
	case "$$project_spec" in \
		[0-9][0-9]-[0-9][0-9]) \
			sprint_spec="sprint-$${project_spec%%-*}"; \
			project_spec="project-$${project_spec##*-}"; \
			;; \
		project-*) : ;; \
		[0-9][0-9]) project_spec="project-$$project_spec" ;; \
		*) project_spec="project-$$project_spec" ;; \
	esac; \
	if [ -n "$(SPRINT)" ]; then \
		sprint_spec="$(SPRINT)"; \
	fi; \
	if [ -z "$$sprint_spec" ]; then \
		if [ "$(words $(SPRINT_DIRS))" -eq 1 ]; then \
			sprint_path="$(DEFAULT_SPRINT_DIR)"; \
		else \
			echo "Set SPRINT=... when targeting project-$* from the repo root."; \
			exit 2; \
		fi; \
	else \
		sprint_path="$$(resolve_sprint_path "$$sprint_spec")"; \
	fi; \
	if [ -z "$$sprint_path" ]; then \
		echo "Could not resolve sprint for project-$*."; \
		exit 2; \
	fi; \
	$(MAKE) -C "$$sprint_path" $(TARGET) PROJECT="$$project_spec"

%:
	@case "$@" in \
		[0-9][0-9]-[0-9][0-9]) \
			target_name="$@"; \
			sprint_num=$${target_name%%-*}; \
			project_num=$${target_name##*-}; \
			$(MAKE) project-$$project_num TARGET="$(TARGET)" PROJECT="$(if $(PROJECT),$(PROJECT),project-$$project_num)" SPRINT="sprint-$$sprint_num"; \
			;; \
		*) \
			echo "Unknown target '$@'. Use 'make help'."; \
			exit 2; \
			;; \
	esac