#importonce
//----------------------------------------------------------------			
/*****************************************************************
LS_Screen.asm
v0.01

dependencies:
	standard includes
memory:
	
*****************************************************************/
//-----------------------CONST-----------------------------------

//--- SUBS -------------------------------------------------------

//-----------------------DATA-------------------------------
//LS_Screen: 		* = LS_Screen "LS_Screen"


//-----------------------MACROS-----------------------------
.macro FillScreen(addr, char){
/*
args: screen addres, character code
*/
		lda	#char
		ldy #0
fill:
		sta addr,y
		sta addr + 256,y
		sta addr + 512,y
		sta addr + 768,y
		iny
		bne fill

}

//----------------------------------------------------------------	