
	ovr all
* binary linker
	lkv 0
	org $6000

*	asm boot.S
*	asm vt100.ctrl.S
	asm vt100.esc.S
	asm vt100.tabs.S
	asm vt100.vt52.S
	asm vt100.csi.S
	asm vt100.screen.S


*	lnk boot.S
*	pos ; reset


*	pos EMU_SIZE
*EMU_SIZE	ext 
*EMU_BLOCKS	geq EMU_SIZE+511\512


*	sav vt100.bin