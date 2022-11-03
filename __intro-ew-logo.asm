.const 		logoXPos=148
.const 		logoYPos=120
.var        logoSprites_num =(logoSprites)/64

intro_EW_logo:
			sei
			lda #BACKGROUND_COLOR
			sta $d020
			sta $d021
			ldx #$00
			lda #$20
!:			sta $0400,x
			sta $0500,x
			sta $0600,x
			sta $0700,x
			dex
			bne !-

            lda #%01111111
            sta $d015
            lda #$00
            sta $d017
            sta $d01c
            sta $d01d

			ldy #$00
intro_EW_logo_begg:		
            lda #$00
!:			cmp $d012
			bne !-

			lda EW_logoFadetab,y
			sta spr1Col
			sta spr2Col
			sta spr3Col
			sta spr4Col
			sta spr5Col
			sta spr6Col
			sta spr7Col

			ldx #logoSprites_num
			:setSprite($0400,0,logoXPos,logoYPos)
			inx
			:setSprite($0400,1,logoXPos+24,logoYPos)
			inx
			:setSprite($0400,2,logoXPos+48,logoYPos)
			inx
			:setSprite($0400,3,logoXPos,logoYPos+21)
			inx
			:setSprite($0400,4,logoXPos+24,logoYPos+21)
			inx
			:setSprite($0400,5,logoXPos+48,logoYPos+21)

			lda #logoYPos+22
!:			cmp $d012
			bne !-
			inx
			:setSprite($0400,0,logoXPos,logoYPos+42)
			inx
			:setSprite($0400,1,logoXPos+24,logoYPos+42)
			inx
			:setSprite($0400,2,logoXPos+48,logoYPos+42)

			iny
			beq intro_EW_logo_end
			jmp intro_EW_logo_begg
intro_EW_logo_end:
            rts

EW_logoFadetab:
			.fill 50,$09
			.byte $0b, $0b, $0b, $0b
			.byte $0c, $0c, $0c, $0c
			.byte $0f, $0f, $0f, $0f
			.fill 100, $01
			.byte $0f, $0f, $0f, $0f
			.byte $0c, $0c, $0c, $0c
			.byte $0b, $0b, $0b, $0b
			.fill 82,$09

