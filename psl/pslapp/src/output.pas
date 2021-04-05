unit output;

interface

uses
  Classes, Windows, SysUtils, Math, MMSystem, Unit1, Unit2;

//
const
  FREQ_SYNC = 44100;
  CMD_SYNC = $fffffff9;
	CMD_WAIT = $fffffffc;
	CMD_EOF  = $fffffffd;

type
  TOutputThread = class(TThread)
  private
    { Private 宣言 }
		nNo, nIf, nIfNo, nSyncFreq: Integer;
    hndEzusb, hndPic: THandle;
		hndFtdi: FT_HANDLE;
		nTimeInit: Int64;
		slLog: TStringList;
    //
	  dwHighAddr: array[0..3] of DWORD;
    txsz: Cardinal;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
    //
    function timeGetTime64: Int64;
		function Main: Integer;
		function WriteInt(conno: Integer; addr: DWORD; data: Word): Boolean;
		procedure SetCommand(cmd: Byte; cs: Word; addr: DWORD; reg: Word);
		function WriteEzusbPicFtdi(conno: Integer; addr: DWORD; data: Word): Boolean;
		procedure WaitInt(n: Integer);
		procedure Solo1MixerWait(addr: DWORD);
		procedure WriteDev(conno: Integer; addr: DWORD; data: Word);
		procedure KeyOff(state: Integer);
  protected
    { protected 宣言 }
    procedure Execute; override;
  published
    { published 宣言 }
		constructor Create(n: Integer);
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

    procedure TOutputThread.UpdateCaption;
    begin
      Form1.Caption := 'TOutputThread スレッドから書き換えました';
    end;

  Execute メソッドの中で Synchronize メソッドに渡すことでメイ
  ンスレッドが所有する Form1 の Caption プロパティを安全に変
  更できます。

      Synchronize(UpdateCaption);
}

{ TOutputThread }

constructor TOutputThread.Create(n: Integer);
begin
	//
  nNo := n;
  case nNo of
		1..EZUSB_DEVMAX:
    	begin
			  nIf := IF_EZUSB;
			  nIfNo := nNo-(1);
        nSyncFreq := DeviceForm.Ezusb[nIfNo].nSyncFreq;
				hndEzusb := DeviceForm.Ezusb[nIfNo].hndHandle;
        hndPic := INVALID_HANDLE_VALUE;
        hndFtdi := nil;
      end;
    1+EZUSB_DEVMAX..EZUSB_DEVMAX+PIC_DEVMAX:
    	begin
			  nIf := IF_PIC;
			  nIfNo := nNo-(1+EZUSB_DEVMAX);
        nSyncFreq := DeviceForm.Pic[nIfNo].nSyncFreq;
			  hndEzusb := INVALID_HANDLE_VALUE;
				hndPic := DeviceForm.Pic[nIfNo].hndWrite;
        hndFtdi := nil;
      end;
    1+EZUSB_DEVMAX+PIC_DEVMAX..EZUSB_DEVMAX+PIC_DEVMAX+FTDI_DEVMAX:
    	begin
			  nIf := IF_FTDI;
			  nIfNo := nNo-(1+EZUSB_DEVMAX+PIC_DEVMAX);
        nSyncFreq := DeviceForm.Ftdi[nIfNo].nSyncFreq;
			  hndEzusb := INVALID_HANDLE_VALUE;
				hndPic := INVALID_HANDLE_VALUE;
        hndFtdi := DeviceForm.Ftdi[nIfNo].hndDevice;
      end;
  	else
    	begin
			  nIf := IF_INT;
			  nIfNo := 0;
        nSyncFreq := 0;
			  hndEzusb := INVALID_HANDLE_VALUE;
        hndPic := INVALID_HANDLE_VALUE;
        hndFtdi := nil;
      end;
  end;

  //
	nTimeInit := MainForm.nStart;

  //
	inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpHigher;
end;

function TOutputThread.timeGetTime64: Int64;
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

var
  DevSts: array[0..CONNECT_DEVMAX-1] of TDeviceStatus;

function TOutputThread.Main: Integer;
	var
    ezusbr: LongBool;
    ezusbrxsz: Cardinal;
    ezusbbtc: TBULK_TRANSFER_CONTROL;
  var
		picr, picrxsz: DWORD;
  var
  	ftdir: FT_STATUS;
  var
    i, rptr, orglen, len: Integer;
    term: Boolean;
  var
    conno: Byte;
  	addr: DWORD;
    data: Word;
    tm, tim2, sync: Int64;
    nTime, nSync: Int64;
begin
	//
  Result := ST_THREAD_ERROR;

  //
  case nIf of
  	IF_EZUSB:
    	begin
		  	txsz := 0;
			  txbf[txsz] := CTL_START;
		 		Inc(txsz);
			  if hndEzusb<>INVALID_HANDLE_VALUE then
			  begin
			 		ezusbbtc.pipeNum := PIPE_CTLCMD;
				  ezusbr := DeviceIoControl(hndEzusb, IOCTL_EZUSB_BULK_WRITE,
			  		@ezusbbtc, SizeOf(ezusbbtc), @txbf, txsz, ezusbrxsz, nil);
					if ezusbr=False then
			  	  Exit;
			  end;
		  	txsz := 0;
      end;
    IF_PIC:
    	begin
		  	txsz := 2;
			  txbf[txsz] := CTL_START;
		 		Inc(txsz);
			  if hndPic<>INVALID_HANDLE_VALUE then
			  begin
			  	txbf[0] := (txsz-2) and $ff;
				  txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
					picr := MainForm.MPUSBWrite(hndPic, @txbf, txsz, @picrxsz, INFINITE);
					if picr=MPUSB_FAIL then
			    	Exit;
			  end;
		  	txsz := 2;
      end;
    IF_FTDI:
    	begin
		  	txsz := 2;
			  txbf[txsz] := CTL_START;
		 		Inc(txsz);
			  if hndFtdi<>nil then
			  begin
			  	txbf[0] := (txsz-2) and $ff;
				  txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
	        ftdir := MainForm.FT_Write(hndFtdi, @txbf, txsz, @picrxsz);
					if ftdir<>FT_OK then
			    	Exit;
			  end;
		  	txsz := 2;
      end;
  end;

 	//
  KeyOff(0);
  for i := 1 to 5 do
	 	WriteEzusbPicFtdi(0, CMD_WAIT, 0);
  KeyOff(1);
  for i := 1 to 10 do
	 	WriteEzusbPicFtdi(0, CMD_WAIT, 0);

	//
  rptr := 0;
  orglen := 0;
  len := orglen;
  term := False;
  sync := 0;
  nTime := 0;
  nSync := 0;
	while (Terminated=False) and (term=False) do
  begin

    //
    if len<1 then
    begin
      //
    	MainForm.ThreadCri[nNo].Cri.Enter;
      len := MainForm.ThreadCri[nNo].nLength;
      if len<0 then
		 	  orglen := -1
      else
      begin
  		  Dec(len, orglen);
        MainForm.ThreadCri[nNo].nLength := len;
		 	  orglen := Min(THREAD_READSIZE, len);
    	end;
			MainForm.ThreadCri[nNo].Cri.Leave;
    	//
	    len := orglen;
      if len<0 then
     	begin
       	//停止
       	Break;
      end else
	    if len<1 then
	      Sleep(1);
    end else
    begin
    	//
  	  tm := timeGetTime64-(MainForm.nStart+1000);
			case nIf of
      	IF_EZUSB, IF_PIC, IF_FTDI:
    	  	begin
  	  		  if tm<0 then
			      begin
  	   				Sleep(1);
    		 		  Continue;
		    	  end;
      	  end;
    	  else
  	    	begin
						if (tm*FREQ_SYNC)<(sync*1000) then
			    	begin
  				   	Sleep(1);
		  	   	  Continue;
				    end;
  	      end;
	    end;
      //
    	while (Terminated=False) and (len>0) do
  	  begin
	    	//
        conno := MainForm.ThreadCri[nNo].Buf[rptr].byNo;
        addr := MainForm.ThreadCri[nNo].Buf[rptr].dwAddr;
        data := MainForm.ThreadCri[nNo].Buf[rptr].wData;
        rptr := (rptr+1) mod MainForm.ThreadCri[nNo].nBufSize;
        Dec(len);
				//
		    tm := timeGetTime64-(MainForm.nStart+1000);
		    tim2 := 500;
			  if (tm-nTime)>=tim2 then
			  begin
			  	nTime := tm;
			    if MainForm.ThreadCri[nNo].bTimeEnb then
						PostMessage(MainForm.Handle, WM_THREAD_UPDATE_TIME, (nTime div 1000) and $ffffffff, 0);
		    end;
				//
        case addr of
        	$00000000..$1fffffff:
          	begin
	          	//レジスタ書き込み
				    	WriteDev(conno, addr, data);
            end;
        	CMD_SYNC:
		        begin
            	//SYNC
    		    	Inc(sync, data);
              Inc(nSync, data);
							case nIf of
					      IF_EZUSB, IF_PIC, IF_FTDI:
					      	begin
                  	while True do
                    begin
								     	tim2 := Min((sync*nSyncFreq) div FREQ_SYNC, $ff);
						  		   	if tim2<1 then
                      	Break;
				      			 	Dec(sync, (tim2*FREQ_SYNC) div nSyncFreq);
					  			  	WriteEzusbPicFtdi(0, CMD_SYNC, tim2);
					    	    end;
                  end;
                else
                	Break;
					    end;
            end;
          CMD_EOF:
          	begin
			       	//終端
            	term := True;
			       	Break;
            end;
        	else
          	begin
            	//その他
            	term := True;
              len := -1;
            	Break;
            end;
        end;
      end;
    end;
  end;

  //
  case nIf of
  	IF_EZUSB:
    	begin
		  	if txsz>0 then
		    begin
				  if hndEzusb<>INVALID_HANDLE_VALUE then
				 	begin
					 	ezusbbtc.pipeNum := PIPE_DATACMD;
			  		ezusbr := DeviceIoControl(hndEzusb, IOCTL_EZUSB_BULK_WRITE,
			  	   	@ezusbbtc, SizeOf(ezusbbtc), @txbf, txsz, ezusbrxsz, nil);
						if ezusbr=False then
					  	Exit;
			    end;
			  	txsz := 0;
			  end;
      end;
    IF_PIC:
    	begin
		  	if txsz>2 then
		    begin
				  if hndPic<>INVALID_HANDLE_VALUE then
				 	begin
			  		txbf[0] := (txsz-2) and $ff;
					  txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						picr := MainForm.MPUSBWrite(hndPic, @txbf, txsz, @picrxsz, INFINITE);
						if picr=MPUSB_FAIL then
				    	Exit;
			    end;
			  	txsz := 2;
			  end;
      end;
    IF_FTDI:
    	begin
		  	if txsz>2 then
		    begin
				  if hndFtdi<>nil then
				 	begin
			  		txbf[0] := (txsz-2) and $ff;
					  txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						ftdir := MainForm.FT_Write(hndFtdi, @txbf, txsz, @picrxsz);
						if ftdir<>FT_OK then
				    	Exit;
			    end;
			  	txsz := 2;
			  end;
      end;
  end;

 	//
  KeyOff(0);
  for i := 1 to 5 do
	 	WriteEzusbPicFtdi(0, CMD_WAIT, 0);
  KeyOff(1);
  for i := 1 to 10 do
	 	WriteEzusbPicFtdi(0, CMD_WAIT, 0);
  case nIf of
  	IF_EZUSB:
    	begin
		  	if txsz>0 then
		    begin
				  if hndEzusb<>INVALID_HANDLE_VALUE then
				 	begin
					 	ezusbbtc.pipeNum := PIPE_DATACMD;
			  		ezusbr := DeviceIoControl(hndEzusb, IOCTL_EZUSB_BULK_WRITE,
			  	   	@ezusbbtc, SizeOf(ezusbbtc), @txbf, txsz, ezusbrxsz, nil);
						if ezusbr=False then
					  	Exit;
			    end;
			  	txsz := 0;
			  end;
      end;
    IF_PIC:
    	begin
		  	if txsz>2 then
		    begin
				  if hndPic<>INVALID_HANDLE_VALUE then
				 	begin
			  		txbf[0] := (txsz-2) and $ff;
					  txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						picr := MainForm.MPUSBWrite(hndPic, @txbf, txsz, @picrxsz, INFINITE);
						if picr=MPUSB_FAIL then
				    	Exit;
			    end;
			  	txsz := 2;
			  end;
      end;
    IF_FTDI:
    	begin
		  	if txsz>2 then
		    begin
				  if hndFtdi<>nil then
				 	begin
			  		txbf[0] := (txsz-2) and $ff;
					  txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						ftdir := MainForm.FT_Write(hndFtdi, @txbf, txsz, @picrxsz);
						if ftdir<>FT_OK then
				    	Exit;
			    end;
			  	txsz := 2;
			  end;
      end;
  end;

	//
  if len<0 then
	  Result := ST_THREAD_TERMINATE
  else
	  Result := ST_THREAD_END;
end;

procedure TOutputThread.Execute;
	var
  	i, j, res: Integer;
begin
	//
	FillChar(DevSts, SizeOf(DevSts), $00);
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //pit
    DevSts[i].Pit.wEnable := $ff00;
    DevSts[i].Pit.byOutput := $00;
    DevSts[i].Pit.byVolume := $3f;
    //dcsg
	  for j := 0 to 3 do
	  	DevSts[i].DcsgGg.Attenuation[j] := $9f+((j*2) shl 4);
   	DevSts[i].DcsgGg.byMask := $ff;
    //opm
    FillChar(DevSts[i].Opm.wTl, SizeOf(DevSts[i].Opm.wTl), $ff);
    //opna
    FillChar(DevSts[i].Opna.wTl, SizeOf(DevSts[i].Opna.wTl), $ff);
    DevSts[i].Opna.dwOldAddr := $ffffffff;
    DevSts[i].Opna.nAdpcmLen := 0;
    FillChar(DevSts[i].Opna.AdpcmBuf, SizeOf(DevSts[i].Opna.AdpcmBuf), $00);
    FillChar(DevSts[i].Opna.Reg, SizeOf(DevSts[i].Opna.Reg), $00);
    //opn2
    DevSts[i].Opn2.byDacSelect := $00;
    DevSts[i].Opn2.byDacPan := $00;
    //opll
    DevSts[i].Opll.nMelodyCh := 9;
    FillChar(DevSts[i].Opll.Reg, SizeOf(DevSts[i].Opll.Reg), $00);
    //msxaudio
    FillChar(DevSts[i].Msxaudio.Reg, SizeOf(DevSts[i].Msxaudio.Reg), $00);
    //scc
    DevSts[i].Scc.wHighAddr := $ffff;
  end;

  //
	slLog := TStringList.Create;

  //
  FillChar(dwHighAddr, SizeOf(dwHighAddr), $ff);
 	res := Main;

  //
  if (MainForm.bDebug=True) and (slLog.Count>0) then
    slLog.SaveToFile('.\_psldebug_output.txt');
  //
 	slLog.Free;

  //
  if res=ST_THREAD_ERROR then
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, nNo, ST_THREAD_ERROR)
  else
  if (Terminated=True) or (res=ST_THREAD_TERMINATE) then
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, nNo, ST_THREAD_TERMINATE)
  else
		PostMessage(MainForm.Handle, WM_THREAD_TERMINATE, nNo, ST_THREAD_END);
end;

procedure TOutputThread.WaitInt(n: Integer);
	var
    tm, lim: Int64;
begin
	//パフォーマンスカウンタが使用できるか確認
  if MainForm.nFreq>0 then
  begin
  	//使用できる
	  QueryPerformanceCounter(lim);
  	Inc(lim, (MainForm.nFreq*n+500000) div 1000000);
	  while Terminated=False do
	  begin
  	  QueryPerformanceCounter(tm);
   		if tm>=lim then
	     	Break;
	  end;
  end else
  begin
  	//使用できない
    Sleep(0);
  end;
end;

procedure TOutputThread.Solo1MixerWait(addr: DWORD);
	var
  	i: Integer;
begin
	//
  for i := 1 to 10 do
	begin
   	if (MainForm.IoRead8(addr+$6) and $40)=0 then
    	Break;
   	Sleep(1);
  end;
end;

procedure TOutputThread.WriteDev(conno: Integer; addr: DWORD; data: Word);
begin
	//書き込み
  case nIF of
    IF_EZUSB, IF_PIC, IF_FTDI:
    	WriteEzusbPicFtdi(conno, addr, data);
    else
   		WriteInt(conno, addr, data);
  end;
end;

function TOutputThread.WriteInt(conno: Integer; addr: DWORD; data: Word): Boolean;
	var
    base: DWORD;
    tm, lim: Int64;
  var
  	ch, info: Integer;
  	d: Byte;
begin
	//
  if (addr=CMD_SYNC) or (addr=CMD_WAIT) then
  begin
  	//
		Sleep(20);
  end else
  begin
		//
	  base := DeviceForm.CnDevice[conno].dwIfIntBase;
    info := DeviceForm.CnDevice[conno].nInfo;
		case info of
			DEVICE_PIT:
				begin
				 	//カウンタ0をカウンタ2として処理
          ch := MainForm.ThreadCri[nNo].nIntPitChannel;
					case addr of
						$0000..$0002:
	          	begin
              	if Integer(addr)=ch then
                begin
							 		MainForm.IoWrite8(base+2, data and $ff);
		            	WaitInt(20);
              	end;
	            end;
						$0003:
							begin
								if ((data shr 6) and 3)=ch then
							 	begin
									data := (data and $3f) or (2 shl 6);
									MainForm.IoWrite8(base+3, data);
		            	WaitInt(20);
								end;
							end;
						$0100:
							begin
								//出力
                if ((data xor DevSts[conno].Pit.byOutput) and (1 shl ch))<>0 then
                begin
									d := MainForm.IoRead8($61);
									if ((data and (1 shl ch))<>0) and ((DevSts[conno].Pit.byVolume and (3 shl (ch*2)))<>0) then
										d := d or $03
									else
										d := d and $fc;
									MainForm.IoWrite8($61, d);
	          	  	WaitInt(20);
              	  DevSts[conno].Pit.byOutput := data;
                end;
							end;
						$0101:
							begin
								//音量
                if ((data xor DevSts[conno].Pit.byVolume) and (3 shl (ch*2)))<>0 then
                begin
									d := MainForm.IoRead8($61);
									if ((DevSts[conno].Pit.byOutput and (1 shl ch))<>0) and ((data and (3 shl (ch*2)))<>0) then
										d := d or $03
									else
										d := d and $fc;
									MainForm.IoWrite8($61, d);
		            	WaitInt(20);
	                DevSts[conno].Pit.byVolume := data;
                end;
              end;
					end;
				end;
			DEVICE_DS1, DEVICE_SOLO1:
				begin
				 	//
          if ((info=DEVICE_SOLO1) and (MainForm.ThreadCri[nNo].bSolo1ChannelLr=True)) and
           	((addr and $00c0)=$00c0) then
          begin
           	//ch/fb/cnt
						data := ((data and $20) shr 1) or ((data and $10) shl 1) or (data and $cf);
          end;
          //
					case addr of
						$0000..$00ff:
							begin
								MainForm.IoWrite8(base, addr and $ff);
	            	WaitInt(20);
								MainForm.IoWrite8(base+1, data and $ff);
	            	WaitInt(20);
							end;
						$0100..$01ff:
							begin
								MainForm.IoWrite8(base+2, addr and $ff);
	            	WaitInt(20);
								MainForm.IoWrite8(base+3, data and $ff);
	            	WaitInt(20);
							end;
            $0200..$02ff:
	            begin
              	//solo-1, mixer
                Solo1MixerWait(base);
                MainForm.IoWrite8(base+$4, addr and $ff);
                Solo1MixerWait(base);
                MainForm.IoWrite8(base+$5, data and $ff);
                Solo1MixerWait(base);
  	          end;
					end;
				end;
			DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
				begin
					//
					tm := timeGetTime64;
					lim := tm+50;
					while tm<lim do
					begin
						if (MainForm.FuncMemRead32(base+$0018) and $0f)>1 then
							Break;
						tm := timeGetTime64;
					end;
					//
					tm := timeGetTime64;
					lim := tm+50;
					while tm<lim do
					begin
						if (MainForm.FuncMemRead32(base+$0004) and $80)=$00 then
							Break;
						tm := timeGetTime64;
					end;
					//
					case addr of
						$0000..$00ff:
							begin
								MainForm.FuncMemWrite8(base+$0000, addr and $ff);
								MainForm.FuncMemWrite8(base+$0004, data and $ff);
	            	WaitInt(20);
							end;
					end;
				end;
			DEVICE_OPN3L:
				begin
	        //
					case addr of
	        	$0000..$000f:
	          	begin
								MainForm.FuncMemWrite32(base+$0100, addr and $ff);
								MainForm.FuncMemWrite32(base+$0104, data and $ff);
	            	WaitInt(20);
		          end;
						$0010..$00ff:
							begin
								//
								tm := timeGetTime64;
								lim := tm+50;
								while tm<lim do
								begin
									if (MainForm.FuncMemRead32(base+$0100) and $80)=$00 then
										Break;
									tm := timeGetTime64;
								end;
	              //
								MainForm.FuncMemWrite32(base+$0100, addr and $ff);
	            	WaitInt(20);
								MainForm.FuncMemWrite32(base+$0104, data and $ff);
	            	WaitInt(20);
				 			end;
						$0100..$01ff:
				 			begin
								//
								tm := timeGetTime64;
								lim := tm+50;
								while tm<lim do
								begin
									if (MainForm.FuncMemRead32(base+$0100) and $80)=$00 then
										Break;
									tm := timeGetTime64;
								end;
	              //
								MainForm.FuncMemWrite32(base+$0108, addr and $ff);
	            	WaitInt(20);
								MainForm.FuncMemWrite32(base+$010c, data and $ff);
	            	WaitInt(20);
							end;
					end;
				end;
		end;
    //
		DevSts[conno].Reg[addr and $ffff] := data;
  end;

  //
  Result := True;
end;

procedure TOutputThread.SetCommand(cmd: Byte; cs: Word; addr: DWORD; reg: Word);
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

function TOutputThread.WriteEzusbPicFtdi(conno: Integer; addr: DWORD; data: Word): Boolean;
	var
    ezusbr: LongBool;
    ezusbrxsz: Cardinal;
    ezusbbtc: TBULK_TRANSFER_CONTROL;
  var
		picr, picrxsz: DWORD;
    s: String;
  var
  	ftdir: FT_STATUS;
	var
  	devcs, devaddr: Word;
    i, waitlp, len, info, ch: Integer;
    sccad: Word;
begin
	//
  Result := False;
  waitlp := Ceil((20*nSyncFreq)/1000);	//20ms
  i := 2+Max(2*(OPNA_ADPCM_LEN-1), 1+OPNA_ADPCM_LEN);
  len := Integer(txsz)+ Max(i, waitlp*3) +(2+3*2);
  case nIF of
  	IF_EZUSB:
    	begin
			  if (txsz>0) and (len>=EZUSB_PIC_FTDI_BUFSIZE) then
			  begin
			  	if hndEzusb<>INVALID_HANDLE_VALUE then
          begin
					 	ezusbbtc.pipeNum := PIPE_DATACMD;
				  	ezusbr := DeviceIoControl(hndEzusb, IOCTL_EZUSB_BULK_WRITE,
				     	@ezusbbtc, SizeOf(ezusbbtc), @txbf, txsz, ezusbrxsz, nil);
						if ezusbr=False then
				      Exit;
          end;
			    txsz := 0;
			  end;
      end;
    IF_PIC:
    	begin
				if (txsz>2) and (len>=EZUSB_PIC_FTDI_BUFSIZE) then
				begin
					if hndPic<>INVALID_HANDLE_VALUE then
          begin
				 		txbf[0] := (txsz-2) and $ff;
						txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						picr := MainForm.MPUSBWrite(hndPic, @txbf, txsz, @picrxsz, INFINITE);
						if picr=MPUSB_FAIL then
							Exit;
        	end;
				  //
					if MainForm.bDebug=True then
				  begin
				    if txsz>0 then
				    begin
				  		for i := 0 to txsz-1 do
	  						s := s + IntToHex(txbf[i], 2);
				    end;
						slLog.Add(s);
				  end;
					txsz := 2;
				end;
      end;
    IF_FTDI:
    	begin
				if (txsz>2) and (len>=EZUSB_PIC_FTDI_BUFSIZE) then
				begin
					if hndFtdi<>nil then
          begin
				 		txbf[0] := (txsz-2) and $ff;
						txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
    		    ftdir := MainForm.FT_Write(hndFtdi, @txbf, txsz, @picrxsz);
						if ftdir<>FT_OK then
							Exit;
        	end;
					txsz := 2;
				end;
      end;
    else
    	Exit;
  end;

	//
  if addr=CMD_SYNC then
  begin
  	//
		case data of
			$0001:
				begin
					txbf[txsz] := CMD_SYNC_1;
					Inc(txsz);
				end;
			$0002..$00ff:
				begin
					txbf[txsz] := CMD_SYNC_8BIT;
					txbf[txsz+1] := data;
					Inc(txsz, 2);
				end;
    end;
  end else
  if addr=CMD_WAIT then
  begin
  	//
		for i := 1 to waitlp do
    begin
			txbf[txsz] := CMD_WAIT_1MS;
			txbf[txsz+1] := $00;
			txbf[txsz+2] := $00;
			Inc(txsz, 3);
    end;
  end else
  begin
		//
		devcs := DeviceForm.CnDevice[conno].nIfEzusbPicFtdiDevCs;
    devaddr := DeviceForm.CnDevice[conno].nIfEzusbPicFtdiDevAddr;
		info := DeviceForm.CnDevice[conno].nInfo;
		case info of
 	  	DEVICE_USART:
      	begin
					case addr of
	        	$0000..$0001:
            	begin
              end;
    	    	$0100..$0101:
  	        	begin
	            end;
          end;
        end;
			DEVICE_PIT:
				begin
					case addr of
						$0000..$0003:
							begin
              	if ((addr xor DevSts[conno].Pit.wEnable) and $ff03)<>0 then
                begin
									SetCommand(CMD_PIT, devcs, devaddr or 0, 0);
									txbf[txsz] := (DevSts[conno].Pit.wEnable and $fc) or (addr and 3);
									DevSts[conno].Pit.wEnable := txbf[txsz];
									Inc(txsz);
              	end;
								SetCommand(CMD_PIT, devcs, devaddr or 1, 0);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
						$0100:
							begin
              	//出力
              	if ((data xor DevSts[conno].Pit.byOutput) and 7)<>0 then
                begin
									SetCommand(CMD_PIT, devcs, devaddr or 0, 0);
									txbf[txsz] := DevSts[conno].Pit.wEnable and $8f;
                  for ch := 0 to 2 do
                  begin
	                  if ((data and (1 shl ch))<>0) and ((DevSts[conno].Pit.byVolume and (3 shl (ch*2)))<>0) then
  	                	Inc(txbf[txsz], $10 shl ch);
                  end;
									DevSts[conno].Pit.wEnable := txbf[txsz];
									Inc(txsz);
              	  DevSts[conno].Pit.byOutput := data;
	              end;
							end;
						$0101:
							begin
              	//音量
              	if ((data xor DevSts[conno].Pit.byVolume) and $3f)<>0 then
 	              begin
									SetCommand(CMD_PIT, devcs, devaddr or 0, 0);
									txbf[txsz] := DevSts[conno].Pit.wEnable and $8f;
       	          for ch := 0 to 2 do
         	        begin
          	        if ((DevSts[conno].Pit.byOutput and (1 shl ch))<>0) and ((data and (3 shl (ch*2)))<>0) then
 	          	      	Inc(txbf[txsz], $10 shl ch);
               	  end;
									DevSts[conno].Pit.wEnable := txbf[txsz];
									Inc(txsz);
	                //※音量レジスタにも書き込むようにする
									DevSts[conno].Pit.byVolume := data;
   	            end;
              end;
					end;
				end;
			DEVICE_PSG, DEVICE_EPSG, DEVICE_SSG, DEVICE_SSGL, DEVICE_OPN, DEVICE_OPNA, DEVICE_OPNA_RAM,
      DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM, DEVICE_OPN2, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
				begin
        	//
					len := DevSts[conno].Opna.nAdpcmLen;
          case info of
          	DEVICE_OPNA_RAM:
		          begin
								if (len>=OPNA_ADPCM_LEN) or ((len>0) and (DevSts[conno].Opna.dwOldAddr=$0108) and (addr<>$0108)) then
								begin
									DevSts[conno].Opna.nAdpcmLen := 0;
									if len=OPNA_ADPCM_LEN then
										SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr, $0108);
									for i := 0 to len-1 do
									begin
										if len<>OPNA_ADPCM_LEN then
											SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, DevSts[conno].Opna.dwOldAddr);
										txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
										Inc(txsz);
									end;
								end;
		          end;
          	DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
	   		      begin
								if (len=OPNA_ADPCM_LEN) or ((len>0) and ((DevSts[conno].Opna.dwOldAddr or $0100)=$0308) and ((addr or $0100)<>$0308)) then
                begin
									DevSts[conno].Opna.nAdpcmLen := 0;
                 	if len=OPNA_ADPCM_LEN then
										SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr, $0308);
									for i := 0 to len-1 do
									begin
	                 	if len<>OPNA_ADPCM_LEN then
											SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, DevSts[conno].Opna.dwOldAddr);
										txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
										Inc(txsz);
									end;
								end;
   			      end;
          end;
					DevSts[conno].Opna.dwOldAddr := addr;
          //
					case addr of
						$0000..$000d:
							begin
								SetCommand(CMD_PSG, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
						$002a:
							begin
								SetCommand(CMD_OPN2_PCM, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
						$0108:
							begin
              	case info of
									DEVICE_OPNA, DEVICE_OPNA_RAM:
		                begin
    		            	//opna, adpcm
  	    		        	if True and (info=DEVICE_OPNA_RAM) then
	          		      begin
                				//まとめて
												DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
												Inc(DevSts[conno].Opna.nAdpcmLen);
    		        	    end else
        		  	      begin
        	  		      	//ひとつづつ
												SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, addr);
												txbf[txsz] := data and $ff;
												Inc(txsz);
	  		              end;
                    end;
                  else
                  	begin
                    	//その他
											SetCommand(CMD_OPN, devcs, devaddr, addr);
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                end;
							end;
            $0200..$0207, $0209..$02ff, $0300..$0307, $0309..$03ff:
            	begin
              	case info of
			          	DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
	                  begin
			              	//opnb, ctl/ram/vol
											SetCommand(CMD_OPNB_CTL, devcs, devaddr, addr);
											txbf[txsz] := data and $ff;
											Inc(txsz);
  	                end;
                end;
              end;
            $0208, $0308:
            	begin
              	case info of
			          	DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
	                  begin
			               	//opnb, ram
 	    			        	if True then
            			    begin
               					//まとめて
												DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
												Inc(DevSts[conno].Opna.nAdpcmLen);
           				    end else
			                begin
      			 	        	//ひとつづつ
												SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, addr);
												txbf[txsz] := data and $ff;
												Inc(txsz);
      			          end;
  	                end;
                end;
          		end;
						else
							begin
								SetCommand(CMD_OPN, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
					end;
				end;
			DEVICE_DCSG:
				begin
					case addr of
						$0000:
							begin
								SetCommand(CMD_DCSG, devcs, devaddr or 1, 0);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
					end;
				end;
			DEVICE_DCSG_GG, DEVICE_DCSG_NGP:
				begin
					case addr of
						$0000:
							begin
								if (data and $90)=$90 then
								begin
									//減衰
									ch := (data shr 5) and 3;
									DevSts[conno].DcsgGg.Attenuation[ch] := data and $ff;
									case (DevSts[conno].DcsgGg.byMask shr ch) and $11 of
										$00:
											SetCommand(CMD_DCSG, devcs, devaddr or 3, 0);	//消音
										$01:
											SetCommand(CMD_DCSG, devcs, devaddr or 1, 0);	//右のみ
										$10:
											SetCommand(CMD_DCSG, devcs, devaddr or 2, 0);	//左のみ
										else
											SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);	//左右
									end;
								end else
								begin
									//その他
									SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);
								end;
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
						$0001:
							begin
								for ch := 0 to 3 do
								begin
									if ((DevSts[conno].DcsgGg.byMask xor data) and ($11 shl ch))<>$00 then
									begin
										//減衰
										case (data shr ch) and $11 of
											$00:
												SetCommand(CMD_DCSG, devcs, devaddr or 3, 0);	//消音
											$01:
												SetCommand(CMD_DCSG, devcs, devaddr or 1, 0);	//右のみ
											$10:
												SetCommand(CMD_DCSG, devcs, devaddr or 2, 0);	//左のみ
											else
												SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);	//左右
										end;
										txbf[txsz] := DevSts[conno].DcsgGg.Attenuation[ch];
										Inc(txsz);
									end;
								end;
								DevSts[conno].DcsgGg.byMask := data and $ff;
							end;
						$0002:
            	if info=DEVICE_DCSG_NGP then
							begin
              	//右
								case data and $f0 of
									$80, $a0, $c0:
                  	begin
                    	//周波数
                    end;
                  $e0:
                  	begin
                    	//ノイズ制御
											SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);			//左右
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                  $90, $b0, $d0, $f0:
                  	begin
                    	//減衰
											SetCommand(CMD_DCSG, devcs, devaddr or (4+3), 0);	//右のみ
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                  else
                  	begin
                    	//周波数
                    end;
                end;
              end;
						$0003:
            	if info=DEVICE_DCSG_NGP then
							begin
              	//左
								case data and $f0 of
									$80, $a0, $c0:
                  	begin
                    	//周波数
											SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);			//左右
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                  $e0:
                  	begin
                    	//ノイズ制御
                    end;
                  $90, $b0, $d0, $f0:
                  	begin
                    	//減衰
											SetCommand(CMD_DCSG, devcs, devaddr or (4+1), 0);	//左のみ
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                  else
                  	begin
                    	//周波数
											SetCommand(CMD_DCSG, devcs, devaddr or 0, 0);			//左右
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                end;
              end;
					end;
				end;
      DEVICE_SAA1099:
      	begin
					SetCommand(CMD_SAA1099, devcs, devaddr or 1, 0);
					txbf[txsz] := addr and $ff;
					Inc(txsz);
					SetCommand(CMD_SAA1099, devcs, devaddr or 0, 0);
					txbf[txsz] := data and $ff;
					Inc(txsz);
        end;
			DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
				begin
					SetCommand(CMD_OPM, devcs, devaddr, addr);
					txbf[txsz] := data and $ff;
					Inc(txsz);
				end;
			DEVICE_OPLL, DEVICE_OPLLP, DEVICE_VRC7:
				begin
					SetCommand(CMD_OPLL, devcs, devaddr, addr);
					txbf[txsz] := data and $ff;
					Inc(txsz);
				end;
			DEVICE_OPL, DEVICE_MSXAUDIO_RAM, DEVICE_OPL2:
				begin
					case addr of
          	$000f:
            	begin
								SetCommand(CMD_MSXAUDIO_ADPCM, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
          	else
            	begin
								SetCommand(CMD_OPL, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
          end;
				end;
			DEVICE_OPL3, DEVICE_OPL3L, DEVICE_DS1, DEVICE_SOLO1, DEVICE_OPL3NL_OPL, DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
				begin
        	//
					len := DevSts[conno].Opna.nAdpcmLen;
          case info of
          	DEVICE_OPL4_RAM:
	   		      begin
								if (len=OPNA_ADPCM_LEN) or ((len>0) and ((DevSts[conno].Opna.dwOldAddr or $0100)=$0508) and ((addr or $0100)<>$0508)) then
                begin
									DevSts[conno].Opna.nAdpcmLen := 0;
                 	if len=OPNA_ADPCM_LEN then
										SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr, $0508);
									for i := 0 to len-1 do
									begin
	                 	if len<>OPNA_ADPCM_LEN then
											SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, DevSts[conno].Opna.dwOldAddr);
										txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
										Inc(txsz);
									end;
								end;
   			      end;
          end;
					DevSts[conno].Opna.dwOldAddr := addr;
					//
        	case addr of
          	$0000..$01ff:
            	begin
              	//opl3, fm
								SetCommand(CMD_OPL3, devcs, devaddr, addr);
                if ((info=DEVICE_OPL3NL_OPL) and (MainForm.ThreadCri[nNo].bOpl3nlOplChannelLr=True)) and
                	((addr and $00c0)=$00c0) then
                begin
                	//ch/fb/cnt
									txbf[txsz] := ((data and $20) shr 1) or ((data and $10) shl 1) or (data and $cf);
                end else
                begin
                	//その他
									txbf[txsz] := data and $ff;
                end;
								Inc(txsz);
              end;
            $0200..$0267, $0280..$02ff:
            	begin
              	//opl4, wavetable
								SetCommand(CMD_OPL4_WAVETABLE, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
            $0268..$027f:
            	begin
              	//opl4, wavetable
                if MainForm.ThreadCri[nNo].bOpl4PcmChannelChg=True then
                begin
                	//output channel selection
                	data := data xor (1 shl 4);
                end;
								SetCommand(CMD_OPL4_WAVETABLE, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
	          $0300..$03ff:
  	        	begin
    	        	//opl4-ml, gmp
      	      end;
            $0400..$0407, $0409..$04ff, $0500..$0507, $0509..$05ff,
            $0600..$0607, $0609..$06ff, $0700..$0707, $0709..$07ff:
            	begin
			          case info of
      			    	DEVICE_OPL4_RAM:
	   		    			  begin
			              	//opl4+ram, ctl/ram
											SetCommand(CMD_OPL4_CTL, devcs, devaddr, addr);
											txbf[txsz] := data and $ff;
											Inc(txsz);
                    end;
                end;
              end;
            $0408, $0508,
            $0608, $0708:
            	begin
			          case info of
      			    	DEVICE_OPL4_RAM:
	   		    			  begin
			               	//opl4+ram, ram
 	    			        	if True then
            			    begin
               					//まとめて
												DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
												Inc(DevSts[conno].Opna.nAdpcmLen);
           				    end else
			                begin
      			 	        	//ひとつづつ
												SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, addr);
												txbf[txsz] := data and $ff;
												Inc(txsz);
            			    end;
                    end;
                end;
          		end;
          end;
				end;
	    DEVICE_OPL4ML_MPU:
    		begin
         	//mpu acknowledge port
					SetCommand(CMD_OPL4ML_MPUACK_R, devcs, devaddr or 0, 0);
					txbf[txsz] := $fe;
					Inc(txsz);
          //status register port
					SetCommand(CMD_OPL4ML_MPUACK_R, devcs, devaddr or 1, 0);
					txbf[txsz] := $bf;
					Inc(txsz);
          //
					SetCommand(CMD_OPL4ML_MPUDATA, devcs, devaddr or (addr and 3), 0);
					txbf[txsz] := data and $ff;
					Inc(txsz);
	      end;
			DEVICE_OPX_RAM:
      	begin
        	//
					len := DevSts[conno].Opna.nAdpcmLen;
					if (len=OPNA_ADPCM_LEN) or ((len>0) and (DevSts[conno].Opna.dwOldAddr=$0908) and (addr<>$0908)) then
          begin
						DevSts[conno].Opna.nAdpcmLen := 0;
           	if len=OPNA_ADPCM_LEN then
							SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr, $0908);
						for i := 0 to len-1 do
						begin
             	if len<>OPNA_ADPCM_LEN then
								SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, DevSts[conno].Opna.dwOldAddr);
							txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
							Inc(txsz);
						end;
					end;
					DevSts[conno].Opna.dwOldAddr := addr;
					//
	      	case addr of
  	      	$0000..$07ff:
            	begin
              	//opx
								SetCommand(CMD_OPX, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0900..$0907, $0909..$091f:
            	begin
              	//opx, ctl/ram
								SetCommand(CMD_OPX_CTL, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0908:
            	begin
               	//opx, ram
			        	if True then
       			    begin
         					//まとめて
									DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
									Inc(DevSts[conno].Opna.nAdpcmLen);
     				    end else
                begin
 			 	        	//ひとつづつ
									SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, addr);
									txbf[txsz] := data and $ff;
									Inc(txsz);
       			    end;
              end;
          end;
        end;
			DEVICE_SCC, DEVICE_052539:
				begin
					case addr of
          	$5000..$57ff, $7000..$77ff, $9000..$97ff, $b000..$b7ff,
            $9800..$98ff, $b800..$b8ff, $bffe..$bfff:
							begin
								sccad := (addr shr 8) and $ff;
								if sccad<>DevSts[conno].Scc.wHighAddr then
								begin
									//上位アドレスが変わった
									DevSts[conno].Scc.wHighAddr := sccad;
									SetCommand(CMD_SCC_HIGHADDR, devcs, devaddr or 2, 0);
									txbf[txsz] := sccad;
									Inc(txsz);
								end;
								SetCommand(CMD_SCC, devcs, devaddr, addr and $ff);
								txbf[txsz] := data and $ff;
								Inc(txsz);
							end;
					end;
				end;
			DEVICE_GA20:
      	begin
        	//
					len := DevSts[conno].Opna.nAdpcmLen;
					if (len=OPNA_ADPCM_LEN) or ((len>0) and (DevSts[conno].Opna.dwOldAddr=$0108) and (addr<>$0108)) then
          begin
						DevSts[conno].Opna.nAdpcmLen := 0;
           	if len=OPNA_ADPCM_LEN then
							SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr or (1 shl 5), $0108);
						for i := 0 to len-1 do
						begin
             	if len<>OPNA_ADPCM_LEN then
								SetCommand(CMD_OPNA_ADPCM, devcs, devaddr or (1 shl 5), DevSts[conno].Opna.dwOldAddr);
							txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
							Inc(txsz);
						end;
					end;
					DevSts[conno].Opna.dwOldAddr := addr;
					//
	      	case addr of
  	      	$0000..$001f:
            	begin
              	//ga20
								SetCommand(CMD_GA20, devcs, devaddr or (0 shl 5) or (addr and $1f), 0);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0100..$0107, $0109..$011f:
            	begin
              	//ga20, ctl/ram
								SetCommand(CMD_GA20_CTL, devcs, devaddr or (1 shl 5), addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0108:
            	begin
               	//ga20, ram
			        	if True then
       			    begin
         					//まとめて
									DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
									Inc(DevSts[conno].Opna.nAdpcmLen);
     				    end else
                begin
 			 	        	//ひとつづつ
									SetCommand(CMD_OPNA_ADPCM, devcs, devaddr or (1 shl 5), addr);
									txbf[txsz] := data and $ff;
									Inc(txsz);
       			    end;
              end;
          end;
        end;
			DEVICE_PCMD8:
      	begin
        	//
					len := DevSts[conno].Opna.nAdpcmLen;
					if (len=OPNA_ADPCM_LEN) or ((len>0) and (DevSts[conno].Opna.dwOldAddr=$0108) and (addr<>$0108)) then
          begin
						DevSts[conno].Opna.nAdpcmLen := 0;
           	if len=OPNA_ADPCM_LEN then
							SetCommand(CMD_OPNA_ADPCM_2, devcs, devaddr, $0108);
						for i := 0 to len-1 do
						begin
             	if len<>OPNA_ADPCM_LEN then
								SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, DevSts[conno].Opna.dwOldAddr);
							txbf[txsz] := DevSts[conno].Opna.AdpcmBuf[i];
							Inc(txsz);
						end;
					end;
					DevSts[conno].Opna.dwOldAddr := addr;
					//
	      	case addr of
  	      	$0000..$00ff:
            	begin
              	//pcmd8
								SetCommand(CMD_PCMD8, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0100..$0107, $0109..$011f:
            	begin
              	//pcmd8, ctl/ram
								SetCommand(CMD_PCMD8_CTL, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
              end;
  	      	$0108:
            	begin
               	//pcmd8, ram
			        	if True then
       			    begin
         					//まとめて
									DevSts[conno].Opna.AdpcmBuf[DevSts[conno].Opna.nAdpcmLen] := data and $ff;
									Inc(DevSts[conno].Opna.nAdpcmLen);
     				    end else
                begin
 			 	        	//ひとつづつ
									SetCommand(CMD_OPNA_ADPCM, devcs, devaddr, addr);
									txbf[txsz] := data and $ff;
									Inc(txsz);
       			    end;
              end;
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
	      	case addr of
  	      	$0000..$01ff:
            	begin
              	//spu, 16ビット書き込み
                i := $0200 or ((addr shr 1) and $ff);
								SetCommand(CMD_SPU_CTL, devcs, devaddr, i);
								txbf[txsz] := data and $ff;
								Inc(txsz);
								SetCommand(CMD_SPU_HIGHDATA, devcs, devaddr, i);
								txbf[txsz] := (data shr 8) and $ff;
								Inc(txsz);
              end;
  	      	$0300..$031f:
            	begin
              	//spu, ctl
								SetCommand(CMD_SPU_CTL, devcs, devaddr, addr);
								txbf[txsz] := data and $ff;
								Inc(txsz);
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
    //
		DevSts[conno].Reg[addr and $ffff] := data;
  end;

  //
  Result := True;
end;

procedure TOutputThread.KeyOff(state: Integer);
	var
  	i, j, n: Integer;
  	conno, info: Integer;
    w: Word;
	var
    ezusbr: LongBool;
    ezusbrxsz: Cardinal;
    ezusbbtc: TBULK_TRANSFER_CONTROL;
  var
		picr, picrxsz: DWORD;
  var
  	ftdir: FT_STATUS;
begin
	//
	for conno := 0 to CONNECT_DEVMAX-1 do
	begin
		//
		if DeviceForm.CnDevice[conno].nThread<>nNo then
			Continue;
		//
		info := DeviceForm.CnDevice[conno].nInfo;
		case info of
			DEVICE_USART:
				begin
					if state=0 then
					begin
						//キーオフ
					end else
					begin
						//レジスタ初期化
					end;
				end;
			DEVICE_PIT:
				begin
					if state=0 then
					begin
						WriteDev(conno, $0100, $00);
						WriteDev(conno, $0101, $3f);
					end else
					begin
						w := Round(DeviceForm.CnDevice[conno].xClock/1000);	//※固定値で良い気がする
						for i := 0 to 2 do
						begin
							WriteDev(conno, $0003, $36 or (i shl 6));
							WriteDev(conno, $0000+i, w and $ff);
							WriteDev(conno, $0000+i, (w shr 8) and $ff);
						end;
					end;
				end;
			DEVICE_PSG, DEVICE_EPSG, DEVICE_SSG, DEVICE_SSGL:
				begin
					if state=0 then
					begin
						if (info=DEVICE_EPSG) and ((DevSts[conno].Reg[$000d] and $e0)=$a0) then
						begin
							//expanded capability mode-bank a
							WriteDev(conno, $000d, $a0);
						end else
						begin
							WriteDev(conno, $000d, $00);
						end;
						for i := 0 to 2 do
							WriteDev(conno, $0008+i, $00);
						WriteDev(conno, $0007, $c0 or $3f);
					end else
					begin
						//
						for i := 0 to 6 do
							WriteDev(conno, $0000+i, $00);
						WriteDev(conno, $000b, $00);
						WriteDev(conno, $000c, $00);
						WriteDev(conno, $000e, $00);
						WriteDev(conno, $000f, $00);
						if (info=DEVICE_EPSG) and ((DevSts[conno].Reg[$000d] and $e0)=$a0) then
						begin
							//expanded capability mode-bank b
							WriteDev(conno, $000d, $b0);
							for i := 0 to 5 do
								WriteDev(conno, $0000+i, $00);
							for i := 0 to 2 do
								WriteDev(conno, $0006+i, $04);
							WriteDev(conno, $0009, $ff);
							WriteDev(conno, $000a, $00);
							//ay38910a-compatibility mode
							WriteDev(conno, $000d, $00);
						end;
					end;
				end;
			DEVICE_DCSG, DEVICE_DCSG_GG, DEVICE_DCSG_NGP:
				begin
					if state=0 then
					begin
						WriteDev(conno, $0000, $9f);
						WriteDev(conno, $0000, $bf);
						WriteDev(conno, $0000, $df);
						WriteDev(conno, $0000, $ff);
					end else
					begin
						//
						case info of
							DEVICE_DCSG_GG, DEVICE_DCSG_NGP:
								WriteDev(conno, $0001, $ff);
						end;
						//
						WriteDev(conno, $0000, $80);
						WriteDev(conno, $0000, $00);
						WriteDev(conno, $0000, $a0);
						WriteDev(conno, $0000, $00);
						WriteDev(conno, $0000, $c0);
						WriteDev(conno, $0000, $00);
						WriteDev(conno, $0000, $e0);
						WriteDev(conno, $0000, $00);
					end;
				end;
			DEVICE_SAA1099:
				begin
					if state=0 then
					begin
						WriteDev(conno, $0014, $00);
						WriteDev(conno, $0015, $00);
						for i := 0 to 5 do
							WriteDev(conno, $0000+i, $00);
						//
						WriteDev(conno, $001c, $02);
					end else
					begin
						//
						for i := 0 to 5 do
							WriteDev(conno, $0008+i, $00);
						for i := 0 to 2 do
							WriteDev(conno, $0010+i, $00);
						//
						WriteDev(conno, $0016, $00);
						WriteDev(conno, $0018, $00);
						WriteDev(conno, $0019, $00);
						if False then
						begin
							WriteDev(conno, $0006, $00);
							WriteDev(conno, $0007, $00);
							WriteDev(conno, $000e, $00);
							WriteDev(conno, $000f, $00);
							WriteDev(conno, $0013, $00);
							WriteDev(conno, $0017, $00);
							WriteDev(conno, $001a, $00);
							WriteDev(conno, $001b, $00);
							WriteDev(conno, $001d, $00);
							WriteDev(conno, $001e, $00);
							WriteDev(conno, $001f, $00);
						end;
						//
						WriteDev(conno, $001c, $01);
					end;
				end;
			DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
				begin
					if state=0 then
					begin
						for i := 0 to 31 do
							WriteDev(conno, $00e0+i, $ff);
						for i := 0 to 7 do
							WriteDev(conno, $0008, i);
					end else
					begin
						//
						WriteDev(conno, $000f, $00);
						WriteDev(conno, $0010, $00);
						WriteDev(conno, $0011, $00);
						WriteDev(conno, $0012, $00);
						WriteDev(conno, $001b, $00);
						//
						WriteDev(conno, $0014, $00);
						for i := 0 to 31 do
						begin
							WriteDev(conno, $0020+i, $00);
							WriteDev(conno, $0040+i, $00);
							WriteDev(conno, $0060+i, $00);
							WriteDev(conno, $0080+i, $00);
							WriteDev(conno, $00a0+i, $00);
							WriteDev(conno, $00c0+i, $00);
							WriteDev(conno, $00e0+i, $00);
						end;
						//
						case info of
							DEVICE_OPM:
								begin
									//
									WriteDev(conno, $0018, $00);
									WriteDev(conno, $0019, $80);
									WriteDev(conno, $0019, $00);
									//TESTレジスタ
									WriteDev(conno, $0001, $00);
								end;
							DEVICE_OPP:
								begin
									//
									WriteDev(conno, $0018, $00);
									WriteDev(conno, $0019, $80);
									WriteDev(conno, $0019, $00);
									//
									for i := $0000 to $0007 do
										WriteDev(conno, i, $00);
									//
									WriteDev(conno, $0009, $00);
								end;
							DEVICE_OPZ:
								begin
									//
									WriteDev(conno, $000a, $04);
									WriteDev(conno, $0015, $01);
									WriteDev(conno, $0016, $00);
									WriteDev(conno, $0017, $80);
									WriteDev(conno, $0017, $00);
									WriteDev(conno, $0018, $00);
									WriteDev(conno, $0019, $80);
									WriteDev(conno, $0019, $00);
									WriteDev(conno, $001c, $00);
									WriteDev(conno, $001e, $00);
									//
									for i := $0000 to $0007 do
										WriteDev(conno, i, $00);
									for i := $0040 to $005f do
										WriteDev(conno, i, $80);
									for i := $00c0 to $00df do
										WriteDev(conno, i, $20);
									//
									WriteDev(conno, $0009, $00);
									WriteDev(conno, $000a, $00);
									WriteDev(conno, $0015, $00);
									//
									if False then
									begin
										//※テスト用
										WriteDev(conno, $0000, $10);
										WriteDev(conno, $0001, $10);	//音が異常ならopm、正常ならopp/opz
										WriteDev(conno, $0002, $10);
										WriteDev(conno, $0003, $10);
										WriteDev(conno, $0004, $10);
										WriteDev(conno, $0005, $10);
										WriteDev(conno, $0006, $10);
										WriteDev(conno, $0007, $10);
										//
										WriteDev(conno, $001b, $0c);
										for i := $0030 to $0037 do
											WriteDev(conno, i, $01);
										for i := $0038 to $003f do
											WriteDev(conno, i, $84);
										for i := $0040 to $005f do
											WriteDev(conno, i, $b0);
										for i := $0060 to $007f do
											WriteDev(conno, i, $80);
										for i := $0080 to $009f do
											WriteDev(conno, i, $20);
									end;
								end;
						end;
					end;
				end;
			DEVICE_OPN:
				begin
					if state=0 then
					begin
						WriteDev(conno, $000d, $00);
						for i := 0 to 2 do
							WriteDev(conno, $0008+i, $00);
						WriteDev(conno, $0007, $c0 or $3f);
						//
						for i := 0 to 2 do
						begin
							for j := 0 to 3 do
								WriteDev(conno, $0080+j*4+i, $ff);
							WriteDev(conno, $0028, i);
						end;
					end else
					begin
						//
						for i := 0 to 6 do
							WriteDev(conno, $0000+i, $00);
						WriteDev(conno, $000b, $00);
						WriteDev(conno, $000c, $00);
						WriteDev(conno, $000e, $00);
						WriteDev(conno, $000f, $00);
						//
						WriteDev(conno, $0024, $00);
						WriteDev(conno, $0025, $00);
						WriteDev(conno, $0026, $00);
						WriteDev(conno, $0027, $00);
						//
						for i := 0 to 2 do
						begin
							for j := 0 to 3 do
							begin
								WriteDev(conno, $0030+j*4+i, $00);
								WriteDev(conno, $0040+j*4+i, $00);
								WriteDev(conno, $0050+j*4+i, $00);
								WriteDev(conno, $0060+j*4+i, $00);
								WriteDev(conno, $0070+j*4+i, $00);
								WriteDev(conno, $0080+j*4+i, $00);
								WriteDev(conno, $0090+j*4+i, $00);
							end;
							WriteDev(conno, $00a4+i, $00);
							WriteDev(conno, $00a0+i, $00);
							WriteDev(conno, $00a8+i, $00);
							WriteDev(conno, $00ac+i, $00);
							WriteDev(conno, $00b0+i, $00);
						end;
						//TESTレジスタ
						WriteDev(conno, $0021, $00);
					end;
				end;
			DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM,
			DEVICE_OPN2, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
				begin
					//
					case info of
						DEVICE_OPNA, DEVICE_OPNA_RAM:
							begin
								//モード切替
								WriteDev(conno, $0029, $80);
							end;
						DEVICE_OPN2:
							begin
								//モード切替
								WriteDev(conno, $0020, $02);
							end;
						DEVICE_OPN3L:
							begin
								//モード切替
								WriteDev(conno, $0020, $02);
								WriteDev(conno, $0029, $80);
							end;
						DEVICE_OPL3NL_OPN:
							begin
								//初期化
								WriteDev(conno, $00f7, $00);
								if False then
								begin
									WriteDev(conno, $0020, $82);
									WriteDev(conno, CMD_WAIT, 0);
									WriteDev(conno, $0020, $02);
								end;
								//モード切替
								WriteDev(conno, $0020, $02);
								WriteDev(conno, $0029, $80);
							end
					end;
					//
					if state=0 then
					begin
						//
						WriteDev(conno, $000d, $00);
						for i := 0 to 2 do
							WriteDev(conno, $0008+i, $00);
						WriteDev(conno, $0007, $c0 or $3f);
						//
						for i := 0 to 2 do
						begin
							for j := 0 to 3 do
								WriteDev(conno, $0080+j*4+i, $ff);
							WriteDev(conno, $0028, i);
							for j := 0 to 3 do
								WriteDev(conno, $0180+j*4+i, $ff);
							WriteDev(conno, $0028, 4+i);
						end;
						//
						case info of
							DEVICE_OPNA, DEVICE_OPNA_RAM:
								begin
									//rhythm
									WriteDev(conno, $0010, $80 or $3f);
									WriteDev(conno, $0011, $00);
									//adpcm
									WriteDev(conno, $0100, $01);
									WriteDev(conno, $010b, $00);
								end;
							DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
								begin
									//rhythm
									WriteDev(conno, $0010, $80 or $3f);
									WriteDev(conno, $0011, $00);
								end;
							DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
								begin
									//adpcm-a
									WriteDev(conno, $0100, $80 or $3f);
									WriteDev(conno, $0101, $00);
									//adpcm-b
									WriteDev(conno, $0010, $01);
									WriteDev(conno, $001b, $00);
								end;
							DEVICE_OPN2:
								begin
									//pcm
									WriteDev(conno, $002a, $80);
								end;
						end;
					end else
					begin
						//
						for i := 0 to 6 do
							WriteDev(conno, $0000+i, $00);
						WriteDev(conno, $000b, $00);
						WriteDev(conno, $000c, $00);
						WriteDev(conno, $000e, $00);
						WriteDev(conno, $000f, $00);
						//
						WriteDev(conno, $0022, $00);
						WriteDev(conno, $0024, $00);
						WriteDev(conno, $0025, $00);
						WriteDev(conno, $0026, $00);
						WriteDev(conno, $0027, $00);
						//
						for i := 0 to 2 do
						begin
							for j := 0 to 3 do
							begin
								WriteDev(conno, $0030+j*4+i, $00);
								WriteDev(conno, $0040+j*4+i, $00);
								WriteDev(conno, $0050+j*4+i, $00);
								WriteDev(conno, $0060+j*4+i, $00);
								WriteDev(conno, $0070+j*4+i, $00);
								WriteDev(conno, $0080+j*4+i, $00);
								WriteDev(conno, $0090+j*4+i, $00);
							end;
							WriteDev(conno, $00a4+i, $00);
							WriteDev(conno, $00a0+i, $00);
							WriteDev(conno, $00a8+i, $00);
							WriteDev(conno, $00ac+i, $00);
							WriteDev(conno, $00b0+i, $00);
							WriteDev(conno, $00b4+i, $c0);
							for j := 0 to 3 do
							begin
								WriteDev(conno, $0130+j*4+i, $00);
								WriteDev(conno, $0140+j*4+i, $00);
								WriteDev(conno, $0150+j*4+i, $00);
								WriteDev(conno, $0160+j*4+i, $00);
								WriteDev(conno, $0170+j*4+i, $00);
								WriteDev(conno, $0180+j*4+i, $00);
								WriteDev(conno, $0190+j*4+i, $00);
							end;
							WriteDev(conno, $01a4+i, $00);
							WriteDev(conno, $01a0+i, $00);
							WriteDev(conno, $01a8+i, $00);
							WriteDev(conno, $01ac+i, $00);
							WriteDev(conno, $01b0+i, $00);
							WriteDev(conno, $01b4+i, $c0);
						end;
						//
						case info of
							DEVICE_OPNA, DEVICE_OPNA_RAM:
								begin
									//rhythm
									WriteDev(conno, $0010, $00);
									for i := 0 to 5 do
										WriteDev(conno, $0018+i, $00);
									//adpcm
									WriteDev(conno, $0100, $21);
									WriteDev(conno, $0101, $02);	//8bit
									WriteDev(conno, $0102, $00);
									WriteDev(conno, $0103, $00);
									WriteDev(conno, $0104, $ff);
									WriteDev(conno, $0105, $ff);
									WriteDev(conno, $0106, $00);
									WriteDev(conno, $0107, $00);
//								WriteDev(conno, $0108, $00);	//adpcm data
									WriteDev(conno, $0109, $00);
									WriteDev(conno, $010a, $00);
									WriteDev(conno, $010b, $00);
									WriteDev(conno, $010c, $ff);	//limit address(l)
									WriteDev(conno, $010d, $ff);	//limit address(h)
									WriteDev(conno, $010e, $00);	//dac data
									WriteDev(conno, $0100, $60);
									//
									WriteDev(conno, $0110, $17);
									WriteDev(conno, $0110, $80);
								end;
							DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
								begin
									//rhythm
									WriteDev(conno, $0010, $00);
									for i := 0 to 5 do
										WriteDev(conno, $0018+i, $00);
								end;
							DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
								begin
									//adpcm-a
									WriteDev(conno, $0100, $00);
									for i := 0 to 5 do
									begin
										WriteDev(conno, $0108+i, $00);
										WriteDev(conno, $0110+i, $00);
										WriteDev(conno, $0118+i, $00);
										WriteDev(conno, $0120+i, $00);
										WriteDev(conno, $0128+i, $00);
									end;
									//adpcm-b
									WriteDev(conno, $0010, $01);
									WriteDev(conno, $0011, $00);
									WriteDev(conno, $0012, $00);
									WriteDev(conno, $0013, $00);
									WriteDev(conno, $0014, $00);
									WriteDev(conno, $0015, $00);
									WriteDev(conno, $0019, $00);
									WriteDev(conno, $001a, $00);
									WriteDev(conno, $001b, $00);
									WriteDev(conno, $0010, $00);
									//
									WriteDev(conno, $001c, $80 or $3f);
								end;
							DEVICE_OPN2:
								begin
									//pcm
									WriteDev(conno, $002a, $80);
									WriteDev(conno, $002b, $00);
								end;
						end;
						//TESTレジスタ
						WriteDev(conno, $0021, $00);					//opna, opnb, opn2, opn3-l
						case info of
							DEVICE_OPNA, DEVICE_OPNA_RAM:
								begin
									WriteDev(conno, $0012, $00);		//opna, ____, ____, opn3-l
								end;
							DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
								begin
									WriteDev(conno, $0102, $00);		//____, opnb, ____, ______
								end;
							DEVICE_OPN2:
								begin
									WriteDev(conno, $002c, $00);		//____, ____, opn2, opn3-l
								end;
							DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
								begin
									WriteDev(conno, $0012, $00);		//opna, ____, ____, opn3-l
									WriteDev(conno, $002a, $00);		//____, ____, ____, opn3-l
									WriteDev(conno, $002b, $00);		//____, ____, ____, opn3-l
									WriteDev(conno, $002c, $00);		//____, ____, opn2, opn3-l
								end;
						end;
						//
						case info of
							DEVICE_OPNA_RAM:
								begin
									//FM音量
									n := MainForm.ThreadCri[nNo].nOpnaBalance and $ff;
//								WriteDev(conno, $030b, n);
								end;
							DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
								begin
									//FM音量
									n := MainForm.ThreadCri[nNo].nOpnbBalance and $ff;
									WriteDev(conno, $030b, n);
								end;
						end;
					end;
				end;
			DEVICE_OPLL, DEVICE_OPLLP, DEVICE_VRC7:
				begin
					if state=0 then
					begin
						if (DevSts[conno].Reg[$000e] and $20)<>0 then
						begin
							//rhythm sound mode
							for i := 0 to 5 do
								WriteDev(conno, $0030+i, $0f);
							WriteDev(conno, $0036, $0f);
							WriteDev(conno, $0037, $ff);
							WriteDev(conno, $0038, $ff);
							//
							WriteDev(conno, $000e, $20);
						end else
						begin
							//
							for i := 0 to 8 do
								WriteDev(conno, $0030+i, $0f);
						end;
						//
						WriteDev(conno, $0006, $ff);
						WriteDev(conno, $0007, $ff);
						for i := 0 to 8 do
							WriteDev(conno, $0020+i, $00);
					end else
					begin
						//
						WriteDev(conno, $000e, $00);
						for i := 0 to 7 do
							WriteDev(conno, $0000+i, $00);
						for i := 0 to 8 do
						begin
							WriteDev(conno, $0010+i, $00);
							WriteDev(conno, $0020+i, $00);
							WriteDev(conno, $0030+i, $00);
						end;
						//TESTレジスタ
						WriteDev(conno, $000f, $02);
						WriteDev(conno, $000f, $00);
						if False then
						begin
							//※テスト用
							i := $00;
							i := i or (1 shl 4);
							i := i or (1 shl 5);
							i := i or (1 shl 6);
							i := i or (1 shl 7);
							WriteDev(conno, $000f, i);
						end;
					end;
				end;
			DEVICE_OPL, DEVICE_MSXAUDIO_RAM, DEVICE_OPL2:
				begin
					if state=0 then
					begin
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0040+w, $3f);
							WriteDev(conno, $0043+w, $3f);
						end;
						if (DevSts[conno].Reg[$00bd] and $20)<>0 then
						begin
							//rhythm sound mode
							WriteDev(conno, $00bd, $20);
						end;
						//
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0080+w, $ff);
							WriteDev(conno, $0083+w, $ff);
							WriteDev(conno, $00b0+i, $00);
						end;
						//
						case info of
							DEVICE_MSXAUDIO_RAM:
								begin
									//adpcm
									WriteDev(conno, $0007, $01);	//opna, $0100
									WriteDev(conno, $0012, $00);	//opna, $010b
								end;
						end;
					end else
					begin
            //
						WriteDev(conno, $00bd, $00);
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0020+w, $00);
							WriteDev(conno, $0023+w, $00);
							WriteDev(conno, $0040+w, $00);
							WriteDev(conno, $0043+w, $00);
							WriteDev(conno, $0060+w, $00);
							WriteDev(conno, $0063+w, $00);
							WriteDev(conno, $0080+w, $00);
							WriteDev(conno, $0083+w, $00);
							WriteDev(conno, $00a0+i, $00);
							WriteDev(conno, $00b0+i, $00);
							WriteDev(conno, $00c0+i, $00);
						end;
						//
						case info of
							DEVICE_OPL2:
              	begin
									WriteDev(conno, $0001, $20);
									for i := 0 to 8 do
                  begin
										w := Opl2Channel2Addr[i];
										WriteDev(conno, $00e0+w, $00);
										WriteDev(conno, $00e3+w, $00);
                  end;
                end;
						end;
            //
						WriteDev(conno, $0002, $00);
						WriteDev(conno, $0003, $00);
						case info of
							DEVICE_MSXAUDIO_RAM:
								begin
									//
									WriteDev(conno, $0006, $ff);
									WriteDev(conno, $0019, $00);
									WriteDev(conno, $0018, $0f);
									//adpcm
									WriteDev(conno, $0007, $21);	//opna, $0100
									WriteDev(conno, $0008, $00);	//opna, $0101, 一部異なる
									WriteDev(conno, $0009, $00);	//opna, $0102
									WriteDev(conno, $000a, $00);	//opna, $0103
									WriteDev(conno, $000b, $ff);	//opna, $0104
									WriteDev(conno, $000c, $ff);	//opna, $0105
									WriteDev(conno, $000d, $00);	//opna, $0106
									WriteDev(conno, $000e, $00);	//opna, $0107
//								WriteDev(conno, $000f, $00);	//opna, $0108, adpcm data
									WriteDev(conno, $0010, $00);	//opna, $0109
									WriteDev(conno, $0011, $00);	//opna, $010a
									WriteDev(conno, $0012, $00);	//opna, $010b
									WriteDev(conno, $0017, $01);	//opna, $010e, dac data, 異なる
									WriteDev(conno, $0016, $00);	//opna, $010e, dac data, 異なる
									WriteDev(conno, $0015, $80);	//opna, $010e, dac data, 異なる
									WriteDev(conno, $0007, $60);	//opna, $0100
									//
									WriteDev(conno, $0004, $70);	//opna, $0110, 一部異なる
									WriteDev(conno, $0004, $80);	//opna, $0110, 一部異なる
								end;
							else
								begin
									WriteDev(conno, $0008, $00);
									//
									WriteDev(conno, $0004, $60);
									WriteDev(conno, $0004, $80);
								end;
						end;
						//TESTレジスタ
						WriteDev(conno, $0001, $08);
						WriteDev(conno, $0001, $00);
					end;
				end;
			DEVICE_OPL3, DEVICE_OPL3L, DEVICE_DS1, DEVICE_SOLO1, DEVICE_OPL3NL_OPL, DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
				begin
					//
					case info of
						DEVICE_OPL3, DEVICE_DS1, DEVICE_SOLO1:
							begin
								//モード切替
								WriteDev(conno, $0105, $01);	//new=1
							end;
						DEVICE_OPL3L:
							begin
								//初期化
								WriteDev(conno, $0108, $00);
								//モード切替
								WriteDev(conno, $0105, $05);	//new=1, new3=1
							end;
						DEVICE_OPL3NL_OPL:
							begin
								//初期化
								WriteDev(conno, $00f7, $00);
								if False then
								begin
									WriteDev(conno, $0108, $04);
									WriteDev(conno, CMD_WAIT, 0);
								end;
								WriteDev(conno, $0108, $00);
								//モード切替
								WriteDev(conno, $0105, $05);	//new=1, new3=1
							end;
						DEVICE_OPL4_RAM:
							begin
								//モード切替
								WriteDev(conno, $0105, $03);	//new=1, new2=1
							end;
						DEVICE_OPL4ML_OPL:
							begin
								//モード切替
								WriteDev(conno, $0105, $07);	//new=1, new2=1, new3=1
							end;
					end;
					//
					if state=0 then
					begin
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0040+w, $3f);
							WriteDev(conno, $0140+w, $3f);
							WriteDev(conno, $0043+w, $3f);
							WriteDev(conno, $0143+w, $3f);
						end;
						if (DevSts[conno].Reg[$00bd] and $20)<>0 then
						begin
							//rhythm sound mode
							WriteDev(conno, $00bd, $20);
						end;
						//
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0080+w, $ff);
							WriteDev(conno, $0180+w, $ff);
							WriteDev(conno, $0083+w, $ff);
							WriteDev(conno, $0183+w, $ff);
							WriteDev(conno, $00b0+i, $00);
							WriteDev(conno, $01b0+i, $00);
						end;
						//
						case info of
							DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
								begin
									//wavetable
									for i := 0 to 23 do
									begin
										WriteDev(conno, $0250+i, $ff);
										WriteDev(conno, $02c8+i, $ff);
										WriteDev(conno, $0268+i, $28);
									end;
								end;
						end;
					end else
					begin
						//
						WriteDev(conno, $00bd, $00);
						for i := 0 to 8 do
						begin
							w := Opl2Channel2Addr[i];
							WriteDev(conno, $0020+w, $00);
							WriteDev(conno, $0120+w, $00);
							WriteDev(conno, $0023+w, $00);
							WriteDev(conno, $0123+w, $00);
							WriteDev(conno, $0040+w, $00);
							WriteDev(conno, $0140+w, $00);
							WriteDev(conno, $0043+w, $00);
							WriteDev(conno, $0143+w, $00);
							WriteDev(conno, $0060+w, $00);
							WriteDev(conno, $0160+w, $00);
							WriteDev(conno, $0063+w, $00);
							WriteDev(conno, $0163+w, $00);
							WriteDev(conno, $0080+w, $00);
							WriteDev(conno, $0180+w, $00);
							WriteDev(conno, $0083+w, $00);
							WriteDev(conno, $0183+w, $00);
							WriteDev(conno, $00a0+i, $00);
							WriteDev(conno, $01a0+i, $00);
							WriteDev(conno, $00b0+i, $00);
							WriteDev(conno, $01b0+i, $00);
							WriteDev(conno, $00c0+i, $00);
							WriteDev(conno, $01c0+i, $00);
							WriteDev(conno, $00e0+w, $00);
							WriteDev(conno, $01e0+w, $00);
							WriteDev(conno, $00e3+w, $00);
							WriteDev(conno, $01e3+w, $00);
						end;
						WriteDev(conno, $0104, $00);
						//
						case info of
							DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
								begin
									//wavetable
//								WriteDev(conno, $0202, $01);	//mpu, ymf704:ok, ymf704c:ng
									WriteDev(conno, $0202, $00);	//mpu, ymf704:ok?（※テストしていない）, ymf704c:ok
									WriteDev(conno, $0203, $00);
									WriteDev(conno, $0204, $00);
									WriteDev(conno, $0205, $00);
									for i := 0 to 23 do
									begin
										WriteDev(conno, $0220+i, $00);
										WriteDev(conno, $0208+i, $00);
										WriteDev(conno, $0238+i, $00);
										WriteDev(conno, $0250+i, $00);
										WriteDev(conno, $0268+i, $00);
										WriteDev(conno, $0280+i, $00);
										WriteDev(conno, $0298+i, $00);
										WriteDev(conno, $02b0+i, $00);
										WriteDev(conno, $02c8+i, $00);
										WriteDev(conno, $02e0+i, $00);
									end;
									//mix, fm
									n := MainForm.ThreadCri[nNo].nOpl4FmMix and 7;
									WriteDev(conno, $02f8, (n shl 3) or n);
									//mix, pcm
									n := MainForm.ThreadCri[nNo].nOpl4PcmMix and 7;
									WriteDev(conno, $02f9, (n shl 3) or n);
								end;
						end;
						//
						WriteDev(conno, $0002, $00);
						WriteDev(conno, $0003, $00);
						WriteDev(conno, $0008, $00);
						WriteDev(conno, $0004, $60);
						WriteDev(conno, $0004, $80);
						//TESTレジスタ
						WriteDev(conno, $0001, $00);
						WriteDev(conno, $0101, $00);
						case info of
							DEVICE_OPL3L, DEVICE_OPL3NL_OPL:
								begin
									WriteDev(conno, $0000, $00);
									WriteDev(conno, $0100, $00);
								end;
							DEVICE_OPL4_RAM:
								begin
									WriteDev(conno, $0000, $00);
									WriteDev(conno, $0100, $00);
									WriteDev(conno, $0200, $00);
									WriteDev(conno, $0201, $00);
								end;
							DEVICE_OPL4ML_OPL:
								begin
									WriteDev(conno, $0000, $00);
									WriteDev(conno, $0100, $00);
									WriteDev(conno, $0200, $00);
									WriteDev(conno, $0201, $00);
									WriteDev(conno, $02fa, $00);	//atc=0
									WriteDev(conno, $02fb, $00);
								end;
						end;
						//
						case info of
							DEVICE_OPL3, DEVICE_OPL3L, DEVICE_DS1, DEVICE_OPL3NL_OPL:
								begin
									WriteDev(conno, $0105, $00);
								end;
							DEVICE_SOLO1:
								begin
									WriteDev(conno, $0105, $00);
									if MainForm.ThreadCri[nNo].bSolo1VolumeChg=True then
									begin
										//FM Volume Register
										n := MainForm.ThreadCri[nNo].nSolo1Volume and $f;
										WriteDev(conno, $0236, (n shl 4) or n);
									end;
								end;
							DEVICE_OPL4_RAM:
								begin
									WriteDev(conno, $0105, $02);	//new2=1
									//ミュート解除
									n := $00;
									//デジタル出力
									if MainForm.ThreadCri[nNo].bOpl4RamSpdif=True then
										n := n or (1 shl 4);
									//DO選択
									n := n or ((MainForm.ThreadCri[nNo].nOpl4RamDo and 3) shl 5);
									WriteDev(conno, $0401, n);
								end;
							DEVICE_OPL4ML_OPL:
								begin
									WriteDev(conno, $0105, $02);	//new2=1
								end;
						end;
					end;
				end;
			DEVICE_OPL4ML_MPU:
				begin
					if state=0 then
					begin
						//リセット
						WriteDev(conno, $0001, $ff);
						WriteDev(conno, CMD_WAIT, 0);
						//UARTモード
						WriteDev(conno, $0001, $3f);
						//
						for i := 0 to 15 do
						begin
							WriteDev(conno, $0000, $b0+i);
							WriteDev(conno, $0000, $78);
							WriteDev(conno, $0000, $00);
						end;
					end else
					begin
					end;
				end;
			DEVICE_OPX_RAM:
				begin
					if state=0 then
          begin
						for i := 0 to 3 do
						begin
							for j := 0 to 11 do
							begin
								w := i*$0100+OpxGroup2Addr[j];
								WriteDev(conno, w+$d0, $ff);
								WriteDev(conno, w+$e0, $ff);
							end;
						end;
						//
						for i := 0 to 3 do
						begin
							for j := 0 to 11 do
							begin
								w := i*$0100+OpxGroup2Addr[j];
								WriteDev(conno, w+$40, $7f);
								WriteDev(conno, w+$60, $1f);
								WriteDev(conno, w+$70, $1f);
								WriteDev(conno, w+$80, $0f);
								WriteDev(conno, w+$00, DevSts[conno].Reg[w+$00] and $fe);
							end;
						end;
					end else
					begin
						//
						for i := 0 to 3 do
						begin
							for j := 0 to 11 do
							begin
								w := i*$0100+OpxGroup2Addr[j];
								for n := $0 to $8 do
									WriteDev(conno, w+(n shl 4), $00);
								WriteDev(conno, w+($a shl 4), $00);
								WriteDev(conno, w+($9 shl 4), $00);
								for n := $b to $e do
									WriteDev(conno, w+(n shl 4), $00);
							end;
						end;
						for j := 0 to 11 do
						begin
							w := $0400+OpxGroup2Addr[j];
							for n := $0 to $9 do
								WriteDev(conno, w+(n shl 4), $00);
							w := $0600+OpxGroup2Addr[j];
							WriteDev(conno, w+$00, $00);
						end;
						WriteDev(conno, $0610, $00);
						WriteDev(conno, $0611, $00);
						WriteDev(conno, $0612, $00);
						WriteDev(conno, $0613, $30);
						if False then
						begin
							WriteDev(conno, $0614, $00);
							WriteDev(conno, $0615, $00);
							WriteDev(conno, $0616, $00);
						end;
						WriteDev(conno, $0620, $00);
						WriteDev(conno, $0621, $00);
						WriteDev(conno, $0622, $00);
						//ミュート解除
						n := $00;
						//デジタル出力
						if MainForm.ThreadCri[nNo].bOpxRamSpdif=True then
							n := n or (1 shl 4);
						//18ビット出力
						if MainForm.ThreadCri[nNo].bOpxRam18bit=True then
							n := n or (1 shl 2);
						//DO/EXT選択
						n := n or ((MainForm.ThreadCri[nNo].nOpxRamDoExt and 3) shl 5);
						WriteDev(conno, $0901, n);
					end;
				end;
			DEVICE_SCC:
				begin
					//
					WriteDev(conno, $5000, $00);
					WriteDev(conno, $7000, $00);
					WriteDev(conno, $9000, $3f);
					WriteDev(conno, $b000, $00);
					WriteDev(conno, $98e0, $00);
					//
					if state=0 then
					begin
						for i := 0 to 4 do
							WriteDev(conno, $988a+i, $00);
						WriteDev(conno, $988f, $00);
					end else
					begin
						for i := 0 to 4 do
						begin
							WriteDev(conno, $9880+i*2, $00);
							WriteDev(conno, $9881+i*2, $00);
						end;
						for i := 0 to 4*32-1 do
							WriteDev(conno, $9800+i, $00);
					end;
				end;
			DEVICE_052539:
				begin
					//
					if MainForm.ThreadCri[nNo].b052539CompatibleMode=True then
					begin
						//SCC互換
						WriteDev(conno, $bffe, $00);
						WriteDev(conno, $5000, $00);
						WriteDev(conno, $7000, $00);
						WriteDev(conno, $9000, $3f);
						WriteDev(conno, $b000, $00);
						WriteDev(conno, $98c0, $00);
						//
						if state=0 then
						begin
							for i := 0 to 4 do
								WriteDev(conno, $988a+i, $00);
							WriteDev(conno, $988f, $00);
						end else
						begin
							for i := 0 to 4 do
							begin
								WriteDev(conno, $9880+i*2, $00);
								WriteDev(conno, $9881+i*2, $00);
							end;
							for i := 0 to 4*32-1 do
								WriteDev(conno, $9800+i, $00);
						end;
					end else
					begin
						//052539固有
						WriteDev(conno, $bffe, $20);
						WriteDev(conno, $5000, $00);
						WriteDev(conno, $7000, $00);
						WriteDev(conno, $9000, $00);
						WriteDev(conno, $b000, $80);
						WriteDev(conno, $b8c0, $00);
						//
						if state=0 then
						begin
							for i := 0 to 4 do
								WriteDev(conno, $b8aa+i, $00);
							WriteDev(conno, $b8af, $00);
						end else
						begin
							for i := 0 to 4 do
							begin
								WriteDev(conno, $b8a0+i*2, $00);
								WriteDev(conno, $b8a1+i*2, $00);
							end;
							for i := 0 to 5*32-1 do
								WriteDev(conno, $b800+i, $00);
						end;
					end;
				end;
			DEVICE_GA20:
				begin
					if state=0 then
					begin
						for i := 0 to 3 do
						begin
							WriteDev(conno, $0005+i*8, $00);
							WriteDev(conno, $0006+i*8, $00);
						end;
            //
						WriteDev(conno, $010e, $80);
						WriteDev(conno, $0101, $03);
						WriteDev(conno, $0103, $00);
						WriteDev(conno, $0102, $00);
						WriteDev(conno, $0108, $80);
						for i := 1 to 15 do
								WriteDev(conno, $0108, $00);
						WriteDev(conno, $0101, $01);
            //
						for i := 0 to 3 do
						begin
							WriteDev(conno, $0000+i*8, $00);
							WriteDev(conno, $0001+i*8, $00);
							WriteDev(conno, $0002+i*8, $00);
							WriteDev(conno, $0003+i*8, $00);
							WriteDev(conno, $0004+i*8, $fe);
							WriteDev(conno, $0006+i*8, $02);
						end;
					end else
					begin
						//
						for i := 0 to 3 do
						begin
							WriteDev(conno, $0000+i*8, $00);
							WriteDev(conno, $0001+i*8, $00);
							WriteDev(conno, $0002+i*8, $00);
							WriteDev(conno, $0003+i*8, $00);
							WriteDev(conno, $0004+i*8, $00);
							WriteDev(conno, $0005+i*8, $00);
							WriteDev(conno, $0006+i*8, $00);
							WriteDev(conno, $0007+i*8, $00);
						end;
					end;
				end;
			DEVICE_PCMD8:
				begin
					if state=0 then
					begin
						for i := 0 to 7 do
						begin
							WriteDev(conno, $0002+i*4, $00);
							w := $0001+i*4;
							WriteDev(conno, w, DevSts[conno].Reg[w] and $7f);
						end;
					end else
					begin
						//
						for i := $0000 to $007f do
							WriteDev(conno, i, $00);
						WriteDev(conno, $0080, $88);
						WriteDev(conno, $0081, $01);
						if False then
						begin
							WriteDev(conno, $0084, $00);
							WriteDev(conno, $0085, $00);
							WriteDev(conno, $0086, $00);
						end;
						WriteDev(conno, $00fe, $00);
						WriteDev(conno, $00ff, $d0);
						//ミュート解除
						n := $00;
						//デジタル出力
						if MainForm.ThreadCri[nNo].bPcmd8Spdif=True then
							n := n or (1 shl 4);
						//DO/EO選択
						n := n or ((MainForm.ThreadCri[nNo].nPcmd8DoEo and 1) shl 5);
						WriteDev(conno, $0101, n);
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
					//
					WriteDev(conno, $0303, $00);	//a9=0
					WriteDev(conno, $0302, $00);	//上位/下位の選択ビットクリア
					//
					WriteDev(conno, $01aa, $8000);
					WriteDev(conno, $01ac, $0004);
					if state=0 then
					begin
						for i := 0 to 23 do
						begin
							WriteDev(conno, $0008+i*$10, $0000);
							WriteDev(conno, $000a+i*$10, $0000);
						end;
						WriteDev(conno, $018c, $ffff);
						WriteDev(conno, $018e, $00ff);
					end else
					begin
						//
						WriteDev(conno, $01aa, $8010);
						WriteDev(conno, $01aa, $8000);
            //
						WriteDev(conno, $0180, $3fff);	//main-l
						WriteDev(conno, $0182, $3fff);	//main-r
						WriteDev(conno, $0184, $0000);
						WriteDev(conno, $0186, $0000);
						WriteDev(conno, $0188, $0000);
						WriteDev(conno, $018a, $0000);
						WriteDev(conno, $0190, $0000);
						WriteDev(conno, $0192, $0000);
						WriteDev(conno, $0194, $0000);
						WriteDev(conno, $0196, $0000);
						WriteDev(conno, $0198, $0000);
						WriteDev(conno, $019a, $0000);
						WriteDev(conno, $01b0, $3fff);	//extina-l
						WriteDev(conno, $01b2, $3fff);	//extina-r
						WriteDev(conno, $01b4, $3fff);	//extinb-l
						WriteDev(conno, $01b6, $3fff);	//extinb-r
						//
						WriteDev(conno, $01a4, $0000);
						WriteDev(conno, $01a6, $0000);
						//
						WriteDev(conno, $01a2, $0000);
						for i := 0 to 29 do
							WriteDev(conno, $1c0+i*2, $0000);
						WriteDev(conno, $01fc, $8000);
						WriteDev(conno, $01fe, $8000);
						//
						for i := 0 to 23 do
						begin
							WriteDev(conno, $0000+i*$10, $0000);
							WriteDev(conno, $0002+i*$10, $0000);
							WriteDev(conno, $0004+i*$10, $0000);
							WriteDev(conno, $0006+i*$10, $0000);
							WriteDev(conno, $0008+i*$10, $0000);
							WriteDev(conno, $000a+i*$10, $0000);
						end;
						WriteDev(conno, $01aa, $c000);
						//ミュート解除
						n := $00;
						//デジタル出力
						if MainForm.ThreadCri[nNo].bSpuSpdif=True then
							n := n or (1 shl 4);
						//外部入力
						if MainForm.ThreadCri[nNo].bSpuExt=True then
							n := n or (1 shl 7);
						WriteDev(conno, $0301, n);
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

	//
	case nIF of
		IF_EZUSB:
			begin
				if txsz>0 then
				begin
					if hndEzusb<>INVALID_HANDLE_VALUE then
					begin
						ezusbbtc.pipeNum := PIPE_DATACMD;
						ezusbr := DeviceIoControl(hndEzusb, IOCTL_EZUSB_BULK_WRITE,
							@ezusbbtc, SizeOf(ezusbbtc), @txbf, txsz, ezusbrxsz, nil);
						if ezusbr=False then
							Exit;
					end;
					txsz := 0;
				end;
			end;
		IF_PIC:
			begin
				if txsz>2 then
				begin
					if hndPic<>INVALID_HANDLE_VALUE then
					begin
						txbf[0] := (txsz-2) and $ff;
						txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						picr := MainForm.MPUSBWrite(hndPic, @txbf, txsz, @picrxsz, INFINITE);
						if picr=MPUSB_FAIL then
							Exit;
					end;
					txsz := 2;
				end;
			end;
		IF_FTDI:
			begin
				if txsz>2 then
				begin
					if hndFtdi<>nil then
					begin
						txbf[0] := (txsz-2) and $ff;
						txbf[1] := (PIPE_DATACMD shl 6) or (((txsz-2) shr 8) and $3f);
						ftdir := MainForm.FT_Write(hndFtdi, @txbf, txsz, @picrxsz);
						if ftdir<>FT_OK then
							Exit;
					end;
					txsz := 2;
				end;
			end;
	end;
end;

end.

