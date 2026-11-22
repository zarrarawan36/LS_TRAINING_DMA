# -----------------------------------------------------------------------------
# J3 (sgdma_mm_rd) simulation Makefile  (PROVIDED)
# Spec reference : SPEC-12 Harness guide, section "Running simulations"
#
# Run every command from this sim/ directory.
#
#   make run                              smoke test, Verilator (builds if needed)
#   make run TEST=<test> SEED=<n>         any test, any seed  <- the one you use daily
#   make run TEST=<test> VERBOSITY=UVM_HIGH
#   make run TEST=<test> WAVES=1          also dumps waves.vcd (open with GTKWave)
#   make regress                          every line of regress.list
#   make SIM=vcs|questa|xcelium run ...   same on a commercial simulator
#   make COV=1 SIM=vcs run ...            with code coverage
#   make clean
#
# The build is redone automatically when a .sv/.svh/.f file changes.
# Your files are listed in my_tb.f. Your tests live in TEST_PKG (tb_top
# imports it so that +UVM_TESTNAME finds them).
# -----------------------------------------------------------------------------

SIM       ?= verilator
TEST      ?= j3_harness_smoke_test
TEST_PKG  ?= j3_test_pkg
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM
WAVES     ?= 0
COV       ?= 0
PLUSARGS  ?=

LOGDIR    := logs
BUILDDIR  := build/$(SIM)
STAMP     := $(BUILDDIR)/.built_$(TEST_PKG)_w$(WAVES)_c$(COV)
FILES     := -f rtl.f -f dv_lib.f -f my_tb.f -f harness.f
SOURCES   := $(shell find .. \( -name '*.sv' -o -name '*.svh' \) -not -path '*/build/*') rtl.f dv_lib.f my_tb.f harness.f
DEFS      := $(if $(TEST_PKG),+define+USER_TEST_PKG=$(TEST_PKG)) $(if $(filter 1,$(WAVES)),+define+DUMP_VCD)
RUNLOG    := $(LOGDIR)/$(TEST)_$(SEED).log
RUNARGS   := +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) $(PLUSARGS)

.PHONY: all build run regress clean help

all: run

help:
	@sed -n '2,22p' Makefile

# ---------------------------------------------------------------- Verilator --
# UVM library for Verilator: https://github.com/chipsalliance/uvm-verilator
UVM_HOME  ?= $(HOME)/.cache/sgdma_tools/uvm-verilator
VL_JOBS   ?= 4
VL_FLAGS  := --binary --timing --vpi -j $(VL_JOBS) -Wno-fatal -Wno-lint -Wno-style \
             --top-module tb_top -Mdir $(BUILDDIR) \
             $(if $(filter 1,$(WAVES)),--trace) $(if $(filter 1,$(COV)),--coverage)
UNAME     := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  # macOS has no <malloc.h>, which the UVM DPI code includes
  VL_FLAGS += -CFLAGS -I$(CURDIR)/build/macstub
endif

# ------------------------------------------------------------------- VCS -----
VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+r \
             -top tb_top -Mdir=$(BUILDDIR)/csrc -o $(BUILDDIR)/simv \
             $(if $(filter 1,$(COV)),-cm line+cond+fsm+tgl+branch)

# ---------------------------------------------------------------- Questa -----
QUESTA_VLOG := -sv -timescale 1ns/1ps -work $(BUILDDIR)/work $(if $(filter 1,$(COV)),+cover=bcefst)

# --------------------------------------------------------------- Xcelium -----
XRUN_FLAGS := -64bit -sv -uvm -uvmhome CDNS-1.2 -timescale 1ns/1ps -access +r \
              -top tb_top -xmlibdirname $(BUILDDIR)/xcelium.d \
              $(if $(filter 1,$(COV)),-coverage all -covoverwrite)

build: $(STAMP)

$(STAMP): $(SOURCES)
	@mkdir -p $(LOGDIR) $(BUILDDIR)
	@rm -f $(BUILDDIR)/.built_*
	@echo "=== building for $(SIM) (TEST_PKG=$(TEST_PKG)) - log: $(LOGDIR)/build.log"
ifeq ($(SIM),verilator)
	@mkdir -p build/macstub && echo '#include <stdlib.h>' > build/macstub/malloc.h
	@test -f $(UVM_HOME)/src/uvm_pkg.sv || (echo "ERROR: UVM not found at UVM_HOME=$(UVM_HOME). Set UVM_HOME=<path to uvm-verilator>." && false)
	@verilator $(VL_FLAGS) +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv \
	  $(UVM_HOME)/src/dpi/uvm_dpi.cc $(DEFS) $(FILES) > $(LOGDIR)/build.log 2>&1 || true
	@test -x $(BUILDDIR)/Vtb_top || (grep -E "%Error" $(LOGDIR)/build.log | head -20; \
	  echo "BUILD FAILED - first errors above, full log: $(LOGDIR)/build.log"; false)
else ifeq ($(SIM),vcs)
	vcs $(VCS_FLAGS) $(DEFS) $(FILES) -l $(LOGDIR)/build.log
else ifeq ($(SIM),questa)
	vlib $(BUILDDIR)/work
	vlog $(QUESTA_VLOG) $(DEFS) $(FILES) -l $(LOGDIR)/build.log
else ifeq ($(SIM),xcelium)
	xrun -elaborate $(XRUN_FLAGS) $(DEFS) $(FILES) -l $(LOGDIR)/build.log
else
	$(error unknown SIM=$(SIM), use verilator | vcs | questa | xcelium)
endif
	@touch $@
	@echo "=== build OK"

run: $(STAMP)
	@mkdir -p $(LOGDIR)
	@echo "=== running TEST=$(TEST) SEED=$(SEED) - log: $(RUNLOG)"
ifeq ($(SIM),verilator)
	@$(BUILDDIR)/Vtb_top $(RUNARGS) +verilator+seed+$(SEED) > $(RUNLOG) 2>&1 || true
else ifeq ($(SIM),vcs)
	-$(BUILDDIR)/simv $(RUNARGS) +ntb_random_seed=$(SEED) $(if $(filter 1,$(COV)),-cm line+cond+fsm+tgl+branch -cm_name $(TEST)_$(SEED)) -l $(RUNLOG)
else ifeq ($(SIM),questa)
	-vsim -c -lib $(BUILDDIR)/work tb_top $(RUNARGS) -sv_seed $(SEED) $(if $(filter 1,$(COV)),-coverage) \
	  -do "$(if $(filter 1,$(COV)),coverage save -onexit $(LOGDIR)/$(TEST)_$(SEED).ucdb;) run -all; quit -f" -l $(RUNLOG)
else ifeq ($(SIM),xcelium)
	-xrun -R $(XRUN_FLAGS) $(RUNARGS) -svseed $(SEED) -l $(RUNLOG)
endif
	@grep -E "UVM_(ERROR|FATAL) .*@|RESULT|SMOKE TEST|not found|Requested test" $(RUNLOG) | head -15 || true
	@grep -q "UVM_ERROR :    0" $(RUNLOG) && grep -q "UVM_FATAL :    0" $(RUNLOG) \
	  && echo "RESULT: $(TEST) seed=$(SEED) PASSED" \
	  || (echo "RESULT: $(TEST) seed=$(SEED) FAILED - read $(RUNLOG)" && false)

# regress.list: one line per run, "<test> <seed>", '#' starts a comment
regress: $(STAMP)
	@pass=0; fail=0; \
	while read t s; do \
	  case "$$t" in ''|\#*) continue;; esac; \
	  if $(MAKE) --no-print-directory run TEST=$$t SEED=$$s >/dev/null 2>&1; \
	  then pass=$$((pass+1)); echo "PASS $$t seed=$$s"; \
	  else fail=$$((fail+1)); echo "FAIL $$t seed=$$s  (logs/$${t}_$$s.log)"; fi; \
	done < regress.list; \
	echo "regression: $$pass passed, $$fail failed"; test $$fail -eq 0

clean:
	rm -rf build $(LOGDIR) waves.vcd coverage.dat *.ucdb
