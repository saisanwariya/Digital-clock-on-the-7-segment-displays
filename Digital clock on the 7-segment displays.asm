***********************************************************************
*
* Title:          Clock Timer (min/sec)
*
* Objective:      CMPEN 472 Homework 8
*
* Revision:       V1.0
*
* Date:	          March 22, 2023
*
* Orginal 
* Programmer:     Kyusun Choi 
*
* Programmer:     Sai Narayan
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        RTI usage
*                 Typewriter program and 7-Segment display, at PORTB
*                 
*
* Algorithm:      Simple Serial I/O use, typewriter, RTIs
*
* Register use:	  A, B, X, CCR
*
* Memory use:     RAM Locations from $3000 for data, 
*                 RAM Locations from $3100 for program
*
*	Input:			    Parameters hard-coded in the program - PORTB, 
*                 Terminal connected over serial
* Output:         
*                 Terminal connected over serial
*                 PORTB bit 7 to bit 4, 7-segment MSB
*                 PORTB bit 3 to bit 0, 7-segment LSB
*
* Observation:    This is a menu-driven program that prints to and receives
*                 data from a terminal, and will do different things based 
*                 on user input, including changing the time and a typewriter 
*                 program that displays ASCII data on PORTB - 7-segment displays.
*
***********************************************************************
* Parameter Declearation Section
*
* Export Symbols
            XDEF        Entry        ; export 'Entry' symbol
            ABSENTRY    Entry        ; for assembly entry point

; include derivative specific macros
PORTA       EQU         $0002
PORTB       EQU         $0001
DDRB        EQU         $0003

SCIBDH      EQU         $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU         $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU         $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU         $00CC        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00CF        ; Serial port (SCI) Data Register

CRGFLG      EQU         $0037        ; Clock and Reset Generator Flags
CRGINT      EQU         $0038        ; Clock and Reset Generator Interrupts
RTICTL      EQU         $003B        ; Real Time Interrupt Control

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character

;*******************************************************
; variable/data section
            ORG    $3000             ; RAMStart defined as $3000
                                     ; in MC9S12C128 chip

ctr2p5m     DS.W   1                 ; interrupt counter for 2.5 mSec. of time
times       DS.B   1
timem       DS.B   1
timeh       DS.B   1
half        DS.B   1                 ; used for determining when a second has passed
dec         DS.B   1                 ; stores the decimal input as hex
dec2        DS.B   1
                                     ; 0 means no, 1 means half second.
CCount      DS.B        $0001        ; Number of chars in buffer
CmdBuff     DS.B        $0006        ; The actual command buffer


;*******************************************************
; interrupt vector section
            ORG    $FFF0             ; RTI interrupt vector setup for the simulator
;            ORG    $3FF0             ; RTI interrupt vector setup for the CSM-12C128 board
            DC.W   rtiisr

;*******************************************************
; code section

            ORG    $3100
Entry
            LDS    #Entry         ; initialize the stack pointer

            LDAA   #%11111111   ; Set PORTB bit 0,1,2,3,4,5,6,7
            STAA   DDRB         ; as output
            STAA   PORTB        ; set all bits of PORTB, initialize

            ldaa   #$0C         ; Enable SCI port Tx and Rx units
            staa   SCICR2       ; disable SCI interrupts

            ldd    #$0002       ; Set SCI Baud Register = $0002 => 1M baud at 24MHz
;           ldd    #$000D       ; Set SCI Baud Register = $000D => 115200 baud at 24MHz
;           ldd    #$009C       ; Set SCI Baud Register = $009C => 9600 baud at 24MHz
            std    SCIBDH       ; SCI port baud rate change


            ldaa    #$00           ; Load accumulator A with 00
            staa    PORTB          ; Store accumulator A value to PORTB to display 00 on the clock
            
            ldaa    #$0            ; Load accumulator A with 0
            staa    PORTA          ; Store accumulator A value to PORTA to also display 00 on the clock

            ldx    #msg1           ; Load index register X with the address of 'msg1', the first message to print
            jsr    printmsg        ; Call the subroutine 'printmsg' to print the message
            jsr    nextline        ; Call the subroutine 'nextline' to move to the next line of display

            ldx    #menu1          ; Load index register X with the address of 'menu1', the first menu line to print
            jsr    printmsg        ; Call 'printmsg' subroutine to print the menu line
            jsr    nextline        ; Call 'nextline' subroutine to move to the next line of display

            ldx    #menu2          ; Load index register X with the address of 'menu2', the second menu line to print
            jsr    printmsg        ; Call 'printmsg' subroutine to print the menu line
            jsr    nextline        ; Call 'nextline' subroutine to move to the next line of display
            
            ldx    #menu3          ; Load index register X with the address of 'menu3', the third menu line to print
            jsr    printmsg        ; Call 'printmsg' subroutine to print the menu line
            jsr    nextline        ; Call 'nextline' subroutine to move to the next line of display
            
            ldx    #menu4          ; Load index register X with the address of 'menu4', the fourth menu line to print
            jsr    printmsg        ; Call 'printmsg' subroutine to print the menu line
            jsr    nextline        ; Call 'nextline' subroutine to move to the next line of display
            
            bset   RTICTL,%00011001 ; Set Real Time Interrupt control: dev=10*(2**10)=2.555msec for C128 board, 4MHz quartz oscillator clock
            bset   CRGINT,%10000000 ; Enable Real Time Interrupt (RTI)
            bset   CRGFLG,%10000000 ; Clear RTI Interrupt Flag

            ldx    #0              ; Load index register X with 0
            stx    ctr2p5m         ; Initialize interrupt counter 'ctr2p5m' with 0
            cli                    ; Clear interrupt mask, enabling global interrupts

            clr    half            ; Clear out the 'half' counter
            clr    times           ; Clear out the 'times' counter
            clr    timem           ; Clear out the 'timem' counter
                
main        ldx    #prompt          ; print the prompt
            jsr    printmsg
            ldx   #CmdBuff          ; cmd buffer init
            clr   CCount
            LDAA  #$0000

looop       jsr    SCountAndDisplay ; if 0.5 second is up, toggle the LED 

            jsr    getchar          ; type writer - check the key board
            tsta                    ;  if nothing typed, keep checking
            beq    looop
                                    ;  otherwise - what is typed on key board
            jsr    putchar          ; is displayed on the terminal window
            
            staa  1,X+               ; store char in buffer
            inc   CCount             ; 
            ldab  CCount
            cmpb  #$08               ; max # chars in buffer is 7
            beq   Error              ; user filled the buffer
            cmpa   #CR
            bne    looop            ; if Enter/Return key is pressed, move the
            ldaa   #LF              ; cursor to next line
            jsr    putchar


            ldx   #CmdBuff           
            ldaa  1,X+   
CmdChk      cmpa  #$73               ; is character == s?            
            lbeq  s                  ;  Yes, S execute
            cmpa  #$71               ; is character == q?            
            lbeq  ttyStart           ;  Yes, start typewriter

Error                                ; no recognized command entered, print err msg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #msg4              ; print the error message
            jsr   printmsg
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  main               ; loop back to beginning, infinitely


s           ldaa  1,X+
            cmpa  #$20              ; ensure second character in input is space
            bne   Error             ; must be a space there
            clr   dec               ; clear out decimal variable s
            clr   dec2               ; clear out decimal variable m              
            
            ldaa  1,X+
            cmpa  #$30              ; ensure digit is a number
            blo   Error
            cmpa  #$39
            bhi   Error
            suba  #$30
            staa  timem

            ldaa  1,X+
            cmpa  #$3A              ; ensure second character in input is space
            bne   Error             ; must be a space there           
            
            ldaa  1,X+
            cmpa  #$30              ; ensure digit is a number
            blo   Error
            cmpa  #$35              ; ensure digit is smaller than 6
            bhi   Error
            
            suba  #$30              ; ASCII number offset
            ldab  #10               ; weight of most sig digit
            mul                     ; A * #10, stored in D
            stab  dec               ; store result in dec. Can store B because number is only 1 byte once converted
            

oneDigit    ldaa  1,X+
            cmpa  #$30              ; ensure digit is a number
            blo   Error
            cmpa  #$39              ; ensure digit is smaller than ":" (9 or below)
            bhi   Error
            
            suba  #$30              ; ASCII number offset
            ldab  #1               ; weight of least sig digit
            mul                     ; A * #10, stored in D
            ldaa  dec
            aba                     ; add stored 10s place number with converted 1s place number
            staa  dec
            
            clr   half
            ldx   #$0000
            stx    ctr2p5m          ; initialize interrupt counter with 0.
            staa  times
            
            
snextS       ldaa    times
            cmpa    #$32            ; if/else if/else chain to convert hex numbers to hex numbers that look like the appropriate decimal number
            blo     selseIf1
            adda    #$1E            ; if (times >= $32) print(times+$1E);
            bra     sprint           
            
selseIf1     cmpa    #$28            
            blo     selseIf2
            adda    #$18            ; else if (times >= $28) print(times+$18);
            bra     sprint
            
selseIf2     cmpa    #$1E
            blo     selseIf3
            adda    #$12            ; else if (times >= $1E) print(times+$12);
            bra     sprint
            
selseIf3     cmpa    #$14
            blo     selseIf4
            adda    #$0C            ; else if (times >= $14) print(times+$0C);
            bra     sprint            
            
selseIf4     cmpa    #$0A
            blo     sprint           ; branch to else case
            adda    #$06            ; else if (times >= $0A) print(times+$06);
            bra     sprint
            
sprint       staa    PORTB           ; show the number on PORTB                            
            lbra   main
            
;
; Typewriter Program
;
ttyStart    sei                      ; disable interrupts
            ldx   #msg1              ; print the first message, 'Hello'
            ldaa  #$DD
            staa  CCount
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar

            ldx   #msg2              ; print the third message
            jsr   printmsg
                                                                                                            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
                 
tty         jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   tty
                                     ;  otherwise - what is typed on key board
            jsr   putchar            ; is displayed on the terminal window - echo print

            staa  PORTB              ; show the character on PORTB

            cmpa  #CR
            bne   tty                ; if Enter/Return key is pressed, move the
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            bra   tty


;subroutine section below

;***********RTI interrupt service routine***************
rtiisr      bset   CRGFLG,%10000000 ; clear RTI Interrupt Flag - for the next one
            ldx    ctr2p5m          ; every time the RTI occur, increase
            inx                     ;    the 16bit interrupt count
            stx    ctr2p5m
            
rtidone     RTI
;***********end of RTI interrupt service routine********

;***************SCountAndDisplay***************
;* Program: increment half-second ctr if 0.5 second is up, handle seconds counting and display
;* Input:   ctr2p5m & times variables
;* Output:  ctr2p5m variable, times variable, 7Segment Displays
;* Registers modified: CCR, A, X
;* Algorithm:
;    Check for 0.5 second passed
;      if not 0.5 second yet, just pass
;      if 0.5 second has reached, then increment half and reset ctr2p5m 
;      if 1 second has been reached, then reset half and increment times and display times on 7seg displays
;**********************************************
SCountAndDisplay   
            psha               ; Push accumulator A onto stack
            pshx               ; Push index register X onto stack

            ldx    ctr2p5m     ; Load value from memory location ctr2p5m into index register X
            cpx    #40         ; Compare the value in the index register X with immediate value 40
            blo    done        ; Branch to label done if result of the compare operation is less 

            ldx    #0          ; Load immediate value 0 into index register X
            stx    ctr2p5m     ; Store value from index register X into memory location ctr2p5m

            ldaa   half        ; Load value from memory location half into accumulator A
            cmpa   #$01        ; Compare the value in accumulator A with immediate value 1 (hex)
            beq    second      ; Branch to label second if result of compare operation is equal
            inc    half        ; Increment value at memory location half
            bra    done        ; Branch to label done
            
second      clr    half        ; Clear the value at memory location half
            inc    times       ; Increment value at memory location times
            ldaa   times       ; Load value from memory location times into accumulator A
            cmpa   #$3C        ; Compare value in accumulator A with immediate value 3C (hex)
            bne    nextS

nextM       clr    times       ; Clear value at memory location times
            inc    timem       ; Increment value at memory location timem
            ldaa   timem       ; Load value from memory location timem into accumulator A
            cmpa   #$0A        ; Compare value in accumulator A with immediate value A (hex)
            bne    nextS
            clr    timem

nextS       ldaa   times
            cmpa   #$32        ; Compare value in accumulator A with immediate value 32 (hex)
            blo    elseIf1
            adda   #$1E        ; Add immediate value 1E (hex) to accumulator A
            bra    print           
            
elseIf1     cmpa   #$28            
            blo    elseIf2
            adda   #$18        ; Add immediate value 18 (hex) to accumulator A
            bra    print
            
elseIf2     cmpa   #$1E
            blo    elseIf3
            adda   #$12        ; Add immediate value 12 (hex) to accumulator A
            bra    print
            
elseIf3     cmpa   #$14
            blo    elseIf4
            adda   #$0C        ; Add immediate value 0C (hex) to accumulator A
            bra    print            
            
elseIf4     cmpa   #$0A
            blo    print       
            adda   #$06        ; Add immediate value 06 (hex) to accumulator A
            bra    print
            
print       staa   PORTB       ; Store value from accumulator A into memory location PORTB (Assumed to be a port for display output)                                                      
            ldab   timem       ; Load value from memory location timem into accumulator B
            stab   PORTA       ; Store value from accumulator B into memory location PORTA (Assumed to be another port for display output)
            
done        pulx               ; Pull value from stack into index register X
            pula               ; Pull value from stack into accumulator A
            rts                ; Return from subroutine

;***************end of SCountAndDisplay***************

;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
NULL            equ     $00
printmsg        psha                   ;Save registers
                pshx
printmsgloop    ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
                cmpa    #NULL
                beq     printmsgdone   ;end of strint yet?
                bsr     putchar        ;if not, print character and do next
                bra     printmsgloop
printmsgdone    pulx 
                pula
                rts
;***********end of printmsg********************

;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar     brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
            staa  SCIDRL                      ; send a character
            rts
;***************end of putchar*****************

;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************

getchar     brclr SCISR1,#%00100000,getchar7
            ldaa  SCIDRL
            rts
getchar7    clra
            rts
;****************end of getchar**************** 

;****************nextline**********************
nextline    psha
            ldaa  #CR              ; move the cursor to beginning of the line
            jsr   putchar          ;   Cariage Return/Enter key
            ldaa  #LF              ; move the cursor to next line, Line Feed
            jsr   putchar
            pula
            rts
;****************end of nextline***************



;****************PRINT STATEMENTS**************
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip
msg1        DC.B    'Hello', $00
msg2        DC.B    'You may type below', $00
msg4        DC.B    'Invalid time format. Correct example => 0:00 to 9:59', $00
prompt      DC.B    'Clock> ', $00
menu1       DC.B    'Input the letter s followed by the Time Format to set the clock to.', $00
menu2       DC.B    'The clock goes from 0:00 to 9:59. Do not enter anything greater than 9:59. Follow the example below:', $00
menu3       DC.B    'Clock> s 1:11', $00
menu4       DC.B    'You may also quit to the Typewriter program by entering the letter q.', $00

            END               ; this is end of assembly source file
                              ; lines below are ignored - not assembled/compiled
