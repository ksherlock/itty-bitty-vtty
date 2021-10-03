SET80VID	equ $c00d
SETALTCHAR	equ $c00f
TXTSET		equ $c051
KEYMOD		equ $c025
KEYSTROBE	equ $c010
KBD		equ $c000
VGCINT		equ $c023
SCANINT		equ $c032


* modem port / printer port

SCCBREG		equ $c038
SCCAREG		equ $c039
SCCBDATA	equ $c03a
SCCADATA	equ $c03b

* Sound GLU
SGCONTROL	equ $c03c	; Sound GLU control register
SGDATA		equ $c03d	; Sound GLU data register
SGADDRL		equ $c03e	; Sound GLU address reg low
SGADDRH		equ $c03f	; Sound GLU address reg high


* interrupt vectors.  JMP ABSLONG.
IRQ1SEC		equ $e10054
IRQQTR		equ $e10038
IRQVBL		equ $e10030
IRQSND		equ $e1002c
