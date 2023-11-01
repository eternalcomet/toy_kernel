#include "ide.h"
#include "lang/asm/x86.h"

const u32 SECTOR_SIZE = 512;

void ide_wait_ready() {
    // wait for BSY to be 0 and RDY be 1
    while (inb(IDE_PORT_STATUS) & (IDE_STATUS_BSY | IDE_STATUS_RDY) != IDE_STATUS_RDY);
}

bool ide_read_sector(u32 lba, u8 count, u8* buffer) {
    //LBA-28 mode
    // 计算LBA地址的四个字节（低、中、高、最高）
    u8 lba_low = lba /*& 0xFF*/; // will trancate automatically
    u8 lba_mid = (lba >> 8) /*& 0xFF*/;
    u8 lba_high = (lba >> 16) /*& 0xFF*/;
    u8 lba_highest = (lba >> 24) & 0xF;

    // // 计算缓冲区的物理地址的三个部分（页、低、高）
    // u8 addr_page = ((u32)buffer >> 16) & 0xFF;
    // u8 addr_low = (u32)buffer & 0xFF;
    // u8 addr_high = ((u32)buffer >> 8) & 0xFF;

    ide_wait_ready();
    outb(IDE_PORT_SECTOR_COUNT, count);
    outb(IDE_PORT_LBA_LOW, lba_low);
    outb(IDE_PORT_LBA_MID, lba_mid);
    outb(IDE_PORT_LBA_HIGH, lba_high);
    outb(IDE_PORT_DRIVE_HEAD, lba_highest | 0xE0); // 发送LBA地址的最高字节和驱动器号（0xE0表示主驱动器）
    outb(IDE_PORT_COMMAND, IDE_CMD_READ_SECTORS_WITH_RETRY);
    ide_wait_ready();
    insl(IDE_PORT_DATA, buffer, count * SECTOR_SIZE / 4);

    return inb(IDE_PORT_STATUS) & (IDE_STATUS_ERR | IDE_STATUS_DF) == 0;
}