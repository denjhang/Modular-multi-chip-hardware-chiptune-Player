unit input;

interface

uses
	Classes, Windows, SysUtils, Math, IniFiles, Unit1, Unit2;

type
	TInputThread = class(TThread)
	private
		{ Private 宣言 }
		FileFmt: Integer;
		FileBuf: PFileBuf;
		dwDataSize: DWORD;
		slLog: TStringList;
		//
		nTimerInfo1, nTimerInfo2: Int64;
		dwLoopPtr: DWORD;
		nLoopLim: Integer;
		xRatio: Extended;
		bStartSkip: Boolean;
		//
		CmdToReqno: array[0..$ff] of Integer;
		TypeToReqno: array[0..$ff] of Integer;
		//
		OpllInst: array[0..2] of array[0..18] of array[0..7] of Byte;
		//
		nOpnTl2PcmLen, nOpnTl2Pcm0: Integer;
		OpnTl2Pcm: array[0..128-1] of Integer;
		nSsgVol2PcmLen, nSsgVol2Pcm0: Integer;
		SsgVol2Pcm: array[0..16-1] of Integer;
		//
		byRhythmEnb: Byte;
		wStartAddr, wEndAddr: array[0..5] of Word;
		dwRhythmRomSize: DWORD;
		RhythmRom: array[0..16*1024-1] of Byte;
    //
		function MainS98: Integer;
		function MainSpuOld: Integer;
		function MainVgm: Integer;
		function MaskReg(conno: Integer; info: DWORD; addr: DWORD; data: PWORD): Boolean;
		procedure WriteBuf(thn, conno: Integer; addr: DWORD; data: Word);
	protected
		{ protected 宣言 }
    procedure Execute; override;
  published
    { published 宣言 }
		constructor Create(fmt: Integer; fheader, pfb: Pointer; pfs: DWORD; r: Extended; llim: Integer);
  end;

implementation

uses output;

{注意:
  異なるスレッドが所有する VCL または CLX のメソッド/関数/
  プロパティを別のスレッドの中から扱う場合、排他処理の問題が
  発生します。

  メインスレッドの所有するオブジェクトに対しては Synchronize
  メソッドを使う事ができます。他のオブジェクトを参照するため
  のメソッドをスレッドクラスに追加し、Synchronize メソッドの
  引数として渡します。

  たとえば、UpdateCaption メソッドを以下のように定義し、

    procedure TInputThread.UpdateCaption;
    begin
      Form1.Caption := 'TInputThread スレッドから書き換えました';
    end;

  Execute メソッドの中で Synchronize メソッドに渡すことでメイ
  ンスレッドが所有する Form1 の Caption プロパティを安全に変
  更できます。

      Synchronize(UpdateCaption);
}

{ TInputThread }

constructor TInputThread.Create(fmt: Integer; fheader, pfb: Pointer; pfs: DWORD; r: Extended; llim: Integer);
	var
  	s98h: PS98Header;
    spuh: PSpuHeader;
    vgmh: PVgmHeader;
  var
  	i, j, cmd{, reqno}: Integer;
begin
  //
  FileFmt := fmt;
  FileBuf := pfb;
  dwDataSize := pfs;

	//
 	nTimerInfo1 := 1;
 	nTimerInfo2 := 1;
  dwLoopPtr := 0;
  nLoopLim := 0;
  xRatio := r;
  bStartSkip := True;
  case fmt of
  	FMT_S98:
    	begin
      	s98h := fheader;
			 	nTimerInfo1 := s98h.dwTimerInfo1;
			 	nTimerInfo2 := s98h.dwTimerInfo2;
			  //
			  if (s98h.dwLoopOffset=0) or (s98h.dwLoopOffset<s98h.dwDataOffset) then
			  begin
			  end else
			  begin
				  dwLoopPtr := s98h.dwLoopOffset-s98h.dwDataOffset;
				  nLoopLim := llim;
			  end;
      end;
    FMT_SPUOLD:
    	begin
      	spuh := fheader;
			 	nTimerInfo1 := 1;
			 	nTimerInfo2 := spuh^.Info[0];
    	end;
    FMT_VGM:
    	begin
      	vgmh := fheader;
			 	nTimerInfo1 := 1;
			 	nTimerInfo2 := 44100;
        //
			  if (vgmh.dwLoopOffset=0) or (vgmh.dwLoopOffset<vgmh.dwVgmDataOffset) then
			  begin
			  end else
			  begin
				  dwLoopPtr := vgmh.dwLoopOffset-vgmh.dwVgmDataOffset;
				  nLoopLim := llim;
			  end;
    	end;
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
	for i := 0 to (SizeOf(TypeToReqno) div SizeOf(TypeToReqno[0]))-1 do
  	TypeToReqno[i] := -1;
  case fmt of
  	FMT_VGM:
    	begin
      	//sega_pcm
      	TypeToReqno[$80] := CmdToReqno[$c0];
        //ym2608
      	TypeToReqno[$81] := CmdToReqno[$56];
        //ym2610
      	TypeToReqno[$82] := CmdToReqno[$58];
      	TypeToReqno[$83] := CmdToReqno[$58];
        //ymf278b rom
      	TypeToReqno[$84] := CmdToReqno[$d0];
        //ymf271
      	TypeToReqno[$85] := CmdToReqno[$d1];
        //ymz280b
      	TypeToReqno[$86] := CmdToReqno[$5d];
        //ymf278b ram
        TypeToReqno[$87] := CmdToReqno[$d0];
        //y8950
        TypeToReqno[$88] := CmdToReqno[$5c];
        //rf5c68
      	TypeToReqno[$c0] := CmdToReqno[$b0];
        //rf5c164
      	TypeToReqno[$c1] := CmdToReqno[$b1];
      end;
  end;

  //
	inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
end;

const
  TLSTEP_OPM = 0.752575;
  TLSTEP_OPN = 0.7525;
	OpnaAdpcm: array[0..15] of Byte = (
		$06, $34, $33, $43, $43, $33, $52, $34,
    $24, $23, $34, $33, $43, $43, $34, $80
  );

var
  DevSts: array[0..CONNECT_DEVMAX-1] of TDeviceStatus;

procedure TInputThread.Execute;
	var
  	i, j, k, l, res: Integer;
    regaddr2, regdata2: Word;
	var
  	path: String;
  	fs: TFileStream;
		nTh, readsz, conno: Integer;
  var
	  ini: TIniFile;
    s: String;
  	c, n, v: Integer;
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
	nOpnTl2PcmLen := 0;
  nSsgVol2PcmLen := 0;
	if MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True then
  begin
		case MainForm.ThreadCri[nTh].nOpnaOpn2PcmType of
    	0:
      	begin
		    	//fm
					nOpnTl2PcmLen := SizeOf(OpnTl2Pcm) div SizeOf(OpnTl2Pcm[0]);
		      n := -1;
		      for i := 0 to nOpnTl2PcmLen-1 do
		      begin
      			OpnTl2Pcm[i] := Round(4084/Power(10, (TLSTEP_OPN*i)/20));
		        if (OpnTl2Pcm[i]<1) and (n<0) then
    		    	n := 1+i;
		      end;
    		  if n>=0 then
	    			nOpnTl2PcmLen := n;
          nOpnTl2Pcm0 := Round((OpnTl2Pcm[0]*3)/2);	//3キャリア合計した分の中間
        end;
      1:
      	begin
		    	//ssg
					nSsgVol2PcmLen := SizeOf(SsgVol2Pcm) div SizeOf(SsgVol2Pcm[0]);
		      for i := 0 to nSsgVol2PcmLen-1 do
          begin
          	j := i;
          	if i>2 then
            	Inc(j);
      			SsgVol2Pcm[i] := 4*Round(Power(10, (0.752*4*j)/20));
          end;
          nSsgVol2Pcm0 := Round((SsgVol2Pcm[nSsgVol2PcmLen-1]*3)/2);	//3ch合計した分の中間
        end;
    end;
  end;

	//
  byRhythmEnb := $00;
  dwRhythmRomSize := 0;
	if MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=True then
  begin
	 	//
		FillChar(RhythmRom, SizeOf(RhythmRom), $80);
		for i := 0 to 5 do
		begin
			//
	    wStartAddr[i] := 0;
		  wEndAddr[i] := 0;
      path := MainForm.ThreadCri[nTh].OpnbOpnaRhythm[i];
      if FileExists(path)=True then
      begin
	    	//
			  fs := nil;
				try
	 				fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
					readsz := fs.Read(RhythmRom[dwRhythmRomSize], SizeOf(RhythmRom)-dwRhythmRomSize);
			    if readsz>0 then
		  		begin
    				readsz := (readsz+255) shr 8;
						wStartAddr[i] := dwRhythmRomSize shr 8;
						wEndAddr[i] := wStartAddr[i] + (readsz-1);
						Inc(dwRhythmRomSize, readsz shl 8);
	  		    byRhythmEnb := byRhythmEnb or (1 shl i);
  	  		end;
			  finally
				  fs.Free;
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
			DEVICE_OPNA, DEVICE_OPNA_RAM:
      	begin
			    case DeviceForm.ReqDevice[i].nInfo of
	  		  	DEVICE_OPN2:
      	     	begin
								if MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True then
							  begin
									case MainForm.ThreadCri[nTh].nOpnaOpn2PcmType of
                  	2:
                    	begin
                      	//adpcm
												WriteBuf(nTh, conno, $0100, $80);
												WriteBuf(nTh, conno, $0101, $c2);
    			              if True then
      			            begin
													WriteBuf(nTh, conno, $0109, $00);
													WriteBuf(nTh, conno, $010a, $80);
            	      		end else
		              	    begin
													WriteBuf(nTh, conno, $0109, $ff);
													WriteBuf(nTh, conno, $010a, $ff);
	          		        end;
												WriteBuf(nTh, conno, $010b, $80);
												for j := 0 to (SizeOf(OpnaAdpcm) div SizeOf(OpnaAdpcm[0]))-1 do
													WriteBuf(nTh, conno, $0108, OpnaAdpcm[j]);
                      end;
                    3:
                    	begin
                      	//pcm
												WriteBuf(nTh, conno, $0110, $1b);
												WriteBuf(nTh, conno, $0110, $80);
												WriteBuf(nTh, conno, $0100, $00);
												WriteBuf(nTh, conno, $0106, $00);
												WriteBuf(nTh, conno, $0107, $01);
												WriteBuf(nTh, conno, $0101, $cc);
												WriteBuf(nTh, conno, $010e, $00);
                      end;
                  end;
                end;
	            end;
  	      end;
        end;
			DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
      	begin
					case DeviceForm.ReqDevice[i].nInfo of
						DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
            	begin
								if (byRhythmEnb<>0) and (MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=True) then
							  begin
									//
									WriteBuf(nTh, conno, $0301, $01);
									for j := 0 to dwRhythmRomSize-1 do
								  begin
										//アドレス設定
										if (j and $ff)=0 then
								    begin
											WriteBuf(nTh, conno, $0302, (j shr 8) and $ff);
											WriteBuf(nTh, conno, $0303, (j shr 16) and $ff);
										end;
										//メモリ書き込み
										WriteBuf(nTh, conno, $0308, RhythmRom[j]);
									end;
									//
									for j := 0 to 5 do
								  begin
                  	if (byRhythmEnb and (1 shl j))<>0 then
                    begin
											WriteBuf(nTh, conno, $0110+j, wStartAddr[j] and $ff);
											WriteBuf(nTh, conno, $0118+j, (wStartAddr[j] shr 8) and $ff);
											WriteBuf(nTh, conno, $0120+j, wEndAddr[j] and $ff);
											WriteBuf(nTh, conno, $0128+j, (wEndAddr[j] shr 8) and $ff);
                  	end;
									end;
                end;
              end;
	        end;
        end;
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

  //
  case FileFmt of
  	FMT_S98:
	  	res := MainS98;
    FMT_SPUOLD:
    	res := MainSpuOld;
    FMT_VGM:
    	res := MainVgm;
    else
    	res := ST_THREAD_ERROR;
  end;
	//
	if Terminated=False then
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

  //
  if (MainForm.bDebug=True) and (slLog.Count>0) then
    slLog.SaveToFile('.\_psldebug_input.txt');
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

function TInputThread.MaskReg(conno: Integer; info: DWORD; addr: DWORD; data: PWORD): Boolean;
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

procedure TInputThread.WriteBuf(thn, conno: Integer; addr: DWORD; data: Word);
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
  while Terminated=False do
  begin
    //
    MainForm.ThreadCri[thn].Cri.Enter;
    len := MainForm.ThreadCri[thn].nLength;
		MainForm.ThreadCri[thn].Cri.Leave;
    if len<0 then
  		Break;
    if (len+1)<=MainForm.ThreadCri[thn].nBufSize then
    begin
			//
		  n := MainForm.ThreadCri[thn].nWritePtr;
		  MainForm.ThreadCri[thn].Buf[n].byNo := conno;
		  MainForm.ThreadCri[thn].Buf[n].dwAddr := addr;
		  MainForm.ThreadCri[thn].Buf[n].wData := data;
			DevSts[conno].Reg[addr and $ffff] := data;
      MainForm.ThreadCri[thn].nWritePtr := (n+1) mod MainForm.ThreadCri[thn].nBufSize;
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


function TInputThread.MainS98: Integer;
	var
  	i, ch, nTh: Integer;
    tm: Int64;
    rptr, offs: DWORD;
	var
    loopc, reqno, conno, cmd: Integer;
    fwrite_in, fwrite_out: Boolean;
    regaddr, regdata, regaddr2, regdata2: Word;
    sync, sync2, endtime: Int64;
  var
  	j, k, d, dmin, tlind0, tlind1, tlind2: Integer;
    rssg: Extended;
  var
    n, att, alg, slot, tl, oplltype: Integer;
    popllinst: PByteArray;
begin
	//
  rptr := 0;
  loopc := 0;
  sync := 0;
  sync2 := 0;
  endtime := 0;
	while Terminated=False do
  begin
		//
		if rptr>=dwDataSize then
		begin
			rptr := dwLoopPtr;
			Inc(loopc);
			if (rptr>=dwDataSize) or (loopc>=nLoopLim) then
				Break;
		end;

		//
		cmd := FileBuf[rptr];
		case cmd of
			$00..(S98_DEVMAX*2)-1:
				begin
					//書き込み
					if (rptr+3)>dwDataSize then
						Break;
					//
					tm := Min($fff, Round(sync*xRatio-sync2) div nTimerInfo2);
					if tm>0 then
					begin
						//
						Inc(sync2, tm*nTimerInfo2);
            if bStartSkip=False then
            begin
							for i := 0 to OUTPUT_THREADMAX-1 do
								WriteBuf(i, 0, CMD_SYNC, tm);
            end;
					end else
					begin
						//
            tm := sync2 div (nTimerInfo2*FREQ_SYNC);
            if (tm-endtime)>=10 then
            begin
            	endtime := tm;
							PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
            end;

						//
						fwrite_in := True;
            fwrite_out := fwrite_in;
						regaddr := ((cmd and 1) shl 8) or FileBuf[rptr+1];
						regdata := FileBuf[rptr+2];
						Inc(rptr, 3);

            //
            reqno := CmdToReqno[cmd];
            if (fwrite_in=True) and (reqno>=0) then
            begin
							conno := DeviceForm.ReqDevice[reqno].nNo;
							if conno>=0 then
							begin
								if DeviceForm.CnDevice[conno].nInfo<>DEVICE_NONE then
								begin
									//
	               	nTh := DeviceForm.CnDevice[conno].nThread;
									case DeviceForm.CnDevice[conno].nInfo of
										DEVICE_DCSG:
											begin
												if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_DCSG_GG then
												begin
													//DCSG_GG→DCSG
													case regaddr of
														$0000:
															begin
																if (regdata and $90)=$90 then
																begin
																	//減衰
																	ch := (regdata shr 5) and 3;
																	DevSts[conno].DcsgGg.Attenuation[ch] := regdata and $ff;
																	if ((DevSts[conno].DcsgGg.byMask shr ch) and $11)=$00 then
																	begin
																		//消音
																		regdata := regdata or $0f;
																	end;
																end;
															end;
														$0001:
															begin
																for ch := 0 to 3 do
																begin
																	if ((DevSts[conno].DcsgGg.byMask xor regdata) and ($11 shl ch))<>$00 then
																	begin
																		//減衰
																		regaddr2 := $0000;
																		regdata2 := DevSts[conno].DcsgGg.Attenuation[ch];
																		if ((regdata shr ch) and $11)=$00 then
																		begin
																			//消音
																			regdata2 := regdata2 or $0f;
																		end;
																		WriteBuf(nTh, conno, regaddr2, regdata2);
																	end;
																end;
																DevSts[conno].DcsgGg.byMask := regdata and $ff;
																fwrite_in := False;
															end;
													end;
												end;
											end;
										DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
											begin
				 								case DeviceForm.ReqDevice[reqno].nInfo of
				 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
														begin
															//OPNB/YM2610B→OPNA
															//  ADPCM-A/B削除
															case regaddr of
																$0010..$001f, $0100..$012f:
																	fwrite_in := False;
															end;
														end;
												end;
											end;
	 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
		 									begin
				 								case DeviceForm.ReqDevice[reqno].nInfo of
													DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
													 	begin
														 	//OPNA→OPNB/YM2610B
															//  リズム/ADPCM削除
															case regaddr of
																$0010..$001f:
                                	begin
                                  	if (byRhythmEnb=0) or (MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=False) then
                                    begin
																			//リズム削除
																			fwrite_in := False
                                    end;
                                  end;
																$0100..$0110:
                                	begin
																		//ADPCM削除
																		fwrite_in := False
                                  end;
															end;
														end;
				 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
														begin
														 	//OPNB/YM2610B→OPNB/YM2610B
                              //  RAM書き込みのアドレス変更
															case regaddr of
																$001e:
																	regaddr := $0301;
																$0016:
																	regaddr := $0302;
																$0017:
																	regaddr := $0303;
																$001f:
																	regaddr := $0308;
																$011f:
																	begin
															 			regaddr := $030b;
																		if True then
																			fwrite_in := False;
																	end;
															end;
														end;
												end;
											end;
									end;
									//
			            if fwrite_in=True then
			            begin
			          		case DeviceForm.ReqDevice[reqno].nInfo of
											DEVICE_OPNA_RAM:
			                	begin
                        	DevSts[conno].Opna.Reg[regaddr] := regdata;
                          case regaddr of
                          	$0101:
                            	begin
																case regdata and $03 of
																	0, 2:
																		begin
																			//1bit/8bit, dram
																		end;
																	else
																		begin
																			//rom→8bit, dram
																			regdata := (regdata and $fc) or $02;
																		end;
																end;
                              end;
                          end;
			                  end;
											DEVICE_MSXAUDIO_RAM:
			                	begin
                        	DevSts[conno].Msxaudio.Reg[regaddr] := regdata;
			                  	case regaddr of
                          	$0008:
                            	begin
																case regdata and $03 of
																	0, 2:
																		begin
																			//256K/64K, dram
																		end;
																	else
																		begin
																			//rom→256K, dram
																			regdata := regdata and $fc;
																		end;
																end;
                              end;
														$0009, $000b:
									          	begin
									   	          if (DevSts[conno].Msxaudio.Reg[$0008] and $01)<>0 then
									 	            begin
									   	          	//rom
									       	        regdata2 := (DevSts[conno].Msxaudio.Reg[regaddr+1] shl 3) or ((regdata shr 5) and 7);
												    			regdata2 := regdata2 and $ff;
																	WriteBuf(nTh, conno, regaddr, regdata2);
																	//
													    		regdata := regdata shl 3;
									         	      if regaddr=$000b then
									           	    	regdata := regdata or 7;
												    			regdata := regdata and $ff;
									              end;
									            end;
														$000a, $000c:
									          	begin
									   	          if (DevSts[conno].Msxaudio.Reg[$0008] and $01)<>0 then
									              begin
									              	//rom
													    		regdata := (regdata shl 3) or ((DevSts[conno].Msxaudio.Reg[regaddr-1] shr 5) and 7);
													    		regdata := regdata and $ff;
									              end;
									            end;
			                    end;
			                  end;
	                    DEVICE_OPL4_RAM, DEVICE_OPL4ML_OPL:
  	                  	begin
                        	//
													regaddr := ((cmd and 3) shl 8) or FileBuf[rptr+1];
    	                  end;
											DEVICE_SCC, DEVICE_052539:
												begin
    	                    //
													case regaddr of
														$0000..$00ff:
															begin
			          	            	//上位アドレス初期化
      			      	            if (DevSts[conno].Scc.wHighAddr and $ff00)<>0 then
            			  	          begin
                  			        	//まだ初期化されていない
                	      			  	if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_SCC then
			                            begin
			                            	//SCC
																    DevSts[conno].Scc.wHighAddr := $0098;
            			        	      end else
                  			          begin
                        			    	//052539
														  			if MainForm.ThreadCri[nTh].b052539CompatibleMode=True then
																	    DevSts[conno].Scc.wHighAddr := $0098
		  			                    	  else
																  	  DevSts[conno].Scc.wHighAddr := $00b8;
	                			          end;
  	                    			  end;
																//下位アドレス/データ書き込み
              	                //  +0 $00
																//  +1 下位アドレス
																//  +2 データ
																regaddr := (DevSts[conno].Scc.wHighAddr shl 8) or (regaddr and $ff);
															end;
														$0100..$01ff:
															begin
																//上位アドレス書き込み
                              	//  +0 $01
	                              //  +1 上位アドレス
  	                            //  +2 $00（未使用）
																DevSts[conno].Scc.wHighAddr := (regaddr shr 8) and $ff;
																fwrite_in := False;
															end;
													end;
												end;
			              end;
										//
										att := MainForm.ThreadCri[nTh].nOpnFmAttenuation;
										if att<>0 then
										begin
											case DeviceForm.ReqDevice[reqno].nInfo of
												DEVICE_OPN, DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
												DEVICE_YM2610B_RAM, DEVICE_OPN2, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
													begin
														case regaddr of
															$0040, $0041, $0042, $0140, $0141, $0142,	//slot1
															$0044, $0045, $0046, $0144, $0145, $0146,	//slot3
															$0048, $0049, $004a, $0148, $0149, $014a,	//slot2
															$004c, $004d, $004e, $014c, $014d, $014e:	//slot4
																begin
																	//fm, tl
																	ch := ((regaddr shr 8) and 1)*3 + (regaddr and 3);
																	slot := 1 + (((regaddr shr 1) and 2) or ((regaddr shr 3) and 1));
																	DevSts[conno].Opna.wTl[ch][slot-1] := regdata;
																	//
																	alg := -1;
																	case ch of
																		0:	//ch1
																			alg := DevSts[conno].Reg[$00b0] and $07;
																		1:	//ch2
																			alg := DevSts[conno].Reg[$00b1] and $07;
																		2:	//ch3
																			alg := DevSts[conno].Reg[$00b2] and $07;
																		3:	//ch4
																			alg := DevSts[conno].Reg[$01b0] and $07;
																		4:	//ch5
																			alg := DevSts[conno].Reg[$01b1] and $07;
																		5:	//ch6
																			alg := DevSts[conno].Reg[$01b2] and $07;
																	end;
																	//
																	n := 0;
																	case alg of
																		0..3:
																			if slot=4 then
																				n := 1;
																		4:
																			if (slot=2) or (slot=4) then
																				n := 1;
																		5..6:
																			if (slot=2) or (slot=3) or (slot=4) then
																				n := 1;
																		7:
																			n := 1;
																	end;
																	//
																	if n<>0 then
																	begin
																		tl := regdata and $7f;
																		Inc(tl, Round(att/TLSTEP_OPN));
																		if tl<0 then
																			tl := 0
																		else
																		if tl>$7f then
																			tl := $7f;
																		regdata := (regdata and $80) or tl;
																	end;
																end;
															$00b0..$00b2, $01b0..$01b2:
																begin
																	//fm, alg
																	ch := ((regaddr shr 8) and 1)*3 + (regaddr and 3);
																	if not ((MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True) and
																		(DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPN2) and
//																		(MainForm.ThreadCri[nTh].nOpnaOpn2PcmType=0) and
																		((DevSts[conno].Opn2.byDacSelect and $80)<>0) and ((1+ch)=6)) then
																	begin
																		for i := 0 to 3 do
																		begin
																			//
																			slot := 1 + (((i shl 1) and 2) or ((i shr 1) and 1));
																			n := 0;
																			case regdata and $07 of
																				0..3:
																					if slot=4 then
																						n := 1;
																				4:
																					if (slot=2) or (slot=4) then
																						n := 1;
																				5..6:
																					if (slot=2) or (slot=3) or (slot=4) then
																						n := 1;
																				7:
																					n := 1;
																			end;
																			//
																			regaddr2 := i*4;
																			if ch<3 then
																				Inc(regaddr2, $0040+ch)
																			else
																				Inc(regaddr2, $0140+ch-3);
																			regdata2 := DevSts[conno].Opna.wTl[ch][slot-1];
																			if (regdata2 and $ff00)<>0 then
																				regdata2 := $00;
																			if n<>0 then
																			begin
																				tl := regdata2 and $7f;
																				Inc(tl, Round(att/TLSTEP_OPN));
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$7f then
																					tl := $7f;
																				regdata2 := (regdata2 and $80) or tl;
																			end;
																			WriteBuf(nTh, conno, regaddr2, regdata2);
																		end;
																	end;
																end;
															else
																begin
																	case DeviceForm.ReqDevice[reqno].nInfo of
																		DEVICE_OPNA, DEVICE_OPNA_RAM,
																		DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																			begin
																				case regaddr of
																					$0011:
																						begin
																							//rhythm, rtl
																							tl := regdata and $3f;
																							Inc(tl, Round(-att/TLSTEP_OPN));
																							if tl<0 then
																								tl := 0
																							else
																							if tl>$3f then
																								tl := $3f;
																							regdata := (regdata and $c0) or tl;
																						end;
																					$0018..$001d:
																						begin
																							//rhythm, itl
																							//※rtlで処理、rtlに一度も書き込みがないときはうまく動作しない
																						end;
																					$010b:
																						begin
																							//adpcm, level control
																							tl := Round(Power(10, -att/20) * regdata);
																							if tl<0 then
																								tl := 0
																							else
																							if tl>$ff then
																								tl := $ff;
																							regdata := tl;
																						end;
																				end;
																			end;
																		DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
																			begin
																				case regaddr of
																					$0101:
																						begin
																							//adpcm-a, atl
																							tl := regdata and $3f;
																							Inc(tl, Round(-att/TLSTEP_OPN));
																							if tl<0 then
																								tl := 0
																							else
																							if tl>$3f then
																								tl := $3f;
																							regdata := (regdata and $c0) or tl;
																						end;
																					$0108..$010d:
																						begin
																							//adpcm-a, acl
																							//※atlで処理、atlに一度も書き込みがないときはうまく動作しない
																						end;
																					$001b:
																						begin
																							//adpcm-b, eg control
																							tl := Round(Power(10, -att/20) * regdata);
																							if tl<0 then
																								tl := 0
																							else
																							if tl>$ff then
																								tl := $ff;
																							regdata := tl;
																						end;
																				end;
																			end;
																		DEVICE_OPN2:
																			begin
																				case regaddr of
																					$002a:
																						begin
																							//pcm
																							tl := Round(Power(10, -att/20) * (Integer(regdata)-$80));
																							Inc(tl, $80);
																							if tl<0 then
																								tl := 0
																							else
																							if tl>$ff then
																								tl := $ff;
																							regdata := tl;
																						end;
																				end;
																			end;
																	end;
																end;
														end;
													end;
											end;
										end;
										//
										att := MainForm.ThreadCri[nTh].nOpmFmAttenuation;
										if att<>0 then
										begin
											case DeviceForm.ReqDevice[reqno].nInfo of
												DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
													begin
														case regaddr of
															$0060..$0067,	//slot1(m1)
															$0068..$006f,	//slot3(m2)
															$0070..$0077,	//slot2(c1)
															$0078..$007f:	//slot4(c2)
																begin
																	//fm, tl
																	ch := regaddr and 7;
																	slot := 1 + (((regaddr shr 2) and 2) or ((regaddr shr 4) and 1));
																	DevSts[conno].Opm.wTl[ch][slot-1] := regdata;
																	//
																	alg := DevSts[conno].Reg[$0020+ch] and $07;
																	//
																	n := 0;
																	case alg of
																		0..3:
																			if slot=4 then
																				n := 1;
																		4:
																			if (slot=2) or (slot=4) then
																				n := 1;
																		5..6:
																			if (slot=2) or (slot=3) or (slot=4) then
																				n := 1;
																		7:
																			n := 1;
																	end;
																	//
																	if n<>0 then
																	begin
																		tl := regdata and $7f;
																		Inc(tl, Round(att/TLSTEP_OPM));
																		if tl<0 then
																			tl := 0
																		else
																		if tl>$7f then
																			tl := $7f;
																		regdata := (regdata and $80) or tl;
																	end;
																end;
															$0020..$0027:
																begin
																	//fm, alg
																	ch := regaddr and 7;
																	//
																	for i := 0 to 3 do
																	begin
																		//
																		slot := 1 + (((i shl 1) and 2) or ((i shr 1) and 1));
																		n := 0;
																		case regdata and $07 of
																			0..3:
																				if slot=4 then
																					n := 1;
																			4:
																				if (slot=2) or (slot=4) then
																					n := 1;
																			5..6:
																				if (slot=2) or (slot=3) or (slot=4) then
																					n := 1;
																			7:
																				n := 1;
																		end;
																		//
																		regaddr2 := $0060+i*8+ch;
																		regdata2 := DevSts[conno].Opm.wTl[ch][slot-1];
																		if (regdata2 and $ff00)<>0 then
																			regdata2 := $00;
																		if n<>0 then
																		begin
																			tl := regdata2 and $7f;
																			Inc(tl, Round(att/TLSTEP_OPM));
																			if tl<0 then
																				tl := 0
																			else
																			if tl>$7f then
																				tl := $7f;
																			regdata2 := (regdata2 and $80) or tl;
																		end;
																		WriteBuf(nTh, conno, regaddr2, regdata2);
																	end;
																end;
														end;
													end;
											end;
										end;
										//
										att := MainForm.ThreadCri[nTh].nGa20Attenuation;
										if att<>0 then
										begin
											if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_GA20 then
											begin
												if (regaddr=$0108) and (regdata<>$00) then
												begin
													tl := Round(Power(10, -att/20) * (Integer(regdata)-$80));
													Inc(tl, $80);
													if tl<$01 then
														tl := $01
													else
													if tl>$ff then
														tl := $ff;
													regdata := tl;
												end;
											end;
										end;
			            end;
									//入力マスク
									if (fwrite_in=True) and (MaskReg(conno, DeviceForm.ReqDevice[reqno].nInfo, regaddr, @regdata)=True) then
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
														bStartSkip := False;
													end;
												end;
										end;
										//
										if (MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True) and (DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPN2) then
										begin
											case MainForm.ThreadCri[nTh].nOpnaOpn2PcmType of
												0:
													begin
														//fm
														case DeviceForm.CnDevice[conno].nInfo of
															DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
															DEVICE_YM2610B_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																begin
																	//PCM→FM変換
																	case regaddr of
																		$002a:	//dac data
																			begin
																				tlind0 := -1;
																				tlind1 := -1;
																				tlind2 := -1;
																				j := DevSts[conno].Reg[$014a] and $7f;
																				k := DevSts[conno].Reg[$014e] and $7f;
																				dmin := 1 shl 15;
																				for i := 0 to nOpnTl2PcmLen-1 do
																				begin
																					n := OpnTl2Pcm[i];
																					d := Abs((Integer(regdata)-$80)*32-(n+OpnTl2Pcm[j]+OpnTl2Pcm[k] - nOpnTl2Pcm0));
																					if d<dmin then
																					begin
																						dmin := d;
																						if n>0 then
																							tlind0 := i
																						else
																							tlind0 := $7f;
																						tlind1 := -1;
																						tlind2 := -1;
																					end;
																				end;
																				//
																				i := DevSts[conno].Reg[$0146] and $7f;
																				k := DevSts[conno].Reg[$014e] and $7f;
																				for j := 0 to nOpnTl2PcmLen-1 do
																				begin
																					n := OpnTl2Pcm[j];
																					d := Abs((Integer(regdata)-$80)*32-(OpnTl2Pcm[i]+n+OpnTl2Pcm[k] - nOpnTl2Pcm0));
																					if d<dmin then
																					begin
																						dmin := d;
																						tlind0 := -1;
																						if n>0 then
																							tlind1 := j
																						else
																							tlind1 := $7f;
																						tlind2 := -1;
																					end;
																				end;
																				//
																				i := DevSts[conno].Reg[$0146] and $7f;
																				j := DevSts[conno].Reg[$014a] and $7f;
																				for k := 0 to nOpnTl2PcmLen-1 do
																				begin
																					n := OpnTl2Pcm[k];
																					d := Abs((Integer(regdata)-$80)*32-(OpnTl2Pcm[i]+OpnTl2Pcm[j]+n - nOpnTl2Pcm0));
																					if d<dmin then
																					begin
																						dmin := d;
																						tlind0 := -1;
																						tlind1 := -1;
																						if n>0 then
																							tlind2 := k
																						else
																							tlind2 := $7f;
																					end;
																				end;
																				//
																				if (tlind0>=0) {and (tlind0<>(DevSts[conno].Reg[$0146] and $7f))} then
																				begin
																					regaddr := $0146;	//s3, tl
																					regdata := tlind0;
																				end else
																				if (tlind1>=0) {and (tlind1<>(DevSts[conno].Reg[$014a] and $7f))} then
																				begin
																					regaddr := $014a;	//s2, tl
																					regdata := tlind1;
																				end else
																				if (tlind2>=0) {and (tlind2<>(DevSts[conno].Reg[$014e] and $7f))} then
																				begin
																					regaddr := $014e;	//s4, tl
																					regdata := tlind2;
																				end else
																					fwrite_out := False;
																			end;
																		$002b:	//dac select
																			begin
																				if ((regdata xor DevSts[conno].Opn2.byDacSelect) and $80)<>0 then
																				begin
																					if (regdata and $80)=0 then
																					begin
																						//PCM→FM
																						//※音色を再設定しないといけない
																						WriteBuf(nTh, conno, $0028, $00 or 6);	//slot/ch.
																					end else
																					begin
																						//FM→PCM
																						WriteBuf(nTh, conno, $0142, $1f);	//s1, tl
																						WriteBuf(nTh, conno, $0146, $7f);	//s3, tl
																						WriteBuf(nTh, conno, $014a, $7f);	//s2, tl
																						WriteBuf(nTh, conno, $014e, $7f);	//s4, tl
																						WriteBuf(nTh, conno, $0152, $1f);	//s1, ks/ar
																						WriteBuf(nTh, conno, $0156, $1f);	//s3, ks/ar
																						WriteBuf(nTh, conno, $015a, $1f);	//s2, ks/ar
																						WriteBuf(nTh, conno, $015e, $1f);	//s4, ks/ar
																						WriteBuf(nTh, conno, $0162, $00);	//s1, amon/dr
																						WriteBuf(nTh, conno, $0166, $00);	//s3, amon/dr
																						WriteBuf(nTh, conno, $016a, $00);	//s2, amon/dr
																						WriteBuf(nTh, conno, $016e, $00);	//s4, amon/dr
																						WriteBuf(nTh, conno, $0172, $00);	//s1, sr
																						WriteBuf(nTh, conno, $0176, $00);	//s3, sr
																						WriteBuf(nTh, conno, $017a, $00);	//s2, sr
																						WriteBuf(nTh, conno, $017e, $00);	//s4, sr
																						WriteBuf(nTh, conno, $0182, $00);	//s1, sl/rr
																						WriteBuf(nTh, conno, $0186, $0f);	//s3, sl/rr
																						WriteBuf(nTh, conno, $018a, $0f);	//s2, sl/rr
																						WriteBuf(nTh, conno, $018e, $0f);	//s4, sl/rr
																						WriteBuf(nTh, conno, $0192, $00);	//s1, ssg-eg
																						WriteBuf(nTh, conno, $0196, $00);	//s3, ssg-eg
																						WriteBuf(nTh, conno, $019a, $00);	//s2, ssg-eg
																						WriteBuf(nTh, conno, $019e, $00);	//s4, ssg-eg
																						WriteBuf(nTh, conno, $0132, $02);	//s1, dt/multi
																						WriteBuf(nTh, conno, $0136, (0 shl 4) or $01);	//s3, dt/multi
																						WriteBuf(nTh, conno, $013a, (0 shl 4) or $01);	//s2, dt/multi
																						WriteBuf(nTh, conno, $013e, (0 shl 4) or $01);	//s4, dt/multi
																						WriteBuf(nTh, conno, $01a6, (0 shl 3) or 0);	//block/fnum2
																						WriteBuf(nTh, conno, $01a2, $10);	//fnum1
																						WriteBuf(nTh, conno, $01b2, (7 shl 3) or 5);	//fb/connect
																						WriteBuf(nTh, conno, $0028, $f0 or 6);	//slot/ch.
																					end;
																				end;
																				DevSts[conno].Opn2.byDacSelect := regdata;
																				fwrite_out := False;
																			end;
																		$0028:	//slot/ch.
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																				begin
																					ch := regdata and $7;
																					if ch<4 then
																						Inc(ch);
																					if ch=6 then
																						fwrite_out := False;
																				end;
																			end;
																		$0142, $0146, $014a, $014e,	//s1/s3/s2/s4, tl
																		$0152, $0156, $015a, $015e,	//s1/s3/s2/s4, ks/ar
																		$0162, $0166, $016a, $016e,	//s1/s3/s2/s4, amon/dr
																		$0172, $0176, $017a, $017e,	//s1/s3/s2/s4, sr
																		$0182, $0186, $018a, $018e,	//s1/s3/s2/s4, sl/rr
																		$0192, $0196, $019a, $019e,	//s1/s3/s2/s4, ssg-eg
																		$0132, $0136, $013a, $013e,	//s1/s3/s2/s4, dt/multi
																		$01a6,	//block/fnum2
																		$01a2,	//fnum1
																		$01b2:	//fb/connect
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																					fwrite_out := False;
																			end;
																		$01b6:	//pan/ams/pms
																			begin
																				DevSts[conno].Opn2.byDacPan := regdata;
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																					regdata := regdata and $c0;	//ams=0/pms=0
																			end;
																	end;
																end;
														end;
													end;
												1:
													begin
														//ssg
														case DeviceForm.CnDevice[conno].nInfo of
															DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
															DEVICE_YM2610B_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																begin
																	//PCM→SSG変換
																	case regaddr of
																		$002a:	//dac data
																			begin
																				tlind0 := -1;
																				tlind1 := -1;
																				tlind2 := -1;
																				if (DevSts[conno].Opn2.byDacPan and $c0)<>0 then
																				begin
																					//
																					case DeviceForm.CnDevice[conno].nInfo of
																						DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																							rssg := Power(10, 5/20);
																						else
																							rssg := Power(10, 14/20);
																					end;
																					//
																					j := DevSts[conno].Reg[$0008] and $f;
																					k := DevSts[conno].Reg[$000a] and $f;
																					dmin := 1 shl 15;
																					for i := 0 to nSsgVol2PcmLen-1 do
																					begin
																						n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																						d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																						if d<dmin then
																						begin
																							dmin := d;
																							tlind0 := i;
																							tlind1 := -1;
																							tlind2 := -1;
																						end;
																					end;
																					//
																					i := DevSts[conno].Reg[$0009] and $f;
																					k := DevSts[conno].Reg[$000a] and $f;
																					for j := 0 to nSsgVol2PcmLen-1 do
																					begin
																						n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																						d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																						if d<dmin then
																						begin
																							dmin := d;
																							tlind0 := -1;
																							tlind1 := j;
																							tlind2 := -1;
																						end;
																					end;
																					//
																					i := DevSts[conno].Reg[$0009] and $f;
																					j := DevSts[conno].Reg[$0008] and $f;
																					for k := 0 to nSsgVol2PcmLen-1 do
																					begin
																						n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																						d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																						if d<dmin then
																						begin
																							dmin := d;
																							tlind0 := -1;
																							tlind1 := -1;
																							tlind2 := k;
																						end;
																					end;
																				end;
																				//
																				if (tlind0>=0) {and (tlind0<>(DevSts[conno].Reg[$0009] and $f))} then
																				begin
																					regaddr := $0009;	//s3, tl
																					regdata := tlind0;
																				end else
																				if (tlind1>=0) {and (tlind1<>(DevSts[conno].Reg[$0008] and $f))} then
																				begin
																					regaddr := $0008;	//s2, tl
																					regdata := tlind1;
																				end else
																				if (tlind2>=0) {and (tlind2<>(DevSts[conno].Reg[$000a] and $f))} then
																				begin
																					regaddr := $000a;	//s4, tl
																					regdata := tlind2;
																				end else
																					fwrite_out := False;
																			end;
																		$002b:	//dac select
																			begin
																				if ((regdata xor DevSts[conno].Opn2.byDacSelect) and $80)<>0 then
																				begin
																					if (regdata and $80)=0 then
																					begin
																						//PCM→FM
																						//※音色を再設定しないといけない
																					end else
																					begin
																						//FM→PCM
																						WriteBuf(nTh, conno, $0000, $00);
																						WriteBuf(nTh, conno, $0001, $00);
																						WriteBuf(nTh, conno, $0002, $00);
																						WriteBuf(nTh, conno, $0003, $00);
																						WriteBuf(nTh, conno, $0004, $00);
																						WriteBuf(nTh, conno, $0005, $00);
																						WriteBuf(nTh, conno, $0009, $00);	//s3, tl
																						WriteBuf(nTh, conno, $0008, $00);	//s2, tl
																						WriteBuf(nTh, conno, $000a, $00);	//s4, tl
																						WriteBuf(nTh, conno, $0007, $3f);
																					end;
																				end;
																				DevSts[conno].Opn2.byDacSelect := regdata;
																				fwrite_out := False;
																			end;
																		$0028:	//slot/ch.
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																				begin
																					ch := regdata and $7;
																					if ch<4 then
																						Inc(ch);
																					if ch=6 then
																						fwrite_out := False;
																				end;
																			end;
																		$0142, $0146, $014a, $014e,	//s1/s3/s2/s4, tl
																		$0152, $0156, $015a, $015e,	//s1/s3/s2/s4, ks/ar
																		$0162, $0166, $016a, $016e,	//s1/s3/s2/s4, amon/dr
																		$0172, $0176, $017a, $017e,	//s1/s3/s2/s4, sr
																		$0182, $0186, $018a, $018e,	//s1/s3/s2/s4, sl/rr
																		$0192, $0196, $019a, $019e,	//s1/s3/s2/s4, ssg-eg
																		$0132, $0136, $013a, $013e,	//s1/s3/s2/s4, dt/multi
																		$01a6,	//block/fnum2
																		$01a2,	//fnum1
																		$01b2:	//fb/connect
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																					fwrite_out := False;
																			end;
																		$01b6:	//pan/ams/pms
																			begin
																				DevSts[conno].Opn2.byDacPan := regdata;
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																					fwrite_out := False;
																			end;
																	end;
																end;
														end;
													end;
												2:
													begin
														//adpcm
														case DeviceForm.CnDevice[conno].nInfo of
															DEVICE_OPNA, DEVICE_OPNA_RAM:
																begin
																	//PCM→ADPCM変換
																	case regaddr of
																		$002a:	//dac data
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																				begin
																					//レベルコントロール
																					regaddr := $010b;
																				end else
																					fwrite_out := False;
																			end;
																		$002b:	//dac select
																			begin
																				DevSts[conno].Opn2.byDacSelect := regdata;
																				fwrite_out := False;
																			end;
																		$01b6:	//pan/ams/pms
																			begin
																				DevSts[conno].Opn2.byDacPan := regdata;
																				//パン
																				regaddr := $0101;
																				regdata := (regdata and $c0) or $02 or (DevSts[conno].Reg[regaddr] and $0c);
																			end;
																	end;
																end;
														end;
													end;
												3:
													begin
														//pcm
														case DeviceForm.CnDevice[conno].nInfo of
															DEVICE_OPNA, DEVICE_OPNA_RAM:
																begin
																	//PCM→PCM変換
																	case regaddr of
																		$002a:	//dac data
																			begin
																				if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																				begin
																					//DACデータ
																					regaddr := $010e;
																					regdata := regdata xor $80;
																				end else
																					fwrite_out := False;
																			end;
																		$002b:	//dac select
																			begin
																				DevSts[conno].Opn2.byDacSelect := regdata;
																				fwrite_out := False;
																			end;
																		$01b6:	//pan/ams/pms
																			begin
																				DevSts[conno].Opn2.byDacPan := regdata;
																				//パン
																				regaddr := $0101;
																				regdata := (regdata and $c0) or $02 or (DevSts[conno].Reg[regaddr] and $0c);
																			end;
																	end;
																end;
														end;
													end;
											end;
										end;
                    //
										case DeviceForm.CnDevice[conno].nInfo of
											DEVICE_OPP, DEVICE_OPZ:
												begin
													if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPM then
													begin
														//アドレス変更
														if regaddr=$0001 then
														begin
															//TESTレジスタ
	                            //※OPP/OPZを調べたら修正
                              regaddr := $ffff;
															fwrite_out := False;
														end;
													end;
												end;
											DEVICE_OPN:
												begin
													if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPNB_RAM then
													begin
                            //CH3@OPNB=CH5@OPNA→CH1@OPN
					 							 		//  チャンネル変更
												 		case regaddr of
													 		$0131, $0141, $0151, $0161, $0171, $0181, $0191,  //slot1
													 		$0135, $0145, $0155, $0165, $0175, $0185, $0195,	//slot3
													 		$0139, $0149, $0159, $0169, $0179, $0189, $0199,	//slot2
													 		$013d, $014d, $015d, $016d, $017d, $018d, $019d,	//slot4
														 	$01a1, $01a5, $01b1, $01b5:
													 			begin
														 			//
															 		Dec(regaddr, $0101);
														   	end;
	  													$0028:
														  	begin
			  			   					   			//
																	if (regdata and $07)=$05 then
									   					   		Dec(regdata, $05);
														  	end;
							  			  	  end;
										   	  end;
											  end;
		 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
										  	begin
					 								case DeviceForm.ReqDevice[reqno].nInfo of
												  	DEVICE_OPN:
							  							begin
							 	  					 		//CH1@OPN→CH5@OPNA=CH3@OPNB
        		                    //  チャンネル変更
            		                //  ※YM2610Bは変更しなくて良い
													   		case regaddr of
	  												   		$0030, $0040, $0050, $0060, $0070, $0080, $0090,  //slot1
															 		$0034, $0044, $0054, $0064, $0074, $0084, $0094,	//slot3
			  								   				$0038, $0048, $0058, $0068, $0078, $0088, $0098,	//slot2
															 		$003c, $004c, $005c, $006c, $007c, $008c, $009c,	//slot4
							  								 	$00a0, $00a4, $00b0, $00b4:
														   			begin
									  					   			//
																   		Inc(regaddr, $0101);
												  			   	end;
	  															$0028:
																  	begin
			  			   					   					//
																			if (regdata and $07)=$00 then
											   					   		Inc(regdata, $05);
																  	end;
									  			  	  end;
												   	  end;
														DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
														 	begin
															 	//OPNA→OPNB/YM2610B
																//  リズム→ADPCMA変換
        	                    	if (byRhythmEnb<>0) and (MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=True) then
           	                    begin
																	case regaddr of
																		$0010..$001f:
                                    	begin
                                        if regaddr=$0010 then
                                        	regdata := regdata and ($c0 or byRhythmEnb);
	                   	                	Inc(regaddr, $0100-$0010);
                                      end;
                                  end;
																end;
															end;
                          end;
									  	  end;
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
											bStartSkip := False;
											WriteBuf(nTh, conno, regaddr, regdata);
										end;
									end;
								end;
							end;
						end;
					end;
				end;

			$fd:
				begin
					//終端
					Inc(rptr);
				end;

			$fe:
				begin
					//SYNC>2
					offs := 0;
					tm := 0;
					while Terminated=False do
					begin
						Inc(offs);
						if (rptr+offs)>=dwDataSize then
						begin
							rptr := dwDataSize;
							loopc := nLoopLim;
							Break;
						end;
						tm := tm or (DWORD(FileBuf[rptr+offs] and $7f) shl (7*(offs-1)));
						if (FileBuf[rptr+offs] and $80)=$00 then
						begin
							Inc(tm, 2);
							Inc(sync, tm*nTimerInfo1*FREQ_SYNC);
							Inc(rptr, 1+offs);
							Break;
						end;
					end;
				end;
			$ff:
				begin
					//SYNC=1
					tm := 1;
					Inc(sync, tm*nTimerInfo1*FREQ_SYNC);
					Inc(rptr);
				end;
			else
				begin
					//不明
					Break;
				end;
		end;
 	end;

  //
            tm := sync2 div (nTimerInfo2*FREQ_SYNC);
            if (tm<>endtime) and (Terminated=False) then
            begin
            	endtime := tm;
							PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
            end;

	//
  Result := ST_THREAD_END;
end;

function TInputThread.MainSpuOld: Integer;
	var
		i, nTh, nState: Integer;
		tm: Int64;
		spuh: PSpuHeader;
		rptr, spudsize: DWORD;
		spud: PSpuDataOld;
	var
		reqno, conno: Integer;
		regaddr, regdata: Word;
		sync, sync2, endtime: Int64;
	const
  	Reg1aa = $c000;
  	DspAddrTable: array[0..193-1] of Word = (
      $1a2,$1a4,
			$1c0,$1c2,$1c4,$1c6,$1c8,$1ca,$1cc,$1ce,
      $1d0,$1d2,$1d4,$1d6,$1d8,$1da,$1dc,$1de,
			$1e0,$1e2,$1e4,$1e6,$1e8,$1ea,$1ec,$1ee,
      $1f0,$1f2,$1f4,$1f6,$1f8,$1fa,$1fc,$1fe,
      $1aa,
      //
			$000,$002,$004,$006,$008,$00a, $010,$012,$014,$016,$018,$01a,
			$020,$022,$024,$026,$028,$02a, $030,$032,$034,$036,$038,$03a,
			$040,$042,$044,$046,$048,$04a, $050,$052,$054,$056,$058,$05a,
			$060,$062,$064,$066,$068,$06a, $070,$072,$074,$076,$078,$07a,
			$080,$082,$084,$086,$088,$08a, $090,$092,$094,$096,$098,$09a,
			$0a0,$0a2,$0a4,$0a6,$0a8,$0aa, $0b0,$0b2,$0b4,$0b6,$0b8,$0ba,
			$0c0,$0c2,$0c4,$0c6,$0c8,$0ca, $0d0,$0d2,$0d4,$0d6,$0d8,$0da,
			$0e0,$0e2,$0e4,$0e6,$0e8,$0ea, $0f0,$0f2,$0f4,$0f6,$0f8,$0fa,
			$100,$102,$104,$106,$108,$10a, $110,$112,$114,$116,$118,$11a,
			$120,$122,$124,$126,$128,$12a, $130,$132,$134,$136,$138,$13a,
			$140,$142,$144,$146,$148,$14a, $150,$152,$154,$156,$158,$15a,
			$160,$162,$164,$166,$168,$16a, $170,$172,$174,$176,$178,$17a,
			$190,$192,$194,$196,$198,$19a,
      //
      $1b0,$1b2,$1b4,$1b6,
			$180,$182,$184,$186
    );
begin
	//
	reqno := CmdToReqno[0];
  conno := -1;
  nTh := -1;
	if reqno>=0 then
	begin
		conno := DeviceForm.ReqDevice[reqno].nNo;
		if conno>=0 then
		begin
			if DeviceForm.CnDevice[conno].nInfo<>DEVICE_NONE then
				nTh := DeviceForm.CnDevice[conno].nThread;
    end;
  end;
  if (reqno<0) or (conno<0) or (nTh<0) then
  begin
		Result := ST_THREAD_ERROR;
    Exit;
  end;

	//
  spuh := @FileBuf[0];
  nState := 0;
	rptr := 0;
  regaddr := 0;
	regdata := 0;
	while Terminated=False do
	begin
		//
    case nState of
    	0:
      	begin
					regaddr := $1aa;
          regdata := Reg1aa and $ffcf;
          Inc(nState);
        end;
    	1:
      	begin
        	//RAM書き込みアドレス設定
					rptr := $01000;
					regaddr := $1a6;
					regdata := (rptr shr 3) and $ffff;
          Inc(nState);
        end;
      2:
      	begin
        	//RAM書き込み
					regaddr := $1a8;
					regdata := spuh^.Ram[rptr+1] and $ff;
          regdata := (regdata shl 8) or (spuh^.Ram[rptr] and $ff);
					Inc(rptr, 2);
        	if (rptr>0) and ((rptr and $3f)=0) then
          	Inc(nState);
        end;
      3:
      	begin
					regaddr := $1aa;
          regdata := (Reg1aa and $ffcf) or $10;
          Inc(nState);
        end;
      4:
      	begin
					regaddr := $1aa;
          regdata := Reg1aa and $ffcf;
        	if rptr<(512*1024) then
          	nState := 2
          else
          begin
						rptr := 0;
          	Inc(nState);
          end;
        end;
      5:
      	begin
        	//レジスタ書き込み
          regaddr := DspAddrTable[rptr];
          if regaddr<>$1aa then
						regdata := spuh^.Reg[regaddr shr 1] and $ffff
          else
          begin
          	regdata := Reg1aa and $c03f;
            regdata := regdata or spuh^.Reg[regaddr shr 1] and $3fc0;
          end;
					Inc(rptr);
  	     	if rptr>=(SizeOf(DspAddrTable) div SizeOf(DspAddrTable[0])) then
          	Inc(nState);
        end;
      else
      	Break;
    end;
		//入力マスク
		if MaskReg(conno, DeviceForm.ReqDevice[reqno].nInfo, regaddr, @regdata)=True then
		begin
			//出力マスク
			if MaskReg(conno, DeviceForm.CnDevice[conno].nInfo, regaddr, @regdata)=True then
				WriteBuf(nTh, conno, regaddr, regdata);
		end;
	end;

  //
  spudsize := SizeOf(spud^);
	rptr := 0;
	sync2 := 0;
	endtime := 0;
	while Terminated=False do
	begin
		//
		if (rptr+spudsize)>dwDataSize then
			Break;
		spud := @FileBuf[SizeOf(TSpuHeader)+rptr];

		//
		sync := (spud^.dwSync)*nTimerInfo1*FREQ_SYNC;
		tm := Min($3f, Round(sync*xRatio-sync2) div nTimerInfo2);
		if tm>0 then
		begin
			//
			Inc(sync2, tm*nTimerInfo2);
			if bStartSkip=False then
			begin
				for i := 0 to OUTPUT_THREADMAX-1 do
					WriteBuf(i, 0, CMD_SYNC, tm);
			end;
		end else
		begin
			//
			tm := sync2 div (nTimerInfo2*FREQ_SYNC);
			if (tm-endtime)>=10 then
			begin
				endtime := tm;
				PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
			end;

			//
			regaddr := (spud^.dwAddr) and $01ff;
			regdata := (spud^.dwData) and $ffff;
			Inc(rptr, spudsize);
			//入力マスク
			if MaskReg(conno, DeviceForm.ReqDevice[reqno].nInfo, regaddr, @regdata)=True then
			begin
				//出力マスク
				if MaskReg(conno, DeviceForm.CnDevice[conno].nInfo, regaddr, @regdata)=True then
				begin
					bStartSkip := False;
					WriteBuf(nTh, conno, regaddr, regdata);
				end;
			end;
		end;
	end;

	//
			tm := sync2 div (nTimerInfo2*FREQ_SYNC);
			if (tm<>endtime) and (Terminated=False) then
			begin
				endtime := tm;
				PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
			end;

	//
	Result := ST_THREAD_END;
end;

function TInputThread.MainVgm: Integer;
	var
  	i, ch, nTh: Integer;
    tm: Int64;
    rptr, offs: DWORD;
	var
    loopc, reqno, conno, cmd: Integer;
    fwrite_in, fwrite_out: Boolean;
    regaddr, regdata, regaddr2, regdata2: Word;
    dblk: TDataBlock;
    sync, sync2, endtime: Int64;
  var
  	j, k, d, dmin, tlind0, tlind1, tlind2: Integer;
    rssg: Extended;
  var
    n, att, alg, slot, tl, oplltype: Integer;
    popllinst: PByteArray;
begin
	//
  rptr := 0;
  loopc := 0;
  FillChar(dblk, SizeOf(dblk), $00);
  dblk.wType := $ffff;
  sync := 0;
  sync2 := 0;
  endtime := 0;
	while Terminated=False do
  begin
		//
		if rptr>=dwDataSize then
		begin
			rptr := dwLoopPtr;
			Inc(loopc);
			if (rptr>=dwDataSize) or (loopc>=nLoopLim) then
				Break;
		end;

    //
		tm := Min($fff, Round(sync*xRatio-sync2) div nTimerInfo2);
		if tm>0 then
		begin
			//
			Inc(sync2, tm*nTimerInfo2);
      if bStartSkip=False then
      begin
				for i := 0 to OUTPUT_THREADMAX-1 do
					WriteBuf(i, 0, CMD_SYNC, tm);
      end;
		end else
		begin
			//
      tm := sync2 div (nTimerInfo2*FREQ_SYNC);
      if (tm-endtime)>=10 then
      begin
       	endtime := tm;
				PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
      end;

      //
     	reqno := -1;
			regaddr := 0;
			regdata := 0;
      if (dblk.wType and $ff00)=0 then
      begin
      	//データブロック
        case dblk.wType of
          $81:
					//	81 = YM2608 DELTA-T ROM data
          	begin
      	      reqno := TypeToReqno[dblk.wType];
            	case dblk.nState of
              	0:
                	begin
										regaddr := $0100;
										regdata := $60;
                  	Inc(dblk.nState);
                  end;
              	1:
                	begin
										regaddr := $0101;
										regdata := $c2;	//8bit, dram
                  	Inc(dblk.nState);
                  end;
              	2:
                	begin
										regaddr := $0102;
										regdata := (dblk.dwRomStartAddr shr 5) and $ff;
                    dblk.dwOffset := dblk.dwRomStartAddr and $1f;
                  	Inc(dblk.nState);
                  end;
              	3:
                	begin
										regaddr := $0103;
										regdata := (dblk.dwRomStartAddr shr 13) and $ff;
                  	Inc(dblk.nState);
                  end;
              	4:
                	begin
										regaddr := $010c;
										regdata := $ff;
                  	Inc(dblk.nState);
                  end;
              	5:
                	begin
										regaddr := $010d;
										regdata := $ff;
                  	Inc(dblk.nState);
                  end;
              	6:
                	begin
				            if dblk.dwReadPtr<dblk.dwSize then
		    		        begin
											regaddr := $0108;
                      if dblk.dwOffset>0 then
                      begin
												regdata := $ff;
                        Dec(dblk.dwOffset);
                      end else
                      begin
												regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
					    	        Inc(dblk.dwReadPtr);
                    	end;
        		    	  end else
                    begin
											regaddr := $0100;
											regdata := $00;
	                  	Inc(dblk.nState);
                    end;
                  end;
                7:
                	begin
										regaddr := $0101;
										regdata := $c2;	//8bit, dram
                  	Inc(dblk.nState);
                  end;
                else
                begin
									reqno := -1;
         		  		dblk.wType := $ffff;
                end;
            	end;
            end;
          $82, $83:
					//	82 = YM2610 ADPCM ROM data
					//	83 = YM2610 DELTA-T ROM data
          	begin
      	      reqno := TypeToReqno[dblk.wType];
            	case dblk.nState of
              	0:
                	begin
                  	//$001e（$0301）
										//  0x00 adpcm-b
										//  0x01 adpcm-a
										regaddr := $001e;
										regdata := (not (dblk.wType-$82)) and 1;
                  	Inc(dblk.nState);
                  end;
              	1:
                	begin
										//$0017（$0303）
                    //  a23-a16
										regaddr := $0017;
										regdata := (dblk.dwRomStartAddr shr 16) and $ff;
                  	Inc(dblk.nState);
                  end;
              	2:
                	begin
										//$0016（$0302）
                    //  a15-a8
										regaddr := $0016;
										regdata := (dblk.dwRomStartAddr shr 8) and $ff;
                    dblk.dwOffset := dblk.dwRomStartAddr and $ff;
                    if dblk.dwOffset>0 then
	                  	Inc(dblk.nState)
                    else
                    	dblk.nState := 4;
                  end;
                3:
                	begin
                   	//$001f（$0308）
                    //  d7-0
										regaddr := $001f;
										regdata := $ff;
                    Dec(dblk.dwOffset);
                    if dblk.dwOffset=0 then
	                  	Inc(dblk.nState);
                  end;
              	4:
		              begin
				            if dblk.dwReadPtr<dblk.dwSize then
		    		        begin
											regaddr := $001f;
											regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
				    	        Inc(dblk.dwReadPtr);
	                    Inc(dblk.dwRomStartAddr);
                      if (dblk.dwRomStartAddr and $ff)=0 then
		                  	dblk.nState := 1;
        		    	  end else
                    begin
											reqno := -1;
		         		  		dblk.wType := $ffff;
	                  	Inc(dblk.nState);
                    end;
                  end;
                else
                begin
									reqno := -1;
         		  		dblk.wType := $ffff;
                end;
            	end;
            end;
	        $84:
					//	84 = YMF278B ROM data
          	begin
            	//※未実装
            end;
          $85:
					//	85 = YMF271 ROM data
          	begin
      	      reqno := TypeToReqno[dblk.wType];
            	case dblk.nState of
              	0:
                	begin
										regaddr := $0903;
										regdata := (dblk.dwRomStartAddr shr 16) and $7f;
                  	Inc(dblk.nState);
                  end;
              	1:
                	begin
										regaddr := $0902;
										regdata := (dblk.dwRomStartAddr shr 8) and $ff;
                    dblk.dwOffset := dblk.dwRomStartAddr and $ff;
                    if dblk.dwOffset>0 then
	                  	Inc(dblk.nState)
                    else
                    	dblk.nState := 3;
                  end;
              	2:
                	begin
										regaddr := $0918;
										regdata := dblk.dwOffset;
                  	Inc(dblk.nState);
                  end;
              	3:
		              begin
				            if dblk.dwReadPtr<dblk.dwSize then
		    		        begin
											regaddr := $0908;
											regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
				    	        Inc(dblk.dwReadPtr);
                      if False then
                      begin
		                    Inc(dblk.dwRomStartAddr);
  	                    if (dblk.dwRomStartAddr and $ff)=0 then
			                  	dblk.nState := 0;
                      end;
        		    	  end else
                    begin
											reqno := -1;
		         		  		dblk.wType := $ffff;
	                  	Inc(dblk.nState);
                    end;
                  end;
                else
                begin
									reqno := -1;
         		  		dblk.wType := $ffff;
                end;
            	end;
            end; 
          $86:
					//	86 = YMZ280B ROM data
          	begin
      	      reqno := TypeToReqno[dblk.wType];
            	case dblk.nState of
              	0:
                	begin
										regaddr := $0103;
										regdata := (dblk.dwRomStartAddr shr 16) and $ff;
                  	Inc(dblk.nState);
                  end;
              	1:
                	begin
										regaddr := $0102;
										regdata := (dblk.dwRomStartAddr shr 8) and $ff;
                    dblk.dwOffset := dblk.dwRomStartAddr and $ff;
                    if dblk.dwOffset>0 then
	                  	Inc(dblk.nState)
                    else
                    	dblk.nState := 3;
                  end;
              	2:
                	begin
										regaddr := $0118;
										regdata := dblk.dwOffset;
                  	Inc(dblk.nState);
                  end;
              	3:
		              begin
				            if dblk.dwReadPtr<dblk.dwSize then
		    		        begin
											regaddr := $0108;
											regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
				    	        Inc(dblk.dwReadPtr);
                      if False then
                      begin
		                    Inc(dblk.dwRomStartAddr);
  	                    if (dblk.dwRomStartAddr and $ff)=0 then
			                  	dblk.nState := 0;
                      end;
        		    	  end else
                    begin
											reqno := -1;
		         		  		dblk.wType := $ffff;
	                  	Inc(dblk.nState);
                    end;
                  end;
                else
                begin
									reqno := -1;
         		  		dblk.wType := $ffff;
                end;
            	end;
            end;
          $87:
					//	87 = YMF278B RAM data
          	begin
            	//※未実装
            end;
          $88:
					//	88 = Y8950 DELTA-T ROM data
          	begin
      	      reqno := TypeToReqno[dblk.wType];
            	case dblk.nState of
              	0:
                	begin
										regaddr := $0007;
										regdata := $60;
                  	Inc(dblk.nState);
                  end;
              	1:
                	begin
										regaddr := $0008;
										regdata := $00;	//256K, dram
                  	Inc(dblk.nState);
                  end;
              	2:
                	begin
										regaddr := $0009;
										regdata := (dblk.dwRomStartAddr shr 2) and $ff;
                    dblk.dwOffset := dblk.dwRomStartAddr and $03;
                  	Inc(dblk.nState);
                  end;
              	3:
                	begin
										regaddr := $000a;
										regdata := (dblk.dwRomStartAddr shr 10) and $ff;
                  	Inc(dblk.nState);
                  end;
              	4:
                	begin
				            if dblk.dwReadPtr<dblk.dwSize then
		    		        begin
											regaddr := $000f;
                      if dblk.dwOffset>0 then
                      begin
												regdata := $ff;
                        Dec(dblk.dwOffset);
                      end else
                      begin
												regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
					    	        Inc(dblk.dwReadPtr);
                    	end;
        		    	  end else
                    begin
											regaddr := $0007;
											regdata := $00;
	                  	Inc(dblk.nState);
                    end;
                  end;
                5:
                	begin
										regaddr := $0008;
										regdata := $00;	//256K, dram
                  	Inc(dblk.nState);
                  end;
                else
                begin
									reqno := -1;
         		  		dblk.wType := $ffff;
                end;
            	end;
            end;
        end;
      end;

      //
			fwrite_in := True;
      fwrite_out := fwrite_in;
      if reqno<0 then
      begin
				//コマンド
				cmd := FileBuf[rptr];
	      reqno := CmdToReqno[cmd];
				case cmd of
					$62, $63, $66, $70..$7f, $80..$8f:
		      	offs := 1;
		  		$4f, $50, $30..$4e:
		      	offs := 2;
		      $51..$5f, $61, $a0, $b0..$b2, $a1..$af, $b3..$bf:
		      	offs := 3;
		      $c0..$c2, $d0, $d1, $c3..$cf, $d2..$df:
		      	offs := 4;
		      $e0, $e1..$ff:
		      	offs := 5;
		      $67:
		      	offs := 7 + PDWORD(@FileBuf[rptr+3])^;
		      $68:
		      	offs := 12;
		      $90:
	        	offs := 5;
		      $91:
	        	offs := 5;
		      $92:
	        	offs := 6;
		      $93:
	        	offs := 11;
		      $94:
	        	offs := 2;
	        $95:
	        	offs := 5;
		      else
			     	offs := 0;
		    end;
		    //
				if (offs=0) or ((rptr+offs)>dwDataSize) then
					Break;

				//
				case cmd of

		    	$4f, $3f:
		      //  0x4F dd    : Game Gear PSG stereo, write dd to port 0x06
		      	begin
							regaddr := $0001;
							regdata := FileBuf[rptr+1];
		        end;
					$50, $30:
		      //  0x50 dd    : PSG (SN76489/SN76496) write value dd
		      	begin
							regaddr := $0000;
							regdata := FileBuf[rptr+1];
		        end;

					$51, $a1:
		      //  0x51 aa dd : YM2413, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$52, $53, $a2, $a3:
		      //  0x52 aa dd : YM2612 port 0, write value dd to register aa
					//  0x53 aa dd : YM2612 port 1, write value dd to register aa
		      	begin
							regaddr := (((cmd-$52) and 1) shl 8) or FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$54, $a4:
					//  0x54 aa dd : YM2151, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$55, $a5:
					//  0x55 aa dd : YM2203, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$56, $57, $a6, $a7:
					//  0x56 aa dd : YM2608 port 0, write value dd to register aa
					//  0x57 aa dd : YM2608 port 1, write value dd to register aa
		      	begin
							regaddr := (((cmd-$56) and 1) shl 8) or FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;
					$58, $59, $a8, $a9:
					//  0x58 aa dd : YM2610 port 0, write value dd to register aa
					//  0x59 aa dd : YM2610 port 1, write value dd to register aa
		      	begin
							regaddr := (((cmd-$58) and 1) shl 8) or FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$5a, $aa:
					//  0x5A aa dd : YM3812, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;
					$5b, $ab:
					//  0x5B aa dd : YM3526, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;
					$5c, $ac:
					//  0x5C aa dd : Y8950, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$5d, $ad:
					//  0x5D aa dd : YMZ280B, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$5e, $5f, $ae, $af:
					//  0x5E aa dd : YMF262 port 0, write value dd to register aa
					//  0x5F aa dd : YMF262 port 1, write value dd to register aa
		      	begin
							regaddr := (((cmd-$5e) and 1) shl 8) or FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$61:
					//  0x61 nn nn : Wait n samples, n can range from 0 to 65535 (approx 1.49
					//               seconds). Longer pauses than this are represented by multiple
					//               wait commands.
		      	begin
		        	tm := PWORD(@FileBuf[rptr+1])^;
							Inc(sync, tm*nTimerInfo1*FREQ_SYNC);
	            fwrite_in := False;
		        end;
					$62:
					//  0x62       : wait 735 samples (60th of a second), a shortcut for
					//               0x61 0xdf 0x02
		      	begin
							Inc(sync, 735*nTimerInfo1*FREQ_SYNC);
	            fwrite_in := False;
		        end;
					$63:
					//  0x63       : wait 882 samples (50th of a second), a shortcut for
					//               0x61 0x72 0x03
		      	begin
							Inc(sync, 882*nTimerInfo1*FREQ_SYNC);
	            fwrite_in := False;
		        end;

					$66:
					//  0x66       : end of sound data
		      	begin
	            fwrite_in := False;
		        end;

					$67:
					//  0x67 ...   : data block
		      	begin
	            dblk.wType := FileBuf[rptr+2];
	            case dblk.wType of
	            	$00..$3f:
								//00..3F : data of recorded streams (uncompressed)
	              	begin
	      			      dblk.dwBufPtr := rptr + 7;
	            			dblk.dwSize := PDWORD(@FileBuf[rptr+3])^;
				            dblk.dwReadPtr := 0;
                    dblk.dwOffset := 0;
	                end;
	              $40..$7e:
	              //40..7E : data of recorded streams (compressed)
	              	begin
	                end;
	              $7f:
								//7F     : Compression Table
	              	begin
	                end;
	              $80..$bf:
								//80..BF : ROM/RAM Image dumps (contain usually samples)
	              	begin
	      			      dblk.dwBufPtr := rptr + 15;
	            			dblk.dwSize := PDWORD(@FileBuf[rptr+3])^ - 8;
                    dblk.nState := 0;
				            dblk.dwReadPtr := 0;
                    dblk.dwOffset := 0;
	                  dblk.dwRomSize := PDWORD(@FileBuf[rptr+7])^;
	                  dblk.dwRomStartAddr := PDWORD(@FileBuf[rptr+11])^;
	                end;
	              $c0..$ff:
								//C0..FF : RAM writes
	              	begin
	      			      dblk.dwBufPtr := rptr + 9;
	            			dblk.dwSize := PDWORD(@FileBuf[rptr+3])^ - 2;
                    dblk.nState := 0;
				            dblk.dwReadPtr := 0;
                    dblk.dwOffset := 0;
	                  dblk.wRamStartAddr := PWORD(@FileBuf[rptr+7])^;
	                end;
	              else
	              	Break;
	            end;
	            fwrite_in := False;
		        end;

					$68:
					//  0x68 ...   : PCM RAM write
		      	begin
	            fwrite_in := False;
		        end;

					$70..$7f:
					//  0x7n       : wait n+1 samples, n can range from 0 to 15.
		      	begin
		        	tm := (cmd and $0f) + 1;
							Inc(sync, tm*nTimerInfo1*FREQ_SYNC);
	            fwrite_in := False;
		        end;

					$80..$8f:
					//  0x8n       : YM2612 port 0 address 2A write from the data bank, then wait
					//               n samples; n can range from 0 to 15. Note that the wait is n,
					//               NOT n+1. (Note: Written to first chip instance only.)
		      	begin
	            if (dblk.wType=$00) and (dblk.dwReadPtr<dblk.dwSize) then
	            begin
								regaddr := $002a;
								regdata := FileBuf[dblk.dwBufPtr + dblk.dwReadPtr];
		            Inc(dblk.dwReadPtr);
	            end;
	            //
		        	tm := cmd and $0f;
							Inc(sync, tm*nTimerInfo1*FREQ_SYNC);
		        end;

					$90:
					//  0x90-0x95  : DAC Stream Control Write
					//  Setup Stream Control:
		      	begin
							fwrite_in := False;
		        end;
					$91:
					//  0x90-0x95  : DAC Stream Control Write
					//  Set Stream Data:
		      	begin
							fwrite_in := False;
		        end;
					$92:
					//  0x90-0x95  : DAC Stream Control Write
					//  Set Stream Frequency:
		      	begin
							fwrite_in := False;
		        end;
					$93:
					//  0x90-0x95  : DAC Stream Control Write
					//  Start Stream:
		      	begin
							fwrite_in := False;
		        end;
					$94:
					//  0x90-0x95  : DAC Stream Control Write
					//  Stop Stream:
		      	begin
							fwrite_in := False;
		        end;
					$95:
					//  0x90-0x95  : DAC Stream Control Write
					//  Start Stream (fast call):
		      	begin
							fwrite_in := False;
		        end;

					$a0:
					//  0xA0 aa dd : AY8910, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
		        end;

					$b0:
					//  0xB0 aa dd : RF5C68, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
							fwrite_in := False;
		        end;
					$b1:
					//  0xB1 aa dd : RF5C164, write value dd to register aa
		      	begin
							regaddr := FileBuf[rptr+1];
							regdata := FileBuf[rptr+2];
							fwrite_in := False;
		        end;

					$b2:
					//  0xB2 ad dd : PWM, write value ddd to register a (d is MSB, dd is LSB)
		      	begin
							regaddr := (FileBuf[rptr+1] and $f0) shr 4;
							regdata := ((FileBuf[rptr+1] and $0f) shl 8) or FileBuf[rptr+2];
							fwrite_in := False;
		        end;

					$c0:
					//  0xC0 aaaa dd : Sega PCM, write value dd to memory offset aaaa
		      	begin
							regaddr := PWORD(@FileBuf[rptr+1])^;
							regdata := FileBuf[rptr+3];
							fwrite_in := False;
		        end;

					$c1:
					//  0xC1 aaaa dd : RF5C68, write value dd to memory offset aaaa
		      	begin
							regaddr := PWORD(@FileBuf[rptr+1])^;
							regdata := FileBuf[rptr+3];
							fwrite_in := False;
		        end;

					$c2:
					//  0xC2 aaaa dd : RF5C164, write value dd to memory offset aaaa
		      	begin
							regaddr := PWORD(@FileBuf[rptr+1])^;
							regdata := FileBuf[rptr+3];
							fwrite_in := False;
		        end;

					$d0:
					//  0xD0 pp aa dd : YMF278B port pp, write value dd to register aa
		      	begin
							regaddr := (FileBuf[rptr+1] shl 8) or FileBuf[rptr+2];
							regdata := FileBuf[rptr+3];
		        end;

					$d1:
					//  0xD1 pp aa dd : YMF271 port pp, write value dd to register aa
		      	begin
							regaddr := (FileBuf[rptr+1] shl 8) or FileBuf[rptr+2];
							regdata := FileBuf[rptr+3];
		        end;

					$e0:
					//  0xE0 dddddddd : seek to offset dddddddd (Intel byte order) in PCM data bank
		      	begin
	          	dblk.dwReadPtr := PDWORD(@FileBuf[rptr+1])^;
	            fwrite_in := False;
		        end;

	        else
	        	Break;
		    end;
		    //
				Inc(rptr, offs);
  		end else
      begin
      	//
				cmd := $66;
  		end;

			//
      if (fwrite_in=True) and (reqno>=0) then
			begin
				conno := DeviceForm.ReqDevice[reqno].nNo;
				if conno>=0 then
				begin
					if DeviceForm.CnDevice[conno].nInfo<>DEVICE_NONE then
					begin
						//
           	nTh := DeviceForm.CnDevice[conno].nThread;
						case DeviceForm.CnDevice[conno].nInfo of
							DEVICE_DCSG:
								begin
									if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_DCSG_GG then
									begin
										//DCSG_GG→DCSG
										case regaddr of
											$0000:
												begin
													if (regdata and $90)=$90 then
													begin
														//減衰
														ch := (regdata shr 5) and 3;
														DevSts[conno].DcsgGg.Attenuation[ch] := regdata and $ff;
														if ((DevSts[conno].DcsgGg.byMask shr ch) and $11)=$00 then
														begin
															//消音
															regdata := regdata or $0f;
														end;
													end;
												end;
											$0001:
												begin
													for ch := 0 to 3 do
													begin
														if ((DevSts[conno].DcsgGg.byMask xor regdata) and ($11 shl ch))<>$00 then
														begin
															//減衰
															regaddr2 := $0000;
															regdata2 := DevSts[conno].DcsgGg.Attenuation[ch];
															if ((regdata shr ch) and $11)=$00 then
															begin
																//消音
																regdata2 := regdata2 or $0f;
															end;
															WriteBuf(nTh, conno, regaddr2, regdata2);
														end;
													end;
													DevSts[conno].DcsgGg.byMask := regdata and $ff;
													fwrite_in := False;
												end;
										end;
									end;
								end;
              DEVICE_DCSG_NGP:
              	begin
									if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_DCSG_NGP then
									begin
										//DCSG_NGP→DCSG_NGP
	                	case cmd of
                    	$30:
												regaddr := $0002;
                    	$50:
												regaddr := $0003;
                    end;
                  end;
                end;
							DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
								begin
	 								case DeviceForm.ReqDevice[reqno].nInfo of
	 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
											begin
												//OPNB/YM2610B→OPNA
												//  ADPCM-A/B削除
												case regaddr of
													$0010..$001f, $0100..$012f:
														fwrite_in := False;
												end;
											end;
									end;
								end;
							DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
								begin
	 								case DeviceForm.ReqDevice[reqno].nInfo of
										DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
										 	begin
											 	//OPNA→OPNB/YM2610B
												//  リズム/ADPCM削除
												case regaddr of
													$0010..$001f:
                          	begin
                            	if (byRhythmEnb=0) or (MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=False) then
                              begin
																//リズム削除
																fwrite_in := False
                              end;
                            end;
													$0100..$0110:
                          	begin
															//ADPCM削除
															fwrite_in := False
                            end;
												end;
											end;
	 									DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
											begin
											 	//OPNB/YM2610B→OPNB/YM2610B
                        //  RAM書き込みのアドレス変更
												case regaddr of
													$001e:
														regaddr := $0301;
													$0016:
														regaddr := $0302;
													$0017:
														regaddr := $0303;
													$001f:
														regaddr := $0308;
													$011f:
														begin
												 			regaddr := $030b;
															if True then
																fwrite_in := False;
														end;
												end;
											end;
									end;
								end;
						end;
						//
            if fwrite_in=True then
            begin
          		case DeviceForm.ReqDevice[reqno].nInfo of
								DEVICE_OPNA_RAM:
									begin
										DevSts[conno].Opna.Reg[regaddr] := regdata;
										case regaddr of
											$0101:
												begin
													case regdata and $03 of
														0, 2:
															begin
																//1bit/8bit, dram
															end;
														else
															begin
																//rom→8bit, dram
																regdata := (regdata and $fc) or $02;
															end;
													end;
												end;
										end;
									end;
								DEVICE_MSXAUDIO_RAM:
									begin
										DevSts[conno].Msxaudio.Reg[regaddr] := regdata;
										case regaddr of
											$0008:
												begin
													case regdata and $03 of
														0, 2:
															begin
																//256K/64K, dram
															end;
														else
															begin
																//rom→256K, dram
																regdata := regdata and $fc;
															end;
													end;
												end;
											$0009, $000b:
												begin
													if (DevSts[conno].Msxaudio.Reg[$0008] and $01)<>0 then
													begin
														//rom
														regdata2 := (DevSts[conno].Msxaudio.Reg[regaddr+1] shl 3) or ((regdata shr 5) and 7);
														regdata2 := regdata2 and $ff;
														WriteBuf(nTh, conno, regaddr, regdata2);
														//
														regdata := regdata shl 3;
														if regaddr=$000b then
															regdata := regdata or 7;
														regdata := regdata and $ff;
													end;
												end;
											$000a, $000c:
												begin
													if (DevSts[conno].Msxaudio.Reg[$0008] and $01)<>0 then
													begin
														//rom
														regdata := (regdata shl 3) or ((DevSts[conno].Msxaudio.Reg[regaddr-1] shr 5) and 7);
														regdata := regdata and $ff;
													end;
												end;
										end;
                  end;
              end;
							//
							att := MainForm.ThreadCri[nTh].nOpnFmAttenuation;
							if att<>0 then
							begin
								case DeviceForm.ReqDevice[reqno].nInfo of
									DEVICE_OPN, DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
									DEVICE_YM2610B_RAM, DEVICE_OPN2, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
										begin
											case regaddr of
												$0040, $0041, $0042, $0140, $0141, $0142,	//slot1
												$0044, $0045, $0046, $0144, $0145, $0146,	//slot3
												$0048, $0049, $004a, $0148, $0149, $014a,	//slot2
												$004c, $004d, $004e, $014c, $014d, $014e:	//slot4
													begin
														//fm, tl
														ch := ((regaddr shr 8) and 1)*3 + (regaddr and 3);
														slot := 1 + (((regaddr shr 1) and 2) or ((regaddr shr 3) and 1));
														DevSts[conno].Opna.wTl[ch][slot-1] := regdata;
														//
														alg := -1;
														case ch of
															0:	//ch1
																alg := DevSts[conno].Reg[$00b0] and $07;
															1:	//ch2
																alg := DevSts[conno].Reg[$00b1] and $07;
															2:	//ch3
																alg := DevSts[conno].Reg[$00b2] and $07;
															3:	//ch4
																alg := DevSts[conno].Reg[$01b0] and $07;
															4:	//ch5
																alg := DevSts[conno].Reg[$01b1] and $07;
															5:	//ch6
																alg := DevSts[conno].Reg[$01b2] and $07;
														end;
														//
														n := 0;
														case alg of
															0..3:
																if slot=4 then
																	n := 1;
															4:
																if (slot=2) or (slot=4) then
																	n := 1;
															5..6:
																if (slot=2) or (slot=3) or (slot=4) then
																	n := 1;
															7:
																n := 1;
														end;
														//
														if n<>0 then
														begin
															tl := regdata and $7f;
															Inc(tl, Round(att/TLSTEP_OPN));
															if tl<0 then
																tl := 0
															else
															if tl>$7f then
																tl := $7f;
															regdata := (regdata and $80) or tl;
														end;
													end;
												$00b0..$00b2, $01b0..$01b2:
													begin
														//fm, alg
														ch := ((regaddr shr 8) and 1)*3 + (regaddr and 3);
														if not ((MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True) and
															(DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPN2) and
//															(MainForm.ThreadCri[nTh].nOpnaOpn2PcmType=0) and
															((DevSts[conno].Opn2.byDacSelect and $80)<>0) and ((1+ch)=6)) then
														begin
															for i := 0 to 3 do
															begin
																//
																slot := 1 + (((i shl 1) and 2) or ((i shr 1) and 1));
																n := 0;
																case regdata and $07 of
																	0..3:
																		if slot=4 then
																			n := 1;
																	4:
																		if (slot=2) or (slot=4) then
																			n := 1;
																	5..6:
																		if (slot=2) or (slot=3) or (slot=4) then
																			n := 1;
																	7:
																		n := 1;
																end;
																//
																regaddr2 := i*4;
																if ch<3 then
																	Inc(regaddr2, $0040+ch)
																else
																	Inc(regaddr2, $0140+ch-3);
																regdata2 := DevSts[conno].Opna.wTl[ch][slot-1];
																if (regdata2 and $ff00)<>0 then
																	regdata2 := $00;
																if n<>0 then
																begin
																	tl := regdata2 and $7f;
																	Inc(tl, Round(att/TLSTEP_OPN));
																	if tl<0 then
																		tl := 0
																	else
																	if tl>$7f then
																		tl := $7f;
																	regdata2 := (regdata2 and $80) or tl;
																end;
																WriteBuf(nTh, conno, regaddr2, regdata2);
															end;
														end;
													end;
												else
													begin
														case DeviceForm.ReqDevice[reqno].nInfo of
															DEVICE_OPNA, DEVICE_OPNA_RAM,
															DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																begin
																	case regaddr of
																		$0011:
																			begin
																				//rhythm, rtl
																				tl := regdata and $3f;
																				Inc(tl, Round(-att/TLSTEP_OPN));
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$3f then
																					tl := $3f;
																				regdata := (regdata and $c0) or tl;
																			end;
																		$0018..$001d:
																			begin
																				//rhythm, itl
																				//※rtlで処理、rtlに一度も書き込みがないときはうまく動作しない
																			end;
																		$010b:
																			begin
																				//adpcm, level control
																				tl := Round(Power(10, -att/20) * regdata);
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$ff then
																					tl := $ff;
																				regdata := tl;
																			end;
																	end;
																end;
															DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
																begin
																	case regaddr of
																		$0101:
																			begin
																				//adpcm-a, atl
																				tl := regdata and $3f;
																				Inc(tl, Round(-att/TLSTEP_OPN));
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$3f then
																					tl := $3f;
																				regdata := (regdata and $c0) or tl;
																			end;
																		$0108..$010d:
																			begin
																				//adpcm-a, acl
																				//※atlで処理、atlに一度も書き込みがないときはうまく動作しない
																			end;
																		$001b:
																			begin
																				//adpcm-b, eg control
																				tl := Round(Power(10, -att/20) * regdata);
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$ff then
																					tl := $ff;
																				regdata := tl;
																			end;
																	end;
																end;
															DEVICE_OPN2:
																begin
																	case regaddr of
																		$002a:
																			begin
																				//pcm
																				tl := Round(Power(10, -att/20) * (Integer(regdata)-$80));
																				Inc(tl, $80);
																				if tl<0 then
																					tl := 0
																				else
																				if tl>$ff then
																					tl := $ff;
																				regdata := tl;
																			end;
																	end;
																end;
														end;
													end;
											end;
										end;
								end;
							end;
							//
							att := MainForm.ThreadCri[nTh].nOpmFmAttenuation;
							if att<>0 then
							begin
								case DeviceForm.ReqDevice[reqno].nInfo of
									DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
										begin
											case regaddr of
												$0060..$0067,	//slot1(m1)
												$0068..$006f,	//slot3(m2)
												$0070..$0077,	//slot2(c1)
												$0078..$007f:	//slot4(c2)
													begin
														//fm, tl
														ch := regaddr and 7;
														slot := 1 + (((regaddr shr 2) and 2) or ((regaddr shr 4) and 1));
														DevSts[conno].Opm.wTl[ch][slot-1] := regdata;
														//
														alg := DevSts[conno].Reg[$0020+ch] and $07;
														//
														n := 0;
														case alg of
															0..3:
																if slot=4 then
																	n := 1;
															4:
																if (slot=2) or (slot=4) then
																	n := 1;
															5..6:
																if (slot=2) or (slot=3) or (slot=4) then
																	n := 1;
															7:
																n := 1;
														end;
														//
														if n<>0 then
														begin
															tl := regdata and $7f;
															Inc(tl, Round(att/TLSTEP_OPM));
															if tl<0 then
																tl := 0
															else
															if tl>$7f then
																tl := $7f;
															regdata := (regdata and $80) or tl;
														end;
													end;
												$0020..$0027:
													begin
														//fm, alg
														ch := regaddr and 7;
														//
														for i := 0 to 3 do
														begin
															//
															slot := 1 + (((i shl 1) and 2) or ((i shr 1) and 1));
															n := 0;
															case regdata and $07 of
																0..3:
																	if slot=4 then
																		n := 1;
																4:
																	if (slot=2) or (slot=4) then
																		n := 1;
																5..6:
																	if (slot=2) or (slot=3) or (slot=4) then
																		n := 1;
																7:
																	n := 1;
															end;
															//
															regaddr2 := $0060+i*8+ch;
															regdata2 := DevSts[conno].Opm.wTl[ch][slot-1];
															if (regdata2 and $ff00)<>0 then
																regdata2 := $00;
															if n<>0 then
															begin
																tl := regdata2 and $7f;
																Inc(tl, Round(att/TLSTEP_OPM));
																if tl<0 then
																	tl := 0
																else
																if tl>$7f then
																	tl := $7f;
																regdata2 := (regdata2 and $80) or tl;
															end;
															WriteBuf(nTh, conno, regaddr2, regdata2);
														end;
													end;
											end;
										end;
								end;
							end;
							//
							att := MainForm.ThreadCri[nTh].nGa20Attenuation;
							if att<>0 then
							begin
								if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_GA20 then
								begin
									if (regaddr=$0108) and (regdata<>$00) then
									begin
										tl := Round(Power(10, -att/20) * (Integer(regdata)-$80));
										Inc(tl, $80);
										if tl<$01 then
											tl := $01
										else
										if tl>$ff then
											tl := $ff;
										regdata := tl;
									end;
								end;
							end;
            end;
						//入力マスク
						if (fwrite_in=True) and (MaskReg(conno, DeviceForm.ReqDevice[reqno].nInfo, regaddr, @regdata)=True) then
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
											bStartSkip := False;
										end;
									end;
							end;
							//
							if (MainForm.ThreadCri[nTh].bOpnaOpn2Pcm=True) and (DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPN2) then
							begin
								case MainForm.ThreadCri[nTh].nOpnaOpn2PcmType of
									0:
										begin
											//fm
											case DeviceForm.CnDevice[conno].nInfo of
												DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
												DEVICE_YM2610B_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
													begin
														//PCM→FM変換
														case regaddr of
															$002a:	//dac data
																begin
																	tlind0 := -1;
																	tlind1 := -1;
																	tlind2 := -1;
																	j := DevSts[conno].Reg[$014a] and $7f;
																	k := DevSts[conno].Reg[$014e] and $7f;
																	dmin := 1 shl 15;
																	for i := 0 to nOpnTl2PcmLen-1 do
																	begin
																		n := OpnTl2Pcm[i];
																		d := Abs((Integer(regdata)-$80)*32-(n+OpnTl2Pcm[j]+OpnTl2Pcm[k] - nOpnTl2Pcm0));
																		if d<dmin then
																		begin
																			dmin := d;
																			if n>0 then
																				tlind0 := i
																			else
																				tlind0 := $7f;
																			tlind1 := -1;
																			tlind2 := -1;
																		end;
																	end;
																	//
																	i := DevSts[conno].Reg[$0146] and $7f;
																	k := DevSts[conno].Reg[$014e] and $7f;
																	for j := 0 to nOpnTl2PcmLen-1 do
																	begin
																		n := OpnTl2Pcm[j];
																		d := Abs((Integer(regdata)-$80)*32-(OpnTl2Pcm[i]+n+OpnTl2Pcm[k] - nOpnTl2Pcm0));
																		if d<dmin then
																		begin
																			dmin := d;
																			tlind0 := -1;
																			if n>0 then
																				tlind1 := j
																			else
																				tlind1 := $7f;
																			tlind2 := -1;
																		end;
																	end;
																	//
																	i := DevSts[conno].Reg[$0146] and $7f;
																	j := DevSts[conno].Reg[$014a] and $7f;
																	for k := 0 to nOpnTl2PcmLen-1 do
																	begin
																		n := OpnTl2Pcm[k];
																		d := Abs((Integer(regdata)-$80)*32-(OpnTl2Pcm[i]+OpnTl2Pcm[j]+n - nOpnTl2Pcm0));
																		if d<dmin then
																		begin
																			dmin := d;
																			tlind0 := -1;
																			tlind1 := -1;
																			if n>0 then
																				tlind2 := k
																			else
																				tlind2 := $7f;
																		end;
																	end;
																	//
																	if (tlind0>=0) {and (tlind0<>(DevSts[conno].Reg[$0146] and $7f))} then
																	begin
																		regaddr := $0146;	//s3, tl
																		regdata := tlind0;
																	end else
																	if (tlind1>=0) {and (tlind1<>(DevSts[conno].Reg[$014a] and $7f))} then
																	begin
																		regaddr := $014a;	//s2, tl
																		regdata := tlind1;
																	end else
																	if (tlind2>=0) {and (tlind2<>(DevSts[conno].Reg[$014e] and $7f))} then
																	begin
																		regaddr := $014e;	//s4, tl
																		regdata := tlind2;
																	end else
																		fwrite_out := False;
																end;
															$002b:	//dac select
																begin
																	if ((regdata xor DevSts[conno].Opn2.byDacSelect) and $80)<>0 then
																	begin
																		if (regdata and $80)=0 then
																		begin
																			//PCM→FM
																			//※音色を再設定しないといけない
																			WriteBuf(nTh, conno, $0028, $00 or 6);	//slot/ch.
																		end else
																		begin
																			//FM→PCM
																			WriteBuf(nTh, conno, $0142, $1f);	//s1, tl
																			WriteBuf(nTh, conno, $0146, $7f);	//s3, tl
																			WriteBuf(nTh, conno, $014a, $7f);	//s2, tl
																			WriteBuf(nTh, conno, $014e, $7f);	//s4, tl
																			WriteBuf(nTh, conno, $0152, $1f);	//s1, ks/ar
																			WriteBuf(nTh, conno, $0156, $1f);	//s3, ks/ar
																			WriteBuf(nTh, conno, $015a, $1f);	//s2, ks/ar
																			WriteBuf(nTh, conno, $015e, $1f);	//s4, ks/ar
																			WriteBuf(nTh, conno, $0162, $00);	//s1, amon/dr
																			WriteBuf(nTh, conno, $0166, $00);	//s3, amon/dr
																			WriteBuf(nTh, conno, $016a, $00);	//s2, amon/dr
																			WriteBuf(nTh, conno, $016e, $00);	//s4, amon/dr
																			WriteBuf(nTh, conno, $0172, $00);	//s1, sr
																			WriteBuf(nTh, conno, $0176, $00);	//s3, sr
																			WriteBuf(nTh, conno, $017a, $00);	//s2, sr
																			WriteBuf(nTh, conno, $017e, $00);	//s4, sr
																			WriteBuf(nTh, conno, $0182, $00);	//s1, sl/rr
																			WriteBuf(nTh, conno, $0186, $0f);	//s3, sl/rr
																			WriteBuf(nTh, conno, $018a, $0f);	//s2, sl/rr
																			WriteBuf(nTh, conno, $018e, $0f);	//s4, sl/rr
																			WriteBuf(nTh, conno, $0192, $00);	//s1, ssg-eg
																			WriteBuf(nTh, conno, $0196, $00);	//s3, ssg-eg
																			WriteBuf(nTh, conno, $019a, $00);	//s2, ssg-eg
																			WriteBuf(nTh, conno, $019e, $00);	//s4, ssg-eg
																			WriteBuf(nTh, conno, $0132, $02);	//s1, dt/multi
																			WriteBuf(nTh, conno, $0136, (0 shl 4) or $01);	//s3, dt/multi
																			WriteBuf(nTh, conno, $013a, (0 shl 4) or $01);	//s2, dt/multi
																			WriteBuf(nTh, conno, $013e, (0 shl 4) or $01);	//s4, dt/multi
																			WriteBuf(nTh, conno, $01a6, (0 shl 3) or 0);	//block/fnum2
																			WriteBuf(nTh, conno, $01a2, $10);	//fnum1
																			WriteBuf(nTh, conno, $01b2, (7 shl 3) or 5);	//fb/connect
																			WriteBuf(nTh, conno, $0028, $f0 or 6);	//slot/ch.
																		end;
																	end;
																	DevSts[conno].Opn2.byDacSelect := regdata;
																	fwrite_out := False;
																end;
															$0028:	//slot/ch.
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																	begin
																		ch := regdata and $7;
																		if ch<4 then
																			Inc(ch);
																		if ch=6 then
																			fwrite_out := False;
																	end;
																end;
															$0142, $0146, $014a, $014e,	//s1/s3/s2/s4, tl
															$0152, $0156, $015a, $015e,	//s1/s3/s2/s4, ks/ar
															$0162, $0166, $016a, $016e,	//s1/s3/s2/s4, amon/dr
															$0172, $0176, $017a, $017e,	//s1/s3/s2/s4, sr
															$0182, $0186, $018a, $018e,	//s1/s3/s2/s4, sl/rr
															$0192, $0196, $019a, $019e,	//s1/s3/s2/s4, ssg-eg
															$0132, $0136, $013a, $013e,	//s1/s3/s2/s4, dt/multi
															$01a6,	//block/fnum2
															$01a2,	//fnum1
															$01b2:	//fb/connect
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																		fwrite_out := False;
																end;
															$01b6:	//pan/ams/pms
																begin
																	DevSts[conno].Opn2.byDacPan := regdata;
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																		regdata := regdata and $c0;	//ams=0/pms=0
																end;
														end;
													end;
											end;
										end;
									1:
										begin
											//ssg
											case DeviceForm.CnDevice[conno].nInfo of
												DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPNB_RAM,
												DEVICE_YM2610B_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
													begin
														//PCM→SSG変換
														case regaddr of
															$002a:	//dac data
																begin
																	tlind0 := -1;
																	tlind1 := -1;
																	tlind2 := -1;
																	if (DevSts[conno].Opn2.byDacPan and $c0)<>0 then
																	begin
																		//
																		case DeviceForm.CnDevice[conno].nInfo of
																			DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
																				rssg := Power(10, 5/20);
																			else
																				rssg := Power(10, 14/20);
																		end;
																		//
																		j := DevSts[conno].Reg[$0008] and $f;
																		k := DevSts[conno].Reg[$000a] and $f;
																		dmin := 1 shl 15;
																		for i := 0 to nSsgVol2PcmLen-1 do
																		begin
																			n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																			d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																			if d<dmin then
																			begin
																				dmin := d;
																				tlind0 := i;
																				tlind1 := -1;
																				tlind2 := -1;
																			end;
																		end;
																		//
																		i := DevSts[conno].Reg[$0009] and $f;
																		k := DevSts[conno].Reg[$000a] and $f;
																		for j := 0 to nSsgVol2PcmLen-1 do
																		begin
																			n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																			d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																			if d<dmin then
																			begin
																				dmin := d;
																				tlind0 := -1;
																				tlind1 := j;
																				tlind2 := -1;
																			end;
																		end;
																		//
																		i := DevSts[conno].Reg[$0009] and $f;
																		j := DevSts[conno].Reg[$0008] and $f;
																		for k := 0 to nSsgVol2PcmLen-1 do
																		begin
																			n := SsgVol2Pcm[i]+SsgVol2Pcm[j]+SsgVol2Pcm[k] - nSsgVol2Pcm0;
																			d := Abs((Integer(regdata)-$80)*32 - Round(rssg*n));
																			if d<dmin then
																			begin
																				dmin := d;
																				tlind0 := -1;
																				tlind1 := -1;
																				tlind2 := k;
																			end;
																		end;
																	end;
																	//
																	if (tlind0>=0) {and (tlind0<>(DevSts[conno].Reg[$0009] and $f))} then
																	begin
																		regaddr := $0009;	//s3, tl
																		regdata := tlind0;
																	end else
																	if (tlind1>=0) {and (tlind1<>(DevSts[conno].Reg[$0008] and $f))} then
																	begin
																		regaddr := $0008;	//s2, tl
																		regdata := tlind1;
																	end else
																	if (tlind2>=0) {and (tlind2<>(DevSts[conno].Reg[$000a] and $f))} then
																	begin
																		regaddr := $000a;	//s4, tl
																		regdata := tlind2;
																	end else
																		fwrite_out := False;
																end;
															$002b:	//dac select
																begin
																	if ((regdata xor DevSts[conno].Opn2.byDacSelect) and $80)<>0 then
																	begin
																		if (regdata and $80)=0 then
																		begin
																			//PCM→FM
																			//※音色を再設定しないといけない
																		end else
																		begin
																			//FM→PCM
																			WriteBuf(nTh, conno, $0000, $00);
																			WriteBuf(nTh, conno, $0001, $00);
																			WriteBuf(nTh, conno, $0002, $00);
																			WriteBuf(nTh, conno, $0003, $00);
																			WriteBuf(nTh, conno, $0004, $00);
																			WriteBuf(nTh, conno, $0005, $00);
																			WriteBuf(nTh, conno, $0009, $00);	//s3, tl
																			WriteBuf(nTh, conno, $0008, $00);	//s2, tl
																			WriteBuf(nTh, conno, $000a, $00);	//s4, tl
																			WriteBuf(nTh, conno, $0007, $3f);
																		end;
																	end;
																	DevSts[conno].Opn2.byDacSelect := regdata;
																	fwrite_out := False;
																end;
															$0028:	//slot/ch.
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																	begin
																		ch := regdata and $7;
																		if ch<4 then
																			Inc(ch);
																		if ch=6 then
																			fwrite_out := False;
																	end;
																end;
															$0142, $0146, $014a, $014e,	//s1/s3/s2/s4, tl
															$0152, $0156, $015a, $015e,	//s1/s3/s2/s4, ks/ar
															$0162, $0166, $016a, $016e,	//s1/s3/s2/s4, amon/dr
															$0172, $0176, $017a, $017e,	//s1/s3/s2/s4, sr
															$0182, $0186, $018a, $018e,	//s1/s3/s2/s4, sl/rr
															$0192, $0196, $019a, $019e,	//s1/s3/s2/s4, ssg-eg
															$0132, $0136, $013a, $013e,	//s1/s3/s2/s4, dt/multi
															$01a6,	//block/fnum2
															$01a2,	//fnum1
															$01b2:	//fb/connect
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																		fwrite_out := False;
																end;
															$01b6:	//pan/ams/pms
																begin
																	DevSts[conno].Opn2.byDacPan := regdata;
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																		fwrite_out := False;
																end;
														end;
													end;
											end;
										end;
									2:
										begin
											//adpcm
											case DeviceForm.CnDevice[conno].nInfo of
												DEVICE_OPNA, DEVICE_OPNA_RAM:
													begin
														//PCM→ADPCM変換
														case regaddr of
															$002a:	//dac data
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																	begin
																		//レベルコントロール
																		regaddr := $010b;
																	end else
																		fwrite_out := False;
																end;
															$002b:	//dac select
																begin
																	DevSts[conno].Opn2.byDacSelect := regdata;
																	fwrite_out := False;
																end;
															$01b6:	//pan/ams/pms
																begin
																	DevSts[conno].Opn2.byDacPan := regdata;
																	//パン
																	regaddr := $0101;
																	regdata := (regdata and $c0) or $02 or (DevSts[conno].Reg[regaddr] and $0c);
																end;
														end;
													end;
											end;
										end;
									3:
										begin
											//pcm
											case DeviceForm.CnDevice[conno].nInfo of
												DEVICE_OPNA, DEVICE_OPNA_RAM:
													begin
														//PCM→PCM変換
														case regaddr of
															$002a:	//dac data
																begin
																	if (DevSts[conno].Opn2.byDacSelect and $80)<>0 then
																	begin
																		//DACデータ
																		regaddr := $010e;
																		regdata := regdata xor $80;
																	end else
																		fwrite_out := False;
																end;
															$002b:	//dac select
																begin
																	DevSts[conno].Opn2.byDacSelect := regdata;
																	fwrite_out := False;
																end;
															$01b6:	//pan/ams/pms
																begin
																	DevSts[conno].Opn2.byDacPan := regdata;
																	//パン
																	regaddr := $0101;
																	regdata := (regdata and $c0) or $02 or (DevSts[conno].Reg[regaddr] and $0c);
																end;
														end;
													end;
											end;
										end;
								end;
							end;
							//
							case DeviceForm.CnDevice[conno].nInfo of
								DEVICE_OPP, DEVICE_OPZ:
									begin
										if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPM then
										begin
											//アドレス変更
											if regaddr=$0001 then
											begin
												//TESTレジスタ
                        //※OPP/OPZを調べたら修正
                        regaddr := $ffff;
												fwrite_out := False;
											end;
										end;
									end;
								DEVICE_OPN:
									begin
										if DeviceForm.ReqDevice[reqno].nInfo=DEVICE_OPNB_RAM then
										begin
                      //CH3@OPNB=CH5@OPNA→CH1@OPN
		 							 		//  チャンネル変更
									 		case regaddr of
										 		$0131, $0141, $0151, $0161, $0171, $0181, $0191,  //slot1
										 		$0135, $0145, $0155, $0165, $0175, $0185, $0195,	//slot3
										 		$0139, $0149, $0159, $0169, $0179, $0189, $0199,	//slot2
										 		$013d, $014d, $015d, $016d, $017d, $018d, $019d,	//slot4
											 	$01a1, $01a5, $01b1, $01b5:
										 			begin
											 			//
												 		Dec(regaddr, $0101);
											   	end;
												$0028:
											  	begin
  			   					   			//
														if (regdata and $07)=$05 then
						   					   		Dec(regdata, $05);
											  	end;
				  			  	  end;
							   	  end;
								  end;
								DEVICE_OPNB_RAM, DEVICE_YM2610B_RAM:
							  	begin
		 								case DeviceForm.ReqDevice[reqno].nInfo of
									  	DEVICE_OPN:
				  							begin
				 	  					 		//CH1@OPN→CH5@OPNA=CH3@OPNB
  		                    //  チャンネル変更
      		                //  ※YM2610Bは変更しなくて良い
										   		case regaddr of
											   		$0030, $0040, $0050, $0060, $0070, $0080, $0090,  //slot1
												 		$0034, $0044, $0054, $0064, $0074, $0084, $0094,	//slot3
  								   				$0038, $0048, $0058, $0068, $0078, $0088, $0098,	//slot2
												 		$003c, $004c, $005c, $006c, $007c, $008c, $009c,	//slot4
				  								 	$00a0, $00a4, $00b0, $00b4:
											   			begin
						  					   			//
													   		Inc(regaddr, $0101);
									  			   	end;
														$0028:
													  	begin
  			   					   					//
																if (regdata and $07)=$00 then
								   					   		Inc(regdata, $05);
													  	end;
						  			  	  end;
									   	  end;
											DEVICE_OPNA, DEVICE_OPNA_RAM, DEVICE_OPN3L, DEVICE_OPL3NL_OPN:
											 	begin
												 	//OPNA→OPNB/YM2610B
													//  リズム→ADPCMA変換
  	                    	if (byRhythmEnb<>0) and (MainForm.ThreadCri[nTh].bOpnbOpnaRhythm=True) then
     	                    begin
														case regaddr of
															$0010..$001f:
                               	begin
                                  if regaddr=$0010 then
                                   	regdata := regdata and ($c0 or byRhythmEnb);
               	                	Inc(regaddr, $0100-$0010);
                                end;
                            end;
													end;
												end;
                    end;
						  	  end;
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
						  end;
							//出力マスク
							if (fwrite_out=True) and (MaskReg(conno, DeviceForm.CnDevice[conno].nInfo, regaddr, @regdata)=True) then
							begin
								//書き込み
								bStartSkip := False;
								WriteBuf(nTh, conno, regaddr, regdata);
							end;
						end;
					end;
				end;
			end;

	  end;
  end;

  //
      tm := sync2 div (nTimerInfo2*FREQ_SYNC);
      if (tm<>endtime) and (Terminated=False) then
      begin
       	endtime := tm;
				PostMessage(MainForm.Handle, WM_THREAD_UPDATE_ENDTIME, endtime and $ffffffff, 0);
      end;

	//
  Result := ST_THREAD_END;
end;

end.

