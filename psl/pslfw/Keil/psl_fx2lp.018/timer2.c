
#include "fx2.h"
#include "fx2regs.h"
#include "fx2sdly.h"            // SYNCDELAY macro

//PA
#define OUTA		IOA
#define DEVnIC		(1<<5)
#define DEVA2		(1<<4)
//PB
#define OUTB		IOB
#define PINSB		OUTB
#define DBUSIN		0x00
#define DBUSOUT	0xff
//PD
#define OUTC		IOD
#define DEVnCS3	(1<<7)
#define DEVnCS2	(1<<6)
#define DEVnCS1	(1<<5)
#define DEVnCS0	(1<<4)
#define DEV_nCS	(DEVnCS3|DEVnCS2|DEVnCS1|DEVnCS0)
#define DEVnRD		(1<<3)
#define DEVnWR		(1<<2)
#define DEV_RD		DEVnWR
#define DEV_WR		DEVnRD
#define DEVA1		(1<<1)
#define DEVA0		(1<<0)

//
#define LENGTH		0x0100	//(1<<n) only
xdata BYTE g_byBuf[LENGTH];
#define BUF(p)		(*((BYTE xdata *)(g_byBuf+((p)&(LENGTH-1)))))
//
BYTE g_byWptr, g_byRptr;
WORD g_wLength;

//
#if 0
WORD g_wAddr[4];
#endif
DWORD g_dwSyncTime;
volatile DWORD g_dwBaseTime;


void WaitUs(BYTE i)
{
	//
	TL0 = (1<<8)-4*i;	//(48M/12)=4

	//overflow flag clear
	TF0 = 0;
	//start
	TR0 = 1;
	while(TF0==0){
	}
	//stop
	TR0 = 0;
}

void WaitMs(WORD i)
{
	//
	i *= 1000/100;
	while(i){
		WaitUs(50);
		WaitUs(50-1);
		i--;
	}
}


void InitPort(void)
{
	//PA
	PORTACFG = 0x00;
	OUTA = DEVnIC;
	OEA = DEVnIC|DEVA2;

	//PD
//	PORTDCFG = 0x00;
	OUTC = DEV_nCS|DEV_WR;
	OED = 0xff;

	//PB
//	PORTBCFG = 0x00;
	OUTB = 0x00;
	OEB = DBUSOUT;

	//stop
	TR0 = 0;
	//8-bit counter with auto-reload
	TMOD = (TMOD&0xfc)|2;

	//T0M=0, 48M/12
	CKCON &= ~(1<<3);
	//clock select
	TMOD &= ~(1<<2);
	//GATE0=0
	TMOD &= ~(1<<3);

	//reload value
	TH0 = 0x00;
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
	BYTE i;

	//
	OUTA = 0x00;
	WaitMs(50);
	OUTA = DEVnIC;
	WaitMs(150);

	//
#if 0
	for(i=0; i<sizeof(g_wAddr)/sizeof(g_wAddr[0]); i++)
		g_wAddr[i] = 0x00;
#endif
}

void SetTimer2(BYTE h, BYTE l)
{
	//16-bit timer/counter with auto-reload
	TCLK = 0;
	RCLK = 0;
	CP_RL2 = 0;

	//T2M=1, 48M/4
	CKCON |= (1<<5);
	//clock select
	C_T2 = 0;

	//
	RCAP2L = l;
	RCAP2H = h;
	TL2 = l;
	TH2 = h;

	//overflow flag clear
	TF2 = 0;
	//interrupt high priority
	PT2 = 1;
	//interrupt enable
	ET2 = 1;

	//
	g_dwBaseTime = 0;
	g_dwSyncTime = 0;
}


void ControlCommand(void)
{
	BYTE i, len;

	//
	len = EP2BCL;
	for(i=0; i<len; ){
		switch(EP2FIFOBUF[i]){
			case 0x00:
				//reset
				EA = 0;
				TR2 = 0;
				ResetDevice();
				//timer, 1sync=1/200Hz, 0x10000-((48M/4)/200Hz)=0x15a0
				SetTimer2(0x15, 0xa0);
				EA = 1;
				i++;
				break;
			case 0x10:
				//start
				EA = 0;
				TR2 = 1;
				EA = 1;
				i++;
				break;
			case 0x12:
				//stop
				EA = 0;
				TR2 = 0;
				EA = 1;
				i++;
				break;

			default:
				//error
				i = len;
				break;
		}
	}
	//
	EP2BCL = 0x80;
}


void ChkStatusReg(BYTE cs, BYTE addr, BYTE mask, BYTE eq)
{
	BYTE i, sts;

	//
	OEB = DBUSIN;
	for(i=250; i; i--){
		OUTC = DEV_nCS|addr;
		OUTC = cs     |addr;
		WaitUs(1);
		sts = PINSB;
		OUTC = DEV_nCS|addr;
		if((sts&mask)==eq)
			break;
		WaitUs(11);
	}
	OUTC = DEV_nCS|DEV_WR;
	OEB = DBUSOUT;
}


void CmdRs(BYTE cmd)
{
	//
	g_byRptr++;
	g_wLength--;
}

void Cmd00(BYTE cmd)
{
	BYTE cs, addr;
	//
	cs = DEV_nCS^(DEVnCS0<<((cmd>>1)&3));
	OUTA = (cmd&0x40)?(DEVnIC|DEVA2):DEVnIC;
	if(cmd&0x20){
		//20~27,60~67:opn/opnc, opn2*(opn2/opn2c/ymf276), opn3-l/opl3-nl_opn, opna, opnb/ymf286/ym2610b, spu
		//28~2f,68~6f:opm/opp/opz
		ChkStatusReg(cs, (cmd&8)?(DEV_RD|DEVA0):DEV_RD, 0x80, 0x00);
	}
	//
	addr = (cmd&1)?(DEV_WR|DEVA1):DEV_WR;
	OUTB = BUF(g_byRptr+1);
	OUTC = DEV_nCS|addr;
	OUTC = cs     |addr;
	WaitUs(1);
	OUTC = DEV_nCS|addr;
	WaitUs(2);
	//
	OUTB = BUF(g_byRptr+2);
	OUTC = DEV_nCS|addr|DEVA0;
	OUTC = cs     |addr|DEVA0;
	WaitUs(1);
	OUTC = DEV_nCS|addr|DEVA0;
	WaitUs(11);
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd10(BYTE cmd)
{
	BYTE cs, addr;
	//
	cs = DEV_nCS^(DEVnCS0<<((cmd>>1)&3));
	switch(cmd&0x28){
		case 0x20:
			//30~37,70~77:opl3-l/opl3-nl_opl(new3=1), opl4/ymf268/opl4-ml_opl(new2=1, opl)
			OUTA = (cmd&0x40)?(DEVnIC|DEVA2):DEVnIC;
			ChkStatusReg(cs, DEV_RD, 0x01, 0x00);
			break;
		case 0x28:
			//38~3f,78~7f:opl4/ymf268/opl4-ml_opl(new2=1, wavetable)
			OUTA = DEVnIC;
			ChkStatusReg(cs, DEV_RD, 0x01, 0x00);
#if 0
			OUTA = (cmd&0x40)?(DEVnIC|DEVA2):DEVnIC;
			break;
#endif
		default:
			OUTA = (cmd&0x40)?(DEVnIC|DEVA2):DEVnIC;
			break;
	}
	//
	addr = (cmd&1)?(DEV_WR|DEVA1):DEV_WR;
	OUTB = BUF(g_byRptr+1);
	OUTC = DEV_nCS|addr;
	OUTC = cs     |addr;
	WaitUs(1);
	OUTC = DEV_nCS|addr;
	WaitUs(11);
	//
	OUTB = BUF(g_byRptr+2);
	OUTC = DEV_nCS|addr|DEVA0;
	OUTC = cs     |addr|DEVA0;
	WaitUs(1);
	OUTC = DEV_nCS|addr|DEVA0;
	WaitUs(24);
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd18(unsigned char cmd)
{
	//
	g_byRptr += 3;
	g_wLength -= 3;
}

void Cmd80(BYTE cmd)
{
	BYTE cs, addr;
	//
	cs = DEV_nCS^(DEVnCS0<<((cmd>>2)&3));
	OUTA = (cmd&0x10)?(DEVnIC|DEVA2):DEVnIC;
	addr = DEV_WR|(cmd&3);
	//
	OUTB = BUF(g_byRptr+1);
	OUTC = DEV_nCS|DEV_RD|addr;
	OUTC = cs            |addr;
#if 1
//	Wait(15);	//sn76489n:ng, sn76489an:ok
//	Wait(23);	//sn76489n:ok, sn76489an:ok
	WaitUs(11);	//sn76489n:ok?, sn76489an:ok?
#endif
	OUTC = DEV_nCS|DEV_RD|addr;
	//
	g_byRptr += 2;
	g_wLength -= 2;
}

void CmdB0(BYTE cmd)
{
	BYTE cs, addr;
	//
	cs = DEV_nCS^(DEVnCS0<<(((cmd<0xd0)?0:2)+((cmd>>2)&1)));
	OUTA = DEVnIC;
	addr = DEV_RD|(cmd&3);
	//
	ChkStatusReg(cs, addr, 0xff, BUF(g_byRptr+1));
	//
	g_byRptr += 2;
	g_wLength -= 2;
}

void CmdB8(BYTE cmd)
{
	BYTE cs;
	//
	cs = DEV_nCS^(DEVnCS0<<(cmd&3));
	OUTA = (cmd&4)?(DEVnIC|DEVA2):DEVnIC;
	{
		//
		OUTB = 0x08;
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		OUTC = cs     |DEV_WR|DEVA1;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		WaitUs(2);
		//
		OUTB = BUF(g_byRptr+1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		OUTC = cs     |DEV_WR|DEVA1|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		WaitUs(11);
		//
		g_byRptr++;
		OUTB = 0x10;
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		OUTC = cs     |DEV_WR|DEVA1;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		WaitUs(2);
		//
		g_wLength--;
		OUTB = 0x80;
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		OUTC = cs     |DEV_WR|DEVA1|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		WaitUs(11);
		//
		ChkStatusReg(cs, DEV_RD|DEVA1, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdD8(BYTE cmd)
{
	BYTE i, cs;
	//
	cs = DEV_nCS^(DEVnCS0<<(cmd&3));
	OUTA = (cmd&4)?(DEVnIC|DEVA2):DEVnIC;
	for(i=16; i; i--){
		//
		OUTB = 0x08;
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		OUTC = cs     |DEV_WR|DEVA1;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		WaitUs(2);
		//
		OUTB = BUF(g_byRptr+1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		OUTC = cs     |DEV_WR|DEVA1|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		WaitUs(11);
		//
		g_byRptr++;
		OUTB = 0x10;
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		OUTC = cs     |DEV_WR|DEVA1;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1;
		WaitUs(2);
		//
		g_wLength--;
		OUTB = 0x80;
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		OUTC = cs     |DEV_WR|DEVA1|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA1|DEVA0;
		WaitUs(11);
		//
		ChkStatusReg(cs, DEV_RD|DEVA1, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdE0(BYTE cmd)
{
	BYTE cs, addr;
	//
	cs = DEV_nCS^(DEVnCS0<<((cmd>>1)&3));
	OUTA = (cmd&8)?(DEVnIC|DEVA2):DEVnIC;
	addr = (cmd&1)?(DEV_WR|DEVA1):DEV_WR;
	{
		//
		OUTB = 0x0f;
		OUTC = DEV_nCS|addr;
		OUTC = cs     |addr;
		WaitUs(1);
		OUTC = DEV_nCS|addr;
		WaitUs(11);
		//
		OUTB = BUF(g_byRptr+1);
		OUTC = DEV_nCS|addr|DEVA0;
		OUTC = cs     |addr|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|addr|DEVA0;
		WaitUs(24);
		//
		g_byRptr++;
		OUTB = 0x04;
		OUTC = DEV_nCS|addr;
		OUTC = cs     |addr;
		WaitUs(1);
		OUTC = DEV_nCS|addr;
		WaitUs(11);
		//
		g_wLength--;
		OUTB = 0x80;
		OUTC = DEV_nCS|addr|DEVA0;
		OUTC = cs     |addr|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|addr|DEVA0;
		WaitUs(24);
		//
		ChkStatusReg(cs, (cmd&1)?(DEV_RD|DEVA1):DEV_RD, 0x08, 0x08);
	}
	g_byRptr++;
	g_wLength--;
}

void CmdF0(BYTE cmd)
{
	BYTE cs;
	//
	cs = DEV_nCS^(DEVnCS0<<(cmd&3));
	OUTA = (cmd&4)?(DEVnIC|DEVA2):DEVnIC;
	{
		//
		ChkStatusReg(cs, DEV_RD, 0x80, 0x00);
		//
		OUTB = 0x2a;
		OUTC = DEV_nCS|DEV_WR;
		OUTC = cs     |DEV_WR;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR;
		WaitUs(2);
		//
		OUTB = BUF(g_byRptr+1);
		OUTC = DEV_nCS|DEV_WR|DEVA0;
		OUTC = cs     |DEV_WR|DEVA0;
		WaitUs(1);
		OUTC = DEV_nCS|DEV_WR|DEVA0;
		WaitUs(11);
	}
	g_byRptr += 2;
	g_wLength -= 2;
}

//
xdata void (*g_fCmd[0x20])(BYTE cmd) = {
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


void RegWrite(DWORD basetime)
{
	BYTE cmd, cs;

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
#if 0
				cs = (cmd&1)?2:0;
				cmd = BUF(g_byRptr+1);
				cs |= (cmd&0x80)?1:0;
				g_wAddr[cs] = (cmd&0x7f)<<3;
#endif
				g_byRptr += 2;
				g_wLength -= 2;
				break;

			case 0xfc:
				//
				WaitMs(1);
				EA = 0;
				g_dwBaseTime = 0;
				g_dwSyncTime = 0;
				EA = 1;
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


void BufCopy(BYTE *p, BYTE n)
{
	//
	AUTOPTRH2 = MSB(p);
	AUTOPTRL2 = LSB(p);
	if(n&1)
		EXTAUTODAT2 = EXTAUTODAT1;
#if 1
	if(n&2){
		EXTAUTODAT2 = EXTAUTODAT1;
		EXTAUTODAT2 = EXTAUTODAT1;
	}
	//
	n >>= 2;
	while(n){
		EXTAUTODAT2 = EXTAUTODAT1;
		EXTAUTODAT2 = EXTAUTODAT1;
		EXTAUTODAT2 = EXTAUTODAT1;
		EXTAUTODAT2 = EXTAUTODAT1;
		n--;
	}
#else
	//
	n >>= 1;
	while(n){
		EXTAUTODAT2 = EXTAUTODAT1;
		EXTAUTODAT2 = EXTAUTODAT1;
		n--;
	}
#endif
}

/*
	Called repeatedly while the device is idle
*/
void TD_Poll(void)
{
	WORD out;
	WORD len, ptr;
	DWORD basetime;

	//pipe1
	//  data command
	if(!(EP2468STAT&bmEP4EMPTY)){
		// check EP4 EMPTY(busy) bit in EP2468STAT (SFR), core set's this bit when FIFO is empty
		out = EP4BCH;
		out <<= 8;
		out |= EP4BCL;
		len = g_wLength+out;
		if(len>LENGTH){
			//buffer full
		} else {
			//
			APTR1H = MSB(EP4FIFOBUF);
			APTR1L = LSB(EP4FIFOBUF);
			ptr = g_byWptr+out;
			if(ptr>LENGTH){
				//
				BufCopy(g_byBuf+g_byWptr, LENGTH-g_byWptr);
				BufCopy(g_byBuf, ptr-LENGTH);
			} else {
				//
				BufCopy(g_byBuf+g_byWptr, out);
			}
			//
			EP4BCL = 0x80;
			g_wLength = len;
			g_byWptr = ptr&(LENGTH-1);
		}
	}
	//
	EA = 0;
	basetime = g_dwBaseTime;
	EA = 1;
	if(basetime>=g_dwSyncTime)
		RegWrite(basetime);

	//pipe0
	//  control command
	if(!(EP2468STAT&bmEP2EMPTY)){
		// check EP2 EMPTY(busy) bit in EP2468STAT (SFR), core set's this bit when FIFO is empty
		ControlCommand();
	}
}


void IntrTimer2(void) interrupt TMR2_VECT
{
	//interrupt flag clear
	TF2 = 0;
	//
//	if(g_dwBaseTime!=0xffffffff)
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

