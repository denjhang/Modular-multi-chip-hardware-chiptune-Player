
; �g�p�A�Z���u��
;   wla-spc700.exe v9.5
;   wlalink.exe v5.7

.MEMORYMAP
SLOTSIZE $0200
DEFAULTSLOT 0
SLOT 0 $0000
.ENDME

.ROMBANKMAP
BANKSTOTAL 1
BANKSIZE $0200
BANKS 1
.ENDRO

.EMPTYFILL $ff


; �������W�X�^
.define	Control		$f1
.define	DspAddr		$f2
.define	DspData		$f3
.define	Port0		$f4
.define	Port1		$f5
.define	Port2		$f6
.define	Port3		$f7
.define	PortControl	$f8
.define	PortData	$f9
.define	Timer0		$fa
.define	Timer1		$fb
.define	Timer2		$fc
.define	Counter0	$fd
.define	Counter1	$fe
.define	Counter2	$ff


	; �w�b�_
	.org	$0000
start:
	.db	"psl", $1a
	.dw	$0001

	.org	$0020
	.dw	start
	.dw	spc_regpc - start
	.dw	ipl1 - start
	.dw	spc_port0 - start
	.dw	ipl2end - start

	; IPL1
	;   $0088�`$00ef
	.org	$0088
ipl1:
	; P�t���O�N���A
	clrp

	; RAM�]���J�n�҂�
wait1:
	mov	y, Port0
	bne	wait1

	; $ffc0�`$ffff��RAM�ɐ؂�ւ�
	mov	Control, y

	; RAM�]���i$0100�`$ffff�j
loop1:
	cmp	y, Port0
	bne	check1

	mov	x, #Port1
loop1b:
	mov	a, (x)+
write_addr:
	mov	!stack, a
	incw	write_addr+1
	beq	end1
	cmp	x, #Port3+1
	bne	loop1b
end1:

	mov	Port0, y
	inc	y
check1:
	bpl	loop1
	cmp	y, Port0
	bpl	loop1

	; �X�^�b�N�ݒ�
	mov	x, !spc_regsp
	mov	sp, x

	; �W�����v��/���W�X�^�ݒ�
	mov	a, !spc_regpc+1
	push	a
	mov	a, !spc_regpc
	push	a
	mov	a, !spc_regpsw
	push	a
	mov	y, !spc_regy
	mov	a, !spc_regx
	push	a
	mov	a, !spc_rega
	push	a

	; Port0�`1�ݒ�
	mov	a, !spc_port1
	push	a
	mov	a, !spc_port0
	push	a

	; Port2�ݒ�
	mov	a, !spc_port2
port2_loop:
	cbne	Port2, port2_loop
	mov	Port2, a

	; Port3�ݒ�
	mov	a, !spc_port3
port3_loop:
	cbne	Port3, port3_loop
	mov	Port3, a

	;
	mov	x, Port0
	mov	Port0, x
	bra	ipl2


; SPC�̃��W�X�^���������܂��
spc_regpc:
	.dw	$0000
spc_rega:
	.db	$00
spc_regx:
	.db	$00
spc_regy:
	.db	$00
spc_regpsw:
	.db	$00
spc_regsp:
	.db	$00

; SPC�� $00f4�`$00f7�iPort0�`3�j���������܂��
spc_port0:
	.db	$00
spc_port1:
	.db	$00
spc_port2:
	.db	$00
spc_port3:
	.db	$00


	; �������W�X�^
	;   $00f0�`$00ff
	.org	$00f0

	; �X�^�b�N
	;   $0100�`$01ff
	.org	$0100
stack:

	; IPL2
	;   $0100�`ipl2end
ipl2:
	; RAM�]���i$0000�`$00ff�j�ADSP���W�X�^�ݒ�
loop2:
	cmp	x, Port0
	beq	loop2
	mov	x, Port0
	mov	a, Port1
	mov	Port0, x
	mov	(x), a
	cmp	x, #Control
	bne	loop2

	; Port0�ݒ�
	pop	a
port0_loop:
	cbne	Port0, port0_loop
	mov	Port0, a

	; Port1�ݒ�
	pop	a
port1_loop:
	cbne	Port1, port1_loop
	mov	Port1, a

	; ���W�X�^�ݒ�
	pop	a
	pop	x
ipl2end:
	; PSW�ݒ�/��PC�ɃW�����v
	.db	$7f	; reti

