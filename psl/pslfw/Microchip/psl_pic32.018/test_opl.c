
#include <plib.h>
#include <stdio.h>
#include <string.h>
#include "types.h"
#include "hio.h"
#include "timer2.h"
#include "test.h"

#if __DEBUG
#if 0
void WriteOplOpllCsbit(unsigned int csbit, unsigned int addr, int reg, int data)
{
	//
	addr += ((reg>>8)&3)*2;
	WriteIcCsbit(csbit, addr, reg&0xff);
	WaitUs(11);
	WriteIcCsbit(csbit, addr+1, data&0xff);
	WaitUs(24);
}

//
const int blockfnumtbl[2][10*12] = {
	{	//opll/opllp/vrc7
		//   c      c#       d      d#       e       f      f#       g      g#       a      a#       b
		0x0056, 0x005b, 0x0061, 0x0067, 0x006d, 0x0073, 0x007a, 0x0081, 0x0089, 0x0091, 0x009a, 0x00a3, 	//o-1
		0x00ac, 0x00b7, 0x00c2, 0x00cd, 0x00d9, 0x00e6, 0x00f4, 0x0102, 0x0112, 0x0122, 0x0133, 0x0146, 	//o0
		0x0159, 0x016d, 0x0183, 0x019a, 0x01b3, 0x01cc, 0x01e8, 0x0302, 0x0312, 0x0322, 0x0333, 0x0346, 	//o1
		0x0359, 0x036d, 0x0383, 0x039a, 0x03b3, 0x03cc, 0x03e8, 0x0502, 0x0512, 0x0522, 0x0533, 0x0546, 	//o2
		0x0559, 0x056d, 0x0583, 0x059a, 0x05b3, 0x05cc, 0x05e8, 0x0702, 0x0712, 0x0722, 0x0733, 0x0746, 	//o3
		0x0759, 0x076d, 0x0783, 0x079a, 0x07b3, 0x07cc, 0x07e8, 0x0902, 0x0912, 0x0922, 0x0933, 0x0946, 	//o4
		0x0959, 0x096d, 0x0983, 0x099a, 0x09b3, 0x09cc, 0x09e8, 0x0b02, 0x0b12, 0x0b22, 0x0b33, 0x0b46, 	//o5
		0x0b59, 0x0b6d, 0x0b83, 0x0b9a, 0x0bb3, 0x0bcc, 0x0be8, 0x0d02, 0x0d12, 0x0d22, 0x0d33, 0x0d46, 	//o6
		0x0d59, 0x0d6d, 0x0d83, 0x0d9a, 0x0db3, 0x0dcc, 0x0de8, 0x0f02, 0x0f12, 0x0f22, 0x0f33, 0x0f46, 	//o7
		0x0f59, 0x0f6d, 0x0f83, 0x0f9a, 0x0fb3, 0x0fcc, 0x0fe8,      0,      0,      0,      0,      0, 	//o8
	},
	{	//opl
		//   c      c#       d      d#       e       f      f#       g      g#       a      a#       b
		0x00ac, 0x00b7, 0x00c2, 0x00cd, 0x00d9, 0x00e6, 0x00f4, 0x0102, 0x0112, 0x0122, 0x0133, 0x0146, 	//o-1
		0x0159, 0x016d, 0x0183, 0x019a, 0x01b3, 0x01cc, 0x01e8, 0x0205, 0x0223, 0x0244, 0x0267, 0x028b, 	//o0
		0x02b2, 0x02db, 0x0306, 0x0334, 0x0365, 0x0399, 0x03cf, 0x0605, 0x0623, 0x0644, 0x0667, 0x068b, 	//o1
		0x06b2, 0x06db, 0x0706, 0x0734, 0x0765, 0x0799, 0x07cf, 0x0a05, 0x0a23, 0x0a44, 0x0a67, 0x0a8b, 	//o2
		0x0ab2, 0x0adb, 0x0b06, 0x0b34, 0x0b65, 0x0b99, 0x0bcf, 0x0e05, 0x0e23, 0x0e44, 0x0e67, 0x0e8b, 	//o3
		0x0eb2, 0x0edb, 0x0f06, 0x0f34, 0x0f65, 0x0f99, 0x0fcf, 0x1205, 0x1223, 0x1244, 0x1267, 0x128b, 	//o4
		0x12b2, 0x12db, 0x1306, 0x1334, 0x1365, 0x1399, 0x13cf, 0x1605, 0x1623, 0x1644, 0x1667, 0x168b, 	//o5
		0x16b2, 0x16db, 0x1706, 0x1734, 0x1765, 0x1799, 0x17cf, 0x1a05, 0x1a23, 0x1a44, 0x1a67, 0x1a8b, 	//o6
		0x1ab2, 0x1adb, 0x1b06, 0x1b34, 0x1b65, 0x1b99, 0x1bcf, 0x1e05, 0x1e23, 0x1e44, 0x1e67, 0x1e8b, 	//o7
		0x1eb2, 0x1edb, 0x1f06, 0x1f34, 0x1f65, 0x1f99, 0x1fcf,      0,      0,      0,      0,      0, 	//o8
	},
};
#endif

#if 0
int OpllTest(void)
{
	//
	const unsigned int csbita = (1<<0);
	const unsigned int csbitb = (1<<1);
	const unsigned int csbitab = csbita|csbitb;
	const char *stype[3] = { "opll", "opllp", "vrc7" };
	const char *srhythm[5] = { "hh", "top-cym", "tom", "sd", "bd" };
	//
	const int fnum = 0x0b4a, fnch7 = 0x0520, fnch8 = 0x0550, fnch9 = 0x01c0;
	int i, j, mode, type, inst, sus, rkey, keyon;
	struct PcKeySence key;

	//
	mode = 0;
	type = 0;
	inst = 0x1;
	sus = 0;
	rkey = 1;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//
		if(key.key_code==0x1b){	//esc
			if(key.ctrl_state&0x10){
				//shift+esc
				printf(".PcSync\n");
				PcFlush();
				while(1){
					if(PcSync("psl", NULL))
						PcReset();
				}
			}
			break;
		}

		//共通
		int binit = 0, bmode = 0, btype = 0, binst = -1, bsus = 0, brkey = -1, bkeyon = 0, bkeyoff = 0, btest = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;
			case 0x71:	//f2
				brkey = 4;
				break;
			case 0x72:	//f3
				brkey = 3;
				break;
			case 0x73:	//f4
				brkey = 2;
				break;
			case 0x74:	//f5
				brkey = 1;
				break;
			case 0x75:	//f6
				brkey = 0;
				break;

			case 0x31:	//1
				if(key.ctrl_state&0x10)
					binst = 0x1;
				break;
			case 0x32:	//2
				if(key.ctrl_state&0x10)
					binst = 0x2;
				break;
			case 0x33:	//3
				if(key.ctrl_state&0x10)
					binst = 0x3;
				break;
			case 0x34:	//4
				if(key.ctrl_state&0x10)
					binst = 0x4;
				break;
			case 0x35:	//5
				if(key.ctrl_state&0x10)
					binst = 0x5;
				break;
			case 0x36:	//6
				if(key.ctrl_state&0x10)
					binst = 0x6;
				break;
			case 0x37:	//7
				if(key.ctrl_state&0x10)
					binst = 0x7;
				break;
			case 0x38:	//8
				if(key.ctrl_state&0x10)
					binst = 0x8;
				break;
			case 0x39:	//9
				if(key.ctrl_state&0x10)
					binst = 0x9;
				break;
			case 0x30:	//0
				if(key.ctrl_state&0x10)
					binst = 0xa;
				break;
			case 0xbd:	//-
				if(key.ctrl_state&0x10)
					binst = 0xb;
				break;
			case 0xde:	//^
				if(key.ctrl_state&0x10)
					binst = 0xc;
				break;
			case 0xdc:	//'\'
				if(key.ctrl_state&0x10)
					binst = 0xd;
				break;

			case 0x09:	//tab
				bmode = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;
			case 0xdb:	//[
				if(key.ctrl_state&0x10)
					binst = 0xe;
				break;
			case 0x0d:	//enter
				btest = 1;
				break;

			case 0xf0:	//capslock
				btype = 1;
				break;
			case 0x53:	//s
				bsus = 1;
				break;

			case 0xdd:	//]
				if(key.ctrl_state&0x10)
					binst = 0xf;
				break;

			case 0x20:	//space
				if(keyon)
					bkeyoff = 1;
				else
					bkeyon = 1;
				break;
		}

		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			if(InitOpllInst())
				return 1;
			//
#if 0
			for(i=0x00; i<0x40; i++)
				WriteOplOpllCsbit(csbitab, 0, i, 0x00);
#else
			for(i=0x08; i<0x40; i++)
				WriteOplOpllCsbit(csbitab, 0, i, 0x00);
#endif
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x36, 0x00);
			WriteOplOpllCsbit(csbitab, 0, 0x37, 0x00);
			WriteOplOpllCsbit(csbitab, 0, 0x38, 0x00);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x16, fnch7&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x26, 0x00|((fnch7>>8)&0x0f));
			WriteOplOpllCsbit(csbitab, 0, 0x17, fnch8&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x27, 0x00|((fnch8>>8)&0x0f));
			WriteOplOpllCsbit(csbitab, 0, 0x18, fnch9&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x28, 0x00|((fnch9>>8)&0x0f));
			//
			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0x00);
			//
			keyon = 0;
		}

		//
		if((bmode || btype || brkey>=0 || bkeyon || bkeyoff || btest) && keyon){
			if(mode){
				//rhythm
				printf(".keyoff=%s, sus=%s\n", srhythm[rkey], sus?"on":"off");
#if 1
				WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
#else
					switch(rkey){
					case 0:	//hh
					case 3:	//sd
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+7, (sus?0x20:0)|0x00|((fnch8>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+7,              0x00|((fnch8>>8)&0x0f));
						break;
					case 1:	//top-cym
					case 2:	//tom
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+8, (sus?0x20:0)|0x00|((fnch9>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+8,              0x00|((fnch9>>8)&0x0f));
						break;
					default:		//bd
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+6, (sus?0x20:0)|0x00|((fnch7>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+6,              0x00|((fnch7>>8)&0x0f));
						break;
				}
#endif
			} else {
				//ch1
				printf(".keyoff=%x, sus=%s\n", inst, sus?"on":"off");
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20, (sus?0x20:0)|0x00|((fnum>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20,              0x00|((fnum>>8)&0x0f));
			}
			WaitMs(50);
			keyon = 0;
		}

		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%d,%s\n", mode, mode?"rhythm":"ch1");
			//
#if 1
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
#else
			WriteOplOpllCsbit(csbitab, 0, 0x20+7, (sus?0x20:0)|0x00|((fnch8>>8)&0x0f));	//hh, sd
			WriteOplOpllCsbit(csbitab, 0, 0x20+8, (sus?0x20:0)|0x00|((fnch9>>8)&0x0f));	//tom, top-cym
			WriteOplOpllCsbit(csbitab, 0, 0x20+6, (sus?0x20:0)|0x00|((fnch7>>8)&0x0f));	//bd
#endif
			WriteOplOpllCsbit(csbitab, 0, 0x20, (sus?0x20:0)|0x00|((fnum>>8)&0x0f));
		}
		//
		if(btype){
			type = (type+1)%3;
			printf(".type=%d,%s\n", type, stype[type]);
		}
		//
		if(binst>=0){
			inst = binst;
			printf(".inst=%d\n", inst);
		}
		//
		if(bsus){
			sus ^= 1;
			printf(".sus=%s\n", sus?"on":"off");
		}
		//
		if(brkey>=0){
			rkey = brkey;
			bkeyon = 1;
		}
		//
		if(bkeyon){
			if(mode){
				printf(".keyon=%s\n", srhythm[rkey]);
#if 1
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+7, (sus?0x20:0)|0x00|((fnch8>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+7,              0x00|((fnch8>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+8, (sus?0x20:0)|0x00|((fnch9>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+8,              0x00|((fnch9>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+6, (sus?0x20:0)|0x00|((fnch7>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+6,              0x00|((fnch7>>8)&0x0f));
				WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20|(1<<rkey));
#else
				switch(rkey){
					case 0:	//hh
					case 3:	//sd
						WriteOplOpllCsbit(csbitab, 0, 0x36, 0x0f);
						WriteOplOpllCsbit(csbitab, 0, 0x37, (rkey==0)?0x0f:0xf0);
						WriteOplOpllCsbit(csbitab, 0, 0x38, 0xff);
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+7, (sus?0x20:0)|0x10|((fnch8>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+7,              0x10|((fnch8>>8)&0x0f));
						break;
					case 1:	//top-cym
					case 2:	//tom
						WriteOplOpllCsbit(csbitab, 0, 0x36, 0x0f);
						WriteOplOpllCsbit(csbitab, 0, 0x37, 0xff);
						WriteOplOpllCsbit(csbitab, 0, 0x38, (rkey==1)?0xf0:0x0f);
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+8, (sus?0x20:0)|0x10|((fnch9>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+8,              0x10|((fnch9>>8)&0x0f));
						break;
					default:		//bd
						WriteOplOpllCsbit(csbitab, 0, 0x36, 0x00);
						WriteOplOpllCsbit(csbitab, 0, 0x37, 0xff);
						WriteOplOpllCsbit(csbitab, 0, 0x38, 0xff);
						WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20+6, (sus?0x20:0)|0x10|((fnch7>>8)&0x0f));
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20+6,              0x10|((fnch7>>8)&0x0f));
						break;
				}
#endif
			} else {
				printf(".keyon=%x, sus=%s\n", inst, sus?"on":"off");
				for(j=0; j<8; j++)
					WriteOplOpllCsbit(csbitab, 0, j, insttbl[type][inst][j]);
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x30, (0<<4)|0x0);
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x30, (inst<<4)|0x0);
				WriteOplOpllCsbit(csbitab, 0, 0x10, fnum&0xff);
				WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x20, (sus?0x20:0)|0x10|((fnum>>8)&0x0f));
				WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x20,              0x10|((fnum>>8)&0x0f));
			}
			WaitMs(20);
			keyon = 1;
		}

		//
		if(btest){
			printf(".test_keyon=%x\n", inst);
			for(j=0; j<8; j++)
				WriteOplOpllCsbit(csbitab, 0, j, insttbl[type][inst][j]);
			WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x30, (0<<4)|0x0);
			WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x30, (inst<<4)|0x0);
			WriteOplOpllCsbit(csbitab, 0, 0x10, fnum&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x20, 0x10|((fnum>>8)&0x0f));
			WaitMs(2000);
			keyon = 1;
			//
			i = (inst+1)&0x0f;
			printf(".change=%x\n", i);
			for(j=0; j<8; j++)
				WriteOplOpllCsbit(csbitab, 0, j, insttbl[type][i][j]);
			WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x30, (0<<4)|0x0);
			WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x30, (i<<4)|0x0);
			WaitMs(2000);
			//
			i = (inst+2)&0x0f;
			printf(".change=%x\n", i);
			for(j=0; j<8; j++)
				WriteOplOpllCsbit(csbitab, 0, j, insttbl[type][i][j]);
			WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x30, (0<<4)|0x0);
			WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x30, (i<<4)|0x0);
			WaitMs(2000);
		}
	}

	return 0;
}
#endif

#if 0
int OpllTest2(void)
{
	//
	const unsigned int csbit = (1<<2);
	const unsigned int addr = 0;
	const int fn = 0x0b4a;
	//
	int i, mode, rhythm, sus, keybit, keyon;
	struct PcKeySence key;

	//
	mode = 1;
	rhythm = 0;
	sus = 0;
	keybit = 0x00;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//
		if(key.key_code==0x1b){	//esc
			if(key.ctrl_state&0x10){
				//shift+esc
				printf(".PcSync\n");
				PcFlush();
				while(1){
					if(PcSync("psl", NULL))
						PcReset();
				}
			}
			break;
		}

		//共通
		int binit = 0, brhythm = 0, bmode = 0, bsus = 0, bfkey = 0, btest = 0, bkeybit = 0, btoggle = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;

			case 0x31:	//1
			case 0x32:	//2
			case 0x33:	//3
			case 0x34:	//4
			case 0x30:	//0
				bkeybit = (key.key_code-0x30) + 1;
				break;

			case 0x09:	//tab
				bmode = 1;
				break;
			case 0x52:	//r
				brhythm = 1;
				break;
			case 0x54:	//t
				btest = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;

			case 0x53:	//s
				bsus = 1;
				break;
			case 0x4b:	//k
				bfkey = 1;
				break;

			case 0x20:	//space
				btoggle = 1;
				break;
		}

		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%s\n", mode?"$0e":"$26-$28");
		}
		//
		if(brhythm){
			rhythm ^= 1;
			printf(".rhythm=%d\n", rhythm);
		}
		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
			for(i=0x00; i<0x40; i++)
				WriteOplOpllCsbit(csbit, addr, i, 0x00);
			//
			WriteOplOpllCsbit(csbit, addr, 0x0e, rhythm?0x20:0x00);
			WriteOplOpllCsbit(csbit, addr, 0x36, 0x20);
			WriteOplOpllCsbit(csbit, addr, 0x37, 0x20);
			WriteOplOpllCsbit(csbit, addr, 0x38, 0x20);
			WriteOplOpllCsbit(csbit, addr, 0x16, fn&0xff);
			WriteOplOpllCsbit(csbit, addr, 0x17, fn&0xff);
			WriteOplOpllCsbit(csbit, addr, 0x18, fn&0xff);
			WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|((fn>>8)&0x0f));
			WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|((fn>>8)&0x0f));
			WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|((fn>>8)&0x0f));
			//
			WriteOplOpllCsbit(csbit, addr, 0x0f, 0x02);
			WriteOplOpllCsbit(csbit, addr, 0x0f, 0x00);
		}

		//
		if(bfkey){
			keyon = 1;
			printf(".fkey\n");
			if(mode){
				WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
				WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
				WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
				WriteOplOpllCsbit(csbit, addr, 0x0e, (rhythm?0x20:0x00)|(keybit&0x1f));
			} else {
				WriteOplOpllCsbit(csbit, addr, 0x0e, (rhythm?0x20:0x00)|0x00);
				if(keybit&0x10)
					WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
				if(keybit&0x09)
					WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
				if(keybit&0x06)
					WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
			}
		}
		//
		if(btest){
			printf(".test_start\n");
			//
#if 0
			WriteOplOpllCsbit(csbit, addr, 0x00, 0x02);	//m
//			WriteOplOpllCsbit(csbit, addr, 0x00, 0x22);	//m
			WriteOplOpllCsbit(csbit, addr, 0x01, 0x21);	//c
			WriteOplOpllCsbit(csbit, addr, 0x02, 0x0f);	//m
			WriteOplOpllCsbit(csbit, addr, 0x03, 0x00);	//c
			WriteOplOpllCsbit(csbit, addr, 0x04, 0x11);	//m
			WriteOplOpllCsbit(csbit, addr, 0x05, 0xf0);	//c
			WriteOplOpllCsbit(csbit, addr, 0x06, 0xf0);	//m
			WriteOplOpllCsbit(csbit, addr, 0x07, 0x00);	//c
			//
			WriteOplOpllCsbit(csbit, addr, 0x30, 0x00);
			WriteOplOpllCsbit(csbit, addr, 0x10, fn&0xff);
			WriteOplOpllCsbit(csbit, addr, 0x20, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
			WaitMs(1000);
			WaitMs(1000);
			WriteOplOpllCsbit(csbit, addr, 0x20, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
#endif
#if 0
			//
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x20);
//			WriteOplOpllCsbit(csbit, addr, 0x38, 0xf0);	//top-cym
			WriteOplOpllCsbit(csbit, addr, 0x38, 0x0f);	//tom
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x26);
			WaitMs(20);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x24);	//top-cym keyoff
			WaitMs(1000);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x20);
			WaitMs(1000);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x26);
			WaitMs(20);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x22);	//tom keyoff
#endif
#if 0
			//
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x20);
			WriteOplOpllCsbit(csbit, addr, 0x37, 0xf0);	//sd
//			WriteOplOpllCsbit(csbit, addr, 0x37, 0x0f);	//hh
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x29);
			WaitMs(20);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x28);	//hh keyoff
			WaitMs(1000);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x20);
			WaitMs(1000);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x29);
			WaitMs(20);
			WriteOplOpllCsbit(csbit, addr, 0x0e, 0x21);	//sd keyoff
#endif
			//
			printf(".test_end\n");
		}

		//
		if(bkeybit){
			keybit ^= 1<<(bkeybit-1);
			printf(".keybit=%02x\n", keybit);
		}
		//
		if(bsus){
			sus ^= 1;
			printf(".sus=%s\n", sus?"on":"off");
			WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|((fn>>8)&0x0f));
			WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|((fn>>8)&0x0f));
			WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|((fn>>8)&0x0f));
		}
		//
		if(btoggle){
			keyon ^= 1;
			printf(".key%s\n", keyon?"on":"off");
			if(keyon){
				//keyon
				if(mode)
					WriteOplOpllCsbit(csbit, addr, 0x0e, (rhythm?0x20:0x00)|(keybit&0x1f));
				else {
					if(keybit&0x10)
						WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
					if(keybit&0x09)
						WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
					if(keybit&0x06)
						WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|0x10|((fn>>8)&0x0f));
				}
			} else {
				//keyoff
				WriteOplOpllCsbit(csbit, addr, 0x0e, rhythm?0x20:0x00);
				WriteOplOpllCsbit(csbit, addr, 0x26, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
				WriteOplOpllCsbit(csbit, addr, 0x27, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
				WriteOplOpllCsbit(csbit, addr, 0x28, (sus?0x20:0)|0x00|((fn>>8)&0x0f));
			}
		}
	}

	return 0;
}
#endif

#if 0
int OpllInst(void)
{
	//
	const unsigned int csbita = (1<<0);
	const unsigned int csbitb = (1<<1);
	const unsigned int csbitab = csbita|csbitb;
	const char *stype[3] = { "opll", "opllp", "vrc7" };
	const char *srhythm[5] = { "hh", "top-cym", "tom", "sd", "bd" };
	//
	int i, j, k, fnum, mode, type, inst, oct, keyon;
	struct PcKeySence key;
	unsigned char curinst[8];

	//
	fnum = 0x0b4a;
	mode = 0;
	type = 2;
	inst = 0x0;
	oct = 0;
	keyon = 0;
	while(1){
		//
//		PowerSaveIdle();
		PcKeySence(&key);
		if(key.key_code==0x00){
			//入力なし
			continue;
		}
//		printf("ctrl=%04x down=%02x code=%02x\n", key.ctrl_state, key.key_down, key.key_code);
		if(key.key_down==0)
			continue;

		//
		if(key.key_code==0x1b){	//esc
			if(key.ctrl_state&0x10){
				//shift+esc
				printf(".PcSync\n");
				PcFlush();
				while(1){
					if(PcSync("psl", NULL))
						PcReset();
				}
			}
			break;
		}

		//共通
		int bmode = 0, btype = 0, binst = -1, brkey = -1, binit = 0, btest = 0, bkeyon = 0, bkeyoff = 0;
		switch(key.key_code){
			case 0xf3:	case 0xf4:	//半角/全角
				if(key.ctrl_state&0x10)
					binst = 0x0;
				break;

			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;

			case 0x71:	//f2
				brkey = 4;
				break;
			case 0x72:	//f3
				brkey = 3;
				break;
			case 0x73:	//f4
				brkey = 2;
				break;
			case 0x74:	//f5
				brkey = 1;
				break;
			case 0x75:	//f6
				brkey = 0;
				break;

			case 0x76:	//f7
			case 0x77:	//f8
			case 0x78:	//f9
			case 0x79:	//f10
			case 0x7a:	//f11
			case 0x7b:	//f12
			case 0x90:	//numlk
			case 0x2d:	//ins
			case 0x2e:	//del
				break;

			case 0x31:	//1
				if(key.ctrl_state&0x10)
					binst = 0x1;
				break;
			case 0x32:	//2
				if(key.ctrl_state&0x10)
					binst = 0x2;
				break;
			case 0x33:	//3
				if(key.ctrl_state&0x10)
					binst = 0x3;
				break;
			case 0x34:	//4
				if(key.ctrl_state&0x10)
					binst = 0x4;
				break;
			case 0x35:	//5
				if(key.ctrl_state&0x10)
					binst = 0x5;
				break;
			case 0x36:	//6
				if(key.ctrl_state&0x10)
					binst = 0x6;
				break;
			case 0x37:	//7
				if(key.ctrl_state&0x10)
					binst = 0x7;
				break;
			case 0x38:	//8
				if(key.ctrl_state&0x10)
					binst = 0x8;
				break;
			case 0x39:	//9
				if(key.ctrl_state&0x10)
					binst = 0x9;
				break;
			case 0x30:	//0
				if(key.ctrl_state&0x10)
					binst = 0xa;
				break;
			case 0xbd:	//-
				if(key.ctrl_state&0x10)
					binst = 0xb;
				break;
			case 0xde:	//^
				if(key.ctrl_state&0x10)
					binst = 0xc;
				break;
			case 0xdc:	//'\'
				if(key.ctrl_state&0x10)
					binst = 0xd;
				break;

			case 0x08:	//backspace
				fnum = 0x0b4a;
				bkeyon = 1;
				break;
			case 0x09:	//tab
				bmode = 1;
				break;

			case 0x51:	//q
			case 0x57:	//w
			case 0x45:	//e
			case 0x52:	//r
			case 0x54:	//t
			case 0x59:	//y
			case 0x55:	//u
			case 0x49:	//i
			case 0x4f:	//o
			case 0x50:	//p
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0xdb:	//[
				if(key.ctrl_state&0x10)
					binst = 0xe;
				break;

			case 0x0d:	//enter
				btest = 1;
				break;

			case 0xf0:	//capslock
				btype = 1;
				break;

			case 0x41:	//a
			case 0x53:	//s
			case 0x44:	//d
			case 0x46:	//f
			case 0x47:	//g
			case 0x48:	//h
			case 0x4a:	//j
			case 0x4b:	//k
			case 0x4c:	//l
			case 0xbb:	//;
			case 0xba:	//:
				break;

			case 0xdd:	//]
				if(key.ctrl_state&0x10)
					binst = 0xf;
				break;

			case 0x10:	//左shift, 右shift
			case 0x5a:	//z
			case 0x58:	//x
			case 0x43:	//c
			case 0x56:	//v
			case 0x42:	//b
			case 0x4e:	//n
			case 0x4d:	//m
			case 0xbc:	//,
			case 0xbe:	//.
			case 0xbf:	///
			case 0xe2:	//バックスラッシュ
			case 0x11:	//左ctrl, 右ctrl
			case 0x5b:	//windows
			case 0x12:	//左alt
			case 0x1d:	//無変換
				break;

			case 0x20:	//space
				if(keyon)
					bkeyoff = 1;
				else
					bkeyon = 1;
				break;

			case 0x1c:	//変換
			case 0xf2:	//カタカナひらがな
			case 0x5d:	//application
			case 0x26:	//↑
			case 0x25:	//←
			case 0x28:	//↓
			case 0x27:	//→
				break;
		}

		//
		int boct = 0, bkey = -1;
		if(mode){
			//key
			if((~key.ctrl_state)&0x10){
				switch(key.key_code){
					case 0x32:	//2
						bkey = 5*12+1;
						break;
					case 0x33:	//3
						bkey = 5*12+3;
						break;
					case 0x35:	//5
						bkey = 5*12+6;
						break;
					case 0x36:	//6
						bkey = 5*12+8;
						break;
					case 0x37:	//7
						bkey = 5*12+10;
						break;

					case 0x39:	//9
						bkey = 6*12+1;
						break;
					case 0x30:	//0
						bkey = 6*12+3;
						break;

					case 0x51:	//q
						bkey = 5*12+0;
						break;
					case 0x57:	//w
						bkey = 5*12+2;
						break;
					case 0x45:	//e
						bkey = 5*12+4;
						break;
					case 0x52:	//r
						bkey = 5*12+5;
						break;
					case 0x54:	//t
						bkey = 5*12+7;
						break;
					case 0x59:	//y
						bkey = 5*12+9;
						break;
					case 0x55:	//u
						bkey = 5*12+11;
						break;

					case 0x49:	//i
						bkey = 6*12+0;
						break;
					case 0x4f:	//o
						bkey = 6*12+2;
						break;
					case 0x50:	//p
						bkey = 6*12+4;
						break;

					case 0x53:	//s
						bkey = 4*12+1;
						break;
					case 0x44:	//d
						bkey = 4*12+3;
						break;

					case 0x47:	//g
						bkey = 4*12+6;
						break;
					case 0x48:	//h
						bkey = 4*12+8;
						break;
					case 0x4a:	//j
						bkey = 4*12+10;
						break;
					case 0x4c:	//l
						bkey = 5*12+1;
						break;
					case 0xbb:	//;
						bkey = 5*12+3;
						break;
					case 0xdd:	//]
						bkey = 5*12+6;
						break;

					case 0x5a:	//z
						bkey = 4*12+0;
						break;
					case 0x58:	//x
						bkey = 4*12+2;
						break;
					case 0x43:	//c
						bkey = 4*12+4;
						break;
					case 0x56:	//v
						bkey = 4*12+5;
						break;
					case 0x42:	//b
						bkey = 4*12+7;
						break;
					case 0x4e:	//n
						bkey = 4*12+9;
						break;
					case 0x4d:	//m
						bkey = 4*12+11;
						break;

					case 0xbc:	//,
						bkey = 5*12+0;
						break;
					case 0xbe:	//.
						bkey = 5*12+2;
						break;
					case 0xbf:	///
						bkey = 5*12+4;
						break;
					case 0xe2:	//バックスラッシュ
						bkey = 5*12+5;
						break;

					case 0x26:	//↑
						boct = +1;
						break;
					case 0x28:	//↓
						boct = -1;
						break;
				}
			}
		} else {
			//edit
			if((~key.ctrl_state)&0x10){
				switch(key.key_code){
					case 0x31:	//1
						//off/on	modulator, am
						curinst[0] ^= 0x80;
						printf(".modulator.am=%s\n", (curinst[0]&0x80)?"on":"off");
						bkeyon = 1;
						break;
					case 0x32:	//2
						//off/on	modulator, vib
						curinst[0] ^= 0x40;
						printf(".modulator.vib=%s\n", (curinst[0]&0x40)?"on":"off");
						bkeyon = 1;
						break;
					case 0x33:	//3
						//percussive/sustained	modulator, egtyp
						curinst[0] ^= 0x20;
						printf(".modulator.egtyp=%s\n", (curinst[0]&0x20)?"sustained":"percussive");
						bkeyon = 1;
						break;
					case 0x34:	//4
						//0/1	modulator, ksr
						curinst[0] ^= 0x10;
						printf(".modulator.ksr=%s\n", (curinst[0]&0x10)?"1":"0");
						bkeyon = 1;
						break;
					case 0x35:	//5
						//-	modulator, multi
						i = (curinst[0]-1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i--;
						curinst[0] = (curinst[0]&0xf0)|(i&0x0f);
						printf(".modulator.multi=%d\n", curinst[0]&0x0f);
						bkeyon = 1;
						break;
					case 0x36:	//6
						//+	modulator, multi
						i = (curinst[0]+1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i++;
						curinst[0] = (curinst[0]&0xf0)|(i&0x0f);
						printf(".modulator.multi=%d\n", curinst[0]&0x0f);
						bkeyon = 1;
						break;
					case 0x37:	//7
						//off/on	carrier, am
						curinst[1] ^= 0x80;
						printf(".carrier.am=%s\n", (curinst[1]&0x80)?"on":"off");
						bkeyon = 1;
						break;
					case 0x38:	//8
						//off/on	carrier, vib
						curinst[1] ^= 0x40;
						printf(".carrier.vib=%s\n", (curinst[1]&0x40)?"on":"off");
						bkeyon = 1;
						break;
					case 0x39:	//9
						//percussive/sustained	carrier, egtyp
						curinst[1] ^= 0x20;
						printf(".carrier.egtyp=%s\n", (curinst[1]&0x20)?"sustained":"percussive");
						bkeyon = 1;
						break;
					case 0x30:	//0
						//0/1	carrier, ksr
						curinst[1] ^= 0x10;
						printf(".carrier.ksr=%s\n", (curinst[1]&0x10)?"1":"0");
						bkeyon = 1;
						break;
					case 0xbd:	//-
						//-	carrier, multi
						i = (curinst[1]-1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i--;
						curinst[1] = (curinst[1]&0xf0)|(i&0x0f);
						printf(".carrier.multi=%d\n", curinst[1]&0x0f);
						bkeyon = 1;
						break;
					case 0xde:	//^
						//+	carrier, multi
						i = (curinst[1]+1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i++;
						curinst[1] = (curinst[1]&0xf0)|(i&0x0f);
						printf(".carrier.multi=%d\n", curinst[1]&0x0f);
						bkeyon = 1;
						break;

					case 0x51:	//q
						//-	modulator, ksl
						curinst[2] = ((curinst[2]-0x40)&0xc0)|(curinst[2]&0x3f);
						printf(".modulator.ksl=%d\n", (curinst[2]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x57:	//w
						//+	modulator, ksl
						curinst[2] = ((curinst[2]+0x40)&0xc0)|(curinst[2]&0x3f);
						printf(".modulator.ksl=%d\n", (curinst[2]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x45:	//e
						//-	modulator, tl
						curinst[2] = (curinst[2]&0xc0)|((curinst[2]-1)&0x3f);
						printf(".modulator.tl=%d\n", curinst[2]&0x3f);
						bkeyon = 1;
						break;
					case 0x52:	//r
						//+	modulator, tl
						curinst[2] = (curinst[2]&0xc0)|((curinst[2]+1)&0x3f);
						printf(".modulator.tl=%d\n", curinst[2]&0x3f);
						bkeyon = 1;
						break;
					case 0x54:	//t
						//-	carrier, ksl
						curinst[3] = ((curinst[3]-0x40)&0xc0)|(curinst[3]&0x3f);
						printf(".carrier.ksl=%d\n", (curinst[3]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x59:	//y
						//+	carrier, ksl
						curinst[3] = ((curinst[3]+0x40)&0xc0)|(curinst[3]&0x3f);
						printf(".carrier.ksl=%d\n", (curinst[3]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x55:	//u
						//normal/half	carrier, dc
						curinst[3] ^= 0x10;
						printf(".carrier.dc=%s\n", (curinst[3]&0x10)?"half":"normal");
						bkeyon = 1;
						break;
					case 0x49:	//i
						//normal/half	modulator, dm
						curinst[3] ^= 0x08;
						printf(".modulator.dc=%s\n", (curinst[3]&0x08)?"half":"normal");
						bkeyon = 1;
						break;
					case 0x4f:	//o
						//-	fb
						curinst[3] = (curinst[3]&0xf8)|((curinst[3]-1)&0x07);
						printf(".fb=%d\n", curinst[3]&0x07);
						bkeyon = 1;
						break;
					case 0x50:	//p
						//+	fb
						curinst[3] = (curinst[3]&0xf8)|((curinst[3]+1)&0x07);
						printf(".fb=%d\n", curinst[3]&0x07);
						bkeyon = 1;
						break;

					case 0x41:	//a
						//-	modulator, ar
						curinst[4] = ((curinst[4]-0x10)&0xf0)|(curinst[4]&0x0f);
						printf(".modulator.ar=%d\n", (curinst[4]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x53:	//s
						//+	modulator, ar
						curinst[4] = ((curinst[4]+0x10)&0xf0)|(curinst[4]&0x0f);
						printf(".modulator.ar=%d\n", (curinst[4]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x44:	//d
						//-	carrier, ar
						curinst[5] = ((curinst[5]-0x10)&0xf0)|(curinst[5]&0x0f);
						printf(".carrier.ar=%d\n", (curinst[5]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x46:	//f
						//+	carrier, ar
						curinst[5] = ((curinst[5]+0x10)&0xf0)|(curinst[5]&0x0f);
						printf(".carrier.ar=%d\n", (curinst[5]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x47:	//g
						//-	modulator, dr
						curinst[4] = (curinst[4]&0xf0)|((curinst[4]-1)&0x0f);
						printf(".modulator.dr=%d\n", curinst[4]&0x0f);
						bkeyon = 1;
						break;
					case 0x48:	//h
						//+	modulator, dr
						curinst[4] = (curinst[4]&0xf0)|((curinst[4]+1)&0x0f);
						printf(".modulator.dr=%d\n", curinst[4]&0x0f);
						bkeyon = 1;
						break;
					case 0x4a:	//j
						//-	carrier, dr
						curinst[5] = (curinst[5]&0xf0)|((curinst[5]-1)&0x0f);
						printf(".carrier.dr=%d\n", curinst[5]&0x0f);
						bkeyon = 1;
						break;
					case 0x4b:	//k
						//+	carrier, dr
						curinst[5] = (curinst[5]&0xf0)|((curinst[5]+1)&0x0f);
						printf(".carrier.dr=%d\n", curinst[5]&0x0f);
						bkeyon = 1;
						break;

#if 0
					case 0xbb:	//;
						//-	modulator, ar/dr/sl
						i = (curinst[4]<<8)|curinst[6];
						i -= 0x10;
						curinst[4] = (i>>8)&0xff;
						curinst[6] = i&0xff;
						printf(".modulator.ar=%d, dr=%d, sl=%d\n", (curinst[4]>>4)&0x0f, curinst[4]&0x0f, (curinst[6]>>4)&0x0f);
						bkeyon = 1;
						break;

					case 0xba:	//:
						//+	modulator, ar/dr/sl
						i = (curinst[4]<<8)|curinst[6];
						i += 0x10;
						curinst[4] = (i>>8)&0xff;
						curinst[6] = i&0xff;
						printf(".modulator.ar=%d, dr=%d, sl=%d\n", (curinst[4]>>4)&0x0f, curinst[4]&0x0f, (curinst[6]>>4)&0x0f);
						bkeyon = 1;
						break;
#endif

					case 0x5a:	//z
						//-	modulator, sl
						curinst[6] = ((curinst[6]-0x10)&0xf0)|(curinst[6]&0x0f);
						printf(".modulator.sl=%d\n", (curinst[6]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x58:	//x
						//+	modulator, sl
						curinst[6] = ((curinst[6]+0x10)&0xf0)|(curinst[6]&0x0f);
						printf(".modulator.sl=%d\n", (curinst[6]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x43:	//c
						//-	carrier, sl
						curinst[7] = ((curinst[7]-0x10)&0xf0)|(curinst[7]&0x0f);
						printf(".carrier.sl=%d\n", (curinst[7]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x56:	//v
						//+	carrier, sl
						curinst[7] = ((curinst[7]+0x10)&0xf0)|(curinst[7]&0x0f);
						printf(".carrier.sl=%d\n", (curinst[7]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x42:	//b
						//-	modulator, rr
						curinst[6] = (curinst[6]&0xf0)|((curinst[6]-1)&0x0f);
						printf(".modulator.rr=%d\n", curinst[6]&0x0f);
						bkeyon = 1;
						break;
					case 0x4e:	//n
						//+	modulator, rr
						curinst[6] = (curinst[6]&0xf0)|((curinst[6]+1)&0x0f);
						printf(".modulator.rr=%d\n", curinst[6]&0x0f);
						bkeyon = 1;
						break;
					case 0x4d:	//m
						//-	carrier, rr
						curinst[7] = (curinst[7]&0xf0)|((curinst[7]-1)&0x0f);
						printf(".carrier.rr=%d\n", curinst[7]&0x0f);
						bkeyon = 1;
						break;
					case 0xbc:	//,
						//+	carrier, rr
						curinst[7] = (curinst[7]&0xf0)|((curinst[7]+1)&0x0f);
						printf(".carrier.rr=%d\n", curinst[7]&0x0f);
						bkeyon = 1;
						break;
				}
			}
		}

		//
		if((bmode || btype || binst>=0 || brkey>=0 || boct || bkey>=0 || binit || bkeyon || bkeyoff) && keyon){
//			printf(".keyoff\n");
			keyon = 0;
			//ch1
			if(bkeyoff)
				WriteOplOpllCsbit(csbitab, 0, 0x20, 0x00|((fnum>>8)&0x0f));
			else
				WriteOplOpllCsbit(csbitab, 0, 0x20, 0x20|((fnum>>8)&0x0f));
			//rhythm
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
			WaitMs(50);
		}

		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%d,%s\n", mode, mode?"key":"edit");
		}
		//
		if(btype){
			type = (type+1)%3;
			printf(".type=%d,%s\n", type, stype[type]);
		}
		//
		if(binst>=0){
			inst = binst;
			printf(".inst=%d\n", inst);
			memcpy(curinst, insttbl[type][inst], sizeof(curinst));
			bkeyon = 1;
		}
		//
		if(brkey>=0){
			printf(".rhythm=%s\n", srhythm[brkey]);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x36, 0x00);
			WriteOplOpllCsbit(csbitab, 0, 0x37, 0x00);
			WriteOplOpllCsbit(csbitab, 0, 0x38, 0x00);
			//
			int fnch7 = 0x0520;
			WriteOplOpllCsbit(csbitab, 0, 0x16, fnch7&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x26, (fnch7>>8)&0x0f);
			int fnch8 = 0x0550;
			WriteOplOpllCsbit(csbitab, 0, 0x17, fnch8&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x27, (fnch8>>8)&0x0f);
			int fnch9 = 0x01c0;
			WriteOplOpllCsbit(csbitab, 0, 0x18, fnch9&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x28, (fnch9>>8)&0x0f);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20|(1<<brkey));
			WaitMs(20);
			keyon = 1;
		}
		//
		if(boct){
			int o = oct+boct;
			if(o<-5)
				o = -5;
			else
			if(o>+4)
				o = +4;
			if(o!=oct){
				oct = o;
				printf(".oct=%d\n", oct+4);
			}
		}
		//
		if(bkey>=0){
			bkey = (oct+1)*12 + bkey;
			if(bkey>=0 && bkey<(sizeof(blockfnumtbl[0])/sizeof(blockfnumtbl[0][0]))){
				if(blockfnumtbl[0][bkey]){
					const char *sscale[12] = { "c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b" };
					printf(".key=o%d%s(%d)\n", (bkey/12)-1, sscale[bkey%12], bkey);
					fnum = blockfnumtbl[0][bkey];
					bkeyon = 1;
				}
			}
		}
		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			if(InitOpllInst())
				return 1;
			memcpy(curinst, insttbl[type][inst], sizeof(curinst));
			//
#if 0
			for(i=0x00; i<0x40; i++)
				WriteOplOpllCsbit(csbitab, 0, i, 0x00);
#else
			for(i=0x08; i<0x40; i++)
				WriteOplOpllCsbit(csbitab, 0, i, 0x00);
#endif
			WriteOplOpllCsbit(csbitab, 0, 0x0e, 0x20);
			//
			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0x00);
		}
		//
		if(btest){
		}
		//
		if(bkeyon){
			int f = 0;
			printf(".keyon(%d,0b%d%d%d%d), %x=", (fnum>>9)&7, (fnum&0x100)?1:0, (fnum&0x080)?1:0, (fnum&0x040)?1:0, (fnum&0x020)?1:0, inst);
			for(i=0; i<8; i++){
				if(inst){
					//inst=1~15
					WriteOplOpllCsbit(csbitab, 0, i, curinst[i]);
				} else {
					//inst=0
					WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, i, curinst[i]);
					if(i==0x04 || i==0x05){
						//0x04:modulator, ar/dr
						//0x05:carrier, ar/dr
						WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, i, curinst[i]);
					}
				}
				printf("0x%02x", curinst[i]);
				if(curinst[i]!=insttbl[type][inst][i])
					f++;
				if(i<7)
					printf(",");
			}
			printf("#%x, %s\n", inst, f?"ne":"eq");
			WriteOplOpllCsbit((type==1)?csbita:csbitb, 0, 0x30, (0<<4)|0x0);
			WriteOplOpllCsbit((type==1)?csbitb:csbita, 0, 0x30, (inst<<4)|0x0);
			WriteOplOpllCsbit(csbitab, 0, 0x10, fnum&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x20, 0x10|((fnum>>8)&0x0f));
			WaitMs(20);
			keyon = 1;
		}
	}

#if 1
	//
	for(i=0; i<3; i++){
		printf("[0]\n");
		printf("#%s\n", stype[i]);
		for(j=0; j<((i==0)?16+3:16); j++){
			//
			memcpy(curinst, insttbl[i][j], sizeof(curinst));
			if(j<17)
				curinst[3] &= ~0x20;
			else
				curinst[3] |= 0x20;
			//modulator
			if((curinst[4]&0xf0)==0){
				//ar=0
				curinst[0] = 0x00;
				curinst[2] = 0x00;
				curinst[4] = 0x00;
				curinst[6] = 0x00;
			} else {
				//multi
				switch(curinst[0]&0x0f){
					case 0x0b:	case 0x0d:	case 0x0f:
						curinst[0] &= 0xfe;
						break;
				}
				//dr/sl
				if(curinst[0]&0x20){
					//持続
					if((curinst[4]&0x0f)==0 || (curinst[6]&0xf0)==0){
						//dr=0, sl=0
						curinst[6] &= ~0xf0;	//sl=0
						curinst[4] &= ~0x0f;	//dr=0
					}
				} else {
					//減衰
					if((curinst[6]&0xf0)==0){
						//sl=0					
						curinst[4] &= ~0x0f;	//dr=0
					}
				}
			}
			//carrier
			if((j>0 && j<17) && (curinst[5]&0xf0)==0){
				//ar=0
				curinst[0] = 0x00;	//modulator
				curinst[2] = 0x00;	//modulator
				curinst[4] = 0x00;	//modulator
				curinst[6] = 0x00;	//modulator
			}
			//carrier
			if(j>0 && (curinst[5]&0xf0)==0){
				//ar=0
				curinst[1] = 0x00;
				curinst[3] = 0x00;
				curinst[5] = 0x00;
				curinst[7] = 0x00;
			} else {
				//multi
				switch(curinst[1]&0x0f){
					case 0x0b:	case 0x0d:	case 0x0f:
						curinst[1] &= 0xfe;
						break;
				}
				//dr/sl
				if(curinst[1]&0x20){
					//持続
					if((curinst[5]&0x0f)==0 || (curinst[7]&0xf0)==0){
						//dr=0, sl=0
						curinst[7] &= ~0xf0;	//sl=0
						curinst[5] &= ~0x0f;	//dr=0
					}
				} else {
					//減衰
					if((curinst[7]&0xf0)==0){
						//sl=0					
						curinst[5] &= ~0x0f;	//dr=0
					}
				}
			}
			//
			if(j==16)
				printf("#\n");
			printf("%d=", j);
			for(k=0; k<8; k++){
				printf("0x%02x", curinst[k]);
				if(k<7)
					printf(",");
			}
			switch(j){
				case 0:
					printf("#%x, original\n", j);
					break;
				case 16:
					printf("#%s\n", srhythm[4]);
					break;
				case 17:
					printf("#%s, %s\n", srhythm[0], srhythm[3]);
					break;
				case 18:
					printf("#%s, %s\n", srhythm[2], srhythm[1]);
					break;
				default:
					printf("#%x\n", j);
					break;
			}
		}
	}
#endif

	return 0;
}
#endif

#if 0
int OpllRhythm(void)
{

	//
	const unsigned int csbita = (1<<0);
	const unsigned int csbitb = (1<<1);
	const unsigned int csbitab = csbita|csbitb;
	const char *srhythm[5] = { "hh", "top-cym", "tom", "sd", "bd" };
	//
	int i, block, fnumber, rch, rkey, rinst, keyon;
	struct PcKeySence key;
	unsigned char curinst[8];

	//
	block = 2;
//	fnumber = (5<<9)|0x014a;	//1k
//	fnumber = (2<<9)|0x0120;
	rch = 6;
	rkey = 0;
	rinst = 16;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00){
			//入力なし
			continue;
		}
		if(key.key_down==0)
			continue;

		//
		if(key.key_code==0x1b){	//esc
			if(key.ctrl_state&0x10){
				//shift+esc
				printf(".PcSync\n");
				PcFlush();
				while(1){
					if(PcSync("psl", NULL))
						PcReset();
				}
			}
			break;
		}

		//共通
		int bblock = 0, brkey = -1, binit = 0, bkeyon = 0, bkeyoff = 0;
		switch(key.key_code){
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;
			case 0x71:	//f2
				brkey = 4;
				break;
			case 0x72:	//f3
				brkey = 3;
				break;
			case 0x73:	//f4
				brkey = 2;
				break;
			case 0x74:	//f5
				brkey = 1;
				break;
			case 0x75:	//f6
				brkey = 0;
				break;

			case 0x08:	//backspace
				fnumber = 0x0b4a;
				bkeyon = 1;
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0x20:	//space
				if(keyon)
					bkeyoff = 1;
				else
					bkeyon = 1;
				break;

			case 0x26:	//↑
				bblock = +1;
				break;
			case 0x28:	//↓
				bblock = -1;
				break;
		}

		//edit
		if((~key.ctrl_state)&0x10){
			switch(key.key_code){
				case 0x31:	//1
					//off/on	modulator, am
					curinst[0] ^= 0x80;
					printf(".modulator.am=%s\n", (curinst[0]&0x80)?"on":"off");
					bkeyon = 1;
					break;
				case 0x32:	//2
					//off/on	modulator, vib
					curinst[0] ^= 0x40;
					printf(".modulator.vib=%s\n", (curinst[0]&0x40)?"on":"off");
					bkeyon = 1;
					break;
				case 0x33:	//3
					//percussive/sustained	modulator, egtyp
					curinst[0] ^= 0x20;
					printf(".modulator.egtyp=%s\n", (curinst[0]&0x20)?"sustained":"percussive");
					bkeyon = 1;
					break;
				case 0x34:	//4
					//0/1	modulator, ksr
					curinst[0] ^= 0x10;
					printf(".modulator.ksr=%s\n", (curinst[0]&0x10)?"1":"0");
					bkeyon = 1;
					break;
				case 0x35:	//5
					//-	modulator, multi
					i = (curinst[0]-1)&0x0f;
					if(i==0xb || i==0xd || i==0xf)
						i--;
					curinst[0] = (curinst[0]&0xf0)|(i&0x0f);
					printf(".modulator.multi=%d\n", curinst[0]&0x0f);
					bkeyon = 1;
					break;
				case 0x36:	//6
					//+	modulator, multi
					i = (curinst[0]+1)&0x0f;
					if(i==0xb || i==0xd || i==0xf)
						i++;
					curinst[0] = (curinst[0]&0xf0)|(i&0x0f);
					printf(".modulator.multi=%d\n", curinst[0]&0x0f);
					bkeyon = 1;
					break;
				case 0x37:	//7
					//off/on	carrier, am
					curinst[1] ^= 0x80;
					printf(".carrier.am=%s\n", (curinst[1]&0x80)?"on":"off");
					bkeyon = 1;
					break;
				case 0x38:	//8
					//off/on	carrier, vib
					curinst[1] ^= 0x40;
					printf(".carrier.vib=%s\n", (curinst[1]&0x40)?"on":"off");
					bkeyon = 1;
					break;
				case 0x39:	//9
					//percussive/sustained	carrier, egtyp
					curinst[1] ^= 0x20;
					printf(".carrier.egtyp=%s\n", (curinst[1]&0x20)?"sustained":"percussive");
					bkeyon = 1;
					break;
				case 0x30:	//0
					//0/1	carrier, ksr
					curinst[1] ^= 0x10;
					printf(".carrier.ksr=%s\n", (curinst[1]&0x10)?"1":"0");
					bkeyon = 1;
					break;
				case 0xbd:	//-
					//-	carrier, multi
					i = (curinst[1]-1)&0x0f;
					if(i==0xb || i==0xd || i==0xf)
						i--;
					curinst[1] = (curinst[1]&0xf0)|(i&0x0f);
					printf(".carrier.multi=%d\n", curinst[1]&0x0f);
					bkeyon = 1;
					break;
				case 0xde:	//^
					//+	carrier, multi
					i = (curinst[1]+1)&0x0f;
					if(i==0xb || i==0xd || i==0xf)
						i++;
					curinst[1] = (curinst[1]&0xf0)|(i&0x0f);
					printf(".carrier.multi=%d\n", curinst[1]&0x0f);
					bkeyon = 1;
					break;

				case 0x51:	//q
					//-	modulator, ksl
					curinst[2] = ((curinst[2]-0x40)&0xc0)|(curinst[2]&0x3f);
					printf(".modulator.ksl=%d\n", (curinst[2]>>6)&0x03);
					bkeyon = 1;
					break;
				case 0x57:	//w
					//+	modulator, ksl
					curinst[2] = ((curinst[2]+0x40)&0xc0)|(curinst[2]&0x3f);
					printf(".modulator.ksl=%d\n", (curinst[2]>>6)&0x03);
					bkeyon = 1;
					break;
				case 0x45:	//e
					//-	modulator, tl
					curinst[2] = (curinst[2]&0xc0)|((curinst[2]-1)&0x3f);
					printf(".modulator.tl=%d\n", curinst[2]&0x3f);
					bkeyon = 1;
					break;
				case 0x52:	//r
					//+	modulator, tl
					curinst[2] = (curinst[2]&0xc0)|((curinst[2]+1)&0x3f);
					printf(".modulator.tl=%d\n", curinst[2]&0x3f);
					bkeyon = 1;
					break;
				case 0x54:	//t
					//-	carrier, ksl
					curinst[3] = ((curinst[3]-0x40)&0xc0)|(curinst[3]&0x3f);
					printf(".carrier.ksl=%d\n", (curinst[3]>>6)&0x03);
					bkeyon = 1;
					break;
				case 0x59:	//y
					//+	carrier, ksl
					curinst[3] = ((curinst[3]+0x40)&0xc0)|(curinst[3]&0x3f);
					printf(".carrier.ksl=%d\n", (curinst[3]>>6)&0x03);
					bkeyon = 1;
					break;
				case 0x55:	//u
					//normal/half	carrier, dc
					curinst[3] ^= 0x10;
					printf(".carrier.dc=%s\n", (curinst[3]&0x10)?"half":"normal");
					bkeyon = 1;
					break;
				case 0x49:	//i
					//normal/half	modulator, dm
					curinst[3] ^= 0x08;
					printf(".modulator.dc=%s\n", (curinst[3]&0x08)?"half":"normal");
					bkeyon = 1;
					break;
				case 0x4f:	//o
					//-	fb
					curinst[3] = (curinst[3]&0xf8)|((curinst[3]-1)&0x07);
					printf(".fb=%d\n", curinst[3]&0x07);
					bkeyon = 1;
					break;
				case 0x50:	//p
					//+	fb
					curinst[3] = (curinst[3]&0xf8)|((curinst[3]+1)&0x07);
					printf(".fb=%d\n", curinst[3]&0x07);
					bkeyon = 1;
					break;

				case 0x41:	//a
					//-	modulator, ar
					curinst[4] = ((curinst[4]-0x10)&0xf0)|(curinst[4]&0x0f);
					printf(".modulator.ar=%d\n", (curinst[4]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x53:	//s
					//+	modulator, ar
					curinst[4] = ((curinst[4]+0x10)&0xf0)|(curinst[4]&0x0f);
					printf(".modulator.ar=%d\n", (curinst[4]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x44:	//d
					//-	carrier, ar
					curinst[5] = ((curinst[5]-0x10)&0xf0)|(curinst[5]&0x0f);
					printf(".carrier.ar=%d\n", (curinst[5]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x46:	//f
					//+	carrier, ar
					curinst[5] = ((curinst[5]+0x10)&0xf0)|(curinst[5]&0x0f);
					printf(".carrier.ar=%d\n", (curinst[5]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x47:	//g
					//-	modulator, dr
					curinst[4] = (curinst[4]&0xf0)|((curinst[4]-1)&0x0f);
					printf(".modulator.dr=%d\n", curinst[4]&0x0f);
					bkeyon = 1;
					break;
				case 0x48:	//h
					//+	modulator, dr
					curinst[4] = (curinst[4]&0xf0)|((curinst[4]+1)&0x0f);
					printf(".modulator.dr=%d\n", curinst[4]&0x0f);
					bkeyon = 1;
					break;
				case 0x4a:	//j
					//-	carrier, dr
					curinst[5] = (curinst[5]&0xf0)|((curinst[5]-1)&0x0f);
					printf(".carrier.dr=%d\n", curinst[5]&0x0f);
					bkeyon = 1;
					break;
				case 0x4b:	//k
					//+	carrier, dr
					curinst[5] = (curinst[5]&0xf0)|((curinst[5]+1)&0x0f);
					printf(".carrier.dr=%d\n", curinst[5]&0x0f);
					bkeyon = 1;
					break;

				case 0x5a:	//z
					//-	modulator, sl
					curinst[6] = ((curinst[6]-0x10)&0xf0)|(curinst[6]&0x0f);
					printf(".modulator.sl=%d\n", (curinst[6]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x58:	//x
					//+	modulator, sl
					curinst[6] = ((curinst[6]+0x10)&0xf0)|(curinst[6]&0x0f);
					printf(".modulator.sl=%d\n", (curinst[6]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x43:	//c
					//-	carrier, sl
					curinst[7] = ((curinst[7]-0x10)&0xf0)|(curinst[7]&0x0f);
					printf(".carrier.sl=%d\n", (curinst[7]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x56:	//v
					//+	carrier, sl
					curinst[7] = ((curinst[7]+0x10)&0xf0)|(curinst[7]&0x0f);
					printf(".carrier.sl=%d\n", (curinst[7]>>4)&0x0f);
					bkeyon = 1;
					break;
				case 0x42:	//b
					//-	modulator, rr
					curinst[6] = (curinst[6]&0xf0)|((curinst[6]-1)&0x0f);
					printf(".modulator.rr=%d\n", curinst[6]&0x0f);
					bkeyon = 1;
					break;
				case 0x4e:	//n
					//+	modulator, rr
					curinst[6] = (curinst[6]&0xf0)|((curinst[6]+1)&0x0f);
					printf(".modulator.rr=%d\n", curinst[6]&0x0f);
					bkeyon = 1;
					break;
				case 0x4d:	//m
					//-	carrier, rr
					curinst[7] = (curinst[7]&0xf0)|((curinst[7]-1)&0x0f);
					printf(".carrier.rr=%d\n", curinst[7]&0x0f);
					bkeyon = 1;
					break;
				case 0xbc:	//,
					//+	carrier, rr
					curinst[7] = (curinst[7]&0xf0)|((curinst[7]+1)&0x0f);
					printf(".carrier.rr=%d\n", curinst[7]&0x0f);
					bkeyon = 1;
					break;
			}
		}

		//
		if((brkey>=0 || binit || bkeyon || bkeyoff) && keyon){
			if(bkeyoff)
				WriteOplOpllCsbit(csbitab, 0, 0x20+rch, 0x00|((fnumber>>8)&0x0f));
			else
				WriteOplOpllCsbit(csbitab, 0, 0x20+rch, 0x20|((fnumber>>8)&0x0f));
			keyon = 0;
			WaitMs(50);
		}

		//
		if(bblock){
			block += bblock;
			if(block<0)
				block = 0;
			else
			if(block>7)
				block = 7;
			printf(".block=%d\n", block);
		}
		//
		if(brkey>=0){
			rkey = brkey;
			printf(".rhythm=%s\n", srhythm[rkey]);
			switch(rkey){
				case 0:	rinst = 17;	rch = 7;	break;	//hh
				case 1:	rinst = 18;	rch = 8;	break;	//top-cym
				case 2:	rinst = 18;	rch = 8;	break;	//tom
				case 3:	rinst = 17;	rch = 7;	break;	//sd
				default:	rinst = 16;	rch = 6;	break;	//bd
			}
			memcpy(curinst, insttbl[0][rinst], sizeof(curinst));
			keyon = 1;
		}
		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			if(InitOpllInst())
				return 1;
			//
			for(i=0x00; i<0x40; i++)
				WriteOplOpllCsbit(csbitab, 0, i, 0x00);
			WriteOplOpllCsbit(csbitb, 0, 0x0e, 0x20);
			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0xff);
//			WriteOplOpllCsbit(csbitab, 0, 0x0f, 0x04+0x02);
//			WriteOplOpllCsbit(csbitab, 0, 0x0f,0x10+0x01);	//bd
//			WriteOplOpllCsbit(csbitab, 0, 0x0f,0x02+0x01);	//sd
			WriteOplOpllCsbit(csbitab, 0, 0x0f,0x00);
		}
		//
		if(bkeyon){
			int f = 0;
			printf(".keyon, %d=", rinst);
//			curinst[3] &= ~0x18;
			const int regnum[2][8] = {
				{ 2, 0, 2, 3, 2, 4, 2, 6 },
				{ 3, 1, 2, 3, 2, 5, 2, 7 },
			};				
			for(i=0; i<8; i++){
				switch(rkey){
					case 0:	WriteOplOpllCsbit(csbita, 0, i, curinst[regnum[0][i]]);	break;	//hh
					case 1:	WriteOplOpllCsbit(csbita, 0, i, curinst[regnum[1][i]]);	break;	//top-cym
					case 2:	WriteOplOpllCsbit(csbita, 0, i, curinst[regnum[0][i]]);	break;	//tom
					case 3:	WriteOplOpllCsbit(csbita, 0, i, curinst[regnum[1][i]]);	break;	//sd
					default:	WriteOplOpllCsbit(csbita, 0, i, curinst[i]);	break;	//bd
				}
				printf("0x%02x", curinst[i]);
				if(curinst[i]!=insttbl[0][rinst][i])
					f++;
				if(i<7)
					printf(",");
			}
			printf(", %s\n", f?"ne":"eq");
			WriteOplOpllCsbit(csbita, 0, 0x30+rch, (0<<4)|0x0);
			WriteOplOpllCsbit(csbitb, 0, 0x30+6, (0xf<<4)|0xf);
			WriteOplOpllCsbit(csbitb, 0, 0x30+7, (0xf<<4)|0xf);
			WriteOplOpllCsbit(csbitb, 0, 0x30+8, (0xf<<4)|0xf);
			switch(rkey){
				case 0:	WriteOplOpllCsbit(csbitb, 0, 0x30+rch, (0x0<<4)|0xf);	break;	//hh
				case 1:	WriteOplOpllCsbit(csbitb, 0, 0x30+rch, (0xf<<4)|0x0);	break;	//top-cym
				case 2:	WriteOplOpllCsbit(csbitb, 0, 0x30+rch, (0x0<<4)|0xf);	break;	//tom
				case 3:	WriteOplOpllCsbit(csbitb, 0, 0x30+rch, (0xf<<4)|0x0);	break;	//sd
				default:	WriteOplOpllCsbit(csbitb, 0, 0x30+rch, (0xf<<4)|0x0);	break;	//bd
			}
			fnumber = (0<<9)|0x0000;
			WriteOplOpllCsbit(csbitab, 0, 0x10+7, fnumber&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x20+7, 0x00|((fnumber>>8)&0x0f));
			fnumber = (0<<9)|0x0000;
			WriteOplOpllCsbit(csbitab, 0, 0x10+8, fnumber&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x20+8, 0x00|((fnumber>>8)&0x0f));
			fnumber = (block<<9)|0x0120;
			WriteOplOpllCsbit(csbitab, 0, 0x10+rch, fnumber&0xff);
			WriteOplOpllCsbit(csbitab, 0, 0x20+rch, 0x10|((fnumber>>8)&0x0f));
			WaitMs(20);
			keyon = 1;
		}
	}

	return 0;
}
#endif

#if 0
int OplInst(void)
{
	//
	const unsigned int csbita = (1<<0);	//opll
	const int fnuma = 0x0b4a;
	const unsigned int csbitb = (1<<2);	//opl/opl2/opl3
	const int fnumb = fnuma<<1;
	const unsigned int csbitab = csbita|csbitb;
	const char *srhythm[5] = { "hh", "top-cym", "tom", "sd", "bd" };
	//
	int i, regbd, mode, type, test, inst, oct, keyon;
	struct PcKeySence key;
	unsigned char curinsta[8];
	unsigned char curinstb[8], currinstb[8];

	//
	regbd = 0xc0;
	mode = 0;
	type = 0;
	test = 0;
	inst = 0;
	oct = 0;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int bmode = 0, btype = 0, btest = 0, binst = -1, binit = 0, bkeyon = 0, bkeyoff = 0, boct = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;

			case 0xf3:	case 0xf4:	//半角/全角
				if(key.ctrl_state&0x10)
					binst = 0;
				break;

			case 0x31:	//1
				if(key.ctrl_state&0x10)
					binst = 1;
				break;
			case 0x32:	//2
				if(key.ctrl_state&0x10)
					binst = 2;
				break;
			case 0x33:	//3
				if(key.ctrl_state&0x10)
					binst = 3;
				break;
			case 0x34:	//4
				if(key.ctrl_state&0x10)
					binst = 4;
				break;

			case 0x08:	//backspace
				btest = 1;
				break;

			case 0x09:	//tab
				bmode = 1;
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0xf0:	//capslock
				btype = 1;
				break;

			case 0x20:	//space
				if(keyon)
					bkeyoff = 1;
				else
					bkeyon = 1;
				break;

			case 0x26:	//↑
				boct = +1;
				break;
			case 0x28:	//↓
				boct = -1;
				break;
		}

		//
		if(type==0){
			//key
			switch(key.key_code){
				case 0x41:	//a
					//opll, am
					curinsta[1] ^= (1<<7);
					bkeyon = 1;
					break;
				case 0x53:	//s
					//opl, am
					curinstb[1] ^= (1<<7);
					bkeyon = 1;
					break;
				case 0x44:	//d
					//opl, dam
					regbd ^= (1<<7);
					bkeyon = 1;
					break;

				case 0x56:	//v
					//opll, vib
					curinsta[1] ^= (1<<6);
					bkeyon = 1;
					break;
				case 0x42:	//b
					//opl, vib
					curinstb[1] ^= (1<<6);
					bkeyon = 1;
					break;
				case 0x4e:	//n
					//opl, dvb
					regbd ^= (1<<6);
					bkeyon = 1;
					break;
			}
		} else {
			//edit
			if((~key.ctrl_state)&0x10){
				switch(key.key_code){
					case 0x31:	//1
						//off/on	modulator, am
						currinstb[0] ^= 0x80;
						printf(".modulator.am=%s\n", (currinstb[0]&0x80)?"on":"off");
						bkeyon = 1;
						break;
					case 0x32:	//2
						//off/on	modulator, vib
						currinstb[0] ^= 0x40;
						printf(".modulator.vib=%s\n", (currinstb[0]&0x40)?"on":"off");
						bkeyon = 1;
						break;
					case 0x33:	//3
						//percussive/sustained	modulator, egtyp
						currinstb[0] ^= 0x20;
						printf(".modulator.egtyp=%s\n", (currinstb[0]&0x20)?"sustained":"percussive");
						bkeyon = 1;
						break;
					case 0x34:	//4
						//0/1	modulator, ksr
						currinstb[0] ^= 0x10;
						printf(".modulator.ksr=%s\n", (currinstb[0]&0x10)?"1":"0");
						bkeyon = 1;
						break;
					case 0x35:	//5
						//-	modulator, multi
						i = (currinstb[0]-1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i--;
						currinstb[0] = (currinstb[0]&0xf0)|(i&0x0f);
						printf(".modulator.multi=%d\n", currinstb[0]&0x0f);
						bkeyon = 1;
						break;
					case 0x36:	//6
						//+	modulator, multi
						i = (currinstb[0]+1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i++;
						currinstb[0] = (currinstb[0]&0xf0)|(i&0x0f);
						printf(".modulator.multi=%d\n", currinstb[0]&0x0f);
						bkeyon = 1;
						break;
					case 0x37:	//7
						//off/on	carrier, am
						currinstb[1] ^= 0x80;
						printf(".carrier.am=%s\n", (currinstb[1]&0x80)?"on":"off");
						bkeyon = 1;
						break;
					case 0x38:	//8
						//off/on	carrier, vib
						currinstb[1] ^= 0x40;
						printf(".carrier.vib=%s\n", (currinstb[1]&0x40)?"on":"off");
						bkeyon = 1;
						break;
					case 0x39:	//9
						//percussive/sustained	carrier, egtyp
						currinstb[1] ^= 0x20;
						printf(".carrier.egtyp=%s\n", (currinstb[1]&0x20)?"sustained":"percussive");
						bkeyon = 1;
						break;
					case 0x30:	//0
						//0/1	carrier, ksr
						currinstb[1] ^= 0x10;
						printf(".carrier.ksr=%s\n", (currinstb[1]&0x10)?"1":"0");
						bkeyon = 1;
						break;
					case 0xbd:	//-
						//-	carrier, multi
						i = (currinstb[1]-1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i--;
						currinstb[1] = (currinstb[1]&0xf0)|(i&0x0f);
						printf(".carrier.multi=%d\n", currinstb[1]&0x0f);
						bkeyon = 1;
						break;
					case 0xde:	//^
						//+	carrier, multi
						i = (currinstb[1]+1)&0x0f;
						if(i==0xb || i==0xd || i==0xf)
							i++;
						currinstb[1] = (currinstb[1]&0xf0)|(i&0x0f);
						printf(".carrier.multi=%d\n", currinstb[1]&0x0f);
						bkeyon = 1;
						break;

					case 0x51:	//q
						//-	modulator, ksl
						currinstb[2] = ((currinstb[2]-0x40)&0xc0)|(currinstb[2]&0x3f);
						printf(".modulator.ksl=%d\n", (currinstb[2]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x57:	//w
						//+	modulator, ksl
						currinstb[2] = ((currinstb[2]+0x40)&0xc0)|(currinstb[2]&0x3f);
						printf(".modulator.ksl=%d\n", (currinstb[2]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x45:	//e
						//-	modulator, tl
						currinstb[2] = (currinstb[2]&0xc0)|((currinstb[2]-1)&0x3f);
						printf(".modulator.tl=%d\n", currinstb[2]&0x3f);
						bkeyon = 1;
						break;
					case 0x52:	//r
						//+	modulator, tl
						currinstb[2] = (currinstb[2]&0xc0)|((currinstb[2]+1)&0x3f);
						printf(".modulator.tl=%d\n", currinstb[2]&0x3f);
						bkeyon = 1;
						break;
					case 0x54:	//t
						//-	carrier, ksl
						currinstb[3] = ((currinstb[3]-0x40)&0xc0)|(currinstb[3]&0x3f);
						printf(".carrier.ksl=%d\n", (currinstb[3]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x59:	//y
						//+	carrier, ksl
						currinstb[3] = ((currinstb[3]+0x40)&0xc0)|(currinstb[3]&0x3f);
						printf(".carrier.ksl=%d\n", (currinstb[3]>>6)&0x03);
						bkeyon = 1;
						break;
					case 0x55:	//u
						//normal/half	carrier, dc
						currinstb[3] ^= 0x10;
						printf(".carrier.dc=%s\n", (currinstb[3]&0x10)?"half":"normal");
						bkeyon = 1;
						break;
					case 0x49:	//i
						//normal/half	modulator, dm
						currinstb[3] ^= 0x08;
						printf(".modulator.dc=%s\n", (currinstb[3]&0x08)?"half":"normal");
						bkeyon = 1;
						break;
					case 0x4f:	//o
						//-	fb
						currinstb[3] = (currinstb[3]&0xf8)|((currinstb[3]-1)&0x07);
						printf(".fb=%d\n", currinstb[3]&0x07);
						bkeyon = 1;
						break;
					case 0x50:	//p
						//+	fb
						currinstb[3] = (currinstb[3]&0xf8)|((currinstb[3]+1)&0x07);
						printf(".fb=%d\n", currinstb[3]&0x07);
						bkeyon = 1;
						break;

					case 0x41:	//a
						//-	modulator, ar
						currinstb[4] = ((currinstb[4]-0x10)&0xf0)|(currinstb[4]&0x0f);
						printf(".modulator.ar=%d\n", (currinstb[4]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x53:	//s
						//+	modulator, ar
						currinstb[4] = ((currinstb[4]+0x10)&0xf0)|(currinstb[4]&0x0f);
						printf(".modulator.ar=%d\n", (currinstb[4]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x44:	//d
						//-	carrier, ar
						currinstb[5] = ((currinstb[5]-0x10)&0xf0)|(currinstb[5]&0x0f);
						printf(".carrier.ar=%d\n", (currinstb[5]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x46:	//f
						//+	carrier, ar
						currinstb[5] = ((currinstb[5]+0x10)&0xf0)|(currinstb[5]&0x0f);
						printf(".carrier.ar=%d\n", (currinstb[5]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x47:	//g
						//-	modulator, dr
						currinstb[4] = (currinstb[4]&0xf0)|((currinstb[4]-1)&0x0f);
						printf(".modulator.dr=%d\n", currinstb[4]&0x0f);
						bkeyon = 1;
						break;
					case 0x48:	//h
						//+	modulator, dr
						currinstb[4] = (currinstb[4]&0xf0)|((currinstb[4]+1)&0x0f);
						printf(".modulator.dr=%d\n", currinstb[4]&0x0f);
						bkeyon = 1;
						break;
					case 0x4a:	//j
						//-	carrier, dr
						currinstb[5] = (currinstb[5]&0xf0)|((currinstb[5]-1)&0x0f);
						printf(".carrier.dr=%d\n", currinstb[5]&0x0f);
						bkeyon = 1;
						break;
					case 0x4b:	//k
						//+	carrier, dr
						currinstb[5] = (currinstb[5]&0xf0)|((currinstb[5]+1)&0x0f);
						printf(".carrier.dr=%d\n", currinstb[5]&0x0f);
						bkeyon = 1;
						break;

					case 0x5a:	//z
						//-	modulator, sl
						currinstb[6] = ((currinstb[6]-0x10)&0xf0)|(currinstb[6]&0x0f);
						printf(".modulator.sl=%d\n", (currinstb[6]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x58:	//x
						//+	modulator, sl
						currinstb[6] = ((currinstb[6]+0x10)&0xf0)|(currinstb[6]&0x0f);
						printf(".modulator.sl=%d\n", (currinstb[6]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x43:	//c
						//-	carrier, sl
						currinstb[7] = ((currinstb[7]-0x10)&0xf0)|(currinstb[7]&0x0f);
						printf(".carrier.sl=%d\n", (currinstb[7]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x56:	//v
						//+	carrier, sl
						currinstb[7] = ((currinstb[7]+0x10)&0xf0)|(currinstb[7]&0x0f);
						printf(".carrier.sl=%d\n", (currinstb[7]>>4)&0x0f);
						bkeyon = 1;
						break;
					case 0x42:	//b
						//-	modulator, rr
						currinstb[6] = (currinstb[6]&0xf0)|((currinstb[6]-1)&0x0f);
						printf(".modulator.rr=%d\n", currinstb[6]&0x0f);
						bkeyon = 1;
						break;
					case 0x4e:	//n
						//+	modulator, rr
						currinstb[6] = (currinstb[6]&0xf0)|((currinstb[6]+1)&0x0f);
						printf(".modulator.rr=%d\n", currinstb[6]&0x0f);
						bkeyon = 1;
						break;
					case 0x4d:	//m
						//-	carrier, rr
						currinstb[7] = (currinstb[7]&0xf0)|((currinstb[7]-1)&0x0f);
						printf(".carrier.rr=%d\n", currinstb[7]&0x0f);
						bkeyon = 1;
						break;
					case 0xbc:	//,
						//+	carrier, rr
						currinstb[7] = (currinstb[7]&0xf0)|((currinstb[7]+1)&0x0f);
						printf(".carrier.rr=%d\n", currinstb[7]&0x0f);
						bkeyon = 1;
						break;
				}
			}
		}

		//
		if((bmode || btype || btest || binst>=0 || boct || binit || bkeyon || bkeyoff) && keyon){
			keyon = 0;
			if(type){
				//opll, rhythm
				WriteOplOpllCsbit(csbita, 0, 0x0e, 0x20);
				//opl, rhythm
				WriteOplOpllCsbit(csbitb, 0, 0xbd, (regbd&0xc0)|0x20);
			} else {
				//opll
				WriteOplOpllCsbit(csbita, 0, 0x20, 0x00|((fnuma>>8)&0x0f));
				//opl
				WriteOplOpllCsbit(csbitb, 0, 0xb0, 0x00|((fnumb>>8)&0x0f));
			}
			WaitMs(50);
		}

		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%d,%s\n", mode, mode?"key":"edit");
		}
		//
		if(btype){
			type = (type+1)%2;
			const char *stype[2] = { "ch1", "rhythm" };
			printf(".type=%d,%s\n", type, stype[type]);
		}
		//
		if(btest){
			test = (test+1)%4;
			printf(".test=%d\n", test);
		}
		//
		if(binst>=0){
			inst = binst;
			printf(".inst=%s\n", srhythm[inst]);
			memset(currinstb, 0x00, sizeof(currinstb));
			switch(inst){
				case 0:
				case 3:
					//hh
					currinstb[0] = insttbl[0][17][0];
					currinstb[2] = insttbl[0][17][2];
					currinstb[4] = insttbl[0][17][4];
					currinstb[6] = insttbl[0][17][6];
					//sd
					currinstb[1] = insttbl[0][17][1];
					currinstb[3] = insttbl[0][17][3];
					currinstb[5] = insttbl[0][17][5];
					currinstb[7] = insttbl[0][17][7];
					break;
				case 1:
				case 2:
					//top-cym
					currinstb[1] = insttbl[0][18][1];
					currinstb[3] = insttbl[0][18][3];
					currinstb[5] = insttbl[0][18][5];
					currinstb[7] = insttbl[0][18][7];
					//tom
					currinstb[0] = insttbl[0][18][0];
					currinstb[2] = insttbl[0][18][2];
					currinstb[4] = insttbl[0][18][4];
					currinstb[6] = insttbl[0][18][6];
					break;
				case 4:
					//bd
					currinstb[0] = insttbl[0][16][0];
					currinstb[1] = insttbl[0][16][1];
					currinstb[2] = insttbl[0][16][2];
					currinstb[3] = insttbl[0][16][3];
					currinstb[4] = insttbl[0][16][4];
					currinstb[5] = insttbl[0][16][5];
					currinstb[6] = insttbl[0][16][6];
					currinstb[7] = insttbl[0][16][7];
					break;
			}
			bkeyon = 1;
		}
		//
		if(boct){
			int o = oct+boct;
			if(o<-7)
				o = -7;
			else
			if(o>+7)
				o = +7;
			if(o!=oct){
				oct = o;
				printf(".oct=%d\n", oct);
			}
		}
		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			if(InitOpllInst())
				return 1;
#if 0
			memcpy(curinsta, insttbl[0][0], sizeof(curinsta));
#else
//			memcpy(curinsta, "\x00\x21\x00\x00\x00\xf0\x00\x0f", sizeof(curinsta));	//sin
			memcpy(curinsta, "\x01\x21\x28\x07\xf0\xf0\x00\x07", sizeof(curinsta));	//saw
#endif
//			memcpy(curinstb, "\x00\x21\x00\x00\x00\xf0\x00\x0f", sizeof(curinstb));	//sin
			memcpy(curinstb, "\x01\x21\x28\x07\xf0\xf0\x00\x07", sizeof(curinstb));	//saw
			memset(currinstb, 0x00, sizeof(currinstb));
			//opll
			for(i=0; i<0x40; i++)
				WriteOplOpllCsbit(csbita, 0, i, 0x00);
			WriteOplOpllCsbit(csbita, 0, 0x0e, 0x20);
#if 1
			//opl/opl2
			for(i=0; i<0x100; i++)
				WriteOplOpllCsbit(csbitb, 0, i, 0x00);
			WriteOplOpllCsbit(csbitb, 0, 0xbd, (regbd&0xc0)|0x20);
			//
			unsigned int addr = ((0>>8)&3)*2;
			WriteIcCsbit(csbita, addr, 0x0f&0xff);
			WriteIcCsbit(csbitb, addr, 0x001&0xff);
			WaitUs(11);
			WriteIcCsbit(csbitab, addr+1, 0xff&0xff);
			WaitUs(24);
			//
			addr = ((0>>8)&3)*2;
			WriteIcCsbit(csbita, addr, 0x0f&0xff);
			WriteIcCsbit(csbitb, addr, 0x001&0xff);
			WaitUs(11);
////			WriteIcCsbit(csbitb, addr+1, (0x20+0x80+0x04+0x01)&0xff);	//opl2, sd/top-cym/hh
////			WaitUs(32);
////			WriteIcCsbit(csbita, addr+1, (     0x02+0x04+0x01)&0xff);	//opll, sd/top-cym/hh
#if 1
			WriteIcCsbit(csbitb, addr+1, (0x20+0x80)&0xff);			//opl2, bd/sd/tom, sd/top-cym/hh
			WaitUs(32);
			WriteIcCsbit(csbita, addr+1, (     0x02)&0xff);			//opll, bd/sd/tom, sd/top-cym/hh
#endif
#if 0
			WriteIcCsbit(csbitb, addr+1, (0x20+0x04)&0xff);			//opl2, sd/top-cym/hh
			WaitUs(32);
			WriteIcCsbit(csbita, addr+1, (     0x04)&0xff);			//opll, sd/top-cym/hh
#endif
#if 0
			WriteIcCsbit(csbitb, addr+1, (0x20)&0xff);
			WaitUs(32);
			WriteIcCsbit(csbita, addr+1, (0x00)&0xff);
#endif
			WaitUs(24);
#else
			//opl3
			for(i=0; i<0x200; i++)
				WriteOplOpllCsbit(csbitb, 0, i, 0x00);
			WriteOplOpllCsbit(csbitb, 0, 0xbd, (regbd&0xc0)|0x20);
			//
			WriteOplOpllCsbit(csbitb, 0, 0x001, 0xff);
			WriteOplOpllCsbit(csbitb, 0, 0x001, 0x00);
			//
			unsigned int addr = ((0>>8)&3)*2;
			WriteIcCsbit(csbita, addr, 0x0f&0xff);
			WriteIcCsbit(csbitb, addr+2, 0x101&0xff);
			WaitUs(11);
			WriteIcCsbit(csbitab, addr+1, 0xff&0xff);
			WaitUs(24);
			//
			addr = ((0>>8)&3)*2;
			WriteIcCsbit(csbita, addr, 0x0f&0xff);
			WriteIcCsbit(csbitb, addr+2, 0x101&0xff);
			WaitUs(11);
			WriteIcCsbit(csbitab, addr+1, 0x00&0xff);
			WaitUs(24);
#endif
		}
		//
		if(bkeyon){
			if(type){
				int f = 0;
				printf(".keyon opl_rhythm, dam=%d,dvb=%d, ", (regbd>>7)&1, (regbd>>6)&1);
				for(i=0; i<8; i++){
					printf("0x%02x", currinstb[i]);
					switch(inst){
						case 0:
						case 3:
							//hh, sd
							if(currinstb[i]!=insttbl[0][17][i])
								f++;
							break;
						case 1:
						case 2:
							//top-cym, tom
							if(currinstb[i]!=insttbl[0][18][i])
								f++;
							break;
						case 4:
							//bd
							if(currinstb[i]!=insttbl[0][16][i])
								f++;
							break;
					}
					if(i<7)
						printf(",");
				}
				printf("#%s, %s\n", srhythm[inst], f?"ne":"eq");

				//rhythm, opll
				WriteOplOpllCsbit(csbita, 0, 0x36, 0x00);
				WriteOplOpllCsbit(csbita, 0, 0x37, 0x00);
				WriteOplOpllCsbit(csbita, 0, 0x38, 0x00);
				//
				int blch7 = 0x02 + oct, fnch7 = 0x0120;
				int blch8 = 0x02 + oct, fnch8 = 0x0150;
				int blch9 = 0x00 + oct, fnch9 = 0x01c0;
				while(blch7<0){
					fnch7 /= 2;
					if(fnch7==0)
						fnch7 = 0x001;
					blch7++;
				}
				while(blch7>7){
					fnch7 *= 2;
					if(fnch7>0x01ff)
						fnch7 = 0x01ff;
					blch7--;
				}
				while(blch8<0){
					fnch8 /= 2;
					if(fnch8==0)
						fnch8 = 0x001;
					blch8++;
				}
				while(blch8>7){
					fnch8 *= 2;
					if(fnch8>0x01ff)
						fnch8 = 0x01ff;
					blch8--;
				}
				while(blch9<0){
					fnch9 /= 2;
					if(fnch9==0)
						fnch9 = 0x001;
					blch9++;
				}
				while(blch9>7){
					fnch9 *= 2;
					if(fnch9>0x01ff)
						fnch9 = 0x01ff;
					blch9--;
				}
				//
				fnch7 = ((blch7&7)<<9) | (fnch7&0x01ff);
				WriteOplOpllCsbit(csbita, 0, 0x16, fnch7&0xff);
				WriteOplOpllCsbit(csbita, 0, 0x26, (fnch7>>8)&0x0f);
				fnch8 = ((blch8&7)<<9) | (fnch8&0x01ff);
				WriteOplOpllCsbit(csbita, 0, 0x17, fnch8&0xff);
				WriteOplOpllCsbit(csbita, 0, 0x27, (fnch8>>8)&0x0f);
				fnch9 = ((blch9&7)<<9) | (fnch9&0x01ff);
				WriteOplOpllCsbit(csbita, 0, 0x18, fnch9&0xff);
				WriteOplOpllCsbit(csbita, 0, 0x28, (fnch9>>8)&0x0f);

				//rhythm, opl
				WriteOplOpllCsbit(csbitb, 0, 0x08, 0x40);
				WriteOplOpllCsbit(csbitb, 0, 0xbd, (regbd&0xc0)|0x20);
				//hh
				if(inst==0 || inst==3)
					WriteOplOpllCsbit(csbitb, 0, 0x31, currinstb[0]);		//am,vib,eg-typ,ksr,multi
				else
					WriteOplOpllCsbit(csbitb, 0, 0x31, insttbl[0][17][0]);
				WriteOplOpllCsbit(csbitb, 0, 0x51, currinstb[2]&0xc0);		//ksl,tl
				WriteOplOpllCsbit(csbitb, 0, 0x71, currinstb[4]);			//ar,dr
				WriteOplOpllCsbit(csbitb, 0, 0x91, currinstb[6]);			//sl,rr
				WriteOplOpllCsbit(csbitb, 0, 0xf1, (currinstb[3]>>3)&1);	//wave select
				//top-cym
				if(inst==1 || inst==2)
					WriteOplOpllCsbit(csbitb, 0, 0x35, currinstb[1]);
				else
					WriteOplOpllCsbit(csbitb, 0, 0x35, insttbl[0][18][1]);
				WriteOplOpllCsbit(csbitb, 0, 0x55, currinstb[3]&0xc0);
				WriteOplOpllCsbit(csbitb, 0, 0x75, currinstb[5]);
				WriteOplOpllCsbit(csbitb, 0, 0x95, currinstb[7]);
				WriteOplOpllCsbit(csbitb, 0, 0xf5, (currinstb[3]>>4)&1);
				//tom
				if(inst==1 || inst==2)
					WriteOplOpllCsbit(csbitb, 0, 0x32, currinstb[0]);
				else
					WriteOplOpllCsbit(csbitb, 0, 0x32, insttbl[0][18][0]);
				WriteOplOpllCsbit(csbitb, 0, 0x52, currinstb[2]&0xc0);
				WriteOplOpllCsbit(csbitb, 0, 0x72, currinstb[4]);
				WriteOplOpllCsbit(csbitb, 0, 0x92, currinstb[6]);
				WriteOplOpllCsbit(csbitb, 0, 0xf2, (currinstb[3]>>3)&1);
				//sd
				if(inst==0 || inst==3)
					WriteOplOpllCsbit(csbitb, 0, 0x34, currinstb[1]);
				else
					WriteOplOpllCsbit(csbitb, 0, 0x34, insttbl[0][17][1]);
				WriteOplOpllCsbit(csbitb, 0, 0x54, currinstb[3]&0xc0);
				WriteOplOpllCsbit(csbitb, 0, 0x74, currinstb[5]);
				WriteOplOpllCsbit(csbitb, 0, 0x94, currinstb[7]);
				WriteOplOpllCsbit(csbitb, 0, 0xf4, (currinstb[3]>>4)&1);
				//bd
				WriteOplOpllCsbit(csbitb, 0, 0x30, currinstb[0]);
				WriteOplOpllCsbit(csbitb, 0, 0x33, currinstb[1]);
				WriteOplOpllCsbit(csbitb, 0, 0x50, currinstb[2]);
				WriteOplOpllCsbit(csbitb, 0, 0x53, currinstb[3]&0xc0);
				WriteOplOpllCsbit(csbitb, 0, 0x70, currinstb[4]);
				WriteOplOpllCsbit(csbitb, 0, 0x73, currinstb[5]);
				WriteOplOpllCsbit(csbitb, 0, 0x90, currinstb[6]);
				WriteOplOpllCsbit(csbitb, 0, 0x93, currinstb[7]);
				WriteOplOpllCsbit(csbitb, 0, 0xf0, (currinstb[3]>>3)&1);
				WriteOplOpllCsbit(csbitb, 0, 0xf3, (currinstb[3]>>4)&1);
				//ch7
				i = fnch7<<1;
				WriteOplOpllCsbit(csbitb, 0, 0xa6, i&0xff);
				WriteOplOpllCsbit(csbitb, 0, 0xb6, (i>>8)&0x1f);
				WriteOplOpllCsbit(csbitb, 0, 0xc6, ((currinstb[3]&7)<<1)|((currinstb[3]&0x20)>>5));	//fb,c
				//ch8
				i = fnch8<<1;
				WriteOplOpllCsbit(csbitb, 0, 0xa7, i&0xff);
				WriteOplOpllCsbit(csbitb, 0, 0xb7, (i>>8)&0x1f);
				WriteOplOpllCsbit(csbitb, 0, 0xc7, ((currinstb[3]&7)<<1)|((currinstb[3]&0x20)>>5));
				//ch9
				i = fnch9<<1;
				WriteOplOpllCsbit(csbitb, 0, 0xa8, i&0xff);
				WriteOplOpllCsbit(csbitb, 0, 0xb8, (i>>8)&0x1f);
				WriteOplOpllCsbit(csbitb, 0, 0xc8, ((currinstb[3]&7)<<1)|((currinstb[3]&0x20)>>5));

				//
				unsigned int addr = ((0>>8)&3)*2;
				WriteIcCsbit(csbita, addr, 0x0e&0xff);
				WriteIcCsbit(csbitb, addr, 0xbd&0xff);
				WaitUs(11);
#if 1
				WriteIcCsbit(csbitb, addr+1, (regbd|0x20|(1<<inst))&0xff);
				WaitUs(32);
				WriteIcCsbit(csbita, addr+1, (regbd|0x20|(1<<inst))&0xff);
#else
				WriteIcCsbit(csbitab, addr+1, (regbd|0x20|(1<<inst))&0xff);
#endif
				WaitUs(24);
			} else {
				printf(".keyon opll, am=%d,vib=%d\n", (curinsta[1]>>7)&1, (curinsta[1]>>6)&1);
				printf(".keyon opl,  am=%d,vib=%d, dam=%d,dvb=%d\n", (curinstb[1]>>7)&1, (curinstb[1]>>6)&1, (regbd>>7)&1, (regbd>>6)&1);
				//opll
				for(i=0; i<8; i++)
					WriteOplOpllCsbit(csbita, 0, i, curinsta[i]);
				WriteOplOpllCsbit(csbita, 0, 0x30, (0<<4)|0x0);
				WriteOplOpllCsbit(csbita, 0, 0x10, fnuma&0xff);
				//opl
				WriteOplOpllCsbit(csbitb, 0, 0x08, 0x40);
				WriteOplOpllCsbit(csbitb, 0, 0xbd, (regbd&0xc0)|0x00);
				WriteOplOpllCsbit(csbitb, 0, 0x20, curinstb[0]);
				WriteOplOpllCsbit(csbitb, 0, 0x23, curinstb[1]);
				WriteOplOpllCsbit(csbitb, 0, 0x40, curinstb[2]);
				WriteOplOpllCsbit(csbitb, 0, 0x43, (curinstb[3]&0xc0)|0x00);
				WriteOplOpllCsbit(csbitb, 0, 0x60, curinstb[4]);
				WriteOplOpllCsbit(csbitb, 0, 0x63, curinstb[5]);
				WriteOplOpllCsbit(csbitb, 0, 0x80, curinstb[6]);
				WriteOplOpllCsbit(csbitb, 0, 0x83, curinstb[7]);
				WriteOplOpllCsbit(csbitb, 0, 0xc0, ((curinstb[3]&7)<<1)|((curinstb[3]&0x20)>>5));	//fb/c
				WriteOplOpllCsbit(csbitb, 0, 0xe0, (curinstb[3]>>3)&1);	//modulator:wave select
				WriteOplOpllCsbit(csbitb, 0, 0xe3, (curinstb[3]>>4)&1);	//carrier:wave select
				WriteOplOpllCsbit(csbitb, 0, 0xa0, fnumb&0xff);
				//
#if 1
				unsigned int addr = ((0>>8)&3)*2;
				int data, datb;
				WriteIcCsbit(csbita, addr, 0x20&0xff);
				WriteIcCsbit(csbitb, addr, 0xb0&0xff);
				WaitUs(11);
				data = 0x10|((fnuma>>8)&0x0f);
				datb = 0x20|((fnumb>>8)&0x1f);
				addr++;
				WriteByteCsbit(csbitb, addr, datb);
				WaitUs(32);
				WriteByteCsbit(csbita, addr, data);
				WaitUs(24);
#else
				WriteOplOpllCsbit(csbita, 0, 0x20, 0x10|((fnuma>>8)&0x0f));
				WriteOplOpllCsbit(csbitb, 0, 0xb0, 0x20|((fnumb>>8)&0x1f));
#endif
			}
			WaitMs(20);
			keyon = 1;
		}
	}
}
#endif

#if 0
void WriteOpl(int cs, unsigned int addr, int reg, int data)
{
	//
	WaitUs(1);
	switch((reg>>8)&0xff){
		case 0:
			//fm
			break;
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x01, 0x00);
			break;
		case 2:
		case 3:
			//wavetable
			if(1)
				ChkStatusReg(cs, addr, 0x03, 0x00);		//ymf268/opl4
			else
				ChkStatusReg(cs, addr+4, 0x03, 0x00);		//opl4-ml/opl4-ml2
			break;
		case 4:
			ChkStatusReg(cs, addr+8, 0x80, 0x00);	
			break;
		default:
			return;			
	}	
	WaitUs(1);
	//
	addr += ((reg>>8)&7)*2;
	WriteIc(cs, addr, reg&0xff);
	switch(reg){
		case 0x0206:
			WaitUs(3);
			WriteIc(cs, addr+1, data&0xff);
			WaitUs(3);
			break;
		default:
			WaitUs(11);
			WriteIc(cs, addr+1, data&0xff);
			WaitUs(24);
			break;
	}
}

unsigned char ReadOpl(int cs, unsigned int addr, int reg)
{
	unsigned char data;
	//
	WaitUs(1);
	switch((reg>>8)&0xff){
		case 0:
			//fm
			break;
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x01, 0x00);
			break;
		case 2:
		case 3:
			//wavetable
			if(1)
				ChkStatusReg(cs, addr, 0x03, 0x00);		//ymf268/opl4
			else
				ChkStatusReg(cs, addr+4, 0x03, 0x00);		//opl4-ml/opl4-ml2
			break;
		case 4:
			ChkStatusReg(cs, addr+8, 0x80, 0x00);	
			break;
		default:
			return 0xff;			
	}	
	WaitUs(1);
	//
	addr += ((reg>>8)&7)*2;
	WriteIc(cs, addr, reg&0xff);
	switch(reg){
		case 0x0206:
			WaitUs(3);
			data = ReadIc(cs, addr+1);
			WaitUs(3);
			break;
		default:
			WaitUs(11);
			data = ReadIc(cs, addr+1);
			WaitUs(24);
			break;
	}
	return data;
}

unsigned char ReadOplStatus(int cs, unsigned int addr)
{
	//
	unsigned char data = ReadIc(cs, addr);
	WaitUs(24);
	return data;
}

void WriteOpl4Com(int cs, unsigned int addr, int data)
{
	//
	WaitUs(1);
	ChkStatusReg(cs, addr+7, 0x02, 0x00);
	WaitUs(1);
	//
	WriteIc(cs, addr+6, data&0xff);
	WaitUs(24);
}

unsigned char ReadOpl4Res(int cs, unsigned int addr)
{
	//
	WaitUs(1);
	ChkStatusReg(cs, addr+7, 0x01, 0x01);
	WaitUs(1);
	//
	unsigned char data = ReadIc(cs, addr+6);
	WaitUs(24);
	return data;
}

void WriteOpl4Command(int cs, unsigned int addr, unsigned char *data, int length)
{
	//
	while(length>0){
		WriteOpl4Com(cs, addr, *data++);
		length--;
	}
}

void ReadOpl4Response(int cs, unsigned int addr, unsigned char *data, int length)
{
	//
	while(length>0){
		*data++ = ReadOpl4Res(cs, addr);
		length--;
	}
}

int OplTest(void)
{
	//
	const int len = sizeof(pcm)/sizeof(pcm[0]);
	struct tagType {
		int cs, addr;		
		char *name;
	} const stype[] = {
		{ 2,  0, "ym3526@a1=0/ym3812@a1=0/y8950" },
		{ 2, +2, "ym3812@a1=1/ks8001@a1=1" },
		{ 2,  0, "ymf262/ymf289/ymf297/ymf704/ymf721" },
		{ 2,  0, "ymf278" },
		{ 0,  0, "ymf268" },
	};
	//
	int i, type, mode, keyon;
	unsigned char data, data2, data3, buf[256];
	struct PcKeySence key;

	//
	type = 3;
	mode = 0;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int btype = 0, bmode = 0, binit = 0, btoggle = 0, bmem = 0, bdet = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;

			case 0x09:	//tab
				bmode = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;

			case 0xf0:	//capslock
				btype = 1;
				break;
			case 0x44:	//d
				bdet = 1;
				break;

			case 0x4d:	//m
				bmem = 1;
				break;

			case 0x20:	//space
				btoggle = 1;
				break;
		}

		//
		if(btype){
			i = sizeof(stype)/sizeof(stype[0]);
			type = (type+1)%i;
			printf(".type=%d,[%s], ", type, stype[type].name);
			printf("oplcs=%d,opladdr=%d\n", stype[type].cs, stype[type].addr);
		}
		int oplcs = stype[type].cs, opladdr = stype[type].addr;

		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%d,%s\n", mode, mode?"square":"sin");
		}
		//
		const int wn = 384;	//384~511
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
			switch(type){
				case 3:	//278
				case 4:	//268
					//
					WriteOpl(oplcs, opladdr, 0x0401, (2<<5)|0x10);
					printf(".init_pcm\n");
					WriteOpl(oplcs, opladdr, 0x0105, 0x03);
					WriteOpl(oplcs, opladdr, 0x02f8, (3<<3)|3);	//fm
					WriteOpl(oplcs, opladdr, 0x02f9, (0<<3)|0);	//pcm
					//
					int wtnum = (type==3)?0:4;
					int base = 0x80000*wtnum;
					int addr = base + 0x0c*(wn-(wtnum?384:0));
					int wtaddr = base + 0x0c*(512-(wtnum?384:0));
					WriteOpl(oplcs, opladdr, 0x0202, (wtnum<<2)|0x01);
					//
					WriteOpl(oplcs, opladdr, 0x0203, (addr>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (addr>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, addr&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, (2<<6)|((wtaddr>>16)&0x3f));
					WriteOpl(oplcs, opladdr, 0x0206, (wtaddr>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, wtaddr&0xff);
					i = 0;
					WriteOpl(oplcs, opladdr, 0x0206, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, i&0xff);
					i = -(len/2);
					WriteOpl(oplcs, opladdr, 0x0206, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, i&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, 0x00);
					WriteOpl(oplcs, opladdr, 0x0206, 0xf0);
					WriteOpl(oplcs, opladdr, 0x0206, 0x00);
					WriteOpl(oplcs, opladdr, 0x0206, 0x0f);
					WriteOpl(oplcs, opladdr, 0x0206, 0x00);
					//
					WriteOpl(oplcs, opladdr, 0x0203, (wtaddr>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (wtaddr>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, wtaddr&0xff);
					for(i=0; i<len; i++)
						WriteOpl(oplcs, opladdr, 0x0206, pcm[i]);
					//
					WriteOpl(oplcs, opladdr, 0x0202, (wtnum<<2)|0x00);
					break;
			}
		}
		//
		if(btoggle){
			//
			keyon ^= 1;
			//
			const int tbl[][3] = {
				{ 0x000, 1,  0 },
				{ 0x200, 2, 25 },
				{ 0x100, 3, 37 },
				{ 0x300, 3, 45 },
				{ 0x080, 4, 51 },
				{ 0x180, 4, 56 },
				{ 0x280, 4, 59 },
				{ 0x380, 4, 63 },
				{ 0x040, 5, 66 },
				{ 0x0c0, 5, 68 },
				{ 0x140, 5, 71 },
			};
			const int tbllen = sizeof(tbl)/sizeof(tbl[0]);
			//
			int ch;		//1~24
			int och = 0;	//0~1
			int m = 0x20|(och?(1<<4):0);
			if(keyon){
				printf(".keyon\n");
				for(ch=1; ch<=(mode?tbllen:1); ch++){
					int n = ch-1;
					int fn = tbl[n][0];
					int oct = tbl[n][1];
					int tl = tbl[n][2];
					WriteOpl(oplcs, opladdr, 0x0220+n, ((fn&0x7f)<<1)|((wn>>8)&0x01));
					WriteOpl(oplcs, opladdr, 0x0208+n, wn&0xff);
					WaitUs(300);
					WriteOpl(oplcs, opladdr, 0x0238+n, ((oct&0xf)<<4)|((fn>>7)&7));
					WriteOpl(oplcs, opladdr, 0x0250+n, ((tl&0x7f)<<1)|1);
				}
				for(ch=1; ch<=(mode?tbllen:1); ch++){
					int n = ch-1;
					WriteOpl(oplcs, opladdr, 0x0268+n, 0x80|m);
					WaitUs(10000-70);	//(441/44100)*1e6=10000
				}
			} else {
				printf(".keyoff\n");
				for(ch=1; ch<=tbllen; ch++){
					int n = ch-1;
					WriteOpl(oplcs, opladdr, 0x0268+n, 0x40|m);
				}
			}
		}
		//
		if(bmem){
			int skip;
			WriteOpl(oplcs, opladdr, 0x0105, 0x03);	//new2=1, new=1
			data2 = ReadOpl(oplcs, opladdr, 0x0105);
			printf("$0105=%02x\n", data2);
			WriteOpl(oplcs, opladdr, 0x0202, 0x01);
			data2 = ReadOpl(oplcs, opladdr, 0x0202);
			printf("$0202=%02x\n", data2);
			//
			printf(".opl4_memory_test_start\n");
			i = 0x000000;
			WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
			WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
			WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
			for(; i<0x400000; i++){
				if((i&0x03ffff)==0)
					printf("$%06x\n", i);
				WriteOpl(oplcs, opladdr, 0x0206, 0x00);
			}
			//
			data = 0x00;
			skip = 0;
			for(i=0x000000; i<0x400000; i++){
				//
				if((i&0x03ffff)==0){
					printf("%s$%06x,", i?"\n":"", i);
					PcFlush();
					skip = 0;
				}
				data += 3;
				if(data==0)
					data++;
				if(skip==0){
					//
					WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
					data3 = ReadOpl(oplcs, opladdr, 0x0206);
					//
					WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
					WriteOpl(oplcs, opladdr, 0x0206, data);
					//
					WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
					data2 = ReadOpl(oplcs, opladdr, 0x0206);
					if(data!=data2 || data3!=0x00){
						printf("$%06x:$%02x<>$%02x,$00<>$%02x", i, data, data2, data3);
						skip = 1;
					}
				}
			}
			printf("\n");
			printf(".opl4_memory_test_end\n");
			//
			printf(".opl4_memory_test2_start\n");
			i = 0x000000;
			for(; i<0x400000; i++){
				if((i&0x03ffff)==0)
					printf("$%06x\n", i);
				if((i&0xff)==0x00){
					WriteOpl(oplcs, opladdr, 0x0403, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0402, (i>>8)&0xff);
				}
				WriteOpl(oplcs, opladdr, 0x0408, 0x00);
			}
			//
			data = 0x00;
			skip = 0;
			for(i=0x000000; i<0x400000; i++){
				//
				if((i&0x03ffff)==0){
					printf("%s$%06x,", i?"\n":"", i);
					PcFlush();
					skip = 0;
				}
				data += 3;
				if(data==0)
					data++;
				if(skip==0){
					//
					WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
					data3 = ReadOpl(oplcs, opladdr, 0x0206);
					//
					if((i&0xff)==0x00){
						WriteOpl(oplcs, opladdr, 0x0403, (i>>16)&0x3f);
						WriteOpl(oplcs, opladdr, 0x0402, (i>>8)&0xff);
					}
					WriteOpl(oplcs, opladdr, 0x0408, data);
					//
					WriteOpl(oplcs, opladdr, 0x0203, (i>>16)&0x3f);
					WriteOpl(oplcs, opladdr, 0x0204, (i>>8)&0xff);
					WriteOpl(oplcs, opladdr, 0x0205, i&0xff);
					data2 = ReadOpl(oplcs, opladdr, 0x0206);
					if(data!=data2 || data3!=0x00){
						printf("$%06x:$%02x<>$%02x,$00<>$%02x", i, data, data2, data3);
						skip = 1;
					}
				}
			}
			printf("\n");
			printf(".opl4_memory_test2_end\n");
		}
		//
		if(bdet){
			printf(".detect\n");
			ResetDevice();
			//
			data = ReadOplStatus(oplcs, opladdr);
			printf("status=%02x\n", data);
			switch(data){
				case 0x06:
					//@opl
					//@msx-audio
					//@opl2/@ks8001
					printf("opl系列/opl2\n");
#if 0
					//
					printf("$0005=%02x\n", ReadOpl(oplcs, opladdr, 0x0005));
					printf("$000f=%02x\n", ReadOpl(oplcs, opladdr, 0x000f));
					printf("$0013=%02x\n", ReadOpl(oplcs, opladdr, 0x0013));
					printf("$0014=%02x\n", ReadOpl(oplcs, opladdr, 0x0014));
					printf("$0019=%02x\n", ReadOpl(oplcs, opladdr, 0x0019));
					printf("$001a=%02x\n", ReadOpl(oplcs, opladdr, 0x001a));
					//
					for(i=0; i<0x0100; i++){
						if((i&0x0f)==0)
							printf("$%02x=", i);
						printf("%02x", ReadOpl(oplcs, opladdr, i));
						if((i&0xf)==0xf)
							printf("\n");
					}
					//
					WriteOpl(oplcs, opladdr, 0x0001, 1<<5);	//wave select enable
					for(i=0; i<0x0100; i++){
						if((i&0x0f)==0)
							printf("$%02x=", i);
						printf("%02x", ReadOpl(oplcs, opladdr, i));
						if((i&0xf)==0xf)
							printf("\n");
					}
#else
					//
					data = ReadOpl(oplcs, opladdr, 0x000f);
					data2 = ReadOpl(oplcs, opladdr, 0x001a);
					printf("$000f=%02x\n", data);
					printf("$001a=%02x\n", data2);
					if(data==0x00 && data2==0x00)
						printf(".device=@msx-audio\n");
					else
						printf(".device=@opl,@opl2\n");
#endif
					break;
				case 0x00:
					//@opl3
					//@ymf268
					//@opl4
					//@opl3-l
					//@opl3-nl_opn/@opl3-nl_opl
					//@opl4-ml
					//?opl4-ml2
					WriteOpl(oplcs, opladdr, 0x0105, 0x07);	//new3=1, new2=1, new=1
					data = ReadOplStatus(oplcs, opladdr);
					printf("status=%02x\n", data);
					data2 = ReadOpl(oplcs, opladdr, 0x0105);
					printf("$0105=%02x\n", data2);
					data3 = ReadOpl(oplcs, opladdr, 0x02f8);
					printf("$02f8=%02x\n", data3);
					if(data==0x02 || (data==0x00 && data2==0x07 && data3==0x2d)){
						printf("opl4系列\n");
						data = ReadOpl(oplcs, opladdr, 0x0202);
						printf("$0202=%02x\n", data);
						switch((data>>5)&7){
							case 1:
#if 0
								//
								for(i=0; i<0x0400; i++){
									switch(i){
										case 0x0000:	case 0x0001:	case 0x0100:	case 0x0101:
											break;
										case 0x0105:	case 0x0108:
											break;
										default:
											WriteOpl(oplcs, opladdr, i, 0x00);
											break;
									}
									if((i&0x1f)==0)
										printf("$%04x=", i);
									printf("%02x", ReadOpl(oplcs, opladdr, i));
									if((i&0x1f)==0x1f)
										printf("\n");
								}
								//
								for(i=0; i<0x0400; i++){
									switch(i){
										case 0x0000:	case 0x0001:	case 0x0100:	case 0x0101:
											break;
										case 0x0105:	case 0x0108:
											break;
										case 0x00c0:	case 0x00c1:	case 0x00c2:	case 0x00c3:	case 0x00c4:
										case 0x00c5:	case 0x00c6:	case 0x00c7:	case 0x00c8:
										case 0x01c0:	case 0x01c1:	case 0x01c2:	case 0x01c3:	case 0x01c4:
										case 0x01c5:	case 0x01c6:	case 0x01c7:	case 0x01c8:
											WriteOpl(oplcs, opladdr, i, (i&0x0f)<<4);
											break;
										default:
											WriteOpl(oplcs, opladdr, i, 0xff);
											break;
									}
									if((i&0x1f)==0)
										printf("$%04x=", i);
									printf("%02x", ReadOpl(oplcs, opladdr, i));
									if((i&0x1f)==0x1f)
										printf("\n");
								}
								//
								printf("reset\n");
								ResetDevice();
								WriteOpl(oplcs, opladdr, 0x0105, 0x07);	//new3=1, new2=1, new=1
								//
								for(i=0; i<0x0400; i++){
									if((i&0x1f)==0)
										printf("$%04x=", i);
									printf("%02x", ReadOpl(oplcs, opladdr, i));
									if((i&0x1f)==0x1f)
										printf("\n");
								}
#else
								//
								printf(".device=@ymf268,@opl4\n");
#endif
								break;
							case 2:
								//
								printf("$8000=");
								WriteOpl4Command(oplcs, opladdr, "\x80\x00\x00", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 11);
								for(i=0; i<11; i++)
									printf("%02x", buf[i]);
								printf("\n");
								//
								printf("$8001=");
								WriteOpl4Command(oplcs, opladdr, "\x80\x01\x7f", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 5);
								for(i=0; i<5; i++)
									printf("%02x", buf[i]);
								printf("\n");
								switch(buf[1]){
									case 1:
										printf(".device=@opl4-ml\n");
										break;
									case 2:
										printf(".device=?opl4-ml2\n");
										break;
									default:
										break;
								}
								//
								printf("$8002=");
								WriteOpl4Command(oplcs, opladdr, "\x80\x02\x7e", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 6);
								for(i=0; i<6; i++)
									printf("%02x", buf[i]);
								printf("\n");
								//
								printf("$8100=");
								WriteOpl4Command(oplcs, opladdr, "\x81\x00\x00", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 8);
								for(i=0; i<8; i++)
									printf("%02x", buf[i]);
								printf("\n");
								//
								printf("$8200=");
								WriteOpl4Command(oplcs, opladdr, "\x82\x00\x00", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 31);
								for(i=0; i<31; i++)
									printf("%02x", buf[i]);
								printf("\n");
								//
								printf("$8201=");
								WriteOpl4Command(oplcs, opladdr, "\x82\x01\x7f", 3);
								ReadOpl4Response(oplcs, opladdr, buf, 5);
								for(i=0; i<5; i++)
									printf("%02x", buf[i]);
								printf("\n");
								break;
						}
					} else {
						printf("opl3系列\n");
						if(data2!=0x07){
							data = ReadOpl(oplcs, opladdr, 0x00ff);
							printf("$00ff=%02x\n", data);
							if(data==0x01 || data==0x02)
								printf(".device=@opl3-nl_opn\n");
							else
								printf(".device=@opl3\n");
						} else {
#if 0
							//
							for(i=0; i<0x0100; i++){
								switch(i){
									case 0x0000:	case 0x0001:	case 0x0100:	case 0x0101:
										break;
									case 0x0105:	case 0x0108:
										break;
									default:
										WriteOpl(oplcs, opladdr, i, 0x00);
										break;
								}
								if((i&0x1f)==0)
									printf("$%04x=", i);
								printf("%02x", ReadOpl(oplcs, opladdr, i));
								if((i&0x1f)==0x1f)
									printf("\n");
							}
							//
							for(i=0; i<0x0100; i++){
								switch(i){
									case 0x0000:	case 0x0001:	case 0x0100:	case 0x0101:
										break;
									case 0x0105:	case 0x0108:
										break;
									case 0x00c0:	case 0x00c1:	case 0x00c2:	case 0x00c3:	case 0x00c4:
									case 0x00c5:	case 0x00c6:	case 0x00c7:	case 0x00c8:
									case 0x01c0:	case 0x01c1:	case 0x01c2:	case 0x01c3:	case 0x01c4:
									case 0x01c5:	case 0x01c6:	case 0x01c7:	case 0x01c8:
										WriteOpl(oplcs, opladdr, i, (i&0x0f)<<4);
										break;
									default:
										WriteOpl(oplcs, opladdr, i, 0xff);
										break;
								}
								if((i&0x1f)==0)
									printf("$%04x=", i);
								printf("%02x", ReadOpl(oplcs, opladdr, i));
								if((i&0x1f)==0x1f)
									printf("\n");
							}
							//
							printf("reset\n");
							ResetDevice();
							WriteOpl(oplcs, opladdr, 0x0105, 0x07);	//new3=1, new2=1, new=1
							//
							for(i=0; i<0x0100; i++){
								if((i&0x1f)==0)
									printf("$%04x=", i);
								printf("%02x", ReadOpl(oplcs, opladdr, i));
								if((i&0x1f)==0x1f)
									printf("\n");
							}
							//
							WriteOpl(oplcs, opladdr, 0x00f7, 0x55);
							printf("$00f7=%02x\n", ReadOpl(oplcs, opladdr, 0x00f7));
							WriteOpl(oplcs, opladdr, 0x00f7, 0xaa);
							printf("$00f7=%02x\n", ReadOpl(oplcs, opladdr, 0x00f7));
#else
							//
							printf(".device=@opl3-l,@opl3-nl_opl\n");
#endif
						}
					}
					break;
				default:
					break;
			}
		}
	}
}
#endif

#if 0
void WriteOpl(int cs, unsigned int addr, int reg, int data)
{
	//
	switch((reg>>8)&3){
		case 0:
			//fm/adpcm
			break;
		default:
			//control/ram
			ChkStatusReg(cs, addr+2, 0x80, 0x00);
			break;
	}	
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(11);
	WriteIc(cs, addr+1, data&0xff);
	WaitUs(24);
}

unsigned char ReadOpl(int cs, unsigned int addr, int reg)
{
	//
	switch((reg>>8)&3){
		case 0:
			//fm/adpcm
			break;
		default:
			//control/ram
			ChkStatusReg(cs, addr+2, 0x80, 0x00);
			break;
	}	
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(11);
	unsigned char data = ReadIc(cs, addr+1);
	WaitUs(24);
	return data;
}

unsigned char ReadOplStatus(int cs, unsigned int addr)
{
	//
	unsigned char data = ReadIc(cs, addr);
	WaitUs(24);
	return data;
}

int MsxaudioMem(void)
{
	//
//	const int cs = 2, addr = 0;	//y8950
	const int cs = 0, addr = 1<<2;	//ym2413+y8950
	const char *smode[2] = { "dram", "rom" };
	//
	int i, j, mode;
	struct PcKeySence key;
	//
	char path[256], buf[256];
	s32 fh;
	unsigned char data;
	const int buflen = sizeof(buf)/sizeof(buf[0]), memsize = 256*1024;

	//
	mode = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int binit = 0, bmode = 0, btest = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;

			case 0x09:	//tab
				bmode = 1;
				break;
			case 0x54:	//t
				btest = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;
		}

		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
#if 0
			i = 0;
			WriteOpl(cs, addr, 0x102, (i>>8)&0xff);
			WriteOpl(cs, addr, 0x103, (0?0:4)|((i>>16)&0x03));
			WriteOpl(cs, addr, 0x108, 0x01);
			WriteOpl(cs, addr, 0x108, 0x02);
			WriteOpl(cs, addr, 0x108, 0x04);
			WriteOpl(cs, addr, 0x108, 0x08);
			WriteOpl(cs, addr, 0x108, 0x10);
			WriteOpl(cs, addr, 0x108, 0x20);
			WriteOpl(cs, addr, 0x108, 0x40);
			WriteOpl(cs, addr, 0x108, 0x80);
			WriteOpl(cs, addr, 0x108, 0x01);
#else
			for(j=0; j<2; j++){
				//
				for(i=0; i<memsize; i++){
					if((i&0xff)==0){
						WriteOpl(cs, addr, 0x102, (i>>8)&0xff);
						WriteOpl(cs, addr, 0x103, (j?0:4)|((i>>16)&0x03));
					}
					WriteOpl(cs, addr, 0x108, ((i+(i>>8))&0xff)^(j?0xff:0));
				}
				//
				sprintf(path, "./_buf-%s.bin", smode[j]);
				fh = PcOpen(path, PC_WRONLY|PC_BINARY|PC_CREAT);
				if(fh==-1){
					printf(".PcOpen(%s)\n", path);
				} else {
					for(i=0; i<memsize; i++){
						if((i&0xff)==0){
							WriteOpl(cs, addr, 0x102, (i>>8)&0xff);
							WriteOpl(cs, addr, 0x103, (j?0:4)|((i>>16)&0x03));
						}
						WriteOpl(cs, addr, 0x118, i&0xff);
						buf[i&(buflen-1)] = ReadOpl(cs, addr, 0x118);
						if((i&(buflen-1))==(buflen-1))
							PcWrite(fh, buf, sizeof(buf));
					}
					PcClose(fh);
				}
			}
#endif
		}
		//
		if(bmode){
			mode ^= 1;
			printf(".mode=%d,%s\n", mode, smode[mode]);
		}
		//
		if(btest){
			printf(".test\n");
			WriteOpl(cs, addr, 0x07, 0x01);
			WriteOpl(cs, addr, 0x07, 0x00);
			//
			WriteOpl(cs, addr, 0x04, 0x00);
			WriteOpl(cs, addr, 0x04, 0x80);
			WriteOpl(cs, addr, 0x07, 0x20);
			WriteOpl(cs, addr, 0x08, mode?0x01:0x00);
			WriteOpl(cs, addr, 0x09, 0x00);
			WriteOpl(cs, addr, 0x0a, 0x00);
			i = (memsize>>(mode?5:2))-1;
			WriteOpl(cs, addr, 0x0b, i&0xff);
			WriteOpl(cs, addr, 0x0c, (i>>8)&(mode?0x1f:0xff));
			sprintf(path, "./_%s.bin", smode[mode]);
			fh = PcOpen(path, PC_WRONLY|PC_BINARY|PC_CREAT);
			if(fh==-1){
				printf(".PcOpen(%s)\n", path);
			} else {
				for(i=-2; i<memsize; i++){
					data = ReadOpl(cs, addr, 0x0f);
					WriteOpl(cs, addr, 0x04, 0x80);
					while(!(ReadOplStatus(cs, addr)&0x08)){
					}
//					ChkStatusReg(cs, addr, 0x08, 0x08);
					if(i<0)
						continue;
					buf[i&(buflen-1)] = data;
					if((i&(buflen-1))==(buflen-1))
						PcWrite(fh, buf, sizeof(buf));
				}
				PcClose(fh);
			}
			WriteOpl(cs, addr, 0x07, 0x00);
			WriteOpl(cs, addr, 0x04, 0x80);
		}
	}
}

int MsxaudioAdpcm(void)
{
	//
//	const int cs = 2, addr = 0;	//y8950
	const int cs = 0, addr = 1<<2;	//ym2413+y8950
	const int len = sizeof(adpcm)/sizeof(adpcm[0]);
	//
	int i, mode, keyon;
	struct PcKeySence key;

	//
	mode = 0;
	keyon = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int binit = 0, bkeyon = 0;
		switch(key.key_code){
			case 0x1b:	//esc
				if(key.ctrl_state&0x10){
					//shift+esc
					printf(".PcSync\n");
					PcFlush();
					while(1){
						if(PcSync("psl", NULL))
							PcReset();
					}
				}
				return 0;
			case 0x70:	//f1
				//※他アプリ起動用、使用できない
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0x20:	//space
				bkeyon = 1;
				break;
		}

		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
			WriteOpl(cs, addr, 0x04, 0x00);
			WriteOpl(cs, addr, 0x04, 0x80);
			WriteOpl(cs, addr, 0x07, 0x60);
			WriteOpl(cs, addr, 0x08, mode?0x01:0x00);
			WriteOpl(cs, addr, 0x09, 0x00);
			WriteOpl(cs, addr, 0x0a, 0x00);
			i = (len>>(mode?5:2))-1;
			WriteOpl(cs, addr, 0x0b, i&0xff);
			WriteOpl(cs, addr, 0x0c, (i>>8)&(mode?0x1f:0xff));
			for(i=0; i<len; i++){
				WriteOpl(cs, addr, 0x04, 0x80);
				WriteOpl(cs, addr, 0x0f, adpcm[i]);
				while(!(ReadOplStatus(cs, addr)&0x08)){
				}
			}
			WriteOpl(cs, addr, 0x10, 0x00);
			WriteOpl(cs, addr, 0x11, 0x40);
			WriteOpl(cs, addr, 0x12, 0x80);
			WriteOpl(cs, addr, 0x07, 0x00);
			WriteOpl(cs, addr, 0x04, 0x80);
		}
		//
		if(bkeyon){
			keyon ^= 1;
			printf(".keyon=%d\n", keyon);
			if(keyon){
				//keyon
				WriteOpl(cs, addr, 0x04, 0x80);
				WriteOpl(cs, addr, 0x07, 0x20|0x10);
				WriteOpl(cs, addr, 0x09, 0x00);
				WriteOpl(cs, addr, 0x0a, 0x00);
				WriteOpl(cs, addr, 0x07, 0xa0|0x10);
			} else {
				//keyoff
				WriteOpl(cs, addr, 0x07, 0x20|0x10);
				WriteOpl(cs, addr, 0x07, 0x01);
				WriteOpl(cs, addr, 0x07, 0x00);
				WriteOpl(cs, addr, 0x04, 0x80);
			}
		}
	}
}
#endif

#if 0
void WriteOpl4(int cs, unsigned int addr, int reg, int data)
{
	//
	WaitUs(1);
	ChkStatusReg(cs, (reg&0x200)?addr+4:addr, 0x03, 0x00);
	WaitUs(1);
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(3);
	WriteIc(cs, addr+1, data&0xff);
	WaitUs(3);
}

unsigned char ReadOpl4(int cs, unsigned int addr, int reg)
{
	//
	WaitUs(1);
	ChkStatusReg(cs, (reg&0x200)?addr+4:addr, 0x03, 0x00);
	WaitUs(1);
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(3);
	unsigned char data = ReadIc(cs, addr+1);
	WaitUs(3);
	return data;
}

//
unsigned char buf[256];

int Opl4RomRead(char *path, int memtype)
{
	s32 fh;
	const int cs = 2;
	unsigned int addr = 0, i, j;

	//
	WriteOpl4(cs, addr, 0x105, 0x07);
	WriteOpl4(cs, addr, 0x202, memtype?0x03:0x01);
#if 0
	for(i=0; i<24; i++){
		WriteOpl4(cs, addr, 0x220+i, 0x00);
		WriteOpl4(cs, addr, 0x208+i, 0x00);
		WriteOpl4(cs, addr, 0x268+i, 0x68);
	}
#endif

	//
	fh = PcOpen(path, PC_WRONLY|PC_BINARY|PC_CREAT);
	if(fh==-1){
		printf(".PcOpen(%s)\n", path);
		return 1;
	}
	printf(".ReadOpl4Rom(%s,%d)\n", path, memtype);
	for(i=0; i<0x400000; i+=sizeof(buf)){
		printf("%08x\n", i);
		WriteOpl4(cs, addr, 0x203, (i>>16)&0x3f);
		WriteOpl4(cs, addr, 0x204, (i>>8)&0xff);
		WriteOpl4(cs, addr, 0x205, i&0xff);
		for(j=0; j<sizeof(buf); j++)
			buf[j] = ReadOpl4(cs, addr, 0?0x204:0x206);
		PcWrite(fh, buf, sizeof(buf));
	}
	PcClose(fh);
	return 0;
}

int Opl4mlPowerdown(void)
{
	const int cs = 2;
	unsigned int addr = 0;

	//
	printf(".Opl4mlPowerdown\n");
	WriteOpl4(cs, addr, 0x105, 0x07);
	ChkStatusReg(cs, addr+7, 0x02, 0x00);
	WriteIc(cs, addr+6, 0xfd);
	return 0;
}
#endif
#endif
