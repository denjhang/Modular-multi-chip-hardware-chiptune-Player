unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Spin, Math, Buttons, IniFiles, StrUtils,
  ComCtrls, Unit1, Grids, ValEdit, Types, Menus, RichEdit, ScktComp, CommCtrl;

type
 	TCs = record
    //
    nIf, nIfNum: Integer;
    dwDevAddr: DWORD;
    nCs, nIndex, nAddr: Integer;
    nEzusb, nPic, nFtdi: Integer;
    //
		Chk: TCheckBox;
 		DevCB: TComboBox;
		ClkCB: TComboBox;
    DelBtn: TButton;
	end;

type
	TEzusbTab = record
    //
    nDevIndex: Integer;
    AutoChk: TCheckBox;
    DevCb: TComboBox;
    ResetBtn: TSpeedButton;
  end;

type
	TPicTab = record
    //
    nDevIndex: Integer;
    AutoChk: TCheckBox;
    DevCb: TComboBox;
    ResetBtn: TSpeedButton;
  end;

type
	TFtdiTab = record
    //
    nDevIndex: Integer;
    AutoChk: TCheckBox;
    DevCb: TComboBox;
    ResetBtn: TSpeedButton;
  end;

type
  TDeviceForm = class(TForm)
    PageControl1: TPageControl;
    TabSheet2: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet1: TTabSheet;
    Ezusb0ResetBtn: TSpeedButton;
    Ezusb0Cs0Chk: TCheckBox;
    Ezusb0Cs2Chk: TCheckBox;
    Ezusb0Cs4Chk: TCheckBox;
    Ezusb0Cs6Chk: TCheckBox;
    Ezusb0Cs6ClkCB: TComboBox;
    Ezusb0Cs4ClkCB: TComboBox;
    Ezusb0Cs2ClkCB: TComboBox;
    Ezusb0Cs0ClkCB: TComboBox;
    Ezusb0Cs0DelBtn: TButton;
    Ezusb0Cs2DelBtn: TButton;
    Ezusb0Cs4DelBtn: TButton;
    Ezusb0Cs6DelBtn: TButton;
    Ezusb0Cs6DevCB: TComboBox;
    Ezusb0Cs4DevCB: TComboBox;
    Ezusb0Cs2DevCB: TComboBox;
    Ezusb0Cs0DevCB: TComboBox;
    Ezusb0Cs7ClkCB: TComboBox;
    Ezusb0Cs5ClkCB: TComboBox;
    Ezusb0Cs3ClkCB: TComboBox;
    Ezusb0Cs1ClkCB: TComboBox;
    Ezusb0Cs1DelBtn: TButton;
    Ezusb0Cs3DelBtn: TButton;
    Ezusb0Cs5DelBtn: TButton;
    Ezusb0Cs7DelBtn: TButton;
    Ezusb0Cs7DevCB: TComboBox;
    Ezusb0Cs5DevCB: TComboBox;
    Ezusb0Cs3DevCB: TComboBox;
    Ezusb0Cs1DevCB: TComboBox;
    Ezusb0Cs1Chk: TCheckBox;
    Ezusb0Cs3Chk: TCheckBox;
    Ezusb0Cs5Chk: TCheckBox;
    Ezusb0Cs7Chk: TCheckBox;
    IntCs0Chk: TCheckBox;
    IntCs2Chk: TCheckBox;
    IntCs4Chk: TCheckBox;
    IntCs1Chk: TCheckBox;
    IntCs3Chk: TCheckBox;
    IntCs5Chk: TCheckBox;
    IntCs7Chk: TCheckBox;
    IntCs6ClkCB: TComboBox;
    IntCs4ClkCB: TComboBox;
    IntCs2ClkCB: TComboBox;
    IntCs0ClkCB: TComboBox;
    IntCs6DevCB: TComboBox;
    IntCs4DevCB: TComboBox;
    IntCs2DevCB: TComboBox;
    IntCs0DevCB: TComboBox;
    IntCs7ClkCB: TComboBox;
    IntCs5ClkCB: TComboBox;
    IntCs3ClkCB: TComboBox;
    IntCs1ClkCB: TComboBox;
    IntCs7DevCB: TComboBox;
    IntCs5DevCB: TComboBox;
    IntCs3DevCB: TComboBox;
    IntCs1DevCB: TComboBox;
    TabSheet6: TTabSheet;
    ValueListEditor: TValueListEditor;
    IntCs6Chk: TCheckBox;
    TabSheet3: TTabSheet;
    Ezusb0DevCB: TComboBox;
    Ezusb1DevCB: TComboBox;
    TabSheet8: TTabSheet;
    KeyListBox: TListBox;
    DeviceListBox: TListBox;
    DebugEdit: TRichEdit;
    LogEdit: TRichEdit;
    Ezusb0AutoChk: TCheckBox;
    Ezusb1AutoChk: TCheckBox;
    TabSheet9: TTabSheet;
    TabSheet10: TTabSheet;
    Pic0ResetBtn: TSpeedButton;
    Pic0DevCB: TComboBox;
    Pic0AutoChk: TCheckBox;
    OpenDlg: TOpenDialog;
    Ezusb1ResetBtn: TSpeedButton;
    Ezusb1Cs0ClkCB: TComboBox;
    Ezusb1Cs0DelBtn: TButton;
    Ezusb1Cs0DevCB: TComboBox;
    Ezusb1Cs0Chk: TCheckBox;
    Ezusb1Cs1Chk: TCheckBox;
    Ezusb1Cs1DevCB: TComboBox;
    Ezusb1Cs1ClkCB: TComboBox;
    Ezusb1Cs1DelBtn: TButton;
    Ezusb1Cs2DelBtn: TButton;
    Ezusb1Cs2ClkCB: TComboBox;
    Ezusb1Cs2DevCB: TComboBox;
    Ezusb1Cs2Chk: TCheckBox;
    Ezusb1Cs3Chk: TCheckBox;
    Ezusb1Cs3DevCB: TComboBox;
    Ezusb1Cs3ClkCB: TComboBox;
    Ezusb1Cs3DelBtn: TButton;
    Ezusb1Cs4DelBtn: TButton;
    Ezusb1Cs4ClkCB: TComboBox;
    Ezusb1Cs4DevCB: TComboBox;
    Ezusb1Cs4Chk: TCheckBox;
    Ezusb1Cs5Chk: TCheckBox;
    Ezusb1Cs5DevCB: TComboBox;
    Ezusb1Cs5ClkCB: TComboBox;
    Ezusb1Cs5DelBtn: TButton;
    Ezusb1Cs6DelBtn: TButton;
    Ezusb1Cs6ClkCB: TComboBox;
    Ezusb1Cs6DevCB: TComboBox;
    Ezusb1Cs6Chk: TCheckBox;
    Ezusb1Cs7Chk: TCheckBox;
    Ezusb1Cs7DevCB: TComboBox;
    Ezusb1Cs7ClkCB: TComboBox;
    Ezusb1Cs7DelBtn: TButton;
    Pic1ResetBtn: TSpeedButton;
    Pic1DevCB: TComboBox;
    Pic1AutoChk: TCheckBox;
    Pic0Cs0Chk: TCheckBox;
    Pic0Cs0DevCB: TComboBox;
    Pic0Cs0ClkCB: TComboBox;
    Pic0Cs0DelBtn: TButton;
    Pic0Cs1Chk: TCheckBox;
    Pic0Cs1DevCB: TComboBox;
    Pic0Cs1ClkCB: TComboBox;
    Pic0Cs1DelBtn: TButton;
    Pic1Cs0Chk: TCheckBox;
    Pic1Cs0DevCB: TComboBox;
    Pic1Cs0ClkCB: TComboBox;
    Pic1Cs0DelBtn: TButton;
    Pic1Cs1Chk: TCheckBox;
    Pic1Cs1DevCB: TComboBox;
    Pic1Cs1ClkCB: TComboBox;
    Pic1Cs1DelBtn: TButton;
    Pic0Cs2Chk: TCheckBox;
    Pic0Cs4Chk: TCheckBox;
    Pic0Cs6Chk: TCheckBox;
    Pic0Cs6ClkCB: TComboBox;
    Pic0Cs4ClkCB: TComboBox;
    Pic0Cs2ClkCB: TComboBox;
    Pic0Cs2DelBtn: TButton;
    Pic0Cs4DelBtn: TButton;
    Pic0Cs6DelBtn: TButton;
    Pic0Cs6DevCB: TComboBox;
    Pic0Cs4DevCB: TComboBox;
    Pic0Cs2DevCB: TComboBox;
    Pic0Cs7ClkCB: TComboBox;
    Pic0Cs5ClkCB: TComboBox;                   
    Pic0Cs3ClkCB: TComboBox;
    Pic0Cs3DelBtn: TButton;
    Pic0Cs5DelBtn: TButton;
    Pic0Cs7DelBtn: TButton;
    Pic0Cs7DevCB: TComboBox;
    Pic0Cs5DevCB: TComboBox;
    Pic0Cs3DevCB: TComboBox;
    Pic0Cs3Chk: TCheckBox;
    Pic0Cs5Chk: TCheckBox;
    Pic0Cs7Chk: TCheckBox;
    Pic1Cs2Chk: TCheckBox;
    Pic1Cs4Chk: TCheckBox;
    Pic1Cs6Chk: TCheckBox;
    Pic1Cs6ClkCB: TComboBox;
    Pic1Cs4ClkCB: TComboBox;
    Pic1Cs2ClkCB: TComboBox;
    Pic1Cs2DelBtn: TButton;
    Pic1Cs4DelBtn: TButton;
    Pic1Cs6DelBtn: TButton;
    Pic1Cs6DevCB: TComboBox;
    Pic1Cs4DevCB: TComboBox;
    Pic1Cs2DevCB: TComboBox;
    Pic1Cs7ClkCB: TComboBox;
    Pic1Cs5ClkCB: TComboBox;
    Pic1Cs3ClkCB: TComboBox;
    Pic1Cs3DelBtn: TButton;
    Pic1Cs5DelBtn: TButton;
    Pic1Cs7DelBtn: TButton;
    Pic1Cs7DevCB: TComboBox;
    Pic1Cs5DevCB: TComboBox;
    Pic1Cs3DevCB: TComboBox;
    Pic1Cs3Chk: TCheckBox;
    Pic1Cs5Chk: TCheckBox;
    Pic1Cs7Chk: TCheckBox;
    TabSheet4: TTabSheet;
    TabSheet7: TTabSheet;
    Ftdi0ResetBtn: TSpeedButton;
    Ftdi0DevCB: TComboBox;
    Ftdi0AutoChk: TCheckBox;
    Ftdi0Cs0Chk: TCheckBox;
    Ftdi0Cs0DevCB: TComboBox;
    Ftdi0Cs0ClkCB: TComboBox;
    Ftdi0Cs0DelBtn: TButton;
    Ftdi0Cs1Chk: TCheckBox;
    Ftdi0Cs1DevCB: TComboBox;
    Ftdi0Cs1ClkCB: TComboBox;
    Ftdi0Cs1DelBtn: TButton;
    Ftdi0Cs2Chk: TCheckBox;
    Ftdi0Cs4Chk: TCheckBox;
    Ftdi0Cs6Chk: TCheckBox;
    Ftdi0Cs6ClkCB: TComboBox;
    Ftdi0Cs4ClkCB: TComboBox;
    Ftdi0Cs2ClkCB: TComboBox;
    Ftdi0Cs2DelBtn: TButton;
    Ftdi0Cs4DelBtn: TButton;
    Ftdi0Cs6DelBtn: TButton;
    Ftdi0Cs6DevCB: TComboBox;
    Ftdi0Cs4DevCB: TComboBox;
    Ftdi0Cs2DevCB: TComboBox;
    Ftdi0Cs7ClkCB: TComboBox;
    Ftdi0Cs5ClkCB: TComboBox;
    Ftdi0Cs3ClkCB: TComboBox;
    Ftdi0Cs3DelBtn: TButton;
    Ftdi0Cs5DelBtn: TButton;
    Ftdi0Cs7DelBtn: TButton;
    Ftdi0Cs7DevCB: TComboBox;
    Ftdi0Cs5DevCB: TComboBox;
    Ftdi0Cs3DevCB: TComboBox;
    Ftdi0Cs3Chk: TCheckBox;
    Ftdi0Cs5Chk: TCheckBox;
    Ftdi0Cs7Chk: TCheckBox;
    Ftdi1ResetBtn: TSpeedButton;
    Ftdi1DevCB: TComboBox;
    Ftdi1AutoChk: TCheckBox;
    Ftdi1Cs0Chk: TCheckBox;
    Ftdi1Cs0DevCB: TComboBox;
    Ftdi1Cs0ClkCB: TComboBox;
    Ftdi1Cs0DelBtn: TButton;
    Ftdi1Cs1Chk: TCheckBox;
    Ftdi1Cs1DevCB: TComboBox;
    Ftdi1Cs1ClkCB: TComboBox;
    Ftdi1Cs1DelBtn: TButton;
    Ftdi1Cs2Chk: TCheckBox;
    Ftdi1Cs4Chk: TCheckBox;
    Ftdi1Cs6Chk: TCheckBox;
    Ftdi1Cs6ClkCB: TComboBox;
    Ftdi1Cs4ClkCB: TComboBox;
    Ftdi1Cs2ClkCB: TComboBox;
    Ftdi1Cs2DelBtn: TButton;
    Ftdi1Cs4DelBtn: TButton;
    Ftdi1Cs6DelBtn: TButton;
    Ftdi1Cs6DevCB: TComboBox;
    Ftdi1Cs4DevCB: TComboBox;
    Ftdi1Cs2DevCB: TComboBox;
    Ftdi1Cs7ClkCB: TComboBox;
    Ftdi1Cs5ClkCB: TComboBox;
    Ftdi1Cs3ClkCB: TComboBox;
    Ftdi1Cs3DelBtn: TButton;
    Ftdi1Cs5DelBtn: TButton;
    Ftdi1Cs7DelBtn: TButton;
    Ftdi1Cs7DevCB: TComboBox;
    Ftdi1Cs5DevCB: TComboBox;
    Ftdi1Cs3DevCB: TComboBox;
    Ftdi1Cs3Chk: TCheckBox;
    Ftdi1Cs5Chk: TCheckBox;
    Ftdi1Cs7Chk: TCheckBox;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure FormCreate(Sender: TObject);
    procedure CsClkCBExit(Sender: TObject);
    procedure CsClkCBKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CsDelBtnClick(Sender: TObject);
    procedure CsDevCBChange(Sender: TObject);
    procedure EzusbResetBtnClick(Sender: TObject);
    procedure CsClkCBChange(Sender: TObject);
    procedure EzusbDevCBChange(Sender: TObject);
    procedure EzusbAutoChkClick(Sender: TObject);
    procedure ValueListEditorEditButtonClick(Sender: TObject);
    procedure ValueListEditorDblClick(Sender: TObject);
    procedure ValueListEditorMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure PicResetBtnClick(Sender: TObject);
    procedure PicAutoChkClick(Sender: TObject);
    procedure PicDevCBChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FtdiAutoChkClick(Sender: TObject);
    procedure FtdiDevCBChange(Sender: TObject);
    procedure FtdiResetBtnClick(Sender: TObject);
  private
    { Private 宣言 }
    procedure SetKey(s: String; val: String);
		procedure SetDeviceForm(n: Integer; s, clock: String);
		function FindPciDevice(id: String): String;
		function GetDeviceAddr(s: String): Integer;
		function GetDeviceStr(n: Integer): String;
		function GetDeviceInfo(s: String): Integer;
		function GetDeviceRatio(s: String; n: Integer): Extended;
		function GetDeviceSel(s: String; n: Integer): String;
		function GetDeviceCtl(s: String): String;
		function AddOpl3(devaddr, base: DWORD): Integer;
		function AddRomeo(devaddr, base: DWORD): Integer;
		function InitEzusb: Boolean;
		function ResetEzusb(n: Integer): Boolean;
		function InitPic: Boolean;
		function ResetPic(n: Integer): Boolean;
		function InitFtdi: Boolean;
		function ResetFtdi(n: Integer): Boolean;
  public
    { Public 宣言 }
  	Cs: array[0..CONNECT_DEVMAX-1] of TCs;
    EzusbTab: array[0..EZUSB_DEVMAX-1] of TEzusbTab;
    PicTab: array[0..PIC_DEVMAX-1] of TPicTab;
    FtdiTab: array[0..FTDI_DEVMAX-1] of TFtdiTab;
    Opl3: array[0..OPL3_DEVMAX-1]of TOpl3;
    Romeo: array[0..ROMEO_DEVMAX-1] of TRomeo;
    Ezusb: array[0..EZUSB_DEVMAX-1] of TEzusb;
    Pic: array[0..PIC_DEVMAX-1] of TPic;
    Ftdi: array[0..FTDI_DEVMAX-1] of TFtdi;
  	CnDevice: array[0..CONNECT_DEVMAX-1] of TConnectDevice;
    ReqDevice: array[0..REQUEST_DEVMAX-1] of TRequestDevice;
		procedure EnumDevice;
		procedure ClearReqDevice;
		procedure CloseEzusb;
		procedure ClosePic;
		procedure CloseFtdi;
    function GetInteger(s: String): Integer;
    function GetString(s: String): String;
    function GetPathString(s: String): String;
    function GetBool(s: String): Boolean;
    function GetIndex(s: String; rev: Boolean): Integer;
		function AddReqDevice(cmd: String; info: Integer; clk: Extended): Boolean;
		function GetEnumDevice: String;
		function AllocDevice(f: Boolean): Integer;
		function GetClockRatio: Extended;
  end;

var
  DeviceForm: TDeviceForm;

const
	//OPL3互換
	ID_DS1       = $000d1073;	//ymf724f
	ID_DS1L      = $000c1073;	//ymf740c, ※テストしていない
	ID_DS1S      = $00101073;	//ymf744b
	ID_DS1E      = $00121073;	//ymf754
	ID_SOLO1     = $1969125d;	//es1938s, ※es1941/es1946/es1969はテストしていない
  //ROMEO
  ID_ROMEO_DEV = $81216809;	//※テストしていない
	ID_ROMEO     = $21516809;
  //※テスト用
  ID_TEST      = $35808086;

const
	CLK_MIN = 1000000;
  CLK_MAX = 59999999;

implementation

{$R *.dfm}

procedure TDeviceForm.WMSysCommand(var Msg: TWMSysCommand);
begin
	//
  if (Msg.CmdType and $fff0)=SC_MINIMIZE then
  	//親ウィンドウを最小化させる
  	Application.Minimize
  else
  	inherited;
end;

function ClkCompare(List: TStringList; Index1, Index2: Integer): Integer;
begin
	//
	Result := CompareValue(StrToFloat(List.Strings[Index1]), StrToFloat(List.Strings[Index2]));
end;

procedure TDeviceForm.SetKey(s: String; val: String);
	var
  	key: String;
begin
	//
  key := KeyListBox.Items.Values[s];
  if key='' then
  	Exit;
  if val='' then
  	val := KeyListBox.Items.Values[s+'Def'];
  ValueListEditor.InsertRow(key, val, True);
end;

function TDeviceForm.GetInteger(s: String): Integer;
	var
  	key: String;
  	def: Integer;
begin
	//
  key := KeyListBox.Items.Values[s];
  def := StrToInt(KeyListBox.Items.Values[s+'Def']);
  Result := StrToIntDef(ValueListEditor.Strings.Values[key], def);
end;

function TDeviceForm.GetString(s: String): String;
	var
  	key: String;
    def: String;
begin
	//
  key := KeyListBox.Items.Values[s];
  def := KeyListBox.Items.Values[s+'Def'];
  Result := ValueListEditor.Strings.Values[key];
  if Result='' then
  	Result := def;
end;

function TDeviceForm.GetPathString(s: String): String;
	var
  	path: String;
begin
	//
	path := GetString(s);
	if AnsiPos('.\', path)=1 then
		path := ExpandUNCFileName(MainForm.ExeDllFolder + path);
	Result := path;
end;

function TDeviceForm.GetBool(s: String): Boolean;
	var
  	key: String;
    def: Boolean;
begin
	//
  key := KeyListBox.Items.Values[s];
  def := StrToBool(KeyListBox.Items.Values[s+'Def']);
  Result := StrToBoolDef(ValueListEditor.Strings.Values[key], def);
end;

function TDeviceForm.GetIndex(s: String; rev: Boolean): Integer;
	var
  	key, val: String;
    n: Integer;
begin
	//
  key := KeyListBox.Items.Values[s];
  val := ValueListEditor.Strings.Values[key];
	n := ValueListEditor.ItemProps[key].PickList.IndexOf(val);
  if n<0 then
  begin
  	val := KeyListBox.Items.Values[s+'Def'];
		n := ValueListEditor.ItemProps[key].PickList.IndexOf(val);
  end;
  if rev=True then
		n := (ValueListEditor.ItemProps[key].PickList.Count-1) - n;
  Result := n;
end;

type
	PLangAndCodepage = ^TLangAndCodepage;
 	TLangAndCodepage = packed record
	  wLanguage: Word;
	  wCodePage: Word;
  end;

procedure TDeviceForm.FormCreate(Sender: TObject);
	var
  	path, s, t, key: String;
	  ini: TIniFile;
    sl: TStringList;
    i, j, n, lim: Integer;
    key0, key1: Integer;
    dev: array[0..2] of String;
  var
		dwLibraryVer: DWORD;
  var
    Form: TRect;
    Visible: Boolean;
    clock: String;

  function GetFileVer(path: String): String;
	  var
	  	infsize, ver: Cardinal;
  	  infbuf: Pointer;
  		i, cbtrans, dwbytes: Cardinal;
	    lptrans: PLangAndCodepage;
  	  lpbuf: PChar;
  begin
		//
    Result := '';
	  infsize := GetFileVersionInfoSize(PChar(path), ver);
  	if infsize=0 then
    	Exit;

 		//
  	infbuf := nil;
   	try
 	  	//
      GetMem(infbuf, infsize);
 			if GetFileVersionInfo(PChar(path), 0, infsize, infbuf) then
  	  begin
 	  		if VerQueryValue(infbuf, '\VarFileInfo\Translation', Pointer(lptrans), cbtrans) then
    	  begin
 	    		//
    	  	for i := 0 to (cbtrans div SizeOf(lptrans^))-1 do
   	    	begin
 	    	  	s := '\StringFileInfo\'+IntToHex(lptrans.wLanguage, 4)+
    	      	IntToHex(lptrans.wCodePage, 4)+'\FileVersion';
 	        	Inc(lptrans);
		    		if VerQueryValue(infbuf, PChar(s), Pointer(lpbuf), dwbytes) then
            begin
            	if Result<>'' then
      		   		Result := Result + Chr($0d)+Chr($0a);
     		   		Result := Result +  s +':'+ lpbuf;
            end;
   		    end;
 		    end;
	    end;
    finally
   		FreeMem(infbuf);
	  end;
  end;

begin

	//
	DeviceListBox.Items.Clear;
	with DeviceListBox do
	begin
		//USART, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',USART';
		Items.Add('USART='+IntToStr(DEVICE_USART)+',-3,"'+s+'",EZUSB/PIC/FTDI');
		//PIT, 内蔵/EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',PIT';
		Items.Add('PIT='+IntToStr(DEVICE_PIT)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//PSG, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',PSG,';
		s := s + FloatToStr(1)+',EPSG,';
		s := s + FloatToStr(2)+',SSG,';
		s := s + FloatToStr(2)+',SSGL,';
		s := s + FloatToStr(2)+',OPN,';
		s := s + FloatToStr(4)+',OPNA,';
		s := s + FloatToStr(4)+',OPNA+RAM,';
		s := s + FloatToStr(4)+',OPNB+RAM,';
		s := s + FloatToStr(4)+',YM2610B+RAM,';
		s := s + FloatToStr(4)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*36))+',OPL3-NL_OPN';
		Items.Add('PSG='+IntToStr(DEVICE_PSG)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//EPSG, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',EPSG';
		Items.Add('EPSG='+IntToStr(DEVICE_EPSG)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//SSG, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SSG,';
		s := s + FloatToStr(1)+',SSGL,';
		s := s + FloatToStr(1)+',OPN,';
		s := s + FloatToStr(2)+',OPNA,';
		s := s + FloatToStr(2)+',OPNA+RAM,';
		s := s + FloatToStr(2)+',OPNB+RAM,';
		s := s + FloatToStr(2)+',YM2610B+RAM,';
		s := s + FloatToStr(2)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*72))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1/2)+',PSG,';
		s := s + FloatToStr(1/2)+',EPSG';
		Items.Add('SSG='+IntToStr(DEVICE_SSG)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//SSGL, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SSGL,';
		s := s + FloatToStr(1)+',SSG,';
		s := s + FloatToStr(1)+',OPN,';
		s := s + FloatToStr(2)+',OPNA,';
		s := s + FloatToStr(2)+',OPNA+RAM,';
		s := s + FloatToStr(2)+',OPNB+RAM,';
		s := s + FloatToStr(2)+',YM2610B+RAM,';
		s := s + FloatToStr(2)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*72))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1/2)+',PSG,';
		s := s + FloatToStr(1/2)+',EPSG';
		Items.Add('SSGL='+IntToStr(DEVICE_SSGL)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//DCSG, EZUSB/FTDI
		s :=     FloatToStr(1)+',DCSG,';
		s := s + FloatToStr(1)+',DCSG_GG,';
		s := s + FloatToStr(1)+',DCSG_NGP';
		Items.Add('DCSG='+IntToStr(DEVICE_DCSG)+',1,"'+s+'",EZUSB/FTDI');
		//DCSG_GG, EZUSB/FTDI
		s :=     FloatToStr(1)+',DCSG_GG,';
		s := s + FloatToStr(1)+',DCSG_NGP,';
		s := s + FloatToStr(1)+',DCSG';
		Items.Add('DCSG_GG='+IntToStr(DEVICE_DCSG_GG)+',2,"'+s+'",EZUSB/FTDI');
		//DCSG_NGP, EZUSB/FTDI
		s :=     FloatToStr(1)+',DCSG_NGP';
		Items.Add('DCSG_NGP='+IntToStr(DEVICE_DCSG_NGP)+',3,"'+s+'",EZUSB/FTDI');
    //SAA1099, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SAA1099';
		Items.Add('SAA1099='+IntToStr(DEVICE_SAA1099)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPM, 内蔵/EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPM,';
		s := s + FloatToStr(1)+',OPP,';
		s := s + FloatToStr(1)+',OPZ';
		Items.Add('OPM='+IntToStr(DEVICE_OPM)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPP, 内蔵/EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPP,';
		s := s + FloatToStr(1)+',OPZ';
		Items.Add('OPP='+IntToStr(DEVICE_OPP)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPZ, 内蔵/EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPZ';
		Items.Add('OPZ='+IntToStr(DEVICE_OPZ)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPN, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPN,';
		s := s + FloatToStr(2)+',OPNA,';
		s := s + FloatToStr(2)+',OPNA+RAM,';
		s := s + FloatToStr(2)+',OPNB+RAM,';
		s := s + FloatToStr(2)+',YM2610B+RAM,';
		s := s + FloatToStr(2)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*72))+',OPL3-NL_OPN,';
		s := s + FloatToStr(2)+',OPN2,';
		s := s + FloatToStr(1)+',SSG,';
		s := s + FloatToStr(1)+',SSGL,';
		s := s + FloatToStr(1/2)+',PSG,';
		s := s + FloatToStr(1/2)+',EPSG';
		Items.Add('OPN='+IntToStr(DEVICE_OPN)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPNA, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPNA,';
		s := s + FloatToStr(1)+',OPNA+RAM,';
		s := s + FloatToStr(1)+',YM2610B+RAM,';
		s := s + FloatToStr(1)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*144))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1)+',OPNB+RAM,';
		s := s + FloatToStr(1)+',OPN2,';
		s := s + FloatToStr(1/2)+',OPN,';
		s := s + FloatToStr(1/2)+',SSG,';
		s := s + FloatToStr(1/2)+',SSGL,';
		s := s + FloatToStr(1/4)+',PSG,';
		s := s + FloatToStr(1/4)+',EPSG';
		Items.Add('OPNA='+IntToStr(DEVICE_OPNA)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPNA+RAM, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPNA+RAM,';
		s := s + FloatToStr(1)+',YM2610B+RAM,';
		s := s + FloatToStr(1)+',OPNA,';
		s := s + FloatToStr(1)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*144))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1)+',OPNB+RAM,';
		s := s + FloatToStr(1)+',OPN2,';
		s := s + FloatToStr(1/2)+',OPN,';
		s := s + FloatToStr(1/2)+',SSG,';
		s := s + FloatToStr(1/2)+',SSGL,';
		s := s + FloatToStr(1/4)+',PSG,';
		s := s + FloatToStr(1/4)+',EPSG';
		Items.Add('OPNA+RAM='+IntToStr(DEVICE_OPNA_RAM)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPNB+RAM, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPNB+RAM,';
		s := s + FloatToStr(1)+',YM2610B+RAM,';
		s := s + FloatToStr(1)+',OPNA,';
		s := s + FloatToStr(1)+',OPNA+RAM,';
		s := s + FloatToStr(1)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*144))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1)+',OPN2,';
		s := s + FloatToStr(1/2)+',OPN,';
		s := s + FloatToStr(1/2)+',SSG,';
		s := s + FloatToStr(1/2)+',SSGL,';
		s := s + FloatToStr(1/4)+',PSG,';
		s := s + FloatToStr(1/4)+',EPSG';
		Items.Add('OPNB+RAM='+IntToStr(DEVICE_OPNB_RAM)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//YM2610B+RAM, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',YM2610B+RAM,';
		s := s + FloatToStr(1)+',OPNB+RAM,';
		s := s + FloatToStr(1)+',OPNA,';
		s := s + FloatToStr(1)+',OPNA+RAM,';
		s := s + FloatToStr(1)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*144))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1)+',OPN2,';
		s := s + FloatToStr(1/2)+',OPN,';
		s := s + FloatToStr(1/2)+',SSG,';
		s := s + FloatToStr(1/2)+',SSGL,';
		s := s + FloatToStr(1/4)+',PSG,';
		s := s + FloatToStr(1/4)+',EPSG';
		Items.Add('YM2610B+RAM='+IntToStr(DEVICE_YM2610B_RAM)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPN2, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPN2,';
		s := s + FloatToStr(1)+',OPNA,';
		s := s + FloatToStr(1)+',OPNA+RAM,';
		s := s + FloatToStr(1)+',YM2610B+RAM,';
		s := s + FloatToStr(1)+',OPN3-L,';
		s := s + FloatToStr(16.9344/((16.9344/305)*144))+',OPL3-NL_OPN,';
		s := s + FloatToStr(1)+',OPNB+RAM,';
		s := s + FloatToStr(1/2)+',OPN';
		Items.Add('OPN2='+IntToStr(DEVICE_OPN2)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//OPN3-L, 内蔵/EZUSB/PIC/FTDI
		s := '""';
		Items.Add('OPN3-L='+IntToStr(DEVICE_OPN3L)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//OPLL, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPLL,';
		s := s + FloatToStr(1)+',OPLLP,';
		s := s + FloatToStr(1)+',VRC7';
		Items.Add('OPLL='+IntToStr(DEVICE_OPLL)+',1,"'+s+'",EZUSB/PIC/FTDI');
    if True then
    begin
    	s := s + ',';
			s := s + FloatToStr(1)+',OPL2,';
			s := s + FloatToStr(4)+',OPL3,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
			s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
			s := s + FloatToStr(4)+',SOLO-1/1E';
			Items.Add('OPLL>OPL2='+IntToStr(DEVICE_OPLL)+',0,"'+s+'",');
    end;
		//OPLLP, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPLLP,';
		s := s + FloatToStr(1)+',OPLL,';
		s := s + FloatToStr(1)+',VRC7';
		Items.Add('OPLLP='+IntToStr(DEVICE_OPLLP)+',1,"'+s+'",EZUSB/PIC/FTDI');
    if True then
    begin
    	s := s + ',';
			s := s + FloatToStr(1)+',OPL2,';
			s := s + FloatToStr(4)+',OPL3,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
			s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
			s := s + FloatToStr(4)+',SOLO-1/1E';
			Items.Add('OPLLP>OPL2='+IntToStr(DEVICE_OPLLP)+',0,"'+s+'",');
    end;
		//VRC7, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',VRC7,';
		s := s + FloatToStr(1)+',OPLL,';
		s := s + FloatToStr(1)+',OPLLP';
		Items.Add('VRC7='+IntToStr(DEVICE_VRC7)+',1,"'+s+'",EZUSB/PIC/FTDI');
    if True then
    begin
    	s := s + ',';
			s := s + FloatToStr(1)+',OPL2,';
			s := s + FloatToStr(4)+',OPL3,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
			s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
			s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
			s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
			s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
			s := s + FloatToStr(4)+',SOLO-1/1E';
			Items.Add('VRC7>OPL2='+IntToStr(DEVICE_VRC7)+',0,"'+s+'",');
    end;
		//OPL, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPL,';
		s := s + FloatToStr(1)+',MSX-AUDIO+RAM,';
		s := s + FloatToStr(1)+',OPL2,';
		s := s + FloatToStr(4)+',OPL3,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
		s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
		s := s + FloatToStr(4)+',SOLO-1/1E';
		Items.Add('OPL='+IntToStr(DEVICE_OPL)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//MSX-AUDIO+RAM, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',MSX-AUDIO+RAM,';
		s := s + FloatToStr(1)+',OPL,';
		s := s + FloatToStr(1)+',OPL2,';
		s := s + FloatToStr(4)+',OPL3,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
		s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
		s := s + FloatToStr(4)+',SOLO-1/1E';
		Items.Add('MSX-AUDIO+RAM='+IntToStr(DEVICE_MSXAUDIO_RAM)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//OPL2, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPL2,';
		s := s + FloatToStr(4)+',OPL3,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL3-L,';
		s := s + FloatToStr(16.9344/((16.9344/340)*72))+',OPL3-NL_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4-ML_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*72))+',OPL4+RAM,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1,';
		s := s + FloatToStr(24.576/((33.87/684)*72))+',DS-1L,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1S,';
		s := s + FloatToStr(24.576/((33.87/682)*72))+',DS-1E,';
		s := s + FloatToStr(4)+',SOLO-1/1E';
		Items.Add('OPL2='+IntToStr(DEVICE_OPL2)+',1,"'+s+'",EZUSB/PIC/FTDI');
		//OPL3, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPL3,';
		s := s + FloatToStr(33.8688/((33.8688/684)*288))+',OPL3-L,';
		s := s + FloatToStr(16.9344/((16.9344/340)*288))+',OPL3-NL_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*288))+',OPL4-ML_OPL,';
		s := s + FloatToStr(33.8688/((33.8688/684)*288))+',OPL4+RAM,';
		s := s + FloatToStr(24.576/((33.87/684)*288))+',DS-1,';
		s := s + FloatToStr(24.576/((33.87/684)*288))+',DS-1L,';
		s := s + FloatToStr(24.576/((33.87/682)*288))+',DS-1S,';
		s := s + FloatToStr(24.576/((33.87/682)*288))+',DS-1E,';
		s := s + FloatToStr(1)+',SOLO-1/1E';
		Items.Add('OPL3='+IntToStr(DEVICE_OPL3)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//OPL3-L, EZUSB/PIC/FTDI
		s := '""';
		Items.Add('OPL3-L='+IntToStr(DEVICE_OPL3L)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//DS-1, 内蔵
		s := '""';
		Items.Add('DS-1='+IntToStr(DEVICE_DS1)+',0,"'+s+'",');
		//DS-1L, 内蔵
		s := '""';
		Items.Add('DS-1L='+IntToStr(DEVICE_DS1)+',0,"'+s+'",');
		//DS-1S, 内蔵
		s := '""';
		Items.Add('DS-1S='+IntToStr(DEVICE_DS1)+',0,"'+s+'",');
		//DS-1E, 内蔵
		s := '""';
		Items.Add('DS-1E='+IntToStr(DEVICE_DS1)+',0,"'+s+'",');
    //SOLO-1/1E, 内蔵
		s := '""';
		Items.Add('SOLO-1/1E='+IntToStr(DEVICE_SOLO1)+',0,"'+s+'",');
		//OPL3-NL_OPN, EZUSB/PIC/FTDI
		s := '""';
		Items.Add('OPL3-NL_OPN='+IntToStr(DEVICE_OPL3NL_OPN)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPL3-NL_OPL, EZUSB/PIC/FTDI
		s := '""';
		Items.Add('OPL3-NL_OPL='+IntToStr(DEVICE_OPL3NL_OPL)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPL4+RAM, PIC/FTDI
		s :=     FloatToStr(1)+',OPL4+RAM,';
		s := s + FloatToStr(1)+',OPL4-ML_OPL,';
		s := s + FloatToStr(14.31818/((14.31818/288)*684))+',OPL3,';
		s := s + FloatToStr(33.8688/((33.8688/684)*684))+',OPL3-L,';
		s := s + FloatToStr(16.9344/((16.9344/340)*684))+',OPL3-NL_OPL,';
		s := s + FloatToStr(24.576/((33.87/684)*684))+',DS-1,';
		s := s + FloatToStr(24.576/((33.87/684)*684))+',DS-1L,';
		s := s + FloatToStr(24.576/((33.87/682)*684))+',DS-1S,';
		s := s + FloatToStr(24.576/((33.87/682)*684))+',DS-1E,';
		s := s + FloatToStr(14.31818/((14.31818/288)*684))+',SOLO-1/1E';
		Items.Add('OPL4+RAM='+IntToStr(DEVICE_OPL4_RAM)+',4,"'+s+'",PIC/FTDI');
		//OPL4-ML_OPL, EZUSB/PIC/FTDI
		s := '""';
		Items.Add('OPL4-ML_OPL='+IntToStr(DEVICE_OPL4ML_OPL)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPL4-ML_MPU, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',OPL4-ML_MPU';
		Items.Add('OPL4-ML_MPU='+IntToStr(DEVICE_OPL4ML_MPU)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//OPX+RAM, PIC/FTDI
		s :=     FloatToStr(1)+',OPX+RAM';
		Items.Add('OPX+RAM='+IntToStr(DEVICE_OPX_RAM)+',5,"'+s+'",PIC/FTDI');
		//SCC, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SCC,';
		s := s + FloatToStr(1)+',052539';
		Items.Add('SCC='+IntToStr(DEVICE_SCC)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//052539, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',052539';
		Items.Add('052539='+IntToStr(DEVICE_052539)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//GA20, PIC/FTDI
		s :=     FloatToStr(1)+',GA20';
		Items.Add('GA20='+IntToStr(DEVICE_GA20)+',6,"'+s+'",PIC/FTDI');
    //PCMD8, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',PCMD8';
		Items.Add('PCMD8='+IntToStr(DEVICE_PCMD8)+',2,"'+s+'",EZUSB/PIC/FTDI');
		//MA-2, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',MA-2,';
		s := s + FloatToStr(1)+',MA-3,';
		s := s + FloatToStr(1)+',MA-5,';
		s := s + FloatToStr(1)+',MA-7';
		Items.Add('MA-2='+IntToStr(DEVICE_MA2)+',-1,"'+s+'",EZUSB/PIC/FTDI');
		//MA-3, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',MA-3,';
		s := s + FloatToStr(1)+',MA-5,';
		s := s + FloatToStr(1)+',MA-7';
		Items.Add('MA-3='+IntToStr(DEVICE_MA3)+',-1,"'+s+'",EZUSB/PIC/FTDI');
		//MA-5, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',MA-5,';
		s := s + FloatToStr(1)+',MA-7';
		Items.Add('MA-5='+IntToStr(DEVICE_MA5)+',-1,"'+s+'",EZUSB/PIC/FTDI');
		//MA-7, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',MA-7';
		Items.Add('MA-7='+IntToStr(DEVICE_MA7)+',-1,"'+s+'",EZUSB/PIC/FTDI');
		//RP2A03, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',RP2A03,';
		s := s + FloatToStr(1)+',RP2A03+EXT,';
		s := s + FloatToStr((4.43361875*6)/((4.43361875*6/15)*12))+',RP2A07';
		Items.Add('RP2A03='+IntToStr(DEVICE_RP2A03)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//RP2A03+EXT, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',RP2A03+EXT,';
		s := s + FloatToStr(1)+',RP2A03,';
		s := s + FloatToStr((4.43361875*6)/((4.43361875*6/15)*12))+',RP2A07';
		Items.Add('RP2A03+EXT='+IntToStr(DEVICE_RP2A03_EXT)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//RP2A07, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',RP2A07,';
		s := s + FloatToStr((3.579545*6)/((3.579545*6/12)*15))+',RP2A03,';
		s := s + FloatToStr((3.579545*6)/((3.579545*6/12)*15))+',RP2A03+EXT';
		Items.Add('RP2A07='+IntToStr(DEVICE_RP2A07)+',-3,"'+s+'",EZUSB/PIC/FTDI');
		//S-SMP+S-DSP, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',S-SMP+S-DSP';
		Items.Add('S-SMP+S-DSP='+IntToStr(DEVICE_SSMP_SDSP)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//CPU_AGB, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',CPU_AGB';
		Items.Add('CPU_AGB='+IntToStr(DEVICE_CPU_AGB)+',-1,"'+s+'",EZUSB/PIC/FTDI');
		//SCSP+SCPU, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SCSP+SCPU';
		Items.Add('SCSP+SCPU='+IntToStr(DEVICE_SCSP_SCPU)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//SPU, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SPU,';
		s := s + FloatToStr(1)+',SPU2';
		Items.Add('SPU='+IntToStr(DEVICE_SPU)+',3,"'+s+'",EZUSB/PIC/FTDI');
		//AICA, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',AICA';
		Items.Add('AICA='+IntToStr(DEVICE_AICA)+',-1,"'+s+'",EZUSB/PIC/FTDI');
    //SPU2, EZUSB/PIC/FTDI
		s :=     FloatToStr(1)+',SPU2';
		Items.Add('SPU2='+IntToStr(DEVICE_SPU2)+',-1,"'+s+'",EZUSB/PIC/FTDI');
	end;

 	//
 	for i := 0 to 2 do
  	dev[i] := '';
  //
  for i := 0 to DeviceListBox.Items.Count-1 do
  begin
   	//
   	s := DeviceListBox.Items.Names[i];
    t := UpperCase(GetDeviceCtl(s));
    //EZ-USB/PIC/FTDIのみ追加
    case GetDeviceAddr(s) of
    	0:
      	begin
        	//内蔵のみ
        end;
    	1..3:
      	begin
        	//1, A0
        	//2, A1-0
        	//3, A2-0
          if AnsiPos('EZUSB', t)>0 then
			   		dev[0] := dev[0] + s +',';
          if AnsiPos('PIC', t)>0 then
			   		dev[1] := dev[1] + s +',';
          if AnsiPos('FTDI', t)>0 then
			   		dev[2] := dev[2] + s +',';
        end;
      4..7:
      	begin
        	//4, A3-0
        	//5, A4-0
        	//6, A5-0
        	//7, A6-0
        	//8, A7-0
          if AnsiPos('PIC', t)>0 then
			   		dev[1] := dev[1] + s +',';
          if AnsiPos('FTDI', t)>0 then
			   		dev[2] := dev[2] + s +',';
        end;
    end;
  end;
  //
 	for i := 0 to 2 do
  	dev[i] := LeftStr(dev[i], Length(dev[i])-1);

	//内蔵
  lim := 12;
  for i := 0 to 7 do
  begin
  	s := 'IntCs'+IntToStr(i and 7);
    Cs[i].nIf := IF_INT;
    Cs[i].nIfNum := 0;
    Cs[i].dwDevAddr := 0;
    Cs[i].nCs := 0;
    Cs[i].nIndex := 0;
    Cs[i].nAddr := -1;
    Cs[i].nEzusb := -1;
    Cs[i].nPic := -1;
    Cs[i].nFtdi := -1;
		Cs[i].Chk := FindComponent(s+'Chk') as TCheckBox;
    Cs[i].Chk.Enabled := False;
    Cs[i].Chk.Caption := '*';
    Cs[i].DevCB := FindComponent(s+'DevCB') as TComboBox;
    Cs[i].DevCB.DropDownCount := lim;
 		Cs[i].DevCB.Items.CommaText := '';
    Cs[i].ClkCB := FindComponent(s+'ClkCB') as TComboBox;
    Cs[i].ClkCB.DropDownCount := lim;
    Cs[i].ClkCB.AutoComplete := False;
    Cs[i].ClkCB.AutoDropDown := False;
    Cs[i].DelBtn := nil;
  end;
	//EZ-USB
  for i := 0 to EZUSB_DEVMAX-1 do
 	begin
		//
    Ezusb[i].hndHandle := INVALID_HANDLE_VALUE;
    Ezusb[i].Device := '';
    Ezusb[i].Rev := '';
    Ezusb[i].bFx2 := False;
    Ezusb[i].nSyncFreq := 0;
    Ezusb[i].nAddrWidth := 0;
    //
    n := 8+i*8;
		EzusbTab[i].nDevIndex := n;
    s := 'Ezusb'+IntToStr(i);
    EzusbTab[i].AutoChk := FindComponent(s+'AutoChk') as TCheckBox;
    EzusbTab[i].AutoChk.ShowHint := MainForm.bDebug;
    EzusbTab[i].DevCb := FindComponent(s+'DevCb') as TComboBox;
    EzusbTab[i].DevCb.Items.Clear;
    EzusbTab[i].ResetBtn := FindComponent(s+'ResetBtn') as TSpeedButton;
		EzusbTab[i].ResetBtn.Enabled := False;
		//
	  for j := 0 to 7 do
  	begin
  		s := 'Ezusb'+IntToStr(i)+'Cs'+IntToStr(j and 7);
	    Cs[n].nIf := IF_EZUSB;
	    Cs[n].nIfNum := i;
	    Cs[n].dwDevAddr := 0;
	    Cs[n].nCs := j div 2;
  	  Cs[n].nIndex := j and 1;
      Cs[n].nAddr := -1;
	    Cs[n].nEzusb := -1;
	    Cs[n].nPic := -1;
	    Cs[n].nFtdi := -1;
			Cs[n].Chk := FindComponent(s+'Chk') as TCheckBox;
	    Cs[n].DevCB := FindComponent(s+'DevCB') as TComboBox;
	    Cs[n].DevCB.DropDownCount := lim;
   		Cs[n].DevCB.Items.CommaText := dev[0];
  	  Cs[n].ClkCB := FindComponent(s+'ClkCB') as TComboBox;
	    Cs[n].ClkCB.DropDownCount := lim;
  	  Cs[n].ClkCB.AutoComplete := False;
	    Cs[n].ClkCB.AutoDropDown := False;
    	Cs[n].DelBtn := FindComponent(s+'DelBtn') as TButton;
      Inc(n);
	  end;
  end;
	//PIC
  for i := 0 to PIC_DEVMAX-1 do
 	begin
		//
    Pic[i].nInstance := -1;
    Pic[i].Device := '';
    Pic[i].Rev := '';
   	Pic[i].hndWrite := INVALID_HANDLE_VALUE;
   	Pic[i].hndRead := INVALID_HANDLE_VALUE;
    Pic[i].nSyncFreq := 0;
    Pic[i].nAddrWidth := 0;
    //
    n := 8+EZUSB_DEVMAX*8+i*8;
		PicTab[i].nDevIndex := n;
    s := 'Pic'+IntToStr(i);
    PicTab[i].AutoChk := FindComponent(s+'AutoChk') as TCheckBox;
    PicTab[i].AutoChk.ShowHint := MainForm.bDebug;
    PicTab[i].DevCb := FindComponent(s+'DevCb') as TComboBox;
    PicTab[i].DevCb.Items.Clear;
    PicTab[i].ResetBtn := FindComponent(s+'ResetBtn') as TSpeedButton;
		PicTab[i].ResetBtn.Enabled := False;
		//
	  for j := 0 to 7 do
  	begin
  		s := 'Pic'+IntToStr(i)+'Cs'+IntToStr(j and 7);
	    Cs[n].nIf := IF_PIC;
	    Cs[n].nIfNum := i;
	    Cs[n].dwDevAddr := 0;
	    Cs[n].nCs := j div 2;
  	  Cs[n].nIndex := j and 1;
      Cs[n].nAddr := -1;
	    Cs[n].nEzusb := -1;
	    Cs[n].nPic := -1;
	    Cs[n].nFtdi := -1;
			Cs[n].Chk := FindComponent(s+'Chk') as TCheckBox;
	    Cs[n].DevCB := FindComponent(s+'DevCB') as TComboBox;
	    Cs[n].DevCB.DropDownCount := lim;
   		Cs[n].DevCB.Items.CommaText := dev[1];
  	  Cs[n].ClkCB := FindComponent(s+'ClkCB') as TComboBox;
	    Cs[n].ClkCB.DropDownCount := lim;
  	  Cs[n].ClkCB.AutoComplete := False;
	    Cs[n].ClkCB.AutoDropDown := False;
    	Cs[n].DelBtn := FindComponent(s+'DelBtn') as TButton;
      Inc(n);
	  end;
  end;
	//FTDI
  for i := 0 to FTDI_DEVMAX-1 do
 	begin
		//
    Ftdi[i].nInstance := -1;
    Ftdi[i].Device := '';
    Ftdi[i].Rev := '';
   	Ftdi[i].hndDevice := nil;
    Ftdi[i].nSyncFreq := 0;
    Ftdi[i].nAddrWidth := 0;
    //
    n := 8+EZUSB_DEVMAX*8+PIC_DEVMAX*8+i*8;
		FtdiTab[i].nDevIndex := n;
    s := 'Ftdi'+IntToStr(i);
    FtdiTab[i].AutoChk := FindComponent(s+'AutoChk') as TCheckBox;
    FtdiTab[i].AutoChk.ShowHint := MainForm.bDebug;
    FtdiTab[i].DevCb := FindComponent(s+'DevCb') as TComboBox;
    FtdiTab[i].DevCb.Items.Clear;
    FtdiTab[i].ResetBtn := FindComponent(s+'ResetBtn') as TSpeedButton;
		FtdiTab[i].ResetBtn.Enabled := False;
		//
	  for j := 0 to 7 do
  	begin
  		s := 'Ftdi'+IntToStr(i)+'Cs'+IntToStr(j and 7);
	    Cs[n].nIf := IF_FTDI;
	    Cs[n].nIfNum := i;
	    Cs[n].dwDevAddr := 0;
	    Cs[n].nCs := j div 2;
  	  Cs[n].nIndex := j and 1;
      Cs[n].nAddr := -1;
	    Cs[n].nEzusb := -1;
	    Cs[n].nPic := -1;
	    Cs[n].nFtdi := -1;
			Cs[n].Chk := FindComponent(s+'Chk') as TCheckBox;
	    Cs[n].DevCB := FindComponent(s+'DevCB') as TComboBox;
	    Cs[n].DevCB.DropDownCount := lim;
   		Cs[n].DevCB.Items.CommaText := dev[2];
  	  Cs[n].ClkCB := FindComponent(s+'ClkCB') as TComboBox;
	    Cs[n].ClkCB.DropDownCount := lim;
  	  Cs[n].ClkCB.AutoComplete := False;
	    Cs[n].ClkCB.AutoDropDown := False;
    	Cs[n].DelBtn := FindComponent(s+'DelBtn') as TButton;
      Inc(n);
	  end;
  end;

  //
  KeyListBox.Items.Clear;
  KeyListBox.Items.Add('KssStart=KSS 再生曲番（曲番無指定時のみ）');
  KeyListBox.Items.Add('KssStartDef='+IntToStr(0));
  KeyListBox.Items.Add('KssLimit=KSS 再生時間');
  KeyListBox.Items.Add('KssLimitDef='+IntToStr(180));
	KeyListBox.Items.Add('KssSpeed=KSS クロック違いを再生速度に反映');
	KeyListBox.Items.Add('KssSpeedDef='+BoolToStr(False));
  KeyListBox.Items.Add('NsfStart=NSF 再生曲番（曲番無指定時のみ）');
  KeyListBox.Items.Add('NsfStartDef='+IntToStr(1));
  KeyListBox.Items.Add('NsfLimit=NSF 再生時間');
  KeyListBox.Items.Add('NsfLimitDef='+IntToStr(180));
	KeyListBox.Items.Add('NsfSpeed=NSF クロック違いを再生速度に反映');
	KeyListBox.Items.Add('NsfSpeedDef='+BoolToStr(False));
	KeyListBox.Items.Add('PsfTime=PSF タグの再生時間を使用');
	KeyListBox.Items.Add('PsfTimeDef='+BoolToStr(True));
	KeyListBox.Items.Add('PsfLoop=PSF ループ回数（タグ使用時のみ）');
	KeyListBox.Items.Add('PsfLoopDef='+IntToStr(2));
  KeyListBox.Items.Add('PsfLimit=PSF 再生時間');
  KeyListBox.Items.Add('PsfLimitDef='+IntToStr(180));
	KeyListBox.Items.Add('PsfSpeed=PSF クロック違いを再生速度に反映');
	KeyListBox.Items.Add('PsfSpeedDef='+BoolToStr(False));
  KeyListBox.Items.Add('S98Loop=S98 ループ回数');
  KeyListBox.Items.Add('S98LoopDef='+IntToStr(2));
	KeyListBox.Items.Add('S98Speed=S98 クロック違いを再生速度に反映');
	KeyListBox.Items.Add('S98SpeedDef='+BoolToStr(False));
	KeyListBox.Items.Add('SpcTime=SPC タグの再生時間を使用');
	KeyListBox.Items.Add('SpcTimeDef='+BoolToStr(True));
	KeyListBox.Items.Add('SpcLoop=SPC ループ回数（タグ使用時のみ）');
	KeyListBox.Items.Add('SpcLoopDef='+IntToStr(2));
  KeyListBox.Items.Add('SpcLimit=SPC 再生時間');
  KeyListBox.Items.Add('SpcLimitDef='+IntToStr(180));
	KeyListBox.Items.Add('SpuSpeed=SPU クロック違いを再生速度に反映');
	KeyListBox.Items.Add('SpuSpeedDef='+BoolToStr(False));
  KeyListBox.Items.Add('VgmLoop=VGM ループ回数');
  KeyListBox.Items.Add('VgmLoopDef='+IntToStr(2));
	KeyListBox.Items.Add('VgmSpeed=VGM クロック違いを再生速度に反映');
	KeyListBox.Items.Add('VgmSpeedDef='+BoolToStr(False));
  //
  KeyListBox.Items.Add('FtdiSetBitMode=FTDI 同期245FIFO');
  KeyListBox.Items.Add('FtdiSetBitModeDef='+BoolToStr(False));
  //
  KeyListBox.Items.Add('IntPitChannel=内蔵PIT 再生CH');
  KeyListBox.Items.Add('IntPitChannelDef='+IntToStr(1));
  //
  KeyListBox.Items.Add('Ga20Attenuation=GA20 減衰量');
  KeyListBox.Items.Add('Ga20AttenuationDef='+IntToStr(0));
  //
	KeyListBox.Items.Add('Opl2Opll=OPL2 OPLLの再生');
	KeyListBox.Items.Add('Opl2OpllDef='+BoolToStr(False));
  KeyListBox.Items.Add('Opl2OpllInst=OPL2 OPLL_OPLL音色');
	KeyListBox.Items.Add('Opl2OpllInstDef='+'.\opll\opll.ini');
  KeyListBox.Items.Add('Opl2OpllpInst=OPL2 OPLL_OPLLP音色');
	KeyListBox.Items.Add('Opl2OpllpInstDef='+'.\opll\opllp.ini');
  KeyListBox.Items.Add('Opl2Vrc7Inst=OPL2 OPLL_VRC7音色');
	KeyListBox.Items.Add('Opl2Vrc7InstDef='+'.\opll\vrc7.ini');
  //
	KeyListBox.Items.Add('Opl3ChannelChg=OPL3 CHA/BとCHC/Dの入れ替え');
	KeyListBox.Items.Add('Opl3ChannelChgDef='+BoolToStr(False));
	KeyListBox.Items.Add('Opl3OpllMoRo=OPL3 OPLL_CHA:MO/CHB:RO');
	KeyListBox.Items.Add('Opl3OpllMoRoDef='+BoolToStr(False));
	KeyListBox.Items.Add('Opl3nlOplChannelLr=OPL3-NL_OPL CHL/CHRの入れ替え');
	KeyListBox.Items.Add('Opl3nlOplChannelLrDef='+BoolToStr(True));
  //
	KeyListBox.Items.Add('Solo1ChannelLr=SOLO-1 CHAとCHBの入れ替え');
	KeyListBox.Items.Add('Solo1ChannelLrDef='+BoolToStr(True));
  KeyListBox.Items.Add('Solo1VolumeChg=SOLO-1 FM音量の強制設定');
  KeyListBox.Items.Add('Solo1VolumeChgDef='+BoolToStr(False));
  KeyListBox.Items.Add('Solo1Volume=SOLO-1 FM音量');
  KeyListBox.Items.Add('Solo1VolumeDef='+'0');
  //
  KeyListBox.Items.Add('Opl4FmMix=OPL4 FM_MIX（$02F8）');
  KeyListBox.Items.Add('Opl4FmMixDef='+'-9');
  KeyListBox.Items.Add('Opl4PcmMix=OPL4 PCM_MIX（$02F9）');
  KeyListBox.Items.Add('Opl4PcmMixDef='+'0');
	KeyListBox.Items.Add('Opl4PcmChannelChg=OPL4 PCM_CH0とCH1の入れ替え');
	KeyListBox.Items.Add('Opl4PcmChannelChgDef='+BoolToStr(False));
	KeyListBox.Items.Add('Opl4+RamDo=OPL4+RAM DO選択');
  KeyListBox.Items.Add('Opl4+RamDoDef='+'DO2');
	KeyListBox.Items.Add('Opl4+RamSpdif=OPL4+RAM デジタル出力');
	KeyListBox.Items.Add('Opl4+RamSpdifDef='+BoolToStr(False));
  //
  KeyListBox.Items.Add('OpmFmAttenuation=OPM FM減衰量');
  KeyListBox.Items.Add('OpmFmAttenuationDef='+IntToStr(0));
  //
  KeyListBox.Items.Add('OpnFmAttenuation=OPN FM減衰量');
  KeyListBox.Items.Add('OpnFmAttenuationDef='+IntToStr(0));
  //
  KeyListBox.Items.Add('OpnaBalance=OPNA FM:SSG');
  KeyListBox.Items.Add('OpnaBalanceDef='+IntToStr(192));
	KeyListBox.Items.Add('OpnaOpn2Pcm=OPNA OPN2_PCMの再生');
	KeyListBox.Items.Add('OpnaOpn2PcmDef='+BoolToStr(False));
	KeyListBox.Items.Add('OpnaOpn2PcmType=OPNA OPN2_PCMの再生方法');
	KeyListBox.Items.Add('OpnaOpn2PcmTypeDef='+'FM');
  //
  KeyListBox.Items.Add('OpnbBalance=OPNB FM:SSG');
  KeyListBox.Items.Add('OpnbBalanceDef='+IntToStr(192));
	KeyListBox.Items.Add('OpnbOpnaRhythm=OPNB OPNA_RHYTHMの再生');
	KeyListBox.Items.Add('OpnbOpnaRhythmDef='+BoolToStr(False));
  KeyListBox.Items.Add('OpnbOpnaBd=OPNB OPNA_RHYTHM_BD');
	KeyListBox.Items.Add('OpnbOpnaBdDef='+'.\opnb\2608bd.rom');
  KeyListBox.Items.Add('OpnbOpnaSd=OPNB OPNA_RHYTHM_SD');
	KeyListBox.Items.Add('OpnbOpnaSdDef='+'.\opnb\2608sd.rom');
  KeyListBox.Items.Add('OpnbOpnaTop=OPNB OPNA_RHYTHM_TOP');
	KeyListBox.Items.Add('OpnbOpnaTopDef='+'.\opnb\2608top.rom');
  KeyListBox.Items.Add('OpnbOpnaHh=OPNB OPNA_RHYTHM_HH');
	KeyListBox.Items.Add('OpnbOpnaHhDef='+'.\opnb\2608hh.rom');
  KeyListBox.Items.Add('OpnbOpnaTom=OPNB OPNA_RHYTHM_TOM');
	KeyListBox.Items.Add('OpnbOpnaTomDef='+'.\opnb\2608tom.rom');
  KeyListBox.Items.Add('OpnbOpnaRim=OPNB OPNA_RHYTHM_RIM');
	KeyListBox.Items.Add('OpnbOpnaRimDef='+'.\opnb\2608rim.rom');
  //
	KeyListBox.Items.Add('Opx+RamDoExt=OPX+RAM DO/EXT選択');
  KeyListBox.Items.Add('Opx+RamDoExtDef='+'DO1');
	KeyListBox.Items.Add('Opx+Ram18bit=OPX+RAM 18ビット出力');
	KeyListBox.Items.Add('Opx+Ram18bitDef='+BoolToStr(False));
	KeyListBox.Items.Add('Opx+RamSpdif=OPX+RAM デジタル出力');
	KeyListBox.Items.Add('Opx+RamSpdifDef='+BoolToStr(False));
  //
	KeyListBox.Items.Add('Pcmd8DoEo=PCMD8 DO/EO選択');
  KeyListBox.Items.Add('Pcmd8DoEoDef='+'DO');
	KeyListBox.Items.Add('Pcmd8Spdif=PCMD8 デジタル出力');
	KeyListBox.Items.Add('Pcmd8SpdifDef='+BoolToStr(False));
  //
	KeyListBox.Items.Add('Rp2a03Ctl=RP2A03 制御プログラム');
	KeyListBox.Items.Add('Rp2a03CtlDef='+'.\nsf\cpuctl.bin');
  KeyListBox.Items.Add('Rp2a03+ExtMask=RP2A03+EXT 拡張音源のマスク');
  KeyListBox.Items.Add('Rp2a03+ExtMaskDef='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMaskVrc6=RP2A03+EXT 拡張音源_VRC6');
  KeyListBox.Items.Add('Rp2a03+ExtMaskVrc6Def='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMaskVrc7=RP2A03+EXT 拡張音源_VRC7');
  KeyListBox.Items.Add('Rp2a03+ExtMaskVrc7Def='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMaskRp2c33=RP2A03+EXT 拡張音源_RP2C33');
  KeyListBox.Items.Add('Rp2a03+ExtMaskRp2c33Def='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMaskMmc5=RP2A03+EXT 拡張音源_MMC5');
  KeyListBox.Items.Add('Rp2a03+ExtMaskMmc5Def='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMask163=RP2A03+EXT 拡張音源_163');
  KeyListBox.Items.Add('Rp2a03+ExtMask163Def='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtMask5b=RP2A03+EXT 拡張音源_5B');
  KeyListBox.Items.Add('Rp2a03+ExtMask5bDef='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtRegRead=RP2A03+EXT $4000-$4013の読込み');
  KeyListBox.Items.Add('Rp2a03+ExtRegReadDef='+BoolToStr(False));
//  KeyListBox.Items.Add('Rp2a03+ExtMmc5Read=RP2A03+EXT MMC5_ROMの読込み');
//  KeyListBox.Items.Add('Rp2a03+ExtMmc5ReadDef='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+Ext163Read=RP2A03+EXT 163_$4800の読込み');
  KeyListBox.Items.Add('Rp2a03+Ext163ReadDef='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtNc=RP2A03+EXT NCピンの設定');
  KeyListBox.Items.Add('Rp2a03+ExtNcDef='+'Low');
  KeyListBox.Items.Add('Rp2a03+ExtRomsel=RP2A03+EXT ROMSELの再設定');
  KeyListBox.Items.Add('Rp2a03+ExtRomselDef='+BoolToStr(False));
  KeyListBox.Items.Add('Rp2a03+ExtRomselVrc6=RP2A03+EXT ROMSEL_VRC6');
  KeyListBox.Items.Add('Rp2a03+ExtRomselVrc6Def='+'Default');
  KeyListBox.Items.Add('Rp2a03+ExtRomselVrc7=RP2A03+EXT ROMSEL_VRC7');
  KeyListBox.Items.Add('Rp2a03+ExtRomselVrc7Def='+'Default');
  KeyListBox.Items.Add('Rp2a03+ExtRomselRp2c33=RP2A03+EXT ROMSEL_RP2C33');
  KeyListBox.Items.Add('Rp2a03+ExtRomselRp2c33Def='+'Default');
  KeyListBox.Items.Add('Rp2a03+ExtRomselMmc5=RP2A03+EXT ROMSEL_MMC5');
  KeyListBox.Items.Add('Rp2a03+ExtRomselMmc5Def='+'Default');
  KeyListBox.Items.Add('Rp2a03+ExtRomsel163=RP2A03+EXT ROMSEL_163');
  KeyListBox.Items.Add('Rp2a03+ExtRomsel163Def='+'Default');
  KeyListBox.Items.Add('Rp2a03+ExtRomsel5b=RP2A03+EXT ROMSEL_5B');
  KeyListBox.Items.Add('Rp2a03+ExtRomsel5bDef='+'Default');
  //
  KeyListBox.Items.Add('052539CompatibleMode=052539 SCC互換として動作');
  KeyListBox.Items.Add('052539CompatibleModeDef='+BoolToStr(False));
  //
	KeyListBox.Items.Add('Scsp+ScpuCtl=SCSP+SCPU 制御プログラム');
	KeyListBox.Items.Add('Scsp+ScpuCtlDef='+'.\psf\scpuctl.bin');
	KeyListBox.Items.Add('Scsp+ScpuExt=SCSP+SCPU 外部入力');
	KeyListBox.Items.Add('Scsp+ScpuExtDef='+BoolToStr(False));
	KeyListBox.Items.Add('Scsp+Scpu18bit=SCSP+SCPU 18ビット出力');
	KeyListBox.Items.Add('Scsp+Scpu18bitDef='+BoolToStr(False));
	KeyListBox.Items.Add('Scsp+ScpuSpdif=SCSP+SCPU デジタル出力');
	KeyListBox.Items.Add('Scsp+ScpuSpdifDef='+BoolToStr(False));
  //
	KeyListBox.Items.Add('SpuExt=SPU 外部入力');
	KeyListBox.Items.Add('SpuExtDef='+BoolToStr(False));
	KeyListBox.Items.Add('SpuSpdif=SPU デジタル出力');
	KeyListBox.Items.Add('SpuSpdifDef='+BoolToStr(False));
  //
	KeyListBox.Items.Add('Ssmp+SdspCtl=S-SMP+S-DSP 制御プログラム');
	KeyListBox.Items.Add('Ssmp+SdspCtlDef='+'.\spc\ssmpctl.bin');
	KeyListBox.Items.Add('Ssmp+SdspType=S-SMP+S-DSP IC#を使用してリセット');
	KeyListBox.Items.Add('Ssmp+SdspTypeDef='+BoolToStr(True));
	KeyListBox.Items.Add('Ssmp+SdspSpdif=S-SMP+S-DSP デジタル出力');
	KeyListBox.Items.Add('Ssmp+SdspSpdifDef='+BoolToStr(False));
  //
  KeyListBox.Items.Add('TabPosition=タブ位置（再表示されたときに更新）');
  KeyListBox.Items.Add('TabPositionDef='+'Top');
  if False then
		KeyListBox.Items.Add('_RelPath=実行ファイルと同じフォルダは相対パスにする');
	KeyListBox.Items.Add('_RelPathDef='+BoolToStr(True));
  //
  ValueListEditor.Strings.Clear;

	//
 	path := ChangeFileExt(Application.ExeName, '.ini');
  ini := TIniFile.Create(path);
  sl := TStringList.Create;
  try
  	//
    Form.Left := ini.ReadInteger('DeviceForm', 'Left', MaxInt);
    Form.Top := ini.ReadInteger('DeviceForm', 'Top', MaxInt);
		Visible := ini.ReadBool('DeviceForm', 'Visible', False);

    //
    clock := ini.ReadString('DeviceForm', 'DevClock', '');
    if clock='' then
    begin
    	with TStringList.Create do
      begin
      	try
        	//
          Add(FloatToStr(14318180/12));
	      	Add(FloatToStr(3579545/2));
  	      Add('1996800');
	        Add('2000000');
    	    Add('2457600');
          Add('3072000');
        	Add('3579545');
      	  Add('3993600');
	        Add('4000000');
//	        Add('4194304');
        	Add(FloatToStr(3579545*2));
  		    Add(FloatToStr(3579545*15/7));
    	    Add('7987200');
      	  Add('8000000');
        	Add(FloatToStr(3579545*4));
	        Add(FloatToStr(44100*384));
  	      Add(FloatToStr(3579545*6));
          Add(FloatToStr(32000*768));
//    	    Add(FloatToStr(4433618.75*6));
      	  Add(FloatToStr(44100*512));
      	  Add(FloatToStr(44100*768));
        	clock := CommaText;
        finally
	        Free;
        end;
      end;
    end;
    //
    sl.CommaText := clock;
    with TStringList.Create do
    begin
    	try
      	//
	      Sorted := True;
		    Duplicates := dupIgnore;
    	  for i := 0 to sl.Count-1 do
	      begin
  	    	s := Trim(sl.Strings[i]);
    	    if s<>'' then
		 				Add(s);
	      end;
		    Sorted := False;
				CustomSort(ClkCompare);
      	clock := CommaText;
      finally
	      Free;
      end;
    end;

    //
    for i := 0 to CONNECT_DEVMAX-1 do
    begin
      //
      if Cs[i].nIf=IF_INT then
       	Continue;
			//
      case Cs[i].nIf of
			  IF_EZUSB:
        	begin
			    	s := 'Ezusb'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
			      SetDeviceForm(i, ini.ReadString('DeviceForm', s, ''), clock);
          end;
			  IF_PIC:
        	begin
			    	s := 'Pic'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
			      SetDeviceForm(i, ini.ReadString('DeviceForm', s, ''), clock);
          end;
			  IF_FTDI:
        	begin
			    	s := 'Ftdi'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
			      SetDeviceForm(i, ini.ReadString('DeviceForm', s, ''), clock);
          end;
      end;
		end;

    //
	  for i := 0 to EZUSB_DEVMAX-1 do
	 	begin
      s := ini.ReadString('DeviceForm', 'Ezusb'+IntToStr(i)+'Auto', '');
      if i=0 then
	     	EzusbTab[i].AutoChk.Checked := StrToBoolDef(s, True)
      else
  	   	EzusbTab[i].AutoChk.Checked := StrToBoolDef(s, False);
    end;
    //
	  for i := 0 to PIC_DEVMAX-1 do
	 	begin
      s := ini.ReadString('DeviceForm', 'Pic'+IntToStr(i)+'Auto', '');
      if i=0 then
	     	PicTab[i].AutoChk.Checked := StrToBoolDef(s, True)
			else
	     	PicTab[i].AutoChk.Checked := StrToBoolDef(s, False);
    end;
    //
	  for i := 0 to FTDI_DEVMAX-1 do
	 	begin
      s := ini.ReadString('DeviceForm', 'Ftdi'+IntToStr(i)+'Auto', '');
      if i=0 then
	     	FtdiTab[i].AutoChk.Checked := StrToBoolDef(s, True)
			else
	     	FtdiTab[i].AutoChk.Checked := StrToBoolDef(s, False);
    end;

    //
    s := 'KssStart';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'KssLimit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'KssSpeed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'NsfStart';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'NsfLimit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'NsfSpeed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'PsfTime';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'PsfLoop';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'PsfLimit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'PsfSpeed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'S98Loop';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'S98Speed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'SpcTime';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'SpcLoop';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'SpcLimit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'SpuSpeed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'VgmLoop';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
    end;
    s := 'VgmSpeed';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'FtdiSetBitMode';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'IntPitChannel';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    //
    s := 'Ga20Attenuation';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.Clear;
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(0));
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(3));
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(6));
    end;
	  //
    s := 'Opl2Opll';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Opl2OpllInst';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'Opl2OpllpInst';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'Opl2Vrc7Inst';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    //
    s := 'Opl3ChannelChg';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Opl3OpllMoRo';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Opl3nlOplChannelLr';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
		//
    s := 'Solo1ChannelLr';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Solo1VolumeChg';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Solo1Volume';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '+10.5,+9.0,+7.5,+6.0,+4.5,+3.0,+1.5,0,-3.0,-6.0,-9.0,-12.0,-15.0,-18.0,-21.0,mute';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    //
    s := 'Opl4FmMix';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,-3,-6,-9,-12,-15,-18,-∞';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    s := 'Opl4PcmMix';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,-3,-6,-9,-12,-15,-18,-∞';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    s := 'Opl4PcmChannelChg';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Opl4+RamDo';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := 'DO0,DO1,DO2';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    s := 'Opl4+RamSpdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'OpmFmAttenuation';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.Clear;
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(0));
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(3));
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(6));
    end;
    //
    s := 'OpnFmAttenuation';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.Clear;
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(0));	//PC-9801-26
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(0));	//PC-9801-86
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(9));	//PC-8801-11
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(7));	//PC-8801-23
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(9));	//MB22459
    end;
    //
    s := 'OpnaBalance';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.Clear;
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-0));		//PC-9801-26
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-0));		//PC-9801-86
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-18));	//PC-8801-11
      ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-15));	//PC-8801-23
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-18));	//MB22459
    end;
    s := 'OpnaOpn2Pcm';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'OpnaOpn2PcmType';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := 'FM,SSG,ADPCM,PCM';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
	  //
    s := 'OpnbBalance';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
	    SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.Clear;
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-0));		//PC-9801-26
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-0));		//PC-9801-86
//  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-18));	//PC-8801-11
      ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-15));	//PC-8801-23
  	  ValueListEditor.ItemProps[key].PickList.Add(IntToStr(192-18));	//MB22459
    end;
    s := 'OpnbOpnaRhythm';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'OpnbOpnaBd';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'OpnbOpnaSd';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'OpnbOpnaTop';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'OpnbOpnaHh';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'OpnbOpnaTom';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'OpnbOpnaRim';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    //
    s := 'Opx+RamDoExt';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := 'DO1,DO2,EXT1,EXT2';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    s := 'Opx+Ram18bit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Opx+RamSpdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'Pcmd8DoEo';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := 'DO,EO';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    s := 'Pcmd8Spdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'Rp2a03Ctl';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'Rp2a03+ExtMask';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMaskVrc6';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMaskVrc7';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMaskRp2c33';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMaskMmc5';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMask163';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtMask5b';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtRegRead';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
//    s := 'Rp2a03+ExtMmc5Read';
//    key := KeyListBox.Items.Values[s];
//    if key<>'' then
//    begin
//			SetKey(s, ini.ReadString('DeviceForm', s, ''));
//  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
//  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
//    end;
    s := 'Rp2a03+Ext163Read';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Rp2a03+ExtNc';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := 'Low,High';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
    s := 'Rp2a03+ExtRomsel';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
		s := 'Rp2a03+ExtRomselVrc6';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
		s := 'Rp2a03+ExtRomselVrc7';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
		s := 'Rp2a03+ExtRomselRp2c33';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
		s := 'Rp2a03+ExtRomselMmc5';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
		s := 'Rp2a03+ExtRomsel163';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
		s := 'Rp2a03+ExtRomsel5b';
		key := KeyListBox.Items.Values[s];
		if key<>'' then
		begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
			ValueListEditor.ItemProps[key].EditStyle := esSimple;
			ValueListEditor.ItemProps[key].PickList.CommaText := '0,1,2,Default';
			ValueListEditor.ItemProps[key].ReadOnly := True;
		end;
	  //
    s := '052539CompatibleMode';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
	  //
    s := 'Scsp+ScpuCtl';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'Scsp+ScpuExt';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Scsp+Scpu18bit';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Scsp+ScpuSpdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'SpuExt';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'SpuSpdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    //
    s := 'Ssmp+SdspCtl';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
		  SetKey(s, ini.ReadString('DeviceForm', s, ''));
	    ValueListEditor.ItemProps[key].EditStyle := esEllipsis;
    end;
    s := 'Ssmp+SdspType';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;
    s := 'Ssmp+SdspSpdif';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
    end;

    //
    s := 'TabPosition';
    key := KeyListBox.Items.Values[s];
    if key<>'' then
    begin
			SetKey(s, ini.ReadString('DeviceForm', s, ''));
  	  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  ValueListEditor.ItemProps[key].PickList.CommaText := 'Bottom,Left,Right,Top';
  	  ValueListEditor.ItemProps[key].ReadOnly := True;
    end;
    //
    if False then
    begin
	    s := '_RelPath';
  	  key := KeyListBox.Items.Values[s];
    	if key<>'' then
	    begin
				SetKey(s, ini.ReadString('DeviceForm', s, ''));
  		  ValueListEditor.ItemProps[key].EditStyle := esSimple;
  	  	ValueListEditor.ItemProps[key].PickList.CommaText := '0,1';
	    end;
    end;
  finally
  	ini.Free;
    sl.Free;
  end;

  //
	for i := 0 to CONNECT_DEVMAX-1 do
  begin
  	if Cs[i].nIf=IF_INT then
    	Continue;
    Cs[i].DevCB.OnChange(Cs[i].DevCB);
  end;
	//
  PageControl1.ActivePageIndex := 0;
  TabSheet8.TabVisible := MainForm.bDebug;

	//
  LogEdit.Lines.Clear;
  DebugEdit.Lines.Clear;

	//
  LogEdit.Lines.Add('ExeDllFolder:'+MainForm.ExeDllFolder);

	//
  path := Application.ExeName;
  if path='' then
		LogEdit.Lines.Add('psl.exeが使用できない')
  else
  begin
	  LogEdit.Lines.Add('ExePath:'+path);
  	s := ExtractShortPathName(path);
	  DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
  end;
  //
  if MainForm.bGiveio=False then
		LogEdit.Lines.Add('giveioが使用できない');
  //
  path := MainForm.pathPciDebugSys;
  if (path='') or (MainForm.bPciDebugSys=False) then
		LogEdit.Lines.Add('pcidebug.sysが使用できない')
  else
  begin
  	LogEdit.Lines.Add('DllPath:'+path);
	  s := ExtractShortPathName(path);
  	DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
  end;
  //
  path := MainForm.pathPciDebugDll;
  if (path='') or (MainForm.bPciDebugDll=False) then
		LogEdit.Lines.Add('pcidebug.dllが使用できない')
  else
  begin
  	LogEdit.Lines.Add('DllPath:'+path);
	  s := ExtractShortPathName(path);
  	DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
  end;
  //
  path := MainForm.pathMpusbApi;
  if (path='') or (MainForm.bMpusbApi=False) then
		LogEdit.Lines.Add('mpusbapi.dllが使用できない')
  else
  begin
  	LogEdit.Lines.Add('DllPath:'+path);
	  s := ExtractShortPathName(path);
  	DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
    LogEdit.Lines.Add('MPUSBGetDLLVersion:$'+IntToHex(MainForm.MPUSBGetDLLVersion, 8));
  end;
  //
  path := MainForm.pathFtd2xx;
  if (path='') or (MainForm.bFtd2xx=False) then
		LogEdit.Lines.Add('ftd2xx.dllが使用できない')
  else
  begin
  	LogEdit.Lines.Add('DllPath:'+path);
	  s := ExtractShortPathName(path);
  	DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
    s := 'FT_GetLibraryVersion:';
		if MainForm.FT_GetLibraryVersion(@dwLibraryVer)=FT_OK then
    	s := s +'$'+ IntToHex(dwLibraryVer, 8)
    else
    	s := s + 'エラー';
    LogEdit.Lines.Add(s);
  end;
  //
  path := MainForm.pathZlib1;
  if (path='') or (MainForm.bZlib1=False) then
		LogEdit.Lines.Add('zlib1.dllが使用できない')
  else
  begin
	  LogEdit.Lines.Add('DllPath:'+path);
  	s := ExtractShortPathName(path);
	  DebugEdit.Lines.Add('ExtractShortPathName:'+s);
		LogEdit.Lines.Add(GetFileVer(s));
    LogEdit.Lines.Add('zlibVersion:'+MainForm.zlibVersion);
    LogEdit.Lines.Add('zlibCompileFlags:$'+IntToHex(MainForm.zlibCompileFlags, 8));
  end;

	//
  LogEdit.Lines.Add('dwPlatformId:'+IntToStr(MainForm.OSVerInfo.dwPlatformId));
  LogEdit.Lines.Add('QueryPerformanceFrequency:'+IntToStr(MainForm.nFreq));

  //
  for i := 0 to OPL3_DEVMAX-1 do
  begin
 		Opl3[i].dwBase := $ffffffff;
 		Opl3[i].dwDevAddr := 0;
  end;
  //
  for i := 0 to ROMEO_DEVMAX-1 do
  begin
  	//
	 	Romeo[i].dwBase := $ffffffff;
 		Romeo[i].dwDevAddr := 0;
		Romeo[i].xX2 := 0;	//7.9872M/7.670454M
  	Romeo[i].xX3 := 0;	//3.579545M
		Romeo[i].bYM2151 := False;
  	Romeo[i].bYMF288 := False;
  end;

 	//内蔵の検索
  sl := TStringList.Create;
 	try
    //OPL3互換
	  if (MainForm.bGiveio=True) and (MainForm.bPciDebugSys=True) and (MainForm.bPciDebugDll=True) then
	  begin
	    sl.Add(IntToHex(ID_DS1, 8)+'="DS-1,24576000"');
	    sl.Add(IntToHex(ID_DS1L, 8)+'="DS-1L,24576000"');
	    sl.Add(IntToHex(ID_DS1S, 8)+'="DS-1S,24576000"');
	    sl.Add(IntToHex(ID_DS1E, 8)+'="DS-1E,24576000"');
      sl.Add(IntToHex(ID_SOLO1, 8)+'="SOLO-1/1E,14318180"');
    end;
	  //ROMEO
	  if (MainForm.bPciDebugSys=True) and (MainForm.bPciDebugDll=True) then
	  begin
  	  sl.Add(IntToHex(ID_ROMEO_DEV, 8)+'="OPM,4000000","OPN3-L,8000000"');
		  sl.Add(IntToHex(ID_ROMEO, 8)+'="OPM,4000000","OPN3-L,8000000"');
    end;
    //※テスト用
    if False then
    begin
  	  sl.Add(IntToHex(ID_TEST, 8)+'="""OPM,OPP,OPZ"",4000000","OPN3-L,8000000"');
    end;
    //検索
	  if (MainForm.bPciDebugSys=True) and (MainForm.bPciDebugDll=True) then
	   	sl.CommaText := FindPciDevice(sl.CommaText);

    //PIT
	  if MainForm.bGiveio=True then
    begin
    	//ATか確認
      key0 := GetKeyboardType(0);
      key1 := GetKeyboardType(1);
  		LogEdit.Lines.Add('GetKeyboardType(0):'+IntToStr(key0));
  		LogEdit.Lines.Add('GetKeyboardType(1):$'+IntToHex(key1, 4));
      if (key0=7) and ((key1 and $ff00)<>$0000) then
      begin
      	//その他
      end else
      begin
      	//AT
		    sl.Insert(0, IntToStr($0040)+',PIT,'+FloatToStr(14318180/12));
      end;
    end;

    //登録
 		with TStringList.Create do
 		begin
    	try
      	//
	      for i := 0 to sl.Count-1 do
		    begin
  				CommaText := sl.Strings[i];
		  	  for j := 0 to CONNECT_DEVMAX-1 do
		    	begin
        		//
			      if Cs[j].nIf<>IF_INT then
			       	Continue;
    	      if Cs[j].Chk.Enabled then
      	     	Continue;
        	  //
      			s := Strings[0];
	          if AnsiPos('PCI', s)=1 then
		         	n := StrToIntDef(RightStr(s, Length(s)-3), -1)
    	      else
	    	     	n := StrToIntDef(s, -1);
						//
          	if (n<$0000) or (n>$ffff) then
           		Break;
	          //
  	       	Cs[j].dwDevAddr := n;
				    Cs[j].Chk.Enabled := True;
      			Cs[j].Chk.Caption := s;
        	  Cs[j].DevCB.Items.CommaText := Strings[1];
          	Cs[j].DevCB.ItemIndex := 0;
	          Cs[j].ClkCB.Items.CommaText := Strings[2];
  	        Cs[j].ClkCB.ItemIndex := 0;
    	      //
      	    Delete(0);
		    		LogEdit.Lines.Add(s+':'+CommaText);
          	Break;
	        end;
  	      //
    	  end;
      finally
		    Free;
      end;
    end;
  finally
   	sl.Free;
  end;

  //
  InitEzusb;
  //
  with TStringList.Create do
  begin
  	try
	  	//
  	  Add('-');
  		for i := 0 to EZUSB_DEVMAX-1 do
		  begin
		    if Ezusb[i].hndHandle<>INVALID_HANDLE_VALUE then
    	  	Add(Ezusb[i].Device);
		  end;
  	  //
      n := 1;
	  	for i := 0 to EZUSB_DEVMAX-1 do
	    begin
      	//
  		  EzusbTab[i].DevCb.Items.CommaText := CommaText;
    	  EzusbTab[i].DevCb.ItemIndex := 0;
        if EzusbTab[i].AutoChk.Checked and (n<Count) then
        begin
	    	  EzusbTab[i].DevCb.ItemIndex := n;
          EzusbTab[i].DevCb.OnChange(EzusbTab[i].DevCb);
        	Inc(n);
        end;
	    end;
    finally
    	Free;
    end;
  end;

  //
  InitPic;
  //
  with TStringList.Create do
  begin
  	try
	  	//
  	  Add('-');
  		for i := 0 to PIC_DEVMAX-1 do
		  begin
				if Pic[i].nInstance>=0 then
    	  	Add(Pic[i].Device +'-'+ IntToStr(Pic[i].nInstance));
		  end;
  	  //
      n := 1;
	  	for i := 0 to PIC_DEVMAX-1 do
	    begin
      	//
  		  PicTab[i].DevCb.Items.CommaText := CommaText;
    	  PicTab[i].DevCb.ItemIndex := 0;
        if PicTab[i].AutoChk.Checked and (n<Count) then
        begin
	    	  PicTab[i].DevCb.ItemIndex := n;
          PicTab[i].DevCb.OnChange(PicTab[i].DevCb);
        	Inc(n);
        end;
	    end;
    finally
    	Free;
    end;
  end;

  //
  InitFtdi;
  //
  with TStringList.Create do
  begin
  	try
	  	//
  	  Add('-');
  		for i := 0 to FTDI_DEVMAX-1 do
		  begin
				if Ftdi[i].nInstance>=0 then
    	  	Add(Ftdi[i].Device +'-'+ IntToStr(Ftdi[i].nInstance));
		  end;
  	  //
      n := 1;
	  	for i := 0 to FTDI_DEVMAX-1 do
	    begin
      	//
  		  FtdiTab[i].DevCb.Items.CommaText := CommaText;
    	  FtdiTab[i].DevCb.ItemIndex := 0;
        if FtdiTab[i].AutoChk.Checked and (n<Count) then
        begin
	    	  FtdiTab[i].DevCb.ItemIndex := n;
          FtdiTab[i].DevCb.OnChange(FtdiTab[i].DevCb);
        	Inc(n);
        end;
	    end;
    finally
    	Free;
    end;
  end;

  //ウィンドウ設定
  if (Form.Left<>MaxInt) and (Form.Top<>MaxInt) then
  begin
		DeviceForm.Position := poDesigned;
	  DeviceForm.Left := Form.Left;
	  DeviceForm.Top := Form.Top;
    DeviceForm.Tag := 0;
  end else
  begin
		DeviceForm.Position := poMainFormCenter;
    DeviceForm.Tag := 1;
  end;
  //
  DeviceForm.Visible := Visible;
end;

procedure TDeviceForm.FormShow(Sender: TObject);
  var
  	w, h: Integer;
begin
	//
  DeviceForm.Tag := 0;

  //
  w := TabSheet1.Width;
 	h := TabSheet1.Height;
  case GetIndex('TabPosition', False) of
		0:	PageControl1.TabPosition := tpBottom;
 		1:	PageControl1.TabPosition := tpLeft;
		2:	PageControl1.TabPosition := tpRight;
		else  PageControl1.TabPosition := tpTop;
  end;
	DeviceForm.Width := DeviceForm.Width + (w-TabSheet1.Width);
	DeviceForm.Height := DeviceForm.Height + (h-TabSheet1.Height);
end;


procedure TDeviceForm.SetDeviceForm(n: Integer; s, clock: String);
	var
  	def: String;
    index: Integer;
begin
	//
  def := '0,SSG,3579545';
  with TStringList.Create do
  begin
  	try
  		//
    	CommaText := s;
    	if Count<>3 then
		  	CommaText := def;
    	//
    	index := Cs[n].DevCB.Items.IndexOf(Strings[1]);
 	  	if index<0 then
    	begin
	  		CommaText := def;
      	index := Cs[n].DevCB.Items.IndexOf(Strings[1]);
      end;
   		Cs[n].DevCB.ItemIndex := index;
      //
			Cs[n].Chk.Checked := StrToBoolDef(Strings[0], False);
      if clock<>'' then
   			Cs[n].ClkCB.Items.CommaText := clock;
   		Cs[n].ClkCB.Text := Strings[2];
  	finally
    	Free;
  	end;
  end;
end;


function TDeviceForm.FindPciDevice(id: String): String;
	var
  	sl1, sl2, sl3: TStringList;
    i, n: Integer;
    bus, dev, func: Integer;
    devaddr, addr, reg: DWORD;
    reg2, reg3: Word;
    regstr: String;

  procedure Solo1MixerWait(addr: DWORD);
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

begin
 	//
  sl1 := TStringList.Create;
  sl2 := TStringList.Create;
  sl3 := TStringList.Create;
  try
  	//
    sl1.Clear;
    sl2.CommaText := id;
    for i := 0 to sl2.Count-1 do
    	sl1.Add(sl2.Strings[i]);
		//
    sl2.Clear;
  	for bus := 0 to $ff do
	  begin
  		for dev := 0 to $1f do
	    begin
    	 	for func := 0 to $07 do
  	    begin
        	//
	      	devaddr := (bus shl 8) or (dev shl 3) or func;
          reg := MainForm.FuncCnfRead32(devaddr, $00);
	      	if reg=$ffffffff then
          	Continue;
          //
          regstr := IntToHex(reg, 8);
          DebugEdit.Lines.Add(IntToStr(devaddr)+'='+regstr);
          sl3.CommaText := sl1.Values[regstr];
          if sl3.Count<1 then
          	Continue;
          //
         	case reg of
 	         	ID_DS1, ID_DS1L:
   	         	begin
                //$40, Legacy Audio Control
     	         	//  fedcba98 76543210
                //  0xxxxxxx xxxxxx11
                reg := MainForm.FuncCnfRead16(devaddr, $40) and $8003;
                //$4a, Power Control Register
     	         	//  fedcba98 76543210
                //  xxxxxxxx xxxx0x00
                reg2 := MainForm.FuncCnfRead16(devaddr, $4a) and $000b;
                if (reg=$0003) and (reg2=$0000) then
                begin
                 	//$42, Extended Legacy Audio Control
 	      	        case MainForm.FuncCnfRead16(devaddr, $42) and 3 of
                  	0: addr := $0388;
 	        	       	1: addr := $0398;
   	        	     	2: addr := $03a0;
     	        	   	else addr := $03a8;
      	          end;
	                n := AddOpl3(devaddr, addr);
	    	      	  if n>=0 then
                  	sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[0]+','+IntToStr(n));
         	      end else
                begin
                 	//OPL3無効
                  if reg=$0003 then
	                  LogEdit.Lines.Add('エラー:PCI'+IntToStr(devaddr)+'が省電力状態');
							 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+'=$'+IntTohex(reg, 4)+',$'+IntTohex(reg2, 4));
                end;
         	    end;
 	         	ID_DS1S, ID_DS1E:
             	begin
                //$40, Legacy Audio Control
   	           	//  fedcba98 76543210
                //  0xxxxxxx xxxxxx11
                reg := MainForm.FuncCnfRead16(devaddr, $40) and $8003;
                //$4a, Power Control 1
   	           	//  fedcba98 76543210
                //  xxxxxxxx xxxxx0x0
                reg2 := MainForm.FuncCnfRead16(devaddr, $4a) and $0005;
                //$4e, Power Control 2
   	           	//  fedcba98 76543210
                //  xxxxxxxx xxxxx00x
                reg3 := MainForm.FuncCnfRead16(devaddr, $4e) and $0006;
                if (reg=$0003) and (reg2=$0000) and (reg3=$0000) then
                begin
                  //$60, FM Synthesizer Base Address
    	            addr := MainForm.FuncCnfRead16(devaddr, $60) and $fffc;
	                n := AddOpl3(devaddr, addr);
	    	      	  if n>=0 then
	    		        	sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[0]+','+IntToStr(n));
         	      end else
                begin
                 	//OPL3無効
                  if reg=$0003 then
	                  LogEdit.Lines.Add('エラー:PCI'+IntToStr(devaddr)+'が省電力状態');
							 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+'=$'+IntTohex(reg, 4)+',$'+IntTohex(reg2, 4)+',$'+IntTohex(reg3, 4));
                end;
              end;
            ID_SOLO1:
            	begin
              	//$08, Revision ID
                reg := MainForm.FuncCnfRead8(devaddr, $08);
     	        	//$14, SB Base for Native-PCI-Audio
 		            addr := MainForm.FuncCnfRead32(devaddr, $14) and $fffffffe;
                //$40, Legacy Audio Control
   	           	//  fedcba98 76543210
                //  1xxxxxxx xxxxxx11
                reg2 := MainForm.FuncCnfRead16(devaddr, $40);
                if ((reg in [$01])=True) and ((reg2 and $8003)=$8003) then
                begin
  	              //addr+$07, Power Management Register
	   	           	//  76543210
  	              //  xx0xxxxx
                  reg3 := MainForm.IoRead8(addr+$07);
                  if (reg3 and $20)=$00 then
                  begin
		                n := AddOpl3(devaddr, addr);
		    	      	  if n>=0 then
	  	  		        	sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[0]+','+IntToStr(n));
                  end else
                  begin
	                 	//FM無効
								 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+'=$'+IntTohex(reg, 2)+',$'+IntTohex(addr, 8)+',$'+IntTohex(reg2, 4)+',$'+IntTohex(reg3, 2));
 	    		          if True then
    		            begin
                    	//FMを有効にする
 	  	  		          //addr+$07, Power Management Register
		                  MainForm.IoWrite8(addr+$07, reg3 and $df);
		                  reg3 := MainForm.IoRead8(addr+$07);
									 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+'=$'+IntTohex(reg, 2)+',$'+IntTohex(addr, 8)+',$'+IntTohex(reg2, 4)+',$'+IntTohex(reg3, 2));
                      //Mixer$36, FM Volume Register
                      Solo1MixerWait(addr);
		                  MainForm.IoWrite8(addr+$4, $36);
                      Solo1MixerWait(addr);
		                  reg3 := MainForm.IoRead8(addr+$5);
									 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+',Mixer$36=$'+IntTohex(reg3, 2));
                      //Mixer$48, Serial Mode Miscellaneous Control
                      Solo1MixerWait(addr);
		                  MainForm.IoWrite8(addr+$4, $48);
                      Solo1MixerWait(addr);
		                  reg3 := MainForm.IoRead8(addr+$5);
                      if (reg3 and $10)<>0 then
                      begin
	                      Solo1MixerWait(addr);
			                  MainForm.IoWrite8(addr+$5, reg3 and $ef);
                      end;
									 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+',Mixer$48=$'+IntTohex(reg3, 2));
                      //Mixer$7f, I2S Interface
                      Solo1MixerWait(addr);
		                  MainForm.IoWrite8(addr+$4, $7f);
                      Solo1MixerWait(addr);
		                  reg3 := MainForm.IoRead8(addr+$5);
                      if (reg3 and $01)<>0 then
                      begin
	                      Solo1MixerWait(addr);
			                  MainForm.IoWrite8(addr+$5, reg3 and $fe);
                      end;
									 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+',Mixer$7f=$'+IntTohex(reg3, 2));
                      //
                      Solo1MixerWait(addr);
	                  end;
                  end;
                end else
                begin
                 	//FM無効
							 		DebugEdit.Lines.Add('PCI'+IntToStr(devaddr)+'=$'+IntTohex(reg, 2)+',$'+IntTohex(addr, 8)+',$'+IntTohex(reg2, 4)+',');
                end;
              end;
            ID_ROMEO_DEV, ID_ROMEO:
 	           	begin
								//
     	         	addr := MainForm.FuncCnfRead32(devaddr, $14);
                n := AddRomeo(devaddr, addr);
                if n>=0 then
                begin
                	//
                 	with TStringList.Create do
                  begin
                  	try
                    	//
		                 	if Romeo[n].xX3>0 then
  		                begin
    	                	CommaText := sl3.Strings[0];
      	                Strings[1] := Strings[1] +','+ FloatToStr(Romeo[n].xX3);
        	            	sl3.Strings[0] := CommaText;
          	          end;
      	    	       	if Romeo[n].xX2>0 then
    	        	      begin
                	    	CommaText := sl3.Strings[1];
                  	    Strings[1] := Strings[1] +','+ FloatToStr(Romeo[n].xX2);
	                    	sl3.Strings[1] := CommaText;
  		                end;
                    finally
	                    Free;
                    end;
	                end;
         	      	//OPM
	                if Romeo[n].bYM2151 then
	    		        	sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[0]+','+IntToStr(n));
   	            	//OPN3-L
	                if Romeo[n].bYMF288 then
		    	        	sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[1]+','+IntToStr(n));
                end;
       	      end;
            ID_TEST:
 	           	begin
              	//
              	n := 0;
                if n>=0 then
                begin
                	//
	               	with TStringList.Create do
	                begin
	                 	try
  	                  //
 	  	              	CommaText := sl3.Strings[0];
   	  	              Strings[1] := Strings[1] +','+ FloatToStr(1234567);
     	  	          	sl3.Strings[0] := CommaText;
          	   	    	CommaText := sl3.Strings[1];
            	   	    Strings[1] := Strings[1] +','+ FloatToStr(2345678);
              	    	sl3.Strings[1] := CommaText;
                	    //
		   		        		sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[0]+','+IntToStr(n));
		    	        		sl2.Add('PCI'+IntToStr(devaddr)+','+sl3.Strings[1]+','+IntToStr(n));
	                  finally
		                  Free;
    	              end;
	    	          end;
    	          end;
              end;
         	end;
	      end;
	    end;
	  end;
    //
    Result := sl2.CommaText;
  finally
  	sl1.Free;
    sl2.Free;
    sl3.Free;
  end;
end;

function IntToBin(Value: Integer; Digits: Integer): String;
	var
  	bit: DWORD;
begin
	//
  Result := '';
  bit := Value;
  while (bit<>0) or (Digits>0) do
  begin
  	Result := Chr($30+(bit and 1))+Result;
    bit := bit shr 1;
    Dec(Digits);
  end;
end;

function TDeviceForm.AddOpl3(devaddr, base: DWORD): Integer;
	var
    i: Integer;
begin
	//
  Result := -1;
  for i := 0 to OPL3_DEVMAX-1 do
  begin
    //
	  if Opl3[i].dwBase<>$ffffffff then
    	Continue;
    //
 		Opl3[i].dwBase := base;
 		Opl3[i].dwDevAddr := devaddr;
    //
    Result := i;
    Break;
  end;
end;

function TDeviceForm.AddRomeo(devaddr, base: DWORD): Integer;
	var
    i, j: Integer;
    s: String;
    xsr3, xsr2: Word;
	var
  	path: String;
	  ini: TIniFile;
    clk: Extended;
begin
	//
  Result := -1;
  for i := 0 to ROMEO_DEVMAX-1 do
  begin
    //
	  if Romeo[i].dwBase<>$ffffffff then
    	Continue;
		//
 		Romeo[i].dwBase := base;
 		Romeo[i].dwDevAddr := devaddr;

		//
  	xsr3 := 0;
		MainForm.FuncMemWrite32(base+$001c, $00000001);
	  for j := 0 to 15 do
   	begin
	  	xsr3 := (xsr3 shl 1) or ((MainForm.FuncMemRead32(base+$001c) shr 31) and 1);
      Sleep(1);
	  end;
		//
	  xsr2 := 0;
		MainForm.FuncMemWrite32(base+$011c, $00000001);
  	for j := 0 to 15 do
    begin
		  xsr2 := (xsr2 shl 1) or ((MainForm.FuncMemRead32(base+$011c) shr 31) and 1);
   	  Sleep(35);
    end;

		//
	 	path := ChangeFileExt(Application.ExeName, '.ini');
  	ini := TIniFile.Create(path);
	  try
  		//
 			DebugEdit.Lines.Add(IntToBin(xsr3, 16));
    	if (xsr3<>$0000) and (xsr3<>$ffff) then
    	begin
	    	s := ini.ReadString('DeviceForm', 'Pci'+IntToStr(devaddr)+'X3', '');
        clk := StrToFloatDef(s, 3579545);
        if (clk>=CLK_MIN) and (clk<=CLK_MAX) then
			  	Romeo[i].xX3 := clk;
    	end;
 	 		DebugEdit.Lines.Add(IntToBin(xsr2, 16));
   		if (xsr2<>$0000) and (xsr2<>$ffff) then
    	begin
	    	s := ini.ReadString('DeviceForm', 'Pci'+IntToStr(devaddr)+'X2', '');
        clk := StrToFloatDef(s, 7987200);
        if (clk>=CLK_MIN) and (clk<=CLK_MAX) then
					Romeo[i].xX2 := clk;
    	end;
	  finally
  		ini.Free;
	  end;

    //
		MainForm.FuncMemWrite32(base+$001c, $00000000);
		MainForm.FuncMemWrite32(base+$011c, $00000000);
	  Sleep(10);
		MainForm.FuncMemWrite32(base+$001c, $00000080);
	 	MainForm.FuncMemWrite32(base+$0000, $00000000);
	 	MainForm.FuncMemWrite32(base+$0010, $80000000);
		MainForm.FuncMemWrite32(base+$011c, $00000080);
    Romeo[i].xYM2151Clk := 4000000;
 	  Romeo[i].xYMF288Clk := 8000000;
  	Sleep(50);
		//
		if (MainForm.FuncMemRead32(base+$0004) and $80)=$00 then
			Romeo[i].bYM2151 := True;
		if (MainForm.FuncMemRead32(base+$0100) and $80)=$00 then
		  Romeo[i].bYMF288 := True;
   	//
    DebugEdit.Lines.Add(IntToHex(base, 8));
		s := IntToStr(i)+',';
 	  if Romeo[i].xX2>0 then
   	 	s := s + 'x2,';
    if Romeo[i].xX3>0 then
 	   	s := s + 'x3,';
   	if Romeo[i].bYM2151 then
     	s := s + 'opm_'+FloatToStr(Romeo[i].xYM2151Clk)+',';
    if Romeo[i].bYMF288 then
 	  	s := s + 'opn3-l_'+FloatToStr(Romeo[i].xYMF288Clk);
		DebugEdit.Lines.Add(s);
    //
    Result := i;
    Break;
  end;
end;

function TDeviceForm.InitEzusb: Boolean;
	var
		hnd: THandle;
    i, j, cnt: Integer;
  	s, t: String;
	var
    r: LongBool;
		txsz, rxsz: Cardinal;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
		dd: TUSB_DEVICE_DESCRIPTOR;
		ii: TUSBD_INTERFACE_INFORMATION;
		sd: TGET_STRING_DESCRIPTOR_IN;
    btc: TBULK_TRANSFER_CONTROL;
  var
  	dev, rev: String;
		sdbuf: array[0..128-1] of Char;
begin
	//
  cnt := 0;
  for i := 0 to EZUSB_DEVLIM-1 do
  begin
		//
    if cnt>=EZUSB_DEVMAX then
    	Break;
    //
		dev := 'EZUSB-'+IntToStr(i);
	  hnd := CreateFile( PChar('\\.\'+dev), GENERIC_WRITE, FILE_SHARE_WRITE, nil,
    	OPEN_EXISTING, 0, 0 );
		if hnd=INVALID_HANDLE_VALUE then
	    Continue;

    //
		r := DeviceIoControl(hnd, IOCTL_Ezusb_GET_DEVICE_DESCRIPTOR,
    	nil, 0, @dd, SizeOf(dd), rxsz, nil);
	  if r=False then
	  begin
		  CloseHandle(hnd);
	    Continue;
	  end;
    //
    if (dd.idVendor<>$547) or (dd.idProduct<>$1002) then
	  begin
		  CloseHandle(hnd);
      LogEdit.Lines.Add('エラー:"'+dev+'"、ファームウェアがダウンロードされていない');
	    Continue;
	  end;

    //
		r := DeviceIoControl(hnd, IOCTL_Ezusb_GET_PIPE_INFO,
    	nil, 0, @ii, SizeOf(ii), rxsz, nil);
	  if r=False then
	  begin
		  CloseHandle(hnd);
	    Continue;
	  end;
    //
    if ii.NumberOfPipes<>4 then
    begin
			CloseHandle(hnd);
 	  	Continue;
    end;
    //
    for j := 0 to ii.NumberOfPipes-1 do
    begin
	    s := IntToStr(j)+',';
      case ii.Pipes[j].PipeType of
		    UsbdPipeTypeControl:
        	s := s + 'Control,';
		    UsbdPipeTypeIsochronous:
        	s := s + 'Isochronous,';
		    UsbdPipeTypeBulk:
        	s := s + 'Bulk,';
		    UsbdPipeTypeInterrupt:
        	s := s + 'Interrupt,';
        else
        	s := s + '?,';
      end;
      s := s + IntToStr(ii.Pipes[j].bEndpointAddress and $0f)+',';
      if ((ii.Pipes[j].bEndpointAddress shr 7) and 1)=0 then
      	s := s + 'out,'
      else
      	s := s + 'in,';
      s := s + IntToStr(ii.Pipes[j].wMaximumPacketSize);
    	DebugEdit.Lines.Add(s);
    end;

    //
    case dd.bcdUSB of
    	$0100:
      	begin
			  	//MINI EZ-USB
		    	Ezusb[cnt].bFx2 := False;
		    	Ezusb[cnt].nSyncFreq := 100;
          Ezusb[cnt].nAddrWidth := 3;
        end;
      $0200:
      	begin
			  	//MINI FX2
		    	Ezusb[cnt].bFx2 := True;
		    	Ezusb[cnt].nSyncFreq := 200;
          Ezusb[cnt].nAddrWidth := 3;
        end;
      else
      	begin
					CloseHandle(hnd);
    	  	Continue;
        end;
    end;

    //
		sd.Index := 2;
		sd.LanguageId := 27;
		r := DeviceIoControl(hnd, IOCTL_Ezusb_GET_STRING_DESCRIPTOR,
    	@sd, SizeOf(sd), @sdbuf, SizeOf(sdbuf), rxsz, nil);
	  if r=False then
	  begin
		  CloseHandle(hnd);
	    Continue;
	  end;
    //
		s := '';
    for j := 1 to (Ord(sdbuf[0]) div 2)-1 do
    	s := s + sdbuf[j*2];
    //
    t := 'EZ-USB Sound Generator Device';
	  if AnsiPos(t, s)<>1 then
	  begin
			CloseHandle(hnd);
      LogEdit.Lines.Add('エラー:"'+dev+'"、対応していないファームウェア');
	  	Continue;
	  end;
    //
   	rev := Copy(s, Length(t)+2, Length(s)-Length(t));
    if rev<>MainForm.sRevString then
    begin
			CloseHandle(hnd);
      LogEdit.Lines.Add('エラー:"'+dev+'"、対応していないリビジョン');
      Continue;
    end;

    //
	  txsz := 0;
  	txbf[txsz] := CTL_RESET;
		Inc(txsz);
 		btc.pipeNum := PIPE_CTLCMD;
	 	r := DeviceIoControl(hnd, IOCTL_EZUSB_BULK_WRITE,
  		@btc, SizeOf(btc), @txbf, txsz, rxsz, nil);
		if r=False then
	  begin
    	CloseHandle(hnd);
  	  Continue;
	  end;

    //
    Ezusb[cnt].hndHandle := hnd;
    Ezusb[cnt].Device := dev;
    Ezusb[cnt].Rev := rev;
    //
    with TStringList.Create do
    begin
    	try
	    	//
	  	  Add(IntToStr(cnt)+':'+Ezusb[cnt].Device);
  		  Add(Ezusb[cnt].Rev);
	  	  if Ezusb[cnt].bFx2 then
	    		Add('MINI FX2')
	    	else
			    Add('MINI EZ-USB');
		    Add(IntToStr(Ezusb[cnt].nSyncFreq)+'Hz');
		    Add(IntToStr(Ezusb[cnt].nAddrWidth));
      	LogEdit.Lines.Add(CommaText);
      finally
      	Free;
      end;
    end;
    Inc(cnt);
  end;

  //
  Result := False;
  if cnt>0 then
		Result := True;
end;

function TDeviceForm.ResetEzusb(n: Integer): Boolean;
	var
    r: LongBool;
		txsz, rxsz: Cardinal;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
    btc: TBULK_TRANSFER_CONTROL;
begin
	//
  Result := False;
	if Ezusb[n].hndHandle=INVALID_HANDLE_VALUE then
  	Exit;

	//
  txsz := 0;
  txbf[txsz] := CTL_RESET;
	Inc(txsz);
  txbf[txsz] := CTL_START;
  Inc(txsz);
  //
 	btc.pipeNum := PIPE_CTLCMD;
 	r := DeviceIoControl(Ezusb[n].hndHandle, IOCTL_EZUSB_BULK_WRITE,
  	@btc, SizeOf(btc), @txbf, txsz, rxsz, nil);
	if r=False then
    Exit;

  //
  Result := True;
end;

procedure TDeviceForm.CloseEzusb;
	var
  	i: Integer;
begin
  //
  for i := 0 to EZUSB_DEVMAX-1 do
  begin
		if Ezusb[i].hndHandle<>INVALID_HANDLE_VALUE then
    begin
			CloseHandle(Ezusb[i].hndHandle);
      Ezusb[i].hndHandle := INVALID_HANDLE_VALUE;
    end;
  end;
end;


function TDeviceForm.InitPic: Boolean;
	var
		hnd: THandle;
    phndwrite, phndread: THandle;
    i, j, cnt: Integer;
  	s, t: String;
	var
		r, txsz, rxsz: DWORD;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
    psd: Boolean;
  var
  	dev, rev, devstr: String;
    sdlen: DWORD;
		sdbuf: array[0..128-1] of Char;
begin
	//
  Result := False;
  if MainForm.bMpusbApi=False then
  	Exit;

  //
	dev := 'vid_1781&pid_0926';
  cnt := 0;
  for i := 0 to Integer(MainForm.MPUSBGetDeviceCount(PChar(dev)))-1 do
  begin
		//
    if cnt>=PIC_DEVMAX then
    	Break;
    //
		hnd := MainForm.MPUSBOpen(i, PChar(dev), nil, MP_READ, 0);
		if hnd=INVALID_HANDLE_VALUE then
	    Continue;
    devstr := IntToStr(cnt)+':'+dev +'-'+ IntToStr(i);

    //Index=0: #9
    //      1: 'OPTIMIZE'
    //      2: 'PIC32USB'/'PIC32USB Sound Generator Device r#.##'
		if MainForm.MPUSBGetStringDescriptor(hnd, 2{Index}, 0{LangId}, @sdbuf, SizeOf(sdbuf),
    	@sdlen)=MPUSB_FAIL then
    begin
			CloseHandle(hnd);
	  	Continue;
    end;
		CloseHandle(hnd);
    //
		s := '';
    for j := 1 to (Ord(sdbuf[0]) div 2)-1 do
    	s := s + sdbuf[j*2];
    //
	  if LeftStr(s, Length('PIC32USB'))<>'PIC32USB' then
	  	Continue;
    psd := False;
	  if s<>'PIC32USB' then
	    psd := True;

    //
		phndwrite := MainForm.MPUSBOpen(i, PChar(dev), PChar('\MCHP_EP2'), MP_WRITE, 0);
		phndread := MainForm.MPUSBOpen(i, PChar(dev), PChar('\MCHP_EP2'), MP_READ, 0);
		if (phndwrite=INVALID_HANDLE_VALUE) or (phndread=INVALID_HANDLE_VALUE) then
    begin
			CloseHandle(phndwrite);
			CloseHandle(phndread);
	  	Continue;
    end;

    //
	  txsz := 2;
  	txbf[txsz] := CTL_RESET;
		Inc(txsz);
    if psd=False then
    begin
		  txbf[txsz] := $ff;
  		Inc(txsz);
    end;
  	txbf[0] := (txsz-2) and $ff;
	  txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
		r := MainForm.MPUSBWrite(phndwrite, @txbf, txsz, @rxsz, 5000{INFINITE});
	  DebugEdit.Lines.Add('write=' + IntToStr(r) + ',' + IntToStr(rxsz) +'/'+ IntToStr(txsz));
		if r=MPUSB_FAIL then
	  begin
			CloseHandle(phndwrite);
			CloseHandle(phndread);
      LogEdit.Lines.Add('エラー:"'+devstr+'"、ファームウェアがダウンロードされていない');
  	  Continue;
	  end;

    //
    if psd=False then
    begin
			//
 		  txsz := 64;
			r := MainForm.MPUSBRead(phndread, @txbf, txsz, @rxsz, 5000{INFINITE});
	  	DebugEdit.Lines.Add('read=' + IntToStr(r) + ',' + IntToStr(rxsz) +'/'+ IntToStr(txsz));
			if r=MPUSB_FAIL then
	  	begin
				CloseHandle(phndwrite);
				CloseHandle(phndread);
        LogEdit.Lines.Add('エラー:"'+devstr+'"、ファームウェアがダウンロードされていない');
 			  Continue;
	  	end;
    	//
 		  s := '';
	   	for j := 0 to rxsz-1 do
   			s := s + IntToHex(txbf[j], 2);
  		DebugEdit.Lines.Add('read_data=' + s);
  	  //
	 	  s := '';
   		for j := 0 to rxsz-1 do
  	  begin
	    	if txbf[j]=$00 then
      		Break;
   			s := s + Chr(txbf[j]);
  	  end;
	  	DebugEdit.Lines.Add('read_data=' + s);
    end;

		//
    t := 'PIC32USB Sound Generator Device';
	  if AnsiPos(t, s)<>1 then
    begin
			CloseHandle(phndwrite);
			CloseHandle(phndread);
      LogEdit.Lines.Add('エラー:"'+devstr+'"、対応していないファームウェア');
	  	Continue;
    end;
    //
   	rev := Copy(s, Length(t)+2, Length(s)-Length(t));
    if rev<>MainForm.sRevString then
    begin
			CloseHandle(phndwrite);
			CloseHandle(phndread);
      LogEdit.Lines.Add('エラー:"'+devstr+'"、対応していないリビジョン');
	  	Continue;
    end;

		//
    Pic[cnt].nInstance := i;
    Pic[cnt].Device := dev;
    Pic[cnt].Rev := rev;
   	Pic[cnt].hndWrite := phndwrite;
   	Pic[cnt].hndRead := phndread;
   	Pic[cnt].nSyncFreq := 44100 div 45;
    Pic[cnt].nAddrWidth := 10;
    //
    with TStringList.Create do
    begin
    	try
	    	//
	  	  Add(devstr);
  		  Add(Pic[cnt].Rev);
		    Add('PIC32USB');
		    Add(IntToStr(Pic[cnt].nSyncFreq)+'Hz');
		    Add(IntToStr(Pic[cnt].nAddrWidth));
      	LogEdit.Lines.Add(CommaText);
      finally
      	Free;
      end;
    end;
    Inc(cnt);
  end;

  //
  if cnt>0 then
		Result := True;
end;

function TDeviceForm.ResetPic(n: Integer): Boolean;
	var
		r, txsz, rxsz: DWORD;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
begin
	//
  Result := False;
	if Pic[n].nInstance<0 then
  	Exit;

  //
  txsz := 2;
 	txbf[txsz] := CTL_RESET;
	Inc(txsz);
  txbf[txsz] := CTL_START;
  Inc(txsz);
  txbf[0] := (txsz-2) and $ff;
  txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
	r := MainForm.MPUSBWrite(Pic[n].hndWrite, @txbf, txsz, @rxsz, 5000{INFINITE});
  DebugEdit.Lines.Add('write=' + IntToStr(r) + ',' + IntToStr(rxsz) +'/'+ IntToStr(txsz));
	if r=MPUSB_FAIL then
    Exit;

  //
  Result := True;
end;

procedure TDeviceForm.ClosePic;
	var
  	i: Integer;
begin
  //
  for i := 0 to PIC_DEVMAX-1 do
  begin
		if Pic[i].nInstance<0 then
    	Continue;
		Pic[i].nInstance := -1;
		CloseHandle(Pic[i].hndWrite);
		CloseHandle(Pic[i].hndRead);
    Pic[i].hndWrite := INVALID_HANDLE_VALUE;
    Pic[i].hndRead := INVALID_HANDLE_VALUE;
  end;
end;


function TDeviceForm.InitFtdi: Boolean;
	var
    i, j, cnt: Integer;
  	s, t: String;
		numDevs: DWORD;
		devInfo, p: PFT_DEVICE_LIST_INFO_NODE;
		phnddevice: FT_HANDLE;
	var
		txsz, rxsz: DWORD;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
  var
  	dev, chip, rev, devstr: String;
begin
	//
  Result := False;
  if MainForm.bFtd2xx=False then
  	Exit;

	//
	if MainForm.FT_CreateDeviceInfoList(@numDevs)<>FT_OK then
  	Exit;
	if numDevs<1 then
  	Exit;
  //
  devInfo := nil;
	try
		i := SizeOf(TFT_DEVICE_LIST_INFO_NODE)*numDevs;
		GetMem(devInfo, i);
		FillChar(devInfo^, i, $00);
		if MainForm.FT_GetDeviceInfoList(devInfo, @numDevs)<>FT_OK then
    	Exit;
    //
    p := devInfo;
	  cnt := 0;
		for i := 0 to numDevs-1 do
		begin
      //
			DebugEdit.Lines.Add('Dev '+IntToStr(i)+':');
			DebugEdit.Lines.Add(' Flags=$'+IntToHex(p^.Flags, 8));
			DebugEdit.Lines.Add(' Type=$'+IntToHex(p^._Type, 8));
			DebugEdit.Lines.Add(' ID=$'+IntToHex(p^.ID, 8));
			DebugEdit.Lines.Add(' LocId=$'+IntToHex(p^.LocId, 8));
			DebugEdit.Lines.Add(' SerialNumber='+p^.SerialNumber);
			DebugEdit.Lines.Add(' Description='+p^.Description);
			DebugEdit.Lines.Add(' ftHandle=$'+IntToHex(DWORD(p^.ftHandle), 8));
  	  if cnt>=FTDI_DEVMAX then
	    	Break;

			//
			dev := 'vid_'+LowerCase(IntToHex((p^.ID shr 16) and $ffff, 4))+
      	'&pid_'+LowerCase(IntToHex(p^.ID and $ffff, 4));
			devstr := IntToStr(cnt)+':'+dev +'-'+ IntToStr(i);

			//
      s := p^.Description;
			t := 'Sound Generator Device';
      j := AnsiPos(t, s);
			if j<1 then
			begin
				LogEdit.Lines.Add('エラー:"'+devstr+'"、対応していない Product_Description');
				Continue;
			end;
      chip := Trim(LeftStr(s, j-1));
      if chip='' then
      	chip := 'FTDI';
			//
			rev := Trim(RightStr(s, Length(s)-((j-1)+Length(t))));
			if rev<>MainForm.sRevString then
			begin
				LogEdit.Lines.Add('エラー:"'+devstr+'"、対応していないリビジョン');
				Continue;
			end;

      //
			if MainForm.FT_Open(i, @phnddevice)<>FT_OK then
      begin
				LogEdit.Lines.Add('エラー:"'+devstr+'"、FT_Open失敗');
				Continue;
      end;
      //
      if GetBool('FtdiSetBitMode')=False then
      	j := FT_BITMODE_RESET
      else
      	j := FT_BITMODE_SYNC_FIFO;
      if MainForm.FT_SetBitMode(phnddevice, $ff, j and $ff)<>FT_OK then
      begin
				MainForm.FT_Close(phnddevice);
				LogEdit.Lines.Add('エラー:"'+devstr+'"、FT_SetBitMode($ff, $'+LowerCase(IntToHex(j ,2))+')失敗');
				Continue;
      end;
			//
			txsz := 2;
			txbf[txsz] := CTL_RESET;
			Inc(txsz);
			txbf[0] := (txsz-2) and $ff;
			txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
			if MainForm.FT_Write(phnddevice, @txbf, txsz, @rxsz)<>FT_OK then
			begin
				MainForm.FT_Close(phnddevice);
				LogEdit.Lines.Add('エラー:"'+devstr+'"、FT_Write失敗');
				Continue;
			end;

			//
			Ftdi[cnt].nInstance := i;
			Ftdi[cnt].Device := dev;
			Ftdi[cnt].Rev := rev;
			Ftdi[cnt].hndDevice := phnddevice;
			Ftdi[cnt].nSyncFreq := 44100;
			Ftdi[cnt].nAddrWidth := 10;
			//
			with TStringList.Create do
			begin
				try
					//
					Add(devstr);
					Add(Ftdi[cnt].Rev);
					Add(chip);
					Add(IntToStr(Ftdi[cnt].nSyncFreq)+'Hz');
					Add(IntToStr(Ftdi[cnt].nAddrWidth));
					LogEdit.Lines.Add(CommaText);
				finally
					Free;
				end;
			end;
      Inc(p);
			Inc(cnt);
		end;
	finally
		FreeMem(devInfo);
	end;

  //
  if cnt>0 then
		Result := True;
end;

function TDeviceForm.ResetFtdi(n: Integer): Boolean;
	var
		txsz, rxsz: DWORD;
		txbf: array[0..EZUSB_PIC_FTDI_BUFSIZE-1] of Byte;
begin
	//
  Result := False;
	if Ftdi[n].nInstance<0 then
  	Exit;

  //
  txsz := 2;
 	txbf[txsz] := CTL_RESET;
	Inc(txsz);
  txbf[txsz] := CTL_START;
  Inc(txsz);
  txbf[0] := (txsz-2) and $ff;
  txbf[1] := (PIPE_CTLCMD shl 6) or (((txsz-2) shr 8) and $3f);
	if MainForm.FT_Write(Ftdi[n].hndDevice, @txbf, txsz, @rxsz)<>FT_OK then
    Exit;

  //
  Result := True;
end;

procedure TDeviceForm.CloseFtdi;
	var
  	i: Integer;
begin
  //
  for i := 0 to FTDI_DEVMAX-1 do
  begin
		if Ftdi[i].nInstance<0 then
    	Continue;
		Ftdi[i].nInstance := -1;
		MainForm.FT_Close(Ftdi[i].hndDevice);
    Ftdi[i].hndDevice := nil;
  end;
end;


function TDeviceForm.GetDeviceAddr(s: String): Integer;
begin
	//
 	Result := 0;
  with TStringList.Create do
  begin
  	try
    	//
	  	CommaText := DeviceListBox.Items.Values[s];
      if Count>1 then
	 			Result := StrToIntDef(Strings[1], 0);
    finally
	  	Free;
    end;
  end;
end;

function TDeviceForm.GetDeviceStr(n: Integer): String;
	var
  	i: Integer;
  	s: String;
begin
	//
  with TStringList.Create do
  begin
  	try
    	//
	    Result := '$'+IntToHex(n, 8);
  		for i := 0 to DeviceListBox.Items.Count-1 do
    	begin
    		s := DeviceListBox.Items.Names[i];
		  	CommaText := DeviceListBox.Items.Values[s];
		    if Count>0 then
    	  begin
		 			if Strings[0]=IntToStr(n) then
	      	begin
  	    		Result := s;
	    	    Break;
		      end;
    	  end;
	    end;
    finally
	  	Free;
    end;
  end;
end;

function TDeviceForm.GetDeviceInfo(s: String): Integer;
begin
	//
  with TStringList.Create do
  begin
  	try
	  	//
  		Result := DEVICE_NONE;
  		CommaText := DeviceListBox.Items.Values[s];
	    if Count>0 then
		 		Result := StrToIntDef(Strings[0], DEVICE_NONE);
    finally
	  	Free;
    end;
  end;
end;

function TDeviceForm.GetDeviceRatio(s: String; n: Integer): Extended;
begin
	//
  with TStringList.Create do
  begin
  	try
    	//
	   	Result := 0;
  		CommaText := DeviceListBox.Items.Values[s];
    	if Count>2 then
	    begin
		    CommaText := Strings[2];
	  	  if (n>=0) and ((n*2+1)<Count) then
		  	  Result := StrToFloatDef(Strings[n*2+0], 0);
	    end;
    finally
	  	Free;
    end;
  end;
end;

function TDeviceForm.GetDeviceSel(s: String; n: Integer): String;
begin
	//
  with TStringList.Create do
  begin
  	try
    	//
	   	Result := '';
  		CommaText := DeviceListBox.Items.Values[s];
    	if Count>2 then
	    begin
		    CommaText := Strings[2];
	  	  if (n>=0) and ((n*2+1)<Count) then
		  	  Result := Strings[n*2+1];
	    end;
    finally
	 		Free;
    end;
  end;
end;

function TDeviceForm.GetDeviceCtl(s: String): String;
begin
	//
  with TStringList.Create do
  begin
  	try
    	//
	   	Result := '';
  		CommaText := DeviceListBox.Items.Values[s];
    	if Count>3 then
		    Result := Strings[3];
    finally
	 		Free;
    end;
  end;
end;

procedure TDeviceForm.EnumDevice;
	var
  	i, j, no: Integer;
    dev: Integer;
    s: String;
		clk: Extended;
begin
  //接続デバイス
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
  	//
	  CnDevice[i].nIfSelect := IF_NONE;
  	CnDevice[i].dwIfIntBase := $00000000;
		CnDevice[i].nIfEzusbNo := -1;
		CnDevice[i].nIfPicNo := -1;
		CnDevice[i].nIfEzusbPicFtdiDevCs := 0;
    CnDevice[i].nIfEzusbPicFtdiDevAddr := 0;
		CnDevice[i].nThread := -1;
	  CnDevice[i].nInfo := DEVICE_NONE;
    CnDEvice[i].bAlloc := False;
    if Cs[i].Chk=nil then
    	Continue;
  	if Cs[i].Chk.Checked=False then
    	Continue;
    //
   	clk := StrToFloatDef(Cs[i].ClkCB.Text, 0);
	  if (clk<CLK_MIN) or (clk>CLK_MAX) then
      Continue;
    //
  	s := Cs[i].DevCB.Text;
    dev := GetDeviceInfo(s);
    if dev=DEVICE_NONE then
    	Continue;
    //
    case Cs[i].nIf of
    	IF_INT:
		    begin
		    	//内蔵
    		  case dev of
      			DEVICE_PIT:
		        	begin
							  CnDevice[i].nIfSelect := IF_INT;
						  	CnDevice[i].dwIfIntBase := Cs[i].dwDevAddr;
								CnDevice[i].nThread := 0;
							  CnDevice[i].nInfo := dev;
							  CnDevice[i].xClock := clk;
        		  end;
		        DEVICE_DS1, DEVICE_SOLO1:
    		    	begin
        		  	for j := 0 to OPL3_DEVMAX-1 do
            		begin
		            	s := 'PCI'+IntToStr(Opl3[j].dwDevAddr);
    		        	if s=Cs[i].Chk.Caption then
	      		      begin
									  CnDevice[i].nIfSelect := IF_INT;
						  			CnDevice[i].dwIfIntBase := Opl3[j].dwBase;
										CnDevice[i].nThread := 0;
									  CnDevice[i].nInfo := dev;
									  CnDevice[i].xClock := clk;
            		    Break;
		            	end;
    		        end;
        		  end;
		        DEVICE_OPM, DEVICE_OPP, DEVICE_OPZ:
	  		     	begin
        		  	for j := 0 to ROMEO_DEVMAX-1 do
            		begin
		            	s := 'PCI'+IntToStr(Romeo[j].dwDevAddr);
    		        	if s<>Cs[i].Chk.Caption then
        		      	Continue;
     							//
								  CnDevice[i].nIfSelect := IF_INT;
							  	CnDevice[i].dwIfIntBase := Romeo[j].dwBase;
									CnDevice[i].nThread := 0;
								  CnDevice[i].nInfo := dev;
								  CnDevice[i].xClock := clk;
								  //
						  		if (Romeo[j].xX3>0) and (CompareValue(clk, Romeo[j].xX3, 500)=EqualsValue) then
								  begin
					  				if Romeo[j].xYM2151Clk<>Romeo[j].xX3 then
						    		begin
							  	  	Romeo[j].xYM2151Clk := Romeo[j].xX3;
											MainForm.FuncMemWrite8(Romeo[j].dwBase+$001c, $01);
					  					Sleep(10);
											MainForm.FuncMemWrite8(Romeo[j].dwBase+$001c, $81);
									  	Sleep(50);
						  	  	end;
								  end else
				 					if Romeo[j].xYM2151Clk<>4000000 then
								  begin
							  		Romeo[j].xYM2151Clk := 4000000;
										MainForm.FuncMemWrite8(Romeo[j].dwBase+$001c, $00);
				 						Sleep(10);
										MainForm.FuncMemWrite8(Romeo[j].dwBase+$001c, $80);
							  		Sleep(50);
						  		end;
        		      Break;
            		end;
		          end;
    		    DEVICE_OPN3L:
	      		 	begin
          			for j := 0 to ROMEO_DEVMAX-1 do
		            begin
    		        	s := 'PCI'+IntToStr(Romeo[j].dwDevAddr);
        		    	if s<>Cs[i].Chk.Caption then
            		  	Continue;
		     					//
								  CnDevice[i].nIfSelect := IF_INT;
							  	CnDevice[i].dwIfIntBase := Romeo[j].dwBase;
									CnDevice[i].nThread := 0;
								  CnDevice[i].nInfo := dev;
								  CnDevice[i].xClock := clk;
						      //
					  			if (Romeo[j].xX2>0) and (CompareValue(clk, Romeo[j].xX2, 500)=EqualsValue) then
							  	begin
									 	if Romeo[j].xYMF288Clk<>Romeo[j].xX2 then
							    	begin
								  		Romeo[j].xYMF288Clk := Romeo[j].xX2;
											MainForm.FuncMemWrite8(Romeo[j].dwBase+$011c, $01);
						  				Sleep(10);
											MainForm.FuncMemWrite8(Romeo[j].dwBase+$011c, $81);
								  		Sleep(50);
					  				end;
							  	end else
						 			if Romeo[j].xYMF288Clk<>8000000 then
								  begin
				  					Romeo[j].xYMF288Clk := 8000000;
										MainForm.FuncMemWrite8(Romeo[j].dwBase+$011c, $00);
						 				Sleep(10);
										MainForm.FuncMemWrite8(Romeo[j].dwBase+$011c, $80);
								 		Sleep(50);
					  			end;
		              Break;
    		        end;
        		  end;
		      end;
    		end;
      IF_EZUSB:
		    begin
    			//EZ-USB
		      no := Cs[i].nEzusb;
    		  if (no>=0) and (Cs[i].nAddr>=0) then
		      begin
	  		    if Ezusb[no].hndHandle<>INVALID_HANDLE_VALUE then
  	    		begin
					  	CnDevice[i].nIfSelect := IF_EZUSB;
							CnDevice[i].nIfEzusbNo := no;
							CnDevice[i].nIfEzusbPicFtdiDevCs := ((i-8) shr 1) and 3;
              CnDevice[i].nIfEzusbPicFtdiDevAddr := Cs[i].nAddr;
							CnDevice[i].nThread := 1+no;
			  			CnDevice[i].nInfo := dev;
					  	CnDevice[i].xClock := clk;
    			  end;
		      end;
    		end;
      IF_PIC:
      	begin
        	//PIC
		      no := Cs[i].nPic;
    		  if (no>=0) and (Cs[i].nAddr>=0) then
		      begin
	  		    if Pic[no].nInstance>=0 then
  	    		begin
					  	CnDevice[i].nIfSelect := IF_PIC;
							CnDevice[i].nIfPicNo := no;
							CnDevice[i].nIfEzusbPicFtdiDevCs := ((i-8) shr 1) and 3;
              CnDevice[i].nIfEzusbPicFtdiDevAddr := Cs[i].nAddr;
							CnDevice[i].nThread := 1+EZUSB_DEVMAX+no;
			  			CnDevice[i].nInfo := dev;
					  	CnDevice[i].xClock := clk;
            end;
          end;
        end;
      IF_FTDI:
      	begin
        	//FTDI
		      no := Cs[i].nFtdi;
    		  if (no>=0) and (Cs[i].nAddr>=0) then
		      begin
	  		    if Ftdi[no].nInstance>=0 then
  	    		begin
					  	CnDevice[i].nIfSelect := IF_FTDI;
							CnDevice[i].nIfFtdiNo := no;
							CnDevice[i].nIfEzusbPicFtdiDevCs := ((i-8) shr 1) and 3;
              CnDevice[i].nIfEzusbPicFtdiDevAddr := Cs[i].nAddr;
							CnDevice[i].nThread := 1+EZUSB_DEVMAX+PIC_DEVMAX+no;
			  			CnDevice[i].nInfo := dev;
					  	CnDevice[i].xClock := clk;
            end;
          end;
        end;
	  end;
  end;
end;

procedure TDeviceForm.ClearReqDevice;
	var
  	i: Integer;
begin
	//要求デバイスの初期化
  for i := 0 to REQUEST_DEVMAX-1 do
  begin
  	ReqDevice[i].nInfo := DEVICE_NONE;
    ReqDevice[i].xClock := 0;
	  ReqDevice[i].xClockRatio := 0;
		ReqDevice[i].nNo := -1;
    ReqDevice[i].bAlloc := False;
    ReqDevice[i].Command := '';
  end;
end;

function TDeviceForm.AddReqDevice(cmd: String; info: Integer; clk: Extended): Boolean;
	var
  	i: Integer;
begin
	//
  Result := False;
  if info=DEVICE_NONE then
  	Exit;
	//要求デバイスの追加
  for i := 0 to REQUEST_DEVMAX-1 do
  begin
  	if ReqDevice[i].nInfo<>DEVICE_NONE then
    	Continue;
    //
  	ReqDevice[i].nInfo := info;
    ReqDevice[i].xClock := clk;
    ReqDevice[i].Command := cmd;
	  Result := True;
    Break;
  end;
end;

function TDeviceForm.GetEnumDevice: String;
	var
  	i: Integer;
    s: String;
begin
	//
  s := '';
  for i := 0 to REQUEST_DEVMAX-1 do
 	begin
 		if ReqDevice[i].nInfo=DEVICE_NONE then
  		Break;
    s := s + GetDeviceStr(ReqDevice[i].nInfo)+','
  end;
  //
  if s='' then
  begin
  	Result := '';
    Exit;
  end;
  Result := LeftStr(s, Length(s)-1);
end;

function TDeviceForm.AllocDevice(f: Boolean): Integer;
	var
  	i, j, k, devmax: Integer;
    s, t, u, v: String;
    ratio: Extended;
    opl2: Boolean;
begin
	//
  devmax := 0;
  with TStringList.Create do
  begin
  	try
    	//
			for i := 0 to DeviceListBox.Items.Count-1 do
      begin
  			CommaText := DeviceListBox.Items.Strings[i];
  	  	if Count>2 then
		    begin
		  	  CommaText := Strings[2];
	  		  devmax := Max(Count div 2, devmax);
		    end;
      end;
    finally
	 		Free;
    end;
  end;
  //
	Result := 0;
  if devmax<1 then
  	Exit;

  //
  opl2 := GetBool('Opl2Opll');
  with TStringList.Create do
  begin
  	try
	  	//
  	  for i := 0 to REQUEST_DEVMAX-1 do
 	  	begin
     		if ReqDevice[i].nInfo=DEVICE_NONE then
      		Break;
	      s := IntToStr(i)+'=' + IntToStr(i);
  	    s := s + '['+GetDeviceStr(ReqDevice[i].nInfo)+','+FloatToStr(ReqDevice[i].xClock)+']';
    	  Add(s);
	    end;

		  //割り当て
		  for i := 0 to devmax-1 do
	  	begin
	    	for j := 0 to REQUEST_DEVMAX-1 do
	  	  begin
 		  	 	//割り当てられていないか確認
    	  	if ReqDevice[j].nInfo=DEVICE_NONE then
	    	  	Break;
  	    	if ReqDevice[j].bAlloc then
    	  		Continue;
	      	t := GetDeviceStr(ReqDevice[j].nInfo);
          v := GetDeviceSel(t, i);
//          if v='' then
//          	Continue;
					//
          ratio := 0;
		  	  for k := 0 to CONNECT_DEVMAX-1 do
	  	  	begin
	 	  	 		//割り当てられていないか確認
	  	    	if CnDevice[k].nInfo=DEVICE_NONE then
		        	Continue;
  		      if CnDevice[k].bAlloc then
    			  	Continue;
      		  //再生に必要なデバイスが接続されているか確認
        		if v<>Cs[k].DevCB.Text then
            begin
            	if opl2=False then
		        		Continue;
             	if GetDeviceSel(t+'>OPL2', i)<>Cs[k].DevCB.Text then
		        		Continue;
		  	     	ratio := GetDeviceRatio(t+'>OPL2', i);
            end else
            begin
		  	     	ratio := GetDeviceRatio(t, i);
            end;
	  	      //割り当てる
  	  	    ReqDevice[j].bAlloc := True;
    	      u := '';
      	    if f=True then
        	  begin
          		if (ratio>0) and (CnDevice[k].xClock>0) and (ReqDevice[j].xClock>0) then
	          	begin
		          	ReqDevice[j].xClockRatio := (ReqDevice[j].xClock*ratio)/CnDevice[k].xClock;
	    	        u := ' x'+FloatToStr(ReqDevice[j].xClockRatio);
  	          end;
    	      end;
    		    ReqDevice[j].nNo := k;
      		  CnDevice[k].bAlloc := True;
        		//
	          case Cs[k].nIf of
            	IF_INT:
		          	t := 'INT';
              IF_EZUSB:
		    	      t := Ezusb[Cs[k].nEzusb].Device;
              IF_PIC:
              	t := Pic[Cs[k].nPic].Device +'-'+ IntToStr(Pic[Cs[k].nPic].nInstance);
              IF_FTDI:
              	t := Ftdi[Cs[k].nFtdi].Device +'-'+ IntToStr(Ftdi[Cs[k].nFtdi].nInstance);
              else
              	t := '?';
            end;
        	  s := IntToStr(j);
          	Values[s] := Values[s] +'>'+ t+'_'+Cs[k].Chk.Caption+'['+
          		Cs[k].DevCB.Text+','+FloatToStr(CnDevice[k].xClock)+']'+u;
		        //
  		      Inc(Result);
    		    Break;
      		end;
		    end;
  		end;
    	//
	    for i := 0 to REQUEST_DEVMAX-1 do
 		  begin
    		//
    		s := Values[IntToStr(i)];
	      if s<>'' then
		      LogEdit.Lines.Add(s);
    	end;
    finally
	  	Free;
    end;
  end;
end;

function TDeviceForm.GetClockRatio: Extended;
	var
  	i, n: Integer;
    ratio: Extended;
begin
	//
	Result := 1;

	//
	ratio := 0;
	n := 0;
	for i := 0 to REQUEST_DEVMAX-1 do
	begin
		//
		if ReqDevice[i].bAlloc=False then
			Continue;
		//
		if n=0 then
		begin
			ratio := ReqDevice[i].xClockRatio;
			Inc(n);
		end else
		begin
			//
			if CompareValue(ReqDevice[i].xClockRatio, ratio, 1000/1000000)=EqualsValue then
			begin
				ratio := ratio + ReqDevice[i].xClockRatio;
				Inc(n);
			end else
			begin
				//差が大きすぎる
        Exit;
			end;
		end;
	end;
	//
	if (ratio>0) and (n>0) then
		Result := ratio/n;
end;

procedure TDeviceForm.CsDevCBChange(Sender: TObject);
	var
  	i, c, m, n, ifaw, csaw: Integer;
    addr: array[0..1] of Integer;
    s: String;
begin
	//
  c := -1;
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
		if Cs[i].nIf=IF_INT then
    	Continue;
  	if (Cs[i].Chk=Sender) or (Cs[i].DevCB=Sender) then
    begin
    	c := i;
	   	Break;
    end;
  end;
  //
  if c<0 then
  	Exit;

 	//
  ifaw := 3;
  if True then
  begin
		case Cs[c].nIf of
		  IF_EZUSB:
			  ifaw := 3;
		  IF_PIC:
			  ifaw := 10;
		  IF_FTDI:
			  ifaw := 10;
  	end;
  end else
  begin
	 	i := 0;
  	case Cs[c].nIf of
    	IF_EZUSB:
    		i := EzusbTab[Cs[c].nIfNum].DevCb.ItemIndex;
	    IF_PIC:
  	  	i := PicTab[Cs[c].nIfNum].DevCb.ItemIndex;
	    IF_FTDI:
  	  	i := FtdiTab[Cs[c].nIfNum].DevCb.ItemIndex;
	  end;
  	//
  	if i>0 then
	  begin
			case Cs[c].nIf of
			  IF_EZUSB:
    		 	ifaw := Ezusb[i].nAddrWidth;
			  IF_PIC:
  		   	ifaw := Pic[i].nAddrWidth;
			  IF_FTDI:
  		   	ifaw := Ftdi[i].nAddrWidth;
	  	end;
		end;
  end;

  //
  m := c;
	if Cs[c].nIndex=0 then
  	n := c+1
  else
  begin
    Dec(c);
	  n := c;
  end;

	//
	s := 'CS'+IntToStr(Cs[c].nCs)+'#';
  for i := 0 to 1 do
	  addr[i] := GetDeviceAddr(Cs[c+i].DevCB.Text);
  csaw := Max(addr[0], addr[1]);
  if (csaw+1)>ifaw then
  begin
	  Cs[c].Chk.Caption := s + 'A'+IntToStr(csaw)+'=x';
  	Cs[c+1].Chk.Caption := s + 'A'+IntToStr(csaw)+'=x';
    if Cs[m].Chk.Checked=True then
    begin
	    Cs[m].nAddr := 0 shl csaw;
    	Cs[n].Chk.Checked := False;
			Cs[n].Chk.Enabled := False;
	    Cs[n].nAddr := -1;
    end else
    if Cs[n].Chk.Checked=True then
    begin
    	Cs[m].Chk.Checked := False;
			Cs[m].Chk.Enabled := False;
	    Cs[m].nAddr := -1;
	   	Cs[n].nAddr := 0 shl csaw;
    end else
    begin
  	 	Cs[c].Chk.Enabled := True;
			Cs[c+1].Chk.Enabled := True;
	    Cs[c].nAddr := 0;
	    Cs[c+1].nAddr := 0;
    end;
  end else
  begin
	  Cs[c].Chk.Caption := s + 'A'+IntToStr(csaw)+'='+IntToStr(Cs[c].nIndex);
  	Cs[c+1].Chk.Caption := s + 'A'+IntToStr(csaw)+'='+IntToStr(Cs[c+1].nIndex);
   	Cs[c].Chk.Enabled := True;
		Cs[c+1].Chk.Enabled := True;
    Cs[c].nAddr := 0 shl csaw;
    Cs[c+1].nAddr := 1 shl csaw;
  end;
end;

procedure TDeviceForm.CsClkCBChange(Sender: TObject);
	var
  	cb: TComboBox;
    clk: Extended;
begin
	//
  cb := Sender as TComboBox;
  if Assigned(cb)=False then
  	Exit;
  //
  clk := StrToFloatDef(Trim(cb.Text), 0);
  if (clk<CLK_MIN) or (clk>CLK_MAX) then
  	cb.Color := clRed
  else
  	cb.Color := clWindow;
end;

procedure TDeviceForm.CsClkCBExit(Sender: TObject);
	var
  	cb: TComboBox;
    s: String;
    clk: Extended;
    i: Integer;
begin
	//
  cb := Sender as TComboBox;
  if Assigned(cb)=False then
  	Exit;
  //
  s := Trim(cb.Text);
  cb.Text := s;
  clk := StrToFloatDef(s, 0);
  if (clk<CLK_MIN) or (clk>CLK_MAX) then
  	Exit;
	//
  with TStringList.Create do
	begin
  	try
    	//
	  	CommaText := cb.Items.CommaText;
  	  Sorted := True;
    	Duplicates := dupIgnore;
	 		Add(FloatToStr(clk));
  	  Sorted := False;
			CustomSort(ClkCompare);
	    for i := 0 to CONNECT_DEVMAX-1 do
  	  begin
    		if Cs[i].nIf=IF_INT then
      		Continue;
	    	Cs[i].ClkCB.Items.CommaText := CommaText;
  	  end;
    finally
	  	Free;
    end;
  end;
end;

procedure TDeviceForm.CsClkCBKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
  	cb: TComboBox;
begin
	//
  cb := Sender as TComboBox;
  if Assigned(cb)=False then
  	Exit;
	//
  if Key=VK_RETURN then
	  cb.OnExit(Sender);
end;

procedure TDeviceForm.CsDelBtnClick(Sender: TObject);
	var
    cb: TComboBox;
  	i, n: Integer;
    s: String;
begin
	//
  cb := nil;
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
  	//
  	if Cs[i].DelBtn=Sender then
    begin
	    cb := Cs[i].ClkCB;
	    Break;
    end;
  end;
  if Assigned(cb)=False then
  	Exit;

  //
  s := Trim(cb.Text);
 	cb.Text := '';
  if s<>FloatToStr(StrToFloatDef(s, 0)) then
  	Exit;
  //
  for i := 0 to CONNECT_DEVMAX-1 do
  begin
  	//
   	if Cs[i].nIf=IF_INT then
     	Continue;
	 	n := Cs[i].ClkCB.Items.IndexOf(s);
	  if n>=0 then
    begin
     	Cs[i].ClkCB.Items.BeginUpdate;
   		Cs[i].ClkCB.Items.Delete(n);
      Cs[i].ClkCB.Items.EndUpdate;
    end;
  end;
end;

procedure TDeviceForm.EzusbResetBtnClick(Sender: TObject);
	var
    i, n, en: Integer;
    dev: String;
begin
	//
	if MainForm.ThreadCnt>0 then
  	Exit;
  //
  en := -1;
 	for i := 0 to EZUSB_DEVMAX-1 do
  begin
   	//
  	if EzusbTab[i].ResetBtn<>Sender then
    	Continue;
		//
    n := EzusbTab[i].DevCb.ItemIndex;
    if n>0 then
    begin
    	en := n-1;
	    Break;
    end;
	end;
  //
  if en<0 then
  	Exit;

  //
  dev := Ezusb[en].Device;
	if ResetEzusb(en) then
		LogEdit.Lines.Add('Reset '+dev);
end;

procedure TDeviceForm.EzusbDevCBChange(Sender: TObject);
	var
  	i, j, fn, en: Integer;
begin
	//
  fn := -1;
 	for i := 0 to EZUSB_DEVMAX-1 do
  begin
   	//
  	if EzusbTab[i].DevCb<>Sender then
    	Continue;
		//
    fn := i;
   	Break;
  end;
  //
  if fn<0 then
  	Exit;

  //
  en := EzusbTab[fn].DevCb.ItemIndex-1;
 	if en<0 then
  begin
    //選択なし
    EzusbTab[fn].ResetBtn.Enabled := False;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_EZUSB) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nEzusb := -1;
    end;
	end else
  begin
  	//選択あり
  	for i := 0 to EZUSB_DEVMAX-1 do
	  begin
      if i=fn then
      	Continue;
      //
      if EzusbTab[i].DevCb.ItemIndex=EzusbTab[fn].DevCb.ItemIndex then
      begin
      	//
      	EzusbTab[i].DevCb.ItemIndex := 0;
		    EzusbTab[i].ResetBtn.Enabled := False;
			  for j := 0 to CONNECT_DEVMAX-1 do
		  	begin
			   	if (Cs[j].nIf<>IF_EZUSB) or (Cs[j].nIfNum<>i) then
      			Continue;
    	  	Cs[j].nEzusb := -1;
		    end;
      end;
    end;
		//
    EzusbTab[fn].ResetBtn.Enabled := True;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_EZUSB) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nEzusb := en;
    end;
  end;
end;

procedure TDeviceForm.EzusbAutoChkClick(Sender: TObject);
begin
	//
end;

procedure TDeviceForm.PicResetBtnClick(Sender: TObject);
	var
    i, n, en: Integer;
    dev: String;
begin
	//
	if MainForm.ThreadCnt>0 then
  	Exit;
	//
  en := -1;
 	for i := 0 to PIC_DEVMAX-1 do
  begin
   	//
  	if PicTab[i].ResetBtn<>Sender then
    	Continue;
		//
    n := PicTab[i].DevCb.ItemIndex;
    if n>0 then
    begin
    	en := n-1;
	    Break;
    end;
	end;
  //
  if en<0 then
  	Exit;

  //
  dev := Pic[en].Device +'-'+ IntToStr(Pic[en].nInstance);
	if ResetPic(en) then
		LogEdit.Lines.Add('Reset '+dev);
end;

procedure TDeviceForm.PicAutoChkClick(Sender: TObject);
begin
	//
end;

procedure TDeviceForm.PicDevCBChange(Sender: TObject);
	var
  	i, j, fn, en: Integer;
begin
	//
  fn := -1;
 	for i := 0 to PIC_DEVMAX-1 do
  begin
   	//
  	if PicTab[i].DevCb<>Sender then
    	Continue;
		//
    fn := i;
   	Break;
  end;
  //
  if fn<0 then
  	Exit;

  //
  en := PicTab[fn].DevCb.ItemIndex-1;
 	if en<0 then
  begin
    //選択なし
    PicTab[fn].ResetBtn.Enabled := False;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_PIC) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nPic := -1;
    end;
	end else
  begin
  	//選択あり
  	for i := 0 to PIC_DEVMAX-1 do
	  begin
      if i=fn then
      	Continue;
      //
      if PicTab[i].DevCb.ItemIndex=PicTab[fn].DevCb.ItemIndex then
      begin
      	//
      	PicTab[i].DevCb.ItemIndex := 0;
		    PicTab[i].ResetBtn.Enabled := False;
			  for j := 0 to CONNECT_DEVMAX-1 do
		  	begin
			   	if (Cs[j].nIf<>IF_PIC) or (Cs[j].nIfNum<>i) then
      			Continue;
    	  	Cs[j].nPic := -1;
		    end;
      end;
    end;
		//
    PicTab[fn].ResetBtn.Enabled := True;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_PIC) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nPic := en;
    end;
  end;
end;

procedure TDeviceForm.ValueListEditorEditButtonClick(Sender: TObject);
	var
  	col, row: Integer;
    path, relpath: String;
begin
	//
  col := ValueListEditor.Col;
  row := ValueListEditor.Row;
  path := Trim(ValueListEditor.Cells[col, row]);
  if AnsiPos('.\', path)=1 then
  	path := ExpandUNCFileName(MainForm.ExeDllFolder + path);
  if FileExists(path)=False then
  	path := MainForm.ExeDllFolder;
  //
  OpenDlg.InitialDir := ExtractFilePath(path);
  OpenDlg.FileName := ExtractFileName(path);
	if OpenDlg.Execute=False then
  	Exit;
  //
  path := OpenDlg.FileName;
  relpath := ExtractRelativePath(MainForm.ExeDllFolder, path);
  if (AnsiPos('..\', ExtractFilePath(relpath))=0) and (Length(relpath)<Length(path)) then
  	path := '.\' + relpath;
 	ValueListEditor.Cells[col, row] := path;
end;

procedure TDeviceForm.ValueListEditorDblClick(Sender: TObject);
	var
  	col, row, index: Integer;
    val: String;
begin
	//
  col := ValueListEditor.Col;
  row := ValueListEditor.Row;
  if (col<>1) or (row<1) or True then
  	Exit;
  Dec(row);
  //
  case ValueListEditor.ItemProps[row].EditStyle of
  	esEllipsis:
    	ValueListEditor.OnEditButtonClick(Sender);
    esPickList:
    	begin
			  val := ValueListEditor.Cells[1, 1+row];
      	index := ValueListEditor.ItemProps[row].PickList.IndexOf(val);
        if index<0 then
        	index := 0;
        index := (index + 1) mod ValueListEditor.ItemProps[row].PickList.Count;
        ValueListEditor.Cells[1, 1+row] := ValueListEditor.ItemProps[row].PickList.Strings[index];
    	end;
  end;
end;

procedure TDeviceForm.ValueListEditorMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
	var
  	gc: TGridCoord;
begin
	//
  gc := ValueListEditor.MouseCoord(X, Y);
  if (gc.Y<0) or (gc.Y>=ValueListEditor.RowCount) then
  begin
	 	ValueListEditor.ShowHint := False;
    Exit;
  end;
	//
  if False then
  begin
	 	ValueListEditor.ShowHint := True;
 		ValueListEditor.Hint := ValueListEditor.Cells[0, gc.Y];
  end;
end;

procedure TDeviceForm.FtdiResetBtnClick(Sender: TObject);
	var
    i, n, en: Integer;
    dev: String;
begin
	//
	if MainForm.ThreadCnt>0 then
  	Exit;
	//
  en := -1;
 	for i := 0 to FTDI_DEVMAX-1 do
  begin
   	//
  	if FtdiTab[i].ResetBtn<>Sender then
    	Continue;
		//
    n := FtdiTab[i].DevCb.ItemIndex;
    if n>0 then
    begin
    	en := n-1;
	    Break;
    end;
	end;
  //
  if en<0 then
  	Exit;

  //
  dev := Ftdi[en].Device +'-'+ IntToStr(Ftdi[en].nInstance);
	if ResetFtdi(en) then
		LogEdit.Lines.Add('Reset '+dev);
end;

procedure TDeviceForm.FtdiDevCBChange(Sender: TObject);
	var
  	i, j, fn, en: Integer;
begin
	//
  fn := -1;
 	for i := 0 to FTDI_DEVMAX-1 do
  begin
   	//
  	if FtdiTab[i].DevCb<>Sender then
    	Continue;
		//
    fn := i;
   	Break;
  end;
  //
  if fn<0 then
  	Exit;

  //
  en := FtdiTab[fn].DevCb.ItemIndex-1;
 	if en<0 then
  begin
    //選択なし
    FtdiTab[fn].ResetBtn.Enabled := False;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_FTDI) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nFtdi := -1;
    end;
	end else
  begin
  	//選択あり
  	for i := 0 to FTDI_DEVMAX-1 do
	  begin
      if i=fn then
      	Continue;
      //
      if FtdiTab[i].DevCb.ItemIndex=FtdiTab[fn].DevCb.ItemIndex then
      begin
      	//
      	FtdiTab[i].DevCb.ItemIndex := 0;
		    FtdiTab[i].ResetBtn.Enabled := False;
			  for j := 0 to CONNECT_DEVMAX-1 do
		  	begin
			   	if (Cs[j].nIf<>IF_FTDI) or (Cs[j].nIfNum<>i) then
      			Continue;
    	  	Cs[j].nFtdi := -1;
		    end;
      end;
    end;
		//
    FtdiTab[fn].ResetBtn.Enabled := True;
	  for j := 0 to CONNECT_DEVMAX-1 do
  	begin
	   	if (Cs[j].nIf<>IF_FTDI) or (Cs[j].nIfNum<>fn) then
      	Continue;
      Cs[j].nFtdi := en;
    end;
  end;
end;

procedure TDeviceForm.FtdiAutoChkClick(Sender: TObject);
begin
	//
end;

end.

