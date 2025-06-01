        LIST    p=PIC16C84

RTTC	equ	1h
PC	equ	2h
STATUS	equ	3h
FSR	equ	4h

Port_A	equ	5h
Port_B	equ	6h

CARRY	equ	0h
C	equ	0h
DCARRY	equ	1h
DC	equ	1h
Z_bit	equ	2h
Z	equ	2h
P_DOWN	equ	3h
PD	equ	3h
T_OUT	equ	4h
TO	equ	4h
PA0	equ	5h
PA1	equ	6h
PA2	equ	7h

F	equ	0h
W	equ	1h

LSB	equ	0h
MSB	equ	7h

TRUE	equ	1h
YES	equ	1h
FALSE	equ	0h
NO	equ	0h

X_flag	equ	PA0
R_flag	equ	PA1

DX	equ	0
DR	equ	1

BAUD_1	equ	.34
BAUD_2	equ	.33
BAUD_3	equ	.16
BAUD_4	equ	.42
BAUD_X	equ	.31
BAUD_Y	equ	.32

rp0     equ     5

	ORG	08h

RcvReg	RES	1
XmtReg	RES	1
Count	RES	1
DlyCnt	RES	1

	ORG	0

        bsf     STATUS,rp0
	movlw	0eh
	movwf	Port_B
	bcf	STATUS,rp0
	bsf	Port_B,DR
	goto	Talk


Talk	clrf	RcvReg
	btfsc	Port_B,DR
	goto	User
	call	Delay4

Rcvr	movlw	8
	movwf	Count
R_next	bcf	STATUS,C
	rrf	RcvReg,F
	btfsc	Port_B,DR
	bsf	RcvReg,MSB
	call	DelayY
	decfsz	Count,F
	goto	R_next

R_over	movf	RcvReg,W
	movwf	XmtReg

Xmtr	movlw	8
	movwf	Count
	bcf	Port_B,DX
	call	Delay1
X_next	bcf	STATUS,C
	rrf	XmtReg,F
	btfsc	STATUS,C
	bsf	Port_B,DX
	btfss	STATUS,C
	bcf	Port_B,DX
	call	DelayX
	decfsz	Count,F
	goto	X_next
	bsf	Port_B,DX
	call	Delay1
	goto	Talk

DelayY	movlw	BAUD_Y
	goto	save
DelayX	movlw	BAUD_X
	goto	save
Delay4	movlw	BAUD_4
	goto	save
Delay1	movlw	BAUD_1
	goto	save
Delay2	movlw	BAUD_2
save	movwf	DlyCnt
redo_1	decfsz	DlyCnt,F
	goto	redo_1
	retlw	0

User	movlw	BAUD_3
	movwf	DlyCnt
redo_2	decfsz	DlyCnt,F
	goto	redo_2
	goto	Talk

	end
