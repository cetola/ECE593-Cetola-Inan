# File: Makefile
# Authors:
# Stephano Cetola
# Baris Inan

all: lib build run

lib:

	@echo "Running vlib"
	vlib work

build:

	@echo "Running vlog"
	vlog +cover toptb.sv

run:

	vsim -c toptb -do "coverage save -onexit report.ucdb; run -all;exit"
	vsim -c -cvgperinstance -viewcov report.ucdb -do "coverage report -output report.txt -srcfile=* -detail -option -cvg;exit"

debug:
	@echo "Running debug"
	vsim -c +DBG-INSTR toptb

clean:
	rm -rf  work transcript tmon.log report.*
