//================================
readKey:

	lda #$0
	sta $dc03	// port b ddr (input)
	lda #$ff
	sta $dc02	// port a ddr (output)

	lda #$00
	sta $dc00	// port a
	lda $dc01   // port b
	cmp #$ff
	beq nokey
	// got column
	tay

	lda #$7f
	sta nokey2+1
	ldx #8
nokey2:
	lda #0
	sta $dc00	// port a

	sec
	ror nokey2+1
	dex
	bmi nokey

	lda $dc01       // port b
	cmp #$ff
	beq nokey2

	// got row in X
	txa
	ora columnTab,y
	sec

	sta $11
	rts

nokey:
	clc
	rts

columnTab:

	.for (var count=0; count<256; count++)
	{
		.if (count == $7f) .byte $70
		else .if (count == $bf) .byte $60
		else .if (count == $df) .byte $50
		else .if (count == $ef) .byte $40
		else .if (count == $f7) .byte $30
		else .if (count == $fb) .byte $20
		else .if (count == $fd) .byte $10
		else .if (count == $fe) .byte $00
		else .byte $ff
	}
