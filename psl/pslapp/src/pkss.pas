unit pkss;

interface

uses
	Windows, SysUtils, Classes, Types, Math, IniFiles, cpu_z80;

type
	PKssHeader = ^TKssHeader;
	TKssHeader = packed record
		//$00 'KSCC'
		Magic: array[0..3] of Byte;
    //$04 読み込み開始アドレス
    wLoadAddress: Word;
    //$06 初期化データ長
    wInitLength: Word;
    //$08 初期化アドレス
    wInitAddress: Word;
    //$0a 再生アドレス
    wPlayAddress: Word;
		//$0c 開始バンク番号
    byBankOffset: Byte;
    //$0d 拡張データ設定
    byExtra: Byte;
    //$0e 予約
    byReserve: Byte;
    //$0f 拡張音源
    bySoundChip: Byte;
  end;

const
	DEVKSS0_PSG		 		= 0;
	DEVKSS0_SCC		 		= 1;
	DEVKSS0_052539	 	= 2;
	DEVKSS0_OPLL		 	= 3;
	DEVKSS0_MSXAUDIO	= 4;
	DEVKSS1_DCSG 	 		= 0;
	DEVKSS1_OPLL		 	= 1;

type
	TKss = class(TCpuZ80)
  private
    { Private 宣言 }
    nNumber: Integer;
    nClock, nTimeLim: Int64;
	  nIntrTstate: Int64;
    nSync, nSync2: Int64;
    byRegBank: Byte;
		RegSccBank: array[0..2-1] of Byte;
		byPsgAddr, byOpllAddr, byMsxaudioAddr: Byte;
		RegPsg: array[0..$10-1] of Byte;
		RegScc: array[0..$100-1] of Byte;
		Reg052539: array[0..$100-1] of Byte;
    byReg052539Mode: Byte;
		RegOpll: array[0..$40-1] of Byte;
		RegMsxaudio: array[0..$100-1] of Byte;
    //
    slLog: TStringList;
    CmdToReqno: array[0..$ff] of Integer;
		OpllInst: array[0..2] of array[0..18] of array[0..7] of Byte;
		function MaskReg(conno: Integer; info: DWORD; addr: DWORD; data: PWORD): Boolean;
		procedure WriteBuf(thn, conno: Integer; addr: DWORD; data: Word);
		procedure WriteDevice(cmd: Integer; regaddr, regdata: Word);
  public
    { Public 宣言 }
    Header: TKssHeader;
    bNtsc: Boolean;
		xRatio: Extended;
    nTimerInfo1, nTimerInfo2: Int64;
    nFrameLim: Int64;
		Memory: array[0..$10000-1] of Byte;
		BankMemory: array[0..128*$4000-1] of Byte;
    nBankBlocks: Integer;
    bBank8k: Boolean;
    function ReadMemory(addr: Word; cycle: TMemoryCycle): Byte; override;
    procedure WriteMemory(addr: Word; n: Byte); override;
    function ReadIo(addr: Word): Byte; override;
    procedure WriteIo(addr: Word; n: Byte); override;
    procedure PkssInit(kssh: TKssHeader; num: Integer; tlim: Int64);
    procedure PkssReset;
    procedure PkssBegin;
    procedure PkssEnd(term: Boolean);
    function PkssExecute: Boolean;
  protected
    { protected 宣言 }
  published
    { published 宣言 }
		constructor Create;
    destructor Destroy; override;
  end;

type
  TKssThread = class(TThread)
  private
    { Private 宣言 }
  public
    { Public 宣言 }
  protected
    { protected 宣言 }
    procedure Execute; override;
  published
    { published 宣言 }
		constructor Create;
  end;

implementation

uses Unit1, Unit2, output;

function TKss.ReadMemory(addr: Word; cycle: TMemoryCycle): Byte;
	var
  	i: Integer;
begin
	//
  inherited ReadMemory(addr, cycle);

	//
	case (addr shr 12) and $f of
		$8..$b:
			begin
				if bBank8k=True then
				begin
					//8k
          i := 0;
          if (addr and $2000)<>0 then
          	i := 1;
					if (RegSccBank[i]<Header.byBankOffset) or (RegSccBank[i]>=(Header.byBankOffset+nBankBlocks)) then
          else
          begin
						Result := BankMemory[((RegSccBank[i]-Header.byBankOffset)*$2000) or (addr and $1fff)];
            Exit;
          end;
				end else
				begin
					//16k
					if (byRegBank<Header.byBankOffset) or (byRegBank>=(Header.byBankOffset+nBankBlocks)) then
					else
          begin
						Result := BankMemory[((byRegBank-Header.byBankOffset)*$4000) or (addr and $3fff)];
            Exit;
          end;
				end;
			end;
		else
			begin
				//ram
			end;
	end;
	Result := Memory[addr];
end;

procedure TKss.WriteMemory(addr: Word; n: Byte);
	var
  	i: Integer;
begin
	//
  inherited WriteMemory(addr, n);

	//
	case (addr shr 12) and $f of
		$8..$b:
			begin
				if bBank8k=True then
				begin
					//8k
				end else
				begin
					//16k
					if (byRegBank<Header.byBankOffset) or (byRegBank>=(Header.byBankOffset+nBankBlocks)) then
					begin
						//範囲外
						if (Header.bySoundChip and $04)<>0 then
            begin
							Memory[addr] := n;
							Exit;
						end;
					end;
				end;
				//scc/052539
				case addr and $ff00 of
					$9000, $9100, $9200, $9300, $9400, $9500, $9600, $9700,
					$b000, $b100, $b200, $b300, $b400, $b500, $b600, $b700:
						begin
							//scc/052539
		          i := 0;
    		      if (addr and $2000)<>0 then
        		  	i := 1;
							RegSccBank[i] := n;
						end;
					$9800, $9900, $9a00, $9b00, $9c00, $9d00, $9e00, $9f00:
						begin
							//scc/052539
							if (byReg052539Mode and $20)<>0 then
							begin
								//052539
                WriteDevice(DEVKSS0_052539, addr, n);
								Reg052539[addr and $ff] := n;
							end else
							begin
								//scc
								WriteDevice(DEVKSS0_SCC, addr, n);
								RegScc[addr and $ff] := n;
							end;
						end;
					$b800, $b900, $ba00, $bb00:
						begin
							//052539
							WriteDevice(DEVKSS0_052539, addr, n);
							Reg052539[addr and $ff] := n;
						end;
					$bc00, $bd00, $be00, $bf00:
						begin
							//052539
							if (addr and $fffe)=$bffe then
								byReg052539Mode := n;
						end;
				end;
			end;
		else
			begin
				//ram
				Memory[addr] := n;
			end;
	end;
end;

function TKss.ReadIo(addr: Word): Byte;
	var
  	ioaddr: Word;
begin
  //
  inherited ReadIo(addr);

	//
	ioaddr := addr and $ff;
	case ioaddr of
		$a2:	//ay3-8910 read port(r)
			Result := RegPsg[byPsgAddr];
		else
			Result := $ff;
	end;
end;

procedure TKss.WriteIo(addr: Word; n: Byte);
	var
  	ioaddr: Word;
begin
	//
  inherited WriteIo(addr, n);

	//
	ioaddr := addr and $ff;
	case ioaddr of
		$a0:	//ay3-8910 address port(w)
			byPsgAddr := n and $0f;
		$a1:	//ay3-8910 data port(w)
			begin
				WriteDevice(DEVKSS0_PSG, byPsgAddr, n);
				RegPsg[byPsgAddr] := n;
			end;
		$7c:	//fmpac address port(w)
			byOpllAddr := n and $3f;
		$7d:	//fmpac data port(w)
			begin
      	WriteDevice(DEVKSS0_OPLL, byOpllAddr, n);
				RegOpll[byOpllAddr] := n;
			end;
		$c0:	//msx-audio address port(w)
			byMsxaudioAddr := n;
		$c1:	//msx-audio data port(w)
			begin
				WriteDevice(DEVKSS0_MSXAUDIO, byMsxaudioAddr, n);
				RegMsxaudio[byMsxaudioAddr] := n;
			end;
		$fe:	//kss 16kbytes-banked rom select port(w)
			byRegBank := n;
		else
			;
	end;
end;

constructor TKss.Create;
begin
  //
  inherited;
	slLog := TStringList.Create;
end;

destructor TKss.Destroy;
begin
	//
  if (MainForm.bDebug=True) and (slLog.Count>0) then
    slLog.SaveToFile('.\_psldebug_pkss.txt');
 	slLog.Free;
  inherited;
end;

procedure TKss.PKssInit(kssh: TKssHeader; num: Integer; tlim: Int64);
begin
	//
  Header := kssh;
  nNumber := num;
  nClock := 3579545;
  nTimeLim := tlim;
  xRatio := 1;

  //
  bNtsc := True;
  if bNtsc=True then
  begin
		//(3.579545e6*6)/(1368*262)=59.92_27434043123
  	nTimerInfo1 := 1368*262;
    nTimerInfo2 := nClock*6;
  end else
  begin
		//(3.579545e6*6)/(1368*313)=50.15_89737122359
  	nTimerInfo1 := 1368*313;
    nTimerInfo2 := nClock*6;
  end;
  nFrameLim := 0;
	nBankBlocks := Header.byExtra and $7f;
  bBank8k := False;
  if (Header.byExtra and (1 shl 7))<>0 then
  	bBank8k := True;

	//
  FillChar(Memory, SizeOf(Memory), $00);
	FillChar(Memory, $4000, $c9);
  Memory[$0001] := $d3;
 	Memory[$0002] := $a0;
  Memory[$0003] := $f5;
 	Memory[$0004] := $7b;
  Memory[$0005] := $d3;
 	Memory[$0006] := $a1;
 	Memory[$0007] := $f1;
  Memory[$0008] := $c9;
  Memory[$0093] := $c3;
 	Memory[$0094] := $01;
  Memory[$0095] := $00;
  Memory[$0009] := $d3;
 	Memory[$000a] := $a0;
  Memory[$000b] := $db;
 	Memory[$000c] := $a2;
  Memory[$000d] := $c9;
  Memory[$0096] := $c3;
 	Memory[$0097] := $09;
  Memory[$0098] := $00;
  //
  FillChar(BankMemory, SizeOf(BankMemory), $00);
end;

procedure TKss.PkssReset;
	var
  	addr: Integer;
begin
	//
  inherited Reset;

  //
  nFrameLim := Ceil((nTimeLim*nTimerInfo2)/(1000*nTimerInfo1));
  nIntrTstate := 0;
  SetReg(REG_IM, 1);
	SetReg(REG_A, nNumber and $ff);
	addr := $f380-12;
	SetReg(REG_SP, addr);
	SetReg(REG_PC, addr);
	Memory[addr] := $cd;
	Memory[addr+1] := Header.wInitAddress and $ff;
	Memory[addr+2] := (Header.wInitAddress shr 8) and $ff;
	Memory[addr+3] := $76;
	Memory[addr+4] := $cd;
	Memory[addr+5] := Header.wPlayAddress and $ff;
	Memory[addr+6] := (Header.wPlayAddress shr 8) and $ff;
	Memory[addr+7] := $18;
	Memory[addr+8] := $fa;

	//
	byRegBank := $00;
	FillChar(RegSccBank, SizeOf(RegSccBank), $00);
  //
	byPsgAddr := $00;
	FillChar(RegPsg, SizeOf(RegPsg), $00);
  FillChar(RegScc, SizeOf(RegScc), $00);
  FillChar(Reg052539, SizeOf(Reg052539), $00);
  byReg052539Mode := $00;
  byOpllAddr := $00;
  FillChar(RegOpll, SizeOf(RegOpll), $00);
  byMsxaudioAddr := $00;
  FillChar(RegMsxaudio, SizeOf(RegMsxaudio), $00);
end;


var
  DevSts: array[0..CONNECT_DEVMAX-1] of TDeviceStatus;

procedure TKss.PkssBegin;
	var
  	i, j, cmd: Integer;
	var
  	k: Integer;
    regaddr2, regdata2: Word;
	var
  	path: String;
		nTh, conno: Integer;
  var
	  ini: TIniFile;
    s: String;
  	v: Integer;
begin
  //
	for i := 0 to (SizeOf(CmdToReqno) div SizeOf(CmdToReqno[0]))-1 do
  	CmdToReqno[i] := -1;
  with TStringList.Create do
  begin
	  try
			for i := 0 to REQUEST_DEVMAX-1 do
			begin
 				if DeviceForm.ReqDevice[i].bAlloc=True then
        begin
	       	CommaText := DeviceForm.ReqDevice[i].Command;
  				for j := 0 to Count-1 do
			    begin
				  	cmd := StrToIntDef(Strings[j], -1);
            if (cmd>=0) and (cmd<(SizeOf(CmdToReqno) div SizeOf(CmdToReqno[0]))) then
            	CmdToReqno[cmd] := i;
          end;
		  	end;
			end;
	  finally
  		Free;
    end;
  end;

  //
  nSync := 0;
  nSync2 := 0;
	PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, (nTimeLim div 1000) and $ffffffff, 0);

	//
	FillChar(DevSts, SizeOf(DevSts), $00);
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //opna
    FillChar(DevSts[i].Opna.wTl, SizeOf(DevSts[i].Opna.wTl), $ff);
    DevSts[i].Opna.dwOldAddr := $ffffffff;
    DevSts[i].Opna.nAdpcmLen := 0;
    FillChar(DevSts[i].Opna.AdpcmBuf, SizeOf(DevSts[i].Opna.AdpcmBuf), $00);
    FillChar(DevSts[i].Opna.Reg, SizeOf(DevSts[i].Opna.Reg), $00);
    //opll
    DevSts[i].Opll.nMelodyCh := 9;
    FillChar(DevSts[i].Opll.Reg, SizeOf(DevSts[i].Opll.Reg), $00);
    //msxaudio
    FillChar(DevSts[i].Msxaudio.Reg, SizeOf(DevSts[i].Msxaudio.Reg), $00);
  end;

  nTh := 0;
  //
	FillChar(OpllInst, SizeOf(OpllInst), $00);
	if MainForm.ThreadCri[nTh].bOpl2Opll=True then
  begin
  	//
    with TStringList.Create do
    begin
		  try
				for i := 0 to 2 do
				begin
  			  path := MainForm.ThreadCri[nTh].Opl2OpllInst[i];
	  	  	if FileExists(path)=True then
	    		begin
					  ini := TIniFile.Create(path);
           	try
	          	for j := 0 to 18 do
 		          begin
						    CommaText := ini.ReadString(IntToStr(0), IntToStr(j), '');
                if Count>=8 then
                begin
                	for k := 0 to Min(Count, 8)-1 do
                  begin
                    v := MainForm.StringToIntDef(Strings[k], -1);
                    if (v<$00) or (v>$ff) then
                    begin
											FillChar(OpllInst[i][j], SizeOf(OpllInst[i][j]), $00);
                    	Break;
                    end else
	                  	OpllInst[i][j][k] := v;
                  end;
                end;
   		        end;
            finally
             	ini.Free;
            end;
	      	end;
	      end;
		  finally
      	Free;
    	end;
		end;
    //
    if MainForm.bDebug=True then
    begin
			for i := 0 to 2 do
			begin
      	s := 'OpllInst[' +IntToStr(i)+ ']';
        sllog.Add(s);
     		for j := 0 to 18 do
    	  begin
	      	s := IntToStr(j)+ '=';
          for k := 0 to 7 do
          begin
            if k>0 then
            	s := s + ',';
          	s := s + '0x'+LowerCase(IntToHex(OpllInst[i][j][k], 2));
          end;
          sllog.Add(s);
  	    end;
	    end;
    end;
  end;

  //
	for i := 0 to REQUEST_DEVMAX-1 do
	begin
  	//
		conno := DeviceForm.ReqDevice[i].nNo;
		if conno<0 then
    	Continue;
    //
    nTh := DeviceForm.CnDevice[conno].nThread;
    case DeviceForm.CnDevice[conno].nInfo of
     	DEVICE_OPL2, DEVICE_OPL3, DEVICE_OPL3L, DEVICE_OPL3NL_OPL,
      DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL, DEVICE_DS1, DEVICE_SOLO1:
       	begin
					case DeviceForm.ReqDevice[i].nInfo of
           	DEVICE_OPLL, DEVICE_OPLLP, DEVICE_VRC7:
             	begin
               	//OPLL/OPLLP/VRC7→OPL2/OPL3/OPL4/DS1/SOLO1
								if MainForm.ThreadCri[nTh].bOpl2Opll=True then
      			    begin
                  regaddr2 := $01; regdata2 := $20;	WriteBuf(nTh, conno, regaddr2, regdata2);
                  if False then
                  begin
                  	//※テスト用
//				            regdata2 := regdata2 or (1 shl 1);
//				            regdata2 := regdata2 or (1 shl 4);
//				            regdata2 := regdata2 or (1 shl 6);
                    WriteBuf(nTh, conno, regaddr2, regdata2);
                  end;
									regaddr2 := $08; regdata2 := $40;	WriteBuf(nTh, conno, regaddr2, regdata2);
                  //
									regaddr2 := $bd; regdata2 := $c0;	WriteBuf(nTh, conno, regaddr2, regdata2);
                  if DeviceForm.ReqDevice[i].nInfo=DEVICE_VRC7 then
                  	DevSts[conno].Opll.nMelodyCh := 6;
                  //
							    if DeviceForm.CnDevice[conno].nInfo<>DEVICE_OPL2 then
                  begin
										regaddr2 := $0105;
                    regdata2 := $01;
                    WriteBuf(nTh, conno, regaddr2, regdata2);
                    for j := 0 to 8 do
                    begin
											regaddr2 := $c0+j;
                      regdata2 := $30;
											if MainForm.ThreadCri[nTh].bOpl3OpllMoRo=True then
	                      regdata2 := $10;
                      if MainForm.ThreadCri[nTh].bOpl3ChannelChg=True then
                      	regdata2 := ((regdata2 and $c0) shr 2) or ((regdata2 and $30) shl 2) or (regdata2 and $0f);
                      WriteBuf(nTh, conno, regaddr2, regdata2);
                    end;
                  end;
                end;
            	end;
          end;
        end;
    end;
  end;
end;

procedure TKss.PkssEnd(term: Boolean);
	var
  	i: Integer;
begin
	//
 	if term=False then
  begin
   	//終端
		for i := 0 to OUTPUT_THREADMAX-1 do
			WriteBuf(i, 0, CMD_EOF, 0);
  end else
  begin
   	//停止
		for i := 0 to OUTPUT_THREADMAX-1 do
    begin
		  MainForm.ThreadCri[i].Cri.Enter;
		 	MainForm.ThreadCri[i].nLength := -1;
			MainForm.ThreadCri[i].Cri.Leave;
  	end;
  end;
end;

function TKss.PkssExecute: Boolean;
	var
  	f: Boolean;
    i, j: Integer;
    lim, tm: Int64;
begin
	//
	f := True;
  lim := nClock*nTimerInfo1;
  while nFrameLim>0 do
  begin
		//
		if (nTstate-nIntrTstate)*nTimerInfo2>=lim then
   	begin
			Inc(nIntrTstate, nTstate - nIntrTstate);
      Dec(nFrameLim);
      SetReg(REG_INTREQ, 1);
			//
			Inc(nSync, 1*nTimerInfo1*FREQ_SYNC);
			tm := Round(nSync*xRatio-nSync2) div nTimerInfo2;
			Inc(nSync2, tm*nTimerInfo2);
			while tm>0 do
			begin
				j := Min($fff, tm);
        Dec(tm, j);
				for i := 0 to OUTPUT_THREADMAX-1 do
					WriteBuf(i, 0, CMD_SYNC, j);
	    end;
	 	  Break;
		end;
		//
   	if (GetReg(REG_HALT)<>0) and (GetReg(REG_INTREQ)=0) then
    begin
 	  	//halt中、割り込みなし
			{op := }ReadMemory(GetReg(REG_PC), CYCLE_OPCODE);
    end else
 	  begin
		  f := inherited Execute;
	  	if f=False then
    	begin
//				LogEdit.Lines.Add('エラー:正しくない命令($'+IntToHex(GetReg(REG_PC), 4)+')');
	 	 		Break;
	    end;
		end;
  end;
  //
	Result := f;
end;

procedure TKss.WriteBuf(thn, conno: Integer; addr: DWORD; data: Word);
	var
  	s: String;
  	len, n: Integer;
begin
	//
  if MainForm.ThreadCri[thn].bEnable=False then
  	Exit;

  //
	if MainForm.bDebug=True then
  begin
  	s := IntToStr(thn) + ',' + IntToStr(conno) + ',' + IntToHex(addr, 8) + ',' + IntToHex(data, 4);
    slLog.Add(s);
  end;

  //
  while True{Terminated=False} do
  begin
    //
    MainForm.ThreadCri[thn].Cri.Enter;
    len := MainForm.ThreadCri[thn].nLength;
		MainForm.ThreadCri[thn].Cri.Leave;
    if (len+1)<=MainForm.ThreadCri[thn].nBufSize then
    begin
			//
		  n := MainForm.ThreadCri[thn].nWritePtr mod MainForm.ThreadCri[thn].nBufSize;
		  MainForm.ThreadCri[thn].Buf[n].byNo := conno;
		  MainForm.ThreadCri[thn].Buf[n].dwAddr := addr;
		  MainForm.ThreadCri[thn].Buf[n].wData := data;
			DevSts[conno].Reg[addr and $ffff] := data;
			Inc(MainForm.ThreadCri[thn].nWritePtr);
			//
		  MainForm.ThreadCri[thn].Cri.Enter;
		 	Inc(MainForm.ThreadCri[thn].nLength);
			MainForm.ThreadCri[thn].Cri.Leave;
    	Break;
    end;
    //
    Sleep(10);
  end;
end;

function TKss.MaskReg(conno: Integer; info: DWORD; addr: DWORD; data: PWORD): Boolean;
begin
	//
  Result := False;
	case info of
  	DEVICE_USART:
    	begin
	    	case addr of
        	$0000..$0001:
          	begin
							//レジスタ書き込み
              //※USARTにあるレジスタ
              //  +0 $00
              //  +1 アドレス（$00～$01）
              //  +2 データ
          		Result := True;
            end;
        	$0100..$0101:
          	begin
							//送受信クロック
              //※USARTにはないレジスタ
              //  +0 $01
              //  +1 $00..$01
              //  +2 分周値 下位/上位
	          	Result := True;
            end;
        end;
      end;
		DEVICE_PIT:
			begin
	    	case addr of
        	$0000..$0003:
          	begin
							//レジスタ書き込み
              //※PITにあるレジスタ
              //  +0 $00
              //  +1 アドレス（$00～$03）
              //  +2 データ
          		Result := True;
            end;
          $0100:
          	begin
							//出力
              //※PITにはないレジスタ
              //  +0 $01
              //  +1 $00
              //  +2 B7-3 0（未使用）
              //  	 B2 OUT2、出力ON/OFF#
							//  	 B1 OUT1、出力ON/OFF#
							//  	 B0 OUT0、出力ON/OFF#
	          	Result := True;
            end;
          $0101:
          	begin
							//音量
              //※PITにはないレジスタ
              //  +0 $01
							//  +1 $01
              //  +2 B7-6 0（未使用）
							//  	 B5-4 OUT2、音量（0:OFF、1:小、2:中、3:大）
							//  	 B3-2 OUT1、音量（0:OFF、1:小、2:中、3:大）
							//  	 B1-0 OUT0、音量（0:OFF、1:小、2:中、3:大）
	          	Result := True;
            end;
        end;
			end;
		DEVICE_PSG, DEVICE_SSG, DEVICE_SSGL:
			begin
       	case addr of
	       	$0000..$0006, $0008..$000c:
          	Result := True;
      	 	$0007:
        	  begin
			    		data^ := data^ or $c0;
	          	Result := True;
	        	end;
          $000d:
          	begin
            	//epsg, mode select
			    		data^ := data^ and $0f;
	          	Result := True;
            end;
    	    $000e..$000f:
      	    begin
        	  	//psg/ssg, io
              //ssgl, test
        		end;
        end;
			end;
		DEVICE_EPSG:
			begin
       	case DevSts[conno].Reg[$000d] and $f0 of
        	$a0:
          	begin
            	//expanded capability mode-bank a
	      		 	case addr of
	    	  		 	$0000..$0006, $0008..$000d:
    	  	    		Result := True;
	  	  	  	 	$0007:
		  	      	  begin
			    					data^ := data^ or $c0;
	      	    			Result := True;
	        				end;
    	  			  $000e..$000f:
      			  	  begin
    		    	  		//psg/ssg, io
	  		      		end;
			        end;
            end;
          $b0:
          	begin
            	//expanded capability mode-bank b
	      		 	case addr of
	    	  		 	$0000..$000a, $000d:
    	  	    		Result := True;
			        end;
            end;
          else
          	begin
            	//ay38910a-compatibility mode
			       	case addr of
				       	$0000..$0006, $0008..$000d:
			          	Result := True;
			      	 	$0007:
			        	  begin
						    		data^ := data^ or $c0;
				          	Result := True;
				        	end;
			    	    $000e..$000f:
			      	    begin
			        	  	//psg/ssg, io
			        		end;
			        end;
            end;
        end;
      end;
		DEVICE_DCSG:
			begin
	    	case addr of
        	$0000:
          	Result := True;
        end;
			end;
		DEVICE_DCSG_GG, DEVICE_DCSG_NGP:
			begin
	    	case addr of
        	$0000..$0001:
          	Result := True;
          $0002..$0003:
          	if info=DEVICE_DCSG_NGP then
	          	Result := True;
        end;
			end;
    DEVICE_SAA1099:
    	begin
      	case addr of
        	$0000..$0005, $0008..$000d, $0010..$0012, $0014..$0016, $0018..$0019, $001c:
          	Result := True;
        end;
      end;
		DEVICE_OPM, DEVICE_OPP:
			begin
	    	case addr of
        	$0000..$0007:
          	begin
            	if info=DEVICE_OPM then
              begin
	            	//opm, test
                if addr=$0001 then
			          	Result := True;
              end else
              begin
              	//opp/opz, ?
		          	Result := True;
              end;
            end;
        	$0008:
          	begin
            	//opm/opp/opz, sn/ch
	          	Result := True;
            end;
        	$0009:
          	begin
            	if info=DEVICE_OPP then
              begin
	              //opp/opz, ?
	          		Result := True;
              end;
            end;
        	$000f..$0012:
          	begin
            	//opm/opp/opz, ne/nfrq
            	//opm/opp/opz, clka1
            	//opm/opp/opz, clka2
            	//opm/opp/opz, clkb
	          	Result := True;
            end;
        	$0014:
          	begin
            	//opm/opp, csm/f reset/irq en/load
            	//opz, csm/?/f reset/irq en/load
			    		data^ := data^ and $b3;
	          	Result := True;
            end;
        	$0018..$0019:
          	begin
            	//opm/opp/opz, lfrq
            	//opm/opp/opz, pmd/amd
	          	Result := True;
            end;
        	$001b:
          	begin
            	//opm/opp, ct/w
            	//opz, ct/?/w
			    		data^ := data^ and $03;
	          	Result := True;
            end;
        	$0020..$0027:
          	begin
            	//opm/opp, rl/fb/conect
            	//opz, ch/fb/conect
	          	Result := True;
            end;
        	$0028..$002f:
          	begin
            	//opm/opp/opz, kc
	          	Result := True;
            end;
        	$0030..$0037:
          	begin
            	//opm/opp, kf
              //opz, kf/?
			    		data^ := data^ and $fc;
	          	Result := True;
            end;
        	$0038..$003f:
          	begin
            	//opm/opp, pms/ams
              //opz, ?/pms/?/ams
			    		data^ := data^ and $73;
	          	Result := True;
            end;
        	$0040..$005f:
          	begin
            	//opm/opp, dt1/mul
              //opz, dt1/mul1
              //opz, wave select/mul2
			    		data^ := data^ and $7f;
	          	Result := True;
            end;
        	$0060..$007f:
          	begin
            	if info=DEVICE_OPM then
              begin
	            	//opm, tl
				    		data^ := data^ and $7f;
              end else
              begin
  	          	//opp/opz, ?/tl
              end;
    	      	Result := True;
            end;
        	$0080..$009f:
          	begin
            	//opm/opp, ks/ar
              //opz, ks/fix/ar
			    		data^ := data^ and $df;
	          	Result := True;
            end;
        	$00a0..$00bf:
          	begin
            	//opm/opp/opz, ams en/d1r
	          	Result := True;
            end;
        	$00c0..$00df:
          	begin
            	//opm/opp, dt2/d2r
              //opz, dt2/d2r
              //opz, eg shift/reverb level?/reverb rate
			    		data^ := data^ and $df;
	          	Result := True;
            end;
        	$00e0..$00ff:
          	begin
            	//opm/opp/opz, d1l/rr
	          	Result := True;
            end;
        end;
			end;
		DEVICE_OPZ:
			begin
	    	case addr of
        	$0000..$0007:
          	begin
             	//opp/opz, ?
	          	Result := True;
            end;
        	$0008:
          	begin
            	//opm/opp/opz, sn/ch
	          	Result := True;
            end;
        	$0009..$000a:
          	begin
              //opp/opz, ?
              //opz, ?
	          	Result := True;
            end;
        	$000f..$0012:
          	begin
            	//opm/opp/opz, ne/nfrq
            	//opm/opp/opz, clka1
            	//opm/opp/opz, clka2
            	//opm/opp/opz, clkb
	          	Result := True;
            end;
        	$0014:
          	begin
							//opz, csm/?/f reset/irq en/load
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
        	$0015:
          	begin
              //opz, ?
	          	Result := True;
            end;
        	$0016..$0017:
          	begin
            	//opz, lfrq?
            	//opz, pmd?/amd?
	          	Result := True;
            end;
        	$0018..$0019:
          	begin
            	//opm/opp/opz, lfrq
            	//opm/opp/opz, pmd/amd
	          	Result := True;
            end;
        	$001b:
          	begin
							//opz, ct/?/w
			    		data^ := data^ and $3f;
	          	Result := True;
            end;
        	$001c, $001e:
          	begin
              //opz, ?
              //opz, ?
	          	Result := True;
            end;
        	$0020..$00ff:
          	begin
							//opz, ch/fb/conect
							//opm/opp/opz, kc
							//opz, kf/?
							//opz, ?/pms/?/ams
							//opz, dt1/mul1
							//opz, wave select/mul2
 	          	//opp/opz, ?/tl
							//opz, ks/fix/ar
							//opm/opp/opz, ams en/d1r
							//opz, dt2/d2r
							//opz, eg shift/reverb level?/reverb rate
							//opm/opp/opz, d1l/rr
          		Result := True;
            end;
          else
          	begin
            	case addr of
              	$0000..$00ff:
			          	Result := True;
              end;
            end;
        end;
			end;
		DEVICE_OPN:
			begin
	     	case addr of
	       	$0000..$0006, $0008..$000c:
          	Result := True;
      	 	$0007:
        	  begin
			    		data^ := data^ or $c0;
	          	Result := True;
	        	end;
          $000d:
          	begin
            	//epsg, mode select
			    		data^ := data^ and $0f;
	          	Result := True;
            end;
    	    $000e..$000f:
      	    begin
        	  	//ssg, io
        		end;
	    	 	$0010..$001f:
	      	 	begin
	          	//opna, rhythm
	          end;
          $0022:
           	begin
             	//opna, lfo
            end;
          $0027:
          	begin
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
          $0028:
           	begin
             	if (data^ and $04)=0 then
              begin
               	//fm, ch1-3
                Result := True;
                if False then
                begin
                	//※テスト用
                  if (DevSts[conno].Reg[$0027] and $c0)=$00 then
		                Result := False;
                	if (data^ and $03)<>2 then
		                Result := False;
                end;
              end else
              begin
               	//fm, ch4-6
              end;
            end;
          $0029:
           	begin
			    		data^ := data^ and $7f;
	          	Result := True;
            end;
	       	$002a..$002b:
	         	begin
		        	//opn2, pcm
              //opn2, fm6/pcm select
	  	      end;
          $00b4..$00b6:
           	begin
			    		data^ := data^ or $c0;
	          	Result := True;
            end;
	  	    $0100..$01ff:
	    	   	begin
	      	  	//opna, adpcm
	      	  	//opna, fm/ch4-6
	        	end;
	        else
          	Result := True;
	      end;
			end;
		DEVICE_OPNA, DEVICE_OPNA_RAM:
			begin
				case addr of
					$0000..$0006, $0008..$000c:
						Result := True;
					$0007:
						begin
							data^ := data^ or $c0;
							Result := True;
						end;
					$000d:
						begin
							//epsg, mode select
							data^ := data^ and $0f;
							Result := True;
						end;
					$000e..$000f:
						begin
							//ssg, io
						end;
					$0027:
						begin
							data^ := data^ and $f3;
							Result := True;
						end;
					$002a..$002b:
						begin
							//opn2, pcm
							//opn2, fm6/pcm select
						end;
					$0100..$0110:
						begin
							//opna, adpcm
							if info=DEVICE_OPNA then
							begin
								case addr of
									$0101:
										begin
											//opna, adpcm control2
											Result := True;
										end;
									$010b:
										begin
											//opna, adpcm level control
											Result := True;
										end;
									$010e:
										begin
											//opna, pcm dac data
											Result := True;
										end;
								end;
							end else
							begin
								case addr of
									$0100:
										begin
											//opna, adpcm control1
											data^ := data^ and $f7;
											Result := True;
										end;
									$0101:
										begin
											//opna, adpcm control2
											Result := True;
										end;
									$010b:
										begin
											//opna, adpcm level control
											Result := True;
										end;
									$010e:
										begin
											//opna, pcm dac data
											Result := True;
										end;
									$0110:
										begin
											//opna, adpcm
											if True then
											begin
												data^ := data^ or $17;
												data^ := data^ and $f7;
											end else
											begin
												data^ := data^ or $13;
												data^ := data^ and $f3;
											end;
											Result := True;
										end;
                  else
                  	Result := True;
								end;
							end;
						end;
					else
						Result := True;
				end;
			end;
    DEVICE_OPNB_RAM:
    	begin
	     	case addr of
	       	$0000..$0006, $0008..$000c:
          	Result := True;
      	 	$0007:
        	  begin
			    		data^ := data^ or $c0;
	          	Result := True;
	        	end;
          $000d:
          	begin
            	//epsg, mode select
			    		data^ := data^ and $0f;
	          	Result := True;
            end;
    	    $000e..$000f:
      	    begin
        	  	//ssg, io
        		end;
          $0027:
          	begin
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
          $0028:
          	begin
             	case (data^ and $07) of
              	1, 2, 5, 6:
                	begin
                  	//fm, ch1-4
		                Result := True;
                  end;
              end;
            end;
          $0029:
          	begin
            	//opna, sch/irq enable
            end;
	       	$002a..$002b:
	         	begin
		        	//opn2, pcm
              //opn2, fm6/pcm select
	  	      end;
       		$0030, $0040, $0050, $0060, $0070, $0080, $0090,  //slot1
 	     		$0034, $0044, $0054, $0064, $0074, $0084, $0094,	//slot3
	 	   		$0038, $0048, $0058, $0068, $0078, $0088, $0098,	//slot2
     	 		$003c, $004c, $005c, $006c, $007c, $008c, $009c,	//slot4
       	 	$00a0, $00a4, $00b0, $00b4:
       			begin
            	//opn/opna/opn2 fm, ch1
            end;
       		$0130, $0140, $0150, $0160, $0170, $0180, $0190,  //slot1
 	     		$0134, $0144, $0154, $0164, $0174, $0184, $0194,	//slot3
	 	   		$0138, $0148, $0158, $0168, $0178, $0188, $0198,	//slot2
     	 		$013c, $014c, $015c, $016c, $017c, $018c, $019c,	//slot4
       	 	$01a0, $01a4, $01b0, $01b4:
       			begin
            	//opna/opn2 fm, ch4
            end;
	        else
          	Result := True;
	      end;
      end;
    DEVICE_YM2610B_RAM:
    	begin
	     	case addr of
	       	$0000..$0006, $0008..$000c:
          	Result := True;
      	 	$0007:
        	  begin
			    		data^ := data^ or $c0;
	          	Result := True;
	        	end;
          $000d:
          	begin
            	//epsg, mode select
			    		data^ := data^ and $0f;
	          	Result := True;
            end;
    	    $000e..$000f:
      	    begin
        	  	//ssg, io
        		end;
          $0027:
          	begin
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
          $0029:
          	begin
            	//opna, sch/irq enable
            end;
	       	$002a..$002b:
	         	begin
		        	//opn2, pcm
              //opn2, fm6/pcm select
	  	      end;
	        else
          	Result := True;
	      end;
      end;
    DEVICE_OPN2:
			begin
	     	case addr of
	       	$0000..$000f:
	         	begin
		        	//ssg
	  	      end;
	    	 	$0010..$001f:
	      	 	begin
	          	//opna, rhythm
	          end;
          $0027:
          	begin
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
	  	    $0100..$0110:
	    	   	begin
	      	  	//opna, adpcm
	        	end;
	        else
          	Result := True;
		    end;
			end;
		DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
			begin
	     	case addr of
	       	$0000..$0006, $0008..$000c:
          	Result := True;
      	 	$0007:
        	  begin
			    		data^ := data^ or $c0;
	          	Result := True;
	        	end;
          $000d:
          	begin
            	//epsg, mode select
			    		data^ := data^ and $0f;
	          	Result := True;
            end;
    	    $000e..$000f:
      	    begin
        	  	//ssg, io
        		end;
          $0027:
          	begin
			    		data^ := data^ and $f3;
	          	Result := True;
            end;
	       	$002a..$002b:
	         	begin
		        	//opn2, pcm
              //opn2, fm6/pcm select
	  	      end;
	  	    $0100..$0110:
	    	   	begin
	      	  	//opna, adpcm
	        	end;
	        else
          	Result := True;
	      end;
			end;
		DEVICE_OPLL, DEVICE_OPLLP:
			begin
	    	case addr of
        	$0000..$00ff:
          	Result := True;
        end;
			end;
		DEVICE_VRC7:
			begin
	    	case addr of
        	$000e:
          	begin
            	//opll, rhythm
            end;
          $0016..$0018, $0026..$0028, $0036..$0038:
          	begin
            	//opll, ch7-9
            end;
        	$0000..$0007, $000f..$0015, $0020..$0025, $0030..$0035:
          	Result := True;
        end;
			end;
		DEVICE_OPL, DEVICE_OPL2:
			begin
      	case addr of
        	$0001:
	         	begin
		        	//opl2/opl3, wave select enable
              if info=DEVICE_OPL then
			    			data^ := data^ and $df;
		          if False then
		          begin
		          	//※テスト用
            		data^ := data^ or (1 shl 1);
    		        data^ := data^ or (1 shl 4);
		            data^ := data^ or (1 shl 6);
    		      end;
          		Result := True;
	  	      end;
          $0004:
          	begin
			    		data^ := data^ or $60;
	          	Result := True;
            end;
          $0005..$0006:
          	begin
            	//msx-audio, key board in/out
            end;
          $0007:
          	begin
            	//msx-audio, adpcm control1
            end;
          $0008:
          	begin
            	//msx-audio, adpcm control2
	          	Result := True;
            end;
          $0009..$0012, $0015..$001a:
          	begin
            	//msx-audio, adpcm
            	//msx-audio, dac/io/pcm
            end;
          $00c0..$00c8:
          	begin
            	//opl3, ch
			    		data^ := data^ and $0f;
		    			Result := True;
            end;
          $00e0..$00f5:
          	begin
		        	//opl2/opl3, wave select
              if info=DEVICE_OPL2 then
              begin
				    		data^ := data^ and $fb;
			    			Result := True;
              end;
            end;
	  	    $0100..$01ff:
	    	   	begin
	      	  	//opl3, fm
	        	end;
          $0200..$02ff:
          	begin
             	//opl4, wavetable
            end;
          $0300..$03ff:
          	begin
            	//opl4-ml, gmp
            end;
          else
          	Result := True;
        end;
			end;
    DEVICE_MSXAUDIO_RAM:
    	begin
      	case addr of
        	$0001:
	         	begin
		        	//opl2/opl3, wave select enable
			    		data^ := data^ and $df;
	          	Result := True;
	  	      end;
          $0004:
          	begin
              if True then
              begin
				    		data^ := data^ or $70;
				    		data^ := data^ and $f4;
              end else
              begin
				    		data^ := data^ or $60;
				    		data^ := data^ and $e4;
              end;
	          	Result := True;
            end;
          $0005..$0006:
          	begin
            	//msx-audio, key board in/out
            end;
          $0007:
          	begin
            	//msx-audio, adpcm control1
			    		data^ := data^ and $f7;
							Result := True;
            end;
          $0008:
          	begin
            	//msx-audio, adpcm control2
	          	Result := True;
            end;
          $0012:
          	begin
            	//msx-audio, adpcm level control
	          	Result := True;
            end;
          $0018..$001a:
          	begin
            	//msx-audio, io/pcm
            end;
          $00c0..$00c8:
          	begin
            	//opl3, ch
			    		data^ := data^ and $0f;
		    			Result := True;
            end;
          $00e0..$00f5:
          	begin
		        	//opl2/opl3, wave select
            end;
	  	    $0100..$01ff:
	    	   	begin
	      	  	//opl3, fm
	        	end;
          $0200..$02ff:
          	begin
             	//opl4, wavetable
            end;
          $0300..$03ff:
          	begin
            	//opl4-ml, gmp
            end;
          else
          	Result := True;
        end;
      end;
		DEVICE_OPL3, DEVICE_OPL3L, DEVICE_DS1, DEVICE_SOLO1, DEVICE_OPL3NL_OPL,
    DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
			begin
      	case addr of
          $0004:
          	begin
			    		data^ := data^ or $60;
	          	Result := True;
            end;
          $0005..$0006:
          	begin
            	//msx-audio, key board in/out
            end;
          $0007:
          	begin
            	//msx-audio, adpcm control1
            end;
          $0008:
          	begin
            	//msx-audio, adpcm control2
			    		data^ := data^ and $7f;
	          	Result := True;
            end;
          $0009..$0012, $0015..$001a:
          	begin
            	//msx-audio, adpcm
            	//msx-audio, dac/io/pcm
            end;
          $00c0..$00c8, $01c0..$01c8:
          	begin
            	//opl3, ch
		          case info of
                DEVICE_OPL3L, DEVICE_DS1, DEVICE_SOLO1, DEVICE_OPL3NL_OPL:
                	data^ := data^ and $3f;
		          end;
		    			Result := True;
            end;
          $0105:
          	begin
	      	  	//opl3, fm
		          case info of
		            DEVICE_OPL4_RAM:
  	              begin
			              data^ := data^ and $fb;		//opl4-ml, new3=0
	                	data^ := data^ or $02;		//new2=1
                  end;
		            DEVICE_OPL4ML_OPL:
                	data^ := data^ or $02;		//new2=1
		          end;
			       	Result := True;
            end;
          $0200..$02ff:
          	begin
             	//opl4, wavetable
              case info of
            		DEVICE_OPL4_RAM:
                	begin
                  	case addr of
                    	$0280..$0297:
                      	begin
                        	//opl4-ml, chorus send level/lfo/vib
						              data^ := data^ and $3f;
									       	Result := True;
                        end;
                    	$02e0..$02f7:
                      	begin
                        	//opl4-ml, reverb send level/am
						              data^ := data^ and $1f;
									       	Result := True;
                        end;
                    	$02fa..$02fb:
                      	begin
                        	//opl4-ml, atc
                        end;
                      else
								       	Result := True;
                    end;
                  end;
		            DEVICE_OPL4ML_OPL:
                	begin
                  	case addr of
                    	$0203..$0206:
                      	begin
                        	//opl4, memory address
                          //opl4, memory data
                        end;
                      else
								       	Result := True;
                    end;
                  end;
              end;
            end;
          $0300..$03ff:
          	begin
            	//opl4-ml, gmp
            end;
          else
		       	Result := True;
        end;
			end;
    DEVICE_OPL4ML_MPU:
    	begin
        case addr of
        	$0000:
          	begin
            	//データライト
	          	Result := True;
            end;
        	$0001:
          	begin
            	//コマンドライト
	          	Result := True;
            end;
        end;
      end;
    DEVICE_OPX_RAM:
    	begin
      	case addr of
        	$0000..$00ff,	//function1
        	$0100..$01ff,	//function2
        	$0200..$02ff,	//function3
        	$0300..$03ff:	//function4
          	begin
            	if False then
              begin
		          	//※テスト用
                if ((addr and $f0)=$00) and ((DevSts[conno].Reg[(addr and $030f) or $b0] and 7)<>7) then
		              data^ := data^ and $fe;
              end;
			       	Result := True;
            end;
        	$0400..$04ff:	//pcm
		       	Result := True;
        	$0600..$0612, $0620..$0622:	//utility
		       	Result := True;
          $0613:
          	begin
            	//opx, reset/enable/load
              data^ := data^ and $f3;
			       	Result := True;
            end;
          $0614..$0617:
          	begin
            	//opx, ext memory address
            	//opx, ext memory data
            end;
          $0900..$09ff:	//ctl/ram
          	Result := True;
        end;
    	end;
		DEVICE_SCC, DEVICE_052539:
			begin
      	case addr of
					$9800..$98ff:
          	begin
		       		Result := True;
          	end;
					$b800..$b8ff:
          	begin
            	if info=DEVICE_052539 then
		       			Result := True;
            end;
        end;
			end;
    DEVICE_GA20:
    	begin
      	case addr of
        	$0000..$0006:	//ch1
		        Result := True;
        	$0008..$000e:	//ch2
		        Result := True;
        	$0010..$0016:	//ch3
		        Result := True;
        	$0018..$001e:	//ch4
		        Result := True;
          $0100..$01ff:	//ctl/ram
          	Result := True;
        end;
    	end;
    DEVICE_PCMD8:
    	begin
      	case addr of
        	$0000..$007f:	//function
          	Result := True;
          $0080:	//utility
          	Result := True;
          $0081..$0082, $0084..$0087, $00fe:
          	begin
            	//pcmd8, dspe
            	//pcmd8, dsp data
              //pcmd8, ram address/data
              //pcmd8, irq enable/mask
            end;
          $00ff:
          	begin
            	//pcmd8, kenb/menb/ienb
              data^ := data^ or $50;
	          	Result := True;
            end;
          $0100..$01ff:	//ctl/ram
          	Result := True;
        end;
    	end;
    DEVICE_MA2, DEVICE_MA3, DEVICE_MA5, DEVICE_MA7:
     	begin
        //
      end;
    DEVICE_RP2A03, DEVICE_RP2A03_EXT, DEVICE_RP2A07:
			begin
			end;
		DEVICE_SSMP_SDSP:
     	begin
      end;
		DEVICE_CPU_AGB:
     	begin
      end;
		DEVICE_SCSP_SCPU:
     	begin
      end;
		DEVICE_SPU:
     	begin
      	if (addr and 1)=0 then
        begin
	      	case addr of
  	      	$000..$1a8, $1ae..$1fe:
			        Result := True;
            $1aa:
            	begin
              	//spu, control
                case (data^ shr 4) and 3 of
                	0..1:
			              data^ := data^ and $ffb3;
                	else
			              data^ := data^ and $ff83;	//dmaを無効にする
                end;
				        Result := True;
            	end;
            $1ac:
            	begin
              	//spu, status
              end;
          end;
        end;
      end;
		DEVICE_AICA:
     	begin
      end;
		DEVICE_SPU2:
     	begin
      	//
      end;
	end;
end;

procedure TKss.WriteDevice(cmd: Integer; regaddr, regdata: Word);
	var
  	i, j: Integer;
	var
  	reqno, conno, nTh: Integer;
    fwrite_out: Boolean;
    regaddr2, regdata2: Word;
  var
    n, ch, oplltype: Integer;
    popllinst: PByteArray;
begin
	//
	reqno := CmdToReqno[cmd];
	if reqno<0 then
  	Exit;
	conno := DeviceForm.ReqDevice[reqno].nNo;
	if conno<0 then
  	Exit;
	if DeviceForm.CnDevice[conno].nInfo=DEVICE_NONE then
  	Exit;
  nTh := DeviceForm.CnDevice[conno].nThread;

	//入力マスク
	fwrite_out := True;
	if MaskReg(conno, DeviceForm.ReqDevice[reqno].nInfo, regaddr, @regdata)=True then
	begin
		//
		case DeviceForm.CnDevice[conno].nInfo of
			DEVICE_OPL2, DEVICE_OPL3, DEVICE_OPL3L, DEVICE_OPL3NL_OPL,
			DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL, DEVICE_DS1, DEVICE_SOLO1:
				begin
					oplltype := -1;
					case DeviceForm.ReqDevice[reqno].nInfo of
						DEVICE_OPLL:
							begin
								//OPLL→OPL2/OPL3/OPL4/DS1/SOLO1
								if MainForm.ThreadCri[nTh].bOpl2Opll=True then
									oplltype := 0;
								fwrite_out := False;
							end;
						DEVICE_OPLLP:
							begin
								//OPLLP→OPL2/OPL3/OPL4/DS1/SOLO1
								if MainForm.ThreadCri[nTh].bOpl2Opll=True then
									oplltype := 1;
								fwrite_out := False;
							end;
						DEVICE_VRC7:
							begin
								//VRC7→OPL2/OPL3/OPL4/DS1/SOLO1
								if MainForm.ThreadCri[nTh].bOpl2Opll=True then
									oplltype := 2;
								fwrite_out := False;
							end;
					end;
					//
					if oplltype>=0 then
					begin
						case regaddr of
							$00,	//modulator, am/vib/egtyp/ksr/multi
							$01:	//carrier, am/vib/egtyp/ksr/multi
								begin
									for i := 0 to DevSts[conno].Opll.nMelodyCh-1 do
									begin
										for j := 1 downto 0 do
										begin
											if ((DevSts[conno].Opll.Reg[$20+i] and $10)=j*$10) and ((DevSts[conno].Opll.Reg[$30+i] and $f0)=0) then
											begin
												regaddr2 := ($20+(regaddr and 1)*3)+Opl2Channel2Addr[i];
												regdata2 := regdata;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
								end;
							$02:	//modulator, ksl/tl
								begin
									for i := 0 to DevSts[conno].Opll.nMelodyCh-1 do
									begin
										for j := 1 downto 0 do
										begin
											if ((DevSts[conno].Opll.Reg[$20+i] and $10)=j*$10) and ((DevSts[conno].Opll.Reg[$30+i] and $f0)=0) then
											begin
												regaddr2 := $40+Opl2Channel2Addr[i];
												regdata2 := regdata;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
								end;
							$03:	//carrier, ksl/dc/dm(modulator)/fb
								begin
									for i := 0 to DevSts[conno].Opll.nMelodyCh-1 do
									begin
										for j := 1 downto 0 do
										begin
											if ((DevSts[conno].Opll.Reg[$20+i] and $10)=j*$10) and ((DevSts[conno].Opll.Reg[$30+i] and $f0)=0) then
											begin
												//fb/c
												regaddr2 := $c0+i;
												regdata2 := (DevSts[conno].Reg[regaddr2] and $f0) or ((regdata and $07) shl 1) or 0;
												WriteBuf(nTh, conno, regaddr2, regdata2);
												//modulator, ws
												regaddr2 := $e0+Opl2Channel2Addr[i];
												regdata2 := (regdata shr 3) and 1;
												WriteBuf(nTh, conno, regaddr2, regdata2);
												//carrier, ksl/tl
												regaddr2 := $43+Opl2Channel2Addr[i];
												regdata2 := (regdata and $c0) or OpllMoVol2Opl2Tl[DevSts[conno].Opll.Reg[$30+i] and $0f];
												WriteBuf(nTh, conno, regaddr2, regdata2);
												//carrier, ws
												regaddr2 := $e3+Opl2Channel2Addr[i];
												regdata2 := (regdata shr 4) and 1;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
								end;
							$04,	//modulator, ar/dr
							$05:	//carrier, ar/dr
								begin
									for i := 0 to DevSts[conno].Opll.nMelodyCh-1 do
									begin
										for j := 1 downto 0 do
										begin
											if ((DevSts[conno].Opll.Reg[$20+i] and $10)=j*$10) and ((DevSts[conno].Opll.Reg[$30+i] and $f0)=0) then
											begin
												regaddr2 := ($60+(regaddr and 1)*3)+Opl2Channel2Addr[i];
												regdata2 := regdata;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
								end;
							$06,	//modulator, sl/rr
							$07:	//carrier, sl/rr
								begin
									for i := 0 to DevSts[conno].Opll.nMelodyCh-1 do
									begin
										for j := 1 downto 0 do
										begin
											if ((DevSts[conno].Opll.Reg[$20+i] and $10)=j*$10) and ((DevSts[conno].Opll.Reg[$30+i] and $f0)=0) then
											begin
												regaddr2 := ($80+(regaddr and 1)*3)+Opl2Channel2Addr[i];
												regdata2 := regdata;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
								end;
							$0e:	//r/bd/sd/tom/t-ct/hh
								begin
									if ((regdata xor DevSts[conno].Opll.Reg[regaddr]) and $20)<>0 then
									begin
										if (DevSts[conno].Opll.Reg[regaddr] and $20)<>0 then
										begin
											//rhythm=1→0
											DevSts[conno].Opll.nMelodyCh := 9;
											//※inst./volを再設定しないといけない
											if DeviceForm.CnDevice[conno].nInfo<>DEVICE_OPL2 then
											begin
												for i := 6 to 8 do
												begin
													regaddr2 := $c0+i;
													regdata2 := $30;
													if MainForm.ThreadCri[nTh].bOpl3OpllMoRo=True then
														regdata2 := $10;
													if MainForm.ThreadCri[nTh].bOpl3ChannelChg=True then
														regdata2 := ((regdata2 and $c0) shr 2) or ((regdata2 and $30) shl 2) or (regdata2 and $0f);
													regdata2 := regdata2 or (DevSts[conno].Reg[regaddr2] and $0f);
													WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
											end;
										end else
										begin
											//rhythm=0→1
											DevSts[conno].Opll.nMelodyCh := 6;
											//hh
											regaddr2 := $31;	regdata2 := OpllInst[oplltype][17][0];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $51;	regdata2 := (OpllInst[oplltype][17][2] and $c0) or OpllRoVol2Opl2Tl[(DevSts[conno].Opll.Reg[$37] and $f0) shr 4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $71;	regdata2 := OpllInst[oplltype][17][4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $91;	regdata2 := OpllInst[oplltype][17][6];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f1;	regdata2 := (OpllInst[oplltype][17][3] shr 3) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//top-cym
											regaddr2 := $35;	regdata2 := OpllInst[oplltype][18][1];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $55;	regdata2 := (OpllInst[oplltype][18][3] and $c0) or OpllRoVol2Opl2Tl[DevSts[conno].Opll.Reg[$38] and $0f];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $75;	regdata2 := OpllInst[oplltype][18][5];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $95;	regdata2 := OpllInst[oplltype][18][7];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f5;	regdata2 := (OpllInst[oplltype][18][3] shr 4) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//tom
											regaddr2 := $32;	regdata2 := OpllInst[oplltype][18][0];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $52;	regdata2 := (OpllInst[oplltype][18][2] and $c0) or OpllRoVol2Opl2Tl[(DevSts[conno].Opll.Reg[$38] and $f0) shr 4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $72;	regdata2 := OpllInst[oplltype][18][4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $92;	regdata2 := OpllInst[oplltype][18][6];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f2;	regdata2 := (OpllInst[oplltype][18][3] shr 3) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//sd
											regaddr2 := $34;	regdata2 := OpllInst[oplltype][17][1];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $54;	regdata2 := (OpllInst[oplltype][17][3] and $c0) or OpllRoVol2Opl2Tl[DevSts[conno].Opll.Reg[$37] and $0f];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $74;	regdata2 := OpllInst[oplltype][17][5];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $94;	regdata2 := OpllInst[oplltype][17][7];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f4;	regdata2 := (OpllInst[oplltype][17][3] shr 4) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//bd
											regaddr2 := $30;	regdata2 := OpllInst[oplltype][16][0];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $50;	regdata2 := OpllInst[oplltype][16][2];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $70;	regdata2 := OpllInst[oplltype][16][4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $90;	regdata2 := OpllInst[oplltype][16][6];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f0;	regdata2 := (OpllInst[oplltype][16][3] shr 3) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $33;	regdata2 := OpllInst[oplltype][16][1];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $53;	regdata2 := (OpllInst[oplltype][16][3] and $c0) or OpllRoVol2Opl2Tl[DevSts[conno].Opll.Reg[$36] and $0f];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $73;	regdata2 := OpllInst[oplltype][16][5];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $93;	regdata2 := OpllInst[oplltype][16][7];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											regaddr2 := $f3;	regdata2 := (OpllInst[oplltype][16][3] shr 4) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//ch7-9
											for i := 0 to 2 do
											begin
												regaddr2 := $c6+i;
												regdata2 := ((OpllInst[oplltype][16+i][3] and $07) shl 1) or ((OpllInst[oplltype][16+i][3] and $20) shr 5);
												if DeviceForm.CnDevice[conno].nInfo<>DEVICE_OPL2 then
												begin
													if MainForm.ThreadCri[nTh].bOpl3OpllMoRo=True then
														regdata2 := regdata2 or $20
													else
														regdata2 := regdata2 or $30;
													if MainForm.ThreadCri[nTh].bOpl3ChannelChg=True then
														regdata2 := ((regdata2 and $c0) shr 2) or ((regdata2 and $30) shl 2) or (regdata2 and $0f);
												end;
												WriteBuf(nTh, conno, regaddr2, regdata2);
											end;
										end;
									end;
									//
									if (regdata and $20)<>0 then
									begin
										//rhythm=1
										//bd
										regaddr2 := $93;	regdata2 := OpllInst[oplltype][16][7];
										if ((DevSts[conno].Opll.Reg[$26] and $20)<>0) and ((regdata and $10)=0) then
											regdata2 := (regdata2 and $f0) or $05;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
										//hh
										regaddr2 := $91;	regdata2 := OpllInst[oplltype][17][6];
										if ((DevSts[conno].Opll.Reg[$27] and $20)<>0) and ((regdata and $01)=0) then
											regdata2 := (regdata2 and $f0) or $05;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
										//sd
										regaddr2 := $94;	regdata2 := OpllInst[oplltype][17][7];
										if ((DevSts[conno].Opll.Reg[$27] and $20)<>0) and ((regdata and $08)=0) then
											regdata2 := (regdata2 and $f0) or $05;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
										//top-cym
										regaddr2 := $95;	regdata2 := OpllInst[oplltype][18][7];
										if ((DevSts[conno].Opll.Reg[$28] and $20)<>0) and ((regdata and $02)=0) then
											regdata2 := (regdata2 and $f0) or $05;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
										//tom
										regaddr2 := $92;	regdata2 := OpllInst[oplltype][18][6];
										if ((DevSts[conno].Opll.Reg[$28] and $20)<>0) and ((regdata and $04)=0) then
											regdata2 := (regdata2 and $f0) or $05;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
									end;
									//
									regaddr2 := $bd;
									regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or (regdata and $3f);
									WriteBuf(nTh, conno, regaddr2, regdata2);
								end;
							$0f:	//test
								begin
									regaddr2 := $01;
									regdata2 := DevSts[conno].Reg[regaddr2] and $20;
									if (regdata and $01)<>0 then
										regdata2 := regdata2 or $01;
									if (regdata and $02)<>0 then
										regdata2 := regdata2 or $88;
									if (regdata and $04)<>0 then
										regdata2 := regdata2 or $04;
									WriteBuf(nTh, conno, regaddr2, regdata2);
								end;
							$10..$18:	//f-num.0-7
								begin
									i := regaddr and $0f;
									regaddr2 := $a0+i;
									regdata2 := (regdata shl 1) and $ff;
									WriteBuf(nTh, conno, regaddr2, regdata2);
									regaddr2 := $b0+i;
									regdata2 := ((DevSts[conno].Opll.Reg[$20+i] shl 1) or (regdata shr 7)) and $3f;
									WriteBuf(nTh, conno, regaddr2, regdata2);
								end;
							$20..$28:	//sus/key/block/f-num.8
								begin
									i := regaddr and $0f;
									if i<DevSts[conno].Opll.nMelodyCh then
									begin
										//carrier, sl/rr
										regaddr2 := $83+Opl2Channel2Addr[i];
										n := (DevSts[conno].Opll.Reg[$30+i] shr 4) and $0f;
										if n=0 then
											popllinst := @DevSts[conno].Opll.Reg
										else
											popllinst := @OpllInst[oplltype][n];
										regdata2 := popllinst[7];
										if ((regdata and $20)<>0) and ((regdata and $10)=0) then
										begin
											//sus on, key off
											regdata2 := (regdata2 and $f0) or $05;
										end;
										if DevSts[conno].Reg[regaddr2]<>regdata2 then
											WriteBuf(nTh, conno, regaddr2, regdata2);
									end else
									begin
										//rhythm
										case regaddr of
											$26:
												begin
													//bd
													regaddr2 := $93;	regdata2 := OpllInst[oplltype][16][7];
													if ((regdata and $20)<>0) and ((regdata and $10)=0) then
														regdata2 := (regdata2 and $f0) or $05;
													if DevSts[conno].Reg[regaddr2]<>regdata2 then
														WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
											$27:
												begin
													//hh
													regaddr2 := $91;	regdata2 := OpllInst[oplltype][17][6];
													if ((regdata and $20)<>0) and ((regdata and $10)=0) then
														regdata2 := (regdata2 and $f0) or $05;
													if DevSts[conno].Reg[regaddr2]<>regdata2 then
														WriteBuf(nTh, conno, regaddr2, regdata2);
													//sd
													regaddr2 := $94;	regdata2 := OpllInst[oplltype][17][7];
													if ((regdata and $20)<>0) and ((regdata and $10)=0) then
														regdata2 := (regdata2 and $f0) or $05;
													if DevSts[conno].Reg[regaddr2]<>regdata2 then
														WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
											$28:
												begin
													//top-cym
													regaddr2 := $95;	regdata2 := OpllInst[oplltype][18][7];
													if ((regdata and $20)<>0) and ((regdata and $10)=0) then
														regdata2 := (regdata2 and $f0) or $05;
													if DevSts[conno].Reg[regaddr2]<>regdata2 then
														WriteBuf(nTh, conno, regaddr2, regdata2);
													//tom
													regaddr2 := $92;	regdata2 := OpllInst[oplltype][18][6];
													if ((regdata and $20)<>0) and ((regdata and $10)=0) then
														regdata2 := (regdata2 and $f0) or $05;
													if DevSts[conno].Reg[regaddr2]<>regdata2 then
														WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
										end;
									end;
									//
									regaddr2 := $b0+i;
									regdata2 := ((regdata shl 1) or (DevSts[conno].Opll.Reg[$10+i] shr 7)) and $3f;
									WriteBuf(nTh, conno, regaddr2, regdata2);
								end;
							$30..$38:	//inst./vol
								begin
									i := regaddr and $0f;
									if i<DevSts[conno].Opll.nMelodyCh then
									begin
										if ((regdata xor DevSts[conno].Opll.Reg[$30+i]) and $f0)<>0 then
										begin
											//inst.変更
											n := (regdata shr 4) and $0f;
											if n=0 then
												popllinst := @DevSts[conno].Opll.Reg
											else
												popllinst := @OpllInst[oplltype][n];
											//modulator, am/vib/egtyp/ksr/multi
											regaddr2 := $20+Opl2Channel2Addr[i];
											regdata2 := popllinst[0];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//modulator, ksl/tl
											regaddr2 := $40+Opl2Channel2Addr[i];
											regdata2 := popllinst[2];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//fb/c
											regaddr2 := $c0+i;
											regdata2 := (DevSts[conno].Reg[regaddr2] and $f0) or ((popllinst[3] and $07) shl 1) or ((popllinst[3] and $20) shr 5);
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//modulator, ws
											regaddr2 := $e0+Opl2Channel2Addr[i];
											regdata2 := (popllinst[3] shr 3) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//modulator, ar/dr
											regaddr2 := $60+Opl2Channel2Addr[i];
											regdata2 := popllinst[4];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//modulator, sl/rr
											regaddr2 := $80+Opl2Channel2Addr[i];
											regdata2 := popllinst[6];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//carrier, am/vib/egtyp/ksr/multi
											regaddr2 := $23+Opl2Channel2Addr[i];
											regdata2 := popllinst[1];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//carrier, ksl/tl
											regaddr2 := $43+Opl2Channel2Addr[i];
											regdata2 := (popllinst[3] and $c0) or OpllMoVol2Opl2Tl[regdata and $0f];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//carrier, ws
											regaddr2 := $e3+Opl2Channel2Addr[i];
											regdata2 := (popllinst[3] shr 4) and 1;
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//carrier, ar/dr
											regaddr2 := $63+Opl2Channel2Addr[i];
											regdata2 := popllinst[5];
											WriteBuf(nTh, conno, regaddr2, regdata2);
											//carrier, sl/rr
											regaddr2 := $83+Opl2Channel2Addr[i];
											regdata2 := popllinst[7];
											WriteBuf(nTh, conno, regaddr2, regdata2);
										end else
										if ((regdata xor DevSts[conno].Opll.Reg[$30+i]) and $0f)<>0 then
										begin
											//inst.一致、vol変更
											//carrier, ksl/tl
											regaddr2 := $43+Opl2Channel2Addr[i];
											regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllMoVol2Opl2Tl[regdata and $0f];
											WriteBuf(nTh, conno, regaddr2, regdata2);
										end;
									end else
									begin
										//rhythm
										case regaddr of
											$36:
												begin
													//bd
													regaddr2 := $53;
													regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllRoVol2Opl2Tl[regdata and $0f];
													WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
											$37:
												begin
													//hh
													regaddr2 := $51;
													regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllRoVol2Opl2Tl[(regdata and $f0) shr 4];
													WriteBuf(nTh, conno, regaddr2, regdata2);
													//sd
													regaddr2 := $54;
													regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllRoVol2Opl2Tl[regdata and $0f];
													WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
											$38:
												begin
													//tom
													regaddr2 := $52;
													regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllRoVol2Opl2Tl[(regdata and $f0) shr 4];
													WriteBuf(nTh, conno, regaddr2, regdata2);
													//top-cym
													regaddr2 := $55;
													regdata2 := (DevSts[conno].Reg[regaddr2] and $c0) or OpllRoVol2Opl2Tl[regdata and $0f];
													WriteBuf(nTh, conno, regaddr2, regdata2);
												end;
										end;
									end;
								end;
						end;
						DevSts[conno].Opll.Reg[regaddr] := regdata;
//						bStartSkip := False;
					end;
				end;
		end;
		//
		case DeviceForm.CnDevice[conno].nInfo of
			DEVICE_OPL3, DEVICE_OPL3L, DEVICE_DS1, DEVICE_SOLO1, DEVICE_OPL3NL_OPL, DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
				begin
					case regaddr of
						$00c0..$00c8, $01c0..$01c8:
							begin
								if MainForm.ThreadCri[nTh].bOpl3ChannelChg=True then
									regdata := ((regdata and $c0) shr 2) or ((regdata and $30) shl 2) or (regdata and $0f);
							end;
					end;
				end;
			DEVICE_052539:
				begin
					if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_SCC then
					begin
						//アドレス変更
						if MainForm.ThreadCri[nTh].b052539CompatibleMode=True then
						begin
							//SCC→SCC互換
							case regaddr of
								$98e0..$98ff:
									begin
										//
										Inc(regaddr, -$20);
									end;
							end;
						end else
						begin
							//SCC→052539固有
							//※CHEは鳴らない
							case regaddr of
								$9800..$987f:
									begin
										//
										Inc(regaddr, $2000);
									end;
								$9880..$989f:
									begin
										//
										Inc(regaddr, $2020);
									end;
								$98e0..$98ff:
									begin
										//
										Inc(regaddr, $1fe0);
									end;
							end;
						end;
					end;
				end;
		end;

		//出力マスク
		if (fwrite_out=True) and (MaskReg(conno, DeviceForm.CnDevice[conno].nInfo, regaddr, @regdata)=True) then
		begin
			//書き込み
			WriteBuf(nTh, conno, regaddr, regdata);
		end;
	end;
end;


{注意:
  異なるスレッドが所有する VCL または CLX のメソッド/関数/
  プロパティを別のスレッドの中から扱う場合、排他処理の問題が
  発生します。

  メインスレッドの所有するオブジェクトに対しては Synchronize
  メソッドを使う事ができます。他のオブジェクトを参照するため
  のメソッドをスレッドクラスに追加し、Synchronize メソッドの
  引数として渡します。

  たとえば、UpdateCaption メソッドを以下のように定義し、

    procedure TKssThread.UpdateCaption;
    begin
      Form1.Caption := 'TKssThread スレッドから書き換えました';
    end;

  Execute メソッドの中で Synchronize メソッドに渡すことでメイ
  ンスレッドが所有する Form1 の Caption プロパティを安全に変
  更できます。

      Synchronize(UpdateCaption);
}

{ TKssThread }

constructor TKssThread.Create;
begin
  //
	inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
end;

procedure TKssThread.Execute;
	var
  	res: Integer;
begin
	//
  MainForm.Kss.PkssReset;
  MainForm.Kss.PkssBegin;
  res := ST_THREAD_END;
	while (Terminated=False) and (MainForm.Kss.nFrameLim>0) do
	begin
		if MainForm.Kss.PkssExecute=False then
		begin
		  res := ST_THREAD_ERROR;
			Break;
		end;
	end;
  MainForm.Kss.PkssEnd(Terminated);

  //
  if res=ST_THREAD_ERROR then
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, -1, ST_THREAD_ERROR)
  else
  if Terminated=True then
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, -1, ST_THREAD_TERMINATE)
  else
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, -1, ST_THREAD_END);
end;

end.

