#importonce

//==========================================
.macro SetScreenAndChar(screen, charset) {
	lda	#[[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
	sta	$D018
}

.macro ByteScreenAndChar(screen, charset) {
	.byte [[screen & $3FFF] / 64] | [[charset & $3FFF] / 1024]
}

//Switch to the vic bank 0..3
.macro SetVICBank(n)
{
    lda $dd00
    and #%11111100
    .if (n==0) {
        ora #%00000011
    } 
    .if (n==1) {
        ora #%00000010
    }
	.if (n==2) {
    	ora #%00000001
	}	
    sta $dd00
}

//Sets sprite position and shape in a given scren bank. X=shape, Y = currentRainFrame
.macro setSprite(screen, n,x,y) {
            stx screen+$3f8+n
            lda #x
            sta spr1X+(n*2)
            lda $d010
            and #~(1<<n)
            .if (x>255) {
                 ora #(1<<n)
            }
            sta $d010
            lda #y
            sta spr1Y+(n*2)
}

.macro setSpritePosition(spriteIndex,x,y) {
            lda #x
            sta spr1X+(spriteIndex*2)
            lda $d010
            and #~(1<<spriteIndex)
            .if (x>255) {
                 ora #(1<<spriteIndex)
            }
            sta $d010
            lda #y
            sta spr1Y+(spriteIndex*2)
}

.macro setSpritePositionFromXY8Bit(spriteIndex) {
            stx spr1X+(spriteIndex*2)
            sty spr1Y+(spriteIndex*2)
}


.macro cutMultiSprite(file, x, y)
{   .const charX = x / 8
    .for(var yPos=y; yPos < y + 21; yPos++) {
        .for(var xPos=charX; xPos < charX + 3; xPos++) {
            .byte file.getMulticolorByte(xPos, yPos)
        }
    }
    .byte $00
}

.macro cutHiresSprite(file, x, y)
{   .const charX = x / 8
    .for(var yPos=y; yPos < y + 21; yPos++) {
        .for(var xPos=charX; xPos < charX + 3; xPos++) {
            .byte file.getSinglecolorByte(xPos, yPos)
        }
    }
    .byte $00
}

//---------------------------------------------------------
//IRQs

.macro enterIrq() {
            pha
            txa
            pha
            tya
            pha
            lda $01
            pha

            lda #$35
            sta $01
}

.macro setIrq(addr, raster) {
            lda #<addr
            ldy #>addr
            sta $fffe
            sty $ffff
            lda #raster
            sta $d012
}

.macro exitIrq() {
            lsr $d019
            pla
            sta $01
            pla
            tay
            pla
            tax
            pla
            rti
}


// Frame skipper:
// executes the code after the macro once every [frames],
// otherwise jumps to [address]
.macro skipFrames(frames, address) {
    ldy count:#frames
    dey
    sty count
    jne address
    lda #frames
    sta count

    // execute the code below the macro once every x frames
}

.pseudocommand jne addr {
      beq !+
      jmp addr
!:
}

.pseudocommand jeq addr {
      bne !+
      jmp addr
!:
}

.macro ensureImmediateArgument(arg) {
	.if (arg.getType()!=AT_IMMEDIATE) .error "The argument must be immediate!"
}

.pseudocommand nop x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) nop
}

.pseudocommand waitCycles cycles {
	:ensureImmediateArgument(cycles)
	.var x = floor(cycles.getValue())
	.if (x<2) .error "Cant make a pause on " + x + " cycles"

	// Take care of odd cyclecount
	.if ([x&1]==1)
	{
        bit $00
        .eval x=x-3
	}

	// Take care of the rest
	.if (x>0)
	    :nop #x/2
}

.macro rasterWait(line) {
            lda #line
!:          cmp $d012
            bne !-
            inc $d019
}
