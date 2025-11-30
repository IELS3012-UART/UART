GHDL   = ghdl
FLAGS  = --std=08
BUILD  = build

SRC = src/baud_gen.vhd tb/baud_gen_tb.vhd

TOP = baud_gen_tb

all: run

analyze:
	$(GHDL) -a $(FLAGS) --workdir=$(BUILD) $(SRC)

elab: analyze
	$(GHDL) -e $(FLAGS) --workdir=$(BUILD) $(TOP)

run: elab
	$(GHDL) -r $(FLAGS) --workdir=$(BUILD) $(TOP) --vcd=$(BUILD)/wave.vcd
	gtkwave $(BUILD)/wave.vcd &

clean:
	rm -rf $(BUILD)
	mkdir -p $(BUILD)
