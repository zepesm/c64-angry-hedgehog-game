/*
    Angry Hedgehog
    @code Zephyr
    2022, Inflexion Development
*/

.segmentdef Main [start=$0800]
#import "_system.asm"
#import "_macros.asm"

// Defs
.const DEFAULT_TUNE = 0
.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328"
.const BACKGROUND_COLOR = $09
.const TITLE_COLOR = $1
.const DEFAULT_INDEX_COLOR = $1

// Zeropage storage
.const currentTune = $10
.const currentIndexColor = $11
.const currentTitleColor = $12
.const indexColorFading_index = $13
.const titleColorFading_index = $14
// $15 -> $1c
.const starFade_indexes = $15

// Modules memory layout
.const CODE             = $0810
.const MUSIC			= $1000
.const CODE_TABLES      = $3000
.const EW_LOGO_SPRITES  = $3500
.const BITMAP			= $4000
.const SCREEN			= $6000
.const COLORRAM			= $6400
.const SPRITES			= $6800

.const IMG_TITLE        = $8000
.const IMG_GAME         = $9e70

// Assets
.const mainPicture = LoadBinary("assets/gfx/hedgehog.kla", KOALA_TEMPLATE)
.const titleScreenPacked = LoadBinary("assets/gfx/hedgehog.kla.b2")
.const music = LoadSid("assets/music/Hedgehog-the-Hero.sid")
.const sprites = LoadPicture("assets/gfx/sprites.png",List().add($000000, $ffffff))
.const EWlogoSpritesFile = LoadPicture("assets/gfx/logo_esm_wrath.png",List().add($000000, $ffffff))

// Sprite pointers
.var titleSprite_1_num =(titleSprite_1-BITMAP)/64
.var titleSprite_2_num =(titleSprite_2-BITMAP)/64
.var titleSprite_3_num =(titleSprite_3-BITMAP)/64
.var titleSprite_playing_1_num =(titleSprite_playing_1-BITMAP)/64
.var titleSprite_playing_2_num =(titleSprite_playing_2-BITMAP)/64
.var titleSprite_playing_3_num =(titleSprite_playing_3-BITMAP)/64
.var indexSprite_1_num =(indexSprite_1-BITMAP)/64
.var indexSprite_2_num =(indexSprite_2-BITMAP)/64
.var indexSprite_3_num =(indexSprite_3-BITMAP)/64
.var starSprite_num =(starSprite-BITMAP)/64

.var starColorTabLen = 32 + 64

// Sprite initial positions
.const indexSpriteX = $84
.const indexSpriteY = $70
.const titleSpriteX = 132
.const titleSpriteY = $f4
.const starSpriteX = 255
.const starSpriteY = $80



.file [name="game.prg", segments="Main", modify="BasicUpstart", _start=start]
.segment Main

* = CODE "Code"		
start:		
    //        jsr intro_EW_logo
player_start:
            sei
            lda #$35
            sta $01
            jsr initPlayer
            jsr titles
            :SetScreenAndChar($6000,$4000)
            :SetVICBank(1)
            :setIrq(irq,$33)
            jsr initTune
    
            lda #starColorTabLen
            sta $30

            :rasterWait($33)
            cli

!loop:
            jsr handleKeyboard            
            jmp !loop-

//---------------------------------------------------------
titles: 
            lda #>BITMAP
            sta $03
            lda #<BITMAP
            sta $02
            ldx #>titleScreen
            ldy #<titleScreen
            jsr decrunch
            rts

//---------------------------------------------------------
// IRQs
//---------------------------------------------------------
irq:

			:enterIrq()
            lda $d011
            ora #$08
            sta $d011


            lda #%01010101
            sta sprPriority


            jsr handleStars
		    :setIrq(irq_index,$6a)
			:exitIrq()

irq_index:
			:enterIrq()
            lda #$ff
            sta sprOnOff
            lda #$00
            sta sprPriority

            jsr handleIndexSprites
			jsr music.play

		    :setIrq(irq_title,$e9)
			:exitIrq()



irq_title:
			:enterIrq()
            jsr handleTitleSprites
			:setIrq(irq_bottom_border,$f8)
			:exitIrq()

irq_bottom_border:
			:enterIrq()
			lda $d011
			and #$f7
			sta $d011
			:setIrq(irq, $0)

			:exitIrq()

last_irq: 
			:enterIrq()
            lda #$00 
            sta sprOnOff
			:setIrq(irq, $33)
			:exitIrq()

//---------------------------------------------------------
// IRQ-based routines
//---------------------------------------------------------
handleIndexSprites: 


            ldx indexColorFading_index
            cpx #$1f
            bmi !+
            jmp handleIndexSprites_end

!:            
            inc indexColorFading_index
            lda FADE_OUT_colortable,X
            sta currentIndexColor

            ldx currentTune
			ldy LUT_indexSprites,x
			sty screenRAM+$03f8
            iny
			sty screenRAM+$03f9
            iny
			sty screenRAM+$03fa
            iny
			sty screenRAM+$03fb

            :setSpritePosition(0, indexSpriteX, indexSpriteY)
            :setSpritePosition(1, indexSpriteX + 24 * 2, indexSpriteY)
            :setSpritePosition(2, indexSpriteX, indexSpriteY + 21 * 2)
            :setSpritePosition(3, indexSpriteX + 24 * 2, indexSpriteY + 21 * 2)

            lda #%00001111
            sta sprXDouble
            sta sprYDouble

            lda #%11110000
            sta sprMulti

            lda currentIndexColor
            sta spr1Col
            sta spr2Col
            sta spr3Col
            sta spr4Col
            rts

handleIndexSprites_end:
            lda #%11110000
            sta sprOnOff
            rts


handleTitleSprites:
            lda #$ff
            sta sprOnOff

            ldx currentTune
			ldy LUT_titleSprites,x
			sty screenRAM+$03f8
            iny
			sty screenRAM+$03f9
            iny
			sty screenRAM+$03fa
            iny
			sty screenRAM+$03fb
            ldy LUT_titleSprites_playing,x
			sty screenRAM+$03fc
            iny
			sty screenRAM+$03fd
            iny
			sty screenRAM+$03fe
            iny
			sty screenRAM+$03ff

            :setSpritePosition(0, titleSpriteX, titleSpriteY + 21)
            :setSpritePosition(1, titleSpriteX + (24 * 1), titleSpriteY + 21)
            :setSpritePosition(2, titleSpriteX + (24 * 2), titleSpriteY + 21)
            :setSpritePosition(3, titleSpriteX + (24 * 3), titleSpriteY + 21)

            :setSpritePosition(4, titleSpriteX, titleSpriteY + 6)
            :setSpritePosition(5, titleSpriteX + (24 * 1), titleSpriteY  + 6)
            :setSpritePosition(6, titleSpriteX + (24 * 2), titleSpriteY + 6)
            :setSpritePosition(7, titleSpriteX + (24 * 3), titleSpriteY + 6)

            ldx titleColorFading_index
            cpx #$10
            beq !+
            inc titleColorFading_index
            lda FADE_IN_colortable,X
            sta currentTitleColor

!:

            lda currentTitleColor
            sta spr1Col
            sta spr2Col
            sta spr3Col
            sta spr4Col
            sta spr5Col
            sta spr6Col
            sta spr7Col
            sta spr8Col

            lda #$00
            sta sprXDouble
            sta sprYDouble
            sta sprMulti
            rts

handleStars: 

            lda currentTune
            cmp #$02
            beq !+
            lda #$00
            sta sprOnOff
            rts
!:
            lda #$ff
            sta sprOnOff

            lda #starSprite_num
            sta screenRAM+$03f8
			sta screenRAM+$03f9
			sta screenRAM+$03fa
			sta screenRAM+$03fb
            sta screenRAM+$03fc
			sta screenRAM+$03fd
			sta screenRAM+$03fe
			sta screenRAM+$03ff

            :setSpritePosition(0, 34, $35)
            :setSpritePosition(1, 320, $51)
            :setSpritePosition(2, 64, $39)
            :setSpritePosition(3, 280, $36)
            :setSpritePosition(4, 310, $3e)
            :setSpritePosition(5, 128, $40)
            :setSpritePosition(6, 44, $45)
            :setSpritePosition(7, 50, $50)

            ldx #$07
!:          ldy (starFade_indexes),x
            lda PULSE_colortable,y
            sta spr1Col,x

            inc (starFade_indexes),x
            lda (starFade_indexes),x
            cmp #starColorTabLen
            bne handleStars_skip_reset
            lda #$00
            sta (starFade_indexes),x
handleStars_skip_reset:
            dex
            bpl !-

            



            rts
//---------------------------------------------------------
// MAIN-LOOP-based routines
//---------------------------------------------------------
handleKeyboard:
			// Read keyboard
			jsr readKey
			cmp #$07	// 1
			beq key1
			cmp #$37	// 2
			beq key2
			cmp #$01	// 3
			beq key3
			rts

key1:		ldx #$00
			cpx currentTune
			beq endKeyRead
			stx currentTune
			jsr initTune
            rts
			
key2:		ldx #$01
			cpx currentTune
			beq endKeyRead
			stx currentTune
			jsr initTune
            rts

key3:		ldx #$02
			cpx currentTune
			beq endKeyRead
			stx currentTune
			jsr initTune

endKeyRead: rts            

//---------------------------------------------------------
// Utility routines
//---------------------------------------------------------
initStars:
            ldx #$07
!:           lda PULSE_stars_startIndexes,x
            sta (starFade_indexes),x
            dex
            bne !-
            rts

initPlayer:

            lda #DEFAULT_TUNE
            sta currentTune

            lda #$7f
            sta $dc0d
            lda $dc0d
            lda #$01
            sta $d01a
            asl $d019
            lda #$00
            sta $d012
            lda #$3b
            sta $d011

            lda #BACKGROUND_COLOR
            sta $d020
            sta $d021

            ldx #$00
    !:  	lda colorRAM,x
            sta $d800,x
            lda colorRAM+$0100,x
            sta $d900,x
            lda colorRAM+$0200,x
            sta $da00,x
            lda colorRAM+$0300,x
            sta $db00,x
            dex
            bne !-

            lda #$18
            sta $d016
            lda #$00
            sta sprPriority

            lda #$ff
            sta $d015
            lda #$00
            sta $d017


            lda #$7f
            sta $dc0d
            lda $dc0d

            lda #$01
            sta $d01a

            lda #%10001000
            sta $d010

            lda #$00
            sta BITMAP + $3fff

            lda #DEFAULT_INDEX_COLOR
            sta currentIndexColor

            lda #$00
            sta indexColorFading_index
            sta titleColorFading_index

            jsr initStars
            rts

initTune: 
            lda #$00
            sta indexColorFading_index
            sta titleColorFading_index
            lda currentTune
            jsr music.init
            rts

//---------------------------------------------------------
// Data / Assets
//---------------------------------------------------------

* = CODE_TABLES "Additional Code + Tables"

// Additional code imports
#import "__keyboard.asm"
#import "__intro-ew-logo.asm"
#import "__byteboozer.asm"


LUT_indexSprites: .byte indexSprite_1_num, indexSprite_2_num, indexSprite_3_num
LUT_titleSprites: .byte titleSprite_1_num, titleSprite_2_num, titleSprite_3_num
LUT_titleSprites_playing: .byte titleSprite_playing_1_num, titleSprite_playing_2_num, titleSprite_playing_3_num

FADE_OUT_colortable: .byte $01,$01,$0d,$0d,$07,$07,$0f,$0f,$03,$03,$05,$05,$0a,$0a,$0c,$0c,$0e,$0e,$08,$08,$04,$04,$02,$02,$0b,$0b,$06,$06,$09,$09,$00,$00
FADE_IN_colortable: .byte $09,$09,$09,$0b,$0b,$0b,$0b,$0b,$05,$05,$05,$05,$07,$07,$07,$01

PULSE_colortable: 
.byte $0,$0,$0,$0b,$0b,$0b,$0b,$0b,$05,$05,$05,$05,$07,$07,$07,$01,$07,$07,$07,$05,$05,$05,$05,$0b,$0b,$0b,$0b,$0b,$0,$0,$0,$0
.fill 64, 0

PULSE_stars_startIndexes: .byte 55,12,60,67,32,45,0,18
//---------------------------------------------------------

* = MUSIC "Music"
.fill music.size, music.getData(i)


* = EW_LOGO_SPRITES "EW Logo Sprites"

logoSprites:
    :cutHiresSprite(EWlogoSpritesFile,0,0)
    :cutHiresSprite(EWlogoSpritesFile,24,0)
    :cutHiresSprite(EWlogoSpritesFile,48,0)
    :cutHiresSprite(EWlogoSpritesFile,0,21)
    :cutHiresSprite(EWlogoSpritesFile,24,21)
    :cutHiresSprite(EWlogoSpritesFile,48,21)
    :cutHiresSprite(EWlogoSpritesFile,0,42)
    :cutHiresSprite(EWlogoSpritesFile,24,42)
    :cutHiresSprite(EWlogoSpritesFile,48,42)
//---------------------------------------------------------

* = BITMAP "Bitmap"
bitmap:    // .fill mainPicture.getBitmapSize(), mainPicture.getBitmap(i)

* = SCREEN "ScreenRAM"
screenRAM:  .fill mainPicture.getScreenRamSize(), mainPicture.getScreenRam(i)
 
 * = COLORRAM "ColorRAM"
 colorRAM:  .fill mainPicture.getColorRamSize(), mainPicture.getColorRam(i)

//---------------------------------------------------------
 
 * = SPRITES "Sprites"

starSprite:
    :cutHiresSprite(sprites, 4 * 24, 21 * 0)

titleSprite_playing_1:
    :cutHiresSprite(sprites, 0 * 24, 21 * 3)
    :cutHiresSprite(sprites, 1 * 24, 21 * 3)
    :cutHiresSprite(sprites, 2 * 24, 21 * 3)
    :cutHiresSprite(sprites, 3 * 24, 21 * 3)
titleSprite_playing_2:
    :cutHiresSprite(sprites, 0 * 24, 21 * 4)
    :cutHiresSprite(sprites, 1 * 24, 21 * 4)
    :cutHiresSprite(sprites, 2 * 24, 21 * 4)
    :cutHiresSprite(sprites, 3 * 24, 21 * 4)
titleSprite_playing_3:
    :cutHiresSprite(sprites, 0 * 24, 21 * 5)
    :cutHiresSprite(sprites, 1 * 24, 21 * 5)
    :cutHiresSprite(sprites, 2 * 24, 21 * 5)
    :cutHiresSprite(sprites, 3 * 24, 21 * 5)

titleSprite_1:
    :cutHiresSprite(sprites, 0 * 24, 0)
    :cutHiresSprite(sprites, 1 * 24, 0)
    :cutHiresSprite(sprites, 2 * 24, 0)
    :cutHiresSprite(sprites, 3 * 24, 0)
titleSprite_2:
    :cutHiresSprite(sprites, 0 * 24, 21)
    :cutHiresSprite(sprites, 1 * 24, 21)
    :cutHiresSprite(sprites, 2 * 24, 21)
    :cutHiresSprite(sprites, 3 * 24, 21)
titleSprite_3:
    :cutHiresSprite(sprites, 0 * 24, 21 * 2)
    :cutHiresSprite(sprites, 1 * 24, 21 * 2)
    :cutHiresSprite(sprites, 2 * 24, 21 * 2)
    :cutHiresSprite(sprites, 3 * 24, 21 * 2)

indexSprite_1:
    :cutHiresSprite(sprites, 0 * 24, 7 * 21)
    :cutHiresSprite(sprites, 1 * 24, 7 * 21)
    :cutHiresSprite(sprites, 0 * 24, 8 * 21)
    :cutHiresSprite(sprites, 1 * 24, 8 * 21)
indexSprite_2:
    :cutHiresSprite(sprites, 2 * 24, 7 * 21)
    :cutHiresSprite(sprites, 3 * 24, 7 * 21)
    :cutHiresSprite(sprites, 2 * 24, 8 * 21)
    :cutHiresSprite(sprites, 3 * 24, 8 * 21)
indexSprite_3:
    :cutHiresSprite(sprites, 4 * 24, 7 * 21)
    :cutHiresSprite(sprites, 5 * 24, 7 * 21)
    :cutHiresSprite(sprites, 4 * 24, 8 * 21)
    :cutHiresSprite(sprites, 5 * 24, 8 * 21)


* = IMG_TITLE "Title screen (packed)"
titleScreen:     .fill titleScreenPacked.getSize(), mainPicture.get(i)

* = IMG_GAME "Game screen (packed)"
gameScreen:     .fill titleScreenPacked.getSize(), mainPicture.get(i)