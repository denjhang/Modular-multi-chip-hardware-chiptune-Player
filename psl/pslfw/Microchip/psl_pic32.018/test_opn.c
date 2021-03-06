
#include <plib.h>
#include <stdio.h>
#include <string.h>
#include "types.h"
#include "hio.h"
#include "timer2.h"
#include "test.h"

#if __DEBUG
#if 0
void WriteSsg(int cs, unsigned int addr, int reg, int data)
{
	//
	WriteIc(cs, addr, reg&0xff);
//	WaitUs(1);
	WriteIc(cs, addr+1, data&0xff);
//	WaitUs(1);
}

unsigned char ReadSsg(int cs, unsigned int addr, int reg)
{
	//
	WriteIc(cs, addr, reg&0xff);
//	WaitUs(1);
	return ReadIc(cs, addr+1);
}

int 	Opn3lSsg(void)
{
	//
	const int cs = 2;
	//
	int i, j, k;
	struct PcKeySence key;
	unsigned char c, d;

	//
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int btest = 0, binit = 0, bnoise = 0;
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

			case 0x08:	//backspace
				btest = 1;
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0x4e:	//n
				bnoise = 1;
				break;
		}

		//
		if(btest){
			printf(".test_enter\n");
			ResetDevice();
#if 1
			//
			printf(".wait1\n");
			WaitMs(10000);
			WriteSsg(cs, 0, 0x0d, 0x04);
			WriteSsg(cs, 0, 0x00, 0x00);
			WriteSsg(cs, 0, 0x01, 0x00);
			WriteSsg(cs, 0, 0x02, 0x00);
			WriteSsg(cs, 0, 0x03, 0x00);
			WriteSsg(cs, 0, 0x04, 0x00);
			WriteSsg(cs, 0, 0x05, 0x00);
			WriteSsg(cs, 0, 0x06, 0x00);
			WriteSsg(cs, 0, 0x09, 0x00);
			WriteSsg(cs, 0, 0x0a, 0x00);
			WriteSsg(cs, 0, 0x0b, 0x80);
			WriteSsg(cs, 0, 0x0c, 0x00);
			WriteSsg(cs, 0, 0x07, 0xff);
			WriteSsg(cs, 0, 0x08, 0x10);
			for(i=0; i<4096; i++){
				WaitMs(100);
				WriteSsg(cs, 0, 0x00, i&0xff);
				WriteSsg(cs, 0, 0x01, (i>>8)&0x0f);
				WriteSsg(cs, 0, 0x02, i&0xff);
				WriteSsg(cs, 0, 0x03, (i>>8)&0x0f);
				WriteSsg(cs, 0, 0x04, i&0xff);
				WriteSsg(cs, 0, 0x05, (i>>8)&0x0f);
				WriteSsg(cs, 0, 0x06, i&0x1f);
				WriteSsg(cs, 0, 0x09, 0x00);
				WriteSsg(cs, 0, 0x0a, 0x00);
				WriteSsg(cs, 0, 0x0b, 0x80);
				WriteSsg(cs, 0, 0x0c, 0x00);
				WriteSsg(cs, 0, 0x07, 0xff);
				WriteSsg(cs, 0, 0x08, 0x10|(i&0x0f));
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			//
			printf(".wait2\n");
			WaitMs(10000);
			WriteSsg(cs, 0, 0x00, 0x00);
			WriteSsg(cs, 0, 0x01, 0x00);
			WriteSsg(cs, 0, 0x02, 0x00);
			WriteSsg(cs, 0, 0x03, 0x00);
			WriteSsg(cs, 0, 0x04, 0x00);
			WriteSsg(cs, 0, 0x05, 0x00);
			WriteSsg(cs, 0, 0x06, 0x00);
			WriteSsg(cs, 0, 0x09, 0x00);
			WriteSsg(cs, 0, 0x0a, 0x00);
			WriteSsg(cs, 0, 0x0b, 0x80);
			WriteSsg(cs, 0, 0x0c, 0x00);
			WriteSsg(cs, 0, 0x0d, 0x00);
			WriteSsg(cs, 0, 0x07, 0xff);
			WriteSsg(cs, 0, 0x08, 0x00);
			for(i=0; i<32; i++){
				WriteSsg(cs, 0, 0x0d, (i>>1)&0x0f);
				WriteSsg(cs, 0, 0x08, 0x10);
				WaitMs(2000);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
#endif
#if 0
			//ok
			WriteIc(cs, 0/*addr*/, 0x00);
			WriteIc(cs, 0+1/*addr*/, 0x7d);
			WriteSsg(cs, 0, 0x01, 0x00);
			WriteSsg(cs, 0, 0x07, 0xfe);
			WriteSsg(cs, 0, 0x08, 0x0f);
			WaitMs(3000);
			WriteSsg(cs, 0, 0x08, 0x00);

			//ng
			WriteIc(cs, 0/*addr*/, 0x0f);
			ResetDevice();
//			WriteIc(cs, 0/*addr*/, 0x00);
			WriteIc(cs, 0+1/*addr*/, 0x7d);
			WriteSsg(cs, 0, 0x01, 0x00);
			WriteSsg(cs, 0, 0x07, 0xfe);
			WriteSsg(cs, 0, 0x08, 0x0f);
			WaitMs(3000);
			WriteSsg(cs, 0, 0x08, 0x00);

			//ng
			WriteIc(cs, 0/*addr*/, 0x00);
			ResetDevice();
//			WriteIc(cs, 0/*addr*/, 0x00);
			WriteIc(cs, 0+1/*addr*/, 0x7d);
			WriteSsg(cs, 0, 0x01, 0x00);
			WriteSsg(cs, 0, 0x07, 0xfe);
			WriteSsg(cs, 0, 0x08, 0x0f);
			WaitMs(3000);
			WriteSsg(cs, 0, 0x08, 0x00);
#endif
#if 0
			//
			for(i=0; i<14; i++)
				WriteSsg(cs, 0, i, 0x00);
			WriteSsg(cs, 0, 0x07, 0xfe);
			WriteSsg(cs, 0, 0x08, 0x0f);
			for(i=0; i<4096; i++){
				WriteSsg(cs, 0, 0x00, i&0xff);
				WriteSsg(cs, 0, 0x01, (i>>8)&0x0f);
				WaitMs(500);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			WaitMs(5000);
#endif
#if 0
			//
			for(i=0; i<14; i++)
				WriteSsg(cs, 0, i, 0x00);
			WriteSsg(cs, 0, 0x07, 0xff);
			WriteSsg(cs, 0, 0x08, 0x0f);
			for(i=0; i<256; i++){
				WriteSsg(cs, 0, 0x00, i&0xff);
				WriteSsg(cs, 0, 0x01, (i>>8)&0x0f);
				WaitMs(500);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			WaitMs(5000);
#endif
#if 0
			//
			for(i=0; i<14; i++)
				WriteSsg(cs, 0, i, 0x00);
			WriteSsg(cs, 0, 0x07, 0xf7);
			WriteSsg(cs, 0, 0x08, 0x0f);
			for(i=0; i<32; i++){
				WriteSsg(cs, 0, 0x06, i);
				WaitMs(1000);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			WaitMs(5000);
#endif
#if 0
			//
			for(i=0; i<14; i++)
				WriteSsg(cs, 0, i, 0x00);
			WriteSsg(cs, 0, 0x07, 0xff);
			WriteSsg(cs, 0, 0x08, 0x10);
			WriteSsg(cs, 0, 0x0b, 0x10);
			WriteSsg(cs, 0, 0x0c, 0x00);
			for(i=0; i<16; i++){
				WriteSsg(cs, 0, 0x0d, i);
				WaitMs(1000);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			WaitMs(5000);
#endif
#if 0
			//
			for(i=0; i<14; i++)
				WriteSsg(cs, 0, i, 0x00);
			WriteSsg(cs, 0, 0x07, 0xff);
			WriteSsg(cs, 0, 0x08, 0x10);
			WriteSsg(cs, 0, 0x0d, 0x0e);
			for(i=0; i<1024; i++){
				WriteSsg(cs, 0, 0x0b, i&0xff);
				WriteSsg(cs, 0, 0x0c, (i>>8)&0xff);
				WaitMs(1000);
			}
			WriteSsg(cs, 0, 0x08, 0x00);
			WaitMs(5000);
#endif
			printf(".test_exit\n");
		}

		//
		if(binit){
			printf(".init\n");
			//
			ResetDevice();
			for(i=0; i<14; i++){
				printf("i=%d,%02x,", i, ReadSsg(cs, 0, i));
				for(j=0; j<8; j++){
					c = 1<<j;
					WriteSsg(cs, 0, i, c);
					d = ReadSsg(cs, 0, i);
					printf("%02x/%02x,", c, d);
				}
				printf("\n");
			}
			//
			for(k=0; k<4; k++){
				ResetDevice();
				printf("k=%d\n", k);
				WriteSsg(cs, 0, 0x07, k<<6);
				for(i=14; i<16; i++){
					printf("i=%d,%02x,", i, ReadSsg(cs, 0, i));
					for(j=0; j<8; j++){
						c = 1<<j;
						WriteSsg(cs, 0, i, c);
						d = ReadSsg(cs, 0, i);
						printf("%02x/%02x,", c, d);
					}
					printf("\n");
				}
			}
		}

		//
		if(bnoise){
			printf(".noise\n");
			//out/ext_pulldown ic#=low
			mPORTCClearBits(BIT_3);
			//
			WaitMs(50);
			//out/ext_pulldown ic#=high
			mPORTCSetBits(BIT_3);
			//
			WaitUs(1);
			WriteSsg(cs, 0, 0x06, 0x08);
			WriteSsg(cs, 0, 0x07, 0xf7);
			WriteSsg(cs, 0, 0x08, 0x0f);
			WriteSsg(cs, 0, 0x09, 0x08);
			WaitMs(10000);
			WriteSsg(cs, 0, 0x08, 0x00);
		}
	}
}
#endif

#if 0
//
const unsigned char adpcma[4096] = {
	0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x08,0x08,0x08,0x80,0x80,0x80,	0x80,0x80,0x80,0x08,0x08,0x08,0x08,0x80,0x88,0x08,0x00,0x80,0x08,0x00,0x88,0x08,
	0x80,0x88,0x08,0x08,0x00,0x08,0x00,0x80,0x88,0x80,0x88,0x80,0x80,0x00,0x08,0x00,	0x08,0x80,0x88,0x88,0x80,0x80,0x08,0x00,0x00,0x08,0x08,0x88,0x88,0x88,0x08,0x00,
	0x00,0x00,0x00,0x88,0x88,0x88,0x88,0x08,0x00,0x00,0x00,0x00,0x80,0x88,0x88,0x88,	0x88,0x80,0x00,0x10,0x00,0x80,0x88,0x88,0x88,0x88,0x80,0x00,0x00,0x10,0x08,0x08,
	0x88,0x98,0x88,0x88,0x01,0x00,0x01,0x08,0x08,0x88,0x89,0x88,0x88,0x00,0x01,0x00,	0x10,0x88,0x08,0x98,0x98,0x88,0x08,0x10,0x10,0x01,0x80,0x88,0x89,0x89,0x88,0x80,
	0x01,0x01,0x00,0x00,0x88,0x88,0x99,0x88,0x80,0x00,0x01,0x10,0x00,0x08,0x89,0x89,	0x98,0x88,0x00,0x10,0x11,0x00,0x08,0x88,0x98,0x99,0x88,0x00,0x01,0x10,0x10,0x00,
	0x88,0x99,0x98,0x98,0x80,0x01,0x11,0x10,0x00,0x88,0x89,0x99,0x98,0x80,0x00,0x11,	0x11,0x00,0x08,0x89,0x99,0x99,0x88,0x00,0x11,0x11,0x10,0x08,0x88,0x99,0xa8,0x98,
	0x00,0x01,0x21,0x10,0x00,0x89,0x8a,0x99,0x98,0x80,0x10,0x21,0x11,0x00,0x88,0x99,	0x99,0x99,0x80,0x01,0x11,0x11,0x10,0x08,0x99,0x99,0xa9,0x88,0x01,0x11,0x12,0x10,
	0x08,0x89,0x99,0xa9,0x98,0x00,0x11,0x12,0x11,0x00,0x89,0x99,0xa9,0x99,0x80,0x11,	0x12,0x12,0x00,0x88,0x99,0xa9,0xa8,0x90,0x01,0x12,0x21,0x10,0x08,0x99,0xa9,0xa9,
	0x98,0x01,0x12,0x12,0x11,0x08,0x89,0xa9,0xa9,0x99,0x00,0x11,0x22,0x21,0x00,0x89,	0x9a,0xaa,0x99,0x80,0x11,0x22,0x21,0x10,0x88,0x9a,0xaa,0x99,0x90,0x01,0x22,0x21,
	0x20,0x08,0x9a,0xaa,0x9a,0x88,0x81,0x12,0x22,0x21,0x08,0x89,0xaa,0xaa,0x99,0x00,	0x12,0x22,0x22,0x00,0x89,0xaa,0xaa,0xa8,0x88,0x12,0x22,0x22,0x10,0x88,0x9a,0xba,
	0xa9,0x88,0x01,0x22,0x32,0x11,0x08,0x9a,0xab,0xa9,0x98,0x81,0x22,0x23,0x21,0x08,	0x8a,0xaa,0xab,0x98,0x80,0x12,0x32,0x31,0x10,0x89,0xab,0xaa,0xa9,0x88,0x12,0x23,
	0x22,0x20,0x88,0xaa,0xab,0xaa,0x88,0x02,0x22,0x32,0x21,0x08,0x9a,0xbb,0xaa,0x98,	0x81,0x23,0x23,0x22,0x08,0x8a,0xab,0xba,0xa8,0x80,0x22,0x32,0x32,0x10,0x89,0xab,
	0xbb,0xa9,0x88,0x12,0x33,0x23,0x11,0x88,0xaa,0xbb,0xba,0x88,0x02,0x23,0x32,0x31,	0x08,0x9b,0xab,0xbb,0x98,0x81,0x23,0x33,0x22,0x18,0x8a,0xbb,0xba,0xa9,0x80,0x22,
	0x33,0x32,0x20,0x89,0xbb,0xbb,0xaa,0x88,0x12,0x33,0x42,0x21,0x88,0xab,0xbb,0xba,	0xa8,0x12,0x23,0x42,0x31,0x08,0x9a,0xbc,0xba,0xa8,0x81,0x23,0x43,0x22,0x10,0x9a,
	0xac,0xbb,0xa9,0x80,0x22,0x43,0x32,0x20,0x89,0xac,0xbb,0xba,0x88,0x13,0x33,0x42,	0x21,0x08,0xab,0xcb,0xbb,0x98,0x02,0x33,0x43,0x22,0x08,0x9a,0xcb,0xbb,0xa9,0x82,
	0x23,0x43,0x32,0x10,0x99,0xbc,0xbc,0xa9,0x81,0x13,0x43,0x42,0x10,0x89,0xac,0xbc,	0xaa,0x90,0x12,0x43,0x42,0x21,0x09,0xab,0xbc,0xc9,0xa8,0x12,0x33,0x44,0x21,0x08,
	0x9b,0xbc,0xca,0x99,0x81,0x33,0x44,0x22,0x10,0x9a,0xbc,0xca,0xb9,0x80,0x23,0x44,	0x23,0x11,0x89,0xbc,0xca,0xba,0x98,0x22,0x43,0x43,0x22,0x09,0xac,0xbc,0xbb,0x99,
	0x02,0x43,0x43,0x32,0x18,0x9b,0xcc,0xba,0xb8,0x81,0x33,0x52,0x32,0x10,0x8a,0xcc,	0xac,0xa9,0x80,0x23,0x44,0x32,0x21,0x89,0xbc,0xcb,0xba,0x98,0x13,0x44,0x33,0x22,
	0x09,0xab,0xdb,0xba,0xa8,0x02,0x34,0x43,0x32,0x18,0x9b,0xcc,0xbb,0xb9,0x81,0x34,	0x43,0x33,0x20,0x9a,0xcc,0xbb,0xbb,0x80,0x23,0x53,0x33,0x21,0x89,0xbc,0xcc,0xaa,
	0x90,0x12,0x44,0x42,0x21,0x19,0xac,0xcb,0xca,0xa8,0x02,0x35,0x33,0x33,0x18,0x9b,	0xdb,0xbc,0x9a,0x01,0x24,0x44,0x23,0x10,0x8b,0xbd,0xbc,0xa9,0x90,0x23,0x53,0x42,
	0x21,0x89,0xbd,0xbc,0xaa,0x98,0x03,0x45,0x23,0x22,0x09,0xac,0xcc,0xab,0xa8,0x01,	0x44,0x43,0x22,0x10,0x9c,0xcb,0xcb,0xaa,0x81,0x34,0x52,0x32,0x20,0x8a,0xcd,0xab,
	0xba,0x88,0x24,0x44,0x33,0x21,0x89,0xbd,0xbc,0xba,0x98,0x03,0x53,0x43,0x22,0x08,	0xac,0xda,0xbb,0xa9,0x02,0x35,0x42,0x32,0x10,0x9c,0xbd,0xba,0xb9,0x81,0x25,0x34,
	0x33,0x11,0x8b,0xcc,0xcb,0xba,0x90,0x23,0x54,0x32,0x22,0x89,0xbd,0xca,0xbb,0x99,	0x13,0x45,0x33,0x22,0x18,0xbc,0xdb,0xba,0xb9,0x02,0x44,0x44,0x21,0x10,0x9a,0xcc,
	0xca,0xa9,0x80,0x34,0x35,0x23,0x11,0x99,0xcc,0xbc,0xaa,0x90,0x14,0x35,0x32,0x21,	0x09,0xbc,0xdb,0xab,0x98,0x03,0x45,0x23,0x32,0x08,0xac,0xcc,0xbb,0xa9,0x01,0x44,
	0x43,0x32,0x20,0x9c,0xcb,0xda,0xa9,0x80,0x23,0x53,0x42,0x11,0x8a,0xbd,0xbb,0xc9,	0x98,0x13,0x53,0x34,0x21,0x09,0xad,0xbb,0xca,0xa8,0x03,0x44,0x42,0x32,0x08,0xab,
	0xeb,0xbb,0xaa,0x02,0x44,0x43,0x33,0x11,0x9c,0xcc,0xbb,0xba,0x91,0x25,0x43,0x42,	0x20,0x89,0xcb,0xdb,0xaa,0x98,0x23,0x45,0x32,0x22,0x09,0xbc,0xda,0xbb,0x99,0x12,
	0x44,0x43,0x23,0x08,0x9c,0xcc,0xbb,0xa9,0x81,0x44,0x35,0x22,0x10,0x9a,0xbd,0xbc,	0xa9,0x88,0x24,0x35,0x23,0x11,0x89,0xbd,0xbc,0xaa,0x98,0x13,0x53,0x34,0x21,0x08,
	0xbc,0xcb,0xca,0xa9,0x12,0x36,0x33,0x32,0x18,0xac,0xcc,0xbb,0xb9,0x81,0x44,0x43,	0x33,0x20,0x8b,0xeb,0xbc,0xb9,0x90,0x24,0x44,0x32,0x21,0x89,0xcc,0xbc,0xba,0xa0,
	0x13,0x53,0x43,0x32,0x09,0xad,0xbd,0xaa,0x99,0x02,0x34,0x52,0x22,0x18,0x9b,0xdb,	0xbb,0xba,0x81,0x44,0x44,0x22,0x20,0x9a,0xcc,0xbc,0xaa,0x88,0x24,0x43,0x43,0x11,
	0x09,0xbd,0xca,0xba,0xa8,0x13,0x53,0x43,0x22,0x08,0xad,0xbc,0xbb,0xa8,0x82,0x53,	0x43,0x32,0x10,0xab,0xeb,0xbc,0xa9,0x80,0x34,0x44,0x23,0x11,0x9a,0xcc,0xbc,0xba,
	0x88,0x24,0x43,0x43,0x21,0x09,0xcb,0xdb,0xba,0xa8,0x13,0x45,0x33,0x31,0x18,0xad,	0xbc,0xbb,0xb9,0x02,0x45,0x33,0x32,0x20,0xab,0xeb,0xca,0xb9,0x80,0x34,0x44,0x32,
	0x20,0x8a,0xcc,0xcb,0xaa,0x98,0x24,0x44,0x32,0x31,0x09,0xcb,0xea,0xba,0x98,0x03,	0x44,0x34,0x22,0x08,0xac,0xbd,0xba,0xa9,0x01,0x43,0x53,0x22,0x28,0x9b,0xcd,0xba,
	0xba,0x81,0x25,0x34,0x33,0x11,0x8a,0xcd,0xab,0xbb,0x90,0x14,0x44,0x33,0x31,0x09,	0xbd,0xcb,0xbb,0xa8,0x03,0x53,0x52,0x22,0x18,0xab,0xdb,0xca,0xa9,0x01,0x34,0x52,
	0x32,0x10,0x9a,0xdb,0xca,0xb9,0x80,0x24,0x44,0x32,0x21,0x8a,0xcc,0xca,0xba,0x98,	0x13,0x63,0x33,0x31,0x19,0xcc,0xcb,0xbb,0xa9,0x03,0x54,0x34,0x22,0x00,0xab,0xdb,
	0xcb,0x99,0x81,0x34,0x52,0x32,0x20,0x9a,0xdb,0xcb,0xaa,0x80,0x24,0x44,0x33,0x20,	0x0a,0xcc,0xbd,0xa9,0x98,0x12,0x44,0x33,0x31,0x08,0xbd,0xcb,0xbb,0xa9,0x12,0x53,
	0x44,0x21,0x10,0xaa,0xdb,0xbc,0xa9,0x01,0x24,0x44,0x22,0x20,0x9a,0xcc,0xbc,0xaa,	0x90,0x24,0x43,0x43,0x21,0x8a,0xbd,0xbd,0xa9,0x98,0x12,0x43,0x43,0x22,0x08,0xbd,
	0xbc,0xbb,0xa8,0x02,0x44,0x43,0x33,0x18,0xab,0xeb,0xca,0xa9,0x80,0x34,0x44,0x23,	0x11,0x9a,0xcc,0xca,0xba,0x88,0x24,0x44,0x23,0x21,0x09,0xcc,0xbc,0xbb,0x98,0x13,
	0x53,0x52,0x21,0x08,0xab,0xdb,0xbb,0xa9,0x02,0x53,0x43,0x33,0x10,0xab,0xeb,0xcb,	0xa9,0x81,0x25,0x34,0x23,0x11,0x8a,0xdb,0xbd,0xa9,0x88,0x22,0x44,0x33,0x21,0x0a,
	0xbd,0xcb,0xba,0xa8,0x13,0x53,0x52,0x21,0x18,0xab,0xdb,0xbc,0x99,0x01,0x35,0x33,	0x41,0x10,0x9a,0xdb,0xbc,0xa9,0x81,0x24,0x43,0x42,0x20,0x8a,0xbe,0xba,0xba,0x98,
	0x24,0x44,0x33,0x21,0x09,0xbe,0xbb,0xca,0x99,0x12,0x44,0x42,0x31,0x18,0xac,0xcb,	0xca,0xa9,0x82,0x35,0x34,0x32,0x10,0x9b,0xcd,0xbb,0xaa,0x81,0x25,0x34,0x33,0x20,
	0x8a,0xcc,0xcb,0xba,0x98,0x14,0x44,0x34,0x11,0x08,0xbc,0xbd,0xaa,0xa8,0x02,0x44,	0x34,0x21,0x18,0xab,0xdb,0xca,0xa9,0x01,0x35,0x34,0x22,0x28,0x8b,0xdb,0xbc,0xaa,
	0x80,0x24,0x52,0x33,0x20,0x8a,0xbe,0xbb,0xba,0xa0,0x14,0x44,0x34,0x21,0x09,0xac,	0xcb,0xca,0x99,0x02,0x44,0x34,0x22,0x18,0xab,0xdb,0xcb,0xa9,0x01,0x35,0x34,0x32,
	0x10,0x9a,0xdb,0xca,0xba,0x80,0x24,0x53,0x23,0x21,0x8a,0xbe,0xbb,0xbb,0xa0,0x14,	0x44,0x42,0x21,0x19,0xac,0xcc,0xaa,0xa9,0x12,0x35,0x42,0x32,0x18,0xab,0xdb,0xcb,
	0xa9,0x81,0x35,0x34,0x32,0x20,0x9a,0xdb,0xcb,0xaa,0x90,0x24,0x53,0x32,0x31,0x8a,	0xbe,0xbc,0xaa,0x98,0x13,0x44,0x42,0x22,0x08,0xbc,0xcb,0xca,0xa9,0x02,0x44,0x34,
	0x32,0x00,0x9c,0xcb,0xcb,0xa9,0x81,0x25,0x43,0x23,0x20,0x9a,0xdb,0xcb,0xba,0x91,	0x24,0x44,0x33,0x31,0x89,0xcd,0xbb,0xba,0xa8,0x13,0x63,0x34,0x31,0x08,0xac,0xcc,
	0xba,0xa9,0x02,0x44,0x34,0x32,0x10,0x9c,0xcb,0xcb,0xb9,0x81,0x35,0x34,0x33,0x20,	0x8b,0xcd,0xbb,0xba,0x90,0x24,0x53,0x33,0x31,0x89,0xcc,0xcb,0xca,0x98,0x12,0x44,
	0x34,0x21,0x18,0xac,0xcb,0xca,0xa9,0x02,0x35,0x34,0x32,0x18,0x9b,0xdb,0xca,0xb9,	0x80,0x34,0x52,0x33,0x20,0x8a,0xcc,0xcb,0xba,0x90,0x23,0x63,0x34,0x20,0x09,0xad,
	0xbb,0xca,0x98,0x03,0x44,0x34,0x22,0x08,0xab,0xeb,0xba,0xa9,0x82,0x36,0x33,0x42,	0x10,0x9b,0xcd,0xab,0xa9,0x80,0x24,0x44,0x23,0x11,0x8a,0xbe,0xbb,0xba,0x90,0x14,
	0x44,0x33,0x31,0x09,0xbe,0xbb,0xca,0xa8,0x12,0x44,0x42,0x31,0x18,0x9c,0xcc,0xab,	0xa9,0x82,0x35,0x34,0x32,0x20,0x9b,0xdb,0xcb,0xb9,0x90,0x34,0x53,0x33,0x20,0x0a,
	0xcd,0xbb,0xba,0x98,0x14,0x44,0x33,0x32,0x09,0xbe,0xbc,0xab,0x99,0x12,0x44,0x42,	0x32,0x18,0xac,0xcb,0xcb,0xa9,0x81,0x43,0x53,0x32,0x20,0x9a,0xdc,0xbb,0xaa,0x90,
	0x34,0x53,0x33,0x21,0x89,0xdb,0xcb,0xbb,0x98,0x14,0x44,0x34,0x21,0x08,0xbc,0xbd,	0xba,0x99,0x02,0x44,0x34,0x22,0x18,0xab,0xdb,0xca,0xb9,0x01,0x25,0x34,0x32,0x20,
	0x9a,0xdb,0xcb,0xaa,0x91,0x24,0x44,0x33,0x20,0x0a,0xbe,0xbb,0xca,0x90,0x12,0x44,	0x42,0x22,0x09,0xac,0xcb,0xca,0xa8,0x01,0x44,0x34,0x32,0x00,0xab,0xdb,0xcb,0xa9,
	0x81,0x35,0x34,0x32,0x20,0x9a,0xcd,0xbb,0xaa,0x90,0x24,0x52,0x42,0x11,0x89,0xac,	0xcb,0xbb,0x98,0x13,0x54,0x33,0x32,0x08,0xbd,0xbd,0xaa,0xa9,0x02,0x35,0x34,0x22,
	0x18,0x9b,0xcc,0xca,0xb9,0x81,0x34,0x43,0x42,0x20,0x8a,0xcc,0xbc,0xba,0x88,0x24,	0x43,0x43,0x21,0x0a,0xbd,0xbc,0xbb,0x98,0x12,0x54,0x32,0x32,0x08,0xad,0xbc,0xbb,
	0xa9,0x01,0x53,0x43,0x33,0x10,0xab,0xeb,0xca,0xb9,0x81,0x24,0x44,0x32,0x20,0x8a,	0xcc,0xca,0xba,0x90,0x14,0x43,0x43,0x31,0x89,0xbd,0xcb,0xab,0xa8,0x12,0x54,0x33,
	0x31,0x18,0xad,0xbc,0xbb,0xb9,0x02,0x44,0x43,0x42,0x00,0x8b,0xcc,0xbc,0xa9,0x80,	0x24,0x43,0x42,0x20,0x8a,0xbd,0xbc,0xb9,0x98,0x14,0x35,0x23,0x22,0x89,0xad,0xbc,
	0xba,0xa8,0x12,0x44,0x43,0x31,0x18,0xac,0xcc,0xba,0xb9,0x01,0x44,0x43,0x32,0x28,	0x9b,0xdb,0xda,0xa9,0x80,0x23,0x53,0x33,0x21,0x8a,0xcd,0xbb,0xbb,0x98,0x24,0x44,
	0x42,0x21,0x08,0xbc,0xcb,0xca,0xa8,0x02,0x44,0x34,0x31,0x18,0x9c,0xcb,0xcb,0xa9,	0x01,0x35,0x34,0x32,0x20,0x9b,0xcd,0xba,0xba,0x80,0x24,0x53,0x32,0x21,0x0a,0xcc,
	0xcb,0xbb,0x90,0x13,0x63,0x34,0x22,0x88,0xad,0xbb,0xca,0xa8,0x02,0x36,0x33,0x32,	0x18,0xac,0xcc,0xbb,0xb9,0x82,0x36,0x33,0x42,0x20,0x9a,0xcc,0xcb,0xaa,0x80,0x24,
	0x43,0x43,0x21,0x89,0xcc,0xbc,0xba,0xa0,0x13,0x45,0x33,0x22,0x08,0xbc,0xdb,0xbb,	0xa8,0x02,0x44,0x43,0x41,0x18,0x9a,0xdb,0xbb,0xb9,0x81,0x44,0x35,0x22,0x20,0x8a,
	0xcc,0xbc,0xaa,0x80,0x23,0x53,0x42,0x21,0x89,0xbc,0xda,0xba,0x98,0x03,0x53,0x42,	0x31,0x19,0xac,0xcc,0xba,0xa9,0x02,0x44,0x34,0x32,0x10,0x9c,0xbd,0xbb,0xb9,0x81,
	0x34,0x53,0x33,0x20,0x8b,0xcd,0xbb,0xba,0x90,0x24,0x44,0x42,0x20,0x09,0xad,0xbb,	0xca,0x98,0x12,0x44,0x42,0x22,0x08,0xac,0xcb,0xca,0xa9,0x02,0x35,0x34,0x32,0x18,
	0x9a,0xdb,0xcb,0xaa,0x81,0x25,0x34,0x32,0x21,0x9a,0xcc,0xcb,0xba,0x88,0x24,0x44,	0x32,0x31,0x09,0xbe,0xbb,0xca,0x98,0x02,0x44,0x42,0x31,0x18,0xac,0xcb,0xca,0xa9,
	0x82,0x35,0x34,0x32,0x10,0x9b,0xdb,0xcb,0xaa,0x81,0x25,0x34,0x32,0x21,0x8a,0xcc,	0xcb,0xba,0x98,0x23,0x63,0x34,0x21,0x09,0xbc,0xcb,0xca,0xa8,0x12,0x44,0x34,0x22,
	0x18,0xac,0xcb,0xcb,0x9a,0x01,0x43,0x53,0x32,0x10,0x9a,0xdc,0xab,0xba,0x80,0x34,	0x53,0x32,0x21,0x8a,0xbe,0xbc,0xaa,0x98,0x22,0x53,0x42,0x22,0x88,0xbc,0xcc,0xab,
	0x99,0x12,0x44,0x34,0x32,0x08,0x9c,0xcb,0xcb,0xa9,0x81,0x43,0x53,0x32,0x20,0x9b,	0xdb,0xcb,0xba,0x80,0x34,0x44,0x33,0x31,0x8a,0xcd,0xbb,0xba,0xa0,0x14,0x44,0x33,
	0x32,0x09,0xbd,0xcb,0xbc,0x98,0x01,0x44,0x33,0x42,0x00,0xab,0xdb,0xca,0xa9,0x81,	0x34,0x44,0x32,0x10,0x8a,0xdb,0xca,0xba,0x80,0x24,0x44,0x32,0x21,0x89,0xcb,0xdb,
	0xba,0xa8,0x14,0x35,0x33,0x31,0x19,0xad,0xcb,0xbb,0xa8,0x02,0x45,0x33,0x33,0x18,	0xab,0xeb,0xcb,0xa9,0x81,0x34,0x52,0x33,0x10,0x8a,0xdb,0xca,0xba,0x90,0x24,0x44,
	0x33,0x21,0x89,0xcc,0xbd,0xaa,0x88,0x02,0x44,0x33,0x22,0x19,0xad,0xbd,0xaa,0xa8,	0x82,0x35,0x33,0x33,0x10,0xac,0xcc,0xca,0xa9,0x81,0x24,0x43,0x42,0x20,0x8a,0xcc,
	0xbc,0xaa,0x90,0x14,0x43,0x42,0x22,0x89,0xbd,0xbc,0xba,0x99,0x13,0x45,0x32,0x32,	0x08,0xac,0xdb,0xba,0xa9,0x01,0x44,0x43,0x32,0x28,0x9b,0xeb,0xbc,0xa9,0x80,0x34,
	0x43,0x42,0x20,0x8a,0xcc,0xbc,0xaa,0x90,0x14,0x35,0x33,0x21,0x89,0xad,0xca,0xbb,	0x98,0x03,0x45,0x32,0x32,0x18,0xbc,0xcc,0xbb,0xa9,0x01,0x44,0x43,0x33,0x10,0x9c,
	0xcb,0xda,0xa9,0x91,0x23,0x53,0x42,0x20,0x8a,0xbd,0xbc,0xaa,0x88,0x13,0x53,0x42,	0x21,0x09,0xad,0xbb,0xca,0xa8,0x12,0x44,0x42,0x32,0x08,0xab,0xeb,0xbb,0xa9,0x82,
	0x44,0x43,0x33,0x10,0x9b,0xdc,0xbc,0xa9,0x80,0x24,0x35,0x23,0x11,0x89,0xcb,0xdb,	0xaa,0x90,0x13,0x53,0x34,0x21,0x08,0xbc,0xcc,0xba,0xa8,0x03,0x44,0x34,0x32,0x00,
	0xac,0xcb,0xcb,0xa9,0x81,0x36,0x33,0x33,0x20,0x9b,0xeb,0xca,0xba,0x80,0x24,0x52,	0x33,0x21,0x8a,0xbe,0xbb,0xbb,0x98,0x14,0x44,0x34,0x21,0x09,0xac,0xcb,0xbb,0xb8,
	0x02,0x54,0x34,0x22,0x18,0x9c,0xbd,0xab,0xa9,0x81,0x34,0x53,0x23,0x10,0x8b,0xcd,	0xab,0xba,0x80,0x24,0x44,0x33,0x20,0x0a,0xbe,0xbb,0xbb,0xa0,0x13,0x63,0x43,0x22,
	0x09,0xac,0xdb,0xab,0xa8,0x02,0x36,0x33,0x41,0x18,0x9a,0xdb,0xbc,0xa9,0x00,0x34,	0x43,0x42,0x11,0x9a,0xcc,0xbc,0xaa,0x80,0x14,0x43,0x42,0x21,0x09,0xcb,0xdb,0xab,
	0x98,0x13,0x45,0x33,0x22,0x09,0xac,0xda,0xbb,0xa9,0x02,0x44,0x43,0x32,0x10,0xab,	0xeb,0xbc,0xa9,0x81,0x24,0x44,0x23,0x10,0x8a,0xcc,0xbc,0xaa,0x90,0x23,0x54,0x23,
	0x21,0x09,0xbd,0xca,0xbb,0x98,0x12,0x53,0x43,0x31,0x18,0xbc,0xcc,0xbb,0xa9,0x02,	0x44,0x43,0x32,0x10,0x9b,0xeb,0xbc,0xa9,0x91,0x25,0x33,0x42,0x20,0x8a,0xcc,0xbc,
	0xaa,0x98,0x23,0x63,0x33,0x21,0x09,0xbe,0xbb,0xca,0xa8,0x12,0x44,0x43,0x22,0x08,	0xac,0xcb,0xcb,0xa8,0x82,0x35,0x42,0x33,0x18,0x9b,0xcd,0xbb,0xaa,0x80,0x35,0x34,
	0x33,0x20,0x8a,0xcc,0xcb,0xbb,0x90,0x23,0x63,0x42,0x22,0x88,0xbd,0xbb,0xca,0xa8,	0x03,0x44,0x34,0x31,0x18,0xab,0xeb,0xbb,0xa9,0x82,0x36,0x34,0x23,0x10,0x9b,0xcc,
	0xcb,0xaa,0x81,0x24,0x44,0x23,0x21,0x8a,0xcc,0xbc,0xba,0x98,0x14,0x43,0x43,0x22,	0x09,0xbd,0xbc,0xbb,0xa8,0x03,0x45,0x33,0x32,0x18,0xac,0xdb,0xbb,0xaa,0x01,0x44,
	0x43,0x42,0x10,0x9a,0xcc,0xbc,0xa9,0x90,0x24,0x43,0x42,0x20,0x0a,0xbd,0xbc,0xb9,	0xa0,0x13,0x45,0x23,0x31,0x09,0xad,0xbc,0xab,0xa8,0x02,0x44,0x43,0x23,0x00,0xac,
	0xcb,0xcb,0xb9,0x82,0x35,0x43,0x32,0x20,0x9a,0xdc,0xbb,0xba,0x80,0x25,0x34,0x42,	0x11,0x89,0xbc,0xcb,0xca,0x90,0x03,0x44,0x42,0x22,0x09,0xac,0xcb,0xca,0xa8,0x01,
	0x44,0x34,0x22,0x10,0xab,0xdb,0xcb,0xa9,0x81,0x35,0x34,0x32,0x20,0x9a,0xcd,0xba,	0xba,0x90,0x24,0x44,0x33,0x21,0x0a,0xbe,0xbb,0xca,0x98,0x13,0x44,0x34,0x22,0x08,
	0xbb,0xeb,0xba,0xa9,0x02,0x44,0x43,0x32,0x18,0x9b,0xeb,0xbc,0xa9,0x81,0x24,0x44,	0x23,0x10,0x8a,0xcc,0xbc,0xaa,0x90,0x14,0x43,0x43,0x21,0x89,0xbd,0xbc,0xba,0xa8,
	0x13,0x45,0x33,0x22,0x08,0xac,0xdb,0xba,0xa9,0x82,0x44,0x43,0x32,0x28,0x9b,0xeb,	0xbc,0xa9,0x80,0x25,0x33,0x42,0x20,0x8a,0xbe,0xbb,0xba,0x90,0x24,0x44,0x33,0x22,
	0x0a,0xbd,0xcb,0xbb,0xa8,0x03,0x54,0x34,0x21,0x18,0xac,0xbd,0xaa,0xa9,0x01,0x34,	0x52,0x32,0x10,0x9b,0xcd,0xab,0xaa,0x81,0x24,0x44,0x23,0x20,0x8a,0xbe,0xbb,0xba,
	0x98,0x24,0x44,0x33,0x31,0x09,0xbd,0xcb,0xca,0x98,0x02,0x44,0x33,0x33,0x19,0xac,	0xdb,0xca,0xa9,0x82,0x34,0x52,0x32,0x10,0x9a,0xdb,0xca,0xb9,0x80,0x24,0x44,0x32,
	0x21,0x8a,0xcc,0xca,0xba,0x98,0x14,0x35,0x33,0x22,0x09,0xbd,0xbc,0xbb,0xa8,0x02,	0x53,0x43,0x33,0x00,0xad,0xbc,0xbb,0xb9,0x82,0x36,0x34,0x32,0x10,0x9a,0xcd,0xab,
	0xb9,0x91,0x24,0x44,0x23,0x21,0x8a,0xbe,0xbb,0xbb,0x98,0x23,0x63,0x43,0x21,0x08,	0xbc,0xcc,0xba,0xa8,0x02,0x44,0x42,0x32,0x18,0x9c,0xcb,0xda,0x99,0x81,0x24,0x35,
	0x22,0x10,0x99,0xcc,0xbb,0xaa,0x90,0x25,0x34,0x42,0x11,0x89,0xbc,0xcb,0xca,0x88,	0x03,0x44,0x34,0x21,0x08,0xac,0xcb,0xca,0xa8,0x02,0x35,0x42,0x32,0x00,0xab,0xdb,
	0xca,0xb9,0x81,0x35,0x34,0x32,0x20,0x9a,0xcd,0xab,0xba,0x88,0x24,0x44,0x33,0x21,	0x0a,0xbe,0xbb,0xca,0x98,0x13,0x44,0x34,0x21,0x19,0xac,0xbd,0xba,0xa8,0x82,0x43,
	0x53,0x22,0x10,0x9c,0xbd,0xba,0xaa,0x81,0x34,0x53,0x23,0x20,0x8b,0xcc,0xcb,0xba,	0x88,0x24,0x44,0x33,0x21,0x09,0xcc,0xcb,0xba,0xa8,0x13,0x54,0x33,0x32,0x08,0xad,
	0xcb,0xbb,0xb8,0x82,0x53,0x44,0x22,0x10,0x9b,0xdb,0xbc,0xa9,0x80,0x34,0x43,0x42,	0x20,0x8a,0xbe,0xbb,0xab,0x88,0x24,0x44,0x33,0x22,0x89,0xbe,0xbb,0xca,0x98,0x02,
	0x44,0x42,0x31,0x18,0xac,0xcb,0xcb,0x99,0x82,0x35,0x42,0x32,0x20,0x9c,0xbd,0xba,	0xba,0x81,0x25,0x34,0x33,0x20,0x8a,0xcc,0xcb,0xba,0x98,0x23,0x63,0x42,0x21,0x08,
	0xbc,0xda,0xba,0xa8,0x12,0x44,0x34,0x31,0x18,0xab,0xeb,0xbb,0xa9,0x82,0x44,0x43,	0x33,0x10,0x9b,0xeb,0xbc,0xaa,0x80,0x24,0x44,0x32,0x21,0x8a,0xcc,0xbc,0xba,0x98,
	0x23,0x54,0x32,0x31,0x09,0xad,0xcb,0xba,0xa8,0x02,0x53,0x43,0x32,0x18,0x9d,0xbc,	0xbb,0xb9,0x01,0x44,0x43,0x33,0x20,0x9b,0xeb,0xca,0xb9,0x91,0x23,0x63,0x33,0x21,
	0x8a,0xbf,0xab,0xba,0x98,0x13,0x54,0x33,0x21,0x19,0xbd,0xbc,0xbb,0xa8,0x02,0x45,	0x33,0x32,0x18,0x9c,0xdb,0xbb,0xb9,0x82,0x36,0x34,0x23,0x10,0x8b,0xcc,0xcb,0xaa,
	0x80,0x24,0x43,0x43,0x21,0x89,0xcc,0xbc,0xba,0xa8,0x14,0x35,0x33,0x31,0x19,0xbc,	0xdb,0xbb,0xa9,0x03,0x45,0x33,0x32,0x10,0xac,0xcc,0xbc,0xa9,0x00,0x34,0x43,0x42,
	0x10,0x8a,0xcc,0xbc,0xaa,0x80,0x14,0x43,0x42,0x21,0x89,0xbd,0xbc,0xab,0x98,0x13,	0x45,0x32,0x31,0x08,0xac,0xcc,0xbb,0x99,0x01,0x44,0x43,0x32,0x10,0xab,0xeb,0xbb,
	0xba,0x81,0x36,0x34,0x32,0x20,0x8a,0xcd,0xab,0xba,0x90,0x24,0x43,0x52,0x11,0x09,	0xbb,0xdb,0xbb,0x99,0x13,0x54,0x33,0x32,0x08,0xbc,0xdb,0xbb,0xb9,0x02,0x53,0x44,
	0x22,0x18,0x9a,0xdb,0xbc,0xa9,0x81,0x24,0x43,0x42,0x20,0x8a,0xbe,0xbb,0xaa,0x98,	0x24,0x44,0x33,0x21,0x09,0xbe,0xbb,0xca,0x98,0x02,0x44,0x42,0x31,0x18,0xac,0xcb,
	0xca,0xa9,0x82,0x35,0x42,0x32,0x10,0x9b,0xcd,0xba,0xb9,0x91,0x25,0x34,0x33,0x11,	0x8a,0xcc,0xcb,0xba,0x98,0x24,0x44,0x33,0x22,0x89,0xbd,0xcb,0xbb,0xa8,0x12,0x54,
	0x33,0x32,0x18,0xac,0xdb,0xca,0xa8,0x81,0x35,0x33,0x42,0x10,0x9b,0xcc,0xbc,0xaa,	0x80,0x24,0x44,0x23,0x20,0x89,0xcc,0xbc,0xba,0x90,0x13,0x54,0x23,0x31,0x09,0xbc,
	0xdb,0xba,0xa8,0x02,0x53,0x43,0x32,0x18,0xac,0xcc,0xbb,0xb9,0x01,0x36,0x34,0x22,	0x20,0x9a,0xdb,0xbc,0xaa,0x80,0x24,0x43,0x43,0x11,0x89,0xcb,0xdb,0xba,0x98,0x23,
	0x53,0x43,0x22,0x09,0xad,0xbc,0xbb,0xa8,0x02,0x45,0x33,0x32,0x18,0xac,0xcc,0xbb,	0xb9,0x82,0x35,0x43,0x42,0x10,0x9a,0xbe,0xab,0xaa,0x90,0x24,0x44,0x32,0x21,0x89,
	0xcb,0xdb,0xba,0x98,0x13,0x53,0x43,0x31,0x19,0xbc,0xdb,0xbb,0x99,0x02,0x45,0x33,	0x32,0x18,0x9c,0xcc,0xbb,0xba,0x01,0x35,0x43,0x42,0x10,0x8a,0xcc,0xbb,0xbb,0x90,
	0x34,0x53,0x42,0x21,0x0a,0xad,0xbc,0xba,0x98,0x13,0x45,0x23,0x22,0x08,0xac,0xda,	0xbb,0xa8,0x01,0x44,0x43,0x23,0x18,0x9c,0xbd,0xbb,0xb9,0x81,0x35,0x34,0x33,0x20,
	0x8a,0xdb,0xcc,0xa9,0x90,0x22,0x53,0x33,0x31,0x0a,0xcc,0xcb,0xbb,0xa8,0x13,0x54,	0x34,0x22,0x08,0xac,0xcb,0xca,0xa8,0x82,0x35,0x34,0x22,0x28,0x9b,0xcd,0xba,0xaa,
	0x81,0x25,0x34,0x23,0x20,0x8a,0xcc,0xcb,0xaa,0x98,0x23,0x63,0x33,0x32,0x89,0xcc,	0xcb,0xca,0x98,0x03,0x36,0x32,0x32,0x08,0xac,0xcc,0xba,0xa9,0x82,0x36,0x33,0x33,
	0x28,0x9b,0xeb,0xcb,0xaa,0x81,0x24,0x53,0x23,0x20,0x8a,0xbe,0xbb,0xc9,0x98,0x22,	0x53,0x34,0x21,0x88,0xbc,0xcb,0xca,0x99,0x12,0x44,0x34,0x22,0x08,0x9c,0xcb,0xca,
	0xa9,0x81,0x43,0x53,0x22,0x20,0x9b,0xcd,0xba,0xba,0x81,0x24,0x44,0x33,0x20,0x89,	0xcc,0xcb,0xba,0x98,0x14,0x44,0x33,0x22,0x09,0xbd,0xcb,0xbb,0xa8,0x03,0x45,0x34,
	0x21,0x18,0x9c,0xbc,0xbc,0xa8,0x81,0x34,0x44,0x22,0x10,0x8b,0xcc,0xbc,0xaa,0x80,	0x24,0x43,0x42,0x21,0x89,0xcb,0xdb,0xab,0x90,0x13,0x53,0x43,0x22,0x09,0xbc,0xdb,
	0xab,0xa8,0x02,0x44,0x43,0x32,0x18,0x9c,0xcc,0xbb,0xaa,0x82,0x35,0x43,0x33,0x20,	0x9b,0xdc,0xbb,0xba,0x91,0x24,0x53,0x42,0x20,0x0a,0xbc,0xcc,0xaa,0x98,0x12,0x53,
	0x34,0x21,0x19,0xac,0xcc,0xab,0x99,0x02,0x44,0x34,0x32,0x00,0xab,0xdb,0xcb,0xaa,	0x01,0x25,0x42,0x33,0x11,0x9a,0xdb,0xcb,0xba,0x80,0x24,0x44,0x33,0x21,0x0a,0xbe,
	0xbc,0xaa,0x98,0x12,0x44,0x43,0x21,0x08,0xac,0xcc,0xab,0xa8,0x01,0x44,0x42,0x32,	0x10,0xab,0xdb,0xcb,0xaa,0x81,0x34,0x53,0x32,0x21,0x9a,0xcd,0xbb,0xba,0x88,0x24,
	0x44,0x33,0x31,0x0a,0xbe,0xbc,0xaa,0xa8,0x13,0x44,0x42,0x31,0x19,0xab,0xeb,0xbb,	0xa9,0x02,0x44,0x43,0x33,0x10,0xab,0xeb,0xca,0xaa,0x81,0x25,0x33,0x42,0x21,0x9a,
	0xbe,0xbb,0xba,0x90,0x14,0x53,0x33,0x22,0x89,0xbe,0xbc,0xaa,0xa8,0x12,0x44,0x43,	0x22,0x08,0xac,0xcc,0xab,0xa9,0x01,0x44,0x34,0x32,0x28,0x9b,0xdb,0xcb,0xb9,0x91,
	0x25,0x43,0x32,0x21,0x8a,0xdb,0xcb,0xbb,0x90,0x23,0x63,0x43,0x21,0x09,0xbd,0xbb,	0xcb,0x98,0x03,0x44,0x42,0x32,0x08,0x9c,0xcc,0xba,0xb8,0x81,0x44,0x34,0x33,0x10,
	0x9b,0xdb,0xda,0xa9,0x80,0x23,0x53,0x33,0x21,0x8a,0xcd,0xbb,0xbb,0x90,0x14,0x44,	0x34,0x21,0x09,0xac,0xcb,0xca,0x99,0x02,0x44,0x34,0x22,0x00,0xab,0xdb,0xcb,0x9a,
	0x01,0x35,0x34,0x23,0x10,0x9a,0xdb,0xca,0xba,0x80,0x34,0x44,0x32,0x21,0x8a,0xbe,	0xbb,0xbb,0x98,0x14,0x44,0x42,0x21,0x08,0xac,0xcc,0xaa,0xa8,0x02,0x36,0x23,0x32,
	0x18,0x9c,0xcc,0xbb,0xa9,0x81,0x43,0x62,0x32,0x10,0x9a,0xcc,0xbc,0xa9,0x90,0x24,	0x35,0x32,0x21,0x89,0xcb,0xdb,0xaa,0x98,0x12,0x53,0x43,0x22,0x09,0xac,0xdb,0xab,
	0xa8,0x02,0x44,0x43,0x23,0x00,0xab,0xeb,0xbb,0xba,0x82,0x36,0x34,0x32,0x20,0x9a,	0xcd,0xab,0xba,0x90,0x24,0x52,0x33,0x31,0x8a,0xbd,0xcb,0xba,0xa8,0x13,0x54,0x33,
	0x32,0x09,0xad,0xbd,0xaa,0xa8,0x82,0x35,0x33,0x33,0x10,0xac,0xcc,0xca,0xa9,0x80,	0x34,0x44,0x22,0x20,0x8a,0xcc,0xbc,0xaa,0x90,0x23,0x53,0x43,0x21,0x89,0xbd,0xbc,
	0xba,0x98,0x03,0x53,0x43,0x22,0x08,0xac,0xda,0xbb,0xa9,0x01,0x44,0x43,0x32,0x28,	0x9b,0xeb,0xbc,0xa9,0x80,0x34,0x43,0x42,0x20,0x8a,0xcc,0xbc,0xaa,0x90,0x14,0x35,
	0x32,0x31,0x89,0xbc,0xdb,0xba,0x99,0x13,0x45,0x32,0x32,0x08,0xac,0xcc,0xbb,0xa9,	0x01,0x44,0x43,0x33,0x10,0x9c,0xcc,0xbb,0xb9,0x91,0x35,0x43,0x33,0x21,0x8a,0xdc,
};

void WriteOpn(int cs, unsigned int addr, int reg, int data)
{
	//
	WaitUs(1);
	switch((reg>>8)&0xff){
		case 0:
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x80, 0x00);
			break;
		case 2:
		case 3:
			//control/ram
			ChkStatusReg(cs, addr+4, 0x80, 0x00);
			break;
		default:
			return;
	}	
	WaitUs(1);
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(11);
	WriteIc(cs, addr+1, data&0xff);
	WaitUs(24);
}

unsigned char ReadOpn(int cs, unsigned int addr, int reg)
{
	//
	WaitUs(1);
	switch((reg>>8)&0xff){
		case 0:
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x80, 0x00);
			break;
		case 2:
		case 3:
			//control/ram
			ChkStatusReg(cs, addr+4, 0x80, 0x00);
			break;
		default:
			return 0xff;
	}	
	WaitUs(1);
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(11);
	unsigned char data = ReadIc(cs, addr+1);
	WaitUs(24);
	return data;
}

unsigned char ReadOpnStatus(int cs, unsigned int addr)
{
	//
	unsigned char data = ReadIc(cs, addr);
	WaitUs(24);
	return data;
}

int OpnbTest(void)
{
	//
	const int len = sizeof(adpcma)/sizeof(adpcma[0]);
	//
	int i, cs, keyon, chenb;
	unsigned char data;
	struct PcKeySence key;

	//
	cs = 0;
	keyon = 0;
	chenb = 0x01;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int bch = 0, binit = 0, bcs = 0, bkeyon = 0;
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
				bch = 1;
				break;
			case 0x32:	//2
				bch = 2;
				break;
			case 0x33:	//3
				bch = 3;
				break;
			case 0x34:	//4
				bch = 4;
				break;
			case 0x35:	//5
				bch = 5;
				break;
			case 0x36:	//6
				bch = 6;
				break;

			case 0xc0:	//@
				binit = 1;
				break;

			case 0xf0:	//capslock
				bcs = 1;
				break;

			case 0x20:	//space
				bkeyon = 1;
				break;
		}

		//
		if(bch){
			chenb ^= 1<<(bch-1);
			printf(".chenb=%02x\n", chenb);
		}
		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
#if 1
			WriteOpn(cs, 0, 0x0021, 0xff);
			WriteOpn(cs, 0, 0x0029, 0x80);
#endif
			data = ReadOpn(cs, 0, 0x00ff);
			printf("$00ff=%02x\n", data);
			//
			WriteOpn(cs, 0, 0x020b, 192);
			WriteOpn(cs, 0, 0x0201, 0x01);
			for(i=0; i<len; i++){
				if((i&0xff)==0){
					WriteOpn(cs, 0, 0x0202, (i>>8)&0xff);
					WriteOpn(cs, 0, 0x0203, (i>>16)&0xff);
				}
				WriteOpn(cs, 0, 0x0208, adpcma[i]);
			}
		}
		//
		if(bcs){
			cs = (cs+1)%4;
			printf(".cs=%d\n", cs);
		}
		//
		if(bkeyon){
			keyon ^= 1;
			printf(".keyon=%d,%02x\n", keyon, chenb);
			if(keyon){
				//keyon
				WriteOpn(cs, 0, 0x0101, 0x3f);
//				WriteOpn(cs, 0, 0x0102, 0x10);	//ng
				WriteOpn(cs, 0, 0x0102, 0xef);
				for(i=0; i<6; i++){
					WriteOpn(cs, 0, 0x0108+i, 0xc0|0x1f |0x20);
					WriteOpn(cs, 0, 0x0110+i, 0x00);
					WriteOpn(cs, 0, 0x0118+i, 0x00);
					WriteOpn(cs, 0, 0x0120+i, ((len-1)>>8)&0xff);
					WriteOpn(cs, 0, 0x0128+i, ((len-1)>>16)&0xff);
				}
#if 1
				WriteOpn(cs, 0, 0x0103, 0xff);
				WriteOpn(cs, 0, 0x0104, 0xff);
				WriteOpn(cs, 0, 0x0105, 0xff);
				WriteOpn(cs, 0, 0x0106, 0xff);
				WriteOpn(cs, 0, 0x0107, 0xff);
				for(i=0; i<2; i++){
					WriteOpn(cs, 0, i+0x010e, 0xff);
					WriteOpn(cs, 0, 0x0116+i, 0xff);
					WriteOpn(cs, 0, i+0x011e, 0xff);
					WriteOpn(cs, 0, 0x0126+i, 0xff);
					WriteOpn(cs, 0, i+0x012e, 0xff);
				}
#endif
				WriteOpn(cs, 0, 0x0100, 0x00|chenb |0x40);
			} else {
				//keyoff
				WriteOpn(cs, 0, 0x0100, 0x80|0x3f);
			}
		}
	}
}
#endif

#if 0
void WriteOpn(int cs, unsigned int addr, int reg, int data)
{
	//
	switch((reg>>8)&0xff){
		case 0:
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x80, 0x00);
			break;
		case 2:
		case 3:
			//control/ram
			ChkStatusReg(cs, addr+4, 0x80, 0x00);
			break;
		default:
			return;
	}	
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(2);
	WriteIc(cs, addr+1, data&0xff);
	WaitUs(11);
}

unsigned char ReadOpn(int cs, unsigned int addr, int reg)
{
	//
	switch((reg>>8)&0xff){
		case 0:
		case 1:
			//fm
			ChkStatusReg(cs, addr, 0x80, 0x00);
			break;
		case 2:
		case 3:
			//control/ram
			ChkStatusReg(cs, addr+4, 0x80, 0x00);
			break;
		default:
			return 0xff;
	}	
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(2);
	unsigned char data = ReadIc(cs, addr+1);
	WaitUs(11);
	return data;
}

int OpnaAdpcm(void)
{
	//
	const int cs = 1;
	const int len = sizeof(adpcm)/sizeof(adpcm[0]);
	//
	int i, keyon;
	unsigned char data;
	struct PcKeySence key;

	//
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
			data = ReadOpn(cs, 0, 0x00ff);
			printf("$00ff=%02x\n", data);
			//
			WriteOpn(cs, 0, 0x0110, 0x17);
			WriteOpn(cs, 0, 0x0110, 0x80);
			WriteOpn(cs, 0, 0x0100, 0x60);
			WriteOpn(cs, 0, 0x0101, 0xc0);
			WriteOpn(cs, 0, 0x0102, 0x00);
			WriteOpn(cs, 0, 0x0103, 0x00);
			i = (len>>2)-1;
			WriteOpn(cs, 0, 0x0104, i&0xff);
			WriteOpn(cs, 0, 0x0105, (i>>8)&0xff);
			WriteOpn(cs, 0, 0x010c, i&0xff);
			WriteOpn(cs, 0, 0x010d, (i>>8)&0xff);
			WriteOpn(cs, 0, 0x0109, 0x00);
			WriteOpn(cs, 0, 0x010a, 0x80);
			WriteOpn(cs, 0, 0x010b, 0x80);
			for(i=0; i<len; i++){
				WriteOpn(cs, 0, 0x0108, adpcm[i]);
				WriteOpn(cs, 0, 0x0110, 0x80);
				ChkStatusReg(cs, 2, 0x08, 0x08);
			}
			WriteOpn(cs, 0, 0x0100, 0x00);
			WriteOpn(cs, 0, 0x0110, 0x80);
		}
		//
		if(bkeyon){
			keyon ^= 1;
			printf(".keyon=%d\n", keyon);
			if(keyon){
				//keyon
				WriteOpn(cs, 0, 0x0110, 0x80);
				WriteOpn(cs, 0, 0x0100, 0x20);
				WriteOpn(cs, 0, 0x0102, 0x00);
				WriteOpn(cs, 0, 0x0103, 0x00);
				WriteOpn(cs, 0, 0x0100, 0xa0);
			} else {
				//keyoff
				WriteOpn(cs, 0, 0x0100, 0x20);
				WriteOpn(cs, 0, 0x0100, 0x01);
				WriteOpn(cs, 0, 0x0100, 0x00);
				WriteOpn(cs, 0, 0x0110, 0x80);
			}
		}
	}
}
#endif

#if 0
void WriteOpn(int cs, unsigned int addr, int reg, int data)
{
	//
	switch((reg>>8)&0xff){
		case 0:
		case 1:
			//fm
//			ChkStatusReg(cs, addr, 0x80, 0x00);
			break;
		case 2:
		case 3:
			//control/ram
			ChkStatusReg(cs, addr+4, 0x80, 0x00);
			break;
		default:
			return;
	}	
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WaitUs(2);
	WriteIc(cs, addr+1, data&0xff);
	WaitUs(11);
}

int OpnaPcm(void)
{
	//
	const int cs = 1;
	const signed char pcm[32] = {
//		0x00,0x10,0x20,0x30,0x40,0x50,0x60,0x70,
		0x18,0x2e,0x43,0x56,0x65,0x70,0x77,0x79,0x77,0x70,0x65,0x56,0x43,0x2e,0x18,0x00,
		0xe8,0xd2,0xbd,0xaa,0x9b,0x90,0x89,0x87,0x89,0x90,0x9b,0xaa,0xbd,0xd2,0xe8,0x00,
	};
	const int len = sizeof(pcm)/sizeof(pcm[0]);
	//
	int keyon, ptr;
	struct PcKeySence key;

	//
	keyon = 0;
	ptr = 0;
	while(1){
		//
		if(keyon){
//			ChkStatusReg(cs, 2, 0x04, 0x04);
//			WriteOpn(cs, 0, 0x0110, 0x80);
			WriteOpn(cs, 0, 0x010e, pcm[ptr]);
			ptr = (ptr+1)&(len-1);
		}
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
			WriteOpn(cs, 0, 0x0029, 0x80);
		}
		//
		if(bkeyon){
			keyon ^= 1;
			printf(".keyon=%d\n", keyon);
			if(keyon){
				//keyon
				WriteOpn(cs, 0, 0x0110, 0x1b);
				WriteOpn(cs, 0, 0x0110, 0x80);
				WriteOpn(cs, 0, 0x0100, 0x00);
				WriteOpn(cs, 0, 0x0106, 1996&0xff);
				WriteOpn(cs, 0, 0x0107, (1996>>8)&0xff);
				WriteOpn(cs, 0, 0x0101, 0xcc);
				ptr = 0;
				WriteOpn(cs, 0, 0x010e, pcm[ptr]);
				ptr = (ptr+1)&(len-1);
			} else {
				//keyoff
				WriteOpn(cs, 0, 0x0101, 0xc4);
				WriteOpn(cs, 0, 0x0110, 0x80);
				WriteOpn(cs, 0, 0x0100, 0x00);
				WriteOpn(cs, 0, 0x0110, 0x80);
			}
		}
	}
}
#endif
#endif
