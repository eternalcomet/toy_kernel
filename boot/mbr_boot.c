#include "lang/c/types32.h"
#include "driver/storage/ide/ide.c"

const int SCREEN_WIDTH = 80;
#define screen_pos(x, y) (SCREEN_WIDTH * (x) + (y)) * 2  // 80x25 screen
byte* const screen = (byte*)0xb8000;
static int screen_pos_x = 0;
static int screen_pos_y = 0;
static byte boot_loader_elf[512];

void putcharb(char c) {
    if (c != '\n') screen[screen_pos(screen_pos_x, screen_pos_y)] = c;
    if (c == '\n' || ++screen_pos_y >= SCREEN_WIDTH) {
        screen_pos_y = 0;
        ++screen_pos_x;
    }
}

void printb(const char* str) {
    while (*str) {
        putcharb(*str++);
    }
}

// void print_intb(int i) {
//     char buf[16];
//     char* p = buf + 15;
//     *p = 0;
//     if (i < 0) {
//         putcharb('-');
//         i = -i;
//     }
//     for (; i > 0; i /= 10) {
//         *(--p) = '0' + i % 10;
//     }
//     printb(p);
// }

// This function will be called by `mbr_boot.asm`
int main() {
    const char* const HELLO_WORLD = "Hello World!\n";
    printb(HELLO_WORLD);
    // putcharb('\n');
    // print_intb((int)&boot_loader_elf);
    bool res = ide_read_sector(1, 1, boot_loader_elf);
    putcharb('a' + res);

    printb(boot_loader_elf);
    return 0;
}
