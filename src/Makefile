source=p2_tb.sv memory.sv regfile.sv mips.sv
iFlags=-g2005-sv
vFlags=-n
wFlags=-A
BENCH=SimpleAdd

.PHONY: run
run: $(BENCH)

# tb_$(BENCH)
.PHONY: $(BENCH)
$(BENCH): tb_$(BENCH).vvp
	vvp $(vFlags) $<

.PHONY: $(BENCH)_wave
$(BENCH)_wave: tb_$(BENCH).lx2
	gtkwave $(wFlags) $< &

tb_$(BENCH).vvp: $(source) $(BENCH).x
	iverilog $(iFlags) -s tb_$(BENCH) -o $@ $(source)

%.lx2: %.vvp
	vvp $(vFlags) $< -lxt2
	mv dump.lx2 $@

clean:
	rm -f *.vvp *.lx2 *.vcd
