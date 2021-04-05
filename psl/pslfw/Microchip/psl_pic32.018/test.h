#ifndef TEST_H
#define TEST_H

//
int PortTest(void);
int Ga20Test(char *path);
int SccTest(void);
int OpxPcmd8Mem(void);
int Rp2a03Test(void);

//opll
int OpllTest(void);
int OpllTest2(void);
int OpllInst(void);
int OpllRhythm(void);
//opl
int OplInst(void);
int OplTest(void);
int MsxaudioMem(void);
int MsxaudioAdpcm(void);
int Opl4RomRead(char *path, int memtype);
int Opl4mlPowerdown(void);

//opn
int Opn3lSsg(void);
int OpnbTest(void);
int OpnaAdpcm(void);
int OpnaPcm(void);

//scsp
int ScspTest(void);
int ScspTestFm(void);
int ScspTestRs(char *dir);

//spu
int SpuTest(char *path);

//
extern unsigned char insttbl[3][16+3][8];
int InitOpllInst(void);
extern const unsigned char adpcm[4096];
extern const unsigned char pcm[441*2];

#endif
// END OF TEST.H
