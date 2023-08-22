#include "lang/c/types32.h"

const int SCREEN_WIDTH = 80;
#define screen_pos(x, y) (SCREEN_WIDTH * (x) + (y)) * 2  // 80x25 screen
byte* const screen = (byte*)0xb8000;
static int screen_pos_x = 0;
static int screen_pos_y = 0;

void putcharb(char c) {
    if (c != '\n') screen[screen_pos(screen_pos_x, screen_pos_y)] = c;
    if (c == '\n' || ++screen_pos_y >= SCREEN_WIDTH) {
        screen_pos_y = 0;
        ++screen_pos_x;
    }
}

void printb(char* str) {
    while (*str) {
        putcharb(*str++);
    }
}

// This function will be called by `mbr_boot.asm`
int main() {
    printb("Hello C World!\n");
    return 0;
}