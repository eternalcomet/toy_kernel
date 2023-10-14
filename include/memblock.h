#define ULLONG_MAX (~0ULL)

#define MEMBLOCK_ALLOC_ACCESSIBLE 0

struct memblock_region{
  u64 base;
  u64 size;
  //enum memblock_flags flags;
};

struct memblock_type{
  u32 cnt;
  u64 max;
  u64 total_size;
  struct memblock_region regions[128];
  char* name;
};

struct memblock{
  u64 current_limit;
  struct memblock_type memory;
  struct memblock_type reserved;
}memblock;

#define __round_mask(x, y) ((__typeof__(x))((y)-1))
#define round_up(x, y) ((((x)-1) | __round_mask(x, y))+1)
#define round_down(x, y) ((x) & ~__round_mask(x, y))

#define for_each_free_mem_range_reserve(i, p_start, p_end) \
        for_each_mem_range_rev(i, &memblock.memory, &memblock.reserved, p_start, p_end)

#define for_each_mem_range_rev(i, type_a, type_b, p_start, p_end) \
        for (i = (u64)ULLONG_MAX, __next_mem_range_rev(&i, type_a, type_b, p_start, p_end); \
             i != (u64)ULLONG_MAX; __next_mem_range_rev(&i, type_a, type_b, p_start, p_end)) 

#define for_each_memblock_type(i, memblock_type, rgn)			\
	for (i = 0, rgn = &memblock_type->regions[0];			\
	     i < memblock_type->cnt;					\
	     i++, rgn = &memblock_type->regions[i])

#define ULLONG_MAX	(~0ULL)
