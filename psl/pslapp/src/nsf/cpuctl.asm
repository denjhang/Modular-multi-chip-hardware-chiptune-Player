
; 使用アセンブラ
;   nesasm.exe v2.51

	.list
CPUCTL:	equ	0

;
	.data
	.org	$0000

; ヘッダ
	.code
	.org	$3800

start:
	db	"psl", $1a
	dw	$0001

	.org	$3820

	dw	start
	dw	nsfheader - start
	dw	call_init+1 - start
	dw	call_play+1 - start


; NSFのヘッダが書き込まれる
; ※128バイト
	.org	$3880
nsfheader:
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


	.org	$3900
NMI:
RESET:
IRQ:
	; IRQ割り込み禁止
	sei
	; 通常モード
	cld

	; VBLANK割り込み停止
	lda	#$00
	sta	$2000

;	;
;	lda	#$24
;	pha
;	plp

	; スタック設定
	ldx	#$ff
	txs

	; ROM書き込み禁止/拡張音源マスク解除
	lda	#$00
	sta	$3800
	; 音源初期化1
	jsr	init_sound

	; RAM初期化
	jsr	clear_ram

	; バンクレジスタ初期化
	lda	nsfheader+$00
	sta	$5ff6
	lda	nsfheader+$01
	sta	$5ff7
	lda	nsfheader+$70
	sta	$5ff8
	lda	nsfheader+$71
	sta	$5ff9
	lda	nsfheader+$72
	sta	$5ffa
	lda	nsfheader+$73
	sta	$5ffb
	lda	nsfheader+$74
	sta	$5ffc
	lda	nsfheader+$75
	sta	$5ffd
	lda	nsfheader+$76
	sta	$5ffe
	lda	nsfheader+$77
	sta	$5fff

	; rp2c33が使われるならRAM2を初期化しない
	lda	nsfheader+$7b
	and	#$04
	bne	ram2_skip
	; RAM2初期化
	jsr	clear_ram2
ram2_skip:

	; スタック初期化
	; ※$0100～$01ff
	lda	#$00
	ldx	#$00
loop_stack:
;	pha
	sta	$0100, x
	inx
	bne	loop_stack

	; 音源初期化2
	jsr	init_sound_2
	; ROM書き込み禁止/拡張音源マスク設定
	lda	nsfheader+$02
	and	#$7f
	sta	$3800

	; PAL/NTSC設定
	lda	nsfheader+$7a
	and	#$01
	tax
	; 再生する曲番号
	ldy	nsfheader+$07
	dey
	tya
call_init:
	; INITを呼ぶ
	jsr	$0000

	; ROM書き込み設定/拡張音源マスク設定
	lda	nsfheader+$02
	sta	$3800
	; VBLANKフラグクリア
	lda	$2002

loop_play:
	jsr	wait_1vblank
call_play:
	; PLAYを呼ぶ
	jsr	$0000
	; 繰り返す
	jmp	loop_play


wait_1vblank:
	pha
loop_1vblank:
	; フラグ読み込み
	lda	$2002
	; STOPフラグが1なら再生停止
	ror	a
	bcs	stop
	; VBLANKフラグが1になるまで繰り返す
	and	#$40
	beq	loop_1vblank
	pla
	rts

stop:
	; 音源初期化1
	jsr	init_sound

	;
	ldx	#$f0
loop_keyoff:
	lda	$2002
	; VBLANKフラグが1になるまで繰り返す
	rol	a
	bcc	loop_keyoff
	inx
	bne	loop_keyoff

	; 音源初期化2
	jsr	init_sound_2

loop_stop:
	; フラグ読み込み
	lda	$2002
	; STOPフラグが1なら繰り返す
	ror	a
	bcs	loop_stop
	jmp	loop_1vblank

	.include	"define.inc"


; 割り込みベクタ
; ※$fffa～$ffffに配置される
	.org	$3ffa

	dw	NMI
	dw	RESET
	dw	IRQ

