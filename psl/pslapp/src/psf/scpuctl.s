
; 使用アセンブラ
;   as68k.exe v1.00
;   sload.exe


	org	$000000

Vector:
	dc.l	Stack		; Reset: Initial SSP
	dc.l	Main		; Reset: Initial PC

	dc.l	Reserved	; Bus Error
	dc.l	Reserved	; Address Error
	dc.l	Reserved	; Illegal Instruction
	dc.l	Reserved	; Zero Divide
	dc.l	Reserved	; CHK Instruction
	dc.l	Reserved	; TRAPV Instruction
	dc.l	Reserved	; Privilege Violation
	dc.l	Reserved	; Trace
	dc.l	Reserved	; Line 1010 Emulator
	dc.l	Reserved	; Line 1111 Emulator
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; Format Error
	dc.l	Reserved	; Uninitialized Interrupt Vector
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; Spurious Interrupt
	dc.l	Reserved	; Level 1 Interrupt Autovector
	dc.l	Reserved	; Level 2 Interrupt Autovector
	dc.l	Reserved	; Level 3 Interrupt Autovector
	dc.l	Reserved	; Level 4 Interrupt Autovector
	dc.l	Reserved	; Level 5 Interrupt Autovector
	dc.l	Reserved	; Level 6 Interrupt Autovector
	dc.l	Reserved	; Level 7 Interrupt Autovector
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; TRAP Instruction Vectors
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)
	dc.l	Reserved	; (Unassigned, Reserved)


Reserved:
	bra	*


Main:

;;
	move.l	#$100000,a0
loop_dma:
	move.w	$0416(a0),d0
	btst	#12,d0		; dexe
	bne	loop_dma


;; mvol=$00
	clr.l	d1
	move.b	d1,$0401(a0)

;; 
	move.l	a0,a1
loop_keyoff:

;; disdl=0, efsdl=0
	move.w	$16(a1),d0
	andi.w	#$1f1f,d0
	move.w	d0,$16(a1)

;; rr=$1f
	move.w	$0a(a1),d0
	ori.w	#$001f,d0
	move.w	d0,$0a(a1)

;; kyonb=0
	move.w	(a1),d0
	andi.w	#$f7ff,d0
	move.w	d0,(a1)
;; kyonex=1
	ori.w	#$1000,d0
	move.w	d0,(a1)

	add.l	#$000020,a1
	cmp.l	#$100400,a1
	blt	loop_keyoff


;;
	move.w	#$0800,d0
loop_dsp:
	move.l	d1,$00(a0,d0.w)
	addi.w	#$0004,d0
	cmpi.w	#$0c00,d0
	blt	loop_dsp

;; 
	move.w	d1,$041e(a0)	; scieb
loop_scintr:
	move.w	$0420(a0),d0	; scipd
	andi.w	#$07ff,d0
	beq	exit_scintr
	move.w	d0,$0422(a0)	; scire
	bra	loop_scintr
exit_scintr:

	move.w	d1,$042a(a0)	; mcieb
loop_mcintr:
	move.w	$042c(a0),d0	; mcipd
	andi.w	#$07ff,d0
	beq	exit_mcintr
	move.w	d0,$042e(a0)	; mcire
	bra	loop_mcintr
exit_mcintr:

;; 
loop_midi:
	move.b	$0404(a0),d0
	btst	#3,d0		; moemp
	beq	loop_midi
	btst	#0,d0		; miemp
	bne	exit_midi
	move.b	$0405(a0),d0	; mibuf
	bra	loop_midi
exit_midi:


;; 
	move.l	#reginit_offs,a1
loop_reginit:
	move.w	(a1),d0
	bmi	exit_reginit
	move.w	d1,$00(a0,d0.w)
	add.l	#$000002,a1
	bra	loop_reginit
exit_reginit:

;; 
Loop:
	bra	Loop


	even
reginit_offs:
	dc.w	$0000,$0002,$0004,$0006,$0008,$000a,$000c,$000e,$0010,$0012,$0014,$0016
	dc.w	$0020,$0022,$0024,$0026,$0028,$002a,$002c,$002e,$0030,$0032,$0034,$0036
	dc.w	$0040,$0042,$0044,$0046,$0048,$004a,$004c,$004e,$0050,$0052,$0054,$0056
	dc.w	$0060,$0062,$0064,$0066,$0068,$006a,$006c,$006e,$0070,$0072,$0074,$0076
	dc.w	$0080,$0082,$0084,$0086,$0088,$008a,$008c,$008e,$0090,$0092,$0094,$0096
	dc.w	$00a0,$00a2,$00a4,$00a6,$00a8,$00aa,$00ac,$00ae,$00b0,$00b2,$00b4,$00b6
	dc.w	$00c0,$00c2,$00c4,$00c6,$00c8,$00ca,$00cc,$00ce,$00d0,$00d2,$00d4,$00d6
	dc.w	$00e0,$00e2,$00e4,$00e6,$00e8,$00ea,$00ec,$00ee,$00f0,$00f2,$00f4,$00f6
	dc.w	$0100,$0102,$0104,$0106,$0108,$010a,$010c,$010e,$0110,$0112,$0114,$0116
	dc.w	$0120,$0122,$0124,$0126,$0128,$012a,$012c,$012e,$0130,$0132,$0134,$0136
	dc.w	$0140,$0142,$0144,$0146,$0148,$014a,$014c,$014e,$0150,$0152,$0154,$0156
	dc.w	$0160,$0162,$0164,$0166,$0168,$016a,$016c,$016e,$0170,$0172,$0174,$0176
	dc.w	$0180,$0182,$0184,$0186,$0188,$018a,$018c,$018e,$0190,$0192,$0194,$0196
	dc.w	$01a0,$01a2,$01a4,$01a6,$01a8,$01aa,$01ac,$01ae,$01b0,$01b2,$01b4,$01b6
	dc.w	$01c0,$01c2,$01c4,$01c6,$01c8,$01ca,$01cc,$01ce,$01d0,$01d2,$01d4,$01d6
	dc.w	$01e0,$01e2,$01e4,$01e6,$01e8,$01ea,$01ec,$01ee,$01f0,$01f2,$01f4,$01f6
	dc.w	$0200,$0202,$0204,$0206,$0208,$020a,$020c,$020e,$0210,$0212,$0214,$0216
	dc.w	$0220,$0222,$0224,$0226,$0228,$022a,$022c,$022e,$0230,$0232,$0234,$0236
	dc.w	$0240,$0242,$0244,$0246,$0248,$024a,$024c,$024e,$0250,$0252,$0254,$0256
	dc.w	$0260,$0262,$0264,$0266,$0268,$026a,$026c,$026e,$0270,$0272,$0274,$0276
	dc.w	$0280,$0282,$0284,$0286,$0288,$028a,$028c,$028e,$0290,$0292,$0294,$0296
	dc.w	$02a0,$02a2,$02a4,$02a6,$02a8,$02aa,$02ac,$02ae,$02b0,$02b2,$02b4,$02b6
	dc.w	$02c0,$02c2,$02c4,$02c6,$02c8,$02ca,$02cc,$02ce,$02d0,$02d2,$02d4,$02d6
	dc.w	$02e0,$02e2,$02e4,$02e6,$02e8,$02ea,$02ec,$02ee,$02f0,$02f2,$02f4,$02f6
	dc.w	$0300,$0302,$0304,$0306,$0308,$030a,$030c,$030e,$0310,$0312,$0314,$0316
	dc.w	$0320,$0322,$0324,$0326,$0328,$032a,$032c,$032e,$0330,$0332,$0334,$0336
	dc.w	$0340,$0342,$0344,$0346,$0348,$034a,$034c,$034e,$0350,$0352,$0354,$0356
	dc.w	$0360,$0362,$0364,$0366,$0368,$036a,$036c,$036e,$0370,$0372,$0374,$0376
	dc.w	$0380,$0382,$0384,$0386,$0388,$038a,$038c,$038e,$0390,$0392,$0394,$0396
	dc.w	$03a0,$03a2,$03a4,$03a6,$03a8,$03aa,$03ac,$03ae,$03b0,$03b2,$03b4,$03b6
	dc.w	$03c0,$03c2,$03c4,$03c6,$03c8,$03ca,$03cc,$03ce,$03d0,$03d2,$03d4,$03d6
	dc.w	$03e0,$03e2,$03e4,$03e6,$03e8,$03ea,$03ec,$03ee,$03f0,$03f2,$03f4,$03f6
	dc.w	$0408,$0412,$0414,$0416,$0418,$041a,$041c
	dc.w	$0424,$0426,$0428
	dc.w	$0600,$0602,$0604,$0606,$0608,$060a,$060c,$060e,$0610,$0612,$0614,$0616,$0618,$061a,$061c,$061e
	dc.w	$0620,$0622,$0624,$0626,$0628,$062a,$062c,$062e,$0630,$0632,$0634,$0636,$0638,$063a,$063c,$063e
	dc.w	$0640,$0642,$0644,$0646,$0648,$064a,$064c,$064e,$0650,$0652,$0654,$0656,$0658,$065a,$065c,$065e
	dc.w	$0660,$0662,$0664,$0666,$0668,$066a,$066c,$066e,$0670,$0672,$0674,$0676,$0678,$067a,$067c,$067e
	dc.w	$0700,$0702,$0704,$0706,$0708,$070a,$070c,$070e,$0710,$0712,$0714,$0716,$0718,$071a,$071c,$071e
	dc.w	$0720,$0722,$0724,$0726,$0728,$072a,$072c,$072e,$0730,$0732,$0734,$0736,$0738,$073a,$073c,$073e
	dc.w	$0740,$0742,$0744,$0746,$0748,$074a,$074c,$074e,$0750,$0752,$0754,$0756,$0758,$075a,$075c,$075e
	dc.w	$0760,$0762,$0764,$0766,$0768,$076a,$076c,$076e,$0770,$0772,$0774,$0776,$0778,$077a,$077c,$077e
	dc.w	$0780,$0782,$0784,$0786,$0788,$078a,$078c,$078e,$0790,$0792,$0794,$0796,$0798,$079a,$079c,$079e
	dc.w	$07a0,$07a2,$07a4,$07a6,$07a8,$07aa,$07ac,$07ae,$07b0,$07b2,$07b4,$07b6,$07b8,$07ba,$07bc,$07be
	dc.w	$0c00,$0c02,$0c04,$0c06,$0c08,$0c0a,$0c0c,$0c0e,$0c10,$0c12,$0c14,$0c16,$0c18,$0c1a,$0c1c,$0c1e
	dc.w	$0c20,$0c22,$0c24,$0c26,$0c28,$0c2a,$0c2c,$0c2e,$0c30,$0c32,$0c34,$0c36,$0c38,$0c3a,$0c3c,$0c3e
	dc.w	$0c40,$0c42,$0c44,$0c46,$0c48,$0c4a,$0c4c,$0c4e,$0c50,$0c52,$0c54,$0c56,$0c58,$0c5a,$0c5c,$0c5e
	dc.w	$0c60,$0c62,$0c64,$0c66,$0c68,$0c6a,$0c6c,$0c6e,$0c70,$0c72,$0c74,$0c76,$0c78,$0c7a,$0c7c,$0c7e
	dc.w	$0c80,$0c82,$0c84,$0c86,$0c88,$0c8a,$0c8c,$0c8e,$0c90,$0c92,$0c94,$0c96,$0c98,$0c9a,$0c9c,$0c9e
	dc.w	$0ca0,$0ca2,$0ca4,$0ca6,$0ca8,$0caa,$0cac,$0cae,$0cb0,$0cb2,$0cb4,$0cb6,$0cb8,$0cba,$0cbc,$0cbe
	dc.w	$0cc0,$0cc2,$0cc4,$0cc6,$0cc8,$0cca,$0ccc,$0cce,$0cd0,$0cd2,$0cd4,$0cd6,$0cd8,$0cda,$0cdc,$0cde
	dc.w	$0ce0,$0ce2,$0ce4,$0ce6,$0ce8,$0cea,$0cec,$0cee,$0cf0,$0cf2,$0cf4,$0cf6,$0cf8,$0cfa,$0cfc,$0cfe
	dc.w	$0d00,$0d02,$0d04,$0d06,$0d08,$0d0a,$0d0c,$0d0e,$0d10,$0d12,$0d14,$0d16,$0d18,$0d1a,$0d1c,$0d1e
	dc.w	$0d20,$0d22,$0d24,$0d26,$0d28,$0d2a,$0d2c,$0d2e,$0d30,$0d32,$0d34,$0d36,$0d38,$0d3a,$0d3c,$0d3e
	dc.w	$0d40,$0d42,$0d44,$0d46,$0d48,$0d4a,$0d4c,$0d4e,$0d50,$0d52,$0d54,$0d56,$0d58,$0d5a,$0d5c,$0d5e
	dc.w	$0d60,$0d62,$0d64,$0d66,$0d68,$0d6a,$0d6c,$0d6e,$0d70,$0d72,$0d74,$0d76,$0d78,$0d7a,$0d7c,$0d7e
	dc.w	$0d80,$0d82,$0d84,$0d86,$0d88,$0d8a,$0d8c,$0d8e,$0d90,$0d92,$0d94,$0d96,$0d98,$0d9a,$0d9c,$0d9e
	dc.w	$0da0,$0da2,$0da4,$0da6,$0da8,$0daa,$0dac,$0dae,$0db0,$0db2,$0db4,$0db6,$0db8,$0dba,$0dbc,$0dbe
	dc.w	$0dc0,$0dc2,$0dc4,$0dc6,$0dc8,$0dca,$0dcc,$0dce,$0dd0,$0dd2,$0dd4,$0dd6,$0dd8,$0dda,$0ddc,$0dde
	dc.w	$0de0,$0de2,$0de4,$0de6,$0de8,$0dea,$0dec,$0dee,$0df0,$0df2,$0df4,$0df6,$0df8,$0dfa,$0dfc,$0dfe
	dc.w	$0e00,$0e02,$0e04,$0e06,$0e08,$0e0a,$0e0c,$0e0e,$0e10,$0e12,$0e14,$0e16,$0e18,$0e1a,$0e1c,$0e1e
	dc.w	$0e20,$0e22,$0e24,$0e26,$0e28,$0e2a,$0e2c,$0e2e,$0e30,$0e32,$0e34,$0e36,$0e38,$0e3a,$0e3c,$0e3e
	dc.w	$0e40,$0e42,$0e44,$0e46,$0e48,$0e4a,$0e4c,$0e4e,$0e50,$0e52,$0e54,$0e56,$0e58,$0e5a,$0e5c,$0e5e
	dc.w	$0e60,$0e62,$0e64,$0e66,$0e68,$0e6a,$0e6c,$0e6e,$0e70,$0e72,$0e74,$0e76,$0e78,$0e7a,$0e7c,$0e7e
	dc.w	$0e80,$0e82,$0e84,$0e86,$0e88,$0e8a,$0e8c,$0e8e,$0e90,$0e92,$0e94,$0e96,$0e98,$0e9a,$0e9c,$0e9e
	dc.w	$0ea0,$0ea2,$0ea4,$0ea6,$0ea8,$0eaa,$0eac,$0eae,$0eb0,$0eb2,$0eb4,$0eb6,$0eb8,$0eba,$0ebc,$0ebe
	dc.w	$0ec0,$0ec2,$0ec4,$0ec6,$0ec8,$0eca,$0ecc,$0ece,$0ed0,$0ed2,$0ed4,$0ed6,$0ed8,$0eda,$0edc,$0ede
	dc.w	$ffff


	org	$00a000
Stack:

	end

