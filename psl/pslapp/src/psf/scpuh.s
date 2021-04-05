
; 使用アセンブラ
;   as68k.exe v1.00
;   sload.exe


	org	$00000000

Start:
	dc.b	"psl",$1a
	dc.w	$0001

	dc.w	Start
	dc.w	Vector

Vector:

	end

