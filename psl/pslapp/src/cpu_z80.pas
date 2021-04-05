unit cpu_z80;

interface

uses
	SysUtils, Classes;

const
	INDEX_BC   = 0;
	INDEX_DE   = 1;
	INDEX_HL   = 2;
	INDEX_AF   = 3;
	INDEX_BC2  = 4;
	INDEX_DE2  = 5;
	INDEX_HL2  = 6;
	INDEX_AF2  = 7;
	INDEX_IR   = 8;
	INDEX_IX   = 9;
	INDEX_IY   = 10;
	INDEX_SP   = 11;
	INDEX_PC   = 12;
  //
  INDEX_ADDR        = 13;
  INDEX_TEMP        = 14;
	INDEX_IFF_IM      = 15;
	INDEX_HALT_INTREQ = 16;

type
	TRegister = (
	  REG_BC,
		REG_B,
	  REG_C,
  	REG_DE,
		REG_D,
  	REG_E,
	  REG_HL,
		REG_H,
	  REG_L,
  	REG_AF,
		REG_A,
  	REG_F,
	  REG_BC2,
  	REG_DE2,
	  REG_HL2,
  	REG_AF2,
	  REG_IR,
		REG_I,
	  REG_R,
  	REG_IX,
		REG_IXH,
		REG_IXL,
	  REG_IY,
		REG_IYH,
		REG_IYL,
  	REG_SP,
		REG_SPH,
		REG_SPL,
	  REG_PC,
		REG_PCH,
		REG_PCL,
    REG_ADDR,
    REG_ADDRH,
    REG_ADDRL,
    REG_TEMP,
    REG_TEMPH,
    REG_TEMPL,
		REG_IFF1_IFF2,
		REG_IM,
	  REG_HALT,
	  REG_INTREQ
  );

const
	_S    = 1 shl 7;
	_Z    = 1 shl 6;
  _H    = 1 shl 4;
	_PV   = 1 shl 2;
	_N    = 1 shl 1;
	_C    = 1 shl 0;
	_MASK = (_S or _Z or _H or _PV or _N or _C) xor $ff;

type
	TFlag = (
		FLAG_S,
		FLAG_Z,
		FLAG_H,
		FLAG_PV,
		FLAG_N,
		FLAG_C
  );

type
	TAluCmd = (
		ALU_ADC16,
		ALU_SBC16,
		ALU_ADC8,
		ALU_SBC8,
		ALU_AND8,
		ALU_OR8,
		ALU_ROR8
  );

type
	TMemoryCycle = (
		CYCLE_NOP,
		CYCLE_OPCODE,
		CYCLE_DATA
  );

type
	TPrefix = (
		PREFIX_XX,
		PREFIX_CBXX,
		PREFIX_DDXX,
		PREFIX_DDCBdXX,
		PREFIX_EDXX,
		PREFIX_FDXX,
		PREFIX_FDCBdXX
  );

type
  TCpuZ80 = class(TObject)
  private
    { Private 宣言 }
    Prefix: TPrefix;
    wReg: array[0..16] of Word;
		byParityLut: array[0..$ff] of Byte;
    slDebugLog: TStringList;
		DebugMemRead: array[0..$10000-1] of Byte;
    function RegIndex(r: TRegister): Integer;
    function GetFlag(f: TFlag): Integer;
    function GetR(pre: TPrefix; r: Integer): Byte;
    procedure SetR(pre: TPrefix; r: Integer; n: Byte);
    function GetRr(pre: TPrefix; rr: Integer): Word;
    procedure SetRr(pre: TPrefix; rr: Integer; nn: Word);
		function Alu(f: Byte; cmd: TAluCmd; a, b: Word; cy, s: Integer): Word;
    procedure IncReg(r: TRegister; d: Integer = 1);
    procedure DecReg(r: TRegister; d: Integer = 1);
  public
    { Public 宣言 }
    nTstate: Int64;
    function GetReg(r: TRegister): Word;
    procedure SetReg(r: TRegister; nn: Word);
    procedure Reset;
    function Execute: Boolean;
    function ReadMemory(addr: Word; cycle: TMemoryCycle): Byte; virtual;
    procedure WriteMemory(addr: Word; n: Byte); virtual;
    function ReadIo(addr: Word): Byte; virtual;
    procedure WriteIo(addr: Word; n: Byte); virtual;
  protected
    { protected 宣言 }
  published
    { published 宣言 }
		constructor Create;
    destructor Destroy; override;
  end;

implementation

function TCpuZ80.RegIndex(r: TRegister): Integer;
	var
  	i: Integer;
begin
  //
  case r of
		REG_BC, REG_B, REG_C:
    	i := INDEX_BC;
		REG_DE, REG_D, REG_E:
    	i := INDEX_DE;
		REG_HL, REG_H, REG_L:
    	i := INDEX_HL;
		REG_AF, REG_A, REG_F:
    	i := INDEX_AF;
	  REG_BC2:
    	i := INDEX_BC2;
  	REG_DE2:
    	i := INDEX_DE2;
	  REG_HL2:
    	i := INDEX_HL2;
  	REG_AF2:
    	i := INDEX_AF2;
		REG_IR, REG_I, REG_R:
    	i := INDEX_IR;
		REG_IX, REG_IXH, REG_IXL:
    	i := INDEX_IX;
		REG_IY, REG_IYH, REG_IYL:
    	i := INDEX_IY;
		REG_SP, REG_SPH, REG_SPL:
    	i := INDEX_SP;
		REG_PC, REG_PCH, REG_PCL:
    	i := INDEX_PC;
    REG_ADDR, REG_ADDRH, REG_ADDRL:
    	i := INDEX_ADDR;
    REG_TEMP, REG_TEMPH, REG_TEMPL:
    	i := INDEX_TEMP;
		REG_IFF1_IFF2, REG_IM:
    	i := INDEX_IFF_IM;
	  REG_HALT, REG_INTREQ:
    	i := INDEX_HALT_INTREQ;
    else
    	i := -1;	//※
  end;
  Result := i;
end;

function TCpuZ80.GetReg(r: TRegister): Word;
	var
  	i: Integer;
  	nn: Word;
begin
	//
	i := RegIndex(r);
  case r of
		REG_B, REG_D, REG_H, REG_A, REG_I, REG_IXH, REG_IYH, REG_SPH, REG_PCH, REG_ADDRH, REG_TEMPH, REG_IFF1_IFF2, REG_HALT:
    	nn := (wReg[i] shr 8) and $ff;
    REG_C, REG_E, REG_L, REG_F, REG_R, REG_IXL, REG_IYL, REG_SPL, REG_PCL, REG_ADDRL, REG_TEMPL, REG_IM, REG_INTREQ:
    	nn := wReg[i] and $ff;
	  REG_BC, REG_DE, REG_HL, REG_AF, REG_BC2, REG_DE2, REG_HL2, REG_AF2, REG_IR, REG_IX, REG_IY, REG_SP, REG_PC, REG_ADDR, REG_TEMP:
    	nn := wReg[i];
    else
    	nn := $ffff;	//※
  end;
  Result := nn;
end;

procedure TCpuZ80.SetReg(r: TRegister; nn: Word);
	var
  	i: Integer;
begin
	//
	i := RegIndex(r);
  case r of
		REG_B, REG_D, REG_H, REG_A, REG_I, REG_IXH, REG_IYH, REG_SPH, REG_PCH, REG_ADDRH, REG_TEMPH, REG_IFF1_IFF2, REG_HALT:
    	wReg[i] := (wReg[i] and $00ff) or ((nn and $ff) shl 8);
    REG_C, REG_E, REG_L, REG_F, REG_R, REG_IXL, REG_IYL, REG_SPL, REG_PCL, REG_ADDRL, REG_TEMPL, REG_IM, REG_INTREQ:
    	wReg[i] := (wReg[i] and $ff00) or (nn and $ff);
	  REG_BC, REG_DE, REG_HL, REG_AF, REG_BC2, REG_DE2, REG_HL2, REG_AF2, REG_IR, REG_IX, REG_IY, REG_SP, REG_PC, REG_ADDR, REG_TEMP:
    	wReg[i] := nn;
  end;
end;

function TCpuZ80.GetFlag(f: TFlag): Integer;
	var
  	n: Byte;
begin
	//
 	n := GetReg(REG_F);
  case f of
 		FLAG_S:
    	n := n and _S;
		FLAG_Z:
    	n := n and _Z;
		FLAG_H:
    	n := n and _H;
		FLAG_PV:
    	n := n and _PV;
		FLAG_N:
    	n := n and _N;
		FLAG_C:
    	n := n and _C;
  	else
			;	//※
  end;
  if n<>0 then
	  n := 1;
  Result := n;
end;

procedure TCpuZ80.IncReg(r: TRegister; d: Integer = 1);
begin
	//
  case r of
		REG_B, REG_D, REG_H, REG_A, REG_I, REG_IXH, REG_IYH, REG_SPH, REG_PCH, REG_ADDRH, REG_TEMPH, REG_IFF1_IFF2, REG_HALT,
    REG_C, REG_E, REG_L, REG_F, REG_R, REG_IXL, REG_IYL, REG_SPL, REG_PCL, REG_ADDRL, REG_TEMPL, REG_IM, REG_INTREQ:
    	SetReg(r, (GetReg(r)+d) and $ff);
	  REG_BC, REG_DE, REG_HL, REG_AF, REG_BC2, REG_DE2, REG_HL2, REG_AF2, REG_IR, REG_IX, REG_IY, REG_SP, REG_PC, REG_ADDR, REG_TEMP:
    	SetReg(r, (GetReg(r)+d) and $ffff);
  end;
end;

procedure TCpuZ80.DecReg(r: TRegister; d: Integer = 1);
begin
	//
  case r of
		REG_B, REG_D, REG_H, REG_A, REG_I, REG_IXH, REG_IYH, REG_SPH, REG_PCH, REG_ADDRH, REG_TEMPH, REG_IFF1_IFF2, REG_HALT,
    REG_C, REG_E, REG_L, REG_F, REG_R, REG_IXL, REG_IYL, REG_SPL, REG_PCL, REG_ADDRL, REG_TEMPL, REG_IM, REG_INTREQ:
    	SetReg(r, (GetReg(r)-d) and $ff);
	  REG_BC, REG_DE, REG_HL, REG_AF, REG_BC2, REG_DE2, REG_HL2, REG_AF2, REG_IR, REG_IX, REG_IY, REG_SP, REG_PC, REG_ADDR, REG_TEMP:
    	SetReg(r, (GetReg(r)-d) and $ffff);
  end;
end;

function TCpuZ80.GetR(pre: TPrefix; r: Integer): Byte;
	var
  	n: Byte;
begin
	//
	case r of
		0: n := GetReg(REG_B);
		1: n := GetReg(REG_C);
		2: n := GetReg(REG_D);
		3: n := GetReg(REG_E);
		4:
     	case pre of
				PREFIX_DDXX, PREFIX_DDCBdXX:
					n := GetReg(REG_IXH);
				PREFIX_FDXX, PREFIX_FDCBdXX:
					n := GetReg(REG_IYH);
        else
					n := GetReg(REG_H);
      end;
		5:
			case pre of
				PREFIX_DDXX, PREFIX_DDCBdXX:
					n := GetReg(REG_IXL);
				PREFIX_FDXX, PREFIX_FDCBdXX:
					n := GetReg(REG_IYL);
				else
					n := GetReg(REG_L);
			end;
		7: n := GetReg(REG_A);
    else
    	n := $ff;	//※
  end;
  Result := n;
end;

procedure TCpuZ80.SetR(pre: TPrefix; r: Integer; n: Byte);
begin
	//
	case r of
		0: SetReg(REG_B, n);
		1: SetReg(REG_C, n);
		2: SetReg(REG_D, n);
		3: SetReg(REG_E, n);
		4:
     	case pre of
				PREFIX_DDXX, PREFIX_DDCBdXX:
					SetReg(REG_IXH, n);
				PREFIX_FDXX, PREFIX_FDCBdXX:
					SetReg(REG_IYH, n);
        else
					SetReg(REG_H, n);
      end;
		5:
			case pre of
				PREFIX_DDXX, PREFIX_DDCBdXX:
					SetReg(REG_IXL, n);
				PREFIX_FDXX, PREFIX_FDCBdXX:
					SetReg(REG_IYL, n);
				else
					SetReg(REG_L, n);
			end;
		7: SetReg(REG_A, n);
    else
    	;	//※
  end;
end;

function TCpuZ80.GetRr(pre: TPrefix; rr: Integer): Word;
	var
  	nn: Word;
begin
	//
	case rr of
		0: nn := GetReg(REG_BC);
		1: nn := GetReg(REG_DE);
		2:
    	case pre of
				PREFIX_DDXX:
					nn := GetReg(REG_IX);
				PREFIX_FDXX:
					nn := GetReg(REG_IY);
				else
					nn := GetReg(REG_HL);
			end;
		3: nn := GetReg(REG_SP);
		else
			nn := $ffff;	//※
  end;
  Result := nn;
end;

procedure TCpuZ80.SetRr(pre: TPrefix; rr: Integer; nn: Word);
begin
	//
	case rr of
		0: SetReg(REG_BC, nn);
		1: SetReg(REG_DE, nn);
		2:
			case pre of
	      PREFIX_DDXX:
					SetReg(REG_IX, nn);
	      PREFIX_FDXX:
					SetReg(REG_IY, nn);
      	else
					SetReg(REG_HL, nn);
      end;
		3: SetReg(REG_SP, nn);
    else
    	;	//※
	end;
end;

const
	_SIGN		  = 1 shl 5;
	_ZERO		  = 1 shl 4;
	_HALF		  = 1 shl 3;
	_PARITY	  = 1 shl 2;
	_OVERFLOW	= 1 shl 1;
	_CARRY		= 1 shl 0;

function TCpuZ80.Alu(f: Byte; cmd: TAluCmd; a, b: Word; cy, s: Integer): Word;
	var
  	c, d: Integer;
begin
	//
	case cmd of
		ALU_ADC16:
			begin
				c := (a and $ffff)+(b and $ffff) + cy;
				if (s and _OVERFLOW)<>0 then
				begin
					if ((a xor b) and $8000)=0 then
					begin
						//元の符号が同じ
						if ((a xor c) and $8000)<>0 then
						begin
							//符号が変わった
							f := f or _PV;
						end;
					end;
				end;
				d := (a and $0fff)+(b and $0fff) + cy;
			end;
		ALU_SBC16:
			begin
				f := f or _N;
				c := (a and $ffff)-(b and $ffff) - cy;
				if (s and _OVERFLOW)<>0 then
				begin
					if ((a xor b) and $8000)<>0 then
					begin
						//元の符号が違う
						if ((a xor c) and $8000)<>0 then
						begin
							//符号が変わった
							f := f or _PV;
						end;
					end;
				end;
				d := (a and $0fff)-(b and $0fff) - cy;
			end;
		ALU_ADC8:
			begin
				c := (a and $ff)+(b and $ff) + cy;
				if (s and _OVERFLOW)<>0 then
				begin
					if ((a xor b) and $80)=0 then
					begin
						//元の符号が同じ
						if ((a xor c) and $80)<>0 then
						begin
							//符号が変わった
							f := f or _PV;
						end;
					end;
				end;
				d := (a and $0f)+(b and $0f) + cy;
			end;
		ALU_SBC8:
			begin
				f := f or _N;
				c := (a and $ff)-(b and $ff) - cy;
				if (s and _OVERFLOW)<>0 then
				begin
					if ((a xor b) and $80)<>0 then
					begin
						//元の符号が違う
						if ((a xor c) and $80)<>0 then
						begin
							//符号が変わった
							f := f or _PV;
						end;
					end;
				end;
				d := (a and $0f)-(b and $0f) - cy;
			end;
		ALU_AND8:
			begin
				f := f or _H;
				c := (a and b) and $ff;
				d := 0;
			end;
		ALU_OR8:
			begin
				c := (a or b) and $ff;
				d := 0;
			end;
		ALU_ROR8:
			begin
				c := 0;
				if (a and $01)<>0 then
					c := $100;
				if b<>0 then
					c := c or $80;
				c := c or ((a shr 1) and $7f);
				d := 0;
			end;
    else
    	begin
	    	//※
        c := 0;
        d := 0;
      end;
	end;

	//
	case cmd of
		ALU_ADC16, ALU_SBC16:
			begin
				if ((s and _SIGN)<>0) and ((c and $8000)<>0) then
					f := f or _S;
				if ((s and _ZERO)<>0) and ((c and $ffff)=0) then
					f := f or _Z;
				if ((s and _HALF)<>0) and ((d and $1000)<>0) then
					f := f or _H;
				if (s and _PARITY)<>0 then
					f := f or byParityLut[(c shr 8) and $ff];
				if ((s and _CARRY)<>0) and ((c and $10000)<>0) then
					f := f or _C;
				SetReg(REG_F, f);
				c := c and $ffff;
			end;
		ALU_ADC8, ALU_SBC8, ALU_AND8, ALU_OR8, ALU_ROR8:
			begin
				if ((s and _SIGN)<>0) and ((c and $80)<>0) then
					f := f or _S;
				if ((s and _ZERO)<>0) and ((c and $ff)=0) then
					f := f or _Z;
				if ((s and _HALF)<>0) and ((d and $10)<>0) then
					f := f or _H;
				if (s and _PARITY)<>0 then
					f := f or byParityLut[c and $ff];
				if ((s and _CARRY)<>0) and ((c and $100)<>0) then
					f := f or _C;
				SetReg(REG_F, f);
				c := c and $ff;
			end;
	end;
	Result := c;
end;

function TCpuZ80.ReadMemory(addr: Word; cycle: TMemoryCycle): Byte;
	var
  	n: Integer;
begin
	//
	case cycle of
		CYCLE_OPCODE:
    	begin
				Inc(nTstate, 4 + 1);	//+1はwait
        n := GetReg(REG_R);
				SetReg(REG_R, (n and $80) or ((n+1) and $7f));
      end;
		CYCLE_DATA:
			Inc(nTstate, 3);
    else
			;
	end;

	//
	Result := $ff;
end;

procedure TCpuZ80.WriteMemory(addr: Word; n: Byte);
begin
	//
	Inc(nTstate, 3);
end;

function TCpuZ80.ReadIo(addr: Word): Byte;
begin
	//
	Inc(nTstate, 3 + 1);	//+1はwait

  //
	Result := $ff;
end;

procedure TCpuZ80.WriteIo(addr: Word; n: Byte);
begin
	//
	Inc(nTstate, 3 + 1);	//+1はwait
end;

constructor TCpuZ80.Create;
	var
  	i, j, c: Integer;
begin
  //
  FillChar(byParityLut, SizeOf(byParityLut), $00);
	for i := 0 to $ff do
  begin
		c := 0;
		for j := 0 to 7 do
    begin
    	if (i and (1 shl j))<>0 then
				Inc(c, 1);
    end;
    if (c and 1)=0 then
    	byParityLut[i] := _PV;
	end;
  //
  slDebugLog := TStringList.Create;
end;

destructor TCpuZ80.Destroy;
begin
	//
  if slDebugLog.Count>0 then
  	slDebugLog.SaveToFile('.\_log.txt');
  slDebugLog.Free;
end;

procedure TCpuZ80.Reset;
begin
	//
  slDebugLog.Clear;
	FillChar(DebugMemRead, SizeOf(DebugMemRead), $00);

  //
  nTstate := 0;
  Prefix := PREFIX_XX;
  FillChar(wReg, SizeOf(wReg), $00);
  SetReg(REG_IFF1_IFF2, $00);
  SetReg(REG_IM, 0);
  SetReg(REG_HALT, 0);
  SetReg(REG_INTREQ, 0);
  SetReg(REG_PC, $0000);
end;

function TCpuZ80.Execute: Boolean;
	var
  	s: String;
    pc: Integer;
  	op, r, n: Byte;
begin
  //
	op := ReadMemory(GetReg(REG_PC), CYCLE_OPCODE);
	IncReg(REG_PC);
	case Prefix of
		PREFIX_XX, PREFIX_DDXX, PREFIX_FDXX:
			begin
				case op of
					$40,	//ld b,b
					$41,	//ld b,c
					$42,	//ld b,d
					$43,	//ld b,e
					$44,	//ld b,h/ixh/iyh
					$45,	//ld b,l/ixl/iyl
					$47,	//ld b,a
					$48,	//ld c,b
					$49,	//ld c,c
					$4a,	//ld c,d
					$4b,	//ld c,e
					$4c,	//ld c,h/ixh/iyh
					$4d,	//ld c,l/ixl/iyl
					$4f,	//ld c,a
					$50,	//ld d,b
					$51,	//ld d,c
					$52,	//ld d,d
					$53,	//ld d,e
					$54,	//ld d,h/ixh/iyh
					$55,	//ld d,l/ixl/iyl
					$57,	//ld d,a
					$58,	//ld e,b
					$59,	//ld e,c
					$5a,	//ld e,d
					$5b,	//ld e,e
					$5c,	//ld e,h/ixh/iyh
					$5d,	//ld e,l/ixl/iyl
					$5f,	//ld e,a
					$60,	//ld h/ixh/iyh,b
					$61,	//ld h/ixh/iyh,c
					$62,	//ld h/ixh/iyh,d
					$63,	//ld h/ixh/iyh,e
					$64,	//ld h/ixh/iyh,h/ixh/iyh
					$65,	//ld h/ixh/iyh,l/ixl/iyl
					$67,	//ld h/ixh/iyh,a
					$68,	//ld l/ixl/iyl,b
					$69,	//ld l/ixl/iyl,c
					$6a,	//ld l/ixl/iyl,d
					$6b,	//ld l/ixl/iyl,e
					$6c,	//ld l/ixl/iyl,h/ixh/iyh
					$6d,	//ld l/ixl/iyl,l/ixl/iyl
					$6f,	//ld l/ixl/iyl,a
					$78,	//ld a,b
					$79,	//ld a,c
					$7a,	//ld a,d
					$7b,	//ld a,e
					$7c,	//ld a,h/ixh/iyh
					$7d,	//ld a,l/ixl/iyl
					$7f:	//ld a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							r := (op shr 3) and 7;
							SetR(Prefix, r, n);
						end;

					$06,	//ld b,n
					$0e,	//ld c,n
					$16,	//ld d,n
					$1e,	//ld e,n
					$26,	//ld h/ixh/ixh,n
					$2e,	//ld l/iyl/iyl,n
					$3e:	//ld a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							r := (op shr 3) and 7;
							SetR(Prefix, r, n);
						end;

					$46,	//ld b,(hl)/(ix+d)/(iy+d)
					$4e,	//ld c,(hl)/(ix+d)/(iy+d)
					$56,	//ld d,(hl)/(ix+d)/(iy+d)
					$5e,	//ld e,(hl)/(ix+d)/(iy+d)
					$66,	//ld h,(hl)/(ix+d)/(iy+d)
					$6e,	//ld l,(hl)/(ix+d)/(iy+d)
					$7e:	//ld a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							r := (op shr 3) and 7;
							SetR(PREFIX_XX, r, n);
						end;

					$70,	//ld (hl)/(ix+d)/(iy+d),b
					$71,	//ld (hl)/(ix+d)/(iy+d),c
					$72,	//ld (hl)/(ix+d)/(iy+d),d
					$73,	//ld (hl)/(ix+d)/(iy+d),e
					$74,	//ld (hl)/(ix+d)/(iy+d),h
					$75,	//ld (hl)/(ix+d)/(iy+d),l
					$77:	//ld (hl)/(ix+d)/(iy+d),a
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							r := op and 7;
							n := GetR(PREFIX_XX, r);
							WriteMemory(GetReg(REG_ADDR), n);
						end;

					$36:	//ld (hl)/(ix+d)/(iy+d),n
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 1);
							end;
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							WriteMemory(GetReg(REG_ADDR), n);
						end;

					$0a:	//ld a,(bc)
						SetReg(REG_A, ReadMemory(GetReg(REG_BC), CYCLE_DATA));
					$1a:	//ld a,(de)
						SetReg(REG_A, ReadMemory(GetReg(REG_DE), CYCLE_DATA));
					$3a:	//ld a,(nn)
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_A, ReadMemory(GetReg(REG_ADDR), CYCLE_DATA));
						end;
					$02:	//ld (bc),a
						WriteMemory(GetReg(REG_BC), GetReg(REG_A));
					$12:	//ld (de),a
						WriteMemory(GetReg(REG_DE), GetReg(REG_A));
					$32:	//ld (nn),a
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							WriteMemory(GetReg(REG_ADDR), GetReg(REG_A));
						end;

					$01,	//ld bc,nn
					$11,	//ld de,nn
					$21,	//ld hl/ix/iy,nn
					$31:	//ld sp,nn
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_TEMPH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							r := (op shr 4) and 3;
							SetRr(Prefix, r, GetReg(REG_TEMP));
						end;

					$2a:	//ld hl/ix/iy,(nn)
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_ADDR), CYCLE_DATA));
							IncReg(REG_ADDR);
							SetReg(REG_TEMPH, ReadMemory(GetReg(REG_ADDR), CYCLE_DATA));
							IncReg(REG_ADDR);
							SetRr(Prefix, 2, GetReg(REG_TEMP));
						end;
					$22:	//ld (nn),hl/ix/iy
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_TEMP, GetRr(Prefix, 2));
							WriteMemory(GetReg(REG_ADDR), GetReg(REG_TEMPL));
							IncReg(REG_ADDR);
							WriteMemory(GetReg(REG_ADDR), GetReg(REG_TEMPH));
							IncReg(REG_ADDR);
						end;
					$f9:	//ld sp,hl/ix/iy
						begin
							SetReg(REG_TEMP, GetRr(Prefix, 2));
							SetReg(REG_SP, GetReg(REG_TEMP));
							Inc(nTstate, 2);
						end;

					$c5,	//push bc
					$d5,	//push de
					$e5,	//push hl/ix/iy
					$f5:	//push af
						begin
							r := (op shr 4) and 3;
							case r of
								0..2:
									SetReg(REG_TEMP, GetRr(Prefix, r));
								3:
									SetReg(REG_TEMP, GetReg(REG_AF));
							end;
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_TEMPH));
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_TEMPL));
							Inc(nTstate, 1);
						end;
					$c1,	//pop bc
					$d1,	//pop de
					$e1,	//pop hl/ix/iy
					$f1:	//pop af
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_TEMPH, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							r := (op shr 4) and 3;
							case r of
								0..2:
									SetRr(Prefix, r, GetReg(REG_TEMP));
								3:
									SetReg(REG_AF, GetReg(REG_TEMP));
							end;
						end;

					$eb:	//ex de,hl/ix/iy
						begin
							SetReg(REG_ADDR, GetRr(Prefix, 2));
							SetReg(REG_TEMP, GetReg(REG_DE));
							SetReg(REG_DE, GetReg(REG_ADDR));
							SetRr(Prefix, 2, GetReg(REG_TEMP));
						end;
					$08:	//ex af,af'
						begin
							SetReg(REG_TEMP, GetReg(REG_AF2));
							SetReg(REG_AF2, GetReg(REG_AF));
							SetReg(REG_AF, GetReg(REG_TEMP));
						end;
					$d9:	//exx
						begin
							SetReg(REG_TEMP, GetReg(REG_BC2));
							SetReg(REG_BC2, GetReg(REG_BC));
							SetReg(REG_BC, GetReg(REG_TEMP));
							SetReg(REG_TEMP, GetReg(REG_DE2));
							SetReg(REG_DE2, GetReg(REG_DE));
							SetReg(REG_DE, GetReg(REG_TEMP));
							SetReg(REG_ADDR, GetRr(Prefix, 2));
							SetReg(REG_TEMP, GetReg(REG_HL2));
							SetReg(REG_HL2, GetReg(REG_ADDR));
							SetRr(Prefix, 2, GetReg(REG_TEMP));
						end;
					$e3:	//ex (sp),hl/ix/iy
						begin
							SetReg(REG_ADDR, GetRr(Prefix, 2));
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							SetReg(REG_TEMPH, ReadMemory(GetReg(REG_SP)+1, CYCLE_DATA));
							WriteMemory(GetReg(REG_SP), GetReg(REG_ADDRL));
							WriteMemory(GetReg(REG_SP)+1, GetReg(REG_ADDRH));
							SetRr(Prefix, 2, GetReg(REG_TEMP));
							Inc(nTstate, 1 + 2);
						end;

					$80,	//add a,b
					$81,	//add a,c
					$82,	//add a,d
					$83,	//add a,e
					$84,	//add a,h/ixh/ixh
					$85,	//add a,l/iyl/iyl
					$87:	//add a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$c6:	//add a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$86:	//add a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;

					$88,	//adc a,b
					$89,	//adc a,c
					$8a,	//adc a,d
					$8b,	//adc a,e
					$8c,	//adc a,h/ixh/ixh
					$8d,	//adc a,l/iyl/iyl
					$8f:	//adc a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$ce:	//adc a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$8e:	//adc a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_ADC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;

					$90,	//sub a,b
					$91,	//sub a,c
					$92,	//sub a,d
					$93,	//sub a,e
					$94,	//sub a,h/ixh/ixh
					$95,	//sub a,l/iyl/iyl
					$97:	//sub a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$d6:	//sub a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$96:	//sub a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;

					$98,	//sbc a,b
					$99,	//sbc a,c
					$9a,	//sbc a,d
					$9b,	//sbc a,e
					$9c,	//sbc a,h/ixh/ixh
					$9d,	//sbc a,l/iyl/iyl
					$9f:	//sbc a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$de:	//sbc a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;
					$9e:	//sbc a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
						end;

					$a0,	//and a,b
					$a1,	//and a,c
					$a2,	//and a,d
					$a3,	//and a,e
					$a4,	//and a,h/ixh/ixh
					$a5,	//and a,l/iyl/iyl
					$a7:	//and a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_AND8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;
					$e6:	//and a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_AND8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;
					$a6:	//and a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_AND8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;

					$a8,	//xor a,b
					$a9,	//xor a,c
					$aa,	//xor a,d
					$ab,	//xor a,e
					$ac,	//xor a,h/ixh/ixh
					$ad,	//xor a,l/iyl/iyl
					$af:	//xor a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, GetReg(REG_A) xor n);
							Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), 0, 0, _SIGN or _ZERO or _PARITY);
						end;
					$ee:	//xor a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, GetReg(REG_A) xor n);
							Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), 0, 0, _SIGN or _ZERO or _PARITY);
						end;
					$ae:	//xor a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, GetReg(REG_A) xor n);
							Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), 0, 0, _SIGN or _ZERO or _PARITY);
						end;

					$b0,	//or a,b
					$b1,	//or a,c
					$b2,	//or a,d
					$b3,	//or a,e
					$b4,	//or a,h/ixh/ixh
					$b5,	//or a,l/iyl/iyl
					$b7:	//or a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;
					$f6:	//or a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;
					$b6:	//or a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_OR8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _PARITY));
						end;

					$b8,	//cp a,b
					$b9,	//cp a,c
					$ba,	//cp a,d
					$bb,	//cp a,e
					$bc,	//cp a,h/ixh/ixh
					$bd,	//cp a,l/iyl/iyl
					$bf:	//cp a,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY);
						end;
					$fe:	//cp a,n
						begin
							n := ReadMemory(GetReg(REG_PC), CYCLE_DATA);
							IncReg(REG_PC);
							Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY);
						end;
					$be:	//cp a,(hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							Alu(GetReg(REG_F) and _MASK, ALU_SBC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY);
						end;

					$04,	//inc b
					$0c,	//inc c
					$14,	//inc d
					$1c,	//inc e
					$24,	//inc h/ixh/ixh
					$2c,	//inc l/iyl/iyl
					$3c:	//inc a
						begin
							r := (op shr 3) and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and (_MASK or _C), ALU_ADC8, n, 1, 0, _SIGN or _ZERO or _HALF or _OVERFLOW);
							SetR(Prefix, r, n);
						end;
					$34:	//inc (hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and (_MASK or _C), ALU_ADC8, n, 1, 0, _SIGN or _ZERO or _HALF or _OVERFLOW);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;
					$05,	//dec b
					$0d,	//dec c
					$15,	//dec d
					$1d,	//dec e
					$25,	//dec h/ixh/ixh
					$2d,	//dec l/iyl/iyl
					$3d:	//dec a
						begin
							r := (op shr 3) and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, n, 1, 0, _SIGN or _ZERO or _HALF or _OVERFLOW);
							SetR(Prefix, r, n);
						end;
					$35:	//dec (hl)/(ix+d)/(iy+d)
						begin
							if Prefix=PREFIX_XX then
								SetReg(REG_ADDR, GetReg(REG_HL))
							else
							begin
								IncReg(REG_ADDR, Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
								IncReg(REG_PC);
								Inc(nTstate, 1 + 4);
							end;
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, n, 1, 0, _SIGN or _ZERO or _HALF or _OVERFLOW);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$27:	//daa
						begin
							//※たぶん間違っている
							if GetFlag(FLAG_N)<>0 then
							begin
								//sub/adc/dec/neg
								n := 0;
								if GetFlag(FLAG_H)<>0 then
									n := n or $06;
								if GetFlag(FLAG_C)<>0 then
									n := n or $60;
								SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _N or _C), ALU_ADC8, GetReg(REG_A), -n, 0, _SIGN or _ZERO or _HALF or _PARITY));
							end else
							begin
								//add/adc/inc
								n := 0;
								if (GetFlag(FLAG_H)<>0) or ((GetReg(REG_A) and $0f)>$09) then
									n := n or $06;
								if (GetFlag(FLAG_C)<>0) or (((GetReg(REG_A)+n) and $f0)>$90) then
									n := n or $60;
								SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _N or _C), ALU_ADC8, GetReg(REG_A), n, 0, _SIGN or _ZERO or _HALF or _PARITY or _CARRY));
							end;
						end;
					$2f:	//cpl
						SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV or _C), ALU_SBC8, $00, GetReg(REG_A), 1, _HALF));
					$3f:	//ccf
						begin
							n := 0;
							if GetFlag(FLAG_C)<>0 then
								n := n or _H;
							if GetFlag(FLAG_C)=0 then
								n := n or _C;
							SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _PV)) or n);
						end;
					$37:	//scf
						SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _PV)) or _C);
					$00:	//nop
						;
					$76:	//halt
          	begin
						  if GetReg(REG_INTREQ)<>0 then
	              SetReg(REG_HALT, 0)
            	else
              begin
	              SetReg(REG_HALT, 1);
                DecReg(REG_PC);
              end;
            end;
					$f3:	//di
						SetReg(REG_IFF1_IFF2, $00);
					$fb:	//ei
						SetReg(REG_IFF1_IFF2, $11);

					$09,	//add hl/ix/iy,bc
					$19,	//add hl/ix/iy,de
					$29,	//add hl/ix/iy,hl/ix/iy
					$39:	//add hl/ix/iy,sp
						begin
							SetReg(REG_ADDR, GetRr(Prefix, 2));
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(Prefix, r));
							SetReg(REG_TEMP, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV), ALU_ADC16, GetReg(REG_ADDR), GetReg(REG_TEMP), 0, _HALF or _CARRY));
							SetRr(Prefix, 2, GetReg(REG_TEMP));
							Inc(nTstate, 4 + 3);	//※クロックが多い
						end;
					$03,	//inc bc
					$13,	//inc de
					$23,	//inc hl/ix/iy
					$33:	//inc sp
						begin
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(Prefix, r));
							IncReg(REG_TEMP);
							SetRr(Prefix, r, GetReg(REG_TEMP));
							Inc(nTstate, 2);
						end;
					$0b,	//dec bc
					$1b,	//dec de
					$2b,	//dec hl/ix/iy
					$3b:	//dec sp
						begin
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(Prefix, r));
							DecReg(REG_TEMP);
							SetRr(Prefix, r, GetReg(REG_TEMP));
							Inc(nTstate, 2);
						end;

					$07:	//rlca
						begin
							n := 0;
							if (GetReg(REG_A) and $80)<>0 then
								n := 1;
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV), ALU_ADC8, GetReg(REG_A), GetReg(REG_A), n, _CARRY));
						end;
					$17:	//rla
						begin
							n := 0;
							if GetFlag(FLAG_C)<>0 then
								n := 1;
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV), ALU_ADC8, GetReg(REG_A), GetReg(REG_A), n, _CARRY));
						end;
					$0f:	//rrca
						begin
							n := 0;
							if (GetReg(REG_A) and $01)<>0 then
								n := 1;
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV), ALU_ROR8, GetReg(REG_A), n, 0, _CARRY));
						end;
					$1f:	//rra
						begin
							n := 0;
							if GetFlag(FLAG_C)<>0 then
								n := 1;
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _S or _Z or _PV), ALU_ROR8, GetReg(REG_A), n, 0, _CARRY));
						end;

					$c3:	//jp nn
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_PC, GetReg(REG_ADDR));
						end;
					$c2,	//jp nz,nn
					$ca,	//jp z,nn
					$d2,	//jp nc,nn
					$da,	//jp c,nn
					$e2,	//jp po,nn
					$ea,	//jp pe,nn
					$f2,	//jp p,nn
					$fa:	//jp m,nn
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							r := (op shr 3) and 7;
							case r of
								0:	n := 1 - GetFlag(FLAG_Z);
								1:	n := GetFlag(FLAG_Z);
								2:	n := 1 - GetFlag(FLAG_C);
								3:	n := GetFlag(FLAG_C);
								4:	n := 1 - GetFlag(FLAG_PV);
								5:	n := GetFlag(FLAG_PV);
								6:	n := 1 - GetFlag(FLAG_S);
								else	n := GetFlag(FLAG_S);
							end;
							if n<>0 then
								SetReg(REG_PC, GetReg(REG_ADDR));
						end;
					$18:	//jr e
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							Inc(nTstate, 1 + 4);
							IncReg(REG_PC, Shortint(GetReg(REG_ADDRL)));
						end;
					$20,	//jr nz,e
					$28,	//jr z,e
					$30,	//jr nc,e
					$38:	//jr c,e
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							r := (op shr 3) and 3;
							case r of
								0:	n := 1 - GetFlag(FLAG_Z);
								1:	n := GetFlag(FLAG_Z);
								2:	n := 1 - GetFlag(FLAG_C);
								else	n := GetFlag(FLAG_C);
							end;
							if n<>0 then
							begin
								Inc(nTstate, 1 + 4);
								IncReg(REG_PC, Shortint(GetReg(REG_ADDRL)));
							end;
						end;
					$e9:	//jp hl/ix/iy
						begin
							SetReg(REG_ADDR, GetRr(Prefix, 2));
							SetReg(REG_PC, GetReg(REG_ADDR));
						end;
					$10:	//djnz e
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							DecReg(REG_B);
							Inc(nTstate, 1);
							if GetReg(REG_B)<>0 then
							begin
								Inc(nTstate, 1 + 4);
								IncReg(REG_PC, Shortint(GetReg(REG_ADDRL)));
							end;
						end;

					$cd:	//call nn
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCH));
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCL));
							Inc(nTstate, 1);
							SetReg(REG_PC, GetReg(REG_ADDR));
						end;
					$c4,	//call nz,nn
					$cc,	//call z,nn
					$d4,	//call nc,nn
					$dc,	//call c,nn
					$e4,	//call po,nn
					$ec,	//call pe,nn
					$f4,	//call p,nn
					$fc:	//call m,nn
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							r := (op shr 3) and 7;
							case r of
								0:	n := 1 - GetFlag(FLAG_Z);
								1:	n := GetFlag(FLAG_Z);
								2:	n := 1 - GetFlag(FLAG_C);
								3:	n := GetFlag(FLAG_C);
								4:	n := 1 - GetFlag(FLAG_PV);
								5:	n := GetFlag(FLAG_PV);
								6:	n := 1 - GetFlag(FLAG_S);
								else	n := GetFlag(FLAG_S);
							end;
							if n<>0 then
							begin
								DecReg(REG_SP);
								WriteMemory(GetReg(REG_SP), GetReg(REG_PCH));
								DecReg(REG_SP);
								WriteMemory(GetReg(REG_SP), GetReg(REG_PCL));
								Inc(nTstate, 1);
								SetReg(REG_PC, GetReg(REG_ADDR));
							end;
						end;
					$c9:	//ret
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_PC, GetReg(REG_ADDR));
						end;
					$c0,	//ret nz
					$c8,	//ret z
					$d0,	//ret nc
					$d8,	//ret c
					$e0,	//ret po
					$e8,	//ret pe
					$f0,	//ret p
					$f8:	//ret m
						begin
							r := (op shr 3) and 7;
							case r of
								0:	n := 1 - GetFlag(FLAG_Z);
								1:	n := GetFlag(FLAG_Z);
								2:	n := 1 - GetFlag(FLAG_C);
								3:	n := GetFlag(FLAG_C);
								4:	n := 1 - GetFlag(FLAG_PV);
								5:	n := GetFlag(FLAG_PV);
								6:	n := 1 - GetFlag(FLAG_S);
								else	n := GetFlag(FLAG_S);
							end;
							Inc(nTstate, 1);
							if n<>0 then
							begin
								SetReg(REG_ADDRL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
								IncReg(REG_SP);
								SetReg(REG_ADDRH, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
								IncReg(REG_SP);
								SetReg(REG_PC, GetReg(REG_ADDR));
							end;
						end;
					$c7,	//rst 00h
					$cf,	//rst 08h
					$d7,	//rst 10h
					$df,	//rst 18h
					$e7,	//rst 20h
					$ef,	//rst 28h
					$f7,	//rst 30h
					$ff:	//rst 38h
						begin
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCH));
							DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCL));
							Inc(nTstate, 1);
							r := (op shr 3) and 7;
							SetReg(REG_PC, r shl 3);
						end;

					$db:	//in a,(n)
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, GetReg(REG_A));
							SetReg(REG_A, ReadIo(GetReg(REG_ADDR)));
						end;
					$d3:	//out (n),a
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, GetReg(REG_A));
							WriteIo(GetReg(REG_ADDR), GetReg(REG_A));
						end;

					$cb:
						begin
							case Prefix of
								PREFIX_DDXX:
									begin
										Prefix := PREFIX_DDCBdXX;
										SetReg(REG_ADDR, GetReg(REG_IX) + Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
										IncReg(REG_PC);
										Inc(nTstate, 1);
									end;
								PREFIX_FDXX:
									begin
										Prefix := PREFIX_FDCBdXX;
										SetReg(REG_ADDR, GetReg(REG_IY) + Shortint(ReadMemory(GetReg(REG_PC), CYCLE_DATA)));
										IncReg(REG_PC);
										Inc(nTstate, 1);
									end;
								else
									begin
										Prefix := PREFIX_CBXX;
										SetReg(REG_ADDR, GetReg(REG_HL));
									end;
							end;
						end;
					$dd:
						begin
							if Prefix<>PREFIX_XX then
              begin
								Result := False;
								Exit;
              end;
							Prefix := PREFIX_DDXX;
							SetReg(REG_ADDR, GetReg(REG_IX));
						end;
					$ed:
						begin
							if Prefix<>PREFIX_XX then
              begin
								Result := False;
								Exit;
              end;
							Prefix := PREFIX_EDXX;
						end;
					$fd:
						begin
							if Prefix<>PREFIX_XX then
              begin
								Result := False;
								Exit;
              end;
							Prefix := PREFIX_FDXX;
							SetReg(REG_ADDR, GetReg(REG_IY));
						end;

					else
            begin
							Result := False;
							Exit;
            end;
				end;
				//
				case op of
					$cb, $dd, $ed, $fd:
						;
					else
						Prefix := PREFIX_XX;
				end;
			end;

		PREFIX_CBXX, PREFIX_DDCBdXX, PREFIX_FDCBdXX:
			begin
				case op of
					$00,	//rlc b
					$01,	//rlc c
					$02,	//rlc d
					$03,	//rlc e
					$04,	//rlc h/ixh/iyh
					$05,	//rlc l/ixl/iyl
					$07:	//rlc a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, (n shr 7) and 1, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$06:	//rlc (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, (n shr 7) and 1, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$08,	//rrc b
					$09,	//rrc c
					$0a,	//rrc d
					$0b,	//rrc e
					$0c,	//rrc h/ixh/iyh
					$0d,	//rrc l/ixl/iyl
					$0f:	//rrc a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, n and 1, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$0e:	//rrc (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, n and 1, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$10,	//rl b
					$11,	//rl c
					$12,	//rl d
					$13,	//rl e
					$14,	//rl h/ixh/iyh
					$15,	//rl l/ixl/iyl
					$17:	//rl a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, GetFlag(FLAG_C), _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$16:	//rl (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, GetFlag(FLAG_C), _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$18,	//rr b
					$19,	//rr c
					$1a,	//rr d
					$1b,	//rr e
					$1c,	//rr h/ixh/iyh
					$1d,	//rr l/ixl/iyl
					$1f:	//rr a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, GetFlag(FLAG_C), 0, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$1e:	//rr (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, GetFlag(FLAG_C), 0, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$20,	//sla b
					$21,	//sla c
					$22,	//sla d
					$23,	//sla e
					$24,	//sla h/ixh/iyh
					$25,	//sla l/ixl/iyl
					$27:	//sla a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$26:	//sla (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ADC8, n, n, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$28,	//sra b
					$29,	//sra c
					$2a,	//sra d
					$2b,	//sra e
					$2c,	//sra h/ixh/iyh
					$2d,	//sra l/ixl/iyl
					$2f:	//sra a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, (n shr 7) and 1, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$2e:	//sra (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, (n shr 7) and 1, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$38,	//srl b
					$39,	//srl c
					$3a,	//srl d
					$3b,	//srl e
					$3c,	//srl h/ixh/iyh
					$3d,	//srl l/ixl/iyl
					$3f:	//srl a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, 0, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							SetR(Prefix, r, n);
						end;
					$3e:	//srl (hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := Alu(GetReg(REG_F) and _MASK, ALU_ROR8, n, 0, 0, _SIGN or _ZERO or _PARITY or _CARRY);
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$40,	//bit 0,b
					$41,	//bit 0,c
					$42,	//bit 0,d
					$43,	//bit 0,e
					$44,	//bit 0,h/ixh/iyh
					$45,	//bit 0,l/ixl/iyl
					$47,	//bit 0,a
					$48,	//bit 1,b
					$49,	//bit 1,c
					$4a,	//bit 1,d
					$4b,	//bit 1,e
					$4c,	//bit 1,h/ixh/iyh
					$4d,	//bit 1,l/ixl/iyl
					$4f,	//bit 1,a
					$50,	//bit 2,b
					$51,	//bit 2,c
					$52,	//bit 2,d
					$53,	//bit 2,e
					$54,	//bit 2,h/ixh/iyh
					$55,	//bit 2,l/ixl/iyl
					$57,	//bit 2,a
					$58,	//bit 3,b
					$59,	//bit 3,c
					$5a,	//bit 3,d
					$5b,	//bit 3,e
					$5c,	//bit 3,h/ixh/iyh
					$5d,	//bit 3,l/ixl/iyl
					$5f,	//bit 3,a
					$60,	//bit 4,b
					$61,	//bit 4,c
					$62,	//bit 4,d
					$63,	//bit 4,e
					$64,	//bit 4,h/ixh/iyh
					$65,	//bit 4,l/ixl/iyl
					$67,	//bit 4,a
					$68,	//bit 5,b
					$69,	//bit 5,c
					$6a,	//bit 5,d
					$6b,	//bit 5,e
					$6c,	//bit 5,h/ixh/iyh
					$6d,	//bit 5,l/ixl/iyl
					$6f,	//bit 5,a
					$70,	//bit 6,b
					$71,	//bit 6,c
					$72,	//bit 6,d
					$73,	//bit 6,e
					$74,	//bit 6,h/ixh/iyh
					$75,	//bit 6,l/ixl/iyl
					$77,	//bit 6,a
					$78,	//bit 7,b
					$79,	//bit 7,c
					$7a,	//bit 7,d
					$7b,	//bit 7,e
					$7c,	//bit 7,h/ixh/iyh
					$7d,	//bit 7,l/ixl/iyl
					$7f:	//bit 7,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							Alu(GetReg(REG_F) and (_MASK or _C), ALU_AND8, n, 1 shl ((op shr 3) and 7), 0, _SIGN or _ZERO or _PARITY);
						end;
					$46,	//bit 0,(hl)/(ix+d)/(iy+d)
					$4e,	//bit 1,(hl)/(ix+d)/(iy+d)
					$56,	//bit 2,(hl)/(ix+d)/(iy+d)
					$5e,	//bit 3,(hl)/(ix+d)/(iy+d)
					$66,	//bit 4,(hl)/(ix+d)/(iy+d)
					$6e,	//bit 5,(hl)/(ix+d)/(iy+d)
					$76,	//bit 6,(hl)/(ix+d)/(iy+d)
					$7e:	//bit 7,(hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							Alu(GetReg(REG_F) and (_MASK or _C), ALU_AND8, n, 1 shl ((op shr 3) and 7), 0, _SIGN or _ZERO or _PARITY);
							Inc(nTstate, 1);
						end;

					$c0,	//set 0,b
					$c1,	//set 0,c
					$c2,	//set 0,d
					$c3,	//set 0,e
					$c4,	//set 0,h/ixh/iyh
					$c5,	//set 0,l/ixl/iyl
					$c7,	//set 0,a
					$c8,	//set 1,b
					$c9,	//set 1,c
					$ca,	//set 1,d
					$cb,	//set 1,e
					$cc,	//set 1,h/ixh/iyh
					$cd,	//set 1,l/ixl/iyl
					$cf,	//set 1,a
					$d0,	//set 2,b
					$d1,	//set 2,c
					$d2,	//set 2,d
					$d3,	//set 2,e
					$d4,	//set 2,h/ixh/iyh
					$d5,	//set 2,l/ixl/iyl
					$d7,	//set 2,a
					$d8,	//set 3,b
					$d9,	//set 3,c
					$da,	//set 3,d
					$db,	//set 3,e
					$dc,	//set 3,h/ixh/iyh
					$dd,	//set 3,l/ixl/iyl
					$df,	//set 3,a
					$e0,	//set 4,b
					$e1,	//set 4,c
					$e2,	//set 4,d
					$e3,	//set 4,e
					$e4,	//set 4,h/ixh/iyh
					$e5,	//set 4,l/ixl/iyl
					$e7,	//set 4,a
					$e8,	//set 5,b
					$e9,	//set 5,c
					$ea,	//set 5,d
					$eb,	//set 5,e
					$ec,	//set 5,h/ixh/iyh
					$ed,	//set 5,l/ixl/iyl
					$ef,	//set 5,a
					$f0,	//set 6,b
					$f1,	//set 6,c
					$f2,	//set 6,d
					$f3,	//set 6,e
					$f4,	//set 6,h/ixh/iyh
					$f5,	//set 6,l/ixl/iyl
					$f7,	//set 6,a
					$f8,	//set 7,b
					$f9,	//set 7,c
					$fa,	//set 7,d
					$fb,	//set 7,e
					$fc,	//set 7,h/ixh/iyh
					$fd,	//set 7,l/ixl/iyl
					$ff:	//set 7,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := n	or (1 shl ((op shr 3) and 7));
							SetR(Prefix, r, n);
						end;
					$c6,	//set 0,(hl)/(ix+d)/(iy+d)
					$ce,	//set 1,(hl)/(ix+d)/(iy+d)
					$d6,	//set 2,(hl)/(ix+d)/(iy+d)
					$de,	//set 3,(hl)/(ix+d)/(iy+d)
					$e6,	//set 4,(hl)/(ix+d)/(iy+d)
					$ee,	//set 5,(hl)/(ix+d)/(iy+d)
					$f6,	//set 6,(hl)/(ix+d)/(iy+d)
					$fe:	//set 7,(hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := n or (1 shl ((op shr 3) and 7));
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					$80,	//res 0,b
					$81,	//res 0,c
					$82,	//res 0,d
					$83,	//res 0,e
					$84,	//res 0,h/ixh/iyh
					$85,	//res 0,l/ixl/iyl
					$87,	//res 0,a
					$88,	//res 1,b
					$89,	//res 1,c
					$8a,	//res 1,d
					$8b,	//res 1,e
					$8c,	//res 1,h/ixh/iyh
					$8d,	//res 1,l/ixl/iyl
					$8f,	//res 1,a
					$90,	//res 2,b
					$91,	//res 2,c
					$92,	//res 2,d
					$93,	//res 2,e
					$94,	//res 2,h/ixh/iyh
					$95,	//res 2,l/ixl/iyl
					$97,	//res 2,a
					$98,	//res 3,b
					$99,	//res 3,c
					$9a,	//res 3,d
					$9b,	//res 3,e
					$9c,	//res 3,h/ixh/iyh
					$9d,	//res 3,l/ixl/iyl
					$9f,	//res 3,a
					$a0,	//res 4,b
					$a1,	//res 4,c
					$a2,	//res 4,d
					$a3,	//res 4,e
					$a4,	//res 4,h/ixh/iyh
					$a5,	//res 4,l/ixl/iyl
					$a7,	//res 4,a
					$a8,	//res 5,b
					$a9,	//res 5,c
					$aa,	//res 5,d
					$ab,	//res 5,e
					$ac,	//res 5,h/ixh/iyh
					$ad,	//res 5,l/ixl/iyl
					$af,	//res 5,a
					$b0,	//res 6,b
					$b1,	//res 6,c
					$b2,	//res 6,d
					$b3,	//res 6,e
					$b4,	//res 6,h/ixh/iyh
					$b5,	//res 6,l/ixl/iyl
					$b7,	//res 6,a
					$b8,	//res 7,b
					$b9,	//res 7,c
					$ba,	//res 7,d
					$bb,	//res 7,e
					$bc,	//res 7,h/ixh/iyh
					$bd,	//res 7,l/ixl/iyl
					$bf:	//res 7,a
						begin
							r := op and 7;
							n := GetR(Prefix, r);
							n := n and ($ff xor (1 shl ((op shr 3) and 7)));
							SetR(Prefix, r, n);
						end;
					$86,	//res 0,(hl)/(ix+d)/(iy+d)
					$8e,	//res 1,(hl)/(ix+d)/(iy+d)
					$96,	//res 2,(hl)/(ix+d)/(iy+d)
					$9e,	//res 3,(hl)/(ix+d)/(iy+d)
					$a6,	//res 4,(hl)/(ix+d)/(iy+d)
					$ae,	//res 5,(hl)/(ix+d)/(iy+d)
					$b6,	//res 6,(hl)/(ix+d)/(iy+d)
					$be:	//res 7,(hl)/(ix+d)/(iy+d)
						begin
							n := ReadMemory(GetReg(REG_ADDR), CYCLE_DATA);
							n := n and ($ff xor (1 shl ((op shr 3) and 7)));
							WriteMemory(GetReg(REG_ADDR), n);
							Inc(nTstate, 1);
						end;

					else
	          begin
							Result := False;
							Exit;
            end;
				end;
				Prefix := PREFIX_XX;
			end;

		PREFIX_EDXX:
			begin
				case op of
					$57:	//ld a,i
						begin
							n := 0;
							if (GetReg(REG_IFF1_IFF2) and $0f)<>0 then
								n := n or _PV;
							SetReg(REG_A, Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_OR8, GetReg(REG_I), 0, 0, _SIGN or _ZERO));
							Inc(nTstate, 1);
						end;
					$5f:	//ld a,r
						begin
							n := 0;
							if (GetReg(REG_IFF1_IFF2) and $0f)<>0 then
								n := n or _PV;
							SetReg(REG_A, Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_OR8, GetReg(REG_R), 0, 0, _SIGN or _ZERO));
							Inc(nTstate, 1);
						end;
					$47:	//ld i,a
						begin
							SetReg(REG_I, GetReg(REG_A));
							Inc(nTstate, 1);
						end;
					$4f:	//ld r,a
						begin
							SetReg(REG_R, GetReg(REG_A));
							Inc(nTstate, 1);
						end;

					$4b,	//ld bc,(nn)
					$5b,	//ld de,(nn)
					$6b,	//ld hl,(nn)
					$7b:	//ld sp,(nn)
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_ADDR), CYCLE_DATA));
							IncReg(REG_ADDR);
							SetReg(REG_TEMPH, ReadMemory(GetReg(REG_ADDR), CYCLE_DATA));
							IncReg(REG_ADDR);
							r := (op shr 4) and 3;
							SetRr(PREFIX_XX, r, GetReg(REG_TEMP));
						end;

					$43,	//ld (nn),bc
					$53,	//ld (nn),de
					$63,	//ld (nn),hl
					$73:	//ld (nn),sp
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_PC), CYCLE_DATA));
							IncReg(REG_PC);
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(PREFIX_XX, r));
							WriteMemory(GetReg(REG_ADDR), GetReg(REG_TEMPL));
							IncReg(REG_ADDR);
							WriteMemory(GetReg(REG_ADDR), GetReg(REG_TEMPH));
							IncReg(REG_ADDR);
						end;

					$a0:	//ldi
						begin
							n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
							WriteMemory(GetReg(REG_DE), n);
							IncReg(REG_DE);
							IncReg(REG_HL);
							DecReg(REG_BC);
							Inc(nTstate, 2);
							n := 0;
							if GetReg(REG_BC)<>0 then
								n := n or _PV;
							SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _C)) or n);
						end;
					$b0:	//ldir
						begin
							while True do
							begin
								n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
								WriteMemory(GetReg(REG_DE), n);
								IncReg(REG_DE);
								IncReg(REG_HL);
								DecReg(REG_BC);
								Inc(nTstate, 2);
								n := 0;
								if GetReg(REG_BC)<>0 then
									n := n or _PV;
								SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _C)) or n);
								if GetFlag(FLAG_PV)=0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;
					$a8:	//ldd
						begin
							n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
							WriteMemory(GetReg(REG_DE), n);
							DecReg(REG_DE);
							DecReg(REG_HL);
							DecReg(REG_BC);
							Inc(nTstate, 2);
							n := 0;
							if GetReg(REG_BC)<>0 then
								n := n or _PV;
							SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _C)) or n);
						end;
					$b8:	//lddr
						begin
							while True do
							begin
								n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
								WriteMemory(GetReg(REG_DE), n);
								DecReg(REG_DE);
								DecReg(REG_HL);
								DecReg(REG_BC);
								Inc(nTstate, 2);
								n := 0;
								if GetReg(REG_BC)<>0 then
									n := n or _PV;
								SetReg(REG_F, (GetReg(REG_F) and (_MASK or _S or _Z or _C)) or n);
								if GetFlag(FLAG_PV)=0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;

					$a1:	//cpi
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
							IncReg(REG_HL);
							DecReg(REG_BC);
							Inc(nTstate, 5);
							n := 0;
							if GetReg(REG_BC)<>0 then
								n := n or _PV;
							Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_SBC8, GetReg(REG_A), GetReg(REG_TEMPL), 0, _SIGN or _ZERO or _HALF);
						end;
					$b1:	//cpir
						begin
							while True do
							begin
								SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
								IncReg(REG_HL);
								DecReg(REG_BC);
								Inc(nTstate, 5);
								n := 0;
								if GetReg(REG_BC)<>0 then
									n := n or _PV;
								Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_SBC8, GetReg(REG_A), GetReg(REG_TEMPL), 0, _SIGN or _ZERO or _HALF);
								if (GetFlag(FLAG_PV)=0) or (GetFlag(FLAG_Z)<>0) then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;
					$a9:	//cpd
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
							DecReg(REG_HL);
							DecReg(REG_BC);
							Inc(nTstate, 5);
							n := 0;
							if GetReg(REG_BC)<>0 then
								n := n or _PV;
							Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_SBC8, GetReg(REG_A), GetReg(REG_TEMPL), 0, _SIGN or _ZERO or _HALF);
						end;
					$b9:	//cpdr
						begin
							while True do
							begin
								SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
								DecReg(REG_HL);
								DecReg(REG_BC);
								Inc(nTstate, 5);
								n := 0;
								if GetReg(REG_BC)<>0 then
									n := n or _PV;
								Alu((GetReg(REG_F) and (_MASK or _C)) or n, ALU_SBC8, GetReg(REG_A), GetReg(REG_TEMPL), 0, _SIGN or _ZERO or _HALF);
								if (GetFlag(FLAG_PV)=0) or (GetFlag(FLAG_Z)<>0) then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;

					$44:	//neg
						SetReg(REG_A, Alu(GetReg(REG_F) and _MASK, ALU_SBC8, $00, GetReg(REG_A), 0, _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));

					$46:	//im 0
						SetReg(REG_IM, 0);
					$56:	//im 1
						SetReg(REG_IM, 1);
					$5e:	//im 2
						SetReg(REG_IM, 2);

					$4a,	//adc hl,bc
					$5a,	//adc hl,de
					$6a,	//adc hl,hl
					$7a:	//adc hl,sp
						begin
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(PREFIX_XX, r));
							SetReg(REG_HL, Alu(GetReg(REG_F) and _MASK, ALU_ADC16, GetReg(REG_HL), GetReg(REG_TEMP), GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
							Inc(nTstate, 4 + 3);	//※クロックが多い
						end;
					$42,	//sbc hl,bc
					$52,	//sbc hl,de
					$62,	//sbc hl,hl
					$72:	//sbc hl,sp
						begin
							r := (op shr 4) and 3;
							SetReg(REG_TEMP, GetRr(PREFIX_XX, r));
							SetReg(REG_HL, Alu(GetReg(REG_F) and _MASK, ALU_SBC16, GetReg(REG_HL), GetReg(REG_TEMP), GetFlag(FLAG_C), _SIGN or _ZERO or _HALF or _OVERFLOW or _CARRY));
							Inc(nTstate, 4 + 3);	//※クロックが多い
						end;

					$6f:	//rld
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
							SetReg(REG_TEMPH, GetReg(REG_A));
							SetReg(REG_TEMP, ((GetReg(REG_TEMP) shl 4) and $0ff0) or (GetReg(REG_TEMPH) and $0f));
							SetReg(REG_TEMPH, GetReg(REG_TEMPH) or (GetReg(REG_A) and $f0));
							WriteMemory(GetReg(REG_HL), GetReg(REG_TEMPL));
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _C), ALU_OR8, GetReg(REG_TEMPH), 0, 0, _SIGN or _ZERO or _PARITY));
							Inc(nTstate, 4);
						end;
					$67:	//rrd
						begin
							SetReg(REG_TEMPL, ReadMemory(GetReg(REG_HL), CYCLE_DATA));
							SetReg(REG_TEMPH, GetReg(REG_A));
							SetReg(REG_TEMP, ((GetReg(REG_TEMPL) shl 8) and $0f00) or ((GetReg(REG_TEMP) shr 4) and $00ff));
							SetReg(REG_TEMPH, GetReg(REG_TEMPH) or (GetReg(REG_A) and $f0));
							WriteMemory(GetReg(REG_HL), GetReg(REG_TEMPL));
							SetReg(REG_A, Alu(GetReg(REG_F) and (_MASK or _C), ALU_OR8, GetReg(REG_TEMPH), 0, 0, _SIGN or _ZERO or _PARITY));
							Inc(nTstate, 4);
						end;

					$4d:	//reti
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_PC, GetReg(REG_ADDR));
              n := GetReg(REG_IFF1_IFF2) and $0f;
							SetReg(REG_IFF1_IFF2, (n shl 4) or n);
						end;
					$45:	//retn
						begin
							SetReg(REG_ADDRL, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_ADDRH, ReadMemory(GetReg(REG_SP), CYCLE_DATA));
							IncReg(REG_SP);
							SetReg(REG_PC, GetReg(REG_ADDR));
              n := GetReg(REG_IFF1_IFF2) and $0f;
							SetReg(REG_IFF1_IFF2, (n shl 4) or n);
						end;

					$40,	//in b,(c)
					$48,	//in c,(c)
					$50,	//in d,(c)
					$58,	//in e,(c)
					$60,	//in h,(c)
					$68,	//in l,(c)
					$78:	//in a,(c)
						begin
							n := ReadIo(GetReg(REG_BC));
							r := (op shr 3) and 7;
							SetR(PREFIX_XX, r, n);
							Alu(GetReg(REG_F) and (_MASK or _C), ALU_OR8, n, 0, 0, _SIGN or _ZERO or _PARITY);
						end;
					$70:	//in f,(c)
						begin
							n := ReadIo(GetReg(REG_BC));
							Alu(GetReg(REG_F) and (_MASK or _C), ALU_OR8, n, 0, 0, _SIGN or _ZERO or _PARITY);
						end;

					$a2:	//ini
						begin
							n := ReadIo(GetReg(REG_BC));
							WriteMemory(GetReg(REG_HL), n);
							IncReg(REG_HL);
							Inc(nTstate, 1);
							SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
						end;
					$b2:	//inir
						begin
							while True do
							begin
								n := ReadIo(GetReg(REG_BC));
								WriteMemory(GetReg(REG_HL), n);
								IncReg(REG_HL);
								Inc(nTstate, 1);
								SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
								if GetFlag(FLAG_Z)<>0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;
					$aa:	//ind
						begin
							n := ReadIo(GetReg(REG_BC));
							WriteMemory(GetReg(REG_HL), n);
							DecReg(REG_HL);
							Inc(nTstate, 1);
							SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
						end;
					$ba:	//indr
						begin
							while True do
							begin
								n := ReadIo(GetReg(REG_BC));
								WriteMemory(GetReg(REG_HL), n);
								DecReg(REG_HL);
								Inc(nTstate, 1);
								SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
								if GetFlag(FLAG_Z)<>0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;

					$41,	//out (c),b
					$49,	//out (c),c
					$51,	//out (c),d
					$59,	//out (c),e
					$61,	//out (c),h
					$69,	//out (c),l
					$79:	//out (c),a
						begin
							r := (op shr 3) and 7;
							n := GetR(PREFIX_XX, r);
							WriteIo(GetReg(REG_BC), n);
						end;

					$a3:	//outi
						begin
							n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
							WriteIo(GetReg(REG_BC), n);
							IncReg(REG_HL);
							Inc(nTstate, 1);
							SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
						end;
					$b3:	//otir
						begin
							while True do
							begin
								n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
								WriteIo(GetReg(REG_BC), n);
								IncReg(REG_HL);
								Inc(nTstate, 1);
								SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
								if GetFlag(FLAG_Z)<>0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;
					$ab:	//outd
						begin
							n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
							WriteIo(GetReg(REG_BC), n);
							DecReg(REG_HL);
							Inc(nTstate, 1);
							SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
						end;
					$bb:	//otdr
						begin
							while True do
							begin
								n := ReadMemory(GetReg(REG_HL), CYCLE_DATA);
								WriteIo(GetReg(REG_BC), n);
								DecReg(REG_HL);
								Inc(nTstate, 1);
								SetReg(REG_B, Alu(GetReg(REG_F) and (_MASK or _C), ALU_SBC8, GetReg(REG_B), 1, 0, _ZERO));
								if GetFlag(FLAG_Z)<>0 then
									Break;
								Inc(nTstate, 1 + 4);
								{op := }ReadMemory(GetReg(REG_PC)-2, CYCLE_OPCODE);
								{op := }ReadMemory(GetReg(REG_PC)-1, CYCLE_OPCODE);
							end;
						end;

					else
            begin
							Result := False;
							Exit;
            end;
				end;
				Prefix := PREFIX_XX;
			end;

		else
      begin
				Result := False;
				Exit;
      end;
	end;

	//
  if Prefix=PREFIX_XX then
  begin
    //
    if False then
    begin
			pc := GetReg(REG_PC);
			if DebugMemRead[pc]=0 then
			begin
				DebugMemRead[pc] := 1;
				s := 'AF='+LowerCase(IntToHex(GetReg(REG_AF), 4))+'(';
				if GetFlag(FLAG_S)<>0 then
					s := s + 'S'
				else
					s := s + '.';
				if GetFlag(FLAG_Z)<>0 then
					s := s + 'Z'
				else
					s := s + '.';
				if (GetReg(REG_F) and $20)<>0 then
					s := s + '1'
				else
					s := s + '.';
				if GetFlag(FLAG_H)<>0 then
					s := s + 'H'
				else
					s := s + '.';
				if (GetReg(REG_F) and $08)<>0 then
					s := s + '1'
				else
					s := s + '.';
				if GetFlag(FLAG_PV)<>0 then
					s := s + 'P'
				else
					s := s + '.';
				if GetFlag(FLAG_N)<>0 then
					s := s + 'N'
				else
					s := s + '.';
				if GetFlag(FLAG_C)<>0 then
					s := s + 'C'
				else
					s := s + '.';
				s := s + '),BC='+LowerCase(IntToHex(GetReg(REG_BC), 4))+
					',DE='+LowerCase(IntToHex(GetReg(REG_DE), 4))+
					',HL='+LowerCase(IntToHex(GetReg(REG_HL), 4))+
					',SP='+LowerCase(IntToHex(GetReg(REG_SP), 4))+
					',IX='+LowerCase(IntToHex(GetReg(REG_IX), 4))+
					',IY='+LowerCase(IntToHex(GetReg(REG_IY), 4))+
					Chr($09) +IntToStr(nTstate)+
					Chr($09) +LowerCase(IntToHex(pc, 4))+'=';
				s := s + LowerCase(IntToHex(ReadMemory(pc, CYCLE_NOP), 2))+
					LowerCase(IntToHex(ReadMemory((pc+1) and $ffff, CYCLE_NOP), 2))+
					LowerCase(IntToHex(ReadMemory((pc+2) and $ffff, CYCLE_NOP), 2))+
					LowerCase(IntToHex(ReadMemory((pc+3) and $ffff, CYCLE_NOP), 2));
				slDebugLog.Add(s);
			end;
    end;
    //
		if (GetReg(REG_INTREQ)<>0) then
    begin
    	if True then
      begin
	 	  	SetReg(REG_INTREQ, 0);
      end else
      if (GetReg(REG_IFF1_IFF2) and $f0)<>0 then
		  begin
	 	  	SetReg(REG_INTREQ, 0);
  	  	case GetReg(REG_IM) of
  		   	1:
	    	  	begin
		      		DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCH));
	   	  			DecReg(REG_SP);
							WriteMemory(GetReg(REG_SP), GetReg(REG_PCL));
							Inc(nTstate, 1);
							SetReg(REG_PC, $0038);
        	  end;
        end;
        SetReg(REG_IFF1_IFF2, (GetReg(REG_IFF1_IFF2) shr 4) and $0f);
     	end;
    end;
	end;

	//
	Result := True;
end;

end.

