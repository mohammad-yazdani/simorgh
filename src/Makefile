source=p2_tb.sv memory.sv regfile.sv mips.sv
iFlags=-g2005-sv
vFlags=-n
wFlags=-A

.PHONY: run
run: SimpleAdd

# tb_SimpleAdd
.PHONY: SimpleAdd
SimpleAdd: tb_SimpleAdd.vvp
	vvp $(vFlags) $<

.PHONY: SimpleAdd_wave
SimpleAdd_wave: tb_SimpleAdd.lx2
	gtkwave $(wFlags) $< &

tb_SimpleAdd.vvp: $(source) SimpleAdd.x
	iverilog $(iFlags) -s tb_SimpleAdd -o $@ $(source)

%.lx2: %.vvp
	vvp $(vFlags) $< -lxt2
	mv dump.lx2 $@

clean:
	rm -f *.vvp *.lx2 *.vcd
