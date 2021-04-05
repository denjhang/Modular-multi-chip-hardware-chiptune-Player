
#include <plib.h>
#include <stdio.h>
#include <string.h>
#include "types.h"
#include "hio.h"
#include "timer2.h"
#include "test.h"

//
#define LENGTH	0x0100	//(1<<n) only
unsigned char g_byBuf[LENGTH];
#define BUF(p)	(*((unsigned char *)(g_byBuf+((p)&(LENGTH-1)))))
//
unsigned char g_byWptr, g_byRptr;
unsigned short g_wLength;

//
unsigned short g_wAddr[4];
unsigned int g_dwSyncTime;
volatile unsigned int g_dwBaseTime;


void WaitUs(unsigned int i)
{
	mT1ClearIntFlag();
	OpenTimer1(T1_ON | T1_PS_1_1 | T1_SOURCE_INT, (i*pb_clk_khz)/1000);
	while(mT1GetIntFlag()==0);
	CloseTimer1();
}

void WaitMs(unsigned int i)
{
	//
	while(i){
		WaitUs(500);
		WaitUs(500-1);
		i--;
	}
}

void BusEnable(unsigned int addr)
{
	unsigned int pbit = 0;
	//
	PMPSetAddress(addr&0xffff);
	switch((addr>>16)&7){
		case 0:
			pbit = BIT_0;
			break;
		case 1:
			pbit = BIT_1;
			break;
		case 2:
			pbit = BIT_2;
			break;
		case 3:
			pbit = BIT_3;
			break;
	}
	if(pbit)
		mPORTDClearBits(pbit);
	else
		mPORTDSetBits(BIT_0 | BIT_1 | BIT_2 | BIT_3);
	mPMPClearIntFlag();
}

void BusEnableCsbit(unsigned int csbit, unsigned int addr)
{
	unsigned int pbit = 0;
	//
	PMPSetAddress(addr&0xffff);
	if(csbit&1)
		pbit |= BIT_0;
	if(csbit&2)
		pbit |= BIT_1;
	if(csbit&4)
		pbit |= BIT_2;
	if(csbit&8)
		pbit |= BIT_3;
	if(pbit)
		mPORTDClearBits(pbit);
	else
		mPORTDSetBits(BIT_0 | BIT_1 | BIT_2 | BIT_3);
	mPMPClearIntFlag();
}

void BusDisable(void)
{
	//
	while(mIsPMPBusy() /*|| mPMPGetIntFlag()==0*/);
	mPORTDSetBits(BIT_0 | BIT_1 | BIT_2 | BIT_3);

	//wait TPB
	switch(OSCCONbits.PBDIV<<_OSCCON_PBDIV_POSITION){
		default:
			__asm__ __volatile__ ("nop");
			__asm__ __volatile__ ("nop");
			__asm__ __volatile__ ("nop");
			__asm__ __volatile__ ("nop");
		case OSC_PB_DIV_4:
			__asm__ __volatile__ ("nop");
			__asm__ __volatile__ ("nop");
		case OSC_PB_DIV_2:
			__asm__ __volatile__ ("nop");
		case OSC_PB_DIV_1:
			__asm__ __volatile__ ("nop");
			break;
	}
}

void WriteByte(unsigned int addr, unsigned char data)
{
	BusEnable(addr);
	PMPMasterWrite(data);
	BusDisable();
}

void WriteByteCsbit(unsigned int csbit, unsigned int addr, unsigned char data)
{
	BusEnableCsbit(csbit, addr);
	PMPMasterWrite(data);
	BusDisable();
}

void WriteWord(unsigned int addr, unsigned short data)
{
	BusEnable(addr);
	PMPMasterWrite(data);
	BusDisable();
}

void WriteWordCsbit(unsigned int csbit, unsigned int addr, unsigned short data)
{
	BusEnableCsbit(csbit, addr);
	PMPMasterWrite(data);
	BusDisable();
}

unsigned char ReadByte(unsigned int addr)
{
	BusEnable(addr);
	mPMPMasterReadByte();
	BusDisable();
	return mPMPMasterReadByte();
}

unsigned short ReadWord(unsigned int addr)
{
	BusEnable(addr);
	mPMPMasterReadWord();
	BusDisable();
	return mPMPMasterReadWord();
}

void WriteIc(int cs, unsigned int base, unsigned char data)
{
	WriteByte((cs<<16)|base, data);
}

void WriteIcCsbit(unsigned int csbit, unsigned int base, unsigned char data)
{
	WriteByteCsbit(csbit, base, data);
}

unsigned char ReadIc(int cs, unsigned int base)
{
	unsigned char data = ReadByte((cs<<16)|base);
	return data;
}


void InitPort(void)
{
	//out/ext_pullup mute=high
	mPORTCSetBits(BIT_2);
	//out/ext_pulldown ic#=low
	mPORTCClearBits(BIT_3);
#if 0
	//通常出力
	mPORTCSetPinsDigitalOut(BIT_2);
	//オープンドレイン出力
	mPORTCOpenDrainOpen(BIT_3);
#else
	//通常出力
	mPORTCSetPinsDigitalOut(BIT_2 | BIT_3);
#endif
	//out/ext_pullup cs0#=high,cs1#=high,cs2#=high,cs3#=high
	mPORTDSetBits(BIT_0 | BIT_1 | BIT_2 | BIT_3);
	mPORTDSetPinsDigitalOut(BIT_0 | BIT_1 | BIT_2 | BIT_3);
	//in/ext_pullup irq#
	mPORTASetPinsDigitalIn(BIT_14);	//INT3/RA14
#if 0
	//
	mJTAGPortEnable(DEBUG_JTAGPORT_OFF);
	mPORTASetBits(BIT_0);
	mPORTASetPinsDigitalOut(BIT_0);
#endif

	//
	unsigned int mode = PMP_IRQ_OFF | PMP_AUTO_ADDR_OFF | PMP_DATA_BUS_16 | PMP_MODE_MASTER2 | PMP_WAIT_BEG_1 | PMP_WAIT_END_1;
	int n = (pb_clk*1.4)/1000000;
	switch(n){
		case 1:	case 2:	case 3:	case 4:	case 5:
		case 6:	case 7:	case 8:	case 9:	case 10:
		case 11:	case 12:	case 13:	case 14:	case 15:
			mode |= n << _PMMODE_WAITM_POSITION;
			break;
		default:
			if(n<1)
				mode |= PMP_WAIT_MID_1;
			else
				mode |= PMP_WAIT_MID_15;
			break;
	}
	mPMPOpen(
		PMP_ON | PMP_IDLE_CON | PMP_MUX_OFF | PMP_TTL | PMP_READ_WRITE_EN | PMP_CS2_CS1_OFF | PMP_WRITE_POL_LO | PMP_READ_POL_LO,
		mode, PMP_PEN_ALL, PMP_INT_OFF
	);
}

void InitBuf(void)
{
	//
	g_byWptr = 0;
	g_byRptr = 0;
	g_wLength = 0;
}

void ResetDevice(void)
{
	int i;

	//
#if 0
	mPORTASetBits(BIT_0);
#endif

	//out/ext_pullup mute=high
	mPORTCSetBits(BIT_2);
	WaitMs(50);
	//out/ext_pulldown ic#=low
	mPORTCClearBits(BIT_3);
	WaitMs(50);

	//out/ext_pulldown ic#=high
	mPORTCSetBits(BIT_3);
	WaitMs(1400);

	//out/ext_pullup mute=low
	mPORTCClearBits(BIT_2);

	//
	for(i=0; i<sizeof(g_wAddr)/sizeof(g_wAddr[0]); i++)
		g_wAddr[i] = 0x00;
}

void SetTimer2(unsigned int v)
{
	//
	CloseTimer2();
	OpenTimer2(T2_ON | T2_PS_1_1 | T2_32BIT_MODE_ON | T2_SOURCE_INT, v);
	ConfigIntTimer3(T3_INT_OFF | T3_INT_PRIOR_2);

	//
	g_dwBaseTime = 0;
	g_dwSyncTime = 0;
}


int ControlCommand(unsigned char *p, int len)
{
	int i;
	static unsigned char inbuf[256];

	//
	for(i=0; i<len; ){
		switch(p[i]){
			case 0x00:
				//reset
				DisableIntT3;
				ResetDevice();
				//timer, 1sync=1/TIMER2_FREQ
				SetTimer2(pb_clk/(1*TIMER2_FREQ));
				i++;
				break;
			case 0x10:
				//start
				EnableIntT3;
				i++;
				break;
			case 0x12:
				//stop
				DisableIntT3;
				i++;
				break;

			case 0xff:
				strcpy(inbuf, "PIC32USB" " Sound Generator Device " REV_STR);
				PcEp2Write(inbuf, 64);
				i++;
				break;

			default:
				//error
				i = len;
				break;
		}
	}

	return len;
}


void ChkStatusReg(int cs, unsigned int base, unsigned char mask, unsigned char eq)
{
	int i;
	unsigned char sts;

	//
	for(i=250; i; i--){
		sts = ReadIc(cs, base);
		if((sts&mask)==eq)
			break;
		WaitUs(11);
	}
}


void CmdRs(unsigned char cmd)
{
	//
	g_byRptr++;
	g_wLength--;
}

void Cmd00(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = (cmd>>1)&3;
	addr = g_wAddr[cs]|((cmd&0x40)?(1<<2):0);
	if(cmd&0x20){
		//20~27,60~67:opn/opnc, opn2*(opn2/opn2c/ymf276), opn3-l/opl3-nl_opn, opna, opnb/ymf286/ym2610b, spu
		//28~2f,68~6f:opm/opp/opz
		ChkStatusReg(cs, addr|((cmd&8)?(1<<0):0), 0x80, 0x00);
	}
	//
	addr |= (cmd&1)?(1<<1):0;
	WriteIc(cs, addr, BUF(g_byRptr+1));
	WaitUs(2);
	//
	WriteIc(cs, addr+1, BUF(g_byRptr+2));
	WaitUs(11);
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd10(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = (cmd>>1)&3;
	switch(cmd&0x28){
		case 0x20:
			//30~37,70~77:opl3-l/opl3-nl_opl(new3=1), opl4/ymf268/opl4-ml_opl(new2=1, opl)
			addr = g_wAddr[cs]|((cmd&0x40)?(1<<2):0);
			ChkStatusReg(cs, addr, 0x01, 0x00);
			break;
		case 0x28:
			//38~3f,78~7f:opl4/ymf268/opl4-ml_opl(new2=1, wavetable)
			addr = g_wAddr[cs];
			ChkStatusReg(cs, addr, 0x03, 0x00);
#if 0
			addr = g_wAddr[cs]|((cmd&0x40)?(1<<2):0);
			break;
#endif
		default:
			addr = g_wAddr[cs]|((cmd&0x40)?(1<<2):0);
			break;
	}
	//
	addr |= (cmd&1)?(1<<1):0;
	WriteIc(cs, addr, BUF(g_byRptr+1));
	WaitUs(11);
	//
	WriteIc(cs, addr+1, BUF(g_byRptr+2));
	WaitUs(24);
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd18(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = (cmd>>1)&3;
	addr = g_wAddr[cs]|((cmd&0x40)?(1<<2):0)|((cmd&1)?(1<<1):0);
	ChkStatusReg(cs, addr&0xfff0, 0x80, 0x00);
	//
	WriteIc(cs, addr, BUF(g_byRptr+1));
	WaitUs(1);
	//
	WriteIc(cs, addr+1, BUF(g_byRptr+2));
	WaitUs(3);
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd80(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = (cmd>>2)&3;
	addr = g_wAddr[cs]|(((cmd&0x10)?(1<<2):0)|(cmd&3));
	//
	WriteIc(cs, addr, BUF(g_byRptr+1));
#if 0
//	Wait(15);	//sn76489n:ng, sn76489an:ok
//	Wait(23);	//sn76489n:ok, sn76489an:ok
	WaitUs(11);	//sn76489n:ok?, sn76489an:ok?
#endif
	//
	g_byRptr += 2;
	g_wLength -= 2;
}

void CmdB0(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = ((cmd<0xd0)?0:2)+((cmd>>2)&1);
	addr = g_wAddr[cs]|(cmd&3);
	//
	ChkStatusReg(cs, addr, 0xff, BUF(g_byRptr+1));
	//
	g_byRptr += 2;
	g_wLength -= 2;
}

void CmdB8(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = cmd&3;
	addr = g_wAddr[cs]|((cmd&4)?(1<<2):0);
	{
		//
		WriteIc(cs, addr+2, 0x08);
		WaitUs(2);
		//
		WriteIc(cs, addr+3, BUF(g_byRptr+1));
		WaitUs(11);
		//
		g_byRptr++;
		WriteIc(cs, addr+2, 0x10);
		WaitUs(2);
		//
		g_wLength--;
		WriteIc(cs, addr+3, 0x80);
		WaitUs(11);
		//
		ChkStatusReg(cs, addr+2, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdD8(unsigned char cmd)
{
	int i, cs;
	unsigned int addr;
	//
	cs = cmd&3;
	addr = g_wAddr[cs]|((cmd&4)?(1<<2):0);
	for(i=16; i; i--){
		//
		WriteIc(cs, addr+2, 0x08);
		WaitUs(2);
		//
		WriteIc(cs, addr+3, BUF(g_byRptr+1));
		WaitUs(11);
		//
		g_byRptr++;
		WriteIc(cs, addr+2, 0x10);
		WaitUs(2);
		//
		g_wLength--;
		WriteIc(cs, addr+3, 0x80);
		WaitUs(11);
		//
		ChkStatusReg(cs, addr+2, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdE0(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = (cmd>>1)&3;
	addr = g_wAddr[cs]|(((cmd&8)?(1<<2):0)|((cmd&1)?(1<<1):0));
	{
		//
		WriteIc(cs, addr, 0x0f);
		WaitUs(11);
		//
		WriteIc(cs, addr+1, BUF(g_byRptr+1));
		WaitUs(24);
		//
		g_byRptr++;
		WriteIc(cs, addr, 0x04);
		WaitUs(11);
		//
		g_wLength--;
		WriteIc(cs, addr+1, 0x80);
		WaitUs(24);
		//
		ChkStatusReg(cs, addr, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdF0(unsigned char cmd)
{
	int cs;
	unsigned int addr;
	//
	cs = cmd&3;
	addr = g_wAddr[cs]|((cmd&4)?(1<<2):0);
	{
		//
		ChkStatusReg(cs, addr, 0x80, 0x00);
		//
		WriteIc(cs, addr, 0x2a);
		WaitUs(2);
		//
		WriteIc(cs, addr+1, BUF(g_byRptr+1));
		WaitUs(11);
	}
	g_byRptr += 2;
	g_wLength -= 2;
}

//
void (*g_fCmd[0x20])(unsigned char cmd) = {
	Cmd00, CmdRs,	//0
	Cmd10, Cmd18,	//1
	Cmd00, Cmd00,	//2
	Cmd10, Cmd10,	//3
	Cmd00, CmdRs,	//4
	Cmd10, Cmd18,	//5
	Cmd00, Cmd00,	//6
	Cmd10, Cmd10,	//7
	Cmd80, Cmd80,	//8
	Cmd80, Cmd80,	//9
	CmdRs, CmdRs,	//a
	CmdB0, CmdB8,	//b
	CmdRs, CmdRs,	//c
	CmdB0, CmdD8,	//d
	CmdE0, CmdE0,	//e
	CmdF0, CmdRs,	//f
};


void RegWrite(unsigned int basetime)
{
	unsigned char cmd, cs;

	//
	while(g_wLength>=3){
		//
		cmd = BUF(g_byRptr);
		switch(cmd){
			case 0xf8:
				//
				if(g_dwSyncTime)
					g_dwSyncTime += 1;
				else
					g_dwSyncTime = basetime+1;
				g_byRptr++;
				g_wLength--;
				return;
			case 0xf9:
				//
				cmd = BUF(g_byRptr+1);
				if(g_dwSyncTime)
					g_dwSyncTime += cmd;
				else
					g_dwSyncTime = basetime+cmd;
				g_byRptr += 2;
				g_wLength -= 2;
				return;

			case 0xfa:
			case 0xfb:
				//
				cs = (cmd&1)?2:0;
				cmd = BUF(g_byRptr+1);
				cs |= (cmd&0x80)?1:0;
				g_wAddr[cs] = (cmd&0x7f)<<3;
				g_byRptr += 2;
				g_wLength -= 2;
				break;

			case 0xfc:
				//
				WaitMs(1);
				g_dwBaseTime = 0;
				g_dwSyncTime = 0;
				g_byRptr += 3;
				g_wLength -= 3;
				return;

			case 0xd8:	case 0xd9:	case 0xda:	case 0xdb:
			case 0xdc:	case 0xdd:	case 0xde:	case 0xdf:
				//
				if(g_wLength<17)
					return;
			default:
				//
				g_fCmd[(cmd>>3)&0x1f](cmd);
				break;
		}
	}
}


int DataCommand(unsigned char *p, int len)
{
	//
	int l = g_wLength+len;
	if(l>LENGTH){
		//buffer full
		len = 0;
	} else {
		//
		int ptr = g_byWptr+len;
		if(ptr>LENGTH){
			//
			memcpy(g_byBuf+g_byWptr, p, LENGTH-g_byWptr);
			memcpy(g_byBuf, p+LENGTH-g_byWptr, ptr-LENGTH);
		} else {
			//
			memcpy(g_byBuf+g_byWptr, p, len);
		}
		//
		g_wLength = l;
		g_byWptr = ptr&(LENGTH-1);
	}

	return len;
}

/*
	Called repeatedly while the device is idle
*/
void TD_Poll(void)
{
	//
	unsigned int basetime = g_dwBaseTime;
	if(basetime>=g_dwSyncTime)
		RegWrite(basetime);
}


void __ISR(_TIMER_3_VECTOR, ipl2) Timer3Handler(void)
{
	//clear the interrupt flag
	mT3ClearIntFlag();
	//
	if(g_dwBaseTime!=0xffffffff)
		g_dwBaseTime++;
}





/*
	pipe0
	  control command

	00 1byte reset
	10 1byte start
	12 1byte stop


	pipe1
	  data command

	cs=0~3
	addr=0~7

	@(0x00,0x10,0x18,0x20,0x28,0x30,0x38)+(addr&(1<<2)?0x40:0)+(cs<<1)+(addr&(1<<1)?1:0)
	38~3f,78~7f:opl4/ymf268/opl4-ml_opl(new2=1, wavetable)
	   30~37,70~77:opl3-l/opl3-nl_opl(new3=1), opl4/ymf268/opl4-ml_opl(new2=1, opl)
	      28~2f,68~6f:opm/opp/opz
	38 30 28 20 18 10 00 3byte cs0(a2=0, a1=0) write, +1=reg +2=data
	39 31 29 21 19 11 01 3byte cs0(a2=0, a1=1) write, +1=reg +2=data
	3a 32 2a 22 1a 12 02 3byte cs1(a2=0, a1=0) write, +1=reg +2=data
	3b 33 2b 23 1b 13 03 3byte cs1(a2=0, a1=1) write, +1=reg +2=data
	3c 34 2c 24 1c 14 04 3byte cs2(a2=0, a1=0) write, +1=reg +2=data
	3d 35 2d 25 1d 15 05 3byte cs2(a2=0, a1=1) write, +1=reg +2=data
	3e 36 2e 26 1e 16 06 3byte cs3(a2=0, a1=0) write, +1=reg +2=data
	3f 37 2f 27 1f 17 07 3byte cs3(a2=0, a1=1) write, +1=reg +2=data
	78 70 68 60 58 50 40 3byte cs0(a2=1, a1=0) write, +1=reg +2=data
	79 71 69 61 59 51 41 3byte cs0(a2=1, a1=1) write, +1=reg +2=data
	7a 72 6a 62 5a 52 42 3byte cs1(a2=1, a1=0) write, +1=reg +2=data
	7b 73 6b 63 5b 53 43 3byte cs1(a2=1, a1=1) write, +1=reg +2=data
	7c 74 6c 64 5c 54 44 3byte cs2(a2=1, a1=0) write, +1=reg +2=data
	7d 75 6d 65 5d 55 45 3byte cs2(a2=1, a1=1) write, +1=reg +2=data
	7e 76 6e 66 5e 56 46 3byte cs3(a2=1, a1=0) write, +1=reg +2=data
	7f 77 6f 67 5f 57 47 3byte cs3(a2=1, a1=1) write, +1=reg +2=data
	                  00~07,40~47:psg/epsg, ssg*(ssg/ssgc/ssgl/ssglp, opn/opnc/opn3-l/opl3-nl_opn, opna, opnb/ymf286/ym2610b), scc/052539, spu
	               10~17,50~57:opll/opllp/vrc7, opl/msx-audio/opl2, opl3, opl3-l/opl3-nl_opl(new3=0), opl4/ymf268/opl4-ml_opl(new2=0, opl), pcmd8
	            18~1f,58~5f:opx
	         20~27,60~67:opn/opnc, opn2*(opn2/opn2c/ymf276), opn3-l/opl3-nl_opn, opna, opnb/ymf286/ym2610b, spu
	08~0f reserve
	48~4f reserve

	@0x80+(addr&(1<<2)?0x10:0)+(cs<<2)+(addr&3)
	80~9f:pit/ptc, dcsg, saa1099, opl4-ml_mpu, scc/052539, ga20, s-smp+s-dsp
	80 2byte cs0(a2=0, a1-0=0) write, +1=data
	81 2byte cs0(a2=0, a1-0=1) write, +1=data
	82 2byte cs0(a2=0, a1-0=2) write, +1=data
	83 2byte cs0(a2=0, a1-0=3) write, +1=data
	84 2byte cs1(a2=0, a1-0=0) write, +1=data
	85 2byte cs1(a2=0, a1-0=1) write, +1=data
	86 2byte cs1(a2=0, a1-0=2) write, +1=data
	87 2byte cs1(a2=0, a1-0=3) write, +1=data
	88 2byte cs2(a2=0, a1-0=0) write, +1=data
	89 2byte cs2(a2=0, a1-0=1) write, +1=data
	8a 2byte cs2(a2=0, a1-0=2) write, +1=data
	8b 2byte cs2(a2=0, a1-0=3) write, +1=data
	8c 2byte cs3(a2=0, a1-0=0) write, +1=data
	8d 2byte cs3(a2=0, a1-0=1) write, +1=data
	8e 2byte cs3(a2=0, a1-0=2) write, +1=data
	8f 2byte cs3(a2=0, a1-0=3) write, +1=data
	90 2byte cs0(a2=1, a1-0=0) write, +1=data
	91 2byte cs0(a2=1, a1-0=1) write, +1=data
	92 2byte cs0(a2=1, a1-0=2) write, +1=data
	93 2byte cs0(a2=1, a1-0=3) write, +1=data
	94 2byte cs1(a2=1, a1-0=0) write, +1=data
	95 2byte cs1(a2=1, a1-0=1) write, +1=data
	96 2byte cs1(a2=1, a1-0=2) write, +1=data
	97 2byte cs1(a2=1, a1-0=3) write, +1=data
	98 2byte cs2(a2=1, a1-0=0) write, +1=data
	99 2byte cs2(a2=1, a1-0=1) write, +1=data
	9a 2byte cs2(a2=1, a1-0=2) write, +1=data
	9b 2byte cs2(a2=1, a1-0=3) write, +1=data
	9c 2byte cs3(a2=1, a1-0=0) write, +1=data
	9d 2byte cs3(a2=1, a1-0=1) write, +1=data
	9e 2byte cs3(a2=1, a1-0=2) write, +1=data
	9f 2byte cs3(a2=1, a1-0=3) write, +1=data

	a0~af reserve

	@((cs&2)?0xd0:0xb0)+((cs&1)?4:0)+(addr&3)
	b0~b7,d0~d7:opl4-ml_mpu, s-smp+s-dsp
	b0 2byte cs0(a2=0, a1-0=0) read/compare, +1=data
	b1 2byte cs0(a2=0, a1-0=1) read/compare, +1=data
	b2 2byte cs0(a2=0, a1-0=2) read/compare, +1=data
	b3 2byte cs0(a2=0, a1-0=3) read/compare, +1=data
	b4 2byte cs1(a2=0, a1-0=0) read/compare, +1=data
	b5 2byte cs1(a2=0, a1-0=1) read/compare, +1=data
	b6 2byte cs1(a2=0, a1-0=2) read/compare, +1=data
	b7 2byte cs1(a2=0, a1-0=3) read/compare, +1=data
	d0 2byte cs2(a2=0, a1-0=0) read/compare, +1=data
	d1 2byte cs2(a2=0, a1-0=1) read/compare, +1=data
	d2 2byte cs2(a2=0, a1-0=2) read/compare, +1=data
	d3 2byte cs2(a2=0, a1-0=3) read/compare, +1=data
	d4 2byte cs3(a2=0, a1-0=0) read/compare, +1=data
	d5 2byte cs3(a2=0, a1-0=1) read/compare, +1=data
	d6 2byte cs3(a2=0, a1-0=2) read/compare, +1=data
	d7 2byte cs3(a2=0, a1-0=3) read/compare, +1=data

	@0xb8+(addr&(1<<2)?4:0)+cs
	b8~bf:opna, opnb/ymf286/ym2610b, opl4/ymf268, opx, ga20, pcmd8, rp2a03/rp2a07, scsp+scpu
	b8 2byte cs0(a2=0, a1=1), adpcm(reg=0x08) write, +1=data
	b9 2byte cs1(a2=0, a1=1), adpcm(reg=0x08) write, +1=data
	ba 2byte cs2(a2=0, a1=1), adpcm(reg=0x08) write, +1=data
	bb 2byte cs3(a2=0, a1=1), adpcm(reg=0x08) write, +1=data
	bc 2byte cs0(a2=1, a1=1), adpcm(reg=0x08) write, +1=data
	bd 2byte cs1(a2=1, a1=1), adpcm(reg=0x08) write, +1=data
	be 2byte cs2(a2=1, a1=1), adpcm(reg=0x08) write, +1=data
	bf 2byte cs3(a2=1, a1=1), adpcm(reg=0x08) write, +1=data

	c0~cf reserve

	@0xd8+(addr&(1<<2)?4:0)+cs
	d8~df:opna, opnb/ymf286/ym2610b, opl4/ymf268, opx, ga20, pcmd8, rp2a03/rp2a07, scsp+scpu
	d8 17byte cs0(a2=0, a1=1), adpcm(reg=0x08) write, +1~+16=data
	d9 17byte cs1(a2=0, a1=1), adpcm(reg=0x08) write, +1~+16=data
	da 17byte cs2(a2=0, a1=1), adpcm(reg=0x08) write, +1~+16=data
	db 17byte cs3(a2=0, a1=1), adpcm(reg=0x08) write, +1~+16=data
	dc 17byte cs0(a2=1, a1=1), adpcm(reg=0x08) write, +1~+16=data
	dd 17byte cs1(a2=1, a1=1), adpcm(reg=0x08) write, +1~+16=data
	de 17byte cs2(a2=1, a1=1), adpcm(reg=0x08) write, +1~+16=data
	df 17byte cs3(a2=1, a1=1), adpcm(reg=0x08) write, +1~+16=data

	@0xe0+(addr&(1<<2)?8:0)+(cs<<1)+(addr&(1<<1)?1:0)
	e0~ef:msx-audio
	e0 2byte cs0(a2=0, a1=0), adpcm(reg=0x0f) write, +1=data
	e1 2byte cs0(a2=0, a1=1), adpcm(reg=0x0f) write, +1=data
	e2 2byte cs1(a2=0, a1=0), adpcm(reg=0x0f) write, +1=data
	e3 2byte cs1(a2=0, a1=1), adpcm(reg=0x0f) write, +1=data
	e4 2byte cs2(a2=0, a1=0), adpcm(reg=0x0f) write, +1=data
	e5 2byte cs2(a2=0, a1=1), adpcm(reg=0x0f) write, +1=data
	e6 2byte cs3(a2=0, a1=0), adpcm(reg=0x0f) write, +1=data
	e7 2byte cs3(a2=0, a1=1), adpcm(reg=0x0f) write, +1=data
	e8 2byte cs0(a2=1, a1=0), adpcm(reg=0x0f) write, +1=data
	e9 2byte cs0(a2=1, a1=1), adpcm(reg=0x0f) write, +1=data
	ea 2byte cs1(a2=1, a1=0), adpcm(reg=0x0f) write, +1=data
	eb 2byte cs1(a2=1, a1=1), adpcm(reg=0x0f) write, +1=data
	ec 2byte cs2(a2=1, a1=0), adpcm(reg=0x0f) write, +1=data
	ed 2byte cs2(a2=1, a1=1), adpcm(reg=0x0f) write, +1=data
	ee 2byte cs3(a2=1, a1=0), adpcm(reg=0x0f) write, +1=data
	ef 2byte cs3(a2=1, a1=1), adpcm(reg=0x0f) write, +1=data

	@0xf0+(addr&(1<<2)?4:0)+cs
	f0~f7:opn2*(opn2/opn2c/ymf276)
	f0 2byte cs0(a2=0, a1=0), pcm(reg=0x2a) write, +1=data
	f1 2byte cs1(a2=0, a1=0), pcm(reg=0x2a) write, +1=data
	f2 2byte cs2(a2=0, a1=0), pcm(reg=0x2a) write, +1=data
	f3 2byte cs3(a2=0, a1=0), pcm(reg=0x2a) write, +1=data
	f4 2byte cs0(a2=1, a1=0), pcm(reg=0x2a) write, +1=data
	f5 2byte cs1(a2=1, a1=0), pcm(reg=0x2a) write, +1=data
	f6 2byte cs2(a2=1, a1=0), pcm(reg=0x2a) write, +1=data
	f7 2byte cs3(a2=1, a1=0), pcm(reg=0x2a) write, +1=data

	f8 1byte sync_1
	f9 2byte sync_8bit 8bit(1~255), +1=b7~0

	@0xfa+((cs&2)?1:0)
	fa~fb
	fa 2byte cs0~1 high address, +1=(d7:cs&1,d6~0:a9~3)
	fb 2byte cs2~3 high address, +1=(d7:cs&1,d6~0:a9~3)

	fc 3byte wait_1ms, +1=dummy +2=dummy
	fd~ff reserve
*/





void Test(struct PcSync *sync)
{
#if __DEBUG
	switch(0x00){
		//
		case 0x01:	PortTest();				break;
		case 0x11:	Ga20Test(sync->arg1);		break;
		case 0x12:	SccTest();				break;
		case 0x13:	OpxPcmd8Mem();			break;
		case 0x14:	Rp2a03Test();				break;
		//opll
		case 0x21:	OpllTest();				break;
		case 0x22:	OpllTest2();				break;
		case 0x23:	OpllInst();				break;
		case 0x24:	OpllRhythm();				break;
		//opl
		case 0x31:	OplInst();				break;
		case 0x32:	OplTest();				break;
		case 0x33:	MsxaudioMem();			break;
		case 0x34:	MsxaudioAdpcm();			break;
		case 0x35:
			Opl4RomRead(".\\_opl4_wavetable_rom.rom", 0);
			Opl4RomRead(".\\_opl4_wavetable_sramrom.rom", 1);
			break;
		case 0x36:	Opl4mlPowerdown();			break;
		//opn
		case 0x41:	Opn3lSsg();				break;
		case 0x42:	OpnbTest();				break;
		case 0x43:	OpnaAdpcm();				break;
		case 0x44:	OpnaPcm();				break;
		//scsp
		case 0x51:	ScspTest();				break;
		case 0x52:	ScspTestFm();				break;
		case 0x53:	ScspTestRs(sync->arg1);		break;
		//spu
		case 0x61:	SpuTest(sync->arg1);		break;
		default:
			break;
	}
#endif
}
