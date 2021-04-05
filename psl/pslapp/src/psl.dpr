program psl;

uses
  Windows,
  Messages,
  Forms,
  SysUtils,
  StrUtils,
  Unit1 in 'Unit1.pas' {MainForm},
  Unit2 in 'Unit2.pas' {DeviceForm},
  input in 'input.pas',
  output in 'output.pas',
  pkss in 'pkss.pas',
  pnsf in 'pnsf.pas',
  pspc in 'pspc.pas',
  ppsf in 'ppsf.pas',
  cpu_z80 in 'cpu_z80.pas';

{$R *.res}

const
  STR_TITLE = 'psl';
	STR_MUTEX = STR_TITLE+'_mutex';

function SearchWndProc(wnd: HWnd; lp: LPARAM): Boolean stdcall;
	var
  	buf: array[0..255] of Char;
  	p: ^HWnd;
begin
	//
	if GetWindowText(wnd, buf, SizeOf(buf))<>0 then
  begin
	  if LeftStr(String(buf), Length(STR_TITLE))=STR_TITLE then
	  begin
    	//
	  	p := Pointer(lp);
	  	p^ := wnd;
	  	Result := False;
      Exit;
    end;
  end;
	//
  Result := True;
end;

function GetWnd: HWnd;
	var
  	p: HWnd;
begin
	//
  p := INVALID_HANDLE_VALUE;
	EnumWindows(@SearchWndProc, LPARAM(@p));
  Result := p;
end;

var
 	hMutex: THandle;
  Wnd, AppWnd: HWnd;
  i: Integer;
  cd: CopyDataStruct;
  s: String;

begin

	//�N�����Ă��邩�`�F�b�N
  hMutex := CreateMutex(nil, False, STR_MUTEX);
  if WaitForSingleObject(hMutex, 0)=WAIT_TIMEOUT then
  begin
  	//�N����
  	CloseHandle(hMutex);
		Wnd := GetWnd;
    if Wnd<>INVALID_HANDLE_VALUE then
    begin
    	//�p�����[�^�Ɏw�肳�ꂽ�t�@�C�������X�g�ɒǉ�
    	for i := 1 to ParamCount do
      begin
				s := ParamStr(i);
        if AnsiPos('/', s)=1 then
        begin
		  		cd.lpData := Pchar(s);
					cd.cbData := Length(s)+1;
		  		SendMessage(Wnd, WM_COPYDATA, 0, LPARAM(@cd));
        end;
      end;
	    //�N�����̃E�B���h�E���A�N�e�B�u�ɂ���
	    SetForegroundWindow(Wnd);
      AppWnd := GetWindowLong(Wnd, GWL_HWNDPARENT);
      if AppWnd<>0 then
      	Wnd := AppWnd;
			//�ŏ�������Ă����猳�̃T�C�Y�ɖ߂�
      if IsIconic(Wnd) then
        SendMessage(Wnd, WM_SYSCOMMAND, SC_RESTORE, -1);
    end;
    //
    Exit;
  end;

  //�V�K�N��
  Application.Initialize;
  Application.Title := 'psl';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDeviceForm, DeviceForm);
  Application.Run;

end.

