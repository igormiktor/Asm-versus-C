; ***********************************************************************************
;
;    Blink two LEDs (PB1 and PB2) on an ATmega328p at 1 Hz on opposite duty cycles
;
;    The MIT License (MIT)
;
;    Copyright (c) 2020 Igor Mikolic-Torreira
;
;    Permission is hereby granted, free of charge, to any person obtaining a copy
;    of this software and associated documentation files (the "Software"), to deal
;    in the Software without restriction, including without limitation the rights
;    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;    copies of the Software, and to permit persons to whom the Software is
;    furnished to do so, subject to the following conditions:
;
;    The above copyright notice and this permission notice shall be included in all
;    copies or substantial portions of the Software.
;
;    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;    SOFTWARE.
;
; ***********************************************************************************



.device "ATmega328p"



; ***************************************
;  R E G I S T E R  P O L I C Y
; ***************************************

; .def rSreg  = r15                             ; Save/Restore status port

.def rTmp   = r16                               ; Define multipurpose register



; **********************************
;  M A C R O S
; **********************************

.macro initializeStack                          ; Takes 1 argument, @0 = register to use

    .ifdef SPH                                  ; if SPH is defined
        ldi @0, High( RAMEND )
        out SPH, @0                             ; Upper byte of stack pointer (always load high-byte first)
    .endif

    ldi @0, Low( RAMEND )
    out SPL, @0                                 ; Lower byte of stack pointer

.endm



; **********************************
;  C O D E  S E G M E N T
; **********************************

.cseg
.org 000000



; ************************************
;  I N T E R R U P T  V E C T O R S
; ************************************

	rjmp main                                      ; Reset vector
	reti ; (other)
	reti ; INT0
	reti ; (other)
	reti ; INT1
	reti ; (other)
	reti ; PCI0
	reti ; (other)
	reti ; PCI1
	reti ; (other)
	reti ; PCI2
	reti ; (other)
	reti ; WDT
	reti ; (other)
	reti ; OC2A
	reti ; (other)
	reti ; OC2B
	reti ; (other)
	reti ; OVF2
	reti ; (other)
	reti ; ICP1
	reti ; (other)
	rjmp Timer1CmpAInterrupt                       ; OC1A
	reti ; (other)
	reti ; OC1B
	reti ; (other)
	reti ; OVF1
	reti ; (other)
	reti ; OC0A
	reti ; (other)
	reti ; OC0B
	reti ; (other)
	reti ; OVF0
	reti ; (other)
	reti ; SPI
	reti ; (other)
	reti ; URXC
	reti ; (other)
	reti ; UDRE
	reti ; (other)
	reti ; UTXC
	reti ; (other)
	reti ; ADCC
	reti ; (other)
	reti ; ERDY
	reti ; (other)
	reti ; ACI
	reti ; (other)
	reti ; TWI
	reti ; (other)
	reti ; SPMR



; ***************************************
;  I N T E R R U P T  H A N D L E R S
; ***************************************

Timer1CmpAInterrupt:

    ; Nothing in this interrupt affects SREG, so no need to save it

    ; Toggle pins.  Note that PORTx bits can be toggled by writing a 1 to the corresponding PINx bit.

    sbi PINB, PINB1                             ; Toggle green LED
    sbi PINB, PINB2                             ; Toggle red LED

    reti



; **********************************
;  M A I N   P R O G R A M
; **********************************

main:

    .def rArg           = r24                   ; Register for argument passing
    .equ kPauseTime     = 20                    ; Seconds
    .equ kTimer1Top     = 62449                 ; "Top" counter value for 1Hz output with prescalar of 256 using Timer1

    initializeStack rTmp                        ; Set up the stack

    sbi DDRB, DDB1                              ; Set pin connected to Green LED to output mode
    sbi DDRB, DDB2                              ; Set pin connected to Red LED to output mode

    sbi PORTB, PORTB1                           ; Green LED high
    sbi PORTB, PORTB2                           ; Red LED high

    ldi rArg, kPauseTime
    rcall delayTenthsOfSeconds                  ; Pause (see both LEDs working)

    cbi PORTB, PORTB1                           ; Green LED low
    cbi PORTB, PORTB2                           ; Red LED low

    ldi rArg, kPauseTime
    rcall delayTenthsOfSeconds                  ; Pause before we start blinking them

    sbi PORTB, PORTB1                           ; Green LED high


    ; Set up Timer1 (CTC mode, prescalar=256, CompA interrupt on)
    ; Timer1 located beyond the 0xFF I/O address range so must access via sts instruction

    ldi rTmp, ( 1 << WGM12 ) | ( 1 << CS12 )    ; Select CTC mode with prescalar = 256
    sts TCCR1B, rTmp;

    ; Load the CompA "top" counter value, 16-bit value must be loaded high-byte first

    ldi rTmp, High( kTimer1Top )                ; Always load high byte first
    sts OCR1AH, rTmp;
    ldi rTmp, Low( kTimer1Top )                 ; And load low byte second
    sts OCR1AL, rTmp;

    ; Enable the CompA interrupt for Timer1

    ldi rTmp, ( 1 << OCIE1A )                   ; Enable CompA interrupt
    sts TIMSK1, rTmp;

    sei                                         ; Enable interrupts


    loopMain:
        rjmp loopMain                           ; infinite loop



; **********************************
;  S U B R O U T I N E
; **********************************

delayTenthsOfSeconds:

    ; Register r24 (tenthOfSecCounter) is passed as parameter
    ; r24 = number of tenths-of-seconds to count (comes in as argument)
    ;     = number of times to execute the outer+inner loops combined
    ; r25 = outer loop counter byte
    ; r26 = low byte of inner loop counter word
    ; r27 = high byte of inner loop counter word

    .def r10ths         = r24                   ; r24 = number of tenths-of-seconds to count (comes in as argument)
                                                ;     = number of times to execute the outer+inner loops combined
    .def rOuter         = r25                   ; r25 = outer loop counter byte
    .def rInnerL        = r26                   ; r26 = low byte of inner loop counter word
    .def rInnerH        = r27                   ; r27 = high byte of inner loop counter word

    ; Executing the following combination of inner and outer loop cycles takes almost precisely 0.1 seconds at 16 Mhz
    .equ kOuterCount    = 7
    .equ kInnerCount    = 57142



    ; Top of loop for number of tenths-of-seconds
    Loop1:
        ; Initialize outer loop (uses a byte counter and counts down)
        ldi rOuter, kOuterCount

        ; Top of outer loop
        Loop2:
            ; Initialze inner loop (uses a word counter and counts down)
            ldi rInnerL, Low( kInnerCount )
            ldi rInnerH, High( kInnerCount )

            ; Top of inner loop
            Loop3:
                ; Decrement and test inner loop
                sbiw rInnerL, 1
                brne Loop3
                ; Done with inner loop

            ; Decrement and test outer loop
            dec rOuter
            brne Loop2
            ; Done with outer loop

        ; Decrement and test tenth-of-second loop
        dec r10ths
        brne Loop1
        ; Done with the requested number of tenths-of-seconds

    ret
