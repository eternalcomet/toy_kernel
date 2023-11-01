#pragma once

// 定义IDE控制器的端口地址
#define IDE_PORT_DATA 0x1F0
#define IDE_PORT_ERROR 0x1F1
#define IDE_PORT_SECTOR_COUNT 0x1F2
#define IDE_PORT_LBA_LOW 0x1F3
#define IDE_PORT_LBA_MID 0x1F4
#define IDE_PORT_LBA_HIGH 0x1F5
#define IDE_PORT_DRIVE_HEAD 0x1F6
#define IDE_PORT_STATUS 0x1F7
#define IDE_PORT_COMMAND 0x1F7

// 定义IDE控制器的状态位
#define IDE_STATUS_ERR (1 << 0)
#define IDE_STATUS_DRQ (1 << 3)
#define IDE_STATUS_SRV (1 << 4)
#define IDE_STATUS_DF (1 << 5)
#define IDE_STATUS_RDY (1 << 6)
#define IDE_STATUS_BSY (1 << 7)

// 定义IDE控制器的命令码
#define IDE_CMD_READ_SECTORS_WITH_RETRY 0x20
#define IDE_CMD_READ_SECTORS_NO_RETRY 0x21
#define IDE_CMD_WRITE_SECTORS_WITH_RETRY 0x30
#define IDE_CMD_WRITE_SECTORS_NO_RETRY 0x31

// 定义DMA控制器的端口地址
#define DMA_PORT_ADDR_2 0x04 // DMA通道2的地址寄存器端口
#define DMA_PORT_COUNT_2 0x05 // DMA通道2的计数寄存器端口
#define DMA_PORT_PAGE_2 0x81 // DMA通道2的页寄存器端口
#define DMA_PORT_COMMAND 0x08 // DMA命令寄存器端口
#define DMA_PORT_MODE 0x0B // DMA模式寄存器端口

// 定义DMA控制器的命令码和模式码
#define DMA_CMD_MEM_TO_MEM (1 << 6) // 内存到内存传输使能位
#define DMA_CMD_CASCADE (1 << 7) // 级联传输使能位
#define DMA_MODE_SINGLE_TRANSFER (1 << 6) // 单次传输模式位
#define DMA_MODE_DEMAND_TRANSFER (2 << 6) // 请求传输模式位
#define DMA_MODE_BLOCK_TRANSFER (3 << 6) // 块传输模式位

void ide_wait_ready();
bool ide_read_sector(u32 lba, u8 count, u8* buffer);