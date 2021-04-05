unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons, ShellApi, Menus, ExtCtrls, Math,
  ActiveX, ShlObj, StrUtils, MMSystem, IniFiles, SyncObjs, AppEvnts, Types,
  ScktComp, pkss;


const
  //
	OPL3_DEVMAX = 2;
	ROMEO_DEVMAX = 2;
  EZUSB_DEVMAX = 2;
	EZUSB_DEVLIM = 8;
  PIC_DEVMAX = 2;
  FTDI_DEVMAX = 2;
	//
	BUFSIZE = 32*(1024*1024);
  OUTPUT_THREADMAX = 1+EZUSB_DEVMAX+PIC_DEVMAX+FTDI_DEVMAX;
  THREAD_BUFSIZE = 32*1024;
  THREAD_READSIZE = 4*1024;


type
	TCnfRead8 = function(pci: ULONG; reg: ULONG): Byte; stdcall;
	TCnfRead16 = function(pci: ULONG; reg: ULONG): Word; stdcall;
	TCnfRead32 = function(pci: ULONG; reg: ULONG): ULONG; stdcall;
  TCnfWrite16 = procedure(pci: ULONG; reg: ULONG; data: Word); stdcall;
	TMemRead8 = function(addr: ULONG): UCHAR; stdcall;
	TMemRead32 = function(addr: ULONG): ULONG; stdcall;
	TMemWrite8 = procedure(addr: ULONG; data: UCHAR); stdcall;
	TMemWrite32 = procedure(addr: ULONG; data: ULONG); stdcall;

const
	MPUSB_FAIL = 0;
	MPUSB_SUCCESS = 1;
	MP_WRITE = 0;
	MP_READ = 1;
	MAX_NUM_MPUSB_DEV = 127;

type
	TMPUSBGetDLLVersion = function: DWORD; cdecl;
	TMPUSBGetDeviceCount = function(pVID_PID: PChar): DWORD; cdecl;
  TMPUSBOpen = function(instance: DWORD; pVID_PID: PChar; pEP: PChar; dwDir: DWORD; dwReserved: DWORD): THandle; cdecl;
  TMPUSBRead = function(handle: THandle; pData: Pointer; dwLen: DWORD; pLength: PDWORD; dwMilliseconds: DWORD): DWORD; cdecl;
	TMPUSBWrite = function(handle: THandle; pData: Pointer; dwLen: DWORD; pLength: PDWORD; dwMilliseconds: DWORD): DWORD; cdecl;
	TMPUSBReadInt = function(handle: THandle; pData: Pointer; dwLen: DWORD; pLength: PDWORD; dwMilliseconds: DWORD): DWORD; cdecl;
 	TMPUSBClose = function(handle: THandle): boolean; cdecl;
	TMPUSBGetDeviceDescriptor = function(handle: THandle; pDevDsc: Pointer; dwLen: DWORD; pLength: PDWORD): DWORD; cdecl;
	TMPUSBGetConfigurationDescriptor = function(handle: THandle; bIndex: UCHAR; pDevDsc: Pointer; dwLen: DWORD; pLength: PDWORD): DWORD; cdecl;
	TMPUSBGetStringDescriptor = function(handle: THandle; bIndex: UCHAR; wLangId: Word; pDevDsc: Pointer; dwLen: DWORD; pLength: PDWORD): DWORD; cdecl;
	TMPUSBSetConfiguration = function(handle: THandle; bConfigSetting: Word): DWORD; cdecl;

type
	FT_HANDLE = Pointer;
	PFT_HANDLE = ^FT_HANDLE;
	FT_STATUS = ULONG;

const
	FT_OK                          = 0;
	FT_INVALID_HANDLE              = 1;
	FT_DEVICE_NOT_FOUND            = 2;
	FT_DEVICE_NOT_OPENED           = 3;
	FT_IO_ERROR                    = 4;
	FT_INSUFFICIENT_RESOURCES      = 5;
	FT_INVALID_PARAMETER           = 6;
	FT_INVALID_BAUD_RATE           = 7;
	FT_DEVICE_NOT_OPENED_FOR_ERASE = 8;
	FT_DEVICE_NOT_OPENED_FOR_WRITE = 9;
	FT_FAILED_TO_WRITE_DEVICE      = 10;
	FT_EEPROM_READ_FAILED          = 11;
	FT_EEPROM_WRITE_FAILED         = 12;
	FT_EEPROM_ERASE_FAILED         = 13;
	FT_EEPROM_NOT_PRESENT          = 14;
	FT_EEPROM_NOT_PROGRAMMED       = 15;
	FT_INVALID_ARGS                = 16;
	FT_NOT_SUPPORTED               = 17;
	FT_OTHER_ERROR                 = 18;
	FT_DEVICE_LIST_NOT_READY       = 19;

type
	PFT_DEVICE_LIST_INFO_NODE = ^TFT_DEVICE_LIST_INFO_NODE;
	TFT_DEVICE_LIST_INFO_NODE = packed record
		Flags: ULONG;
		_Type: ULONG;
		ID: ULONG;
		LocId: DWORD;
		SerialNumber: array[0..16-1] of Char;
		Description: array[0..64-1] of Char;
		ftHandle: FT_HANDLE;
	end;

const
	FT_DEVICE_BM       = 0;
	FT_DEVICE_AM       = 1;
	FT_DEVICE_100AX    = 2;
	FT_DEVICE_UNKNOWN  = 3;
	FT_DEVICE_2232C    = 4;
	FT_DEVICE_232R     = 5;
	FT_DEVICE_2232H    = 6;
	FT_DEVICE_4232H    = 7;
	FT_DEVICE_232H     = 8;
	FT_DEVICE_X_SERIES = 9;

const
	FT_BITMODE_RESET         = $00;
	FT_BITMODE_ASYNC_BITBANG = $01;
	FT_BITMODE_MPSSE         = $02;
	FT_BITMODE_SYNC_BITBANG  = $04;
	FT_BITMODE_MCU_HOST      = $08;
	FT_BITMODE_FAST_SERIAL   = $10;
	FT_BITMODE_CBUS_BITBANG  = $20;
	FT_BITMODE_SYNC_FIFO     = $40;

type
	TFT_CreateDeviceInfoList = function(lpdwNumDevs: LPDWORD): FT_STATUS; stdcall;
	TFT_GetDeviceInfoList = function(pDest: PFT_DEVICE_LIST_INFO_NODE; lpdwNumDevs: LPDWORD): FT_STATUS; stdcall;
	TFT_Open = function(iDevice: Integer; ftHandle: PFT_HANDLE): FT_STATUS; stdcall;
	TFT_Close = function(ftHandle: FT_HANDLE): FT_STATUS; stdcall;
	TFT_Read = function(ftHandle: FT_HANDLE; lpBuffer: Pointer; dwBytesToRead: DWORD; lpdwBytesReturned: LPDWORD): FT_STATUS; stdcall;
	TFT_Write = function(ftHandle: FT_HANDLE; lpBuffer: Pointer; dwBytesToWrite: DWORD; lpdwBytesWritten: LPDWORD): FT_STATUS; stdcall;
	TFT_SetBitMode = function(ftHandle: FT_HANDLE; ucMask: UCHAR; ucEnable: UCHAR): FT_STATUS; stdcall;
	TFT_GetBitMode = function(ftHandle: FT_HANDLE; pucMode: PUCHAR): FT_STATUS; stdcall;
	TFT_GetLibraryVersion = function(lpdwDLLVersion: LPDWORD): FT_STATUS; stdcall;

const
	//
	Z_OK = 0;
	//
	Z_NO_COMPRESSION = 0;
	Z_BEST_SPEED = 1;
	Z_BEST_COMPRESSION = 9;
	Z_DEFAULT_COMPRESSION = -1;
	//
	Z_NULL = Pointer(0);

type
	TzlibVersion = function: PChar;
	TzlibCompileFlags = function: ULONG;
	Tcompress2 = function(dest: PByte; destLen: PULONG; const source: PByte; sourceLen: ULONG; level: Integer): Integer; cdecl;
	Tuncompress = function(dest: PByte; destLen: PULONG; const source: PByte; sourceLen: ULONG): Integer; cdecl;
	TgzFile = Pointer;
	Tgzopen = function(const path: PChar; const mode: PChar): TgzFile; cdecl;
	Tgzread = function(fi: TgzFile; buf: Pointer; len: Cardinal): Integer; cdecl;
	Tgzseek = function(fi: TgzFile; offset: Integer; whence: Integer): Integer; cdecl;
	Tgzclose = function(fi: TgzFile): Integer; cdecl;
	Tcrc32 = function(crc: ULONG; const buf: PByte; len: UINT): ULONG; cdecl;

type
	TOpl3 = record
		//
    dwDevAddr, dwBase: DWORD;
  end;

type
	TRomeo = record
		//
    dwBase, dwDevAddr: DWORD;
    xX2, xX3: Extended;
    bYM2151, bYMF288: Boolean;
    xYM2151Clk, xYMF288Clk: Extended;
  end;


const
	FILE_DEVICE_UNKNOWN = $00000022 shl 16;
	Ezusb_IOCTL_INDEX = $0800;
	METHOD_BUFFERED = 0;
	METHOD_IN_DIRECT = 1;
	METHOD_OUT_DIRECT = 2;

const
	IOCTL_Ezusb_GET_PIPE_INFO         = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+0) shl 2) + METHOD_BUFFERED;
	IOCTL_Ezusb_GET_DEVICE_DESCRIPTOR = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+1) shl 2) + METHOD_BUFFERED;
  IOCTL_Ezusb_VENDOR_REQUEST        = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+5) shl 2) + METHOD_BUFFERED;
	IOCTL_Ezusb_ABORTPIPE             = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+15) shl 2) + METHOD_IN_DIRECT;
	IOCTL_Ezusb_GET_STRING_DESCRIPTOR = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+17) shl 2) + METHOD_BUFFERED;
	IOCTL_EZUSB_BULK_READ             = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+19) shl 2) + METHOD_OUT_DIRECT;
	IOCTL_EZUSB_BULK_WRITE            = FILE_DEVICE_UNKNOWN + ((Ezusb_IOCTL_INDEX+20) shl 2) + METHOD_IN_DIRECT;

type
	TUSBD_PIPE_TYPE = (
    UsbdPipeTypeControl,
    UsbdPipeTypeIsochronous,
    UsbdPipeTypeBulk,
    UsbdPipeTypeInterrupt
	);

type
	TUSBD_PIPE_INFORMATION = record
    wMaximumPacketSize: Word;
    bEndpointAddress: UCHAR;
    bInterval: UCHAR;
    PipeType: TUSBD_PIPE_TYPE;
    PipeHandle: THandle{USBD_PIPE_HANDLE};
    MaximumTransferSize: ULONG;
    PipeFlags: ULONG;
	end;

type
	TUSBD_INTERFACE_INFORMATION = record
    wLength: Word;
    bInterfaceNumber: UCHAR;
    bAlternateSetting: UCHAR;
    bClass: UCHAR;
    bSubClass: UCHAR;
    bProtocol: UCHAR;
    bReserved: UCHAR;
    InterfaceHandle: THandle{USBD_INTERFACE_HANDLE};
    NumberOfPipes: ULONG;
    Pipes: array[0..3] of TUSBD_PIPE_INFORMATION;
	end;

type
	TUSB_DEVICE_DESCRIPTOR = record
    bLength: UCHAR;
    bDescriptorType: UCHAR;
    bcdUSB: Word;
    bDeviceClass: UCHAR;
    bDeviceSubClass: UCHAR;
    bDeviceProtocol: UCHAR;
    bMaxPacketSize0: UCHAR;
    idVendor: Word;
    idProduct: Word;
    bcdDevice: Word;
    iManufacturer: UCHAR;
    iProduct: UCHAR;
    iSerialNumber: UCHAR;
    bNumConfigurations: UCHAR;
  end;

type
	TVENDOR_REQUEST_IN = record
    bRequest: Byte;
    wValue: Word;
    wIndex: Word;
    wLength: Word;
    direction: Byte;
    bData: Byte;
	end;

type
 	TBULK_TRANSFER_CONTROL = record
		pipeNum: ULONG;
	end;

type
	TGET_STRING_DESCRIPTOR_IN = record
  	Index: UCHAR;
		LanguageId: Word;
	end;


const
  EZUSB_PIC_FTDI_BUFSIZE = 384;	//※278（3*2+(1+OPNA_ADPCM_LEN)*16）以上にすること

const
	//pipe0 制御出力コマンド
  PIPE_CTLCMD          = 0;
  CTL_RESET 					 = $00;	//1
  CTL_START				 		 = $10;	//1
  CTL_STOP				 		 = $12;	//1
	//pipe1 データ出力コマンド
  PIPE_DATACMD         = 1;
	CMD_WRITE_REGA	     = $00;	//3 $00-$07, $10-$3f
//CMD_WRITE_REGA2	     = $40;	//3 $40-$47, $50-$7f
	CMD_WRITE_REGB	     = $80;	//2 $80-$8f
//CMD_WRITE_REGB2	     = $90;	//2 $90-$9f
	CMD_READREG_CS01		 = $b0;	//2 $b0-$b7
//CMD_READREG_CS23		 = $d0;	//2 $d0-$d7
	CMD_OPNA_ADPCM	     = $b8;	//2 $b8-$bb
//CMD_OPNA_ADPCM2	     = $bc;	//2 $bc-$bf
	CMD_OPNA_ADPCM_2	   = $d8;	//1+OPNA_ADPCM_LEN $d8-$db
//CMD_OPNA_ADPCM2_2	   = $dc;	//1+OPNA_ADPCM_LEN $dc-$df
	OPNA_ADPCM_LEN       = 16;
	CMD_MSXAUDIO_ADPCM   = $e0;	//2 $e0-$e7
//CMD_MSXAUDIO_ADPCM2  = $e8;	//2 $e8-$ef
	CMD_OPN2_PCM		     = $f0;	//2 $f0-$f3
//CMD_OPN2_PCM2		     = $f4;	//2 $f4-$f7
	CMD_SYNC_1					 = $f8;	//1
	CMD_SYNC_8BIT			   = $f9;	//2
	CMD_HIGHADDR_CS01		 = $fa;	//2
//CMD_HIGHADDR_CS23		 = $fb;	//2
	CMD_WAIT_1MS			   = $fc;	//3
  //
  CMD_PIT  			 			 = CMD_WRITE_REGB;
	CMD_PSG  			 			 = CMD_WRITE_REGA;
  CMD_DCSG 			 			 = CMD_WRITE_REGB;
  CMD_SAA1099		 			 = CMD_WRITE_REGB;
  CMD_OPM  			 			 = CMD_WRITE_REGA+$28;
  CMD_OPN  			 			 = CMD_WRITE_REGA+$20;
  CMD_OPNB_CTL 	 			 = CMD_WRITE_REGA+$20;
  CMD_OPLL 			 			 = CMD_WRITE_REGA+$10;
  CMD_OPL  			 			 = CMD_WRITE_REGA+$10;
  CMD_OPL3 			 			 = CMD_WRITE_REGA+$10;
  CMD_OPL4_WAVETABLE	 = CMD_WRITE_REGA+$38;
  CMD_OPL4_CTL			 	 = CMD_WRITE_REGA+$20;
  CMD_OPL4ML_MPUDATA 	 = CMD_WRITE_REGB;
  CMD_OPL4ML_MPUACK_R	 = CMD_READREG_CS01;
	CMD_OPX					 		 = CMD_WRITE_REGA+$18;
	CMD_OPX_CTL			 		 = CMD_WRITE_REGA+$20;
  CMD_SCC 			 			 = CMD_WRITE_REGA;
  CMD_SCC_HIGHADDR		 = CMD_WRITE_REGB;
	CMD_GA20						 = CMD_WRITE_REGB;
	CMD_GA20_CTL				 = CMD_WRITE_REGA+$20;
	CMD_PCMD8						 = CMD_WRITE_REGA+$10;
	CMD_PCMD8_CTL				 = CMD_WRITE_REGA+$20;
	COM_RP2A03_CTL 			 = CMD_WRITE_REGA;
  CMD_SSMP_SDSP	 			 = CMD_WRITE_REGB;
  CMD_SSMP_SDSP_R			 = CMD_READREG_CS01;
	CMD_SSMP_SDSP_CTL    = CMD_WRITE_REGA+$20;
  CMD_SCSP_SCPU_CTL		 = CMD_WRITE_REGA+$20;
	CMD_SPU_CTL					 = CMD_WRITE_REGA+$20;
	CMD_SPU_HIGHDATA		 = CMD_WRITE_REGA;
  //pipe3 制御データ入力
  PIPE_CTL_DATA        = 3;

type
	TEzusb = record
  	//
		hndHandle: THandle;
		Device, Rev: String;
  	bFx2: Boolean;
    nSyncFreq: Integer;
    nAddrWidth: Integer;
  end;

type
	TPic = record
  	//
    nInstance: Integer;
		Device, Rev: String;
		hndWrite, hndRead: THandle;
    nSyncFreq: Integer;
    nAddrWidth: Integer;
  end;

type
	TFtdi = record
  	//
    nInstance: Integer;
		Device, Rev: String;
		hndDevice: FT_HANDLE;
    nSyncFreq: Integer;
    nAddrWidth: Integer;
  end;


type
	TDevicePit = record
    wEnable: Word;
    byOutput, byVolume: Byte;
  end;
	TDeviceDcsgGg = record
		Attenuation: array[0..3] of Byte;
    byMask: Byte;
  end;
  TDeviceOpm = record
    wTl: array[0..7] of array[0..3] of Word;
  end;
	TDeviceOpna = record
    wTl: array[0..5] of array[0..3] of Word;
    dwOldAddr: DWORD;
    nAdpcmLen: Integer;
    AdpcmBuf: array[0..OPNA_ADPCM_LEN-1] of Byte;
    Reg: array[$0000..$01ff] of Byte;
  end;
	TDeviceOpn2 = record
    byDacSelect, byDacPan: Byte;
  end;
  TDeviceOpll = record
		nMelodyCh: Integer;
    Reg: array[$00..$ff] of Byte;
  end;
  TDeviceMsxaudio = record
    Reg: array[$00..$ff] of Byte;
  end;
	TDeviceScc = record
    wHighAddr: Word;
  end;

type
	TDeviceStatus = record
    //
    Pit: TDevicePit;
    DcsgGg: TDeviceDcsgGg;
    Opm: TDeviceOpm;
    Opna: TDeviceOpna;
    Opn2: TDeviceOpn2;
    Opll: TDeviceOpll;
  	Msxaudio: TDeviceMsxaudio;
    Scc: TDeviceScc;
    //
    Reg: array[$0000..$ffff] of Word;
  end;


const
	//
	ST_TERMINATE = 1;
	ST_PLAY      = 2;
	ST_PREV      = 3;
	ST_NEXT      = 4;
  //
  ST_THREAD_ERROR     = 11;
  ST_THREAD_TERMINATE = 12;
  ST_THREAD_END       = 13;

const
  WM_STATE                 = WM_APP+10;
  WM_THREAD_UPDATE_TIME    = WM_APP+20;
  WM_THREAD_UPDATE_ENDTIME = WM_APP+21;
  WM_THREAD_TERMINATE      = WM_APP+22;

type
 	TOutputData = record
  	//
    byNo: Byte;
    dwAddr: DWORD;
    wData: Word;
  end;

type
 	TThreadCri = record
  	//定数
    bEnable: Boolean;
    bTimeEnb: Boolean;
    nBufSize: Integer;
    //設定
    nIntPitChannel: Integer;
   	nGa20Attenuation: Integer;
    bOpl2Opll: Boolean;
    Opl2OpllInst: array[0..2] of String;
    bOpl3ChannelChg, bOpl3OpllMoRo, bOpl3nlOplChannelLr: Boolean;
    bSolo1ChannelLr, bSolo1VolumeChg: Boolean;
  	nSolo1Volume: Integer;
    nOpl4FmMix, nOpl4PcmMix: Integer;
    bOpl4PcmChannelChg: Boolean;
    nOpl4RamDo: Integer;
    bOpl4RamSpdif: Boolean;
		nOpmFmAttenuation: Integer;
		nOpnFmAttenuation: Integer;
    nOpnaBalance: Integer;
    bOpnaOpn2Pcm: Boolean;
    nOpnaOpn2PcmType: Integer;
    nOpnbBalance: Integer;
    bOpnbOpnaRhythm: Boolean;
    OpnbOpnaRhythm: array[0..5] of String;
		nOpxRamDoExt: Integer;
		bOpxRam18bit, bOpxRamSpdif: Boolean;
		nPcmd8DoEo: Integer;
		bPcmd8Spdif: Boolean;
    b052539CompatibleMode: Boolean;
		bSpuExt, bSpuSpdif: Boolean;
		//入力
    nWritePtr: Integer;
		//入出力
		Cri: TCriticalSection;
    nLength: Integer;
    Buf: array[0..THREAD_BUFSIZE-1] of TOutputData;
	end;

//
const
	FMT_S98    = 0;
  FMT_SPUOLD = 1;
  FMT_VGM    = 2;


type
	PFileBuf = ^TFileBuf;
	TFileBuf = array[0..BUFSIZE-1] of Byte;
	TBuf = array[0..BUFSIZE-1] of Byte;

const
  CONNECT_DEVMAX = 8+EZUSB_DEVMAX*8+PIC_DEVMAX*8+FTDI_DEVMAX*8;
  REQUEST_DEVMAX = 64;	//要求される最大デバイス数、今はS98_DEVMAXと同じ

const
  IF_NONE  = -1;
  IF_INT   = 0;
  IF_EZUSB = 1;
  IF_PIC   = 2;
  IF_FTDI  = 3;

type
	TConnectDevice = record
    //接続先
    nIfSelect: Integer;
    dwIfIntBase: DWORD;
    nIfEzusbNo, nIfPicNo, nIfFtdiNo: Integer;
    nIfEzusbPicFtdiDevCs, nIfEzusbPicFtdiDevAddr: Integer;
    //スレッド番号
    nThread: Integer;
    //デバイス
    nInfo: Integer;
    //クロック
    xClock: Extended;
    //割り当て済みか
    bAlloc: Boolean;
  end;

	PRequestDevice = ^TRequestDevice;
	TRequestDevice = record
    //デバイス
    nInfo: Integer;
    //クロック
    xClock: Extended;
    xClockRatio: Extended;
    //出力先
    nNo: Integer;
    //割り当て済みか
    bAlloc: Boolean;
    //コマンド番号
    Command: String;
  end;

const
	DEVICE_NONE     		= 0;
  DEVICE_USART     		= 1;	//USART, SCU
  DEVICE_PIT      		= 2;	//PIT, PTC
  DEVICE_PSG      		= 3;	//PSG
  DEVICE_EPSG     		= 4;	//EPSG
	DEVICE_SSG      		= 5;	//SSG, SSGC
	DEVICE_SSGL      		= 6;	//SSGL, SSGLP
	DEVICE_DCSG			 		= 7;	//DCSG
	DEVICE_DCSG_GG			= 8;	//DCSG_GG
	DEVICE_DCSG_NGP			= 9;	//DCSG_NGP
  DEVICE_SAA1099  		= 10;	//SAA1099
	DEVICE_OPM      		= 11;	//OPM
	DEVICE_OPP      		= 12;	//OPP
	DEVICE_OPZ      		= 13;	//OPZ
	DEVICE_OPN      		= 14;	//OPN, OPNC
	DEVICE_OPNA     		= 15;	//OPNA
	DEVICE_OPNA_RAM 		= 16;	//OPNA+RAM
	DEVICE_OPNB_RAM 		= 17;	//OPNB+RAM, YMF286+RAM
	DEVICE_YM2610B_RAM	= 18;	//YM2610B+RAM
	DEVICE_OPN2     		= 19;	//OPN2, OPN2C, YMF276
	DEVICE_OPN3L    		= 20;	//OPN3-L
	DEVICE_OPLL     		= 21;	//OPLL
	DEVICE_OPLLP    		= 22;	//OPLLP
	DEVICE_VRC7   			= 23;	//VRC7
	DEVICE_OPL      		= 24;	//OPL
	DEVICE_MSXAUDIO_RAM	= 25;	//MSX-AUDIO+RAM
	DEVICE_OPL2     		= 26;	//OPL2
	DEVICE_OPL3     		= 27;	//OPL3
	DEVICE_OPL3L    		= 28;	//OPL3-L
	DEVICE_DS1      		= 29;	//DS-1, DS-1L, DS-1S, DS-1E
	DEVICE_SOLO1     		= 30;	//SOLO-1, SOLO-1E
	DEVICE_OPL3NL_OPN		= 31;	//OPL3-NL_OPN
	DEVICE_OPL3NL_OPL		= 32;	//OPL3-NL_OPL
  DEVICE_OPL4_RAM			= 33;	//OPL4+RAM, YMF268+RAM
  DEVICE_OPL4ML_OPL		= 34;	//OPL4-ML_OPL, OPL4-ML2_OPL
  DEVICE_OPL4ML_MPU		= 35;	//OPL4-ML_MPU, OPL4-ML2_MPU
	DEVICE_OPX_RAM			= 36;	//OPX+RAM
  DEVICE_SCC      		= 37;	//SCC
  DEVICE_052539    		= 38;	//052539
	DEVICE_GA20  				= 39;	//GA20
  DEVICE_PCMD8				= 40;	//PCMD8
	DEVICE_MA2  				= 41;	//MA-2
	DEVICE_MA3  				= 42;	//MA-3
	DEVICE_MA5  				= 43;	//MA-5
	DEVICE_MA7  				= 44;	//MA-7
  //
	DEVICE_RP2A03				= 50; //RP2A03
	DEVICE_RP2A03_EXT		= 51; //RP2A03+EXT（VRC6,VRC7,RP2C33,MMC5,163,5B）
	DEVICE_RP2A07	  		= 52;	//RP2A07
	DEVICE_SSMP_SDSP		= 53;	//S-SMP+S-DSP
	DEVICE_CPU_AGB 			= 54;	//CPU_AGB
	DEVICE_SCSP_SCPU		= 55;	//SCSP+SCPU
	DEVICE_SPU  				= 56;	//SPU
	DEVICE_AICA  				= 57;	//AICA
	DEVICE_SPU2  				= 58;	//SPU2
  //
  DEVICE_SEGAPCM			= Integer($80000000);	//Sega_PCM
  DEVICE_RF5C68				= Integer($80000001);	//RF5C68
	DEVICE_RF5C164			= Integer($80000002);	//RF5C164
  DEVICE_PWM					= Integer($80000003);	//PWM
	DEVICE_HUC6280			= Integer($80000004);	//HuC6280
	DEVICE_HUC6230			= Integer($80000005);	//HuC6230

const
  Opl2Channel2Addr: array[0..8] of Integer = (
		$00, $01, $02, $08, $09, $0a, $10, $11, $12
  );
  OpxGroup2Addr: array[0..11] of Integer = (
  	$00, $01, $02, $04, $05, $06, $08, $09, $0a, $0c, $0d, $0e
  );
  OpllMoVol2Opl2Tl: array[0..15] of Byte = (
	  $00, $04, $08, $0c, $10, $14, $18, $1c,
    $20, $24, $29, $2d, $33, $38, $3f, $3f
  );
  OpllRoVol2Opl2Tl: array[0..15] of Byte = (
	  $00, $04, $08, $0c, $10, $14, $18, $1c,
    $20, $24, $29, $2d, $33, $38, $3f, $3f
  );


const
	ST_OK = 0;
	ST_ERR = 1;
	ST_MARK = 2;


const
	S98_DEVMAX = 64;

type
	PS98Header = ^TS98Header;
	TS98Header = packed record
		//$00
    //  'S980': V0
    //  'S981': V1
    //  'S982': V2
    //  'S983': V3
		Magic: array[0..3] of Byte;
		//$04 SYNCの分子
    //  0=10
    dwTimerInfo1: DWORD;
		//$08 SYNCの分母
    //  0=1000
    dwTimerInfo2: DWORD;
		//$0c
    //  V0～V2: 圧縮サイズ、0=圧縮なし
    //  V3: 0
    dwCompress: DWORD;
		//$10 タイトルオフセット
    //  0=タイトルなし
    dwTitleOffset: DWORD;
		//$14 データオフセット
    dwDataOffset: DWORD;
		//$18 ループオフセット
    //  0=ループなし
    dwLoopOffset: DWORD;
    //$1c
    //  V0～V2: 圧縮データオフセット
    //  V3: デバイス数
    dwCompressOffset: DWORD;
  end;

	TS98DeviceInfo = packed record
    //$00 種類
    dwInfo: DWORD;
    //$04 クロック
    dwClock: DWORD;
    //$08
    //  V0～V2: 予約
    //  V3: パン
    dwPan: DWORD;
    //$0c 予約
    dwReserved: DWORD;
  end;

const
	DEVS98_NONE  = $00;
	DEVS98_SSG   = $01;
	DEVS98_OPN   = $02;
	DEVS98_OPN2  = $03;
	DEVS98_OPNA  = $04;
	DEVS98_OPM   = $05;
	DEVS98_OPLL  = $06;
	DEVS98_OPL   = $07;
	DEVS98_OPL2  = $08;
	DEVS98_OPL3  = $09;
  DEVS98_PSG   = $0f;
	DEVS98_DCSG  = $10;
  //※テスト用
 	DEVS98_USART    = $38323531;	//'8251'
  DEVS98_PIT   		= $00504954;	//'\x00PIT'
  DEVS98_EPSG     = $45505347;	//'EPSG'
  DEVS98_SAA1099  = $00534141;  //'\x00SAA'
	DEVS98_OPP			= $004f5050;	//'\x00OPP'
	DEVS98_OPZ			= $004f505a;	//'\x00OPZ'
  DEVS98_OPNB     = $4f504e42;	//'OPNB'
  DEVS98_YM2610B  = $00261042;	//'\x00\x26\x10B'
	DEVS98_OPLLP    = $594df281;	//'YM\xf2\x81'
	DEVS98_VRC7   	= $56524337;	//'VRC7'
	DEVS98_MSXAUDIO	= $4d535841;  //'MSXA'
	DEVS98_OPL4			= $4f504c34;  //'OPL4'
  DEVS98_MPU   		= $004d5055;  //'\x00MPU'
  DEVS98_SCC   		= $00534343;  //'\x00SCC'
  DEVS98_052539		= $53434350;  //'SCCP'
	DEVS98_GA20			= $47413230;	//'GA20'


type
	PNsfHeader = ^TNsfHeader;
	TNsfHeader = packed record
		//$00 'NESM'+Chr($1a)
		Magic: array[0..4] of Byte;
		//$05 バージョン番号
    byVersion: Byte;
    //$06 曲数
    byTotalSongs: Byte;
    //$07 開始曲番号
    byStartSong: Byte;
    //$08 読み込み開始アドレス
    wLoadAddress: Word;
    //$0a 初期化アドレス
    wInitAddress: Word;
    //$0c 再生アドレス
    wPlayAddress: Word;
    //$0e 曲名
    Name: array[0..31] of Char;
    //$2e 作曲者
    Artist: array[0..31] of Char;
    //$4e 著作権所有者
    Copyright: array[0..31] of Char;
    //$6e 速度（1us単位）、NTSC
    wSpeedNtsc: Word;
    //$70 バンクスイッチ
    BankSw: array[0..7] of Byte;
    //$78 速度（1us単位）、PAL
    wSpeedPal: Word;
    //$7a PAL/NTSCビット
    byPalNtsc: Byte;
    //$7b 拡張音源
    bySoundChip: Byte;
		//$7c 予約
    Reserved: array[0..3] of Byte;
  end;

const
	DEVNSF_BIT_VRC6 = 0;
	DEVNSF_BIT_VRC7 = 1;
	DEVNSF_BIT_FDS  = 2;
	DEVNSF_BIT_MMC5 = 3;
	DEVNSF_BIT_N106 = 4;
	DEVNSF_BIT_FME7 = 5;
	DEVNSF_VRC6     = 1 shl DEVNSF_BIT_VRC6;
	DEVNSF_VRC7     = 1 shl DEVNSF_BIT_VRC7;
	DEVNSF_FDS      = 1 shl DEVNSF_BIT_FDS;
	DEVNSF_MMC5     = 1 shl DEVNSF_BIT_MMC5;
	DEVNSF_N106     = 1 shl DEVNSF_BIT_N106;
	DEVNSF_FME7     = 1 shl DEVNSF_BIT_FME7;
  DEVNSF_EXTMASK  = DEVNSF_VRC6 or DEVNSF_VRC7 or DEVNSF_FDS or
  	DEVNSF_MMC5 or DEVNSF_N106 or DEVNSF_FME7;

const
	NSF_BANKSIZE = $1000;
  NSF_ROMADDR  = $000000;
	NSF_RAMADDR  = $100000;		//$0000～$07ff
	NSF_RAMSIZE  = NSF_BANKSIZE div 2;
	NSF_CTLADDR  = $100800;		//$3800～$3fff, $f800～$ffff
	NSF_CTLSIZE  = NSF_BANKSIZE div 2;


type
	PSpcFile = ^TSpcFile;
	TSpcFile = packed record
		//$00000 'SNES-SPC700 Sound File Data v0.30'+Chr($1a)+Chr($1a)
		Magic: array[0..34] of Byte;
		//$00023 ID666
    byId666Info: Byte;
		//$00024 Version minor
    byVersion: Byte;
    //$00025 SPC700 Registers、PC
    wSpc700PC: Word;
    //$00027 SPC700 Registers、A
    bySpc700A: Byte;
    //$00028 SPC700 Registers、X
    bySpc700X: Byte;
    //$00029 SPC700 Registers、Y
    bySpc700Y: Byte;
    //$0002a SPC700 Registers、PSW
    bySpc700PSW: Byte;
    //$0002b SPC700 Registers、SP (lower byte)
    bySpc700SP: Byte;
    //$0002c SPC700 Registers、reserved
    wSpc700Reserved: Word;
  	//$0002e ID666 Tag
    Id666: array[0..209] of Byte;
    //$00100 64KB RAM
    Ram: array[0..65535] of Byte;
    //$10100 DSP Registers
    Dsp: array[0..127] of Byte;
    //$10180 unused
    Unused: array[0..63] of Byte;
    //$101c0 Extra RAM
    ExRam: array[0..63] of Byte;
  end;

type
	PId666Text = ^TId666Text;
	TId666Text = packed record
		//$00000 Song title
		SongTitle: array[0..31] of Char;
		//$00020 Game title
		GameTitle: array[0..31] of Char;
		//$00040 Name of dumper
		Dumper: array[0..15] of Char;
		//$00050 Comments
		Comments: array[0..31] of Char;
		//$00070 Date SPC was dumped (MM/DD/YYYY)
		Date: array[0..10] of Char;
		//$0007b Number of seconds to play song before fading out
		Fadeout: array[0..2] of Char;
		//$0007e Length of fade in milliseconds
		Fadein: array[0..4] of Char;
		//$00083 Artist of song
		Artist: array[0..31] of Char;
		//$000a3 Default channel disables (0 = enable, 1 = disable)
		byChannel: Byte;
		//$000a4 Emulator used to dump SPC:
		cEmulator: Char;
		//$000a5 reserved (set to all 0's)
		Reserved: array[0..44] of Byte;
  end;

type
	PId666Binary = ^TId666Binary;
	TId666Binary = packed record
		//$00000 Song title
		SongTitle: array[0..31] of Char;
		//$00020 Game title
		GameTitle: array[0..31] of Char;
		//$00040 Name of dumper
		Dumper: array[0..15] of Char;
		//$00050 Comments
		Comments: array[0..31] of Char;
		//$00070 Date SPC was dumped (YYYYMMDD)
		dwDate: DWORD;
		//$00074 unused
		Unused: array[0..6] of Byte;
		//$0007b Number of seconds to play song before fading out
		Fadeout: array[0..2] of Byte;
		//$0007e Length of fade in milliseconds
		dwFadein: DWORD;
		//$00082 Artist of song
		Artist: array[0..31] of Char;
		//$000a2 Default channel disables (0 = enable, 1 = disable)
		byChannel: Byte;
		//$000a3 Emulator used to dump SPC:
		byEmulator: Byte;
		//$000a4 reserved (set to all 0's)
		Reserved: array[0..45] of Byte;
  end;


type
	PSpuHeader = ^TSpuHeader;
	TSpuHeader = packed record
  	//$00000 512KB RAM
    Ram: array[0..512*1024-1] of Byte;
    //$80000 Registers
    Reg: array[0..256-1] of Word;
    //$80200
		Info: array[0..1] of DWORD;
	end;

type
	PSpuDataOld = ^TSpuDataOld;
	TSpuDataOld = packed record
  	//$00
	  dwSync: DWORD;
    //$04
	  dwAddr: DWORD;
    //$08
	  dwData: DWORD;
  end;


type
	PVgmHeader = ^TVgmHeader;
	TVgmHeader = packed record
		//$00 file identification
		Magic: array[0..3] of Byte;
		//$04 Eof offset
    dwEofOffset: DWORD;
		//$08 Version number
    dwVersion: DWORD;
		//$0c SN76489 clock
    dwSN76489Clock: DWORD;
		//$10 YM2413 clock
    dwYM2413Clock: DWORD;
		//$14 GD3 offset
    dwGD3Offset: DWORD;
		//$18 Total # samples
    dwTotalSamples: DWORD;
		//$1c Loop offset
    dwLoopOffset: DWORD;
		//$20 Loop # samples
    dwLoopSamples: DWORD;
    //VGM 1.01
		//  $24 Rate
    dwRate: DWORD;
    //VGM 1.10
		//  $28 SN76489 feedback
    wSN76489Feedback: Word;
		//  $2a SN76489 shift register width
    bySN76489ShiftRegWidth: Byte;
    //VGM 1.51
		//  $2b SN76489 Flags
    bySN76489Flags: Byte;
    //VGM 1.10
		//  $2c YM2612 clock
    dwYM2612Clock: DWORD;
		//  $30 YM2151 clock
    dwYM2151Clock: DWORD;
    //VGM 1.50
		//  $34 VGM data offset
    dwVgmDataOffset: DWORD;
    //VGM 1.51
		//  $38 Sega PCM clock
    dwSegaPcmClock: DWORD;
		//  $3c Sega PCM interface register
    dwSegaPcmInterfaceReg: DWORD;
		//  $40 RF5C68 clock
    dwRF5C68Clock: DWORD;
		//  $44 YM2203 clock
    dwYM2203Clock: DWORD;
		//  $48 YM2608 clock
    dwYM2608Clock: DWORD;
		//  $4c YM2610/YM2610B clock
    dwYM2610Clock: DWORD;
		//  $50 YM3812 clock
    dwYM3812Clock: DWORD;
		//  $54 YM3526 clock
    dwYM3526Clock: DWORD;
		//  $58 Y8950 clock
    dwY8950Clock: DWORD;
		//  $5c YMF262 clock
    dwYMF262Clock: DWORD;
		//  $60 YMF278B clock
    dwYMF278Clock: DWORD;
		//  $64 YMF271 clock
    dwYMF271Clock: DWORD;
		//  $68 YMZ280B clock
    dwYMZ280Clock: DWORD;
		//  $6c RF5C164 clock
    dwRF5C164Clock: DWORD;
		//  $70 PWM clock
    dwPwmClock: DWORD;
		//  $74 AY8910 clock
    dwAY8910Clock: DWORD;
		//  $78 AY8910 Chip Type
    byAY8910ChipType: Byte;
		//  $79 AY8910 Flags
    byAY8910Flags: Byte;
		//  $7a YM2203/AY8910 Flags
    byYM2203_AY8910Flags: Byte;
    //  $7b YM2608/AY8910 Flags
    byYM2608_AY8910Flags: Byte;
    //VGM 1.60
    //  $7c Volume Modifier
    byVolumeModifier: Byte;
		//  $7d reserved
    byReserved: Byte;
		//  $7e Loop Base
    byLoopBase: Byte;
    //VGM 1.51
		//  $7f Loop Modifier
    byLoopModifier: Byte;
	end;

type
	PGd3Header = ^TGd3Header;
	TGd3Header = packed record
		//$00 file identification
		dwMagic: DWORD;
		//$04 Version number
    dwVersion: DWORD;
		//$08 Length
    dwLength: DWORD;
  end;

type
	PDataBlock = ^TDataBlock;
  TDataBlock = record
    wType: Word;
    dwBufPtr, dwSize: DWORD;
    nState: Integer;
    dwReadPtr, dwOffset: DWORD;
    dwRomSize, dwRomStartAddr: DWORD;
    wRamStartAddr: Word;
  end;


type
	PPsfHeader = ^TPsfHeader;
	TPsfHeader = packed record
		//$00 ASCII signature: "PSF"
		Magic: array[0..2] of Byte;
		//$03 Version byte
    byVersion: Byte;
    //$04 Size of reserved area (R)
    dwSizeReserved: DWORD;
    //$08 Compressed program length (N)
    dwProgramLength: DWORD;
    //$0c Compressed program CRC-32
    dwProgramCrc32: DWORD;
  end;

type
	PPsxExeHeader = ^TPsxExeHeader;
	TPsxExeHeader = packed record
		//$00 ASCII "PS-X EXE"
		Magic: array[0..7] of Byte;
		Reserved1: array[0..8-1] of Byte;
    //$10 Initial PC
    dwInitialPC: DWORD;
    //
		Reserved2: array[0..4-1] of Byte;
    //$18 Text section start address
    dwStartAddress: DWORD;
    //$1c Text section size
    dwSectionSize: DWORD;
    //
		Reserved3: array[0..16-1] of Byte;
    //$30 Initial SP ($29)
    dwInitialSP: DWORD;
    //
		Reserved4: array[0..24-1] of Byte;
    //$4c ASCII marker
		Marker: array[0..1972-1] of Byte;
  end;

type
	P68kExeHeader = ^T68kExeHeader;
	T68kExeHeader = packed record
    //$00 Load address
    dwLoadAddress: DWORD;
	end;

type
	PArm7ExeHeader = ^TArm7ExeHeader;
	TArm7ExeHeader = packed record
    //$00 Load address
    dwLoadAddress: DWORD;
	end;

type
	PAgbExeHeader = ^TAgbExeHeader;
	TAgbExeHeader = packed record
  	//$00 GSF_Entry_Point
    dwEntryPoint: DWORD;
		//$04 GSF_Offset
    dwOffset: DWORD;
		//$08 Size of Rom
    dwSize: DWORD;
	end;


type
  TMainForm = class(TForm)
    TimeLbl: TLabel;
    StopBtn: TSpeedButton;
    PlayBtn: TSpeedButton;
    PrevBtn: TSpeedButton;
    NextBtn: TSpeedButton;
    Memo: TMemo;
    DevBtn: TSpeedButton;
    PopupMenu: TPopupMenu;
    PMDelete: TMenuItem;
    PMPlay: TMenuItem;
    N1: TMenuItem;
    PMExist: TMenuItem;
    PMClose: TMenuItem;
    N2: TMenuItem;
    PMAllDelete: TMenuItem;
    ListView: TListView;
    PMOpen: TMenuItem;
    PMFolder: TMenuItem;
    N3: TMenuItem;
    OpenDlg: TOpenDialog;
    PMDuplicate1: TMenuItem;
    PMStop: TMenuItem;
    PMPrev: TMenuItem;
    PMNext: TMenuItem;
    PMSelect: TMenuItem;
    EndTimeLbl: TLabel;
    PMExplorer: TMenuItem;
    PMDev: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure PlayBtnClick(Sender: TObject);
    procedure PrevBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DevBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PMDeleteClick(Sender: TObject);
    procedure PMExistClick(Sender: TObject);
    procedure PMAllDeleteClick(Sender: TObject);
    procedure PMOpenClick(Sender: TObject);
    procedure PMFolderClick(Sender: TObject);
    procedure ListViewDblClick(Sender: TObject);
    procedure ListViewColumnClick(Sender: TObject;
      Column: TListColumn);
    procedure PMDuplicate1Click(Sender: TObject);
    procedure ListViewAdvancedCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);
		procedure WMSizing(var Msg: TMessage); message WM_SIZING;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
		procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
		procedure WMQueryEndSession(var Msg: TWMQueryEndSession); message WM_QUERYENDSESSION;
    procedure WMState(var Msg: TMessage); message WM_STATE;
    procedure WMThreadUpdateTime(var Msg: TMessage); message WM_THREAD_UPDATE_TIME;
    procedure WMThreadUpdateEndTime(var Msg: TMessage); message WM_THREAD_UPDATE_ENDTIME;
    procedure WMThreadTerminate(var Msg: TMessage); message WM_THREAD_TERMINATE;
    procedure PMSelectClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure PMExplorerClick(Sender: TObject);
  private
    { Private 宣言 }
    DefaultFolder: String;
    FormCaption: String;
		nFormHeightMin: Integer;
		nFormWidthMin: Integer;
    FileFilter: String;
  	//
    nListIndex: Integer;
		//
    FileBuf: TBuf;
    nFileSize: Integer;
    //
    function GetPathNumber(i: Integer): String;
    function GetPath(i: Integer): String;
		function GetNumber(i: Integer): Integer;
		function GetType(i: Integer): String;
    procedure InitSetting(i: Integer);
		function PlayS98(path: String): Integer;
		function PlayKss(path: String; number: Integer): Integer;
    function PlayNsf(path: String; number: Integer): Integer;
    function PlaySpc(path: String): Integer;
    function PlaySpu(path: String): Integer;
    function PlayVgm(path: String; extvgm: Boolean): Integer;
    function PsfStrToMSecs(const S: string): Int64;
    function PlayPsf(path: String): Integer;
    function ClearReadOnly(path: String): Boolean;
		procedure SaveIni;
		procedure SavePlayList;
		procedure SetType(i: Integer; s: String);
		procedure SetSoundGen(i: Integer; s: String);
		procedure SetListIndex(i: Integer);
    procedure AddPlayList(path: String);
		procedure AddFolder(path: String);
    procedure TerminateThread;
  protected
    { Protected 宣言 }
		procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public 宣言 }
    ExeDllFolder: String;
    OSVerInfo: TOSVersionInfo;
		bGiveio: Boolean;
    //
		bPciDebugSys, bPciDebugDll: Boolean;
    hndPciDebug: THandle;
    pathPciDebugSys, pathPciDebugDll: String;
		FuncCnfRead8: TCnfRead8;
		FuncCnfRead16: TCnfRead16;
		FuncCnfRead32: TCnfRead32;
    FuncCnfWrite16: TCnfWrite16;
		FuncMemRead8: TMemRead8;
		FuncMemRead32: TMemRead32;
		FuncMemWrite8: TMemWrite8;
		FuncMemWrite32: TMemWrite32;
    //
		bMpusbApi: Boolean;
    hndMpusbApi: THandle;
    pathMpusbApi: String;
		MPUSBGetDLLVersion: TMPUSBGetDLLVersion;
		MPUSBGetDeviceCount: TMPUSBGetDeviceCount;
	  MPUSBOpen: TMPUSBOpen;
  	MPUSBRead: TMPUSBRead;
		MPUSBWrite: TMPUSBWrite;
		MPUSBReadInt: TMPUSBReadInt;
	 	MPUSBClose: TMPUSBClose;
		MPUSBGetDeviceDescriptor: TMPUSBGetDeviceDescriptor;
		MPUSBGetConfigurationDescriptor: TMPUSBGetConfigurationDescriptor;
		MPUSBGetStringDescriptor: TMPUSBGetStringDescriptor;
		MPUSBSetConfiguration: TMPUSBSetConfiguration;
    //
		bFtd2xx: Boolean;
		hndFtd2xx: THandle;
    pathFtd2xx: String;
		FT_CreateDeviceInfoList: TFT_CreateDeviceInfoList;
		FT_GetDeviceInfoList: TFT_GetDeviceInfoList;
		FT_Open: TFT_Open;
		FT_Close: TFT_Close;
		FT_Read: TFT_Read;
		FT_Write: TFT_Write;
		FT_SetBitMode: TFT_SetBitMode;
		FT_GetBitMode: TFT_GetBitMode;
		FT_GetLibraryVersion: TFT_GetLibraryVersion;
    //
		bZlib1: Boolean;
    hndZlib1: THandle;
		pathZlib1: String;
		zlibVersion: TzlibVersion;
		zlibCompileFlags: TzlibCompileFlags;
    compress2: Tcompress2;
    uncompress: Tuncompress;
	  gzopen: Tgzopen;
		gzread: Tgzread;
    gzseek: Tgzseek;
  	gzclose: Tgzclose;
    crc32: Tcrc32;
    //
    bDebug: Boolean;
    sRevString: String;
    nFreq, nStart: Int64;
    Kss: TKss;
    ThreadCnt: Integer;
	  ThreadCri: array[0..OUTPUT_THREADMAX-1] of TThreadCri;
    //
		function StringToIntDef(const S: string; Default: Integer): Integer;
		function IoRead8(addr: Word): Byte;
		procedure IoWrite8(addr: Word; data: Byte);
  end;

var
  MainForm: TMainForm;

implementation

uses Unit2, input, output, pnsf, pspc, ppsf;

var
  InputThread: TInputThread;
 	KssThread: TKssThread;
  NsfThread: TNsfThread;
  PsfThread: TPsfThread;
  SpcThread: TSpcThread;
 	OutputThread: array[0..OUTPUT_THREADMAX-1] of TOutputThread;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
	var
  	hnd: THandle;
	var
  	path, s, t: String;
	  ini: TIniFile;
    sl1, sl2: TStringList;
    i, j: Integer;
   	sb: array[0..MAX_PATH-1] of Char;
  var
    Form: TRect;
begin

	//
  DefaultFolder := GetCurrentDir+'\';
  FormCaption := Application.Title +' - ';
  MainForm.Caption := FormCaption;
	//ウィンドウ最小幅高さ
  nFormHeightMin := MainForm.Height;
  nFormWidthMin := MainForm.Width;

  //
  with TStringList.Create do
  begin
  	try
	  	Clear;
//			Add('*.dsf; *.minidsf');
//			Add('*.gsf; *.minigsf');
			Add('*.kss');
			Add('*.nsf');
//			Add('*.psf; *.minipsf');
			Add('*.s98');
			Add('*.spc');
			Add('*.spu');
			Add('*.ssf; *.minissf');
			Add('*.vgm; *.vgz');
	    Text := LowerCase(Text);
  	  //
			s := '';
	    t := '';
  	  for i := 0 to Count-1 do
    	begin
    		if s<>'' then
      		s := s + '; ';
				s := s + Strings[i];
  	    t := t + '|'+Strings[i] + '|'+Strings[i];
    	end;
    finally
    	Free;
    end;
	  OpenDlg.Filter := 'すべての対応形式|' + s + t;
    //
    s := StringReplace(s, '*', '', [rfReplaceAll]);
    s := StringReplace(s, '; ', '*', [rfReplaceAll]);
    FileFilter := UpperCase(s) + '*';
  end;

	//
  InputThread := nil;
  KssThread := nil;
  NsfThread := nil;
  PsfThread := nil;
  SpcThread := nil;
	Kss := TKss.Create;
  ThreadCnt := 0;
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
	 	OutputThread[i] := nil;
  	ThreadCri[i].nBufSize := SizeOf(ThreadCri[i].Buf) div SizeOf(ThreadCri[i].Buf[0]);
		ThreadCri[i].Cri := TCriticalSection.Create;
  end;
  //
  bDebug := not True;
  sRevString := 'r0.18';
  QueryPerformanceFrequency(nFreq);
  timeBeginPeriod(1);

  //OSバージョンの取得
  ExeDllFolder := ExtractFilePath(Application.ExeName);
  FillChar(OSVerInfo, SizeOf(OSVerInfo), $00);
	OSVerInfo.dwOSVersionInfoSize := SizeOf(OSVerInfo);
  bGiveio := False;
	if GetVersionEx(OSVerInfo) then
  begin
  	if OSVerInfo.dwPlatformId=VER_PLATFORM_WIN32_NT then
    begin
		  //giveioが使用できるか
			hnd := CreateFile('\\.\giveio', GENERIC_READ, 0, nil, OPEN_EXISTING,
		  	FILE_ATTRIBUTE_NORMAL, 0);
			if hnd<>INVALID_HANDLE_VALUE then
		 	begin
		  	//使用できる
			  bGiveio := True;
				CloseHandle(hnd);
		  end;
    end else
    begin
	  	//使用できる
		  bGiveio := True;
    end;
  end;

  //pcidebug.sysが存在するか
  bPciDebugSys := False;
  pathPciDebugSys := '';
  path := ExeDllFolder + 'pcidebug.sys';
 	if FileExists(path)=True then
  begin
	  bPciDebugSys := True;
  	pathPciDebugSys := path;
  end;

  //pcidebug.dllが使用できるか
  bPciDebugDll := False;
  hndPciDebug := 0;
  pathPciDebugDll := '';
  if bPciDebugSys=True then
  begin
	 	path := ChangeFileExt(pathPciDebugSys, '.dll');
 		hndPciDebug := LoadLibrary(PChar(path));
	  if hndPciDebug<>0 then
  	begin
  		//使用できる
			FuncCnfRead8 := GetProcAddress(hndPciDebug, '_pciConfigReadChar');
	    FuncCnfRead16 := GetProcAddress(hndPciDebug, '_pciConfigReadShort');
  	  FuncCnfRead32 := GetProcAddress(hndPciDebug, '_pciConfigReadLong');
      FuncCnfWrite16 := GetProcAddress(hndPciDebug, '_pciConfigWriteShort');
    	FuncMemRead8 := GetProcAddress(hndPciDebug, '_MemReadChar');
	    FuncMemRead32 := GetProcAddress(hndPciDebug, '_MemReadLong');
  	  FuncMemWrite8 := GetProcAddress(hndPciDebug, '_MemWriteChar');
    	FuncMemWrite32 := GetProcAddress(hndPciDebug, '_MemWriteLong');
		  //
		  if (Assigned(FuncCnfRead8)=False) or (Assigned(FuncCnfRead16)=False) or
      	(Assigned(FuncCnfRead32)=False) or (Assigned(FuncCnfWrite16)=False) or
        (Assigned(FuncMemRead8)=False) or (Assigned(FuncMemRead32)=False) or
        (Assigned(FuncMemWrite8)=False) or (Assigned(FuncMemWrite32)=False) then
		  begin
    		//閉じる
	    	FreeLibrary(hndPciDebug);
		    hndPciDebug := 0;
  	  end else
    	begin
		  	bPciDebugDll := True;
			  if GetModuleFileName(hndPciDebug, sb, SizeOf(sb))>0 then
  	    	pathPciDebugDll := sb;
    	end;
    end;
  end;

  //mpusbapi.dllが使用できるか
  bMpusbApi := False;
  path := ExeDllFolder + 'mpusbapi.dll';
 	hndMpusbApi := LoadLibrary(PChar(path));
  pathMpusbApi := '';
  if hndMpusbApi<>0 then
  begin
  	//使用できる
  	MPUSBGetDLLVersion := GetProcAddress(hndMpusbApi, '_MPUSBGetDLLVersion');
  	MPUSBGetDeviceCount := GetProcAddress(hndMpusbApi, '_MPUSBGetDeviceCount');
  	MPUSBOpen := GetProcAddress(hndMpusbApi, '_MPUSBOpen');
  	MPUSBRead := GetProcAddress(hndMpusbApi, '_MPUSBRead');
  	MPUSBWrite := GetProcAddress(hndMpusbApi, '_MPUSBWrite');
  	MPUSBReadInt := GetProcAddress(hndMpusbApi, '_MPUSBReadInt');
  	MPUSBClose := GetProcAddress(hndMpusbApi, '_MPUSBClose');
  	MPUSBGetDeviceDescriptor := GetProcAddress(hndMpusbApi, '_MPUSBGetDeviceDescriptor');
  	MPUSBGetConfigurationDescriptor := GetProcAddress(hndMpusbApi, '_MPUSBGetConfigurationDescriptor');
  	MPUSBGetStringDescriptor := GetProcAddress(hndMpusbApi, '_MPUSBGetStringDescriptor');
  	MPUSBSetConfiguration := GetProcAddress(hndMpusbApi, '_MPUSBSetConfiguration');
    //
    if (Assigned(MPUSBGetDLLVersion)=False) or (Assigned(MPUSBGetDeviceCount)=False) or
    	(Assigned(MPUSBOpen)=False) or (Assigned(MPUSBRead)=False) or
      (Assigned(MPUSBWrite)=False) or (Assigned(MPUSBReadInt)=False) or
      (Assigned(MPUSBClose)=False) or (Assigned(MPUSBGetDeviceDescriptor)=False) or
      (Assigned(MPUSBGetConfigurationDescriptor)=False) or (Assigned(MPUSBGetStringDescriptor)=False) or
      (Assigned(MPUSBSetConfiguration)=False) then
    begin
    	//閉じる
	    FreeLibrary(hndMpusbApi);
	    hndMpusbApi := 0;
    end else
    begin
		  bMpusbApi := True;
		  if GetModuleFileName(hndMpusbApi, sb, SizeOf(sb))>0 then
      	pathMpusbApi := sb;
    end;
  end;

  //ftd2xx.dllが使用できるか
  bFtd2xx := False;
  path := ExeDllFolder + 'ftd2xx.dll';
 	hndFtd2xx := LoadLibrary(PChar(path));
  pathFtd2xx := '';
  if hndFtd2xx<>0 then
  begin
  	//使用できる
		FT_CreateDeviceInfoList := GetProcAddress(hndFtd2xx, 'FT_CreateDeviceInfoList');
		FT_GetDeviceInfoList := GetProcAddress(hndFtd2xx, 'FT_GetDeviceInfoList');
		FT_Open := GetProcAddress(hndFtd2xx, 'FT_Open');
		FT_Close := GetProcAddress(hndFtd2xx, 'FT_Close');
		FT_Read := GetProcAddress(hndFtd2xx, 'FT_Read');
		FT_Write := GetProcAddress(hndFtd2xx, 'FT_Write');
		FT_SetBitMode := GetProcAddress(hndFtd2xx, 'FT_SetBitMode');
		FT_GetBitMode := GetProcAddress(hndFtd2xx, 'FT_GetBitMode');
		FT_GetLibraryVersion := GetProcAddress(hndFtd2xx, 'FT_GetLibraryVersion');
    //
		if (Assigned(FT_CreateDeviceInfoList)=False) or (Assigned(FT_GetDeviceInfoList)=False) or
			(Assigned(FT_Open)=False) or (Assigned(FT_Close)=False) or
			(Assigned(FT_Read)=False) or (Assigned(FT_Write)=False) or
      (Assigned(FT_SetBitMode)=False) or (Assigned(FT_GetBitMode)=False) or
			(Assigned(FT_GetLibraryVersion)=False) then
    begin
    	//閉じる
	    FreeLibrary(hndFtd2xx);
	    hndFtd2xx := 0;
    end else
    begin
		  bFtd2xx := True;
		  if GetModuleFileName(hndFtd2xx, sb, SizeOf(sb))>0 then
      	pathFtd2xx := sb;
    end;
  end;

  //zlib1.dllが使用できるか
  bZlib1 := False;
  path := ExeDllFolder + 'zlib1.dll';
 	hndZlib1 := LoadLibrary(PChar(path));
  pathZlib1 := '';
  if hndZlib1<>0 then
  begin
  	//使用できる
  	zlibVersion := GetProcAddress(hndZlib1, 'zlibVersion');
 		zlibCompileFlags := GetProcAddress(hndZlib1, 'zlibCompileFlags');
  	compress2 := GetProcAddress(hndZlib1, 'compress2');
  	uncompress := GetProcAddress(hndZlib1, 'uncompress');
	  gzopen := GetProcAddress(hndZlib1, 'gzopen');
		gzread := GetProcAddress(hndZlib1, 'gzread');
    gzseek := GetProcAddress(hndZlib1, 'gzseek');
  	gzclose := GetProcAddress(hndZlib1, 'gzclose');
    crc32 := GetProcAddress(hndZlib1, 'crc32');
    //
    if (Assigned(zlibVersion)=False) or (Assigned(zlibCompileFlags)=False) or
    	(Assigned(compress2)=False) or (Assigned(uncompress)=False) or
      (Assigned(gzopen)=False) or (Assigned(gzread)=False) or
      (Assigned(gzseek)=False) or (Assigned(gzclose)=False) or
      (Assigned(crc32)=False) then
    begin
    	//閉じる
	    FreeLibrary(hndZlib1);
	    hndZlib1 := 0;
    end else
    begin
		  bZlib1 := True;
		  if GetModuleFileName(hndZlib1, sb, SizeOf(sb))>0 then
      	pathZlib1 := sb;
    end;
  end;

  //
 	path := ChangeFileExt(Application.ExeName, '.ini');
  ini := TIniFile.Create(path);
  sl1 := TStringList.Create;
  try
  	//
    Form.Left := ini.ReadInteger('MainForm', 'Left', MaxInt);
    Form.Top := ini.ReadInteger('MainForm', 'Top', MaxInt);
    Form.Right := ini.ReadInteger('MainForm', 'Right', MaxInt);
    Form.Bottom := ini.ReadInteger('MainForm', 'Bottom', MaxInt);

		//
    sl1.CommaText := ini.ReadString('MainForm', 'Column', '');
    if sl1.Count=ListView.Columns.Count then
    begin
	   	for i := 0 to sl1.Count-1 do
      begin
        j := StrToIntDef(sl1.Strings[i], 0);
        if j>0 then
					ListView.Column[i].Width := j;
      end;
    end;
    //
		nListIndex := -1;
    SetListIndex(ini.ReadInteger('MainForm', 'Index', -1));
  finally
  	ini.Free;
    sl1.Free;
  end;

  //
	try
	  path := ChangeFileExt(Application.ExeName, '.lst');
	  if FileExists(path)=True then
    begin
			sl1 := TStringList.Create;
			sl2 := TStringList.Create;
		  try
        //
	      sl1.Capacity := Max(sl1.Capacity, 10000);
     		sl1.LoadFromFile(path);
        //
			  ListView.Items.BeginUpdate;
			 	ListView.Items.Clear;
        for i := 0 to sl1.Count-1 do
        begin
          //
          sl2.CommaText := sl1.Strings[i];
          if sl2.Count<2 then
          	Continue;
          //
          if AnsiPos('.\', sl2.Strings[0])=1 then
          begin
          	path := sl2.Strings[0];
				    if AnsiEndsStr('\', path)=False then
				    	path := path + '\';
          	path := ExpandUNCFileName(ExeDllFolder + path);
          	sl2.Strings[0] := ExtractFileDir(path);
          end;
          //
					with ListView.Items.Add do
          begin
          	Caption := sl2.Strings[0];
	          for j := 1 to MainForm.ListView.Columns.Count-1 do
  	        begin
    	      	if j<sl2.Count then
								SubItems.Add(sl2.Strings[j])
        	    else
								SubItems.Add('-');
            end;
          end;
        end;
			finally
			  ListView.Items.EndUpdate;
				sl1.Free;
				sl2.Free;
			end;
    end;
  except
	 	on E:Exception do
    	ShowMessage(E.Message);
  end;

  //
  if nListIndex>=ListView.Items.Count then
  	SetListIndex(-1);
  if nListIndex<0 then
  begin
		ListView.ItemIndex := -1;
	  ListView.ItemFocused := nil;
  end else
  begin
		ListView.ItemIndex := nListIndex;
	  ListView.ItemFocused := ListView.Items.Item[nListIndex];
    ListView.Selected.MakeVisible(True);
  end;

	//
  OpenDlg.InitialDir := DefaultFolder;
  TimeLbl.Caption := '00:00';
  EndTimeLbl.Caption := '-';
  Memo.Lines.Clear;

  //ウィンドウ設定
  if (Form.Left<>MaxInt) and (Form.Top<>MaxInt) and
  	(Form.Right<>MaxInt) and (Form.Bottom<>MaxInt) then
  begin
		MainForm.Position := poDesigned;
	  MainForm.Left := Form.Left;
	  MainForm.Top := Form.Top;
	  MainForm.Width := Form.Right;
	  MainForm.Height := Form.Bottom;
  end else
  begin
		MainForm.Position := poScreenCenter;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
	var
  	i: Integer;
begin
  //
  bGiveio := False;
  if hndPciDebug<>0 then
  begin
  	//閉じる
    FreeLibrary(hndPciDebug);
    hndPciDebug := 0;
	  bPciDebugDll := False;
	  bPciDebugSys := False;
  end;
  if hndMpusbApi<>0 then
  begin
  	//閉じる
    FreeLibrary(hndMpusbApi);
    hndMpusbApi := 0;
	  bMpusbApi := False;
  end;
  if hndFtd2xx<>0 then
  begin
  	//閉じる
    FreeLibrary(hndFtd2xx);
    hndFtd2xx := 0;
	  bFtd2xx := False;
  end;
  if hndZlib1<>0 then
  begin
  	//閉じる
    FreeLibrary(hndZlib1);
    hndZlib1 := 0;
	  bZlib1 := False;
  end;

  //
  Kss.Free;
  for i := 0 to OUTPUT_THREADMAX-1 do
		ThreadCri[i].Cri.Free;
  //
  timeEndPeriod(1{10});
end;


function TMainForm.ClearReadOnly(path: String): Boolean;
	var
    attrs: Integer;
begin
	//
  Result := False;
  if FileExists(path)=False then
  	Exit;
  attrs := FileGetAttr(path);
  if attrs<0 then
  	Exit;
	//
 	Result := True;
  if (attrs and faReadOnly)<>0 then
  begin
   	if FileSetAttr(path, attrs-faReadOnly)<>0 then
    	Result := False;
  end;
end;

procedure TMainForm.SaveIni;
	var
  	path, s: String;
	  ini: TIniFile;
    sl: TStringList;
    i, j: Integer;
begin
  //
  if WindowState=wsMaximized then
  begin
  	Application.Minimize;
  	WindowState := wsNormal;
  end;

	//
 	path := ChangeFileExt(Application.ExeName, '.ini');
 	ClearReadOnly(path);
	//
  ini := TIniFile.Create(path);
  sl := TStringList.Create;
  try
  	//
    with MainForm do
    begin
    	//
    	ini.WriteInteger('MainForm', 'Left', Left);
    	ini.WriteInteger('MainForm', 'Top', Top);
    	ini.WriteInteger('MainForm', 'Right', Width);
    	ini.WriteInteger('MainForm', 'Bottom', Height);

			//
	    sl.Clear;
	    for i := 0 to ListView.Columns.Count-1 do
	    	sl.Add(IntToStr(ListView.Column[i].Width));
	    ini.WriteString('MainForm', 'Column', sl.CommaText);
	    //
	    ini.WriteInteger('MainForm', 'Index', nListIndex);
  	end;

  	//
    with DeviceForm do
    begin
    	//
      if Tag=0 then
      begin
	    	ini.WriteInteger('DeviceForm', 'Left', Left);
  	  	ini.WriteInteger('DeviceForm', 'Top', Top);
				ini.WriteBool('DeviceForm', 'Visible', Visible);
      end;

      //
	    for i := 0 to CONNECT_DEVMAX-1 do
	    begin
        //
        if Cs[i].nIf=IF_INT then
        	Continue;
				//
		    sl.Clear;
		    if Cs[i].Chk.Checked then
		    	sl.Add('1')
		    else
		    	sl.Add('0');
	    	sl.Add(Cs[i].DevCB.Text);
	    	sl.Add(Cs[i].ClkCB.Text);
        case Cs[i].nIf of
				  IF_EZUSB:
  	      	begin
				    	s := 'Ezusb'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
					    ini.WriteString('DeviceForm', s, sl.CommaText);
            end;
				  IF_PIC:
  	      	begin
				    	s := 'Pic'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
					    ini.WriteString('DeviceForm', s, sl.CommaText);
            end;
				  IF_FTDI:
  	      	begin
				    	s := 'Ftdi'+IntToStr(Cs[i].nIfNum)+'Device'+IntToStr(Cs[i].nCs)+'-'+IntToStr(Cs[i].nIndex);
					    ini.WriteString('DeviceForm', s, sl.CommaText);
            end;
        end;
      end;

	    //
      sl.Clear;
      sl.Sorted := True;
		  sl.Duplicates := dupIgnore;
	    for i := 0 to CONNECT_DEVMAX-1 do
      begin
        if Cs[i].nIf=IF_INT then
        	Continue;
      	s := Trim(Cs[i].ClkCB.Text);
        if s<>'' then
	      	sl.Add(s);
	    	for j := 0 to Cs[i].ClkCB.Items.Count-1 do
   	  		sl.Add(Cs[i].ClkCB.Items.Strings[j]);
      end;
      ini.WriteString('DeviceForm', 'DevClock', sl.CommaText);

      //
		  for i := 0 to EZUSB_DEVMAX-1 do
		 	begin
		    if DeviceForm.EzusbTab[i].AutoChk.Checked then
		    	s := '1'
		    else
		    	s := '0';
	      ini.WriteString('DeviceForm', 'Ezusb'+IntToStr(i)+'Auto', s);
      end;
      //
		  for i := 0 to PIC_DEVMAX-1 do
		 	begin
		    if DeviceForm.PicTab[i].AutoChk.Checked then
		    	s := '1'
		    else
		    	s := '0';
	      ini.WriteString('DeviceForm', 'Pic'+IntToStr(i)+'Auto', s);
      end;
      //
		  for i := 0 to FTDI_DEVMAX-1 do
		 	begin
		    if DeviceForm.FtdiTab[i].AutoChk.Checked then
		    	s := '1'
		    else
		    	s := '0';
	      ini.WriteString('DeviceForm', 'Ftdi'+IntToStr(i)+'Auto', s);
      end;

	    //
	    s := 'KssStart';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'KssLimit';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'KssSpeed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'NsfStart';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'NsfLimit';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'NsfSpeed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'PsfTime';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'PsfLoop';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'PsfLimit';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'PsfSpeed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'S98Loop';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'S98Speed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'SpcTime';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'SpcLoop';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'SpcLimit';
      ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'SpuSpeed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'VgmLoop';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'VgmSpeed';
			ini.WriteBool('DeviceForm', s, GetBool(s));
		  //
      s := 'FtdiSetBitMode';
		  ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'IntPitChannel';
		  ini.WriteInteger('DeviceForm', s, GetInteger(s));
      //
      s := 'Ga20Attenuation';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
      //
	    s := 'Opl2Opll';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Opl2OpllInst';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opl2OpllpInst';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opl2Vrc7Inst';
		  ini.WriteString('DeviceForm', s, GetString(s));
      //
	    s := 'Opl3ChannelChg';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Opl3OpllMoRo';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Opl3nlOplChannelLr';
			ini.WriteBool('DeviceForm', s, GetBool(s));
			//
	    s := 'Solo1ChannelLr';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Solo1VolumeChg';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Solo1Volume';
		  ini.WriteString('DeviceForm', s, GetString(s));
      //
	    s := 'Opl4FmMix';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opl4PcmMix';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opl4PcmChannelChg';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Opl4+RamDo';
	    ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opl4+RamSpdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'OpmFmAttenuation';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
      //
	    s := 'OpnFmAttenuation';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
			//
	    s := 'OpnaBalance';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'OpnaOpn2Pcm';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      s := 'OpnaOpn2PcmType';
		  ini.WriteString('DeviceForm', s, GetString(s));
		  //
	    s := 'OpnbBalance';
	    ini.WriteInteger('DeviceForm', s, GetInteger(s));
	    s := 'OpnbOpnaRhythm';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'OpnbOpnaBd';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'OpnbOpnaSd';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'OpnbOpnaTop';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'OpnbOpnaHh';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'OpnbOpnaTom';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'OpnbOpnaRim';
		  ini.WriteString('DeviceForm', s, GetString(s));
		  //
	    s := 'Opx+RamDoExt';
	    ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Opx+Ram18bit';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Opx+RamSpdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'Pcmd8DoEo';
	    ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Pcmd8Spdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'Rp2a03Ctl';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Rp2a03+ExtMask';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMaskVrc6';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMaskVrc7';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMaskRp2c33';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMaskMmc5';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMask163';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtMask5b';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtRegRead';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
//	    s := 'Rp2a03+ExtMmc5Read';
// 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+Ext163Read';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Rp2a03+ExtNc';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomsel';
			ini.WriteBool('DeviceForm', s, GetBool(s));
			s := 'Rp2a03+ExtRomselVrc6';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomselVrc7';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomselRp2c33';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomselMmc5';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomsel163';
			ini.WriteString('DeviceForm', s, GetString(s));
			s := 'Rp2a03+ExtRomsel5b';
			ini.WriteString('DeviceForm', s, GetString(s));
		  //
	    s := '052539CompatibleMode';
 			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'Scsp+ScpuCtl';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Scsp+ScpuExt';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Scsp+Scpu18bit';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Scsp+ScpuSpdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'SpuExt';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'SpuSpdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'Ssmp+SdspCtl';
		  ini.WriteString('DeviceForm', s, GetString(s));
	    s := 'Ssmp+SdspType';
			ini.WriteBool('DeviceForm', s, GetBool(s));
	    s := 'Ssmp+SdspSpdif';
			ini.WriteBool('DeviceForm', s, GetBool(s));
      //
	    s := 'TabPosition';
		  ini.WriteString('DeviceForm', s, GetString(s));
      if False then
      begin
		    s := '_RelPath';
				ini.WriteBool('DeviceForm', s, GetBool(s));
      end;
    end;

    //
    ini.UpdateFile;

  finally
  	ini.Free;
    sl.Free;
  end;
end;


procedure TMainForm.WMCopyData(var Msg: TWMCopyData);
	var
  	path: String;
begin
	//
  try
  	//
	  path := PChar(PCopyDataStruct(Msg.CopyDataStruct).lpData);
	  ListView.Items.BeginUpdate;
	  if DirectoryExists(path) then
	  	AddFolder(path)
	  else
	  	AddPlayList(path);
	finally
	  ListView.Items.EndUpdate;
	end;
end;

procedure TMainForm.WMSizing(var Msg: TMessage);
begin
	//フォームサイズの制限
  with PRect(Msg.LParam)^ do
  begin
    if (Right-Left)<nFormWidthMin then
      Right := Left + nFormWidthMin;
    if (Bottom-Top)<nFormHeightMin then
      Bottom := Top + nFormHeightMin;
  end;
	//
  inherited;
end;

procedure TMainForm.CreateParams(var Params: TCreateParams);
begin
	//
  inherited CreateParams(Params);
	//ファイルのドロップ許可
  Params.ExStyle := Params.ExStyle or WS_EX_ACCEPTFILES;
end;

procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles);
	var
  	c, i: Cardinal;
		path: array[0..MAX_PATH-1] of Char;
begin
	//
  try
		//ドロップされたファイル数
  	c := DragQueryFile(Msg.Drop, Cardinal(-1), nil, 0);
    if c<1 then
    	Exit;
		//
	  ListView.Items.BeginUpdate;
    for i := 0 to c-1 do
    begin
	    if DragQueryFile(Msg.Drop, i, path, sizeof(path))>0 then
      begin
      	//
			  if DirectoryExists(path) then
			  	AddFolder(path)
			  else
			  	AddPlayList(path);
      end;
    end;
  finally
	  ListView.Items.EndUpdate;
    DragFinish(Msg.Drop);
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	//
	SaveIni;
  SavePlayList;
  //スレッド破棄
  TerminateThread;
  DeviceForm.CloseEzusb;
  DeviceForm.ClosePic;
  DeviceForm.CloseFtdi;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	//
end;

procedure TMainForm.WMQueryEndSession(var Msg: TWMQueryEndSession);
begin
	//
	SaveIni;
  SavePlayList;
  //スレッド破棄
  TerminateThread;
  DeviceForm.CloseEzusb;
  DeviceForm.ClosePic;
  DeviceForm.CloseFtdi;
  //
  inherited;
end;


function TMainForm.StringToIntDef(const S: string; Default: Integer): Integer;
	var
  	str: String;
		i, base, c, a: Integer;
		plus, err: Boolean;
		v: Int64;
begin
	//
  str := LowerCase(Trim(S));
	i := 1;
  plus := True;
	if AnsiPos('+', S)=i then
	begin
  	plus := True;
		Inc(i);
  end else
	if AnsiPos('-', S)=i then
	begin
  	plus := False;
		Inc(i);
  end;

	//
	base := 10;
	if AnsiPos('$', str)=i then
	begin
		base := 16;
		Inc(i);
	end else
	if AnsiPos('0x', str)=i then
	begin
		base := 16;
		Inc(i, 2);
	end else
	if AnsiPos('0b', str)=i then
	begin
		base := 2;
		Inc(i, 2);
	end;

	//
	err := True;
	v := 0;
	while i<=Length(str) do
	begin
		//
		c := Ord(s[i]);
    a := -1;
		case c of
			Ord('0')..Ord('9'):
				a := c - Ord('0');
			Ord('a')..Ord('f'):
        a := c - Ord('a') + $0a;
		end;
    if (a<0) or (a>=base) then
    begin
			err := True;
			Break;
    end;
    //
		v := v*base + a;
		if v>$7fffffff then
		begin
			err := True;
			Break;
		end;
		err := False;
		Inc(i);
	end;

	//
	if err=True then
		v := Default
	else
	begin
		if plus=False then
			v := -v;
	end;
	Result := v;
end;


function TMainForm.GetPathNumber(i: Integer): String;
	var
  	s: String;
begin
	//
  Result := '';
  if (i<0) or (i>=ListView.Items.Count) then
  	Exit;
	//
	with ListView.Items.Item[i] do
  begin
  	s := Caption;
    if AnsiEndsStr('\', s)=False then
    	s := s + '\';
	  Result := s + SubItems[0];
  end;
end;

function TMainForm.GetPath(i: Integer): String;
	var
  	s, t: String;
    n: Integer;
begin
	//
  Result := '';
  if (i<0) or (i>=ListView.Items.Count) then
  	Exit;
	//
	with ListView.Items.Item[i] do
  begin
  	s := Caption;
    if AnsiEndsStr('\', s)=False then
    	s := s + '\';
		//
  	t := SubItems[0];
	  n := AnsiPos('::', t);
  	if n>0 then
	  begin
  		//曲番あり
      t := LeftStr(t, n-1);
    end;
	  Result := s + t;
  end;
end;

function TMainForm.GetNumber(i: Integer): Integer;
	var
  	s: String;
    n: Integer;
begin
	//
  Result := -1;
  if (i<0) or (i>=ListView.Items.Count) then
  	Exit;
	//
	with ListView.Items.Item[i] do
  begin
	  s := SubItems[0];
	  n := AnsiPos('::', s);
  	if n>0 then
	  begin
  		//曲番あり
    	Result := StringToIntDef(RightStr(s, Length(s)-(n+2)+1), -1);
	  end;
  end;
end;

function TMainForm.GetType(i: Integer): String;
begin
	//
  Result := '';
  if (i<0) or (i>=ListView.Items.Count) then
  	Exit;
	//
	with ListView.Items.Item[i] do
	  Result := SubItems[1];
end;

procedure TMainForm.SetType(i: Integer; s: String);
begin
	//
	with ListView.Items.Item[i] do
	  SubItems[1] := s;
end;

procedure TMainForm.SetSoundGen(i: Integer; s: String);
begin
	//
  if s='' then
  begin
  	s := '-';
    if True then
    	Exit;
  end;
	//
	with ListView.Items.Item[i] do
	  SubItems[2] := s;
end;

procedure TMainForm.SetListIndex(i: Integer);
	var
  	n: Integer;
begin
	//
  if i<>nListIndex then
  begin
    //
    n := nListIndex;
  	nListIndex := i;
    if (n>=0) and (n<ListView.Items.Count) then
  		ListView.Items.Item[n].Update;
    if (i>=0) and (i<ListView.Items.Count) then
  		ListView.Items.Item[i].Update;
  end;
end;


procedure TMainForm.AddPlayList(path: String);
	var
  	ext: String;
begin
	//
  ext := UpperCase(ExtractFileExt(path));
  if (ext='') or (AnsiPos(ext+'*', FileFilter)=0) then
   	Exit;
  //
	with ListView.Items.Add do
  begin
		Caption := ExtractFileDir(path);
		SubItems.Add(ExtractFileName(path));
		SubItems.Add(RightStr(ext, Length(ext)-1));
	  SubItems.Add('-');
  end;
end;

procedure TMainForm.AddFolder(path: String);
	var
	  sr: TSearchRec;
begin
	//
  if AnsiEndsStr('\', path)=False then
  	path := path + '\';
	if FindFirst(path+'*.*', faAnyFile and (not faVolumeID), sr)<>0 then
   	Exit;
  //
  try
	 	repeat
	   	if (sr.Attr and faDirectory)=0 then
		  	AddPlayList(path+sr.Name)
	    else
     	if (sr.Name<>'.') and (sr.Name<>'..') then
	      AddFolder(path+sr.Name);
	  until FindNext(sr)<>0;
  finally
  	FindClose(sr);
  end;
end;

procedure TMainForm.SavePlayList;
	var
  	path, relpath, s: String;
    sl1, sl2: TStringList;
    i, j: Integer;
    f: Boolean;
begin
	//
  path := ChangeFileExt(Application.ExeName, '.lst');
  if FileExists(path)=True then
  begin
   	s := ChangeFileExt(path, '.~lst');
    if FileExists(s)=False then
    begin
 	 		RenameFile(path, s);
    end else
    begin
    	ClearReadOnly(s);
	    if DeleteFile(s)=True then
  	 		RenameFile(path, s);
    end;
  end;
  //
	f := DeviceForm.GetBool('_RelPath');
	sl1 := TStringList.Create;
	sl2 := TStringList.Create;
  try
  	sl1.Clear;
    sl1.Capacity := Max(sl1.Capacity, ListView.Items.Count);
	  for i := 0 to ListView.Items.Count-1 do
    begin
	  	sl2.Clear;
      sl2.Add(ListView.Items.Item[i].Caption);
    	for j := 0 to ListView.Items.Item[i].SubItems.Count-1 do
      	sl2.Add(ListView.Items.Item[i].SubItems.Strings[j]);
      //
		  if f=True then
		  begin
      	s := sl2.Strings[0];
        if AnsiEndsStr('\', s)=False then
        	s := s + '\';
		  	relpath := ExtractRelativePath(ExeDllFolder, s);
			  if (AnsiPos('..\', relpath)=0) and (Length(relpath)<Length(s)) then
		  		sl2.Strings[0] := '.\' + ExtractFileDir(relpath);
		  end;
      sl1.Add(sl2.CommaText);
    end;
    //
   	ClearReadOnly(path);
	  sl1.SaveToFile(path);
	finally
		sl1.Free;
		sl2.Free;
	end;
end;


function TMainForm.IoRead8(addr: Word): Byte;
begin
	//ポート入力
	asm
  	push eax
  	push edx
  	mov dx, addr
    in al, dx
  	mov Result, al
  	pop edx
  	pop eax
  end;
end;

procedure TMainForm.IoWrite8(addr: Word; data: Byte);
begin
	//ポート出力
	asm
  	push eax
  	push edx
  	mov dx, addr
  	mov al, data
    out dx, al
  	pop edx
  	pop eax
  end;
end;


procedure TMainForm.WMState(var Msg: TMessage);
	var
  	path, s: String;
    number: Integer;
  	f: Integer;
begin
	//
  case Msg.WParam of
    ST_TERMINATE:
    	begin
      	//スレッド破棄
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_TERMINATE');
      	TerminateThread;
        //
        if True then
        begin
					StopBtn.Enabled := False;
				  PMStop.Enabled := False;
        end;
      end;
  	ST_PLAY:
    	begin
				//再生
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_PLAY');
				//
			  if ListView.Items.Count<1 then
			  	Exit;
			  //
			  if nListIndex<0 then
			  	SetListIndex(0)
			  else
				if nListIndex>=ListView.Items.Count then
			  	SetListIndex(ListView.Items.Count-1);

				//
			  MainForm.Caption := FormCaption;
			  TimeLbl.Caption := '00:00';
			  EndTimeLbl.Caption := '-';
			  TimeLbl.Tag := 0;
			  EndTimeLbl.Tag := 0;
			  Memo.Lines.Clear;
			 	DeviceForm.LogEdit.Lines.Add('');

			  //
			  path := GetPath(nListIndex);
        number := GetNumber(nListIndex);
        if False then
	        DeviceForm.LogEdit.Lines.Add(DateTimeToStr(Now));
   			DeviceForm.LogEdit.Lines.Add(path);
			  if FileExists(path)=False then
			  begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:ファイルが存在しない');
			  	f := ST_ERR;
			  end else
			  begin
				  //
				  s := GetType(nListIndex);
				 	f := ST_ERR;
          if AnsiPos(s+'*', FileFilter)>0 then
          begin
					  if s='S98' then
					  	f := PlayS98(path)
					  else
      	    if s='KSS' then
						  f := PlayKss(path, number)
				  	else
	          if s='NSF' then
					  	f := PlayNsf(path, number)
					  else
					  if s='SPC' then
					  	f := PlaySpc(path)
				  	else
					  if s='SPU' then
					  	f := PlaySpu(path)
					  else
					  if s='VGM' then
					  	f := PlayVgm(path, True)
					  else
					  if s='VGZ' then
					  	f := PlayVgm(path, False)
          	else
	         	if {(s='PSF') or (s='MINIPSF') or} (s='SSF') or (s='MINISSF') {or
				    	(s='DSF') or (s='MINIDSF') or (s='GSF') or (s='MINIGSF')} then
				  		f := PlayPsf(path);
          end;
				  //
          if f=ST_MARK then
				  	SetType(nListIndex, '-');
			  end;
			  //
			  if f=ST_OK then
			  begin
			  	StopBtn.Enabled := True;
				  PMStop.Enabled := True;
			  end else
			  begin
			  	StopBtn.Enabled := False;
				  PMStop.Enabled := False;
			  end;
      end;
  	ST_PREV:
    	begin
      	//前
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_PREV');
			  if ListView.Items.Count>0 then
        begin
				  if nListIndex<1 then
					  SetListIndex(ListView.Items.Count-1)
				  else
				  	SetListIndex(nListIndex-1);
          Msg.LParam := ST_PLAY;
        end;
      end;
  	ST_NEXT:
    	begin
      	//次
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_NEXT');
			  if ListView.Items.Count>0 then
        begin
				  if (nListIndex+1)>=ListView.Items.Count then
					  SetListIndex(0)
				  else
				  	SetListIndex(nListIndex+1);
          Msg.LParam := ST_PLAY;
        end;
      end;
    else
    	begin
      	//不明
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_?('+IntToStr(Msg.WParam)+')');
      end;
  end;

  //
  if Msg.LParam<>0 then
		PostMessage(Handle, WM_STATE, Msg.LParam, 0);
end;

procedure TMainForm.WMThreadUpdateTime(var Msg: TMessage);
begin
	//
  if Msg.WParam>TimeLbl.Tag then
  begin
	  TimeLbl.Caption := Format('%.2d:%.2d', [Msg.WParam div 60, Msg.WParam mod 60]);
  	TimeLbl.Tag := Msg.WParam;
  end;
end;

procedure TMainForm.WMThreadUpdateEndTime(var Msg: TMessage);
begin
	//
  if Msg.WParam>EndTimeLbl.Tag then
  begin
	  EndTimeLbl.Caption := Format('%.2d:%.2d', [Msg.WParam div 60, Msg.WParam mod 60]);
  	EndTimeLbl.Tag := Msg.WParam;
  end;
end;

procedure TMainForm.WMThreadTerminate(var Msg: TMessage);
begin
  //
  if (bDebug=True) or (Msg.LParam=ST_THREAD_ERROR) then
	 	DeviceForm.LogEdit.Lines.Add('ThreadTerminate:'+IntToStr(Msg.WParam)+','+IntToStr(Msg.LParam));
	//
  case Msg.LParam of
  	ST_THREAD_ERROR:
    	begin
      	//エラー
        if ThreadCnt>0 then
        	Dec(ThreadCnt);
      end;
  	ST_THREAD_TERMINATE:
    	begin
      	//停止させた
        if ThreadCnt>0 then
        	Dec(ThreadCnt);
      end;
  	ST_THREAD_END:
    	begin
      	//再生終了
        if ThreadCnt>0 then
        	Dec(ThreadCnt);
        //すべてのスレッドが終了したら次の曲
				if ThreadCnt=0 then
        begin
        	if (nListIndex+1)<ListView.Items.Count then
						PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_NEXT)
  	      else
						PostMessage(Handle, WM_STATE, ST_TERMINATE, 0);
        end;
      end;
    else
    	begin
      	//不明
        if bDebug=True then
					DeviceForm.LogEdit.Lines.Add('ST_THREAD_?('+IntToStr(Msg.LParam)+')');
      end;
  end;
end;


procedure TMainForm.PlayBtnClick(Sender: TObject);
begin
	//再生
	PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_PLAY);
end;

procedure TMainForm.StopBtnClick(Sender: TObject);
begin
	//停止
	StopBtn.Enabled := False;
  PMStop.Enabled := False;
	PostMessage(Handle, WM_STATE, ST_TERMINATE, 0);
end;

procedure TMainForm.TerminateThread;
	var
  	i: Integer;
begin
	//スレッド終了
  if Assigned(InputThread) then
  begin
		InputThread.Terminate;
	  InputThread.WaitFor;
  	InputThread.Free;
	  InputThread := nil;
  end;
  if Assigned(KssThread) then
  begin
		KssThread.Terminate;
	  KssThread.WaitFor;
  	KssThread.Free;
	  KssThread := nil;
  end;
  if Assigned(NsfThread) then
  begin
		NsfThread.Terminate;
	  NsfThread.WaitFor;
  	NsfThread.Free;
	  NsfThread := nil;
  end;
  if Assigned(PsfThread) then
  begin
		PsfThread.Terminate;
	  PsfThread.WaitFor;
  	PsfThread.Free;
	  PsfThread := nil;
  end;
  if Assigned(SpcThread) then
  begin
		SpcThread.Terminate;
	  SpcThread.WaitFor;
  	SpcThread.Free;
	  SpcThread := nil;
  end;
	//
  for i := 0 to OUTPUT_THREADMAX-1 do
 	begin
   	if Assigned(OutputThread[i]) then
    begin
		  OutputThread[i].Terminate;
      OutputThread[i].WaitFor;
	    OutputThread[i].Free;
      OutputThread[i] := nil;
    end;
  end;
end;

procedure TMainForm.PrevBtnClick(Sender: TObject);
begin
	//前
	PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_PREV);
end;

procedure TMainForm.NextBtnClick(Sender: TObject);
begin
	//次
	PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_NEXT);
end;

procedure TMainForm.DevBtnClick(Sender: TObject);
begin
	//
  if DeviceForm.Visible then
		DeviceForm.Visible := False
  else
  begin
	  DeviceForm.Visible := True;
	  DeviceForm.Position := poDesigned;
  end;
end;


procedure TMainForm.ListViewDblClick(Sender: TObject);
begin
	//
	if ListView.ItemIndex<0 then
  	Exit;
  //
 	SetListIndex(ListView.ItemIndex);
	PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_PLAY);
end;

procedure TMainForm.ListViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
	//
  case Key of
  	VK_RETURN:
    	begin
      	if ListView.ItemIndex>=0 then
        begin
	      	SetListIndex(ListView.ItemIndex);
					PostMessage(Handle, WM_STATE, ST_TERMINATE, ST_PLAY);
        end;
      end;
    VK_DELETE:
    	PMDelete.Click;
  end;
end;

procedure TMainForm.ListViewColumnClick(Sender: TObject;
  Column: TListColumn);

	function CustomSortProc(Item1, Item2: TListItem; ParamSort: Integer): Integer; stdcall;
	begin
		//
	 	if ParamSort=0 then
		  Result := CompareText(Item1.Caption, Item2.Caption)
		else
	    Result := CompareText(Item1.SubItems[ParamSort-1], Item2.SubItems[ParamSort-1]);
	end;

	var
  	i: Integer;
    li: TListItem;
begin
	//
  if nListIndex<0 then
  	li := nil
  else
  begin
  	li := ListView.Items.Item[nListIndex];
	  SetListIndex(-1);
  end;

	//ソート
  ListView.CustomSort(@CustomSortProc, Column.Index);

	//
  if Assigned(li) then
  begin
   	//選択ファイルあり
   	i := ListView.Items.IndexOf(li);
    if ListView.Items.Count<1 then
    begin
     	//リストなし
    	SetListIndex(-1);
    end else
    begin
     	//リストあり
     	if i<0 then
       	i := 0;
    	SetListIndex(i);
    end;
  end;
end;

procedure TMainForm.ListViewAdvancedCustomDrawItem(
  Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
	//
  if nListIndex<>Item.Index then
  	Exit;
  Sender.Canvas.Brush.Color := clMoneyGreen;
end;


procedure TMainForm.PMDeleteClick(Sender: TObject);
	var
  	i: Integer;
    li: TListItem;
begin
	//
	if ListView.SelCount<1 then
  	Exit;
	//
  if nListIndex<0 then
  	li := nil
  else
  begin
  	li := ListView.Items.Item[nListIndex];
	  SetListIndex(-1);
  end;

  //選択ファイルをリストから削除
  try
  	ListView.Items.BeginUpdate;
	  ListView.DeleteSelected;
  finally
  	ListView.Items.EndUpdate;
  end;

	//
  if Assigned(li) then
  begin
   	//選択ファイルあり
   	i := ListView.Items.IndexOf(li);
    if ListView.Items.Count<1 then
    begin
     	//リストなし
    	SetListIndex(-1);
    end else
    begin
     	//リストあり
     	if i<0 then
       	i := 0;
    	SetListIndex(i);
    end;
  end;
end;

procedure TMainForm.PMExistClick(Sender: TObject);
	var
  	i: Integer;
    li: TListItem;
begin
	//
  if nListIndex<0 then
  	li := nil
  else
  begin
  	li := ListView.Items.Item[nListIndex];
	  SetListIndex(-1);
  end;

  //存在しないファイルをリストから削除
  //※曲番が指定されているファイルは除く
  try
		//
	  ListView.Items.BeginUpdate;
    ListView.ClearSelection;
	  for i := 0 to ListView.Items.Count-1 do
 	  begin
	    if FileExists(GetPath(i))=False then
      begin
      	if GetNumber(i)<0 then
       		ListView.Items.Item[i].Selected := True;
      end;
	  end;
    //削除
	  ListView.DeleteSelected;
  finally
	  ListView.Items.EndUpdate;
  end;

	//
  if Assigned(li) then
  begin
   	//選択ファイルあり
   	i := ListView.Items.IndexOf(li);
    if ListView.Items.Count<1 then
    begin
     	//リストなし
    	SetListIndex(-1);
    end else
    begin
     	//リストあり
     	if i<0 then
       	i := 0;
    	SetListIndex(i);
    end;
  end;
end;

procedure TMainForm.PMDuplicate1Click(Sender: TObject);
	var
    i: Integer;
    s: String;
    li: TListItem;
begin
	//
  if nListIndex<0 then
  	li := nil
  else
  begin
  	li := ListView.Items.Item[nListIndex];
	  SetListIndex(-1);
  end;

  //同じパスのファイルをリストから削除
  //※同一ファイルで同一曲番の場合も含む
	with TStringList.Create do
  begin
	  try
  		//
      CaseSensitive := False;
      Sorted := True;
      Duplicates := dupIgnore;
    	Capacity := ListView.Items.Count;
			//
		  ListView.Items.BeginUpdate;
      ListView.ClearSelection;
		  for i := 0 to ListView.Items.Count-1 do
  	  begin
    		s := GetPathNumber(i);
	      if IndexOf(s)<0 then
  	    	Add(s)
        else
        	ListView.Items.Item[i].Selected := True;
  		end;
      //削除
		  ListView.DeleteSelected;
		finally
		  ListView.Items.EndUpdate;
			Free;
		end;
  end;

	//
  if Assigned(li) then
  begin
   	//選択ファイルあり
   	i := ListView.Items.IndexOf(li);
    if ListView.Items.Count<1 then
    begin
     	//リストなし
    	SetListIndex(-1);
    end else
    begin
     	//リストあり
     	if i<0 then
       	i := 0;
    	SetListIndex(i);
    end;
  end;
end;

procedure TMainForm.PMAllDeleteClick(Sender: TObject);
begin
  //
  if MessageDlg('すべて削除しますか?', mtConfirmation, [mbYes, mbNo], 0)<>mrYes then
  	Exit;

  //
 	try
  	ListView.Items.BeginUpdate;
  	ListView.Items.Clear;
 		SetListIndex(-1);
  finally
 		ListView.Items.EndUpdate;
  end;
end;

procedure TMainForm.PMOpenClick(Sender: TObject);
	var
  	i: Integer;
begin
	//
  OpenDlg.FilterIndex := 1;
	if OpenDlg.Execute=False then
  	Exit;
  //
  try
  	ListView.Items.BeginUpdate;
	  for i := 0 to OpenDlg.Files.Count-1 do
			AddPlayList(OpenDlg.Files.Strings[i]);
  finally
  	ListView.Items.EndUpdate;
  end;
end;

procedure TMainForm.PMFolderClick(Sender: TObject);
	var
		mem: IMalloc;
  	lpbi: TBrowseInfo;
		il: PItemIDList;
		dn, s: array[0..MAX_PATH] of Char;

	function cb(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
  begin
		//
    if (uMsg=BFFM_INITIALIZED) and (lpData<>0) then
			SendMessage(Wnd, BFFM_SETSELECTION, WPARAM(True), lpData);
		Result := 0;
  end;

begin
	//
  lpbi.hwndOwner := MainForm.WindowHandle;
  lpbi.pidlRoot := nil;
  lpbi.pszDisplayName := dn;
  lpbi.lpszTitle := '';
  lpbi.ulFlags := BIF_RETURNONLYFSDIRS;
  lpbi.lpfn := Pointer(@cb);
  lpbi.lParam := LPARAM(PChar(DefaultFolder));
  lpbi.iImage := 0;
  //
  SHGetMalloc(mem);
	il := SHBrowseForFolder(lpbi);
	if Assigned(il) then
  begin
  	if SHGetPathFromIDList(il, s) then
    begin
    	//
		 	DefaultFolder := s;
      try
      	ListVIew.Items.BeginUpdate;
      	AddFolder(s);
      finally
      	ListView.Items.EndUpdate;
      end;
		end;
		mem.Free(il);
	end;
end;

procedure TMainForm.PMSelectClick(Sender: TObject);
begin
	//
  if nListIndex<0 then
  	Exit;
  //
  try
  	ListView.Items.BeginUpdate;
	 	ListView.ClearSelection;
		ListView.ItemIndex := nListIndex;
	  ListView.ItemFocused := ListView.Items.Item[nListIndex];
  	ListView.Selected.MakeVisible(True);
  finally
  	ListView.Items.EndUpdate;
  end;
end;

procedure TMainForm.PMExplorerClick(Sender: TObject);
	var
  	path, cmd: String;
    si: TStartupInfo;
    pi: TProcessInformation;
begin
	//
  path := GetPath(nListIndex);
  if (path='') or (FileExists(path)=False) then
  	Exit;

  //
  FillChar(si, SizeOf(si), $00);
  si.cb := SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := SW_SHOW;
	//
  cmd := 'explorer.exe ';
  if True then
  	cmd := cmd + '/n, ';
  if False then
  	cmd := cmd + '/e, ';
  cmd := cmd + '/select, "'+path+'"';
  //
  if CreateProcess(nil, PChar(cmd), nil, nil, False, NORMAL_PRIORITY_CLASS,
  	nil, nil, si, pi)=False then
  begin
  	//失敗
	 	DeviceForm.LogEdit.Lines.Add('エラー:エクスプローラの実行に失敗');
  end;
end;


procedure TMainForm.InitSetting(i: Integer);
begin
	//
	with ThreadCri[i] do
	begin
		nIntPitChannel				:= DeviceForm.GetInteger('IntPitChannel');
		nGa20Attenuation			:= DeviceForm.GetInteger('Ga20Attenuation');
		bOpl2Opll							:= DeviceForm.GetBool('Opl2Opll');
		Opl2OpllInst[0]				:= DeviceForm.GetPathString('Opl2OpllInst');
		Opl2OpllInst[1]				:= DeviceForm.GetPathString('Opl2OpllpInst');
		Opl2OpllInst[2]				:= DeviceForm.GetPathString('Opl2Vrc7Inst');
		bOpl3ChannelChg				:= DeviceForm.GetBool('Opl3ChannelChg');
		bOpl3OpllMoRo					:= DeviceForm.GetBool('Opl3OpllMoRo');
		bOpl3nlOplChannelLr		:= DeviceForm.GetBool('Opl3nlOplChannelLr');
		bSolo1ChannelLr				:= DeviceForm.GetBool('Solo1ChannelLr');
		bSolo1VolumeChg				:= DeviceForm.GetBool('Solo1VolumeChg');
		nSolo1Volume					:= DeviceForm.GetIndex('Solo1Volume', True);
		nOpl4FmMix						:= DeviceForm.GetIndex('Opl4FmMix', False);
		nOpl4PcmMix						:= DeviceForm.GetIndex('Opl4PcmMix', False);
		bOpl4PcmChannelChg		:= DeviceForm.GetBool('Opl4PcmChannelChg');
		nOpl4RamDo						:= DeviceForm.GetIndex('Opl4+RamDo', False);
		bOpl4RamSpdif					:= DeviceForm.GetBool('Opl4+RamSpdif');
		nOpmFmAttenuation			:= DeviceForm.GetInteger('OpmFmAttenuation');
		nOpnFmAttenuation			:= DeviceForm.GetInteger('OpnFmAttenuation');
		nOpnaBalance					:= DeviceForm.GetInteger('OpnaBalance');
		bOpnaOpn2Pcm					:= DeviceForm.GetBool('OpnaOpn2Pcm');
		nOpnaOpn2PcmType			:= DeviceForm.GetIndex('OpnaOpn2PcmType', False);
		nOpnbBalance					:= DeviceForm.GetInteger('OpnbBalance');
		bOpnbOpnaRhythm				:= DeviceForm.GetBool('OpnbOpnaRhythm');
		OpnbOpnaRhythm[0]			:= DeviceForm.GetPathString('OpnbOpnaBd');
		OpnbOpnaRhythm[1]			:= DeviceForm.GetPathString('OpnbOpnaSd');
		OpnbOpnaRhythm[2]			:= DeviceForm.GetPathString('OpnbOpnaTop');
		OpnbOpnaRhythm[3]			:= DeviceForm.GetPathString('OpnbOpnaHh');
		OpnbOpnaRhythm[4]			:= DeviceForm.GetPathString('OpnbOpnaTom');
		OpnbOpnaRhythm[5]			:= DeviceForm.GetPathString('OpnbOpnaRim');
		nOpxRamDoExt					:= DeviceForm.GetIndex('Opx+RamDoExt', False);
		bOpxRam18bit					:= DeviceForm.GetBool('Opx+Ram18bit');
		bOpxRamSpdif					:= DeviceForm.GetBool('Opx+RamSpdif');
		nPcmd8DoEo						:= DeviceForm.GetIndex('Pcmd8DoEo', False);
		bPcmd8Spdif						:= DeviceForm.GetBool('Pcmd8Spdif');
		b052539CompatibleMode	:= DeviceForm.GetBool('052539CompatibleMode');
 		bSpuExt								:= DeviceForm.GetBool('SpuExt');
    bSpuSpdif							:= DeviceForm.GetBool('SpuSpdif');
	end;
end;

function TMainForm.PlayS98(path: String): Integer;
	var
    fs: TFileStream;
		s98h: TS98Header;
    dev, bdev: TS98DeviceInfo;
    speed: Boolean;
    ratio: Extended;
  var
    s: String;
    i, j, n: Integer;

	function S98DevToDevice(info: DWORD): Integer;
	begin
		//
		Result := DEVICE_NONE;
		case info of
			//
			DEVS98_SSG:
				Result := DEVICE_SSG;
			DEVS98_OPN:
				Result := DEVICE_OPN;
			DEVS98_OPN2:
				Result := DEVICE_OPN2;
			DEVS98_OPNA:
				Result := DEVICE_OPNA_RAM;
			DEVS98_OPM:
				Result := DEVICE_OPM;
			DEVS98_OPLL:
				Result := DEVICE_OPLL;
			DEVS98_OPL:
				Result := DEVICE_OPL;
			DEVS98_OPL2:
				Result := DEVICE_OPL2;
			DEVS98_OPL3:
				Result := DEVICE_OPL3;
			DEVS98_PSG:
				Result := DEVICE_PSG;
			DEVS98_DCSG:
				Result := DEVICE_DCSG_GG;
		end;
		//
		if {(bDebug=True) and} (Result=DEVICE_NONE) then
		begin
			//※テスト用
			case info of
				DEVS98_USART:
					Result := DEVICE_USART;
				DEVS98_PIT:
					Result := DEVICE_PIT;
				DEVS98_EPSG:
					Result := DEVICE_EPSG;
				DEVS98_SAA1099:
					Result := DEVICE_SAA1099;
				DEVS98_OPP:
					Result := DEVICE_OPP;
				DEVS98_OPZ:
					Result := DEVICE_OPZ;
				DEVS98_OPNB:
					Result := DEVICE_OPNB_RAM;
				DEVS98_YM2610B:
					Result := DEVICE_YM2610B_RAM;
				DEVS98_OPLLP:
					Result := DEVICE_OPLLP;
				DEVS98_VRC7:
					Result := DEVICE_VRC7;
				DEVS98_MSXAUDIO:
					Result := DEVICE_MSXAUDIO_RAM;
				DEVS98_OPL4:
					Result := DEVICE_OPL4_RAM;
				DEVS98_MPU:
					Result := DEVICE_OPL4ML_MPU;
				DEVS98_SCC:
					Result := DEVICE_SCC;
				DEVS98_052539:
					Result := DEVICE_052539;
				DEVS98_GA20:
					Result := DEVICE_GA20;
			end;
		end;
	end;

begin
	//
  fs := nil;
  try
  try
		//
		fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
  	if fs.Read(s98h, SizeOf(s98h))<>SizeOf(s98h) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:S98ではない');
	  	Result := ST_MARK;
    	Exit;
		end;
    //
    s := Chr(s98h.Magic[0])+Chr(s98h.Magic[1])+Chr(s98h.Magic[2]);
    if s<>'S98' then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:S98ではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    case s98h.Magic[3] of
    	Ord('0')..Ord('3'):
      	begin
        end;
      else
		    begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
			  	Result := ST_ERR;
		    	Exit;
        end;
    end;

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

    //
	  if s98h.dwTimerInfo1=0 then
		 	s98h.dwTimerInfo1 := 10;
	  if s98h.dwTimerInfo2=0 then
		 	s98h.dwTimerInfo2 := 1000;
    //
    s := ''''+ s + Chr(s98h.Magic[3]) +''' ';
    s := s + IntToStr(s98h.dwTimerInfo1)+'/'+IntToStr(s98h.dwTimerInfo2) +' ';
    s := s + '$'+IntToHex(s98h.dwLoopOffset, 8);
    DeviceForm.LogEdit.Lines.Add(s);

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;
    if s98h.Magic[3]<>Ord('3') then
    begin
    	//V0-V2
	    for i := 0 to S98_DEVMAX-1 do
	    begin
      	//
		  	if fs.Read(dev, SizeOf(dev))<>SizeOf(dev) then
		    begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
			  	Result := ST_ERR;
		    	Exit;
		    end;
        //
        case dev.dwInfo of
        	DEVS98_NONE:
          	begin
    		    	if i=0 then
		          begin
          			//最初がDEVS98_NONEのときはDEVS98_OPNA
	      		    DeviceForm.AddReqDevice(IntToStr(i*2)+','+IntToStr(i*2+1), S98DevToDevice(DEVS98_OPNA), 7987200);
    		      end;
			        Break;
            end;
          else
          	begin
			        if dev.dwClock>0 then
      			  begin
					      if DeviceForm.AddReqDevice(IntToStr(i*2)+','+IntToStr(i*2+1), S98DevToDevice(dev.dwInfo), dev.dwClock)=False then
	    			    	Break;
			        end;
            end;
        end;
	    end;
    end else
    begin
    	//V3
      if s98h.dwCompressOffset=0 then
      begin
      	//デバイス数=0のときはDEVS98_OPNA
        DeviceForm.AddReqDevice(IntToStr(0*2)+','+IntToStr(0*2+1), S98DevToDevice(DEVS98_OPNA), 7987200);
      end else
      begin
      	//デバイス数>0
				FillChar(bdev, SizeOf(bdev), $00);
		    for i := 0 to s98h.dwCompressOffset-1 do
		    begin
			  	if fs.Read(dev, SizeOf(dev))<>SizeOf(dev) then
		    	begin
					 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
				  	Result := ST_ERR;
			    	Exit;
			    end;
          //
          case dev.dwInfo of
          	DEVS98_NONE:
		          begin
           			//一つ前のデバイスを調べる
	              if (i>0) and (bdev.dwInfo=DEVS98_OPL4) and (bdev.dwClock=dev.dwClock) then
   		          begin
       		      	//DEVS98_OPL4を追加する
	  			  	    if bdev.dwClock>0 then
      	  		    begin
					    		  if DeviceForm.AddReqDevice(IntToStr((i-1)*2)+','+IntToStr((i-1)*2+1)+','+IntToStr(i*2)+','+
                    	IntToStr(i*2+1), S98DevToDevice(bdev.dwInfo), bdev.dwClock)=False then
			          			Break;
			            end;
		            end;
    		      end;
          	DEVS98_OPL4:
		          begin
              	//無視する
                //  ※次がDEVS98_NONEの場合、DEVS98_OPL4を追加する
              end;
            else
		          begin
	  		  	    if dev.dwClock>0 then
        		    begin
				    		  if DeviceForm.AddReqDevice(IntToStr(i*2)+','+IntToStr(i*2+1), S98DevToDevice(dev.dwInfo), dev.dwClock)=False then
		          			Break;
		            end;
    		      end;
          end;
          //
          Move(dev, bdev, SizeOf(bdev));
		    end;
      end;
    end;

    //
  	if s98h.dwTitleOffset<>0 then
    begin
			//
	  	if fs.Seek(s98h.dwTitleOffset, soFromBeginning)<>Int64(s98h.dwTitleOffset) then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
		  	Result := ST_ERR;
	    	Exit;
      end;
      //
			if s98h.dwTitleOffset<=s98h.dwDataOffset then
      	i := s98h.dwDataOffset - s98h.dwTitleOffset
      else
      	i := fs.Size - s98h.dwTitleOffset;
    	//
	    s := '';
	    while i>0 do
	    begin
      	//
	    	if fs.Read(FileBuf, 1)<>1 then
        	Break;
	      if FileBuf[0] in [$00..$08, $0b..$0c, $0e..$1f] then
	      	Break;
				s := s + Chr(FileBuf[0]);
        Dec(i);
	  	end;
      //
      if s98h.Magic[3]=Ord('3') then
      begin
      	//
      	if AnsiPos('[S98]', s)=1 then
	  	    s := RightStr(s, Length(s)-Length('[S98]'));
        //
      	if AnsiPos(Chr($ef)+Chr($bb)+Chr($bf), s)=1 then
	  	    s := Utf8ToAnsi(RightStr(s, Length(s)-Length(Chr($ef)+Chr($bb)+Chr($bf))));
			end;
      //
      s := Trim(s);
      if s<>'' then
				Memo.Lines.Text := s;
    end;

    //
    if s98h.dwCompress<>0 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:圧縮されている');
	  	Result := ST_MARK;
    	Exit;
    end;

    //
    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
    speed := DeviceForm.GetBool('S98Speed');
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;
    //
		if speed=False then
	    ratio := 1
    else
    begin
    	ratio := DeviceForm.GetClockRatio;
			DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
    end;

    //
  	if fs.Seek(s98h.dwDataOffset, soFromBeginning)<>Int64(s98h.dwDataOffset) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
	  	Result := ST_ERR;
    	Exit;
    end;
		//
    if s98h.dwTitleOffset<s98h.dwDataOffset then
	    i := BUFSIZE
    else
	    i := s98h.dwTitleOffset - s98h.dwDataOffset;
    //
  	nFileSize := fs.Read(FileBuf, Min(i, BUFSIZE));
    if nFileSize<1 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
	  	Result := ST_ERR;
    	Exit;
    end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
	  fs.Free;
  end;

  //
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	//
	 	OutputThread[i] := nil;
  	ThreadCri[i].bEnable := False;
    ThreadCri[i].bTimeEnb := False;
	  ThreadCri[i].nWritePtr := 0;
  	ThreadCri[i].nLength := 0;
	  InitSetting(i);
  end;

  //
  nStart := timeGetTime;
 	InputThread := TInputThread.Create(FMT_S98, @s98h, @FileBuf, nFileSize,
  	ratio, DeviceForm.GetInteger('S98Loop'));

	//
  n := -1;
 	for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //
    case DeviceForm.CnDevice[i].nIfSelect of
   		IF_INT:
		    begin
        	j := 0;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_EZUSB:
      	begin
        	j := 1+DeviceForm.CnDevice[i].nIfEzusbNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_PIC:
      	begin
        	j := 1+EZUSB_DEVMAX+DeviceForm.CnDevice[i].nIfPicNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_FTDI:
      	begin
        	j := 1+EZUSB_DEVMAX+PIC_DEVMAX+DeviceForm.CnDevice[i].nIfFtdiNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
    end;
  end;
  //
  if n>=0 then
   	ThreadCri[n].bTimeEnb := True;

  //
  ThreadCnt := 1;
	InputThread.Resume;
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	if Assigned(OutputThread[i]) then
    begin
    	Inc(ThreadCnt);
	    OutputThread[i].Resume;
    end;
  end;
  Result := ST_OK;
end;

function TMainForm.PlayKss(path: String; number: Integer): Integer;
	var
  	fs: TFileStream;
		kssh: TKssHeader;
    speed: Boolean;
    ratio: Extended;
  var
    s, ext: String;
    i, j, n: Integer;
begin
  //
  fs := nil;
  try
 	try
  	//
	  fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
  	if fs.Read(kssh, SizeOf(kssh))<>SizeOf(kssh) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:KSSではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    s := '';
    for i := 0 to (SizeOf(kssh.Magic) div SizeOf(kssh.Magic[0])) - 1 do
			s := s + Chr(kssh.Magic[i]);
    if (s<>'KSCC') and (s<>'KSSX') then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:KSSではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
   	if s<>'KSCC' then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
	  	Result := ST_ERR;
    	Exit;
    end;
    s := ''''+ Trim(s) +''' ';

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

	  //再生する曲番
    if number<0 then
    begin
    	//ファイル名に曲番指定がない
	  	number := DeviceForm.GetInteger('KssStart');
    end;
    number := number and $ff;

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;

    //
    Kss.PkssInit(kssh, number, Int64(DeviceForm.GetInteger('KssLimit'))*1000);
    s := s + '#'+ IntToStr(number) +' ';
    s := s + '$'+IntToHex(0, 2) +'(';
    ext := '';
    if Kss.bNtsc=True then
    begin
    	//NTSC
      s := s + 'NTSC,';
    end else
    begin
    	//PAL
      s := s + 'PAL,';
    end;
    s := s + IntToStr(Kss.nTimerInfo1)+'/'+IntToStr(Kss.nTimerInfo2)+')';
    DeviceForm.LogEdit.Lines.Add(s);

    //
    ext := '';
   	if (kssh.bySoundChip and (1 shl 1))<>0 then
    begin
    	//SN76489=1
      if (kssh.bySoundChip and (1 shl 2))=0 then
      begin
	      ext := ext + 'SN76489,';
				DeviceForm.AddReqDevice(IntToStr(DEVKSS1_DCSG), DEVICE_DCSG, 3579545);
      end else
				DeviceForm.AddReqDevice(IntToStr(DEVKSS1_DCSG), DEVICE_DCSG_GG, 3579545);
      if (kssh.bySoundChip and (1 shl 0))<>0 then
      begin
	      ext := ext + 'FMUNIT,';
				DeviceForm.AddReqDevice(IntToStr(DEVKSS1_OPLL), DEVICE_OPLL, 3579545);
      end;
      if (kssh.bySoundChip and (1 shl 2))<>0 then
	      ext := ext + 'GG stereo,';
    end else
    begin
    	//SN76489=0
      ext := ext + 'PSG,';
			DeviceForm.AddReqDevice(IntToStr(DEVKSS0_PSG), DEVICE_PSG, 3579545/2);
      ext := ext + 'SCC/052539,';
			DeviceForm.AddReqDevice(IntToStr(DEVKSS0_SCC), DEVICE_SCC, 3579545);
			DeviceForm.AddReqDevice(IntToStr(DEVKSS0_052539), DEVICE_052539, 3579545);
      if (kssh.bySoundChip and (1 shl 0))<>0 then
      begin
	      ext := ext + 'FMPAC,';
				DeviceForm.AddReqDevice(IntToStr(DEVKSS0_OPLL), DEVICE_OPLL, 3579545);
      end;
      if (kssh.bySoundChip and (1 shl 3))<>0 then
      begin
	      ext := ext + 'MSX-AUDIO,';
				DeviceForm.AddReqDevice(IntToStr(DEVKSS0_MSXAUDIO), DEVICE_MSXAUDIO_RAM, 3579545);
      end;
    end;
		//
    if ext<>'' then
    begin
    	ext := LeftStr(ext, Length(ext)-1);
			s := '$'+IntToHex(kssh.bySoundChip, 2)+'('+ext+')';
    	DeviceForm.LogEdit.Lines.Add(s);
    end;

    //
    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
    speed := DeviceForm.GetBool('KssSpeed');
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;
    //
		if speed=False then
    	ratio := 1
    else
    begin
    	ratio := DeviceForm.GetClockRatio;
			DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
    end;

    //
   	if (kssh.bySoundChip and (1 shl 1))<>0 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
	  	Result := ST_ERR;
    	Exit;
    end;

    //
    if fs.Read(Kss.Memory[kssh.wLoadAddress], kssh.wInitLength)<>kssh.wInitLength then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:再生できないファイル');
	  	Result := ST_ERR;
    	Exit;
		end;
    //
    if Kss.nBankBlocks<>0 then
    begin
	   	i := 16*1024;
  	  if Kss.bBank8K=True then
    		i := 8*1024;
      j := fs.Read(Kss.BankMemory, i*Kss.nBankBlocks);
  	  if j<i then
	    begin
		 		DeviceForm.LogEdit.Lines.Add('エラー:再生できないファイル');
	  		Result := ST_ERR;
  	  	Exit;
	    end;
  	  if j<(i*Kss.nBankBlocks) then
		 		DeviceForm.LogEdit.Lines.Add('エラー:拡張データサイズが設定値未満（'+ IntToStr(j)
        	+'/'+ IntToStr(i*Kss.nBankBlocks) +'）');
    end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
	  fs.Free;
  end;

  //
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	//
	 	OutputThread[i] := nil;
  	ThreadCri[i].bEnable := False;
    ThreadCri[i].bTimeEnb := False;
	  ThreadCri[i].nWritePtr := 0;
  	ThreadCri[i].nLength := 0;
	  InitSetting(i);
  end;

  //
  nStart := timeGetTime;
  Kss.xRatio := ratio;
 	KssThread := TKssThread.Create;

	//
  n := -1;
 	for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //
    case DeviceForm.CnDevice[i].nIfSelect of
   		IF_INT:
		    begin
        	j := 0;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_EZUSB:
      	begin
        	j := 1+DeviceForm.CnDevice[i].nIfEzusbNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_PIC:
      	begin
        	j := 1+EZUSB_DEVMAX+DeviceForm.CnDevice[i].nIfPicNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_FTDI:
      	begin
        	j := 1+EZUSB_DEVMAX+PIC_DEVMAX+DeviceForm.CnDevice[i].nIfFtdiNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
    end;
  end;
  //
  if n>=0 then
   	ThreadCri[n].bTimeEnb := True;

  //
  ThreadCnt := 1;
	KssThread.Resume;
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	if Assigned(OutputThread[i]) then
    begin
    	Inc(ThreadCnt);
	    OutputThread[i].Resume;
    end;
  end;
  Result := ST_OK;
end;

function TMainForm.PlayNsf(path: String; number: Integer): Integer;
	var
    fs: TFileStream;
		nsfh: TNsfHeader;
    speed: Boolean;
    ratio: Extended;
	var
    s, ext: String;
    i, bank, loffs, info, romsize: Integer;
    dwTimerInfo1, dwTimerInfo2: DWORD;
    p: PByte;
begin
	//
  fs := nil;
  try
  try
		//
		fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
  	if fs.Read(nsfh, SizeOf(nsfh))<>SizeOf(nsfh) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:NSFではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    s := '';
    for i := 0 to (SizeOf(nsfh.Magic) div SizeOf(nsfh.Magic[0])) - 1 do
			s := s + Chr(nsfh.Magic[i]);
    if s<>('NESM'+Chr($1a)) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:NSFではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    s := ''''+ Trim(s) +''' ';
    s := s + '$'+IntToHex(nsfh.byVersion, 2) +' ';
    if nsfh.byVersion<>$01 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
	  	Result := ST_ERR;
    	Exit;
    end;

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

	  //再生する曲番
    if number<0 then
    begin
    	//ファイル名に曲番指定がない
	  	number := DeviceForm.GetInteger('NsfStart');
    end;
    number := number and $ff;
	  if number<nsfh.byStartSong then
  		number := nsfh.byStartSong
	  else
  	if number>nsfh.byTotalSongs then
	  	number := nsfh.byTotalSongs;

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;

    //
    s := s + '#'+ IntToStr(number);
    s := s + '('+ IntToStr(nsfh.byStartSong) +'-'+ IntToStr(nsfh.byTotalSongs) +') ';
    s := s + '$'+IntToHex(nsfh.byPalNtsc, 2) +'(';
    ext := '';
    if (nsfh.byPalNtsc and 3)=1 then
    begin
    	//1:PAL
      dwTimerInfo1 := nsfh.wSpeedPal;
      s := s + 'PAL,';
      nsfh.bySoundChip := 0;
	    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_RP2A07, 4433618.75*6);
    end else
    begin
    	//0:NTSC, 2,3:PAL/NTSC
      dwTimerInfo1 := nsfh.wSpeedNtsc;
			nsfh.byPalNtsc := nsfh.byPalNtsc and $fe;
      s := s + 'NTSC,';
      nsfh.bySoundChip := nsfh.bySoundChip and DEVNSF_EXTMASK;
      if nsfh.bySoundChip=0 then
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_RP2A03, 3579545*6)
      else
      begin
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_RP2A03_EXT, 3579545*6);
  	 		if (nsfh.bySoundChip and DEVNSF_VRC6)<>0 then
  		  	ext := ext + ',VRC6';
	   		if (nsfh.bySoundChip and DEVNSF_VRC7)<>0 then
	    		ext := ext + ',VRC7';
  		 	if (nsfh.bySoundChip and DEVNSF_FDS)<>0 then
	  	  	ext := ext + ',FDS';
   			if (nsfh.bySoundChip and DEVNSF_MMC5)<>0 then
  	  		ext := ext + ',MMC5';
		   	if (nsfh.bySoundChip and DEVNSF_N106)<>0 then
  	  		ext := ext + ',N106';
  		 	if (nsfh.bySoundChip and DEVNSF_FME7)<>0 then
	    		ext := ext + ',FME7';
      end;
    end;
    dwTimerInfo2 := 1000000;
    s := s + IntToStr(dwTimerInfo1)+'/'+IntToStr(dwTimerInfo2)+')';
    DeviceForm.LogEdit.Lines.Add(s);

    //
    if ext<>'' then
    begin
    	ext := RightStr(ext, Length(ext)-1);
			s := '$'+IntToHex(nsfh.bySoundChip, 2)+'('+ext+')';
    	DeviceForm.LogEdit.Lines.Add(s);
    end;

    //
    s := '';
    for i := 0 to SizeOf(nsfh.Name)-2 do
    begin
    	if Ord(nsfh.Name[i])=$00 then
       	Break;
			s := s + nsfh.Name[i];
  	end;
    s := Trim(s)+Chr($0d)+Chr($0a);
    //
    for i := 0 to SizeOf(nsfh.Artist)-2 do
    begin
    	if Ord(nsfh.Artist[i])=$00 then
       	Break;
			s := s + nsfh.Artist[i];
  	end;
    s := Trim(s)+Chr($0d)+Chr($0a);
    //
    for i := 0 to SizeOf(nsfh.Copyright)-2 do
    begin
    	if Ord(nsfh.Copyright[i])=$00 then
       	Break;
			s := s + nsfh.Copyright[i];
  	end;
    //
    s := Trim(s);
    if s<>'' then
			Memo.Lines.Text := s;

    //
    if (nsfh.byTotalSongs<1) or (nsfh.byStartSong<1) or (nsfh.byStartSong>nsfh.byTotalSongs) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:再生する曲がない');
	  	Result := ST_ERR;
    	Exit;
    end;
    //
    if nsfh.wLoadAddress<$6000 then
    begin
    	s := LowerCase(IntToHex(nsfh.wLoadAddress, 4));
		 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み開始アドレス（$'+s+'）が正しくない');
	  	Result := ST_ERR;
    	Exit;
    end;
    //
    if nsfh.wInitAddress<$6000 then
    begin
    	s := LowerCase(IntToHex(nsfh.wInitAddress, 4));
		 	DeviceForm.LogEdit.Lines.Add('エラー:初期化アドレス（$'+s+'）が正しくない');
	  	Result := ST_ERR;
    	Exit;
    end;
    //
    if nsfh.wPlayAddress<$6000 then
    begin
    	s := LowerCase(IntToHex(nsfh.wPlayAddress, 4));
		 	DeviceForm.LogEdit.Lines.Add('エラー:再生アドレス（$'+s+'）が正しくない');
	  	Result := ST_ERR;
    	Exit;
    end;

    //
    if ext='' then
	    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice)
    else
	    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice+'('+ext+')');
    speed := DeviceForm.GetBool('NsfSpeed');
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;
    //
    info := DEVICE_NONE;
    romsize := 0;
 	  for i := 0 to CONNECT_DEVMAX-1 do
  	begin
      if DeviceForm.CnDevice[i].bAlloc=False then
		  	Continue;
  	  case DeviceForm.CnDevice[i].nInfo of
				DEVICE_RP2A03, DEVICE_RP2A07:
       		begin
          	info := DeviceForm.CnDevice[i].nInfo;
						romsize := 512*1024 - 10*NSF_BANKSIZE;
    	      Break;
  	      end;
				DEVICE_RP2A03_EXT:
       		begin
          	info := DeviceForm.CnDevice[i].nInfo;
						romsize := 1024*1024;
    	      Break;
  	      end;
	    end;
    end;
    if (info=DEVICE_NONE) or (romsize<1) then
    begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
    end;
    //
		if speed=False then
	    ratio := 1
    else
    begin
    	ratio := DeviceForm.GetClockRatio;
			DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
    end;

	  //再生する曲番
  	nsfh.byStartSong := number;

		//
    bank := $00;
   	for i := 0 to 7 do
   		bank := bank or nsfh.BankSw[i];
    if bank<>$00 then
    begin
    	//バンク使用
      if (nsfh.bySoundChip and DEVNSF_FDS)<>0 then
      begin
	      nsfh.Magic[0] := nsfh.BankSw[6];	//$5ff6
  	    nsfh.Magic[1] := nsfh.BankSw[7];	//$5ff7
      end else
      begin
	      nsfh.Magic[0] := 254;					//$5ff6
  	    nsfh.Magic[1] := 255;					//$5ff7
        if info=DEVICE_RP2A03_EXT then
        	Dec(romsize, NSF_BANKSIZE*2);
      end;
    end else
    begin
    	//バンク未使用
      bank := -((nsfh.wLoadAddress-$6000) shr 12);	//最小は-9=-(($f000-$6000)>>12)
      nsfh.Magic[0] := bank and $ff;	//$5ff6
      if (info=DEVICE_RP2A03_EXT) and (bank<0) then
	      Dec(romsize, NSF_BANKSIZE);
      Inc(bank);
      nsfh.Magic[1] := bank and $ff;	//$5ff7
      if (info=DEVICE_RP2A03_EXT) and (bank<0) then
	      Dec(romsize, NSF_BANKSIZE);
    	for i := 0 to 7 do
      begin
	      Inc(bank);
    		nsfh.BankSw[i] := bank and $ff;	//$5ff8-$5fff
      end;
    end;
    //
	  FillChar(FileBuf, SizeOf(FileBuf), $ff);
   	loffs := nsfh.wLoadAddress and $0fff;
  	nFileSize := fs.Read(FileBuf[loffs], BUFSIZE);
		if nFileSize<1 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:再生できないファイル');
	  	Result := ST_ERR;
    	Exit;
    end;
		//
    Inc(nFileSize, loffs);
    if nFileSize>romsize then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:再生できないファイルサイズ');
	  	Result := ST_ERR;
    	Exit;
    end;

		//ROM書き込み
    nsfh.Magic[2] := $00;
    if (nsfh.bySoundChip and DEVNSF_FDS)<>0 then
			nsfh.Magic[2] := nsfh.Magic[2] or (1 shl 7);
		//拡張音源のマスク
    nsfh.Magic[2] := nsfh.Magic[2] or ((not nsfh.bySoundChip) and DEVNSF_EXTMASK);
		if DeviceForm.GetBool('Rp2a03+ExtMask')=True then
		begin
			if DeviceForm.GetBool('Rp2a03+ExtMaskVrc6')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_VRC6;
			if DeviceForm.GetBool('Rp2a03+ExtMaskVrc7')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_VRC7;
			if DeviceForm.GetBool('Rp2a03+ExtMaskRp2c33')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_FDS;
			if DeviceForm.GetBool('Rp2a03+ExtMaskMmc5')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_MMC5;
			if DeviceForm.GetBool('Rp2a03+ExtMask163')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_N106;
			if DeviceForm.GetBool('Rp2a03+ExtMask5b')=True then
				nsfh.Magic[2] := nsfh.Magic[2] or DEVNSF_FME7;
		end;

    //
    p := @nsfh.Name[0];
    p^ := $00;
    if DeviceForm.GetBool('Rp2a03+ExtRegRead')=True then
    	p^ := p^ or (1 shl 7);
//    if DeviceForm.GetBool('Rp2a03+ExtMmc5Read')=True then
//    	p^ := p^ or (1 shl 6);
    if DeviceForm.GetBool('Rp2a03+Ext163Read')=True then
    	p^ := p^ or (1 shl 5);
    if DeviceForm.GetIndex('Rp2a03+ExtNc', False)<>0 then
    	p^ := p^ or (1 shl 3);
    Inc(p);
    //
    if DeviceForm.GetBool('Rp2a03+ExtRomsel')=True then
    begin
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomselVrc6', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_VRC6 shl 4);
			Inc(p);
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomselVrc7', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_VRC7 shl 4);
			Inc(p);
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomselRp2c33', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_FDS shl 4);
			Inc(p);
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomselMmc5', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_MMC5 shl 4);
			Inc(p);
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomsel163', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_N106 shl 4);
			Inc(p);
			p^ := DeviceForm.GetIndex('Rp2a03+ExtRomsel5b', False) and $0f;
			p^ := p^ or (DEVNSF_BIT_FME7 shl 4);
    end else
    begin
    	i := 3;	//'Default'
			p^ := (DEVNSF_BIT_VRC6 shl 4) or (i and $0f);
			Inc(p);
			p^ := (DEVNSF_BIT_VRC7 shl 4) or (i and $0f);
			Inc(p);
			p^ := (DEVNSF_BIT_FDS shl 4) or (i and $0f);
			Inc(p);
			p^ := (DEVNSF_BIT_MMC5 shl 4) or (i and $0f);
			Inc(p);
			p^ := (DEVNSF_BIT_N106 shl 4) or (i and $0f);
			Inc(p);
			p^ := (DEVNSF_BIT_FME7 shl 4) or (i and $0f);
    end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
	  fs.Free;
  end;

	//
  s := DeviceForm.GetPathString('Rp2a03Ctl');
  if FileExists(s)=False then
  begin
	 	DeviceForm.LogEdit.Lines.Add('エラー:['+s+'] が存在しない');
    Result := ST_ERR;
    Exit;
  end;
  //
  NsfThread := TNsfThread.Create(@nsfh, @FileBuf, nFileSize, dwTimerInfo1, dwTimerInfo2,
  	ratio, Int64(DeviceForm.GetInteger('NsfLimit'))*1000, s);
  ThreadCnt := 1;
	NsfThread.Resume;
  Result := ST_OK;
end;

function TMainForm.PlaySpc(path: String): Integer;
	var
    fs: TFileStream;
		spc: TSpcFile;
    id666text: Boolean;
    id666t: TId666Text;
    id666b: TId666Binary;
    speed: Boolean;
  var
    s, tag_date, tag_fout, tag_fin, tag_emu: String;
    i: Integer;
    tlim: Int64;
begin
	//
  fs := nil;
  try
  try
		//
		fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
  	if fs.Read(spc, SizeOf(spc))<>SizeOf(spc) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:SPCではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    s := '';
    for i := 0 to (SizeOf(spc.Magic) div SizeOf(spc.Magic[0])) - 1 do
			s := s + Chr(spc.Magic[i]);
    if (s<>('SNES-SPC700 Sound File Data v0.10'+Chr($1a)+Chr($1a))) and
    	(s<>('SNES-SPC700 Sound File Data v0.30'+Chr($1a)+Chr($1a))) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:SPCではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
    s := ''''+ Trim(s) +''' ';
    s := s + IntToStr(spc.byVersion) +' ';
    if (spc.byVersion<>10) and (spc.byVersion<>30) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
	  	Result := ST_ERR;
    	Exit;
    end;

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;
    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_SSMP_SDSP, 32000*768);

    //ID666タグ
    tlim := Int64(DeviceForm.GetInteger('SpcLimit'))*1000;
    if spc.byId666Info<>26 then
    begin
    	//なし
	    DeviceForm.LogEdit.Lines.Add(s);
    end else
    begin
    	//あり
      Move(spc.Id666, id666t, SizeOf(id666t));
      Move(spc.Id666, id666b, SizeOf(id666b));

      //
	    tag_date := '';
    	for i := 0 to SizeOf(id666t.Date)-1 do
  	  begin
	    	if Ord(id666t.Date[i])=$00 then
     	 		Break;
				tag_date := tag_date + id666t.Date[i];
  		end;
      tag_date := Trim(tag_date);
      //
      tag_fout := '';
    	for i := 0 to SizeOf(id666t.Fadeout)-1 do
  	  begin
	    	if Ord(id666t.Fadeout[i])=$00 then
     	 		Break;
				tag_fout := tag_fout + id666t.Fadeout[i];
  		end;
      tag_fout := Trim(tag_fout);
      if tag_fout='' then
				tag_fout := '0';
      //
      tag_fin := '';
    	for i := 0 to SizeOf(id666t.Fadein)-1 do
  	  begin
	    	if Ord(id666t.Fadein[i])=$00 then
     	 		Break;
        tag_fin := tag_fin + id666t.Fadein[i];
  		end;
      tag_fin := Trim(tag_fin);
      if tag_fin='' then
				tag_fin := '0';

      //テキスト/バイナリ判定
      id666text := True;
      if (StrToIntDef(tag_fout, -1)<0) or (StrToIntDef(tag_fin, -1)<0) or (StrToIntDef(id666t.cEmulator, -1)<0) then
      	id666text := False;
      //
      tag_emu := '';
      if id666text=True then
      begin
      	//テキスト
	      s := s + 'Text(';
    	  tag_emu := id666t.cEmulator;
      end else
      begin
      	//バイナリ
	      s := s + 'Binary(';
 		  	tag_date := IntToStr((id666b.dwDate shr 8) and $ff);
 		  	tag_date := tag_date + '/' + IntToStr(id666b.dwDate and $ff);
 		  	tag_date := tag_date + '/' + IntToStr((id666b.dwDate shr 16) and $ffff);
        //
        tag_fout := IntToStr((id666b.FadeOut[2] shl 16) + (id666b.FadeOut[1] shl 8) + id666b.FadeOut[0]);
        //
 	      tag_fin := IntToStr(id666b.dwFadeIn);
        //
        tag_emu := IntToStr(id666b.byEmulator);
      end;

      //
      s := s + tag_date +','+ tag_fout +','+ tag_fin +','+ tag_emu + ')';
	    DeviceForm.LogEdit.Lines.Add(s);

      //再生時間
      if StrToInt(tag_fout)>0 then
     	begin
  	    if DeviceForm.GetBool('SpcTime')=True then
 	      	tlim := (DeviceForm.GetInteger('SpcLoop') * StrToInt64(tag_fout))*1000;
      end;

      //
	    s := '';
    	for i := 0 to SizeOf(id666t.SongTitle)-1 do
  	  begin
	    	if Ord(id666t.SongTitle[i])=$00 then
      	 	Break;
				s := s + id666t.SongTitle[i];
  		end;
	    s := Trim(s)+Chr($0d)+Chr($0a);
      //
    	for i := 0 to SizeOf(id666t.GameTitle)-1 do
  	  begin
	    	if Ord(id666t.GameTitle[i])=$00 then
      	 	Break;
				s := s + id666t.GameTitle[i];
  		end;
	    s := Trim(s)+Chr($0d)+Chr($0a);
      //
    	for i := 0 to SizeOf(id666t.Dumper)-1 do
  	  begin
	    	if Ord(id666t.Dumper[i])=$00 then
      	 	Break;
				s := s + id666t.Dumper[i];
  		end;
	    s := Trim(s)+Chr($0d)+Chr($0a);
      //
    	for i := 0 to SizeOf(id666t.Comments)-1 do
  	  begin
	    	if Ord(id666t.Comments[i])=$00 then
      	 	Break;
				s := s + id666t.Comments[i];
  		end;
	    s := Trim(s)+Chr($0d)+Chr($0a);

      //
      if id666text=True then
      begin
      	//テキスト
	    	for i := 0 to SizeOf(id666t.Artist)-1 do
  		  begin
	  	  	if Ord(id666t.Artist[i])=$00 then
      		 	Break;
					s := s + id666t.Artist[i];
  			end;
      end else
      begin
      	//バイナリ
	    	for i := 0 to SizeOf(id666b.Artist)-1 do
  		  begin
	  	  	if Ord(id666b.Artist[i])=$00 then
      		 	Break;
					s := s + id666b.Artist[i];
  			end;
      end;
	    s := Trim(s)+Chr($0d)+Chr($0a);
    	//
    	s := Trim(s);
  	  if s<>'' then
				Memo.Lines.Text := s;
    end;

    //
    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
    speed := False;
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
	  fs.Free;
  end;

	//
  s := DeviceForm.GetPathString('Ssmp+SdspCtl');
  if FileExists(s)=False then
  begin
	 	DeviceForm.LogEdit.Lines.Add('エラー:['+s+'] が存在しない');
    Result := ST_ERR;
    Exit;
  end;
  //
  SpcThread := TSpcThread.Create(@spc, tlim, s, DeviceForm.GetBool('Ssmp+SdspType'),
  	DeviceForm.GetBool('Ssmp+SdspSpdif'));
  ThreadCnt := 1;
	SpcThread.Resume;
  Result := ST_OK;
end;

function TMainForm.PlaySpu(path: String): Integer;
	var
    fs: TFileStream;
		spuh: PSpuHeader;
    spuhsize, datasize: Integer;
    spuold, speed: Boolean;
    ratio: Extended;
  var
    s: String;
    i, j, n: Integer;
begin
	//
  fs := nil;
  try
  try
		//
		fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
    spuh := @FileBuf;
    spuhsize := SizeOf(spuh^);
  	if fs.Read(spuh^, spuhsize)<>spuhsize then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:SPUではない');
	  	Result := ST_MARK;
    	Exit;
		end;
    //
    s := '';
    for i := 0 to 4-1 do
    begin
     	if spuh^.Ram[i]<$20 then
		    s := s + '$'+IntToHex(spuh^.Ram[i], 2)
      else
	    	s := s + Chr(spuh^.Ram[i]);
    end;
    if (s<>'$00$00$00$00') and (s<>'SPU$00') and (s<>'SPU1') then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:SPUではない');
	  	Result := ST_MARK;
    	Exit;
    end;
    //
   	if spuh^.Info[0]<1 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:SPUではない');
	  	Result := ST_MARK;
    	Exit;
    end;

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

    //
   	datasize := spuh^.Info[1]*SizeOf(TSpuDataOld);
		if (spuh^.Info[1]>0) and ((fs.Size-fs.Position)=datasize) then
    begin
    	//旧
	    spuold := True;
  	  s := ''''+ s + ''' Old(1/' + IntToStr(spuh^.Info[0]) + ')';
    end else
    begin
    	//新
	    spuold := False;
	    s := ''''+ s + ''' New(1/' + IntToStr(44100) + ')';
      fs.Seek(-SizeOf(spuh^.Info[1]), soFromCurrent);
    	datasize := fs.Size-fs.Position;
    end;
    DeviceForm.LogEdit.Lines.Add(s);

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;
    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_SPU, 44100*768);

    //
    s := '';
   	for i := 0 to 64-1 do
 	  begin
      if spuh^.Ram[$04+i] in [$00..$08, $0b..$0c, $0e..$1f] then
      	Break;
			s := s + Chr(spuh^.Ram[$04+i]);
 		end;
    s := Trim(s)+Chr($0d)+Chr($0a);
    //
   	for i := 0 to 64-1 do
 	  begin
    	if spuh^.Ram[$44+i] in [$00..$08, $0b..$0c, $0e..$1f] then
     	 	Break;
			s := s + Chr(spuh^.Ram[$44+i]);
 		end;
    s := Trim(s)+Chr($0d)+Chr($0a);
    //
   	for i := 0 to 32-1 do
 	  begin
    	if spuh^.Ram[$84+i] in [$00..$08, $0b..$0c, $0e..$1f] then
     	 	Break;
			s := s + Chr(spuh^.Ram[$84+i]);
 		end;
    s := Trim(s)+Chr($0d)+Chr($0a);
    //
   	for i := 0 to 32-1 do
 	  begin
    	if spuh^.Ram[$a4+i] in [$00..$08, $0b..$0c, $0e..$1f] then
     	 	Break;
			s := s + Chr(spuh^.Ram[$a4+i]);
 		end;
    s := Trim(s)+Chr($0d)+Chr($0a);
   	//
   	s := Trim(s);
 	  if s<>'' then
			Memo.Lines.Text := s;

    //
    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
    speed := DeviceForm.GetBool('SpuSpeed');
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;
    //
		if speed=False then
	    ratio := 1
    else
    begin
    	ratio := DeviceForm.GetClockRatio;
			DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
    end;

    //
    if spuold=False then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
	  	Result := ST_ERR;
    	Exit;
    end;

    //
  	nFileSize := fs.Read(FileBuf[spuhsize], Min(datasize, BUFSIZE-spuhsize));
    if nFileSize<1 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
	  	Result := ST_ERR;
    	Exit;
    end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
	  fs.Free;
  end;

  //
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	//
	 	OutputThread[i] := nil;
  	ThreadCri[i].bEnable := False;
    ThreadCri[i].bTimeEnb := False;
	  ThreadCri[i].nWritePtr := 0;
  	ThreadCri[i].nLength := 0;
	  InitSetting(i);
  end;

  //
  nStart := timeGetTime;
 	InputThread := TInputThread.Create(FMT_SPUOLD, spuh, @FileBuf, nFileSize,
  	ratio, 0);

	//
  n := -1;
 	for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //
    case DeviceForm.CnDevice[i].nIfSelect of
   		IF_INT:
		    begin
        	j := 0;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_EZUSB:
      	begin
        	j := 1+DeviceForm.CnDevice[i].nIfEzusbNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_PIC:
      	begin
        	j := 1+EZUSB_DEVMAX+DeviceForm.CnDevice[i].nIfPicNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_FTDI:
      	begin
        	j := 1+EZUSB_DEVMAX+PIC_DEVMAX+DeviceForm.CnDevice[i].nIfFtdiNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
    end;
  end;
  //
  if n>=0 then
   	ThreadCri[n].bTimeEnb := True;

  //
  ThreadCnt := 1;
	InputThread.Resume;
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	if Assigned(OutputThread[i]) then
    begin
    	Inc(ThreadCnt);
	    OutputThread[i].Resume;
    end;
  end;
  Result := ST_OK;
end;

function TMainForm.PlayVgm(path: String; extvgm: Boolean): Integer;
	var
    fs: TFileStream;
    gz: TgzFile;
		vgmh: TVgmHeader;
		gd3h: TGd3Header;
    speed: Boolean;
    ratio: Extended;
	var
    s: String;
    i, j, n, size: Integer;
    cp: PByte{Pointer};
    offs, clock: DWORD;
    p: PWideChar;
    loffs: Int64;
begin
	//
  fs := nil;
  gz := nil;
  try
  try
		//
    if extvgm=True then
    begin
    	//VGM
			fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
	    size := fs.Read(vgmh, SizeOf(vgmh));
    end else
    begin
    	//VGZ
      if bZlib1=False then
      begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:zlib1.dllが使用できない');
  	    Result := ST_ERR;
	      Exit;
      end else
      begin
			 	gz := gzopen(PChar(path), 'r');
		  	if gz=nil then
        begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:ファイルが開けない');
		      Result := ST_ERR;
		      Exit;
				end;
	    	size := gzread(gz, @vgmh, SizeOf(vgmh));
      end;
    end;
  	if size<$24 then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:VGMではない');
	  	Result := ST_MARK;
    	Exit;
		end;
    //
    s := Chr(vgmh.Magic[0])+Chr(vgmh.Magic[1])+Chr(vgmh.Magic[2])+Chr(vgmh.Magic[3]);
    if s<>'Vgm ' then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:VGMではない');
	  	Result := ST_MARK;
    	Exit;
    end;

    //
    cp := nil;
    case vgmh.dwVersion of
      ($0100):
		  	cp := @vgmh.dwRate;
      $0101:
		  	cp := @vgmh.wSN76489Feedback;
      ($0110):
		  	cp := @vgmh.dwVgmDataOffset;
     	$0150:
		  	cp := @vgmh.dwSegaPcmClock;
     	$0151, $0160:
      	;
      else
		    begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
			  	Result := ST_ERR;
		    	Exit;
        end;
    end;
    //
    if cp<>nil then
    	FillChar(cp^, SizeOf(vgmh) - (DWORD(cp)-DWORD(@vgmh)), $00);

		//
  	MainForm.Caption := FormCaption + ExtractFileName(path);

    //
 		Inc(vgmh.dwEofOffset, $04);
    if vgmh.dwGD3Offset<>0 then
	    Inc(vgmh.dwGD3Offset, $14);
    if vgmh.dwLoopOffset<>0 then
	    Inc(vgmh.dwLoopOffset, $1c);
    case vgmh.dwVersion of
      $0100, $0101, $0110:
       	vgmh.dwVgmDataOffset := $40;
     	$0150, $0151, $0160:
      	begin
        	if vgmh.dwVgmDataOffset<>0 then
	        	Inc(vgmh.dwVgmDataOffset, $34)
          else
          	vgmh.dwVgmDataOffset := $40;
        end;
    end;
    //
    offs := vgmh.dwEofOffset;
    if vgmh.dwGD3Offset<>0 then
    	offs := Min(offs, vgmh.dwGD3Offset);
    if vgmh.dwLoopOffset<>0 then
    	offs := Min(offs, vgmh.dwLoopOffset);
    if vgmh.dwVgmDataOffset<>0 then
	    offs := Min(offs, vgmh.dwVgmDataOffset);
    if offs<SizeOf(vgmh) then
    begin
    	cp := @vgmh;
      Inc(cp, offs);
	  	FillChar(cp^, SizeOf(vgmh) - offs, $00);
    end;

    //
    s := ''''+ s + ''' $'+IntToHex(vgmh.dwVersion, 4) + ' $'+IntToHex(vgmh.dwLoopOffset, 8);
    DeviceForm.LogEdit.Lines.Add(s);

    //再生に必要なデバイス
		DeviceForm.EnumDevice;
    DeviceForm.ClearReqDevice;

		//
    clock := vgmh.dwSN76489Clock and $3fffffff;
    if clock<>0 then
    begin
    	case (vgmh.dwSN76489Clock shr 30) and 3 of
      	0:
			    DeviceForm.AddReqDevice(IntToStr($50)+','+IntToStr($4f), DEVICE_DCSG_GG, clock);
        1:
        	begin
				    DeviceForm.AddReqDevice(IntToStr($50)+','+IntToStr($4f), DEVICE_DCSG_GG, clock);
				    DeviceForm.AddReqDevice(IntToStr($30)+','+IntToStr($3f), DEVICE_DCSG_GG, clock);
          end;
        2:
        	begin
          	//
          end;
        else
        	begin
          	//※$30/$50をひとつのデバイスで処理
				    DeviceForm.AddReqDevice(IntToStr($30)+','+IntToStr($50), DEVICE_DCSG_NGP, clock);
          end;
      end;
    end;

		//
    case vgmh.dwVersion of
      $0100, $0101:
      	begin
        	clock := vgmh.dwYM2413Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($51), DEVICE_OPLL, clock);
				    DeviceForm.AddReqDevice(IntToStr($52)+','+IntToStr($53)+','+IntToStr($80)+','+IntToStr($81)+','+
            	IntToStr($82)+','+IntToStr($83)+','+IntToStr($84)+','+IntToStr($85)+','+IntToStr($86)+','+
              IntToStr($87)+','+IntToStr($88)+','+IntToStr($89)+','+IntToStr($8a)+','+IntToStr($8b)+','+
            	IntToStr($8c)+','+IntToStr($8d)+','+IntToStr($8e)+','+IntToStr($8f), DEVICE_OPN2, clock);
				    DeviceForm.AddReqDevice(IntToStr($54), DEVICE_OPM, clock);
          	if (vgmh.dwYM2413Clock and $40000000)<>0 then
            begin
					    DeviceForm.AddReqDevice(IntToStr($a1), DEVICE_OPLL, clock);
					    DeviceForm.AddReqDevice(IntToStr($a2)+','+IntToStr($a3), DEVICE_OPN2, clock);
					    DeviceForm.AddReqDevice(IntToStr($a4), DEVICE_OPM, clock);
            end;
          end;
        end;
      $0110, $0150, $0151, $0160:
      	begin
        	clock := vgmh.dwYM2413Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($51), DEVICE_OPLL, clock);
          	if (vgmh.dwYM2413Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($a1), DEVICE_OPLL, clock);
          end;
          //
          clock := vgmh.dwYM2612Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($52)+','+IntToStr($53)+','+IntToStr($80)+','+IntToStr($81)+','+
            	IntToStr($82)+','+IntToStr($83)+','+IntToStr($84)+','+IntToStr($85)+','+IntToStr($86)+','+
              IntToStr($87)+','+IntToStr($88)+','+IntToStr($89)+','+IntToStr($8a)+','+IntToStr($8b)+','+
            	IntToStr($8c)+','+IntToStr($8d)+','+IntToStr($8e)+','+IntToStr($8f), DEVICE_OPN2, clock);
          	if (vgmh.dwYM2612Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($a2)+','+IntToStr($a3), DEVICE_OPN2, clock);
          end;
          //
          clock := vgmh.dwYM2151Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($54), DEVICE_OPM, clock);
            if (vgmh.dwYM2151Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($a4), DEVICE_OPM, clock);
          end;
        end;
    end;
    //
    case vgmh.dwVersion of
      $0151, $0160:
      	begin
        	clock := vgmh.dwSegaPcmClock and $3fffffff;
			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($c0), DEVICE_SEGAPCM, clock);
          //
        	clock := vgmh.dwRF5C68Clock and $3fffffff;
			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($b0)+','+IntToStr($c1), DEVICE_RF5C68, clock);
        	//
        	clock := vgmh.dwYM2203Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($55), DEVICE_OPN, clock);
            if (vgmh.dwYM2203Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($a5), DEVICE_OPN, clock);
          end;
          //
          clock := vgmh.dwYM2608Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($56)+','+IntToStr($57), DEVICE_OPNA_RAM, clock);
            if (vgmh.dwYM2608Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($a6)+','+IntToStr($a7), DEVICE_OPNA_RAM, clock);
          end;
          //
          clock := vgmh.dwYM2610Clock and $3fffffff;
          if clock<>0 then
          begin
          	case (vgmh.dwYM2610Clock shr 30) and 3 of
            	0:
						    DeviceForm.AddReqDevice(IntToStr($58)+','+IntToStr($59), DEVICE_OPNB_RAM, clock);
              2:
					    	DeviceForm.AddReqDevice(IntToStr($58)+','+IntToStr($59), DEVICE_YM2610B_RAM, clock);
              1:
              	begin
							    DeviceForm.AddReqDevice(IntToStr($58)+','+IntToStr($59), DEVICE_OPNB_RAM, clock);
							    DeviceForm.AddReqDevice(IntToStr($a8)+','+IntToStr($a9), DEVICE_OPNB_RAM, clock);
                end;
              else
              	begin
					    	DeviceForm.AddReqDevice(IntToStr($58)+','+IntToStr($59), DEVICE_YM2610B_RAM, clock);
					    	DeviceForm.AddReqDevice(IntToStr($a8)+','+IntToStr($a9), DEVICE_YM2610B_RAM, clock);
                end;
            end;
          end;
          //
          clock := vgmh.dwYM3812Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($5a), DEVICE_OPL2, clock);
            if (vgmh.dwYM3812Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($aa), DEVICE_OPL2, clock);
          end;
          //
          clock := vgmh.dwYM3526Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($5b), DEVICE_OPL, clock);
            if (vgmh.dwYM3526Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($ab), DEVICE_OPL, clock);
          end;
          //
          clock := vgmh.dwY8950Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($5c), DEVICE_MSXAUDIO_RAM, clock);
            if (vgmh.dwY8950Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($ac), DEVICE_MSXAUDIO_RAM, clock);
          end;
          //
          clock := vgmh.dwYMF262Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($5e)+','+IntToStr($5f), DEVICE_OPL3, clock);
            if (vgmh.dwYMF262Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($ae)+','+IntToStr($af), DEVICE_OPL3, clock);
          end;
          //
 					clock := vgmh.dwYMF278Clock and $3fffffff;
 			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($d0), DEVICE_OPL4_RAM, clock);
          //
          clock := vgmh.dwYMF271Clock  and $3fffffff;
			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($d1), DEVICE_OPX_RAM, clock);
          //
          clock := vgmh.dwYMZ280Clock and $3fffffff;
			    if clock<>0 then
          begin
				    DeviceForm.AddReqDevice(IntToStr($5d), DEVICE_PCMD8, clock);
            if (vgmh.dwYMZ280Clock and $40000000)<>0 then
					    DeviceForm.AddReqDevice(IntToStr($ad), DEVICE_PCMD8, clock);
          end;
          //
        	clock := vgmh.dwRF5C164Clock and $3fffffff;
			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($b1)+','+IntToStr($c2), DEVICE_RF5C164, clock);
          //
        	clock := vgmh.dwPwmClock and $3fffffff;
			    if clock<>0 then
				    DeviceForm.AddReqDevice(IntToStr($b2), DEVICE_PWM, clock);
          //
          clock := vgmh.dwAY8910Clock and $3fffffff;
			    if clock<>0 then
          begin
          	case vgmh.byAY8910ChipType of
        			$00..$02:	//AY8910, AY8912, AY8913
						    DeviceForm.AddReqDevice(IntToStr($a0), DEVICE_PSG, clock);
        			$03:	//AY8930
						    DeviceForm.AddReqDevice(IntToStr($a0), DEVICE_EPSG, clock);		//※クロック分周設定
        			$10, $11:	//YM2149, YM3439
						    DeviceForm.AddReqDevice(IntToStr($a0), DEVICE_SSG, clock*2);	//※クロック分周設定
        			$12, $13:	//YMZ284, YMZ294
						    DeviceForm.AddReqDevice(IntToStr($a0), DEVICE_SSGL, clock*2);	//※クロック分周設定
            end;
          end;
        end;
    end;

    //
    if extvgm=True then
    begin
    	loffs := fs.Seek(vgmh.dwGD3Offset, soFromBeginning);
	  	size := fs.Read(gd3h, SizeOf(gd3h));
    end else
    begin
    	loffs := gzseek(gz, vgmh.dwGD3Offset, SEEK_SET);
    	size := gzread(gz, @gd3h, SizeOf(gd3h));
    end;
    //
    if (loffs=vgmh.dwGD3Offset) and (size=SizeOf(gd3h)) then
    begin
    	if (gd3h.dwMagic=$20336447) and (gd3h.dwVersion=$0100) then
      begin
    		//
  	    n := Min(gd3h.dwLength, vgmh.dwEofOffset-(vgmh.dwGD3Offset+SizeOf(gd3h)));
	  	  if extvgm=True then
	  			size := fs.Read(FileBuf, n)
  		  else
  		  	size := gzread(gz, @FileBuf, n);
	      //
      	if size=n then
    	  begin
        	//
			    s := '';
          p := @FileBuf[0];
	  	  	for i := 0 to (n div 2)-1 do
  		  	begin
	    			if Ord(p^)=$0000 then
					    s := Trim(s)+Chr($0d)+Chr($0a)
            else
              s := s + WideCharLenToString(p, 1);
            Inc(p);
	  			end;
			    s := Trim(s)+Chr($0d)+Chr($0a);
					//
	  	  	s := Trim(s);
  			  if s<>'' then
						Memo.Lines.Text := s;
        end;
      end;
    end;

    //
    SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
    speed := DeviceForm.GetBool('VgmSpeed');
	  if DeviceForm.AllocDevice(speed)<1 then
	  begin
			DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
	  	Result := ST_ERR;
	  	Exit;
	  end;
    //
		if speed=False then
	    ratio := 1
    else
    begin
    	ratio := DeviceForm.GetClockRatio;
			DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
    end;

    //
   	if vgmh.dwGD3Offset<>0 then
    begin
     	if vgmh.dwGD3Offset>=vgmh.dwVgmDataOffset then
    		vgmh.dwEofOffset := Min(vgmh.dwGD3Offset, vgmh.dwEofOffset);
    end;
    //
    if extvgm=True then
    begin
    	loffs := fs.Seek(vgmh.dwVgmDataOffset, soFromBeginning);
	  	nFileSize := fs.Read(FileBuf, Min(vgmh.dwEofOffset-vgmh.dwVgmDataOffset, BUFSIZE));
    end else
    begin
    	loffs := gzseek(gz, vgmh.dwVgmDataOffset, SEEK_SET);
    	nFileSize := gzread(gz, @FileBuf, Min(vgmh.dwEofOffset-vgmh.dwVgmDataOffset, BUFSIZE));
    end;
		//
  	if (loffs<>vgmh.dwVgmDataOffset) or (nFileSize<1) then
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
	  	Result := ST_ERR;
    	Exit;
    end;

  except
	 	on E:Exception do
    begin
		 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
      Result := ST_ERR;
      Exit;
    end;
  end;
  finally
  	if fs<>nil then
	  	fs.Free;
    if gz<>nil then
   		gzclose(gz);
  end;

  //
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	//
	 	OutputThread[i] := nil;
  	ThreadCri[i].bEnable := False;
    ThreadCri[i].bTimeEnb := False;
	  ThreadCri[i].nWritePtr := 0;
  	ThreadCri[i].nLength := 0;
	  InitSetting(i);
  end;

  //
  nStart := timeGetTime;
 	InputThread := TInputThread.Create(FMT_VGM, @vgmh, @FileBuf, nFileSize,
  	ratio, DeviceForm.GetInteger('VgmLoop'));

	//
  n := -1;
 	for i := 0 to CONNECT_DEVMAX-1 do
  begin
    //
    case DeviceForm.CnDevice[i].nIfSelect of
   		IF_INT:
		    begin
        	j := 0;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_EZUSB:
      	begin
        	j := 1+DeviceForm.CnDevice[i].nIfEzusbNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_PIC:
      	begin
        	j := 1+EZUSB_DEVMAX+DeviceForm.CnDevice[i].nIfPicNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
      IF_FTDI:
      	begin
        	j := 1+EZUSB_DEVMAX+PIC_DEVMAX+DeviceForm.CnDevice[i].nIfFtdiNo;
		      if ThreadCri[j].bEnable=False then
    		  begin
	  				ThreadCri[j].bEnable := True;
            if n<0 then
            	n := j;
				  	OutputThread[j] := TOutputThread.Create(j);
    		  end;
        end;
    end;
  end;
  //
  if n>=0 then
   	ThreadCri[n].bTimeEnb := True;

  //
  ThreadCnt := 1;
	InputThread.Resume;
  for i := 0 to OUTPUT_THREADMAX-1 do
  begin
  	if Assigned(OutputThread[i]) then
    begin
    	Inc(ThreadCnt);
	    OutputThread[i].Resume;
    end;
  end;
  Result := ST_OK;
end;

function TMainForm.PsfStrToMSecs(const S: string): Int64;
	var
  	t: String;
    i, c: Integer;
    v, w: Int64;
begin
	//
	Result := -1;
  with TStringList.Create do
  begin
  	try
      //
	  	CommaText := StringReplace(S, '.', ',', []);
      case Count of
       	1:
         	begin
		       	t := Strings[0];
			      w := 0;
          end;
        2:
         	begin
		       	t := Strings[0];
            w := StrToInt64Def(Strings[1], -1);
          end;
        else
        	Exit;
      end;
      if (t='') or (w<0) then
      	Exit;
			//
	  	CommaText := StringReplace(t, ':', ',', [rfReplaceAll]);
      case Count of
	     	1..3:
       		begin
       	  	v := 0;
            for i := 0 to Count-1 do
            begin
    	       	c := StrToInt64Def(Strings[i], -1);
  	          if c<0 then
              	Exit;
         	  	v := v*60 + c;
          	end;
	         	Result := v*1000 + w*100;
	      	end;
        else
        	Exit;
    	end;
    finally
    	Free;
    end;
  end;
end;

function TMainForm.PlayPsf(path: String): Integer;

	var
    exepsxh: TPsxExeHeader;
    exe68kh: T68kExeHeader;
    exearm7h: TArm7ExeHeader;
    exeagbh: TAgbExeHeader;

	function LoadPsf(depth, lib: Integer; ppsfh: PPsfHeader; pref: PInteger; plen, pfade: PInt64; path: String): Integer;
		var
	    fs: TFileStream;
			psfh: TPsfHeader;
      ppsxh: PPsxExeHeader;
      p68kh: P68kExeHeader;
      parm7h: PArm7ExeHeader;
      pagbh: PAgbExeHeader;
	  var
    	s, t, tag, maker: String;
	    i, n, readlim, readptr, readsz, destptr: Integer;
      len, fade: Int64;
	    destsz, crc: ULONG;
	    loffs: Int64;
	begin
		//
	  fs := nil;
	  try
	  try
			//
      if depth>0 then
      begin
		  	if FileExists(path)=False then
		    begin
				 	DeviceForm.LogEdit.Lines.Add('エラー:ファイルが存在しない');
			  	Result := ST_ERR;
		    	Exit;
				end;
      end;
      //
			fs := TFileStream.Create(path, fmOpenRead or fmShareDenyWrite);
	  	if fs.Read(psfh, SizeOf(psfh))<>SizeOf(psfh) then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:PSFではない');
		  	Result := ST_MARK;
	    	Exit;
			end;
	    //
	    s := Chr(psfh.Magic[0])+Chr(psfh.Magic[1])+Chr(psfh.Magic[2]);
	    if s<>'PSF' then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:PSFではない');
		  	Result := ST_MARK;
	    	Exit;
	    end;
	    //
      if bDebug=True then
 	    begin
	    	s := s + ' $' + IntToHex(psfh.byVersion, 2);
				DeviceForm.LogEdit.Lines.Add('depth='+IntToStr(depth)+', lib='+IntToStr(lib)+
        	', '+s);
      end;
	    //
	    case psfh.byVersion of
//	    	$01:	//Playstation (PSF1)
//		      readlim := SizeOf(TPsxExeHeader)+$1f0000;
	    	$11:	//Saturn (SSF) (format subject to change)
		      readlim := SizeOf(T68kExeHeader)+$080000;
//	    	$12:	//Dreamcast (DSF) (format subject to change)
//		      readlim := SizeOf(TArm7ExeHeader)+$200000;
//	    	$22:	//GameBoy Advance (GSF)
//		      readlim := SizeOf(TAgbExeHeader)+$400000;	//※最大サイズ未確認
	    	$02,	//Playstation 2 (PSF2)
	    	$13,	//Sega Genesis (format to be announced)
	    	$21,	//Nintendo 64 (USF)
	    	$23,	//Super NES (SNSF)
	    	$41:	//Capcom QSound (QSF)
			    begin
					 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
				  	Result := ST_ERR;
			    	Exit;
	        end;
	      else
			    begin
					 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
				  	Result := ST_ERR;
			    	Exit;
	        end;
	    end;

      //
    	if depth=0 then
      	Move(psfh, ppsfh^, SizeOf(ppsfh^))
      else
      if psfh.byVersion<>ppsfh^.byVersion then
      begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:_lib*の形式が一致しない');
		  	Result := ST_ERR;
	    	Exit;
      end;

	    //
	    loffs := SizeOf(psfh) + psfh.dwSizeReserved + psfh.dwProgramLength;
	  	if fs.Seek(loffs, soFromBeginning)<>loffs then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
		  	Result := ST_ERR;
	    	Exit;
	    end;
	    //
      tag := '';
      readptr := $400000;
			n := fs.Read(FileBuf[readptr], BUFSIZE-readptr);
	   	if n>5 then
	 	  begin
	     	//
	  	  s := Chr(FileBuf[readptr+0])+Chr(FileBuf[readptr+1])+Chr(FileBuf[readptr+2])+
        	Chr(FileBuf[readptr+3])+Chr(FileBuf[readptr+4]);
		    if s='[TAG]' then
	      begin
	      	//
          s := '';
	 		  	for i := 5 to n-1 do
		  		begin
	   				if Ord(FileBuf[readptr+i])=$00 then
	        		Break;
		        s := s + Chr(FileBuf[readptr+i]);
					end;
          //
		  	  s := Trim(s);
				  if s<>'' then
          begin
          	tag := s;
				   	if depth=0 then
							Memo.Lines.Text := tag;
            //
			      if bDebug=True then
            begin
	            with TStringList.Create do
  	          begin
    	        	try
      	        	Text := tag;
        	        for i := 0 to Count-1 do
			    	        DeviceForm.LogEdit.Lines.Add(Strings[i]);
            	  finally
              		Free;
  	            end;
	            end;
            end;
          end;
	      end;
	    end;

		 	//
		  with TStringList.Create do
		  begin
		  	try
					//
		     	Text := tag;
		      for i := 1 to Count do
		      begin
		      	if i=1 then
		        	s := '_lib'
		        else
		        	s := '_lib'+IntToStr(i);
		        n := IndexOfName(s);
		        if n<0 then
	          begin
	          	//タグなし
			        if i>1 then
		          	Break;
	          end else
	          begin
	          	//タグあり
	      	   	t := ExtractFilePath(path) + Values[s];
				      if bDebug=True then
			         	DeviceForm.LogEdit.Lines.Add(t);
	            //
					  	if depth<10 then
					    begin
	  	          if lib=1 then
		  	        	n := LoadPsf(depth+1, i, ppsfh, pref, plen, pfade, t)
	      	      else
		      	    	n := LoadPsf(depth+1, lib, ppsfh, pref, plen, pfade, t);
	        		  if n<>ST_OK then
	      	    	begin
	    	       		Result := n;
		  	          Exit;
					      end;
	            end;
	          end;
		      end;
		    finally
			  	Free;
		    end;
		  end;

	    //
	    loffs := SizeOf(psfh) + psfh.dwSizeReserved;
	  	if fs.Seek(loffs, soFromBeginning)<>loffs then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
		  	Result := ST_ERR;
	    	Exit;
	    end;
	    //
      readptr := $400000;
	  	readsz := fs.Read(FileBuf[readptr], Min(psfh.dwProgramLength, BUFSIZE-(readptr+readlim)));
	    if readsz<1 then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
		  	Result := ST_ERR;
	    	Exit;
	    end;
      //
      crc := crc32(0, Z_NULL, 0);
      crc := crc32(crc, @FileBuf[readptr], readsz);
      if crc<>psfh.dwProgramCrc32 then
      begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:CRC32が正しくない');
		  	Result := ST_ERR;
	    	Exit;
      end;

	    //
      destptr := $800000;
      destsz := BUFSIZE-(destptr+readlim);
	    if uncompress(@FileBuf[destptr], @destsz, @FileBuf[readptr], readsz)<>Z_OK then
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:読み込み失敗');
		  	Result := ST_ERR;
	    	Exit;
	    end;

      //
			maker := '';
			case psfh.byVersion of
				$01:	//Playstation (PSF1)
					begin
						//
						s := '';
						ppsxh := PPsxExeHeader(@FileBuf[destptr]);
						for i := 0 to (SizeOf(ppsxh^.Magic) div SizeOf(ppsxh^.Magic[0])) - 1 do
							s := s + Chr(ppsxh^.Magic[i]);
						if s<>'PS-X EXE' then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TPsxExeHeaderが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						//
						for i := 0 to (SizeOf(ppsxh^.Marker) div SizeOf(ppsxh^.Marker[0])) - 1 do
						begin
							if Ord(ppsxh^.Marker[i])=$00 then
								Break;
							maker := maker + Chr(ppsxh^.Marker[i]);
						end;
						//
						if bDebug=True then
						begin
							DeviceForm.LogEdit.Lines.Add('destsz='+IntToHex(destsz, 8));
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.Magic[]='+s);
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwInitialPC='+IntToHex(ppsxh^.dwInitialPC, 8));
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwStartAddress='+IntToHex(ppsxh^.dwStartAddress, 8));
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwSectionSize='+IntToHex(ppsxh^.dwSectionSize, 8));
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwInitialSP='+IntToHex(ppsxh^.dwInitialSP, 8));
							DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.Maker[]='+maker);
						end;

						//
						loffs := ppsxh^.dwStartAddress - $80000000;
						if (loffs<0) or (loffs>=nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TPsxExeHeader.dwStartAddressが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						n := Min(ppsxh^.dwSectionSize, destsz-SizeOf(TPsxExeHeader));
						if (n<0) or (n>nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TPsxExeHeader.dwSectionSizeが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						//
						n := Min(n, nFileSize-loffs);
						if n>0 then
							Move(FileBuf[destptr+SizeOf(TPsxExeHeader)], FileBuf[loffs], n);
						if (depth=0) or (lib=1) then
							Move(FileBuf[destptr], exepsxh, SizeOf(exepsxh));
					end;
				$11:	//Saturn (SSF) (format subject to change)
					begin
          	//
						p68kh := P68kExeHeader(@FileBuf[destptr]);
						if bDebug=True then
						begin
							DeviceForm.LogEdit.Lines.Add('destsz='+IntToHex(destsz, 8));
							DeviceForm.LogEdit.Lines.Add('T68kExeHeader.dwLoadAddress='+IntToHex(p68kh^.dwLoadAddress, 8));
						end;

						//
						loffs := p68kh^.dwLoadAddress;
						if (loffs<0) or (loffs>=nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:T68kExeHeader.dwLoadAddressが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						n := destsz-SizeOf(T68kExeHeader);
						if (n<0) or (n>nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:サイズが大きすぎる');
							Result := ST_ERR;
							Exit;
						end;
						//
						n := Min(n, nFileSize-loffs);
						if n>0 then
							Move(FileBuf[destptr+SizeOf(T68kExeHeader)], FileBuf[loffs], n);
						if (depth=0) or (lib=1) then
							Move(FileBuf[destptr], exe68kh, SizeOf(exe68kh));
					end;
				$12:	//Dreamcast (DSF) (format subject to change)
					begin
          	//
						parm7h := PArm7ExeHeader(@FileBuf[destptr]);
						if bDebug=True then
						begin
							DeviceForm.LogEdit.Lines.Add('destsz='+IntToHex(destsz, 8));
							DeviceForm.LogEdit.Lines.Add('TArm7ExeHeader.dwLoadAddress='+IntToHex(parm7h^.dwLoadAddress, 8));
            end;

						//
						loffs := parm7h^.dwLoadAddress;
						if (loffs<0) or (loffs>=nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TArm7ExeHeader.dwLoadAddressが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						n := destsz-SizeOf(TArm7ExeHeader);
						if (n<0) or (n>nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:サイズが大きすぎる');
							Result := ST_ERR;
							Exit;
						end;
						//
						n := Min(n, nFileSize-loffs);
						if n>0 then
							Move(FileBuf[destptr+SizeOf(TArm7ExeHeader)], FileBuf[loffs], n);
						if (depth=0) or (lib=1) then
							Move(FileBuf[destptr], exearm7h, SizeOf(exearm7h));
					end;
				$22:	//GameBoy Advance (GSF)
					begin
          	//
						pagbh := PAgbExeHeader(@FileBuf[destptr]);
						if bDebug=True then
						begin
							DeviceForm.LogEdit.Lines.Add('destsz='+IntToHex(destsz, 8));
							DeviceForm.LogEdit.Lines.Add('TAgbExeHeader.dwEntryPoint='+IntToHex(pagbh^.dwEntryPoint, 8));
							DeviceForm.LogEdit.Lines.Add('TAgbExeHeader.dwOffset='+IntToHex(pagbh^.dwOffset, 8));
							DeviceForm.LogEdit.Lines.Add('TAgbExeHeader.dwSize='+IntToHex(pagbh^.dwSize, 8));
            end;

						//
						loffs := pagbh^.dwOffset and $01ffffff;
						if (loffs<0) or (loffs>=nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TAgbExeHeader.dwOffsetが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						n := Min(pagbh^.dwSize, destsz-SizeOf(TAgbExeHeader));
						if (n<0) or (n>nFileSize) then
						begin
							DeviceForm.LogEdit.Lines.Add('エラー:TAgbExeHeader.dwSizeが正しくない');
							Result := ST_ERR;
							Exit;
						end;
						//
						n := Min(n, nFileSize-loffs);
						if n>0 then
							Move(FileBuf[destptr+SizeOf(TAgbExeHeader)], FileBuf[loffs], n);
						if (depth=0) or (lib=1) then
							Move(FileBuf[destptr], exeagbh, SizeOf(exeagbh));
					end;
			end;

	  except
		 	on E:Exception do
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:'+E.Message);
	      Result := ST_ERR;
	      Exit;
	    end;
	  end;
	  finally
		  fs.Free;
	  end;

	 	//
	  with TStringList.Create do
	  begin
	  	try
				//
	     	Text := tag;
	     	if depth=0 then
        begin
        	//
				  if AnsiPos('North America', maker)>0 then
				  	pref^ := -60
				  else
				  if AnsiPos('Japan', maker)>0 then
				   	pref^ := -60
			  	else
				  if AnsiPos('Europe', maker)>0 then
				   	pref^ := -50;
          //
          len := PsfStrToMSecs(Values['length']);
          if len>0 then
	         	plen^ := len;
          fade := PsfStrToMSecs(Values['fade']);
          if fade>0 then
	         	pfade^ := fade;
        end;
        //
				n := StrToIntDef(Values['_refresh'], 0);
	      if n>0 then
   	    begin
					if pref^<1 then
	     	  	pref^ := n;
	    	  if bDebug=True then
        	 	DeviceForm.LogEdit.Lines.Add(IntToStr(n));
        end;
	    finally
		  	Free;
	    end;
	  end;

		//
	  Result := ST_OK;
	end;

	var
		psfh: TPsfHeader;
    speed, ext, bit, dif: Boolean;
    ctl: String;
    ratio: Extended;
  var
  	s: String;
    n, ref: Integer;
    len, fade, tlim: Int64;
	var
    fs: TFileStream;

  const
		inst: array[0..5] of Byte = ( $1b, $7c, $00, $02, $04, $00 );
  var
  	i, j, k: Integer;

begin

	//
  if bZlib1=False then
  begin
	 	DeviceForm.LogEdit.Lines.Add('エラー:zlib1.dllが利用できない');
	  Result := ST_ERR;
	  Exit;
  end;

  //
 	FillChar(psfh, SizeOf(psfh), $00);
 	FillChar(exepsxh, SizeOf(exepsxh), $00);
 	FillChar(exe68kh, SizeOf(exe68kh), $00);
 	FillChar(exearm7h, SizeOf(exearm7h), $00);
 	FillChar(exeagbh, SizeOf(exeagbh), $00);
  nFileSize := $400000;
  FillChar(FileBuf, nFileSize, $00);
  ref := 0;
  len := 0;
  fade := 0;
  n := LoadPsf(0, 1, @psfh, @ref, @len, @fade, path);
  if n<>ST_OK then
  begin
  	Result := n;
  	Exit;
  end;
  //
	if ref<0 then
	 	ref := -ref;
	tlim := Int64(DeviceForm.GetInteger('PsfLimit'))*1000;
  if len>0 then
  begin
  	if DeviceForm.GetBool('PsfTime')=True then
	  	tlim := DeviceForm.GetInteger('PsfLoop') * len + fade;
  end;
	//
 	if bDebug=True then
  begin
    //
		case psfh.byVersion of
  	 	$01:	//Playstation (PSF1)
      	begin
	 			  DeviceForm.LogEdit.Lines.Add('SizeOf(TPsxExeHeader)='+IntToHex(SizeOf(TPsxExeHeader), 8));
		    	DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwInitialPC='+IntToHex(exepsxh.dwInitialPC, 8));
	 		  	DeviceForm.LogEdit.Lines.Add('TPsxExeHeader.dwInitialSP='+IntToHex(exepsxh.dwInitialSP, 8));
  			  DeviceForm.LogEdit.Lines.Add('Refresh='+IntToStr(ref));
	  		end;
	   	$11:	//Saturn (SSF) (format subject to change)
      	begin
	 			  DeviceForm.LogEdit.Lines.Add('SizeOf(T68kExeHeader)='+IntToHex(SizeOf(T68kExeHeader), 8));
  			  DeviceForm.LogEdit.Lines.Add('Refresh='+IntToStr(ref));
	  		end;
  	 	$12:	//Dreamcast (DSF) (format subject to change)
      	begin
	 			  DeviceForm.LogEdit.Lines.Add('SizeOf(TArm7ExeHeader)='+IntToHex(SizeOf(TArm7ExeHeader), 8));
  			  DeviceForm.LogEdit.Lines.Add('Refresh='+IntToStr(ref));
	  		end;
   		$22:	//GameBoy Advance (GSF)
      	begin
	 			  DeviceForm.LogEdit.Lines.Add('SizeOf(TAgbExeHeader)='+IntToHex(SizeOf(TAgbExeHeader), 8));
		    	DeviceForm.LogEdit.Lines.Add('TAgbExeHeader.dwEntryPoint='+IntToHex(exeagbh.dwEntryPoint, 8));
  			  DeviceForm.LogEdit.Lines.Add('Refresh='+IntToStr(ref));
	  		end;
    end;
    //
	  DeviceForm.LogEdit.Lines.Add('Length='+IntToStr(tlim));
  end;

  //
  s := Chr(psfh.Magic[0])+Chr(psfh.Magic[1])+Chr(psfh.Magic[2]);
  s := '''' + s + ''' $' + IntToHex(psfh.byVersion, 2);
  if ref>0 then
  	s := s + ' 1/' + IntToStr(ref);
  DeviceForm.LogEdit.Lines.Add(s);

  //再生に必要なデバイス
	DeviceForm.EnumDevice;
  DeviceForm.ClearReqDevice;
  //
  ctl := '';
  ext := False;
  bit := False;
	dif := False;
  case psfh.byVersion of
  	$01:	//Playstation (PSF1)
    	begin
			  nFileSize := $1f0000;
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_SPU, 44100*768);
        ext := DeviceForm.GetBool('SpuExt');
        dif := DeviceForm.GetBool('SpuSpdif');
      end;
   	$11:	//Saturn (SSF) (format subject to change)
	   	begin
      	nFileSize := $080000;
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_SCSP_SCPU, 44100*512);
        ctl := DeviceForm.GetPathString('Scsp+ScpuCtl');
        ext := DeviceForm.GetBool('Scsp+ScpuExt');
        bit := DeviceForm.GetBool('Scsp+Scpu18bit');
        dif := DeviceForm.GetBool('Scsp+ScpuSpdif');
			  if bit=True then
			  begin
			    j := SizeOf(inst) div SizeOf(inst[0]);
          s := '';
			    for i := $0000 to ($7000-j) div 2 do
			    begin
          	k := i*2;
			    	if CompareMem(@FileBuf[k], @inst, j)=True then
			      begin
            	Inc(k, 3);
		        	FileBuf[k] := FileBuf[k] or $01;
             	s := s + '$'+IntToHex(k, 4)+',';
			      end;
			    end;
          if s<>'' then
          	DeviceForm.LogEdit.Lines.Add('patch_dac18b='+LowerCase(LeftStr(s, Length(s)-1)));
			  end;
	    end;
		$12:	//Dreamcast (DSF) (format subject to change)
	  	begin
      	nFileSize := $200000;
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_AICA, 44100*768);
	    end;
		$22:	//GameBoy Advance (GSF)
	  	begin
	      nFileSize := $400000;		//※最大サイズ未確認
		    DeviceForm.AddReqDevice(IntToStr(0), DEVICE_CPU_AGB, 4194304);	//※クロック未確認
	    end;
		$02,	//Playstation 2 (PSF2)
		$13,	//Sega Genesis (format to be announced)
		$21,	//Nintendo 64 (USF)
		$23,	//Super NES (SNSF)
		$41:	//Capcom QSound (QSF)
	  	begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
		  	Result := ST_ERR;
	    	Exit;
	    end;
	  else
	    begin
			 	DeviceForm.LogEdit.Lines.Add('エラー:対応していない形式');
		  	Result := ST_ERR;
	    	Exit;
	    end;
	end;
  //
  if bDebug=True then
  begin
  	fs := nil;
  	try
			fs := TFileStream.Create('.\_psldebug_unit1.bin', fmCreate or fmShareDenyWrite);
      fs.Write(FileBuf, nFileSize)
    finally
    	fs.Free;
    end;
  end;

	//
	MainForm.Caption := FormCaption + ListView.Items[nListIndex].Caption+' '+ExtractFileName(path);

  //
  SetSoundGen(nListIndex, DeviceForm.GetEnumDevice);
  speed := DeviceForm.GetBool('PsfSpeed');
	if DeviceForm.AllocDevice(speed)<1 then
	begin
		DeviceForm.LogEdit.Lines.Add('エラー:再生デバイスなし');
		Result := ST_ERR;
		Exit;
	end;
  //
	if speed=False then
	  ratio := 1
  else
  begin
  	ratio := DeviceForm.GetClockRatio;
		DeviceForm.LogEdit.Lines.Add('x'+FloatToStr(ratio));
  end;

	//
  if (ctl<>'') and (FileExists(ctl)=False) then
  begin
	 	DeviceForm.LogEdit.Lines.Add('エラー:['+ctl+'] が存在しない');
    Result := ST_ERR;
    Exit;
  end;
  //
 	PsfThread := TPsfThread.Create(@psfh, @FileBuf, nFileSize,
  	ratio, tlim, ctl, ext, bit, dif);
  ThreadCnt := 1;
	PsfThread.Resume;
  Result := ST_OK;
end;

end.

