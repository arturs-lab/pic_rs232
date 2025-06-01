        LIST    p=PIC16C84

; Data flow control codes:
; Game Boy controlls all data flow between GB, RS232C port, keyboard
; and infrared interface. No data is transmitted to GB unless command
; to do so is received from GB. Data is, however received and transmitted
; through RS232 keyboard and IR interfaces. After received data is placed
; in the corresponding buffer (8 bytes) it must be read by GB. If data fills
; entire buffer and still is not read, no further data is received.
; To initiate transaction between GB and interface GB sends Command byte.
; Interface responds with a Status byte.
; Command byte must end with zero. Status byte must start with zero.
; Commands:
; 0000 0xxx put xxx bytes in RS232 buffer and transmit
; 0000 1xxx get next xxx bytes from RS232 receive buffer
; 0001 0xxx put xxx bytes in IR buffer and transmit
; 0001 1xxx get next xxx bytes from IR receive buffer
; 0010 0xxx get next xxx keystrokes from keyboard
; 0011 0000 send status byte
; 0011 0001 send number of bytes in RS232 xmit and receive buffers
; 0011 0010 send number of bytes in IR xmit and receive buffers
; 0011 0011 send number of bytes in keyboard buffer

IND0    equ     0h
RTTC    equ     1h
PC      equ     2h
STATUS  equ     3h
FSR     equ     4h

Port_A  equ     5h
Port_B  equ     6h

C       equ     0h
DC      equ     1h
Z       equ     2h
PD      equ     3h
TO      equ     4h
PA0     equ     5h
PA1     equ     6h
PA2     equ     7h

F       equ     0h
W       equ     1h

LSB     equ     0h
MSB     equ     7h

TRUE    equ     1h
YES     equ     1h
FALSE   equ     0h
NO      equ     0h

X_flag  equ     PA0
R_flag  equ     PA1

DX      equ     0
DR      equ     1
RTS     equ     2
CTS     equ     3

DI      equ     0
DO      equ     1
CK      equ     2

BAUD_1  equ     .34
BAUD_2  equ     .33
BAUD_3  equ     .16
BAUD_4  equ     .42
BAUD_X  equ     .31
BAUD_Y  equ     .32

rp0     equ     5

        ORG     08h

;RcvReg  RES     1
;XmtReg  RES     1
Count   RES     1
;DlyCnt  RES     1
Ptr1    RES     1       ; GB -> PC data buffer pointer
Cntr1   RES     1       ; data counter
Ptr2    RES     1       ; PC -> GB data buffer pointer
Cntr2   RES     1       ; data counter
Tmp     RES     1       ; temporary data register

        ORG     0

        bsf     STATUS,rp0      ; select register bank B
        movlw   0fah            ; setup RB0 and RB2 out, rest in
        movwf   Port_B
        movlw   0eh             ; setup RA0 out, rest in
        movwf   Port_A
        movlw   01h             ; prescaller = 4, RTTC increment on internal clock
        movwf   RTTC
        bcf     STATUS,rp0      ; select register bank A
        bsf     Port_B,DR       ; Set DX high
        bcf     Port_B,RTS      ; but for now keep RTS low
        bsf     Port_A,DI       ; and make sure that Nintendo Data In line is high
        movlw   10h             ; setup pointer for GB -> PC data buffer
        movwf   Ptr1
        movlw   18h             ; and for PC -> GB data buffer
        movwf   Ptr2
        clrf    Cntr1           ; Reset data counters
        clrf    Cntr2

main    btfss   Port_A,CK       ; wait for a clock pulse from Game Boy
        goto    GBrcv           ; clock pulse! go read byte
        btfsc   Port_B,CTS      ; see if PC wants to send something
        goto    main            ; no, continue loop
        bcf     Port_B,RTS      ; yes, say "ready" to PC
        goto    PCrcv           ; and receive it

; receive data from GB, send to PC
GBRcv   call    DelayA          ; call 1/2 bit delay
        movlw   80h
        movwf   Tmp             ; Prepare temporary register
GBRcv1  bcf     STATUS,C
        rrf     Tmp,F
        btfsc   Port_A,DO       ; test GB Data Out line
        bsf     Tmp,MSB
        call    DelayB          ; delay = 1 bit time (120us)
        btfsc   STATUS,C        ; see if we're done
        goto    GBRcv1          ; no, receive next bit

                                ; yes, send data to PC
PCxmt   bsf     Port_B,RTS      ; indicate that you're ready to send
        btfss   Port_B,CTS      ; wait for PC to be ready to receive
        goto    PCxmt
        movlw   8               ; send data to PC
        movwf   Count
        bcf     Port_B,DX       ; send start bit
        call    Delay1
X_next  bcf     STATUS,C        ; prepare C register (kind of pointless)
        rrf     Tmp,F           ; roll transmitted bit in there
        btfsc   STATUS,C
        bsf     Port_B,DX
        btfss   STATUS,C
        bcf     Port_B,DX
        call    DelayX          ; call bit delay
        decfsz  Count,F         ; see if there's any more data to be sent
        goto    X_next
        bsf     Port_B,DX       ; no, send stop bit
        call    Delay1
        bcf     Port_B,RTS      ; clear RTS to indicate end of transmission
        goto    main            ; start over

PCrcv1  call    Delay3

PCrcv   btfsc   Port_B,DR       ; see if start bit is being transmitted
        goto    PCrcv1          ; no, wait half a bit time
        call    Delay4          ; yes, wait 1.25 bit time

Rcvr    movlw   80h             ; setup receive register
        movwf   Tmp
R_next  bcf     STATUS,C        ; reset Carry flag
        rrf     Tmp,F
        btfsc   Port_B,DR       ; set MSB accordingly to RxD
        bsf     Tmp,MSB
        call    DelayY
        btfss   STATUS,C        ; see if we're done
        goto    R_next

GBxmt   

DelayA  movlw   .128-DelA
        goto    save
DelayB  movlw   .128-DelB
        goto    save
DelayY  movlw   BAUD_Y
        goto    save
DelayX  movlw   BAUD_X
        goto    save
Delay3  movlw   BAUD_3
        goto    save
Delay4  movlw   BAUD_4
        goto    save
Delay1  movlw   BAUD_1
        goto    save
Delay2  movlw   BAUD_2
save    movwf   RTTC
sv1     btfss   RTTC,MSB
        goto    sv1             ; wait for RTTC to time-out
        retlw   0


        end
