
#include <plib.h>
#include <stdio.h>
#include <string.h>
#include "types.h"
#include "hio.h"
#include "timer2.h"

#pragma config FPLLMUL = MUL_20, FPLLIDIV = DIV_4, FPLLODIV = DIV_1, FWDTEN = OFF	//80MHz
#pragma config POSCMOD = XT, FNOSC = PRIPLL, FPBDIV = DIV_1, FUSBIDIO = OFF
#pragma config UPLLEN = ON, UPLLIDIV = DIV_4

//Ethernet Alt I/O setting, RMII PHY
#pragma config FETHIO = OFF, FMIIEN = OFF

//
unsigned int sys_clk, pb_clk, pb_clk_khz;

//
unsigned char pktbuf[2048];
unsigned char pipe0buf[2048];
unsigned char pipe1buf[2048];

int main(void)
{
#if 0
	//sys_clk=32M, pb_clk=4M
	const unsigned long int fpllmul = OSC_PLL_MULT_16, fpllodiv = OSC_PLL_POST_2;
	const unsigned int fpbdiv = OSC_PB_DIV_8;
#endif
#if 1
	//sys_clk=48M, pb_clk=6M
	const unsigned long int fpllmul = OSC_PLL_MULT_24, fpllodiv = OSC_PLL_POST_2;
	const unsigned int fpbdiv = OSC_PB_DIV_8;
#endif
#if 0
	//sys_clk=64M, pb_clk=8M
	const unsigned long int fpllmul = OSC_PLL_MULT_16, fpllodiv = OSC_PLL_POST_1;
	const unsigned int fpbdiv = OSC_PB_DIV_8;
#endif
#if 0
	//sys_clk=80M, pb_clk=80M
	const unsigned long int fpllmul = OSC_PLL_MULT_20, fpllodiv = OSC_PLL_POST_1;
	const unsigned int fpbdiv = OSC_PB_DIV_1;
#endif

	//
	if((OSCCONbits.PLLMULT<<_OSCCON_PLLMULT_POSITION)!=fpllmul || (OSCCONbits.PLLODIV<<_OSCCON_PLLODIV_POSITION)!=fpllodiv)
		OSCConfig(OSC_POSC_PLL, fpllmul, fpllodiv, 0);
	//
	const unsigned int pll_mult[8]={ 15, 16, 17, 18, 19, 20, 21, 24 };
	const unsigned int pll_idiv[8]={ 1, 2, 3, 4, 5, 6, 10, 12 };
	sys_clk = (16000000 * pll_mult[OSCCONbits.PLLMULT]) / (pll_idiv[DEVCFG2bits.FPLLIDIV] * (1<<OSCCONbits.PLLODIV));
	//
	pb_clk = SYSTEMConfig(sys_clk, SYS_CFG_WAIT_STATES | SYS_CFG_PCACHE | SYS_CFG_PB_BUS);
	if((OSCCONbits.PBDIV<<_OSCCON_PBDIV_POSITION)<fpbdiv){
		OSCSetPBDIV(fpbdiv);
		pb_clk = SYSTEMConfig(sys_clk, 0);
	}
	pb_clk_khz = (pb_clk+999)/1000;

	//
	InitPort();
	INTEnableSystemMultiVectoredInt();

	// 
	InitBuf();
//	ResetDevice();

	//
	struct PcSync sync;
	if(PcSync("psl", &sync))
		PcReset();
#if 0
	printf(".sync.req_name(%s)\n", sync.req_name);
	if(strcmp(sync.req_name, "psl"))
		PcReset();
#endif

	//
	int pipenum, pktbuflen, pktrptr, pktlen;
	//
	pipenum = 0;
	pktbuflen = sizeof(pktbuf)/sizeof(pktbuf[0]);
	pktrptr = pktlen = 0;

	//
	struct tagPipe {
		unsigned char *buf;
		int buflen;
		int rptr, length;
	} pipe[2];
	//
	pipe[0].buf = pipe0buf;
	pipe[0].buflen = sizeof(pipe0buf)/sizeof(pipe0buf[0]);
	pipe[0].rptr = pipe[0].length = 0;
	//
	pipe[1].buf = pipe1buf;
	pipe[1].buflen = sizeof(pipe1buf)/sizeof(pipe1buf[0]);
	pipe[1].rptr = pipe[1].length = 0;

	//
#ifdef __DEBUG
	printf(".build(debug,\"%s\",%s)\n", __DATE__, __TIME__);
#else
	printf(".build(release,\"%s\",%s)\n", __DATE__, __TIME__);
#endif
	printf(".sys_clk(%u)\n", sys_clk);
	printf(".pb_clk(%u,%uk)\n", pb_clk, pb_clk_khz);
	printf(".rev_str(%s)\n", REV_STR);
	printf(".timer2_freq(%u)\n", TIMER2_FREQ);

#ifdef __DEBUG
	//
	volatile unsigned int *psdptr = (void *)0x9d07d6d8;
	unsigned char *psdorg = (void *)0x9d07d6b8;
	unsigned char *psd = (void *)(*psdptr);
	unsigned char *psd2 = (void *)0x9d07ff00;
	if(psd==psdorg || psd==psd2){
		//
		int i;
		unsigned char writebuf[256];
		unsigned int int_status, pagebuf[PAGE_SIZE];
		const unsigned char *p, *str_psd2 = " Sound Generator Device " REV_STR;
		//
		printf(".product_string_descriptor_original(0x%08x,\"", (unsigned int)psdorg);
		for(i=2; i<psdorg[0]; i+=2)
			printf("%c", psdorg[i]);
		printf("\")\n");
		printf(".product_string_descriptor(0x%08x,\"", (unsigned int)psd);
		for(i=2; i<psd[0]; i+=2)
			printf("%c", psd[i]);
		printf("\")\n");
		//
		if(strcmp(sync.arg1, "/psdw")==0){
			//‘‚«Š·‚¦
			if(psd!=psd2){
				//‘‚«Š·‚¦‚Ä‚¢‚È‚¢
				i = psd[0];
				memcpy(writebuf, psd, i);
				for(p=str_psd2; *p!='\0'; p++){
					writebuf[i++] = *p;
					writebuf[i++] = 0x00;
					if(i>=(sizeof(writebuf)-2))
						break;
				}
				writebuf[0] = i;
				memset(writebuf+i, 0xff, sizeof(writebuf)-i);
				//
				int_status = INTDisableInterrupts();
				if(NVMProgram(psd2, writebuf, sizeof(writebuf), pagebuf)==0){
					memcpy(writebuf, &psd2, sizeof(psd2));
					NVMProgram((void *)psdptr, writebuf, sizeof(*psdptr), pagebuf);
				}
				INTRestoreInterrupts(int_status);
				//
				psd = (void *)(*psdptr);
				printf(".product_string_descriptor'(0x%08x,\"", (unsigned int)psd);
				for(i=2; i<psd[0]; i+=2)
					printf("%c", psd[i]);
				printf("\")\n");
			}
		} else
		if(strcmp(sync.arg1, "/psdr")==0){
			//–ß‚·
			if(psd==psd2){
				//‘‚«Š·‚¦Ï‚Ý
				int_status = INTDisableInterrupts();
				memcpy(writebuf, &psdorg, sizeof(psdorg));
				NVMProgram((void *)psdptr, writebuf, sizeof(*psdptr), pagebuf);
				INTRestoreInterrupts(int_status);
				//
				psd = (void *)(*psdptr);
				printf(".product_string_descriptor'(0x%08x,\"", (unsigned int)psd);
				for(i=2; i<psd[0]; i+=2)
					printf("%c", psd[i]);
				printf("\")\n");
			}
		}
	}	
	printf(".pktbuflen(%u)\n", pktbuflen);
	printf(".pipe[0].buflen(%u)\n", pipe[0].buflen);
	printf(".pipe[1].buflen(%u)\n", pipe[1].buflen);
	//
	Test(&sync);
#endif
	//
	PcFlush();
	PcExit();

	//
	while(1){
		//
		unsigned int gp;
		__asm__ __volatile__ ("move %0, $gp" : "=r" (gp));
		gp += (short)0x8300;
		volatile unsigned char *pp = (void *)(*((volatile unsigned int *)gp));
		if(pp!=NULL){
			if(pktlen==0 && (pp[0]&(1<<7))==0){
				int lim = ((pp[3]<<8)|pp[2])&0x03ff;
				if(lim>=2){
					int len = PcEp2Read(pktbuf, lim);
					pipenum = (pktbuf[1]&0xc0)?1:0;
					pktrptr = 2;
					pktlen = ((pktbuf[1]<<8)|pktbuf[0])&0x3fff;
					//
					lim = (pktrptr+pktlen)-len;
					if(lim>0){
#if 0
						mPORTAToggleBits(BIT_0);
#endif
						len += PcEp2Read(pktbuf+len, lim);
					}
				}
			}
		}
		//
		if(pktlen){
			struct tagPipe *p = &pipe[pipenum];
			if(p->length){
				//buffer full
			} else {
				//
				memcpy(p->buf, pktbuf+pktrptr, pktlen);
				p->rptr = 0;
				p->length += pktlen;
				pktrptr += pktlen;
				pktlen -= pktlen;
			}
		}

		//pipe0
		//  control command
		if(pipe[0].length){
			int len = pipe[0].length;
			len = ControlCommand(pipe[0].buf+pipe[0].rptr, len);
			pipe[0].rptr += len;
			pipe[0].length -= len;
		}
		//pipe1
		//  data command
		if(pipe[1].length){
			int len = (pipe[1].length>64)?64:pipe[1].length;
			len = DataCommand(pipe[1].buf+pipe[1].rptr, len);
			pipe[1].rptr += len;
			pipe[1].length -= len;
		}

		//
		TD_Poll();
	}
}
