#include <fat.h>


#define FAT_ATTR_READ_ONLY	0x01
#define FAT_ATTR_HIDDEN		0x02
#define FAT_ATTR_SYSTEM		0x04
#define FAT_ATTR_VOLUME_ID	0x08
#define FAT_ATTR_DIRECTORY	0x10
#define FAT_ATTR_ARCHIVE		0x20
#define FAT_ATTR_LONG_NAME	(FAT_ATTR_READ_ONLY | FAT_ATTR_HIDDEN\
 				| FAT_ATTR_SYSTEM| FAT_ATTR_VOLUME_ID)

#define FAT_DIR_ENTRY_SIZE	32


struct fat_bpb {

	char BS_jmpBoot[3];
	char BS_OEMName[8];
	WORD BPB_BytsPerSec;
	BYTE BPB_SecPerClus;
	WORD BPB_RsvdSecCnt;
	BYTE BPB_NumFATs;
	WORD BPB_RootEntCnt;
	WORD BPB_TotSec16;
	BYTE BPB_Media;
	WORD BPB_FATSz16;
	WORD BPB_SecPertrk;
	WORD BPB_NumHeads;
	DWORD BPB_HiddSec;
	DWORD BPB_TotSec32;
	
union {
 	struct {// Para FAT12/FAT16

	BYTE BS_DrvNum;
	BYTE BS_Reserved1;
	BYTE BS_BootSig;
	DWORD BS_VolID;
	char BS_VolLab[11];
	char BS_FilSysType[8];
		
		}__attribute__ ((packed)) fat12_or_fat16;

	struct { // Para FAT32
	
	DWORD BPB_FATSz32;
	WORD BPB_ExtFlags;
	WORD BPB_FSVer;
	DWORD BPB_RootClus;
	WORD BPB_FSInfo;
	WORD BPB_BkBootSec;
	char BPB_Reserved[12];
	BYTE BS_DrvNum;
	BYTE BS_Reserved1;
	BYTE BS_BootSig;
	DWORD BS_VolID;
	char BS_VolLab[11];
	char BS_FilSysType[8];

		}__attribute__ ((packed)) fat32;
	}__attribute__ ((packed)) version_specific;
}__attribute__ ((packed));


struct fat_directory{
	
	char DIR_Name[8];
	char DIR_Name_Ext[3];
	BYTE DIR_Attr;
	BYTE DIR_NTRes;
	BYTE DIR_CrtTimeTenth;
	WORD DIR_CrtTime;
	WORD DIR_CrtDate;
	WORD DIR_LstAccDate;
	WORD DIR_FstClusHI;
	WORD DIR_WrtTime;
	WORD DIR_WrtDate;
	WORD DIR_FstClusLO;
	DWORD DIR_FileSize;
	
}__attribute__ ((packed));
