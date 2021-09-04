
	ovr all

* binary linker
	lkv 0
	org $6000

	asm boot.S
	asm vt100.ctrl.S



	lnk boot.S
	pos ; reset


	pos EMU_SIZE
EMU_SIZE	ext 
EMU_BLOCKS	geq EMU_SIZE+511\512


	sav vt100.bin