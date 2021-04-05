
* binary link
	lkv 0
	org $0800

	ovr all
*	if boot.S
	asm boot.S

*	if vt52.S
	asm vt52.S


	lnk boot.L
	lnk vt52.L

	pos eof
	sav vt52.bin
	ent

	end
