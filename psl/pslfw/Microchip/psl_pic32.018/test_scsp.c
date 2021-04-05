
#include <plib.h>
#include <stdio.h>
#include <string.h>
#include "types.h"
#include "hio.h"
#include "timer2.h"
#include "test.h"

#if __DEBUG
#if 0
void WriteScspFpga(int cs, unsigned int addr, int reg, int data)
{
	//
	ChkStatusReg(cs, addr+4, 0x80, 0x00);
	//
	addr += ((reg>>8)&3)*2;
	WriteIc(cs, addr, reg&0xff);
	WriteIc(cs, addr+1, data&0xff);
}

unsigned short ReadFpga(int cs, unsigned int addr)
{
	//
	ChkStatusReg(cs, addr+4, 0x80, 0x00);
	//
	unsigned short data = ReadIc(cs, addr);
	return (data<<8)|ReadIc(cs, addr+1);
}

void WriteScspWord(int cs, unsigned int addr, unsigned int addr2, unsigned short dat2)
{
	//
	WriteScspFpga(cs, addr, 0x304, 0x00|((addr2>>17)&0x0f));
	WriteScspFpga(cs, addr, 0x303, (addr2>>9)&0xff);
	WriteScspFpga(cs, addr, 0x302, (addr2>>1)&0xff);
	WriteScspFpga(cs, addr, 0x308, (dat2>>8)&0xff);
	WriteScspFpga(cs, addr, 0x308, dat2&0xff);
}

unsigned short ReadScspWord(int cs, unsigned int addr, unsigned int addr2)
{
	//
	WriteScspFpga(cs, addr, 0x304, 0x00|((addr2>>17)&0x0f));
	WriteScspFpga(cs, addr, 0x303, (addr2>>9)&0xff);
	WriteScspFpga(cs, addr, 0x302, (addr2>>1)&0xff);
	WriteScspFpga(cs, addr, 0x318, 0x00);
	return ReadFpga(cs, addr);
}

unsigned int ReadScspDword(int cs, unsigned int addr, unsigned int addr2)
{
	unsigned int data = ReadScspWord(cs, addr, addr2);
	data <<= 16;
	WriteScspFpga(cs, addr, 0x318, 0x00);
	data |= ReadFpga(cs, addr);
	return data;
}

void WriteScspByte(int cs, unsigned int addr, unsigned int addr2, unsigned char dat2)
{
	//
	WriteScspFpga(cs, addr, 0x304, ((addr2&1)?0x20:0x10)|((addr2>>17)&0x0f));
	WriteScspFpga(cs, addr, 0x303, (addr2>>9)&0xff);
	WriteScspFpga(cs, addr, 0x302, (addr2>>1)&0xff);
	WriteScspFpga(cs, addr, 0x308, dat2&0xff);
	WriteScspFpga(cs, addr, 0x308, dat2&0xff);
}

int LoadScspFile(char *dir, const char *file, int cs, unsigned int addr, unsigned int addr2)
{
	s32 fh, fs, i, rs;
	char path[256];
	unsigned char buf[128];

	//
	sprintf(path, "%s.\\%s.BIN", dir, file);
	fh = PcOpen(path, PC_RDONLY|PC_BINARY);
	if(fh==-1){
		printf(".PcOpen(%s)\n", path);
		return 1;
	}
	
	//
	fs = PcLseek(fh, 0, PC_SEEK_END);
	PcLseek(fh, 0, PC_SEEK_SET);
	printf(".load(0x%06x,%d)=%s\n", addr2, fs, path);
	WriteScspFpga(cs, addr, 0x304, 0x00|((addr2>>17)&0x0f));
	WriteScspFpga(cs, addr, 0x303, (addr2>>9)&0xff);
	WriteScspFpga(cs, addr, 0x302, (addr2>>1)&0xff);
	while(fs>0){
		//
		rs = sizeof(buf);
		if(fs<rs)
			rs = fs;
		PcRead(fh, buf, rs);
		fs -= rs;
		//
		for(i=0; i<rs; i++)
			WriteScspFpga(cs, addr, 0x308, buf[i]);
		addr2 += rs;
	}
	//
	if(addr2&1){
		WriteScspFpga(cs, addr, 0x304, 0x10|((addr2>>17)&0x0f));
		WriteScspFpga(cs, addr, 0x308, 0xff);
	}
	return 0;
}

int SaveScspFile(char *path, int cs, unsigned int addr, unsigned int addr2, int fs)
{
	s32 fh;
	int i, j;
	unsigned short data;
	unsigned char buf[128];

	//
	fh = PcOpen(path, PC_WRONLY|PC_BINARY|PC_CREAT);
	if(fh==-1){
		printf(".PcOpen(%s)\n", path);
		return 1;
	}

	//
	printf(".save(0x%06x,%d)=%s\n", addr2, fs, path);
	WriteScspFpga(cs, addr, 0x304, 0x00|((addr2>>17)&0x0f));
	WriteScspFpga(cs, addr, 0x303, (addr2>>9)&0xff);
	WriteScspFpga(cs, addr, 0x302, (addr2>>1)&0xff);
	for(i=0; i<fs; i+=sizeof(buf)){
//		printf("%08x\n", i);
		for(j=0; j<sizeof(buf); j+=2){
			WriteScspFpga(cs, addr, 0x318, 0x00);
			data = ReadFpga(cs, addr);
			buf[j] = (data>>8)&0xff;
			buf[j+1] = data&0xff;
		}
		PcWrite(fh, buf, sizeof(buf));
	}
	PcClose(fh);
	return 0;
}

//
const unsigned char scsptest[] = {
	0x00,0x00,0xa0,0x00,0x00,0x00,0x01,0x02,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,
	0x60,0xfe,0x20,0x7c,0x00,0x10,0x00,0x00,0x11,0x7c,0x00,0x0f,0x04,0x01,0x30,0x3c,0x00,0x20,0x00,0x40,0x00,0x00,0x31,0x40,0x00,0x00,0x30,0x3c,0x01,0x78,0x31,0x40,
	0x00,0x02,0x30,0x3c,0x00,0x00,0x31,0x40,0x00,0x04,0x30,0x3c,0x01,0xb9,0x31,0x40,0x00,0x06,0x31,0x7c,0x00,0x00,0x00,0x08,0x31,0x7c,0x00,0x00,0x00,0x0a,0x31,0x7c,
	0x01,0x00,0x00,0x0c,0x31,0x7c,0x00,0x00,0x00,0x0e,0x31,0x7c,0x00,0x00,0x00,0x10,0x31,0x7c,0x00,0x00,0x00,0x12,0x31,0x7c,0x00,0x00,0x00,0x14,0x31,0x7c,0xe0,0x00,
	0x00,0x16,0x30,0x28,0x00,0x00,0x00,0x40,0x08,0x00,0x31,0x40,0x00,0x00,0x00,0x40,0x10,0x00,0x31,0x40,0x00,0x00,0x60,0xfe,0x00,0x00,0x12,0x2d,0x23,0xfb,0x35,0x0f,
	0x45,0x0f,0x53,0xaa,0x60,0x92,0x6b,0x85,0x74,0x4b,0x7a,0xb5,0x7e,0xa2,0x7f,0xff,0x7e,0xc3,0x7a,0xf6,0x74,0xab,0x6c,0x03,0x61,0x2a,0x54,0x5a,0x45,0xd4,0x35,0xe3,
	0x24,0xdb,0x13,0x14,0x00,0xe9,0xee,0xba,0xdc,0xe5,0xcb,0xc6,0xbb,0xb6,0xad,0x08,0xa0,0x08,0x94,0xfa,0x8c,0x18,0x85,0x8f,0x81,0x81,0x80,0x03,0x81,0x1d,0x84,0xca,
	0x8a,0xf5,0x93,0x80,0x9e,0x3e,0xaa,0xf7,0xb9,0x69,0xc9,0x4a,0xda,0x46,0xec,0x06,0xfe,0x2d,0x10,0x5e,0x22,0x3a,0x33,0x65,0x43,0x85,0x52,0x46,0x5f,0x5d,0x6a,0x85,
	0x73,0x84,0x7a,0x2d,0x7e,0x5b,0x7f,0xfa,0x7f,0x01,0x7b,0x75,0x75,0x68,0x6c,0xfb,0x62,0x58,0x55,0xb7,0x47,0x59,0x37,0x89,0x26,0x99,0x14,0xe1,0x02,0xbc,0xf0,0x89,
	0xde,0xa7,0xcd,0x71,0xbd,0x42,0xae,0x6d,0xa1,0x3f,0x95,0xfd,0x8c,0xe1,0x86,0x1a,0x81,0xcb,0x80,0x0b,0x80,0xe3,0x84,0x4e,0x8a,0x3c,0x92,0x8c,0x9d,0x13,0xa9,0x9c,
	0xb7,0xe6,0xc7,0xa5,0xd8,0x89,0xea,0x39,0xfc,0x5a,0x0e,0x8f,0x20,0x77,0x31,0xb8,0x41,0xf6,0x50,0xde,0x5e,0x23,0x69,0x7f,0x72,0xb8,0x79,0x9e,0x7e,0x0d,0x7f,0xee,
	0x7f,0x37,0x7b,0xed,0x76,0x1f,0x6d,0xed,0x63,0x80,0x57,0x0f,0x48,0xdb,0x39,0x2c,0x28,0x55,0x16,0xad,0x04,0x8f,0xf2,0x59,0xe0,0x6b,0xcf,0x20,0xbe,0xd2,0xaf,0xd7,
	0xa2,0x7c,0x97,0x05,0x8d,0xb0,0x86,0xab,0x82,0x1c,0x80,0x1a,0x80,0xb0,0x83,0xda,0x89,0x88,0x91,0x9c,0x9b,0xee,0xa8,0x46,0xb6,0x66,0xc6,0x03,0xd6,0xce,0xe8,0x6e,
	0xfa,0x88,0x0c,0xbf,0x1e,0xb3,0x30,0x08,0x40,0x64,0x4f,0x73,0x5c,0xe4,0x68,0x74,0x71,0xe6,0x79,0x0a,0x7d,0xb9,0x7f,0xdc,0x7f,0x68,0x7c,0x5e,0x76,0xd0,0x6e,0xd9,
	0x64,0xa3,0x58,0x63,0x4a,0x59,0x3a,0xcc,0x2a,0x0f,0x18,0x78,0x06,0x61,0xf4,0x2a,0xe2,0x30,0xd0,0xd0,0xc0,0x66,0xb1,0x45,0xa3,0xbd,0x98,0x13,0x8e,0x85,0x87,0x43,
	0x82,0x74,0x80,0x30,0x80,0x83,0x83,0x6b,0x88,0xda,0x90,0xb3,0x9a,0xcd,0xa6,0xf5,0xb4,0xea,0xc4,0x65,0xd5,0x15,0xe6,0xa3,0xf8,0xb6,0x0a,0xee,0x1c,0xed,0x2e,0x56,
	0x3e,0xcf,0x4e,0x02,0x5b,0xa1,0x67,0x64,0x71,0x0e,0x78,0x6f,0x7d,0x5e,0x7f,0xc3,0x7f,0x91,0x7c,0xc9,0x77,0x7a,0x6f,0xc0,0x65,0xc1,0x59,0xb3,0x4b,0xd3,0x3c,0x6a,
	0x2b,0xc7,0x1a,0x41,0x08,0x33,0xf5,0xfb,0xe3,0xf6,0xd2,0x83,0xc1,0xfc,0xb2,0xb7,0xa5,0x03,0x99,0x26,0x8f,0x60,0x87,0xe1,0x82,0xd2,0x80,0x4c,0x80,0x5d,0x83,0x03,
	0x88,0x33,0x8f,0xcf,0x99,0xb2,0xa5,0xa8,0xb3,0x72,0xc2,0xc9,0xd3,0x5e,0xe4,0xda,0xf6,0xe4,0x09,0x1c,0x1b,0x26,0x2c,0xa2,0x3d,0x37,0x4c,0x8e,0x5a,0x58,0x66,0x4e,
	0x70,0x31,0x77,0xcd,0x7c,0xfd,0x7f,0xa3,0x7f,0xb4,0x7d,0x2e,0x78,0x1f,0x70,0xa0,0x66,0xda,0x5a,0xfd,0x4d,0x49,0x3e,0x04,0x2d,0x7d,0x1c,0x0a,0x0a,0x05,0xf7,0xcd,
	0xe5,0xbf,0xd4,0x39,0xc3,0x96,0xb4,0x2d,0xa6,0x4d,0x9a,0x3f,0x90,0x40,0x88,0x86,0x83,0x37,0x80,0x6f,0x80,0x3d,0x82,0xa2,0x87,0x91,0x8e,0xf2,0x98,0x9c,0xa4,0x5f,
	0xb1,0xfe,0xc1,0x31,0xd1,0xaa,0xe3,0x13,0xf5,0x12,0x07,0x4a,0x19,0x5d,0x2a,0xeb,0x3b,0x9b,0x4b,0x16,0x59,0x0b,0x65,0x33,0x6f,0x4d,0x77,0x26,0x7c,0x95,0x7f,0x7d,
	0x7f,0xd0,0x7d,0x8c,0x78,0xbd,0x71,0x7b,0x67,0xed,0x5c,0x43,0x4e,0xbb,0x3f,0x9a,0x2f,0x30,0x1d,0xd0,0x0b,0xd6,0xf9,0x9f,0xe7,0x88,0xd5,0xf1,0xc5,0x34,0xb5,0xa7,
	0xa7,0x9d,0x9b,0x5d,0x91,0x27,0x89,0x30,0x83,0xa2,0x80,0x98,0x80,0x24,0x82,0x47,0x86,0xf6,0x8e,0x1a,0x97,0x8c,0xa3,0x1c,0xb0,0x8d,0xbf,0x9c,0xcf,0xf8,0xe1,0x4d,
	0xf3,0x41,0x05,0x78,0x17,0x92,0x29,0x32,0x39,0xfd,0x49,0x9a,0x57,0xba,0x64,0x12,0x6e,0x64,0x76,0x78,0x7c,0x26,0x7f,0x50,0x7f,0xe6,0x7d,0xe4,0x79,0x55,0x72,0x50,
	0x68,0xfb,0x5d,0x84,0x50,0x29,0x41,0x2e,0x30,0xe0,0x1f,0x95,0x0d,0xa7,0xfb,0x71,0xe9,0x53,0xd7,0xab,0xc6,0xd4,0xb7,0x25,0xa8,0xf1,0x9c,0x80,0x92,0x13,0x89,0xe1,
	0x84,0x13,0x80,0xc9,0x80,0x12,0x81,0xf3,0x86,0x62,0x8d,0x48,0x96,0x81,0xa1,0xdd,0xaf,0x22,0xbe,0x0a,0xce,0x48,0xdf,0x89,0xf1,0x71,0x03,0xa6,0x15,0xc7,0x27,0x77,
	0x38,0x5b,0x48,0x1a,0x56,0x64,0x62,0xed,0x6d,0x74,0x75,0xc4,0x7b,0xb2,0x7f,0x1d,0x7f,0xf5,0x7e,0x35,0x79,0xe6,0x73,0x1f,0x6a,0x03,0x5e,0xc1,0x51,0x93,0x42,0xbe,
	0x32,0x8f,0x21,0x59,0x0f,0x77,0xfd,0x44,0xeb,0x1f,0xd9,0x67,0xc8,0x77,0xb8,0xa7,0xaa,0x49,0x9d,0xa8,0x93,0x05,0x8a,0x98,0x84,0x8b,0x80,0xff,0x80,0x06,0x81,0xa5,
	0x85,0xd3,0x8c,0x7c,0x95,0x7b,0xa0,0xa3,0xad,0xba,0xbc,0x7b,0xcc,0x9b,0xdd,0xc6,0xef,0xa2,0x01,0xd3,0x13,0xfa,0x25,0xba,0x36,0xb6,0x46,0x97,0x55,0x09,0x61,0xc2,
	0x6c,0x80,0x75,0x0b,0x7b,0x36,0x7e,0xe3,0x7f,0xfd,0x7e,0x7f,0x7a,0x71,0x73,0xe8,0x6b,0x06,0x5f,0xf8,0x52,0xf8,0x44,0x4a,0x34,0x3a,0x23,0x1b,0x11,0x46,0xff,0x17,
	0xec,0xec,0xdb,0x25,0xca,0x1d,0xba,0x2c,0xab,0xa6,0x9e,0xd6,0x93,0xfd,0x8b,0x55,0x85,0x0a,0x81,0x3d,0x80,0x01,0x81,0x5e,0x85,0x4b,0x8b,0xb5,0x94,0x7b,0x9f,0x6e,
	0xac,0x56,0xba,0xf1,0xca,0xf1,0xdc,0x05,0xed,0xd3,
};

int ScspTest(void)
{
	//
	const int cs = 3;
	//
	int i, addr, n, mode;
	unsigned short data, data2;
	struct PcKeySence key;

	//
	n = 0x1234;
	mode = 0;
	while(1){
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			continue;
		}

		//共通
		int btest = 0, binit = 0, bmode = -1, bwrite = 0;
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

			case 0x31:	//1
				bmode = 1;
				break;
			case 0x32:	//2
				bmode = 2;
				break;
			case 0x33:	//3
				bmode = 3;
				break;
			case 0x30:	//0
				bmode = 0;
				break;
			case 0x08:	//backspace
				btest = 1;
				break;

			case 0x57:	//w
				bwrite = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;
		}

		//
		if(btest){
			printf(".test\n");
			ResetDevice();
			//
			WriteScspFpga(cs, 0, 0x301, 0x19);
			addr = 0x100400;
			WriteScspFpga(cs, 0, 0x304, 0x10|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			data = 0x0200;
			WriteScspFpga(cs, 0, 0x308, (data>>8)&0xff);
			WriteScspFpga(cs, 0, 0x308, data&0xff);
			//
			addr = 0x000000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<sizeof(scsptest)/sizeof(scsptest[0]); i++)
				WriteScspFpga(cs, 0, 0x308, scsptest[i]);
			//
			WriteScspFpga(cs, 0, 0x301, 0x11);
			WaitMs(1);
			WriteScspFpga(cs, 0, 0x301, 0x10);
		}

		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			//
			WriteScspFpga(cs, 0, 0x301, 0x19);
			addr = 0x100000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			printf("reset\n");
			for(i=0; i<0x1000; i+=2){
				WriteScspFpga(cs, 0, 0x318, 0x00);
				if(((i>>1)&15)==0)
					printf("0x%06x: ", addr+i);
				printf("%04x,", ReadFpga(cs, 0));
				if(((i>>1)&15)==15)
					printf("\n");
			}
			//
			addr = 0x100000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<0x1000; i+=2){
				WriteScspFpga(cs, 0, 0x308, 0xff);
				WriteScspFpga(cs, 0, 0x308, 0xff);
			}
			//
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			printf("set\n");
			for(i=0; i<0x1000; i+=2){
				WriteScspFpga(cs, 0, 0x318, 0x00);
				if(((i>>1)&15)==0)
					printf("0x%06x: ", addr+i);
				printf("%04x,", ReadFpga(cs, 0));
				if(((i>>1)&15)==15)
					printf("\n");
			}
			//
			ResetDevice();
			//
			WriteScspFpga(cs, 0, 0x301, 0x19);
			addr = 0x100000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<0x1000; i+=2){
				WriteScspFpga(cs, 0, 0x308, 0x00);
				WriteScspFpga(cs, 0, 0x308, 0x00);
			}
			//
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			printf("clear\n");
			for(i=0; i<0x1000; i+=2){
				WriteScspFpga(cs, 0, 0x318, 0x00);
				if(((i>>1)&15)==0)
					printf("0x%06x: ", addr+i);
				printf("%04x,", ReadFpga(cs, 0));
				if(((i>>1)&15)==15)
					printf("\n");
			}
		}
		
		//
		if(bmode>=0){
			mode = bmode;
			printf(".mode=%d\n", mode);
		}
		if(bwrite){
			printf(".write=%d,0x%04x\n", mode, n);
			//
			WriteScspFpga(cs, 0, 0x301, 0x19);
			addr = 0x000400;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			WriteScspFpga(cs, 0, 0x318, 0x00);
			data = ReadFpga(cs, 0);
			//
			WriteScspFpga(cs, 0, 0x304, (mode<<4)|((addr>>17)&0x0f));
//			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));	//全ビット（b15-0）書き込み
//			WriteScspFpga(cs, 0, 0x304, 0x10|((addr>>17)&0x0f));	//偶数アドレス/上位ビット（b15-8）書き込み
//			WriteScspFpga(cs, 0, 0x304, 0x20|((addr>>17)&0x0f));	//奇数アドレス/下位ビット（b7-0）書き込み
//			WriteScspFpga(cs, 0, 0x304, 0x30|((addr>>17)&0x0f));	//全ビット（b15-0）書き込まない
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			WriteScspFpga(cs, 0, 0x308, (n>>8)&0xff);
			WriteScspFpga(cs, 0, 0x308, n&0xff);
			//
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			WriteScspFpga(cs, 0, 0x318, 0x00);
			data2 = ReadFpga(cs, 0);
			printf("read=0x%04x>0x%04x,%s(%s,%s)\n", data, data2, (data2==n)?"eq":"ne",
				((data2&0xff00)==(n&0xff00))?"eq":"ne", ((data2&0xff)==(n&0xff))?"eq":"ne");
			//
			n = (n+0x1111)&0xffff;
		}
	}
}

//
const short fmsin[1024] = {
	     0,   192,   384,   576,   832,  1024,  1216,  1408,  1600,  1792,  1984,  2176,  2432,  2624,  2816,  3008,	  3200,  3392,  3584,  3776,  4032,  4224,  4416,  4608,  4800,  4992,  5184,  5376,  5568,  5760,  6016,  6208,
	  6400,  6592,  6784,  6976,  7168,  7360,  7552,  7744,  7936,  8128,  8320,  8512,  8704,  8896,  9088,  9280,	  9472,  9664,  9856, 10048, 10240, 10432, 10624, 10816, 11008, 11200, 11392, 11584, 11776, 11968, 12160, 12352,
	 12544, 12672, 12864, 13056, 13248, 13440, 13632, 13824, 13952, 14144, 14336, 14528, 14720, 14912, 15040, 15232,	 15424, 15616, 15744, 15936, 16128, 16320, 16448, 16640, 16832, 16960, 17152, 17344, 17472, 17664, 17856, 17984,
	 18176, 18304, 18496, 18688, 18816, 19008, 19136, 19328, 19456, 19648, 19776, 19968, 20096, 20288, 20416, 20608,	 20736, 20928, 21056, 21184, 21376, 21504, 21632, 21824, 21952, 22080, 22272, 22400, 22528, 22720, 22848, 22976,
	 23104, 23296, 23424, 23552, 23680, 23808, 23936, 24128, 24256, 24384, 24512, 24640, 24768, 24896, 25024, 25152,	 25280, 25408, 25536, 25664, 25792, 25920, 26048, 26176, 26240, 26368, 26496, 26624, 26752, 26880, 26944, 27072,
	 27200, 27328, 27392, 27520, 27648, 27712, 27840, 27968, 28032, 28160, 28224, 28352, 28480, 28544, 28672, 28736,	 28864, 28928, 29056, 29120, 29184, 29312, 29376, 29504, 29568, 29632, 29760, 29824, 29888, 29952, 30080, 30144,
	 30208, 30272, 30336, 30464, 30528, 30592, 30656, 30720, 30784, 30848, 30912, 30976, 31040, 31104, 31168, 31232,	 31296, 31360, 31424, 31488, 31488, 31552, 31616, 31680, 31744, 31744, 31808, 31872, 31936, 31936, 32000, 32064,
	 32064, 32128, 32128, 32192, 32192, 32256, 32320, 32320, 32320, 32384, 32384, 32448, 32448, 32512, 32512, 32512,	 32576, 32576, 32576, 32576, 32640, 32640, 32640, 32640, 32640, 32704, 32704, 32704, 32704, 32704, 32704, 32704,
	 32704, 32704, 32704, 32704, 32704, 32704, 32704, 32704, 32640, 32640, 32640, 32640, 32640, 32576, 32576, 32576,	 32576, 32512, 32512, 32512, 32448, 32448, 32384, 32384, 32320, 32320, 32320, 32256, 32192, 32192, 32128, 32128,
	 32064, 32064, 32000, 31936, 31936, 31872, 31808, 31744, 31744, 31680, 31616, 31552, 31488, 31488, 31424, 31360,	 31296, 31232, 31168, 31104, 31040, 30976, 30912, 30848, 30784, 30720, 30656, 30592, 30528, 30464, 30336, 30272,
	 30208, 30144, 30080, 29952, 29888, 29824, 29760, 29632, 29568, 29504, 29376, 29312, 29184, 29120, 29056, 28928,	 28864, 28736, 28672, 28544, 28480, 28352, 28224, 28160, 28032, 27968, 27840, 27712, 27648, 27520, 27392, 27328,
	 27200, 27072, 26944, 26880, 26752, 26624, 26496, 26368, 26240, 26176, 26048, 25920, 25792, 25664, 25536, 25408,	 25280, 25152, 25024, 24896, 24768, 24640, 24512, 24384, 24256, 24128, 23936, 23808, 23680, 23552, 23424, 23296,
	 23104, 22976, 22848, 22720, 22528, 22400, 22272, 22080, 21952, 21824, 21632, 21504, 21376, 21184, 21056, 20928,	 20736, 20608, 20416, 20288, 20096, 19968, 19776, 19648, 19456, 19328, 19136, 19008, 18816, 18688, 18496, 18304,
	 18176, 17984, 17856, 17664, 17472, 17344, 17152, 16960, 16832, 16640, 16448, 16320, 16128, 15936, 15744, 15616,	 15424, 15232, 15040, 14912, 14720, 14528, 14336, 14144, 13952, 13824, 13632, 13440, 13248, 13056, 12864, 12672,
	 12544, 12352, 12160, 11968, 11776, 11584, 11392, 11200, 11008, 10816, 10624, 10432, 10240, 10048,  9856,  9664,	  9472,  9280,  9088,  8896,  8704,  8512,  8320,  8128,  7936,  7744,  7552,  7360,  7168,  6976,  6784,  6592,
	  6400,  6208,  6016,  5760,  5568,  5376,  5184,  4992,  4800,  4608,  4416,  4224,  4032,  3776,  3584,  3392,	  3200,  3008,  2816,  2624,  2432,  2176,  1984,  1792,  1600,  1408,  1216,  1024,   832,   576,   384,   192,
	     0,  -192,  -384,  -576,  -832, -1024, -1216, -1408, -1600, -1792, -1984, -2176, -2432, -2624, -2816, -3008,	 -3200, -3392, -3584, -3776, -4032, -4224, -4416, -4608, -4800, -4992, -5184, -5376, -5568, -5760, -6016, -6208,
	 -6400, -6592, -6784, -6976, -7168, -7360, -7552, -7744, -7936, -8128, -8320, -8512, -8704, -8896, -9088, -9280,	 -9472, -9664, -9856,-10048,-10240,-10432,-10624,-10816,-11008,-11200,-11392,-11584,-11776,-11968,-12160,-12352,
	-12544,-12672,-12864,-13056,-13248,-13440,-13632,-13824,-13952,-14144,-14336,-14528,-14720,-14912,-15040,-15232,	-15424,-15616,-15744,-15936,-16128,-16320,-16448,-16640,-16832,-16960,-17152,-17344,-17472,-17664,-17856,-17984,
	-18176,-18304,-18496,-18688,-18816,-19008,-19136,-19328,-19456,-19648,-19776,-19968,-20096,-20288,-20416,-20608,	-20736,-20928,-21056,-21184,-21376,-21504,-21632,-21824,-21952,-22080,-22272,-22400,-22528,-22720,-22848,-22976,
	-23104,-23296,-23424,-23552,-23680,-23808,-23936,-24128,-24256,-24384,-24512,-24640,-24768,-24896,-25024,-25152,	-25280,-25408,-25536,-25664,-25792,-25920,-26048,-26176,-26240,-26368,-26496,-26624,-26752,-26880,-26944,-27072,
	-27200,-27328,-27392,-27520,-27648,-27712,-27840,-27968,-28032,-28160,-28224,-28352,-28480,-28544,-28672,-28736,	-28864,-28928,-29056,-29120,-29184,-29312,-29376,-29504,-29568,-29632,-29760,-29824,-29888,-29952,-30080,-30144,
	-30208,-30272,-30336,-30464,-30528,-30592,-30656,-30720,-30784,-30848,-30912,-30976,-31040,-31104,-31168,-31232,	-31296,-31360,-31424,-31488,-31488,-31552,-31616,-31680,-31744,-31744,-31808,-31872,-31936,-31936,-32000,-32064,
	-32064,-32128,-32128,-32192,-32192,-32256,-32320,-32320,-32320,-32384,-32384,-32448,-32448,-32512,-32512,-32512,	-32576,-32576,-32576,-32576,-32640,-32640,-32640,-32640,-32640,-32704,-32704,-32704,-32704,-32704,-32704,-32704,
	-32704,-32704,-32704,-32704,-32704,-32704,-32704,-32704,-32640,-32640,-32640,-32640,-32640,-32576,-32576,-32576,	-32576,-32512,-32512,-32512,-32448,-32448,-32384,-32384,-32320,-32320,-32320,-32256,-32192,-32192,-32128,-32128,
	-32064,-32064,-32000,-31936,-31936,-31872,-31808,-31744,-31744,-31680,-31616,-31552,-31488,-31488,-31424,-31360,	-31296,-31232,-31168,-31104,-31040,-30976,-30912,-30848,-30784,-30720,-30656,-30592,-30528,-30464,-30336,-30272,
	-30208,-30144,-30080,-29952,-29888,-29824,-29760,-29632,-29568,-29504,-29376,-29312,-29184,-29120,-29056,-28928,	-28864,-28736,-28672,-28544,-28480,-28352,-28224,-28160,-28032,-27968,-27840,-27712,-27648,-27520,-27392,-27328,
	-27200,-27072,-26944,-26880,-26752,-26624,-26496,-26368,-26240,-26176,-26048,-25920,-25792,-25664,-25536,-25408,	-25280,-25152,-25024,-24896,-24768,-24640,-24512,-24384,-24256,-24128,-23936,-23808,-23680,-23552,-23424,-23296,
	-23104,-22976,-22848,-22720,-22528,-22400,-22272,-22080,-21952,-21824,-21632,-21504,-21376,-21184,-21056,-20928,	-20736,-20608,-20416,-20288,-20096,-19968,-19776,-19648,-19456,-19328,-19136,-19008,-18816,-18688,-18496,-18304,
	-18176,-17984,-17856,-17664,-17472,-17344,-17152,-16960,-16832,-16640,-16448,-16320,-16128,-15936,-15744,-15616,	-15424,-15232,-15040,-14912,-14720,-14528,-14336,-14144,-13952,-13824,-13632,-13440,-13248,-13056,-12864,-12672,
	-12544,-12352,-12160,-11968,-11776,-11584,-11392,-11200,-11008,-10816,-10624,-10432,-10240,-10048, -9856, -9664,	 -9472, -9280, -9088, -8896, -8704, -8512, -8320, -8128, -7936, -7744, -7552, -7360, -7168, -6976, -6784, -6592,
	 -6400, -6208, -6016, -5760, -5568, -5376, -5184, -4992, -4800, -4608, -4416, -4224, -4032, -3776, -3584, -3392,	 -3200, -3008, -2816, -2624, -2432, -2176, -1984, -1792, -1600, -1408, -1216, -1024,  -832,  -576,  -384,  -192,
};

int ScspTestFm(void)
{
	//
	const int cs = 3;
	const char *stype[3] = { "opll", "opllp", "vrc7" };
	const char *srhythm[5] = { "hh", "top-cym", "tom", "sd", "bd" };
	const int len = sizeof(fmsin)/sizeof(fmsin[0]);
	//
	int i, type, inst, rinst, keyon;
	unsigned int addr, sa[2], lsa[2], lea[2];
	struct PcKeySence key;

	//
	type = 0;
	inst = 4;
	rinst = 0;
	keyon = 0;
	int mdx = 0, mdy = 0;
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
		int binit = 0, bext = 0, btype = 0, binst = -1, brinst = -1, bkeyon = 0, bkeyoff = 0, bmdx = 0, bmdy = 0;
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
				brinst = 4;
				break;
			case 0x72:	//f3
				brinst = 3;
				break;
			case 0x73:	//f4
				brinst = 2;
				break;
			case 0x74:	//f5
				brinst = 1;
				break;
			case 0x75:	//f6
				brinst = 0;
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
			case 0x35:	//5
				if(key.ctrl_state&0x10)
					binst = 5;
				break;
			case 0x36:	//6
				if(key.ctrl_state&0x10)
					binst = 6;
				break;
			case 0x37:	//7
				if(key.ctrl_state&0x10)
					binst = 7;
				break;
			case 0x38:	//8
				if(key.ctrl_state&0x10)
					binst = 8;
				break;
			case 0x39:	//9
				if(key.ctrl_state&0x10)
					binst = 9;
				break;
			case 0x30:	//0
				if(key.ctrl_state&0x10)
					binst = 10;
				break;
			case 0xbd:	//-
				if(key.ctrl_state&0x10)
					binst = 11;
				break;
			case 0xde:	//^
				if(key.ctrl_state&0x10)
					binst = 12;
				break;
			case 0xdc:	//'\'
				if(key.ctrl_state&0x10)
					binst = 13;
				break;

			case 0x45:	//e
				bext = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;
			case 0xdb:	//[
				if(key.ctrl_state&0x10)
					binst = 14;
				break;

			case 0xf0:	//capslock
				btype = 1;
				break;

			case 0xdd:	//]
				if(key.ctrl_state&0x10)
					binst = 15;
				break;

			case 0x20:	//space
				if(keyon)
					bkeyoff = 1;
				else
					bkeyon = 1;
				break;

			case 0x26:	//↑
				bmdx = +1;
				break;
			case 0x25:	//←
				bmdy = -1;
				break;
			case 0x27:	//→
				bmdy = +1;
				break;
			case 0x28:	//↓
				bmdx = -1;
				break;
		}

		//
		if(binit){
			printf(".init\n");
			ResetDevice();
			WriteScspFpga(cs, 0, 0x301, 0x19);
			WriteScspWord(cs, 0, 0x100400, 0x020f);
			if(InitOpllInst())
				return 1;
			//
			addr = 0x001000;
			sa[0] = lsa[0] = addr + len*2;
			lea[0] = sa[0] + len*2;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<3*len; i++){
				short v = fmsin[i%len];
				WriteScspFpga(cs, 0, 0x308, (v>>8)&0xff);
				WriteScspFpga(cs, 0, 0x308, v&0xff);
			}
			//
			addr = 0x002000;
			sa[1] = lsa[1] = addr + len*2;
			lea[1] = sa[1] + len*2;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<3*len; i++){
				short v = fmsin[i%len];
				if(v<0)
					v = 0;
				WriteScspFpga(cs, 0, 0x308, (v>>8)&0xff);
				WriteScspFpga(cs, 0, 0x308, v&0xff);
			}
			//
			WriteScspFpga(cs, 0, 0x301, 0x11);
			keyon = 0;
		}
		//
		if(bext){
			addr = 0x100000;
			i = ReadScspWord(cs, 0, addr+0x0217)&0x00e0;
			i |= ReadScspWord(cs, 0, addr+0x0237)&0x00e0;
			if(i){
				printf(".ext_disable\n");
				WriteScspByte(cs, 0, addr+0x0217, (0<<5)|0x1f);	//left
				WriteScspByte(cs, 0, addr+0x0237, (0<<5)|0x0f);	//right
			} else {
				printf(".ext_enable\n");
				WriteScspByte(cs, 0, addr+0x0217, (7<<5)|0x1f);	//left
				WriteScspByte(cs, 0, addr+0x0237, (7<<5)|0x0f);	//right
			}						
		}

		//
		if((btype || binst>=0 || brinst>=0 || bkeyon || bkeyoff) && keyon){
			printf(".keyoff=%d\n", inst);
			//
			for(i=0; i<2; i++){
				addr = 0x100000 + i*0x20;
				unsigned short d0 = 0x0020|((sa[0]>>16)&0x000f);
				d0 &= ~0x0800;
				WriteScspWord(cs, 0, addr+0x0000, d0);
				d0 |= 0x1000;
				WriteScspWord(cs, 0, addr+0x0000, d0);
			}
			WaitMs(50);
			keyon = 0;
		}

		//
		if(btype){
			i = sizeof(stype)/sizeof(stype[0]);
			type = (type+1)%i;
			printf(".type=%d,%s\n", type, stype[type]);
		}
		//
		if(binst>=0){
			inst = binst;
			printf(".inst=%d\n", inst);
			bkeyon = 1;
		}
		//
		if(brinst>=0){
			rinst = brinst;
			printf(".rinst=%d,%s\n", rinst, srhythm[rinst]);
//			bkeyon = 1;
		}
		//
		if(bmdx!=0){
			mdx += bmdx;
			mdx &= 0x3f;
			printf(".mdx=%x\n", mdx);
		}
		if(bmdy!=0){
			mdy += bmdy;
			mdy &= 0x3f;
			printf(".mdy=%x\n", mdy);
		}
		//
		if(bkeyon){
			printf(".keyon=%d\n", inst);
			//
			const int multi2octfns[16][2] = {
				{ -1,   0 }, {  0,   0 }, {  1,   0 }, {  1, 512 },
				{  2,   0 }, {  2, 256 }, {  2, 512 }, {  2, 768 },
				{  3,   0 }, {  3, 128 }, {  3, 256 }, {  3, 256 },
				{  3, 512 }, {  3, 512 }, {  3, 896 }, {  3, 896 },
			};

			//
			int oam[2], ovib[2], oegtyp[2], oksr[2], omulti[2];
			int oksl[2], oar[2], odr[2], osl[2], orr[2];
			for(i=0; i<2; i++){
				oam[i] = (insttbl[type][inst][i]>>7)&1;
				ovib[i] = (insttbl[type][inst][i]>>6)&1;
				oegtyp[i] = (insttbl[type][inst][i]>>5)&1;
				oksr[i] = (insttbl[type][inst][i]>>4)&1;
				omulti[i] = insttbl[type][inst][i]&0xf;
				oksl[i] = (insttbl[type][inst][2+i]>>6)&3;
				oar[i] = (insttbl[type][inst][4+i]>>4)&0xf;
				odr[i] = insttbl[type][inst][4+i]&0xf;
				osl[i] = (insttbl[type][inst][6+i]>>4)&0xf;
				orr[i] = insttbl[type][inst][6+i]&0xf;
			}
			int otl = insttbl[type][inst][2]&0x3f;
			int odc = (insttbl[type][inst][3]>>4)&1;
			int odm = (insttbl[type][inst][3]>>3)&1;
			int ofb = insttbl[type][inst][3]&7;
			//
			int d2r = (oegtyp[0]?0:(orr[0]<<1))&0x1f;
			int d1r = (odr[0]<<1)&0x1f;
			int ar = (oar[0]<<1)&0x1f;
			int krs = (0xf)&0xf;
			int dl = (0x1f-osl[0]*2)&0x1f;
			int rr = (orr[0]<<1)&0x1f;
			int tl = (otl<<1)&0xff;
			int mdl = (4+ofb)&0xf;
			int mdxsl = (0x00)&0x3f;
			int mdysl = (0x00)&0x3f;
			int oct = (3+multi2octfns[omulti[0]][0])&0xf;
			int fns = (multi2octfns[omulti[0]][1])&0x3ff;
			int lfof = (0x13)&0x1f;
			int plfos = (ovib[0]?2:0)&7;
			int alfos = (oam[0]?5:0)&7;
			int disdl = (0)&7;
			//
			i = 0;
			addr = 0x100000 + i*0x20;
			WriteScspWord(cs, 0, addr+0x0002, sa[odm]&0xfffe);
			WriteScspWord(cs, 0, addr+0x0004, ((lsa[odm]-sa[odm])>>1)&0xffff);
			WriteScspWord(cs, 0, addr+0x0006, ((lea[odm]-sa[odm])>>1)&0xffff);
			WriteScspWord(cs, 0, addr+0x0008, (d2r<<11)|(d1r<<6)|ar);
			WriteScspWord(cs, 0, addr+0x000a, (krs<<10)|(dl<<5)|rr);
			WriteScspWord(cs, 0, addr+0x000c, (disdl?(1<<9):0)|tl);
			WriteScspWord(cs, 0, addr+0x000e, (mdl<<12)|(mdxsl<<6)|mdysl);
			WriteScspWord(cs, 0, addr+0x0010, (oct<<11)|fns);
			WriteScspWord(cs, 0, addr+0x0012, 0x0210|(lfof<<10)|(plfos<<5)|alfos);
			WriteScspWord(cs, 0, addr+0x0014, 0x0000);
			WriteScspWord(cs, 0, addr+0x0016, (disdl<<13));

			//
				d2r = (oegtyp[1]?0:(orr[1]<<1))&0x1f;
				d1r = (odr[1]<<1)&0x1f;
				ar = (oar[1]<<1)&0x1f;
				krs = (0xf)&0xf;
				dl = (0x1f-osl[1]*2)&0x1f;
				rr = (orr[1]<<1)&0x1f;
				tl = (0<<3)&0xff;
				mdl = (10)&0xf;
				mdxsl = (0x1f)&0x3f;
				mdysl = (0x1f)&0x3f;
				oct = (3+multi2octfns[omulti[1]][0])&0xf;
				fns = (multi2octfns[omulti[1]][1])&0x3ff;
				lfof = (0x13)&0x1f;
				plfos = (ovib[1]?2:0)&7;
				alfos = (oam[1]?5:0)&7;
				disdl = (7)&7;
			//
			i = 1;
			addr = 0x100000 + i*0x20;
			WriteScspWord(cs, 0, addr+0x0002, sa[odc]&0xfffe);
			WriteScspWord(cs, 0, addr+0x0004, ((lsa[odc]-sa[odc])>>1)&0xffff);
			WriteScspWord(cs, 0, addr+0x0006, ((lea[odc]-sa[odc])>>1)&0xffff);
			WriteScspWord(cs, 0, addr+0x0008, (d2r<<11)|(d1r<<6)|ar);
			WriteScspWord(cs, 0, addr+0x000a, (krs<<10)|(dl<<5)|rr);
			WriteScspWord(cs, 0, addr+0x000c, (disdl?(1<<9):0)|tl);
			WriteScspWord(cs, 0, addr+0x000e, (mdl<<12)|(mdxsl<<6)|mdysl);
			WriteScspWord(cs, 0, addr+0x0010, (oct<<11)|fns);
			WriteScspWord(cs, 0, addr+0x0012, 0x0210|(lfof<<10)|(plfos<<5)|alfos);
			WriteScspWord(cs, 0, addr+0x0014, 0x0000);
			WriteScspWord(cs, 0, addr+0x0016, (disdl<<13));

			//
			for(i=0; i<2; i++){
				addr = 0x100000 + i*0x20;
				unsigned int d0 = 0x0020|((sa[0]>>16)&0x000f);
				d0 |= 0x0800;
				WriteScspWord(cs, 0, addr+0x0000, d0);
				d0 |= 0x1000;
				WriteScspWord(cs, 0, addr+0x0000, d0);
			}
			WaitMs(20);
			keyon = 1;
		}
	}

	return 0;
}

//
const char *smode[3] = { "ss", "stv", "stv_2" };
const unsigned char musicvalue[3][10] = {
	{ 0x6e, 0x72, 0x68, 0x6e, 0x68, 0x6c, 0x66, 0x72, 0x74, 0x7e },	//ss
	{ 0x6e, 0x72, 0x68, 0x6e, 0x68, 0x6c, 0x66, 0x72, 0x74, 0x7e },	//stv、track10は除く
	{ 0x6e, 0x72, 0x68, 0x6e, 0x68, 0x6c, 0x66, 0x72, 0x74, 0x7e },	//stv_2、track10は除く
};
const unsigned short musictime[3][10][2] = {
	{
		{ 1*600+247, 2*600+493 },
		{ 1*600+273, 2*600+547 },
		{ 1*600+225, 2*600+450 },
		{ 1*600+119, 2*600+195 },
		{ 1*600+274, 2*600+548 },
		{ 1*600+334, 3*600+ 68 },
		{ 1*600+313, 2*600+561 },
		{ 2*600+275, 4*600+549 },
		{ 0*600+439, 1*600+277 },
		{ 1*600+486, 3*600+373 },
	},
	{
		{ 1*600+247, 2*600+493 },
		{ 1*600+273, 2*600+547 },
		{ 1*600+225, 2*600+450 },
		{ 1*600+119, 2*600+195 },
		{ 1*600+274, 2*600+548 },
		{ 1*600+334, 3*600+ 68 },
		{ 1*600+313, 2*600+561 },
		{ 2*600+275, 4*600+549 },
		{ 0*600+439, 1*600+277 },
		{ 1*600+486, 3*600+373 },
	},
	{
		{ 1*600+247, 2*600+493 },
		{ 1*600+273, 2*600+547 },
		{ 1*600+225, 2*600+450 },
		{ 1*600+119, 2*600+195 },
		{ 1*600+274, 2*600+548 },
		{ 1*600+334, 3*600+ 68 },
		{ 1*600+313, 2*600+561 },
		{ 2*600+275, 4*600+549 },
		{ 0*600+439, 1*600+277 },
		{ 1*600+486, 3*600+373 },
	},
};
const char *musiclist[3][10][5] = {
	{
		{ "SS\\SND_EFT2", "SS\\TNE_M1",  "SS\\SEQ_M1",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M2",  "SS\\SEQ_M2",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M3",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M4",  "SS\\SEQ_M4",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M5",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M6",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M7",  "SS\\SEQ_M7",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT3", "SS\\TNE_M8",  "SS\\SEQ_M8",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT4", "SS\\TNE_M9",  "SS\\SEQ_M9",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M10", "SS\\SEQ_M10", "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
	},
	{
		{ "SS\\SND_EFT2", "SS\\TNE_M1",  "SS\\SEQ_M1",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M2",  "SS\\SEQ_M2",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M3",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M4",  "SS\\SEQ_M4",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M5",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M6",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M7",  "SS\\SEQ_M7",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT3", "SS\\TNE_M8",  "SS\\SEQ_M8",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT4", "SS\\TNE_M9",  "SS\\SEQ_M9",  "SS\\TNE_GAME", "SS\\SEQ_GAME"  },
		{ "SS\\SND_EFT2", "SS\\TNE_M10", "SS\\SEQ_M10", "SS\\TNE_GAME", "SS\\SEQ_GAME"  },	//SS用
	},
	{
		{ "SS\\SND_EFT2", "SS\\TNE_M1",  "SS\\SEQ_M1",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M2",  "SS\\SEQ_M2",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M3",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M4",  "SS\\SEQ_M4",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M5",  "SS\\SEQ_M5",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M6",  "SS\\SEQ_M6",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M7",  "SS\\SEQ_M7",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT3", "SS\\TNE_M8",  "SS\\SEQ_M8",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT4", "SS\\TNE_M9",  "SS\\SEQ_M9",  "SS\\TNE_GAME", "STV\\SEQ_GAME" },
		{ "SS\\SND_EFT2", "SS\\TNE_M10", "SS\\SEQ_M10", "SS\\TNE_GAME", "SS\\SEQ_GAME"  },	//SS用
	},
};
const unsigned char selist[3][71] = {
	{
		//ss
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
		0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13,
		0x14, 0x15, 0x16, 0x17, 0x19, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
		0x1e, 0x1f, 0x1f, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
		0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31,
		0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x0e, 0x0f,
		0x3a, 0x3b, 0x3c, 0x1c, 0x10, 0x12, 0x13, 0x3d, 0x3e, 0x3f,
		0x40,
	},
	{
		//stv
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
		0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13,
		0x14, 0x15, 0x16, 0x17, 0x19, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
		0x1e, 0x1f, 0x1f, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
		0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31,
		0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x0e, 0x0f,
		0x3a, 0x3b, 0x3c, 0x1c, 0x10, 0x12, 0x13, 0x3d, 0x3e, 0x3f,
		0x40,
	},
	{
		//stv_2
		//  ※stvと同じ
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
		0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13,
		0x14, 0x15, 0x16, 0x17, 0x19, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
		0x1e, 0x1f, 0x1f, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
		0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31,
		0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x0e, 0x0f,
		0x3a, 0x3b, 0x3c, 0x1c, 0x10, 0x12, 0x13, 0x3d, 0x3e, 0x3f,
		0x40,
	},
};

void WaitCmd(int cs,  unsigned int addr, unsigned int ptrhi)
{
	int i, j, f;
	
	//
	for(i=0; i<250; i++){
		f = 1;
		for(j=0; j<8; j++){
			if((ReadScspWord(cs, addr, ptrhi+0x10*j)&0xff00)!=0){
				f = 0;
				break;
			}
		}
		if(f)
			break;
		WaitUs(11);
	}
}

int ScspTestRs(char *dir)
{
	//
	const int cs = 3;
	//
	int i, j, mode, pmode, loop, track, ptrack, number, pnumber, playm, plays;
	unsigned int ptrsit, ptrhi, ptrcrnt, ptrmap, addr;
	const char *name[5];
	struct PcKeySence key;

	//
	mode = 1;
	pmode = -1;
	loop = 0;
	track = 0;
	ptrack = -1;
	number = 1;
	pnumber = -1;
	playm = plays = 0;
	ptrsit = ptrhi = ptrcrnt = ptrmap = 0;
	memset(name, 0x00, sizeof(name));
	while(1){
		//
		int bstopm = 0;
		if(ptrhi && (loop>0 && playm) && (pmode>=0 && ptrack>=0)){
			j = ReadScspWord(cs, 0, ptrhi+0x80);
			if((j&0xff00)!=0x0000){
				i = ReadScspWord(cs, 0, ptrhi+0xb0);
				if(i>=(musictime[pmode][ptrack][(loop>1)?1:0]+100)){
					printf(".pos=0x%04x_%02d:%02d.%d\n", j, i/(60*10), (i/10)%60, i%10);
					bstopm = 1;
				}
			}
		}
		//
		PcKeySence(&key);
		if(key.key_code==0x00 || key.key_down==0){
			//入力なし、キー押上
			if(bstopm==0)
				continue;
		}

		//共通
		int binit = 0, bmode = 0, bloop = 0, btrack = 0, bnumber = 0, bplaym = 0, bplays = 0, bdsp = 0, bpos = 0;
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

			case 0x09:	//tab
				bmode = 1;
				break;
			case 0xc0:	//@
				binit = 1;
				break;
			case 0x0d:	//enter
				bplaym = 1;
				break;

			case 0x44:	//d
				bdsp = 1;
				break;
			case 0x4c:	//l
				bloop = 1;
				break;

			case 0x56:	//v
				bpos = 1;
				break;

			case 0x20:	//space
				bplays = 1;
				break;
			case 0x26:	//↑
				btrack = +1;
				break;
			case 0x25:	//←
				bnumber = -1;
				break;
			case 0x28:	//↓
				btrack = -1;
				break;
			case 0x27:	//→
				bnumber = +1;
				break;
		}

		//
		if(binit){
			printf(".init_start\n");
			memset(name, 0x00, sizeof(name));
			ResetDevice();
			//
			WriteScspFpga(cs, 0, 0x301, 0x19);
			WriteScspWord(cs, 0, 0x100400, 0x0200);
/*
			addr = 0x000000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<0xb000; i++)
				WriteScspFpga(cs, 0, 0x308, 0x00);
*/
			addr = 0x006000;
			WriteScspFpga(cs, 0, 0x304, 0x00|((addr>>17)&0x0f));
			WriteScspFpga(cs, 0, 0x303, (addr>>9)&0xff);
			WriteScspFpga(cs, 0, 0x302, (addr>>1)&0xff);
			for(i=0; i<0x4000; i++)
				WriteScspFpga(cs, 0, 0x308, 0x00);

			//
			LoadScspFile(dir, "SS\\SND_DRVR", cs, 0, 0x000000);
			ptrsit = ReadScspDword(cs, 0, 0x0400);
			ptrhi = ReadScspDword(cs, 0, 0x0404);
			ptrcrnt = ReadScspDword(cs, 0, 0x0408);
			ptrmap = ReadScspDword(cs, 0, ptrsit+0x08);
			printf("ptrsit=0x%06x, ", ptrsit);
			printf("ptrhi=0x%06x, ", ptrhi);
			printf("ptrcrnt=0x%06x, ", ptrcrnt);
			printf("ptrmap=0x%06x\n", ptrmap);
			if(0){
				//※テスト用
				WriteScspByte(cs, 0, 0x10ab, 0x03);
				WriteScspByte(cs, 0, 0x3a8b, 0x03);
			}
			
			//
			LoadScspFile(dir, "SS\\SND_MAP", cs, 0, ptrmap);

			//
			WriteScspFpga(cs, 0, 0x301, 0x18);
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0x00);
			WriteScspWord(cs, 0, ptrhi, 0x0800);
			//
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0x00);
			WriteScspWord(cs, 0, ptrhi, 0x0800);

			//
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0x0f);
			WriteScspWord(cs, 0, ptrhi, 0x8200);

			//
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0x00);
			WriteScspByte(cs, 0, ptrhi+3, 0x00);
			WriteScspByte(cs, 0, ptrhi+4, 0x01);
			WriteScspByte(cs, 0, ptrhi+5, 0x00);
			WriteScspByte(cs, 0, ptrhi+6, 0x00);
			WriteScspWord(cs, 0, ptrhi, 0x1000);
			WaitMs(200);

/*			//
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0xe0);
			WriteScspByte(cs, 0, ptrhi+3, 0xe0);
			WriteScspWord(cs, 0, ptrhi, 0x8000);

			//
			WaitCmd(cs, 0, ptrhi);
			WriteScspByte(cs, 0, ptrhi+2, 0x1f);
			WriteScspByte(cs, 0, ptrhi+3, 0x0f);
			WriteScspWord(cs, 0, ptrhi, 0x8100);*/

			//
			if(name[0]!=musiclist[mode][track][0]){
				for(i=0; i<32; i++){
					addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
					if((addr>>24)&0x80)
						break;
					if(((addr>>24)&0x7f)!=0x20)
						continue;
					//
					name[0] = musiclist[mode][track][0];
					WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
					LoadScspFile(dir, name[0], cs, 0, addr&0x0fffff);
					printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
					break;
				}

				//
				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspByte(cs, 0, ptrhi+3, 0x00);
				WriteScspByte(cs, 0, ptrhi+4, 0x00);
				WriteScspByte(cs, 0, ptrhi+5, 0x01);
				WriteScspByte(cs, 0, ptrhi+6, 0x01);
				WriteScspWord(cs, 0, ptrhi, 0x1000);
				WaitMs(200);
	
				//
				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspWord(cs, 0, ptrhi, 0x8300);

				//
				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspByte(cs, 0, ptrhi+3, 0x00);
				WriteScspWord(cs, 0, ptrhi, 0x8700);
	
				//
				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+2, 0x01);
				WriteScspByte(cs, 0, ptrhi+3, 0xf1);
				WriteScspWord(cs, 0, ptrhi, 0x8800);
				//
				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspByte(cs, 0, ptrhi+3, 0xef);
				WriteScspWord(cs, 0, ptrhi, 0x8800);
			}

			//
			if(name[3]!=musiclist[mode][track][3]){
				for(i=0; i<32; i++){
					addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
					if((addr>>24)&0x80)
						break;
					if(((addr>>24)&0x7f)!=0x01)
						continue;
					//
					name[3] = musiclist[mode][track][3];
					WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
					LoadScspFile(dir, name[3], cs, 0, addr&0x0fffff);
					printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
					break;
				}
			}

			//
			if(name[4]!=musiclist[mode][track][4]){
				for(i=0; i<32; i++){
					addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
					if((addr>>24)&0x80)
						break;
					if(((addr>>24)&0x7f)!=0x11)
						continue;
					//
					name[4] = musiclist[mode][track][4];
					WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
					LoadScspFile(dir, name[4], cs, 0, addr&0x0fffff);
					printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
					break;
				}
			}
			
			//
			WriteScspFpga(cs, 0, 0x301, 0x10);
			printf(".init_end\n");
		}
		
		//
		if(bmode){
			i = sizeof(smode)/sizeof(smode[0]);
			mode = (mode+1)%i;
			printf(".mode=%d,%s\n", mode, smode[mode]);
		}
		if(bloop){
			i = 3;
			loop = (loop+1)%i;
			printf(".loop=%d\n", loop);
		}
		if(btrack){
			i = sizeof(musiclist[0])/sizeof(musiclist[0][0]);
			track += btrack;
			if(track<0)
				track = 0;
			else
			if(track>(i-1))
				track = (i-1);
			else
				printf(".track=%s,%d/%d,%s\n", smode[mode], track+1, i, musiclist[mode][track][2]);
		}
		if(bnumber){
			i = (0)?128:sizeof(selist[0])/sizeof(selist[0][0]);
			number += bnumber;
			if(number<0)
				number = 0;
			else
			if(number>(i-1))
				number = (i-1);
			else
				printf(".number=%s,%d/%d,0x%02x\n", smode[mode], number+1, i, selist[mode][number]);
		}

		//
		if(bdsp){
			i = ReadScspWord(cs, 0, 0x100ee0);
			j = ReadScspWord(cs, 0, 0x100ee0+2);
			printf("dsp=0x%04x,0x%04x\n", i, j);
		}

		//
		if(!(ptrsit && ptrhi && ptrcrnt && ptrmap))
			continue;

		//
		if(bplaym || bstopm){
			playm ^= 1;
			if(!playm){
				printf(".stopm=%s,%d,%s\n", smode[pmode], ptrack+1, musiclist[pmode][ptrack][2]);
//				pmode = -1;
//				ptrack = -1;
				//
				WaitCmd(cs, 0, ptrhi);
				//停止
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspByte(cs, 0, ptrhi+3, 0x00);
				WriteScspWord(cs, 0, ptrhi, 0x0200);
			} else {
				printf(".playm=%s,%d,%s\n", smode[mode], track+1, musiclist[mode][track][2]);
				pmode = mode;
				ptrack = track;

{
				//
				if(name[0]!=musiclist[mode][track][0]){
					for(i=0; i<32; i++){
						addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
						if((addr>>24)&0x80)
							break;
						if(((addr>>24)&0x7f)!=0x20)
							continue;
						//
						name[0] = musiclist[mode][track][0];
						WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
						LoadScspFile(dir, name[0], cs, 0, addr&0x0fffff);
						printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
						break;
					}
	
					//
					WaitCmd(cs, 0, ptrhi);
					WriteScspByte(cs, 0, ptrhi+2, 0x00);
					WriteScspByte(cs, 0, ptrhi+3, 0x00);
					WriteScspByte(cs, 0, ptrhi+4, 0x00);
					WriteScspByte(cs, 0, ptrhi+5, 0x01);
					WriteScspByte(cs, 0, ptrhi+6, 0x01);
					WriteScspWord(cs, 0, ptrhi, 0x1000);
					WaitMs(200);
		
					//
					WaitCmd(cs, 0, ptrhi);
					WriteScspByte(cs, 0, ptrhi+2, 0x00);
					WriteScspWord(cs, 0, ptrhi, 0x8300);
	
					//
					WaitCmd(cs, 0, ptrhi);
					WriteScspByte(cs, 0, ptrhi+2, 0x00);
					WriteScspByte(cs, 0, ptrhi+3, 0x00);
					WriteScspWord(cs, 0, ptrhi, 0x8700);
		
					//
					WaitCmd(cs, 0, ptrhi);
					WriteScspByte(cs, 0, ptrhi+2, 0x01);
					WriteScspByte(cs, 0, ptrhi+3, 0xf1);
					WriteScspWord(cs, 0, ptrhi, 0x8800);
					//
					WaitCmd(cs, 0, ptrhi);
					WriteScspByte(cs, 0, ptrhi+2, 0x00);
					WriteScspByte(cs, 0, ptrhi+3, 0xef);
					WriteScspWord(cs, 0, ptrhi, 0x8800);
				}
}

				//
				if(name[1]!=musiclist[mode][track][1]){
					for(i=0; i<32; i++){
						addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
						if((addr>>24)&0x80)
							break;
						if(((addr>>24)&0x7f)!=0x00)
							continue;
						//
						name[1] = musiclist[mode][track][1];
						WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
						LoadScspFile(dir, name[1], cs, 0, addr&0x0fffff);
						printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
						break;
					}
				}

				//
				if(name[2]!=musiclist[mode][track][2]){
					for(i=0; i<32; i++){
						addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
						if((addr>>24)&0x80)
							break;
						if(((addr>>24)&0x7f)!=0x10)
							continue;
						//
						name[2] = musiclist[mode][track][2];
						WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
						LoadScspFile(dir, name[2], cs, 0, addr&0x0fffff);
						printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
						break;
					}
				}

{
				//
				if(name[3]!=musiclist[mode][track][3]){
					for(i=0; i<32; i++){
						addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
						if((addr>>24)&0x80)
							break;
						if(((addr>>24)&0x7f)!=0x01)
							continue;
						//
						name[3] = musiclist[mode][track][3];
						WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
						LoadScspFile(dir, name[3], cs, 0, addr&0x0fffff);
						printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
						break;
					}
				}
	
				//
				if(name[4]!=musiclist[mode][track][4]){
					for(i=0; i<32; i++){
						addr = ReadScspDword(cs, 0, ptrcrnt+i*8);
						if((addr>>24)&0x80)
							break;
						if(((addr>>24)&0x7f)!=0x11)
							continue;
						//
						name[4] = musiclist[mode][track][4];
						WriteScspByte(cs, 0, ptrcrnt+i*8+4, 0x80);
						LoadScspFile(dir, name[4], cs, 0, addr&0x0fffff);
						printf(".size=%d\n", ReadScspDword(cs, 0, ptrcrnt+i*8+4)&0x0fffff);
						break;
					}
				}
}

				//
				WaitCmd(cs, 0, ptrhi);
				//開始
				WriteScspByte(cs, 0, ptrhi+2, 0x00);
				WriteScspByte(cs, 0, ptrhi+3, 0x00);
				WriteScspByte(cs, 0, ptrhi+4, 0x00);
{
		char path[128];
		sprintf(path, ".\\_mem_%s,%d.bin", smode[mode], track+1);
//		SaveScspFile(path, cs, 0, 0x000000, 0x080000);
//		SaveScspFile(path, cs, 0, 0x000000, 0x00a000);
}
				WriteScspWord(cs, 0, ptrhi, 0x0100);

				//
//				WaitCmd(cs, 0, ptrhi);
				WriteScspByte(cs, 0, ptrhi+0x12, 0x00);
				WriteScspByte(cs, 0, ptrhi+0x13, musicvalue[mode][track]);
				WriteScspByte(cs, 0, ptrhi+0x14, 0x00);
				WriteScspWord(cs, 0, ptrhi+0x10, 0x0500);
			}
		}
		//
		if(bplays){
			plays ^= 1;
			if(!plays){
				printf(".stops=%s,%d,0x%02x\n", smode[mode], pnumber+1, selist[mode][pnumber]);
//				pnumber = -1;
				//
				WaitCmd(cs, 0, ptrhi);
				//停止
				WriteScspByte(cs, 0, ptrhi+2, 0x01);
				WriteScspByte(cs, 0, ptrhi+3, 0x00);
				WriteScspWord(cs, 0, ptrhi, 0x0200);
			} else {
				printf(".plays=%s,%d,0x%02x\n", smode[mode], number+1, selist[mode][number]);
				pnumber = number;
				//
				WaitCmd(cs, 0, ptrhi);
				//開始
				WriteScspByte(cs, 0, ptrhi+2, 0x01);
				WriteScspByte(cs, 0, ptrhi+3, 0x01);
				WriteScspByte(cs, 0, ptrhi+4, (0)?number:selist[0][number]);
				WriteScspWord(cs, 0, ptrhi, 0x0100);
			}
		}
		//
		if(bpos){
			i = ReadScspWord(cs, 0, ptrhi+0xb0);
			j = 0;
			if(pmode>=0 && ptrack>=0){
				if(i>=musictime[pmode][ptrack][0]){
					j = i - musictime[pmode][ptrack][0];
					j /= musictime[pmode][ptrack][1] - musictime[pmode][ptrack][0];
					j++;
				}
			}
			printf(".pos=0x%04x_%02d:%02d.%d_loop%d, ", ReadScspWord(cs, 0, ptrhi+0x80), i/(60*10), (i/10)%60, i%10, j);
			i = ReadScspWord(cs, 0, ptrhi+0xb2);
			printf("0x%04x_%02d:%02d.%d\n", ReadScspWord(cs, 0, ptrhi+0x82), i/(60*10), (i/10)%60, i%10);
		}
	}
}
#endif
#endif
