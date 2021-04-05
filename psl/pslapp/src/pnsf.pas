unit pnsf;

interface

uses
  Classes, Windows, SysUtils, Math, MMSystem, Unit1, Unit2;

type
  TNsfThread = class(TThread)
  private
    { Private 宣言 }
    FileBuf: PFileBuf;
    dwDataSize: DWORD;
    nTimeInit, nTimeLim: Int64;
    slLog: TStringList;
    //
    nTimerInfo1, nTimerInfo2: Int64;
    byMode: Byte;
    Romsel: array[0..5] of Byte;
    wLoadAddr: Word;
    xRatio: Extended;
		//
    InitFileBuf: array[0..NSF_CTLSIZE-1] of Byte;
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
		constructor Create(nsfh: PNsfHeader; pfb: Pointer; pfs: DWORD; ti1, ti2: DWORD; r: Extended; tlim: Int64; ctl: String);
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

    procedure TNsfThread.UpdateCaption;
    begin
      Form1.Caption := 'TNsfThread スレッドから書き換えました';
    end;

  Execute メソッドの中で Synchronize メソッドに渡すことでメイ
  ンスレッドが所有する Form1 の Caption プロパティを安全に変
  更できます。

      Synchronize(UpdateCaption);
}

{ TNsfThread }

constructor TNsfThread.Create(nsfh: PNsfHeader; pfb: Pointer; pfs: DWORD; ti1, ti2: DWORD; r: Extended; tlim: Int64; ctl: String);
	var
  	s: Integer;
    fs: TFileStream;
    offset, {start,} header, init, play: Integer;
    p: PByte;
  var
  	i, j, cmd: Integer;
begin
	//
  FileBuf := pfb;
  dwDataSize := pfs;
	//
  p := @nsfh^.Name[0];
  byMode := p^;
  Inc(p);
 	Move(p^, Romsel, SizeOf(RomSel));
  wLoadAddr := nsfh^.wLoadAddress;
 	nTimerInfo1 := ti1;
 	nTimerInfo2 := ti2;
  xRatio := r;
  nTimeInit := -1;
  nTimeLim := tlim;

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
			  header := InitFileBuf[offset+2] or (InitFileBuf[offset+3] shl 8);
			  init := InitFileBuf[offset+4] or (InitFileBuf[offset+5] shl 8);
			  play := InitFileBuf[offset+6] or (InitFileBuf[offset+7] shl 8);
			  //
			  Move(nsfh^, InitFileBuf[header], SizeOf(nsfh^));
			  InitFileBuf[init] := nsfh^.wInitAddress and $ff;
			  InitFileBuf[init+1] := nsfh^.wInitAddress shr 8;
			  InitFileBuf[play] := nsfh^.wPlayAddress and $ff;
			  InitFileBuf[play+1] := nsfh^.wPlayAddress shr 8;
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

function TNsfThread.timeGetTime64: Int64;
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

function TNsfThread.Main: Integer;
	var
  	reqno, conno, ifno: Integer;
  	devcs, devaddr: Word;
    nSyncFreq: Integer;
    //
    i, j: Integer;
    ptr, addr: DWORD;
    //
    wVBlank: Word;
    xClock: Extended;
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
  txbf[txsz] := CTL_START;
  Inc(txsz);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_CTLCMD, @txbf, txsz)=False then
  	Exit;

  //EZ-USB/PIC/FTDI⇔RAM
	txsz := 0;
	txbf[txsz] := CMD_WAIT_1MS;
	txbf[txsz+1] := $00;
	txbf[txsz+2] := $00;
	SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $01);
	txbf[txsz] := byMode or $03;
  Inc(txsz);
  //ROMSEL設定
  for i := Low(Romsel) to High(RomSel) do
  begin
		SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $44);
		txbf[txsz] := Romsel[i];
	  Inc(txsz);
  end;
  //VBLANK分周
  case DeviceForm.CnDevice[conno].nInfo of
  	DEVICE_RP2A03, DEVICE_RP2A03_EXT:
		  xClock := (3579545*6)/12;
	  else
		  xClock := (4433618.75*6)/15;
  end;
  wVBlank := Round((xClock*xRatio*nTimerInfo1)/nTimerInfo2)-1;
  wVBlank := Max(wVBlank, 23863);
	wVBlank := Min(wVBlank, 44335);
  //
	SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $0a);
	txbf[txsz] := (wVBlank shr 8) and $ff;
  Inc(txsz);
	SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $09);
	txbf[txsz] := wVBlank and $ff;
  Inc(txsz);
  //
  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

	//制御プログラム転送
  ptr := 0;
  while ptr<NSF_CTLSIZE do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;

    //アドレス
	  addr := NSF_CTLADDR+ptr;
		txsz := 0;
		SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $03);
		txbf[txsz] := (addr shr 16) and $ff;
	  Inc(txsz);
		SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $02);
		txbf[txsz] := (addr shr 8) and $ff;
	  Inc(txsz);
    //データ
    for i := 1 to 16 do
    begin
	    //
			SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr or 6, 0);
	    for j := 1 to OPNA_ADPCM_LEN do
	    begin
				txbf[txsz] := InitFileBuf[ptr];
			  Inc(txsz);
		    Inc(ptr);
	    end;
    end;
    //
	  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  	Exit;
  end;

	//再生プログラム転送
  ptr := 0;
  while ptr<dwDataSize do
  begin
  	//
		if Terminated=True then
    begin
    	Result := ST_THREAD_END;
    	Exit;
    end;

    //アドレス
	  addr := NSF_ROMADDR+ptr;
		txsz := 0;
		SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $03);
		txbf[txsz] := (addr shr 16) and $ff;
	  Inc(txsz);
		SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $02);
		txbf[txsz] := (addr shr 8) and $ff;
	  Inc(txsz);
    //データ
    for i := 1 to 16 do
    begin
	    //
			SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr or 6, 0);
	    for j := 1 to OPNA_ADPCM_LEN do
	    begin
				txbf[txsz] := FileBuf^[ptr];
			  Inc(txsz);
		    Inc(ptr);
	    end;
    end;
    //
	  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
	  	Exit;
  end;

  //CPU⇔RAM, 再生開始
	txsz := 0;
	SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $01);
	txbf[txsz] := byMode or $00;
  Inc(txsz);
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

  //CPU⇔RAM, 再生停止
	txsz := 0;
	SetCommand(COM_RP2A03_CTL, devcs, devaddr or 6, $01);
	txbf[txsz] := byMode or $02;
  Inc(txsz);
	txbf[txsz] := CMD_WAIT_1MS;
	txbf[txsz+1] := $00;
	txbf[txsz+2] := $00;
	Inc(txsz, 3);
  if WriteEzusbPicFtdi(conno, ifno, PIPE_DATACMD, @txbf, txsz)=False then
  	Exit;

	//
  Result := ST_THREAD_END;
end;

procedure TNsfThread.SetCommand(cmd: Byte; cs: Word; addr: DWORD; reg: Word);
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

function TNsfThread.WriteEzusbPicFtdi(conno: Integer; ifno: Integer; pipenum: Cardinal; txbf: Pointer; txsz: Cardinal): Boolean;
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

procedure TNsfThread.Execute;
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
    slLog.SaveToFile('.\_psldebug_pnsf.txt');
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

