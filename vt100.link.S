
	ovr all
* binary linker
	lkv 0
	org $6000

*	asm boot.S
*	asm vt100.ctrl.S
	asm vt100.main.S
	asm vt100.esc.S
	asm vt100.tabs.S
	asm vt100.vt52.S
	asm vt100.csi.S
	asm vt100.screen.S
	asm vt100.modem.S
	asm vt100.key.S


*	lnk boot.S
*	pos ; reset


*	pos EMU_SIZE
*EMU_SIZE	ext 
*EMU_BLOCKS	geq EMU_SIZE+511\512

	lnk vt100.main.L
	lnk vt100.esc.L
	lnk vt100.tabs.L
	lnk vt100.vt52.L
	lnk vt100.csi.L
	lnk vt100.screen.L
	lnk vt100.modem.L
	lnk vt100.key.L

	sav vt100.bin
