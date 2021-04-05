
	.code
	.org	(*+$ff)&$ff00

clear_ram:
	; RAM‰Šú‰»
	; ¦$0000`$00ff, $0200`$07ff
	lda	#$00
	ldx	#$00
loop_ram:
	sta	<$00, x
	sta	$0200, x
	sta	$0300, x
	sta	$0400, x
	sta	$0500, x
	sta	$0600, x
	sta	$0700, x
	inx
	bne	loop_ram
	rts


clear_ram2:
	; RAM2‰Šú‰»
	; ¦$6000`$7fff
	lda	#$00
	ldx	#$00
loop_ram2:
	sta	$6000, x
	sta	$6100, x
	sta	$6200, x
	sta	$6300, x
	sta	$6400, x
	sta	$6500, x
	sta	$6600, x
	sta	$6700, x
	sta	$6800, x
	sta	$6900, x
	sta	$6a00, x
	sta	$6b00, x
	sta	$6c00, x
	sta	$6d00, x
	sta	$6e00, x
	sta	$6f00, x
	sta	$7000, x
	sta	$7100, x
	sta	$7200, x
	sta	$7300, x
	sta	$7400, x
	sta	$7500, x
	sta	$7600, x
	sta	$7700, x
	sta	$7800, x
	sta	$7900, x
	sta	$7a00, x
	sta	$7b00, x
	sta	$7c00, x
	sta	$7d00, x
	sta	$7e00, x
	sta	$7f00, x
	inx
	bne	loop_ram2
	rts


init_sound:
	; ‰¹Œ¹‰Šú‰»1
	jsr	init_cpu
	jsr	init_5b
	jsr	init_163
	jsr	init_mmc5
	jsr	init_rp2c33
	jsr	init_vrc7
	jsr	init_vrc6
	rts

init_sound_2:
	; ‰¹Œ¹‰Šú‰»2
	jsr	init_cpu_2
	jsr	init_mmc5_2
	jsr	init_vrc7_2
	rts


init_cpu:
	; CPU‰Šú‰»1
	lda	#$10
	sta	$4000
	lda	#$00
	sta	$4001
	sta	$4002
	lda	#$18
	sta	$4003
	lda	#$10
	sta	$4004
	lda	#$00
	sta	$4005
	sta	$4006
	lda	#$18
	sta	$4007
	;
	lda	#$00
	sta	$4008
;	sta	$4009
	sta	$400a
	lda	#$18
	sta	$400b
	lda	#$10
	sta	$400c
	lda	#$00
	sta	$400e
	lda	#$18
	sta	$400f
	;
	lda	#$10
	sta	$4010
	lda	#$00
	sta	$4011
	lda	#$00
	sta	$4012
	sta	$4013
	rts

init_cpu_2:
	; CPU‰Šú‰»2
;	lda	#$00
;	sta	$4000
;	sta	$4003
;	sta	$4004
;	sta	$4007
;	sta	$400b
;	sta	$400c
;	sta	$400f
	;
	lda	#$00
	sta	$4017
	lda	#$0f
	sta	$4015
	rts

init_5b:
	; 5B‰Šú‰»
	.ifdef CPUCTL
	lda	#$00
	sta	$3580	; ¦$8000‚É•ÏŠ·‚³‚ê‚é
	.endif
	;
	ldx	#$08
	lda	#$00
	stx	$c000
	sta	$e000
	inx
	stx	$c000
	sta	$e000
	inx
	stx	$c000
	sta	$e000
	;
	ldx	#$07
	lda	#$3f
	stx	$c000
	sta	$e000
	;
	ldx	#$0e
	lda	#$00
	stx	$c000
	sta	$e000
	inx
	stx	$c000
	sta	$e000
	rts

init_163:
	; 163‰Šú‰»
	.ifdef CPUCTL
	lda	#$00
	sta	$3400	; ¦$e000‚É•ÏŠ·‚³‚ê‚é
	.endif
	;
	ldx	#$40
	lda	#$00
loop_init163:
	stx	$f800
	sta	$4800
	inx
	cpx	#$80
	bne	loop_init163
	;
	ldx	#$00
	lda	#$00
loop_init163_2:
	stx	$f800
	sta	$4800
	inx
	cpx	#$40
	bne	loop_init163_2
	rts

init_mmc5:
	; MMC5‰Šú‰»1
	lda	#$10
	sta	$5000
	lda	#$00
	sta	$5001
	sta	$5002
	lda	#$18
	sta	$5003
	lda	#$10
	sta	$5004
	lda	#$00
	sta	$5005
	sta	$5006
	lda	#$18
	sta	$5007
	;
	lda	#$10
	sta	$5010
	lda	#$00
	sta	$5011
	lda	#$00
	sta	$5012
	sta	$5013
	rts

init_mmc5_2:
	; MMC5‰Šú‰»2
;	lda	#$00
;	sta	$5000
;	sta	$5003
;	sta	$5004
;	sta	$5007
	;
	lda	#$00
	sta	$5017
	lda	#$03
	sta	$5015
	rts

init_rp2c33:
	; RP2C33‰Šú‰»
	lda	#$00
	sta	$4022
	sta	$4023
	lda	#$02
	sta	$4023
	;
	lda	#$2e
	sta	$4025
	lda	#$ff
	sta	$4026
	;
	lda	#$80
	sta	$4080
	lda	#$00
	sta	$4082
	lda	#$40
	sta	$4083
	lda	#$e8
	sta	$408a
	;
	lda	#$80
	sta	$4089
	ldx	#$00
	lda	#$00
loop_initrp2c33:
	sta	$4040, x
	inx
	cpx	#$40
	bne	loop_initrp2c33
	rts

init_vrc7:
	; VRC7‰Šú‰»1
	.ifdef CPUCTL
	lda	#$00
	sta	$3100	; ¦$e000‚É•ÏŠ·‚³‚ê‚é
	.endif
	;
	ldx	#$10
	lda	#$00
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	;
	ldx	#$20
	lda	#$20
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	inx
	jsr	write_vrc7
	rts

init_vrc7_2:
	; VRC7‰Šú‰»2
	ldx	#$0e
	lda	#$00
	jsr	write_vrc7
	;
	ldx	#$0f
	lda	#$ff
	jsr	write_vrc7
	lda	#$00
	jsr	write_vrc7
	rts

init_vrc6:
	; VRC6‰Šú‰»
	lda	#$00
	sta	$9000
	sta	$a000
	sta	$b000
	sta	$9001
	sta	$a001
	sta	$b001
	sta	$9002
	sta	$a002
	sta	$b002
	;
	lda	#$00	; ¦ok
;	lda	#$01	; ¦ng
;	lda	#$02	; ¦ng
;	lda	#$03	; ¦ng
;	lda	#$04	; ¦ng
;	lda	#$05	; ¦ng
;	lda	#$06	; ¦ng
;	lda	#$07	; ¦ng
;	lda	#$08	; ¦ok
	sta	$9003
	rts


write_vrc7:
	stx	$9010
	; 6, 3+2+4=9
	pha
	nop
	pla
	sta	$9030
	; 42, 3+2+(2+2+2)*6+4+6=51
	pha
	lda	#$06
loop_writevrc7:
	clc
	sbc	#$00
	bne	loop_writevrc7
	pla
	rts

