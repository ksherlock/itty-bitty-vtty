
	ovr all
* binary linker
	lkv 0
	org $2000

	asm vt100.main.S
	asm vt100.esc.S
	asm vt100.tabs.S
	asm vt100.vt52.S
	asm vt100.csi.S
	asm vt100.screen.S
	asm vt100.modem.S
	asm vt100.key.S
	asm vt100.beep.S
	asm vt100.cda.S

	lnk vt100.main.L
	lnk vt100.esc.L
	lnk vt100.tabs.L
	lnk vt100.vt52.L
	lnk vt100.csi.L
	lnk vt100.screen.L
	lnk vt100.modem.L
	lnk vt100.key.L
	lnk vt100.beep.L
	lnk vt100.cda.L

	typ $ff
	sav vt100.system
