;------------------------------------------------------------------------
;-  Written by: Neviksti
;-     If you use my code, please share your creations with me
;-     as I am always curious :)
;------------------------------------------------------------------------

;temporary sprite buffer1 ($0400-$061F)
.DEFINE SpriteBuf1	$0400;minus everything by 4
.DEFINE Pipe1Sprite $0408
.DEFINE Pipe2Sprite	$0430
.DEFINE	Pipe3Sprite $040C
.DEFINE	Pipe4Sprite $0410
.DEFINE	Pipe5Sprite $0414
.DEFINE	Pipe6Sprite $0418
.DEFINE	Pipe7Sprite $041C
.DEFINE	Pipe8Sprite $0420
.DEFINE	Pipe9Sprite $0424
.DEFINE	Pipe10Sprite $0428
.DEFINE	Pipe11Sprite $042C
.DEFINE GroundTile1	$0404
.DEFINE GroundTile2	$0434
.DEFINE GroundTile3	$0438
.DEFINE GroundTile4	$043C
.DEFINE GroundTile5	$0440
.DEFINE GroundTile6	$0444
.DEFINE GroundTile7	$0448
.DEFINE GroundTile8	$044C
.DEFINE SpriteBuf2	$0600


.DEFINE sx	   		0
.DEFINE sy	   		1
.DEFINE sframe 		2
.DEFINE spriority		3

.BANK 0
.SECTION "SpriteInit"

SpriteInit:
	php	

	rep	#$30	;16bit mem/A, 16 bit X/Y

	ldx #$0000
	lda #$5555
_clr:
	sta SpriteBuf2, x		;initialize all sprites to be off the screen
	inx
	inx
	cpx #$0020
	bne _clr	

	plp
	rts
.ENDS
;==========================================================================================
