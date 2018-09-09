;------------------------------------------------------------------------
;-  Written by: Neviksti
;-     This was coded as an example for Darrok (from the zsnes message
;-     boards) who was interested in learning more about the SNES 
;-     hardware and language.
;-
;-     If you use my code, please share your creations with me
;-     as I am always curious :)
;------------------------------------------------------------------------

;=== Include MemoryMap, VectorTable, HeaderInfo ===
.INCLUDE "flappy.inc"

;=== Include Library Routines & Macros ===
.INCLUDE "LoadGraphics.asm"
.INCLUDE "InitSNES.asm"
.INCLUDE "2input.asm"
.INCLUDE "Sprites.asm"
.INCLUDE "Strings.asm"

;==============================================================================
; main
;==============================================================================

.DEFINE MapX		$18
.DEFINE MapY		$1A
.DEFINE CurrentFrame	(SpriteBuf1+sframe)

.DEFINE FrameWait		$1C
.DEFINE VertSpeed		$22
.DEFINE UntilFrame		$2C
.DEFINE jumpRelsd		$28
.DEFINE PipesMoved		$36
.DEFINE Pipe1XPOS		$30
.DEFINE Pipe1YPOS		$34
.DEFINE LastP1Chg		$38; starts at 7A6B for whatever random-ass reason
.DEFINE randomVar1		$3E
.DEFINE randomVar2		$40
.DEFINE flappyScore		$42;16 bit variable
.DEFINE deadOrNot		$44
.DEFINE deadFirstBounce	$46
.DEFINE deadSecBounce	$48
.DEFINE gameOver		$4A
.DEFINE	FramesUntilNextHalfDown $3A
.DEFINE LongFrameNumber	$1000



.BANK 0 SLOT 0
.ORG 0
.SECTION "WalkerCode"

Main:
	InitializeSNES

	rep #$10		;A/mem = 8bit, X/Y=16bit
	sep #$20

    ;$404 = Sprite 2 X
	;$405 = Sprite 2 Y
	;$406 = Sprite 2 tile numbering
	;$407 = Sprite 2 priority bits
	;Load palette to make our pictures look correct
	LoadPalette	BG_Palette

	;Load Tile and Character data to VRAM
	LoadBlockToVRAM	BackgroundMap, $0000, $2000	; 64x64 tiles = 4096 words = 8192 bytes
	LoadBlockToVRAM	BackgroundPics, $2000, $6000	; 384 tiles * (8bit color)= 0x6000 bytes
	LoadBlockToVRAM	ASCIITiles, $5000, $0800	;128 tiles * (2bit color = 2 planes) --> 2048 bytes
	LoadBlockToVRAM	SpriteTiles, $6000, $3000 ;24 32x32 tiles * (4bit color = 4 planes) --> 12288 bytes | 6000 2800
	LoadBlockToVRAM Sprite2, $9000, $0800; biker test sprite | 9000 0800
	

	;Set the priority bit of all the BG2 tiles
	LDA #$80
	STA $2115		;set up the VRAM so we can write just to the high byte
	LDX #$5800
	STX $2116
	LDX #$0400		;32x32 tiles = 1024
	LDA #$20
Next_tile:
	STA $2119
	DEX
	BNE Next_tile
	LDA #01
	STA $1E
	LDA #00
	STA $20
	
	JSR SpriteInit	;setup the sprite buffer
	JSR JoyInit		;setup joypads and enable NMI

	;         ---12345678901234567890123456789012---
	PrintString " Flappy Bird development build \n"
	lda #$00
	sta FramesUntilNextHalfDown;initilate this variable. This is alternates which allows the bird to fall 1/2 of a pixel per frame
	lda #$00
	sta $42
	lda MapY
	clc
	adc #$70; what this code does is move the background up a little
	sta MapY
	
	lda #$70
	sta Pipe1YPOS; this makes the whole first column of pipes either go up or down. Simply change the value of this to see the effect
	;lda #$EE
	;sta Pipe2XPOS
	;lda #$5A
	;sta Pipe2YPOS
	;ldx #$00
	;stx Pipe1XPOS
	ldx #$796B
	stx LastP1Chg; starts at 7A6B for whatever random-ass reason

	;setup our walking sprite
	;put him in the center of the screen
	lda #($80-16)
	sta SpriteBuf1+sx
	lda #(224/2-16)
	sta SpriteBuf1+sy
	lda #$6C
	sta $30
	;lda #($80-4)
	lda Pipe1XPOS
	sta Pipe1Sprite+sx;$0404
	;lda #(224/2+38)
	lda #(Pipe1YPOS+70)
	sta Pipe1Sprite+sy;

	;put sprite #0, #1, #2 and #3 on screen
	lda #%00000000
	sta SpriteBuf2
	;lda #$55
	;sta SpriteBuf2

	;set the sprite to the highest priority
	lda #%00110000
	sta SpriteBuf1+spriority
	;lda SpriteBuf1+sframe+4
	;lda #$00
	lda #$44
	sta Pipe1Sprite+sframe;$0406
	;lda #$32
	lda #%00110001
	sta Pipe1Sprite+spriority;$0407
	
	;-----------------------sprite 2
	lda Pipe1XPOS
	sta Pipe2Sprite+sx;
	;lda #(224/2+70)
	lda #(Pipe1YPOS+102)
	sta Pipe2Sprite+sy;
	lda #$40
	sta Pipe2Sprite+sframe
	lda #%00110001
	sta Pipe2Sprite+spriority
	;------sprite 3------------------
	lda Pipe1XPOS
	sta Pipe3Sprite+sx;
	;lda #(224/2-4)
	lda #(Pipe1YPOS-4)
	sta Pipe3Sprite+sy;
	lda #$44
	sta Pipe3Sprite+sframe
	lda #%10110001
	sta Pipe3Sprite+spriority
	;------sprite 4------------------
	lda Pipe1XPOS
	sta Pipe4Sprite+sx;
	;lda #(224/2-4)
	lda #(Pipe1YPOS-36)
	sta Pipe4Sprite+sy;
	lda #$40
	sta Pipe4Sprite+sframe
	lda #%10110001
	sta Pipe4Sprite+spriority
	;-----sprite4- through 8 high byte--
	lda #%00000000
	sta SpriteBuf2+1
	;-----sprite8- through 12 high byte--
	lda #%00000000
	sta SpriteBuf2+2
	;-----------------------
	;sprite 5 - 2nd Pipe End Bottom
	lda #$D5
	sta Pipe5Sprite+sx
	lda #$80
	sta Pipe5Sprite+sy
	lda #$44
	sta Pipe5Sprite+sframe
	lda #%00110001
	sta Pipe5Sprite+spriority
	;--------------------------------------------
	;sprite 6 - 2nd Pipe Middle Bottom
	lda #$D5
	sta Pipe6Sprite+sx
	lda #$A0
	sta Pipe6Sprite+sy
	lda #$40
	sta Pipe6Sprite+sframe
	lda #%00110001
	sta Pipe6Sprite+spriority
	;-----------------------
	;sprite 7 - 2nd Pipe End Upper
	lda #$D5
	sta Pipe7Sprite+sx
	lda #$38
	sta Pipe7Sprite+sy
	lda #$44
	sta Pipe7Sprite+sframe
	lda #%10110001;remember this one is flipped horizontally
	sta Pipe7Sprite+spriority
	;--------------------------------------------
	;sprite 8 - 2nd Pipe Middle Upper
	lda #$D5
	sta Pipe8Sprite+sx
	lda #$20
	sta Pipe8Sprite+sy
	lda #$40
	sta Pipe8Sprite+sframe
	lda #%10110001; fuck it i'll flip this too. Who knows what kind of exotic bugs either one of these options are triggering
	sta Pipe8Sprite+spriority
	;--------------------------------------------
	;sprite 9. 1st pipe lowest
	lda Pipe1XPOS
	sta Pipe9Sprite+sx
	lda #$C0
	sta Pipe9Sprite+sy
	lda #$40
	sta Pipe9Sprite+sframe
	lda #%00110001
	sta Pipe9Sprite+spriority
	;---------------------------------------------
	;sprite 10. 2nd pipe lowest
	lda #$D5
	sta Pipe10Sprite+sx
	lda #$C0
	sta Pipe10Sprite+sy
	lda #$40
	sta Pipe10Sprite+sframe
	lda #%00110001
	sta Pipe10Sprite+spriority
	;---------------------------------------------
	;sprite 11. 1st pipe 2nd lowest
	lda Pipe1XPOS
	sta Pipe11Sprite+sx
	lda #$A0
	sta Pipe11Sprite+sy
	lda #$40
	sta Pipe11Sprite+sframe
	lda #%00110001
	sta Pipe11Sprite+spriority
	;-----sprite12- through 16 high byte--
	lda #%01010100
	sta SpriteBuf2+3
	;sprite 13. 1st A ground tile
	;lda #$00
	;sta GroundTile1+sx;$0430
	;lda #$C0
	;sta GroundTile1+sy;$0431
	;lda #$48
	;sta GroundTile1+sframe;$0432
	;lda #%00110001
	;sta GroundTile1+spriority;$0433
	;sprite 14. 2nd ground tile
	;lda #$20
	;sta GroundTile2+sx;
	;lda #$C0
	;sta GroundTile2+sy;
	;lda #$48
	;sta GroundTile2+sframe;
	;lda #%00110001
	;sta GroundTile2+spriority;
	;sprite 15. 3rd ground tile
	;lda #$40
	;sta GroundTile3+sx;
	;lda #$C0
	;sta GroundTile3+sy;
	;lda #$48
	;sta GroundTile3+sframe;
	;lda #%00110001
	;sta GroundTile3+spriority;
	;====sprite 16 through 19 high byte--
	lda #%01010101
	sta SpriteBuf2+4
	;sprite 16. 4th ground tile
	;lda #$60
	;sta GroundTile4+sx;
	;lda #$C0
	;sta GroundTile4+sy;
	;lda #$48
	;sta GroundTile4+sframe;
	;lda #%00110001
	;sta GroundTile4+spriority;
	;sprite 17. 5th ground tile
	;lda #$80
	;sta GroundTile5+sx;
	;lda #$C0
	;sta GroundTile5+sy;
	;lda #$48
	;sta GroundTile5+sframe;
	;lda #%00110001
	;sta GroundTile5+spriority;
	;sprite 18. 6th ground tile
	;lda #$A0
	;sta GroundTile6+sx;
	;lda #$C0
	;sta GroundTile6+sy;
	;lda #$48
	;sta GroundTile6+sframe;
	;lda #%00110001
	;sta GroundTile6+spriority;
	;setup the video modes and such, then turn on the screen
	JSR SetupVideo	

InfiniteLoop:
	WAI

	;ldy $24;UntilFrame
	;cmp #$00
	;beq _untilFrameset
	SetCursorPos 20, 10
	;ldy #FrameNum
	;ldy #UntilFrame
	;PrintString "Frame num = %d    "
	ldy #SpriteBuf1+sframe
	PrintString "Frame num = %d    "
	
	JSR BirdDie
	;lda $24;UntilFrame
	;cmp FrameNum
	;bcs _uphelper
	
	;See what buttons were pressed
;_colorc:
;	lda $4219
;	and #$08
;	beq _whatever
;	
;	ldx	MapY
;	dex
;	dex
;	stx	MapY
;	
;	ldx $02
;	stx $0E
;	lda	CurrentFrame
;	and	#$F0
;	cmp	#$40
;	beq	IncrementFrame2
;	;lda	#$40
;	lda	#$C0
;	sta	CurrentFrame
;	jmp	_done ;changed bra to jmp
	
_up:
	;lda	Joy1+1
	lda	$4218
	and	#$80 ;Go up when you press the B button
	beq	_downHelper
	;ldx	MapY
	;dex
	;dex
	;stx	MapY
	;ldx #$15; amount of frames to go up for
	ldx #$31; I don't know if the 65C816 can handle negatives, and I don't feel like spending 3+ days of debugging to find out
	stx $2C

	;ldx	MapY
	;dex
	;dex
	;stx	MapY
	ldx	MapX
	inx
	stx	MapX
	lda #$30;change "sprite selection" back to the 1st selection
	sta SpriteBuf1+spriority
	lda	CurrentFrame
	and	#$F0
	cmp	#$40
	beq	IncrementFrame2
	lda	#$40
	sta	CurrentFrame
	jmp	_done ;changed bra to jmp
_downHelper:
	jmp _down
_done2:
	;ldx $2C
	;cpx #$01
	;bcs _autoup2
	jmp _done
_autoup2:
	jmp _autoup
	
IncrementFrame2:
	inc	FrameWait
	lda	FrameWait
	cmp	#$06
	bne	_done2

	lda	CurrentFrame
	and	#$F0
	sta	FrameWait
	lda	CurrentFrame
	clc
	adc	#$04
	and	#$0C
	adc	FrameWait
	sta	CurrentFrame
	inc	FrameNum

	stz	FrameWait
	jmp	_done ; changed all the bra to jsl

_down:
	lda	Joy1+1
	and	#$04
	beq	_left

	ldx	MapY
	inx
	inx
	stx	MapY

	lda	CurrentFrame
	and	#$F0
	cmp	#$C0
	beq	IncrementFrame2
	lda	#$C0
	sta	CurrentFrame
	jmp	_done ; changed bra to jmp

_left:
	lda	Joy1+1
	and	#$02
	beq	_right

	ldx	MapX
	dex
	dex
	stx	MapX

	lda	CurrentFrame
	and	#$F0
	cmp	#$80
	beq	IncrementFrame
	lda	#$80
	sta	CurrentFrame
	jmp	_done ; changed bra to jmp

_right:
	lda	Joy1+1
	and	#$01
	beq	_standing_still

	ldx	MapX
	inx
	inx
	stx	MapX

	lda	CurrentFrame
	and	#$F0
	cmp	#$40
	beq	IncrementFrame
	lda	#$40
	sta	CurrentFrame
	jmp	_done ;changed bra to jmp

_standing_still:
	;lda	CurrentFrame
	;and	#$F0
	;sta	CurrentFrame ; If I don't comment out this line + previous 2 lines the stationary flapping doesn't work right
	ldx	MapX ;make bird fly right on its own
	inx
	stx	MapX
	
	;ldx	MapY ;make bird go down on its own. It's no fun if you can't die!
	;inx
	;stx	MapY
	ldx SpriteBuf1+sy
	inx
	stx SpriteBuf1+sy;make the bird go down "without the camera following". Basically this moves the bird downwards automaticly without moving the map
	;the above 3 lines can be temporarily disabled for testing purposes - makes it not fall down
	JSR DetectCollision; where i attempted to put collision code once
	
	lda $2C;determine which sprites to use
	cmp #$13; changed from #$16 to #$11 9/08/17 2:28PM to show the mid-deceleration sprite
	bcc _decendAnims1
	lda	CurrentFrame
	and	#$F0
	cmp	#$00
	beq	IncrementFrame
	lda	#$00
	sta	CurrentFrame
	jmp	_done
_decendAnims1:
	JSR GoDownFast
	JSR HalfwayDownwardSpeed;These branch statements are getting really out of hand complicated so I'm using more subroutines due to the 128 byte read in advance limit on beq, bcc and bcs.
	lda	CurrentFrame
	and	#$F0
	cmp	#$C0
	beq	IncrementFrame
	lda	#$C0
	sta	CurrentFrame
jmp _done
	
_goUpFramesSlow
	lda	CurrentFrame
	and	#$F0
	cmp	#$80
	beq	IncrementFrame
	lda	#$80
	sta	CurrentFrame
	jmp	_almostDone ;changed _done to almostDone

IncrementFrame:
	inc	FrameWait
	lda	FrameWait
	cmp	#$06
	bne	_done

	lda	CurrentFrame
	and	#$F0
	sta	FrameWait
	lda	CurrentFrame
	clc
	adc	#$04
	and	#$0C
	adc	FrameWait
	sta	CurrentFrame
	inc	FrameNum

	stz	FrameWait
	bra	_done
_autoup:
	wai
	JSR DetectCollision
	lda $2C
	;cmp #$10;when to stop going up quickly and start gong up moderately
	cmp #$2E; don't know if the 65C816 can do negatives...
	bcc _autoUpMedium2
	;ldx	MapY
	;dex
	;dex
	;dex
	;stx	MapY; uncommenting the previous 5 lines will move the map down, providing the illusion of the camera moving with the bird upwards, but this is not that I need
	ldx SpriteBuf1+sy
	dex
	dex
	dex
	stx SpriteBuf1+sy
	dec $2C
	
	ldx	MapX ;make bird fly right on its own
	inx
	stx	MapX

	jmp _goUpFrames
	
_autoUpSlow2:
	;ldx	MapY
	;dex
	;stx	MapY
	ldx SpriteBuf1+sy
	dex
	stx SpriteBuf1+sy
	dec $2C
	
	ldx	MapX ;make bird fly right on its own
	inx
	stx	MapX

	jmp _goUpFramesSlow
_autoUpMedium2:
	lda $2C
	;cmp #$0D;when to stop going up moderately and start gong up slowly
	cmp #$2A; 65C816 and negatives.. blah blah blah
	bcc _autoUpSlow2
	;ldx	MapY
	;dex
	;dex
	;stx	MapY
	ldx SpriteBuf1+sy
	dex
	dex
	stx SpriteBuf1+sy
	dec $2C
	
	ldx	MapX ;make bird fly right on its own
	inx
	stx	MapX

	jmp _goUpFrames
	
_goUpFrames:
	lda	CurrentFrame
	and	#$F0
	cmp	#$40
	beq	IncrementFrame
	lda	#$40
	sta	CurrentFrame
	lda #$01
	sta $2A
	jmp	_almostDone ;changed _done to almostDone
	
_done:
	;JSR DetectCollision
	SetCursorPos 20, 10
	;ldy #FrameNum
	ldy #UntilFrame
	PrintString "Frame num = %d    "
	ldx $2C
	cpx #$1A
	bcs _autoupHelp
	ldx $2C
	cpx #$01
	bcs _gravDecay
	;lda $2A
	;cmp #$00
	;beq _PipesLeft
	;lda #$00
	;sta $2A
	;dec $2C
	;lda FrameNum ;commented this out as of 2:44pm 09/6/2017
	;cmp UntilFrame ;commented this out as of 2:44pm 09/6/2017
	;bcc _upVelocity ;commented this out as of 2:44pm 09/6/2017
	SetCursorPos 20, 10
	;ldy #FrameNum
	;ldy #UntilFrame
	;PrintString "Frame num = %d    "
	PrintString "Frame num = %d    "
	JMP InfiniteLoop	;Do this forever
	
_almostDone:
	lda	$4218
	and	#$80 ;Go up when you press the B button
	beq	_done
	;ldx	MapY
	;dex
	;dex
	;stx	MapY
	;ldx #$15; amount of frames to go up for
	ldx #$2A; I don't know if the 65C816 can handle negatives, and I don't feel like spending 3+ days of debugging to find out
	stx $2C

	;ldx	MapY
	;dex
	;dex
	;stx	MapY
	

	lda	CurrentFrame
	and	#$F0
	cmp	#$40
	beq	_inrfrmHelp
	lda	#$40
	sta	CurrentFrame
	jmp	_done ;changed bra to jmp
_inrfrmHelp:
jmp IncrementFrame2
_gravDecay:
	dec $2C
	jmp InfiniteLoop
_autoupHelp
	jmp _autoup
;_PipesLeft:
	;lda #$01
	;sta PipesMoved
	;ldx $404
	;inx
	;stx $404
	;jmp _done
;==========================================================================================
DetectCollision:
	lda Pipe1Sprite+sx;$0404
	cmp $0400
	beq _detectYcol
	bra _SecondDetection
	
	_detectYcol:
	lda $401
	clc
	adc #$16;putting this at 16 seems to work better for whatever reason
	sta $60
	lda Pipe1Sprite+sy;$0405
	cmp $60
	bcc _executeResult
	bra _detectYColTwo
	_detectYColTwo:
	lda $401
	sec
	sbc #$10;this one is fucking stupid but it generally works better than anything else I tried although I don't know why
	sta $64
	lda Pipe3Sprite+sy;$040D;Pipe3Sprite is the top end pipe
	cmp $64
	bcs _executeResult
	bra _endDectCol;changed from _endDectCol to _determinePointsPipe1
	_executeResult:
	;lda $0400
	;clc
	;adc #$10
	;sta $0400
	;stz $42
	lda #$01
	sta $44
	bra _endDectCol;changed from _endDectCol to _determinePointsPipe1
	_SecondDetection:
	lda Pipe5Sprite+sx;$0414
	cmp $0400
	beq _detectYcolB
	bra _determinePointsPipe1;changed from _endDectCol to _determinePointsPipe1
	
	_detectYcolB:
	lda $401
	clc
	adc #$20
	sta $60
	lda Pipe5Sprite+sy;$0415
	cmp $60
	bcc _executeResult
	bra _detectYColTwoB
	_detectYColTwoB:
	lda $401
	sec
	sbc #$10
	sta $64
	lda Pipe7Sprite+sy;$041D;40C is the top end pipe
	cmp $64
	bcs _executeResult
	bra _endDectCol;changed from _endDectCol to _determinePointsPipe1
	;_executeResult2:
	;lda $0400
	;clc
	;adc #$10
	;sta $0400
	;bra _endDectCol
	
	_determinePointsPipe1:
	lda Pipe1Sprite+sx;$404
	clc
	adc #$01
	sta $3E
	lda $3E
	cmp $400
	beq _scoreAPoint ;Check if the bird sucessfully passes the first vertical pipe barrier or not
	
	lda Pipe7Sprite+sx;$41C; pick a pipe sprite from the second column. Any pipe from column 2 will do. I randomly chose the one with an X axis address of $41C
	clc
	adc #$02
	sta $40
	lda $40
	cmp $400
	beq _scoreAPoint;check if it passed the 2nd vertical barrier. Note that these are only checking if it makes it past the X plane +2 pixels. Easy and simple.
	
	bra _endDectCol
	
	;_determinePointsPipe2:
	;bra _endDectCol
	_scoreAPoint:
	inc $42
	ldy #flappyScore
	SetCursorPos 2, 2
	PrintString "Score = %d    "
	bra _endDectCol
	
	_endDectCol:
	;JMP _done
	RTS
;==========================================================================================
BirdDie:
	lda $44
	cmp #$00
	bne _beginBirdDie
	;bra _endBirdDie
	RTS
	_beginBirdDie:
	lda #%10110000
	sta SpriteBuf1+spriority;flip bird sprite vertically
	
	JSR DetermineIfUpOrDown
	;ldx SpriteBuf1+sy
	;inx
	;stx SpriteBuf1+sy;go down
	
	lda	CurrentFrame
	and	#$F0
	cmp	#$40
	beq	IncrementFrameDie
	lda	#$40
	sta	CurrentFrame
	lda #$01
	sta $2A
	jmp	_endBirdDie
	
	IncrementFrameDie:
	JSR IncrementFrameSubRoutine
	;inc	FrameWait
	;lda	FrameWait
	;cmp	#$06
	;bne	_endBirdDie

	;lda	CurrentFrame
	;and	#$F0
	;sta	FrameWait
	;lda	CurrentFrame
	;clc
	;adc	#$04
	;and	#$0C
	;adc	FrameWait
	;sta	CurrentFrame
	;inc	FrameNum

	;stz	FrameWait
	jmp	_endBirdDie ; changed all the bra to jsl
	_endBirdDie:
	lda $48
	cmp #$01
	beq _beginFirstBounce
	lda $401;SpriteBuf1+sy
	cmp #$E0
	bcc _notFinishedDying
	bra _beginFirstBounce
	;lda $46
	;cmp #$01
	;bne _beginFirstBounce
	;lda #$00
	;sta $44
	;lda #%00110000
	;sta SpriteBuf1+spriority
	
	RTS
	_notFinishedDying:
	lda $46
	cmp #$01
	beq _removeDeathFlag
	
	jmp InfiniteLoop
	
	_beginFirstBounce:
	lda #$01
	sta $48
	ldx SpriteBuf1+sy
	dex
	dex
	stx SpriteBuf1+sy
	
	lda $401;check if high enough
	cmp #$D0
	bcc _checkIfHighEnough
	;lda $46
	;cmp #$01
	;bne _beginFirstBounce
	;lda #$00
	;sta $44
	;lda #%00110000
	;sta SpriteBuf1+spriority
	bra _notFinishedDying
	
	_checkIfHighEnough:
	lda #$01
	sta $46
	lda #$00
	sta $48
	jmp InfiniteLoop
	_removeDeathFlag:
	lda #$00
	sta $44
	stz $46
	stz $48
	RTS
;=================================================================================
DetermineIfUpOrDown:
	lda $48
	cmp #$01
	beq _endDetUoD
	ldx SpriteBuf1+sy
	inx
	inx
	inx
	stx SpriteBuf1+sy
	bra _endDetUoD
	
	_endDetUoD:
	
	RTS
;================================================================================
IncrementFrameSubRoutine:
	inc	FrameWait
	lda	FrameWait
	cmp	#$06
	bne	_endBirdDie

	lda	CurrentFrame
	and	#$F0
	sta	FrameWait
	lda	CurrentFrame
	clc
	adc	#$04
	and	#$0C
	adc	FrameWait
	sta	CurrentFrame
	inc	FrameNum

	stz	FrameWait
	RTS ; changed all the bra to jsl
;==========================================================================================
;- Scoring -

;==========================================================================================
HalfwayDownwardSpeed:
	ldx SpriteBuf1+sy;I have no idea just wtf is going on here but it kind of works
	inx
	stx SpriteBuf1+sy
	lda #$3A
	cmp #$00
	beq _GoDownHalf
	bra _GoDownNotYet
	_GoDownHalf:
	ldx SpriteBuf1+sy
	inx
	stx SpriteBuf1+sy
	lda #$01
	sta $3A
	bra _endHDS
	_GoDownNotYet:
	stz $3A
	bra _endHDS
	
	_endHDS:
	
		RTS
;==========================================================================================
GoDownFast:
	lda $2C
	cmp #$03
	bcc _executeDown
	bra _endGoDownFast

_executeDown:
	ldx SpriteBuf1+sy
	inx
	stx SpriteBuf1+sy
	
	lda #$31;change "sprite selection" to the 2nd selection
	sta SpriteBuf1+spriority
	lda	CurrentFrame
	and	#$F0
	cmp	#$00
	beq	IncrementFrameWarp
	lda	#$00
	sta	CurrentFrame
	lda #$30;change "sprite selection" back to the 1st selection
	sta SpriteBuf1+spriority
	jmp _done
	IncrementFrameWarp:
	jmp IncrementFrame
	
	_endGoDownFast:
	
	RTS
;==========================================================================================
PipesGoLeft:
	lda $44
	cmp #$01
	beq _end
	dec Pipe1Sprite+sx;$0404
	dec Pipe2Sprite+sx;$0408
	dec Pipe3Sprite+sx;$040C
	dec Pipe4Sprite+sx;$0410
	dec Pipe5Sprite+sx;$0414
	dec Pipe6Sprite+sx;$0418
	dec Pipe7Sprite+sx;$041C
	dec Pipe8Sprite+sx;$0420
	dec Pipe9Sprite+sx;$0424
	dec Pipe10Sprite+sx;$0428
	dec Pipe11Sprite+sx;$042C
	;that was the first column, now for the second column
	;--------------------------------------------------
	lda Pipe1Sprite+sx;$0404
	cmp #$FE
	beq _raisePipeC1
	bra _end
_raisePipeC1:
	lda Pipe1Sprite+sy;$0405
	cmp #$64
	bcc _lowerPipeOne
	sec
	sbc #$20
	sta Pipe1Sprite+sy;$0405
	lda Pipe2Sprite+sy;$0409
	sec
	sbc #$20
	sta Pipe2Sprite+sy;$0409
	lda Pipe3Sprite+sy;$040D
	sec
	sbc #$20
	sta Pipe3Sprite+sy;$040D
	lda Pipe4Sprite+sy;$0411
	sec
	sbc #$20
	sta Pipe4Sprite+sy;$0411
	;dec $0405
	;dec $0409
	;dec $040D
	;dec $0411
	;clc
	;adc #$20
	;sta $34
	;lda #(Pipe1YPOS+70)
	;sta $0405
	;lda #(Pipe1YPOS+102)
	;sta $0409;
	;lda #(Pipe1YPOS-4)
	;sta $040D;
	;lda #(Pipe1YPOS-36)
	;sta $0411;
	bra _end
_lowerPipeOne:
	lda Pipe1Sprite+sy;$0405
	clc
	adc #$40
	sta Pipe1Sprite+sy;$0405
	lda Pipe2Sprite+sy;$0409
	clc
	adc #$40
	sta Pipe2Sprite+sy;$0409
	lda Pipe3Sprite+sy;$040D
	clc
	adc #$40
	sta Pipe3Sprite+sy;$040D
	lda Pipe4Sprite+sy;$0411
	clc
	adc #$40
	sta Pipe4Sprite+sy;$0411
	bra _end
	
_end:

	RTS

	
.DEFINE FrameNum $12		

VBlank:
	rep #$30		;A/Mem=16bits, X/Y=16bits
	phb
	pha
	phx
	phy
	phd

	sep #$20		; mem/A = 8 bit, X/Y = 16 bit
	JSR PipesGoLeft

	;*********transfer sprite data
	
	;stz $2102
    ;stz $2103           ; Set OAM address to 0

    ;ldy #$0400          ; Writes #$00 to $4300, #$04 to $4301
    ;sty $4300           ; CPU -> PPU, auto inc, $2104 (OAM write)
    ;stz $4302
    ;stz $4303
    ;lda #$7E
    ;sta $4304           ; CPU address 7E:0000 - Work RAM
    ;ldy #$0220
    ;sty $4305           ; #$220 bytes to transfer
    ;lda #$01
    ;sta $420B

	stz $2102		; set OAM address to 0
	stz $2103

	LDY #$0400
	STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM data write)
	LDY #$0400
	STY $4302	; source offset
	LDY #$0220
	STY $4305		; number of bytes to transfer
	LDA #$7E
	STA $4304		; bank address = $7E  (work RAM)
	LDA #$01
	STA $420B		;start DMA transfer
	
	;*********transfer sprite2 data

	;lda #$01
	;sta $2102		; set OAM address to 0
	;lda #$01
	;sta $2103

	;LDY #$404
	;STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM data write)
	;LDY #$404
	;STY $4302		; source offset
	;LDY #$0220
	;STY $4305		; number of bytes to transfer
	;LDA #$7E
	;STA $4304		; bank address = $7E  (work RAM)
	;LDA #$01
	;STA $420B		;start DMA transfer

	;*********transfer BG2 data
	LDA #$00
	STA $2115		;set up VRAM write to write only the lower byte

	LDX #$5800
	STX $2116		;set VRAM address to BG3 tile map

	LDY #$1800
	STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2118 (Lowbyte of VRAM write)
	LDY #$0000
	STY $4302		; source offset
	LDY #$0400
	STY $4305		; number of bytes to transfer
	LDA #$7F
	STA $4304		; bank address = $7F  (work RAM)
	LDA #$01
	STA $420B		;start DMA transfer

	;update the map co-ordinates
	lda MapX
	sta $210D
	lda MapX+1
	sta $210D

	lda MapY
	sta $210E
	lda MapY+1
	sta $210E
	;-------------------------------------------------
	;all this stuff below makes the pipes go left
	;ldx $404
	;dex
	;stx $404
	;ldx $408
	;dex
	;stx $408
	;ldx $40C
	;dex
	;stx $40C
	;ldx $410
	;dex
	;stx $410
	;that was the first column, now for the second column

	;update the joypad data
	JSR GetInput

	lda $4210		;clear NMI Flag

	REP #$30		;A/Mem=16bits, X/Y=16bits
	
	inc FrameNum
	PLD 
	PLY 
	PLX 
	PLA 
	PLB 
      RTI
	  

;End of demo Main code

;============================================================================
; SetupVideo -- Set the video mode for the demo
;----------------------------------------------------------------------------
; In: None
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
SetupVideo:
	php

	rep #$10		;A/mem = 8bit, X/Y=16bit
	sep #$20
      
	lda #$A3		;Sprites 32x32 or 64x64, character data at $6000 (word address)
      sta $2101         

	lda #$04		;Set video mode 4, 8x8 tiles (256 color BG1, 4 color BG2)
      sta $2105         

	lda #$03		;Set BG1's Tile Map VRAM offset to $0000 (word address)
      sta $2107		;   and the Tile Map size to 64 tiles x 64 tiles

	lda #$52		;Set BG1's Character VRAM offset to $2000 (word address)
      sta $210B		;Set BG2's Character VRAM offset to $5000 (word address)

	lda #$58		;Set BG2's Tile Map VRAM offset to $5800 (word address)
      sta $2108		;   and the Tile Map size to 32 tiles x 32 tiles

	lda #$13		;Turn on BG1 and BG2 and Sprites
      sta $212C

      lda #$0F		;Turn on screen, full brightness
      sta $2100		

	lda #$FF		;Scroll BG2 down 1 pixel
	sta $2110
	sta $2110         

	plp
	rts

.ENDS

;==========================================================================================

.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

;Map data
BackgroundMap:
	.INCBIN ".\\Pictures\\mymap.map"

;Color data
BG_Palette:
	.INCBIN ".\\Pictures\\mymap.clr"
	.INCBIN ".\\Pictures\\flappy2.clr"
	.INCBIN ".\\Pictures\\biker.clr"
Sprite2:
	.INCBIN ".\\Pictures\\biker.pic"	
SpriteTiles:
	.INCBIN ".\\Pictures\\flappy2.pic"

ASCIITiles:
	.INCBIN ".\\Pictures\\ascii.pic"

.ENDS

;==========================================================================================

.BANK 4 SLOT 0
.ORG 0
.SECTION "BG_CharacterData"

;character data
BackgroundPics:
	.INCBIN ".\\Pictures\\mymap.pic"
.ENDS

;==========================================================================================
