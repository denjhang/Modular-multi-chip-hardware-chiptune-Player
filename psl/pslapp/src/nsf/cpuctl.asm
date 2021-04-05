
; �g�p�A�Z���u��
;   nesasm.exe v2.51

	.list
CPUCTL:	equ	0

;
	.data
	.org	$0000

; �w�b�_
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


; NSF�̃w�b�_���������܂��
; ��128�o�C�g
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
	; IRQ���荞�݋֎~
	sei
	; �ʏ탂�[�h
	cld

	; VBLANK���荞�ݒ�~
	lda	#$00
	sta	$2000

;	;
;	lda	#$24
;	pha
;	plp

	; �X�^�b�N�ݒ�
	ldx	#$ff
	txs

	; ROM�������݋֎~/�g�������}�X�N����
	lda	#$00
	sta	$3800
	; ����������1
	jsr	init_sound

	; RAM������
	jsr	clear_ram

	; �o���N���W�X�^������
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

	; rp2c33���g����Ȃ�RAM2�����������Ȃ�
	lda	nsfheader+$7b
	and	#$04
	bne	ram2_skip
	; RAM2������
	jsr	clear_ram2
ram2_skip:

	; �X�^�b�N������
	; ��$0100�`$01ff
	lda	#$00
	ldx	#$00
loop_stack:
;	pha
	sta	$0100, x
	inx
	bne	loop_stack

	; ����������2
	jsr	init_sound_2
	; ROM�������݋֎~/�g�������}�X�N�ݒ�
	lda	nsfheader+$02
	and	#$7f
	sta	$3800

	; PAL/NTSC�ݒ�
	lda	nsfheader+$7a
	and	#$01
	tax
	; �Đ�����Ȕԍ�
	ldy	nsfheader+$07
	dey
	tya
call_init:
	; INIT���Ă�
	jsr	$0000

	; ROM�������ݐݒ�/�g�������}�X�N�ݒ�
	lda	nsfheader+$02
	sta	$3800
	; VBLANK�t���O�N���A
	lda	$2002

loop_play:
	jsr	wait_1vblank
call_play:
	; PLAY���Ă�
	jsr	$0000
	; �J��Ԃ�
	jmp	loop_play


wait_1vblank:
	pha
loop_1vblank:
	; �t���O�ǂݍ���
	lda	$2002
	; STOP�t���O��1�Ȃ�Đ���~
	ror	a
	bcs	stop
	; VBLANK�t���O��1�ɂȂ�܂ŌJ��Ԃ�
	and	#$40
	beq	loop_1vblank
	pla
	rts

stop:
	; ����������1
	jsr	init_sound

	;
	ldx	#$f0
loop_keyoff:
	lda	$2002
	; VBLANK�t���O��1�ɂȂ�܂ŌJ��Ԃ�
	rol	a
	bcc	loop_keyoff
	inx
	bne	loop_keyoff

	; ����������2
	jsr	init_sound_2

loop_stop:
	; �t���O�ǂݍ���
	lda	$2002
	; STOP�t���O��1�Ȃ�J��Ԃ�
	ror	a
	bcs	loop_stop
	jmp	loop_1vblank

	.include	"define.inc"


; ���荞�݃x�N�^
; ��$fffa�`$ffff�ɔz�u�����
	.org	$3ffa

	dw	NMI
	dw	RESET
	dw	IRQ

