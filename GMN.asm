//----------------------------------------------------------
// LS Guess my number
//
//java -jar kickass.jar GMN.asm
//
//http://unusedino.de/ec64/technical/project64/mapping_c64.html
//https://github.com/OldSkoolCoder/Tutorials/blob/master/08%20-%20Tutorial%20Eight.asm
//https://www.c64-wiki.com/wiki/Main_Page
//https://www.pagetable.com/c64disasm/
//https://gist.github.com/cbmeeks/4287745eab43e246ddc6bcbe96a48c19
//----------------------------------------------------------

.const VER	= "1.04"
#import "Include\LIB_SymbolTable.asm"

//------------------------DISK------------------------------

.disk [filename= "GMN.d64", name = "GMN"]
{
[name="GMN", type="prg", segments="GMN" ],
}

//------------------------BASIC-----------------------------

.segment GMN []
#import "Include\LS_StandardBasicStart.asm"

//-----------------------CONST-----------------------------------

.const startRaster = 48
.const endRaster = 251
.const maxG = 9

//-----------------------START------------------------------

		* = $0810 "Main"
Start:
		sei							//set interrupt
		TurnOffCiaInterrupt()
		EnableRasterInterrupt()
		Clear_RST8()
		lda #startRaster
		sta RASTER_COUNTER
		SetIrqVector(irqcode)
		cli
	
game:
		lda #0
		sta NDX
		lda #WHITE					//title
		sta CUR_COLOR
		jsr CLSCR					
		PrintCentered(title)
		PrintCentered(version)
		CenterSequence(99,23)
		EndLine()
		EndLine()
		lda #LIGHTBLUE
		sta CUR_COLOR
		PrintText(G1)
		PrintText(G2)
		EndLine()
		
		RandomNumber(1, 99)
		MOV8(WINT, numToGuess)
		lda #0
		sta gCount
		
guessLoop:
		inc gCount
		//test for maxG, and goto game over = LOST
		lda gCount
		cmp #maxG
		bcs loser
		Console8(gCount)
		PrintText(TRY)
		InputInteger(2)
		lda numToGuess
		cmp guess
		beq won
		bcs low
		bcc high
		
round:	EndLine()
		jmp guessLoop
low:
		PrintText(sep)
		PrintText(higher)
		jmp round
high:
		PrintText(sep)
		PrintText(lower)
		jmp round

loser:
		EndLine()
		PrintText(lost)
		EndLine()
		jmp end
won:	
		PrintText(sep)
		PrintText(correct)
		EndLine()
		EndLine()
		PrintText(win)
		EndLine()	
end:
		//play another?
		PrintText(again)
		jsr another

//-----------------------SUBS-------------------------------
subs:	* = subs "Subroutines"

//------ IMPORTS ----

#import "Include\LS_ConsolePrint.asm" 
#import "Include\LS_Interrupt.asm"
#import "Include\LS_System.asm"
#import "Include\LS_Keyboard.asm"
#import "Include\LS_Random.asm"

another:{
			WaitAnyKey()
			cmp #KEY_Y			
			beq restart
			cmp #KEY_N			
			beq quit
			jmp another
restart:	jmp game
quit:		
			lda #0
			sta NDX
			rts
}

irqcode:
{
	lda modeflag
	beq mode1
	jmp mode2

mode1:
	lda #$01
	sta modeflag
	lda #LIGHTBLUE
	sta BORDER
	lda #startRaster
	sta RASTER_COUNTER
	AcknowledgeInterrupt()
	jmp IRQOUT

mode2:
	lda #$00
	sta modeflag
	lda #BLUE
	sta BORDER
	lda #endRaster
	sta RASTER_COUNTER
	AcknowledgeInterrupt()
	ExitInterrupt()
}

getNumber:
{
			sty	mChar		//max number of chars
			lda #0
			sta countChar	//reset
loop:		jsr GETIN		//get character in A
			beq loop
			//check if enter
			cmp #CHR_Return
			beq enter
			//check if delete
			cmp #CHR_Backspace
			beq delete
			//check if max reached
			ldx countChar
			cpx mChar
			bmi check
			jmp loop
check:
			//check if less than 30
			cmp #$30
			bcc loop		//< asc(0)
			cmp #$3A
			bcs loop		//> Asc(9)
			//store value,inc pointer
			inc countChar
			ldy countChar
			sta input,y
			jsr CHROUT
			jmp loop
			
enter:
			ldx countChar
			cpx #0
			beq loop		//no entry, cont loop
			jmp continue
			
delete:
			ldx countChar
			cpx #0
			beq loop		//no entry, nothing to delete
			dec countChar
			lda #CHR_Backspace
			jsr CHROUT
			jmp loop
			
continue:
			//set null after sequence
			inc countChar
			ldy countChar
			lda #0
			sta input,y
			//make it to number
			StringToInt8(input)
			stx guess
			rts
}

//-----------------------TEXT-------------------------------
text: 		* = text "Text"
title:		.text 	"*  GUESS MY NUMBER  *"
			.byte $0d,$00
version:	.text 	"V"
			.text VER
			.text " BY LS"
			.byte $0d,$00
G1:			.text "I HAVE A NUMBER IN MY MIND."			
			.byte $0d,$00
G2:			.text "TRY TO GUESS IT."
			.byte $0d,$00
TRY:		.text ". TRY: "
			brk
sep: 		.text "  : "
			brk
higher:		.text "IT'S HIGHER"
			brk
lower:		.text "IT'S LOWER"
			brk
equal: 		.text "YES. THIS WAS IT!"
			brk
correct:	.text "CORRECT!"
			brk
win:		.text "YOU HAVE WON THE GAME"
			.byte $0d,$00
lost:		.text "YOU TOOK TOO LONG LOSER"
			.byte $0d,$00
again:		.text "PLAY ANOTHER (Y/N)?"
			brk
		
//-----------------------DATA-------------------------------
data: 		* = data "Data"
modeflag:		.byte 0
numToGuess:		.byte 0
guess:			.byte 0
gCount:			.byte 0
mChar:			.byte 0
countChar:		.byte 0
input:			.byte 0,0,0,0,0,0,0,0

//--------------------MACROS-------------------------

.macro InputInteger(n){
/*
arguments: y: number of places
return: none
*/
		ldy #n
		jsr getNumber
}