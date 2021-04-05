#ifndef TIMER2_H
#define TIMER2_H

//
#define REV_STR		"r0.18"
#define TIMER2_FREQ	980	//44100/45

//
extern unsigned int sys_clk, pb_clk, pb_clk_khz;
extern volatile unsigned int g_dwBaseTime;

//
void InitPort(void);
void InitBuf(void);
void ResetDevice(void);
void SetTimer2(unsigned int v);
int ControlCommand(unsigned char *p, int len);
int DataCommand(unsigned char *p, int len);
void TD_Poll(void);

//
void WaitUs(unsigned int i);
void WaitMs(unsigned int i);
void WriteByteCsbit(unsigned int csbit, unsigned int addr, unsigned char data);
void WriteIc(int cs, unsigned int base, unsigned char data);
void WriteIcCsbit(unsigned int csbit, unsigned int base, unsigned char data);
unsigned char ReadIc(int cs, unsigned int base);
void InitPort(void);
void ResetDevice(void);
void ChkStatusReg(int cs, unsigned int base, unsigned char mask, unsigned char eq);
void Test(struct PcSync *sync);

#endif
// END OF TIMER2.H
