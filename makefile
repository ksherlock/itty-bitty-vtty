

scc.po: scc.bin
	dd bs=1024 count=800 if=/dev/zero of=scc.po
	dd bs=512 if=scc.bin of=scc.po conv=notrunc

modem.po: modem.bin
	dd bs=1024 count=800 if=/dev/zero of=modem.po
	dd bs=512 if=modem.bin of=modem.po conv=notrunc

vt52.po: vt52.bin
	dd bs=1024 count=800 if=/dev/zero of=vt52.po
	dd bs=512 if=vt52.bin of=vt52.po conv=notrunc

vt52.bin: vt52.S boot.S link.S
	iix qlink link.S


scc.bin: scc.s
	iix qasm scc.s

modem.bin: modem.s
	iix qasm modem.s

