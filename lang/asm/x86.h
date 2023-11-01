#pragma once

#include "lang/c/types32.h"
static inline u8 inb(u16 port) {
    u8 data;
    asm volatile("in %w1,%b0" : "=a" (data) : "d" (port));
    return data;
}

static inline void outb(u16 port, u8 data) {
    asm volatile("out %b0,%w1" :: "a" (data), "d" (port));
}

static inline void insl(u16 port, void* dest, u32 cnt) {
    asm volatile("cld; rep insl" :
    "=D" (dest), "=c" (cnt) :
        "d" (port), "0" (dest), "1" (cnt) :
        "memory", "cc");
}