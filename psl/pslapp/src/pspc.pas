unit pspc;

interface

uses
  Classes, Windows, SysUtils, Math, MMSystem, Unit1, Unit2;

type
  TSpcThread = class(TThread)
  private
    { Private 宣言 }
    SpcFile: TSpcFile;
    nTimeInit, nTimeLim: Int64;
    bType, bSpdif: Boolean;
    slLog: TStringList;
    //
    Ipl1Addr, Ipl2EndAddr: Word;
    InitFileBuf: array[0..64*1024-1] of Byte;
    CmdToReqno: array[0..$ff] of Integer;
    //
	  dwHighAddr: array[0..3] of DWORD;
    txsz: Cardinal;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
    //
    function timeGetTime64: Int64;
		function Main: Integer;
		procedure SetCommand(cmd: Byte; cs: Word; addr: DWORD; reg: Word);
		function WriteEzusbPicFtdi(conno: Integer; ifno: Integer; pipenum: Cardinal; txbf: Pointer; txsz: Cardinal): Boolean;
  protected
    { protected 宣言 }
    procedure Execute; override;
  published
    { published 宣言 }
		constructor Create(spc: PSpcFile; tlim: Int64; ctl: String; typ, dif: Boolean);
  end;

implementation

{注意:
  異なるスレッドが所有する VCL または CLX のメソッド/関数/
  プロパティを別のスレッドの中から扱う場合、排他処理の問題が
  発生します。

  メインスレッドの所有するオブジェクトに対しては Synchronize
  メソッドを使う事ができます。他のオブジェクトを参照するため
  のメソッドをスレッドクラスに追加し、Synchronize メソッドの
  引数として渡します。

  たとえば、UpdateCaption メソッドを以下のように定義し、

    procedure TSpcThread.UpdateCaption;
    begin
      Form1.Caption := 'TSpcThread スレッドから書き換えました';
    end;

  Execute メソッドの中で Synchronize メソッドに渡すことでメイ
  ンスレッドが所有する Form1 の Caption プロパティを安全に変
  更できます。

      Synchronize(UpdateCaption);
}

{ TSpcThread }

constructor TSpcThread.Create(spc: PSpcFile; tlim: Int64; ctl: String; typ, dif: Boolean);
	var
  	s: Integer;
    fs: TFileStream;
    offset, {start,} reg, port: Integer;
  var
  	i, j, cmd: Integer;
begin
	//
  Move(spc^, SpcFile, SizeOf(SpcFile));
  nTimeInit := -1;
  nTimeLim := tlim;
  bType := typ;
  bSpdif := dif;

  //
  FillChar(InitFileBuf, SizeOf(InitFileBuf), $00);
  fs := nil;
 	try
	 	fs := TFileStream.Create(ctl, fmOpenRead or fmShareDenyWrite);
    while True do
    begin
 			s := fs.Read(InitFileBuf, SizeOf(InitFileBuf));
      if s<1 then
      begin
				InitFileBuf[0] := $00;
      	Break;
      end;
      //
    	if (InitFileBuf[0]=Ord('p')) and (InitFileBuf[1]=Ord('s')) and
  			(InitFileBuf[2]=Ord('l')) and (InitFileBuf[3]=$1a) and
        (((InitFileBuf[5] shl 8) or InitFileBuf[4])>$0000) then
      begin
			  //
        offset := $0020;
//			  start := InitFileBuf[offset+0] or (InitFileBuf[offset+1] shl 8);
			  reg := InitFileBuf[offset+2] or (InitFileBuf[offset+3] shl 8);
			  Ipl1Addr := InitFileBuf[offset+4] or (InitFileBuf[offset+5] shl 8);
			  port := InitFileBuf[offset+6] or (InitFileBuf[offset+7] shl 8);
			  Ipl2EndAddr := InitFileBuf[offset+8] or (InitFileBuf[offset+9] shl 8);
			  //
			  InitFileBuf[reg] := SpcFile.wSpc700PC and $ff;
			  InitFileBuf[reg+1] := (SpcFile.wSpc700PC shr 8) and $ff;
  	 	 	InitFileBuf[reg+2] := SpcFile.bySpc700A;
	    	InitFileBuf[reg+3] := SpcFile.bySpc700X;
	    	InitFileBuf[reg+4] := SpcFile.bySpc700Y;
  		  InitFileBuf[reg+5] := SpcFile.bySpc700PSW;
        if True then
	  		  InitFileBuf[reg+5] := InitFileBuf[reg+5] and $fb;	//i=0
	  	  InitFileBuf[reg+6] := SpcFile.bySpc700SP;
        //
	  	  InitFileBuf[port] := SpcFile.Ram[$00f4];
	  	  InitFileBuf[port+1] := SpcFile.Ram[$00f5];
	  	  InitFileBuf[port+2] := SpcFile.Ram[$00f6];
	  	  InitFileBuf[port+3] := SpcFile.Ram[$00f7];
        Break;
      end else
      begin
      	//
				InitFileBuf[0] := $00;
      end;
    end;
  finally
    fs.Free;
 	end;

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
	inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
end;

function TSpcThread.timeGetTime64: Int64;
	var
  	tm: Int64;
begin
	//
	tm := timeGetTime;
  if nTimeInit<0 then
  	nTimeInit := tm;
  if tm<(nTimeInit and $ffffffff) then
  	Inc(nTimeInit, $100000000);
	Result := (nTimeInit and $ffffffff00000000) or tm;
end;

const
  DspAddrTable: array[0..87-1] of Word = (
    $6c, $6d, $7d,
    $0f, $1f, $2f, $3f, $4f, $5f, $6f, $7f,
    $0d, $4d,
    //
    $6c, $2d, $3d, $5d,
    //
    $00, $01, $02, $03, $04, $05, $06, $07,
    $10, $11, $12, $13, $14, $15, $16, $17,
    $20, $21, $22, $23, $24, $25, $26, $27,
    $30, $31, $32, $33, $34, $35, $36, $37,
    $40, $41, $42, $43, $44, $45, $46, $47,
    $50, $51, $52, $53, $54, $55, $56, $57,
    $60, $61, $62, $63, $64, $65, $66, $67,
    $70, $71, $72, $73, $74, $75, $76, $77,
    $ff5c, $ff4c,
		//
    $2c, $3c, $0c, $1c
  );

function TSpcThread.Main: Integer;
	var
  	reqno, conno, ifno: Integer;
  	devcs, devaddr: Word;
    nSyncFreq: Integer;
    //
    i, j: Integer;
    ptr, seq, addr, lim: DWORD;
    //
    nStart, nTime, nTimeOld: Int64;
		//
    tm, tim2: Int64;
begin
  //
  Result := ST_THREAD_ERROR;
  reqno := CmdToReqno[0];
  if (reqno<0) or (InitFileBuf[0]<>Ord('p')) then
    Exit;
	conno := DeviceForm.ReqDevice[reqno].nNo;
  if conno<0 then
	  Exit;
  //
	devcs := DeviceForm.CnDevice[conno].nIfEzusbPicFtdiDevCs;
  devaddr := DeviceForm.CnDevice[conno].nIfEzusbPicFtdiDevAddr;

	//
	ifno := -1;
	case DeviceForm.CnDevice[conno].nIfSelect of
		IF_EZUSB:
			ifno := DeviceForm.CnDevice[conno].nIfEzusbNo;
		IF_PIC:
			ifno := DeviceForm.CnDevice[conno].nIfPicNo;
		IF_FTDI:
			ifno := DeviceForm.CnDevice[conno].nIfFtdiNo;
	end;
	if ifno<0 then
		Exit;
	//
	nSyncFreq := 0;
	case DeviceForm.CnDevice[conno].nIfSelect of
		IF_EZUSB:
			nSyncFreq := DeviceForm.Ezusb[ifno].nSyncFreq;
		IF_PIC:
			nSyncFreq := DeviceForm.Pic[ifno].nSyncFreq;
		IF_FTDI:
			nSyncFreq := DeviceForm.Ftdi[ifno].nSyncFreq;
	end;
	if nSyncFreq<1 then
		Exit;

	//
  txsz := 0;
  if bType=True then
  begin
  	txbf[txsz] := CTL_RESET;
		Inc(txsz);
  end;
  txbf[txsz] := CTL_START;
  Inc(txsz);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_CTLCMD, @txbf, txsz)=False then
  	Exit;

  //
  txsz := 0;
  if bType=False then
  begin
 	  //SPDIF設定/ミュート有効、リセット
		txbf[txsz] := CMD_WAIT_1MS;
		txbf[txsz+1] := $00;
		txbf[txsz+2] := $00;
		SetCommand(CMD_SSMP_SDSP_CTL, devcs, devaddr or 4, $01);
		txbf[txsz] := $0b;
    if bSpdif=True then
			txbf[txsz] := txbf[txsz] or $10;
	  Inc(txsz);
		//
		txbf[txsz] := CMD_WAIT_1MS;
		txbf[txsz+1] := $00;
		txbf[txsz+2] := $00;
		Inc(txsz, 3);
	  //SPDIF設定/ミュート有効、リセット解除
		SetCommand(CMD_SSMP_SDSP_CTL, devcs, devaddr or 4, $01);
		txbf[txsz] := $08;
    if bSpdif=True then
			txbf[txsz] := txbf[txsz] or $10;
	  Inc(txsz);
  end;
  //
  for i := 1 to 50 do
  begin
		txbf[txsz] := CMD_WAIT_1MS;
		txbf[txsz+1] := $00;
		txbf[txsz+2] := $00;
		Inc(txsz, 3);
  end;
	if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

  //初期化待ち
	txsz := 0;
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := $aa;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 1, 0);
	txbf[txsz] := $bb;
  Inc(txsz);
	txbf[txsz] := CMD_WAIT_1MS;
	txbf[txsz+1] := $00;
	txbf[txsz+2] := $00;
	Inc(txsz, 3);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := $aa;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 1, 0);
	txbf[txsz] := $bb;
  Inc(txsz);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

  //IPL1転送
  //  Max(Ipl1Addr, $0002)～$00ef
  addr := Max(Ipl1Addr, $0002);
  lim := $00f0;
	txsz := 0;
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 2, 0);
	txbf[txsz] := addr and $ff;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 3, 0);
	txbf[txsz] := (addr shr 8) and $ff;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := $01;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := $cc;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := $cc;
  Inc(txsz);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;
	//
  seq := $00;
  while addr<lim do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;
		//
		txsz := 0;
		for i := 1 to EZUSB_PIC_FTDI_BUFSIZE div 6 do
    begin
    	if addr>=lim then
      	Break;
      //
			SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
			txbf[txsz] := InitFileBuf[addr];
	    Inc(addr);
  		Inc(txsz);
			SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
			txbf[txsz] := seq and $ff;
  		Inc(txsz);
			SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
			txbf[txsz] := seq and $ff;
	    Inc(seq);
  		Inc(txsz);
    end;
	  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  	Exit;
  end;

 	//IPL1実行
	txsz := 0;
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 2, 0);
	txbf[txsz] := Ipl1Addr and $ff;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 3, 0);
	txbf[txsz] := (Ipl1Addr shr 8) and $ff;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := $00;
 	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := Max((seq+1) and $ff, (seq+2) and $ff);
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := Max((seq+1) and $ff, (seq+2) and $ff);
  Inc(txsz);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

	//IPL2転送、RAM転送1
  //  $0100～$ffff
  addr := $0100;
  lim := $10000;
  seq := $00;
  while addr<lim do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;
    //
		txsz := 0;
		for i := 1 to EZUSB_PIC_FTDI_BUFSIZE div 10 do
    begin
  	 	if addr>=lim then
	    	Break;
			//
      for j := 1 to 3 do
      begin
				SetCommand(CMD_SSMP_SDSP, devcs, devaddr or j, 0);
        if addr<=Ipl2EndAddr then
					txbf[txsz] := InitFileBuf[addr]
        else
					txbf[txsz] := SpcFile.Ram[addr and $ffff];
  	  	Inc(addr);
	  		Inc(txsz);
      end;
      //
			SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
			txbf[txsz] := seq and $ff;
  		Inc(txsz);
			SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
			txbf[txsz] := seq and $ff;
  	  Inc(seq);
		  Inc(txsz);
    end;
  	if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  	Exit;
  end;

 	//ポート2～3設定
  txsz := 0;
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 2, 0);
	txbf[txsz] := SpcFile.Ram[$f6];
 	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 3, 0);
	txbf[txsz] := SpcFile.Ram[$f7];
 	Inc(txsz);
  //RAM転送2
  //  $0000～$00ef、$00fa～$00fc
  addr := $0000;
  lim := $0100;
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := $00;
 	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := Max((seq+1) and $ff, (seq+2) and $ff);
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := Max((seq+1) and $ff, (seq+2) and $ff);
  Inc(txsz);
 	if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;
  //
  while addr<lim do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;
		//
		txsz := 0;
		for i := 1 to EZUSB_PIC_FTDI_BUFSIZE div 6 do
    begin
    	if addr>=lim then
      	Break;
      //
      case addr of
      	$00..$ef, $fa..$fc:
		      begin
						SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
						txbf[txsz] := SpcFile.Ram[addr];
		  			Inc(txsz);
						SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
						txbf[txsz] := addr and $ff;
		  			Inc(txsz);
						SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
						txbf[txsz] := addr and $ff;
					  Inc(txsz);
		      end;
      end;
   		Inc(addr);
    end;
 		if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  	Exit;
  end;

  //DSPレジスタ転送
  lim := SizeOf(DspAddrTable) div SizeOf(DspAddrTable[0]);
  for ptr := 0 to lim-1 do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;
		//
    addr := DspAddrTable[ptr];
   	if (addr and $ff00)<>0 then
    	Continue;

		//
		txsz := 0;
		SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
		txbf[txsz] := addr;
		Inc(txsz);
		SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
		txbf[txsz] := $f2;
		Inc(txsz);
		SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
		txbf[txsz] := $f2;
  	Inc(txsz);
    //
		SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
 	  if (ptr=0) and (addr=$6c) then
			txbf[txsz] := $60 or (SpcFile.Dsp[addr] and $1f)
    else
			txbf[txsz] := SpcFile.Dsp[addr];
		Inc(txsz);
		SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
		txbf[txsz] := $f3;
		Inc(txsz);
		SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
		txbf[txsz] := $f3;
	  Inc(txsz);
   	//
		if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  		Exit;

 	  if addr=$4d then
    begin
    	//
      for i := 1 to 5 do
      begin
				txsz := 0;
	 	   	for j := 1 to 50 do
  	    begin
					txbf[txsz] := CMD_WAIT_1MS;
					txbf[txsz+1] := $00;
					txbf[txsz+2] := $00;
					Inc(txsz, 3);
        end;
    	 	//
 				if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
			  	Exit;
     	end;
    end;
  end;

 	//SPDIF設定/ミュート解除、ポート0～1設定、実行
  //  $00f1～$00f2
	txsz := 0;
  if bType=False then
  begin
		SetCommand(CMD_SSMP_SDSP_CTL, devcs, devaddr or 4, $01);
		txbf[txsz] := $00;
    if bSpdif=True then
			txbf[txsz] := txbf[txsz] or $10;
	  Inc(txsz);
	  //
		txbf[txsz] := CMD_WAIT_1MS;
		txbf[txsz+1] := $00;
		txbf[txsz+2] := $00;
		Inc(txsz, 3);
	end;
	//
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := SpcFile.Ram[$f2];
	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := $f2;
	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := $f2;
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := SpcFile.Ram[$f1] and $cf;
	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := $f1;
	Inc(txsz);
	SetCommand(CMD_SSMP_SDSP_R, devcs, devaddr or 0, 0);
	txbf[txsz] := $f1;
  Inc(txsz);
	//
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 0, 0);
	txbf[txsz] := SpcFile.Ram[$f4];
  Inc(txsz);
	SetCommand(CMD_SSMP_SDSP, devcs, devaddr or 1, 0);
	txbf[txsz] := SpcFile.Ram[$f5];
 	Inc(txsz);
	//
	txbf[txsz] := CMD_WAIT_1MS;
	txbf[txsz+1] := $00;
	txbf[txsz+2] := $00;
	Inc(txsz, 3);
	if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

  //
 	txsz := 0;
  nStart := timeGetTime64;
  nTimeOld := 0;
	PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, (nTimeLim div 1000) and $ffffffff, 0);
	while Terminated=False do
  begin
  	//
	  tm := timeGetTime64;
	  nTime := tm-nStart;
    tim2 := 100;
	  if (nTime-nTimeOld)>=tim2 then
	  begin
		 	if (txsz+2)<=EZUSB_PIC_FTDI_BUFSIZE then
      begin
		  	Inc(nTimeOld, tim2);
				PostMessage(MainForm.Handle, WM_THREAD_UPDATE_TIME, (nTime div 1000) and $ffffffff, 0);
				tm := (tim2*nSyncFreq) div 1000;
        while tm>0 do
        begin
		      txbf[txsz] := CMD_SYNC_8BIT;
  		    txbf[txsz+1] := Min($ff, tm);
          Dec(tm, txbf[txsz+1]);
    			Inc(txsz, 2);
        end;
      end;
	  end;
 	  //
    if nTime>nTimeLim then
     	Break;

    //
    if txsz>0 then
    begin
			if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  		Exit;
      txsz := 0;
    end;
    //
    Sleep(1);
  end;

	//
  if bType=True then
  begin
	  txsz := 0;
  	txbf[txsz] := CTL_RESET;
		Inc(txsz);
		if WriteEzusbPicFtdi(conno, ifno, PIPE_CTLCMD, @txbf, txsz)=False then
	 		Exit;
  end;
  //
  if bType=False then
  begin
	  //SPDIF設定/ミュート有効、リセット解除
		txsz := 0;
		SetCommand(CMD_SSMP_SDSP_CTL, devcs, devaddr or 4, $01);
		txbf[txsz] := $08;
    if bSpdif=True then
			txbf[txsz] := txbf[txsz] or $10;
	  Inc(txsz);
	  //
		txbf[txsz] := CMD_WAIT_1MS;
		txbf[txsz+1] := $00;
		txbf[txsz+2] := $00;
		Inc(txsz, 3);
	  //SPDIF設定/ミュート有効、リセット
		SetCommand(CMD_SSMP_SDSP_CTL, devcs, devaddr or 4, $01);
		txbf[txsz] := $0b;
    if bSpdif=True then
			txbf[txsz] := txbf[txsz] or $10;
	  Inc(txsz);
    //
		if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	 		Exit;
	end;

	//
  Result := ST_THREAD_END;
end;

procedure TSpcThread.SetCommand(cmd: Byte; cs: Word; addr: DWORD; reg: Word);
begin
	//
  case cmd of
		CMD_WRITE_REGA+$00, CMD_WRITE_REGA+$10, CMD_WRITE_REGA+$18, CMD_WRITE_REGA+$20,
    CMD_WRITE_REGA+$28, CMD_WRITE_REGA+$30, CMD_WRITE_REGA+$38,
		CMD_OPNA_ADPCM, CMD_OPNA_ADPCM_2, CMD_MSXAUDIO_ADPCM, CMD_OPN2_PCM:
     	addr := addr or ((reg shr 8)*2);
  end;
  //
  if ((addr xor dwHighAddr[cs]) and $fffffff8)<>0 then
  begin
  	//上位アドレスが変わった
    dwHighAddr[cs] := addr;
		txbf[txsz] := CMD_HIGHADDR_CS01;
		if (cs and 2)<>0 then
    	txbf[txsz] := txbf[txsz] or $01;
		txbf[txsz+1] := ((cs and 1) shl 7) or ((addr shr 3) and $7f);
		Inc(txsz, 2);
  end;
  //
  case cmd of
		CMD_WRITE_REGA+$00, CMD_WRITE_REGA+$10, CMD_WRITE_REGA+$18, CMD_WRITE_REGA+$20,
    CMD_WRITE_REGA+$28, CMD_WRITE_REGA+$30, CMD_WRITE_REGA+$38:
    	begin
				txbf[txsz] := (CMD_WRITE_REGA or (cmd and $38)) or (cs shl 1) or ((addr shr 1) and 1);
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $40;
				txbf[txsz+1] := reg and $ff;
        Inc(txsz, 2);
      end;
		CMD_WRITE_REGB:
    	begin
      	txbf[txsz] := CMD_WRITE_REGB or (cs shl 2) or (addr and 3);
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $10;
        Inc(txsz);
      end;
		CMD_READREG_CS01:
    	begin
      	txbf[txsz] := CMD_READREG_CS01 or ((cs and 1) shl 2) or (addr and 3);
      	if (cs and 2)<>0 then
        	Inc(txbf[txsz], $20);
        Inc(txsz);
      end;
		CMD_OPNA_ADPCM:
    	begin
      	txbf[txsz] := CMD_OPNA_ADPCM or cs;
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $04;
        Inc(txsz);
      end;
		CMD_OPNA_ADPCM_2:
    	begin
      	txbf[txsz] := CMD_OPNA_ADPCM_2 or cs;
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $04;
        Inc(txsz);
      end;
		CMD_MSXAUDIO_ADPCM:
    	begin
      	txbf[txsz] := CMD_MSXAUDIO_ADPCM or (cs shl 1) or ((addr shr 1) and 1);
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $08;
        Inc(txsz);
      end;
		CMD_OPN2_PCM:
    	begin
      	txbf[txsz] := CMD_OPN2_PCM or cs;
      	if (addr and 4)<>0 then
					txbf[txsz] := txbf[txsz] or $04;
        Inc(txsz);
      end;
  end;
end;

function TSpcThread.WriteEzusbPicFtdi(conno: Integer; ifno: Integer; pipenum: Cardinal; txbf: Pointer; txsz: Cardinal): Boolean;
	var
    ezusbr: LongBool;
    ezusbrxsz: Cardinal;
    ezusbbtc: TBULK_TRANSFER_CONTROL;
  var
		pictxbf: array[0..(2+EZUSB_PIC_FTDI_BUFSIZE)-1] of Byte;
		picr, pictxsz, picrxsz: DWORD;
  var
  	ftdir: FT_STATUS;
  var
  	s: String;
  	i: Integer;
begin
  //
	Result := True;
  case DeviceForm.CnDevice[conno].nIfSelect of
  	IF_EZUSB:
    	begin
       	Move(txbf^, PByte(@pictxbf[0])^, txsz);
        pictxsz := txsz;
			 	ezusbbtc.pipeNum := pipenum;
			 	ezusbr := DeviceIoControl(DeviceForm.Ezusb[ifno].hndHandle, IOCTL_EZUSB_BULK_WRITE,
			  	@ezusbbtc, SizeOf(ezusbbtc), txbf, txsz, ezusbrxsz, nil);
				if ezusbr=False then
					Result := False;
		  	s := BoolToStr(ezusbr) + ',' + IntToStr(conno) + ',' + IntToStr(pipenum) + ',' + IntToStr(txsz) + '/' + IntToStr(ezusbrxsz) + ',';
      end;
    IF_PIC:
    	begin
       	Move(txbf^, PByte(@pictxbf[2])^, txsz);
       	pictxsz := 2+txsz;
		 		pictxbf[0] := (pictxsz-2) and $ff;
			  pictxbf[1] := (pipenum shl 6) or (((pictxsz-2) shr 8) and $3f);
				picr := MainForm.MPUSBWrite(DeviceForm.Pic[ifno].hndWrite, @pictxbf, pictxsz, @picrxsz, INFINITE);
				if picr=MPUSB_FAIL then
					Result := False;
		  	s := IntToStr(picr) + ',' + IntToStr(conno) + ',' + IntToStr(pipenum) + ',' + IntToStr(pictxsz) + '/' + IntToStr(picrxsz) + ',';
      end;
    IF_FTDI:
    	begin
       	Move(txbf^, PByte(@pictxbf[2])^, txsz);
       	pictxsz := 2+txsz;
		 		pictxbf[0] := (pictxsz-2) and $ff;
			  pictxbf[1] := (pipenum shl 6) or (((pictxsz-2) shr 8) and $3f);
        ftdir := MainForm.FT_Write(DeviceForm.Ftdi[ifno].hndDevice, @pictxbf, pictxsz, @picrxsz);
				if ftdir<>FT_OK then
					Result := False;
		  	s := IntToStr(ftdir) + ',' + IntToStr(conno) + ',' + IntToStr(pipenum) + ',' + IntToStr(pictxsz) + '/' + IntToStr(picrxsz) + ',';
      end;
    else
    	begin
      	pictxsz := 0;
			  s := '?';
      end;
  end;

  //
	if MainForm.bDebug=True then
  begin
    if pictxsz>0 then
    begin
  		for i := 0 to pictxsz-1 do
	  		s := s + IntToHex(pictxbf[i], 2);
    end;
		slLog.Add(s);
  end;
end;

procedure TSpcThread.Execute;
	var
  	res: Integer;
begin
  //
	slLog := TStringList.Create;

  //
  FillChar(dwHighAddr, SizeOf(dwHighAddr), $ff);
	res := Main;

  //
  if (MainForm.bDebug=True) and (slLog.Count>0) then
    slLog.SaveToFile('.\_psldebug_pspc.txt');
  //
  slLog.Free;

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

