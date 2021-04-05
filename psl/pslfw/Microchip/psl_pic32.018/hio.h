#define PC_RDONLY		0x01	//�ǂݍ��ݐ�p
#define PC_WRONLY		0x02	//�������ݐ�p
#define PC_RDWR			0x03	//�ǂݏ���
#define PC_BINARY		0x04	//�o�C�i�����[�h
#define PC_APPEND		0x10	//�ǉ�
#define PC_CREAT		0x20	//�t�@�C�����쐬����
#define PC_TRUNC		0x40	//�t�@�C���̒������O�ɂ���

#define PC_SEEK_SET		0		//�t�@�C���̐擪����
#define PC_SEEK_CUR		1		//���݂̃t�@�C���|�C���g����
#define PC_SEEK_END		2		//�t�@�C���̍Ōォ��

#define	PC_STDOUT

struct PcSync{
	u8 req_reset;
	s8 req_name[12];
	s8 arg1[21];
	s8 arg2[10];
	s8 arg3[10];
	s8 arg4[10];
};

struct PcKeySence{
	u16	ctrl_state;	//SHIFT,ALT,CTRL etc
	u8	key_down;	//0:up 1:down
	u8	key_code;
};

#define LONGCALL	__longcall__

void	LONGCALL	PcInit();
s32		LONGCALL	PcOpen(s8 *fname,s32 mode);
s32		LONGCALL	PcClose(s32 fh);
s32		LONGCALL	PcRead(s32 fh, void *buf, s32 len);
s32		LONGCALL	PcWrite(s32 fh,void *buf, s32 len);
s32		LONGCALL	PcLseek(s32 fh,s32 ofs, s32 where);
void	LONGCALL	PcPuts(s8 *str);
void	LONGCALL	PcPutc(s8 c);
void	LONGCALL	PcFlush();
s32		LONGCALL	PcGets(s8 *str);
s32		LONGCALL	PcGetc();
void	LONGCALL	PcReset();
s32		LONGCALL	PcSync(s8 *name, struct PcSync *sync);
void	LONGCALL	PcExit();
void	LONGCALL	PcHexLoad(s8 *fname, u32 flash_addr);
s32		LONGCALL	PcSvfLoad(s8 *fname);
void	LONGCALL	PcKeySence(struct PcKeySence *key);
s32		LONGCALL	PcEp2Read(u8 *buf, s32 len);
s32		LONGCALL	PcEp2Write(u8 *buf, s32 len);
