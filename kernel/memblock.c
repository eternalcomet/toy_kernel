#include "types.h"
#include "memblock.h"
#include "memlayout.h"
#include "mmu.h"
#include "defs.h"

#define clamp(val, lo, hi) min( (typeof(val))(max(val, lo)),hi)  

// Insert a region to the regions list
int memblock_insert_region(struct memblock_type *type, int idx, u64 base, u64 size){
  struct memblock_region* rgn = &type->regions[idx];
  memmove(rgn + 1, rgn, (type->cnt -idx)* sizeof(*rgn));
  rgn->base = base;
  rgn->size = size;
  
  type->cnt++;
  type->total_size+=size;
}

// Merge the adjacent and continuous regions
int memblock_merge_regions(struct memblock_type *type){
  int i = 0;

  while(i < type->cnt -1){
    struct memblock_region* this = &type->regions[i];
    struct memblock_region* next = &type->regions[i+1];

    if(this->base + this->size != next->base){
      i++;
      continue;
    }
    
    this->size += next->size;
    memmove(next, next + 1, (type->cnt -(i+2) * sizeof(*next)));
  }
}

void memblock_remove_region(struct memblock_type* type, u64 i){
  type->total_size -= type->regions[i].size;
  memmove(&type->regions[i], &type->regions[i+1],
     type->cnt - (i + 1) * sizeof( type->regions[i] ));
  type->cnt--;

  if(type->cnt == 0){
    type->cnt = 1;
    type->regions[0].base = 0;
    type->regions[0].size = 0;
  }
}

// The entry is sorted in default
int memblock_add_regions(struct memblock_type *type,u64 base,u64 size){
  int insert = 0;
  u64 obase = base;
  u64 end = base + size;
  int idx, nr_new;
  struct memblock_region* rgn;

  if(!size)return 0;

  if(type->regions[0].size == 0){
    type->regions[0].base = base;
    type->regions[0].size = size;
    type->total_size = size;
    return 0;
  }
  repeat:
    base = obase;
    nr_new = 0;
    for_each_memblock_type(idx, type, rgn){
      u64 rbase = rgn->base;
      u64 rend = rbase + rgn->size;

      if(rbase >= end)
        break;
      if(rend <= base)
        continue;
      if(rbase > base){
        nr_new++;
        if(insert)
          memblock_insert_region(type, idx++, base, rbase-base);
      }
      base = min(rend, end);
    }
    
    if(base < end){
      nr_new++;
      if(insert)
        memblock_insert_region(type, idx, base, end-base);
    }

    if(!nr_new)
      return 0;

    if(!insert){
      if(type->cnt + nr_new > type->max)
        //panic();
      insert = 1;
      goto repeat;
    }
    else{
      memblock_merge_regions(type);
      return 0;
    }
}

int memblock_add(u64 base, u64 size){
  return memblock_add_regions(&memblock.memory, base, size);
}

int memblock_reserve(u64 base, u64 size){
  return memblock_add_regions(&memblock.reserved, base, size);
}

void __next_mem_range_rev(u64* idx, struct memblock_type* type_a, struct memblock_type* type_b, u64 *out_start, u64 *out_end){
  int idx_a = *idx & 0xffffffff;
  int idx_b = *idx >> 32;

  if (*idx == (u64)ULLONG_MAX){
    idx_a = type_a->cnt-1;
    idx_b = type_b->cnt;
  }

  for(; idx_a >= 0; idx_a--){
    struct memblock_region* m = &type_a->regions[idx_a];

    u64 m_start = m->base;
    u64 m_end = m->base + m->size;

    for(; idx_b >= 0; idx_b--){
      struct memblock_region* r;
      u64 r_start;
      u64 r_end;

      r = &type_b->regions[idx_b];
      r_start = idx_b ? r[-1].base + r[-1].size : 0;
      r_end = idx_b < type_b->cnt ? r->base : ULLONG_MAX;

      if(r_end <= m_start)
        break;
      if(m_end > r_start){
        *out_start = max(m_start, r_start);
        *out_end = min(m_end, r_end);
        
        if(m_start >= r_start)
          idx_a--;
        else
          idx_b--;
        *idx = (u32)idx_a | (u64)idx_b << 32;
        return;
      }    
    }
  }
  *idx = ULLONG_MAX;
}

u64 __memblock_find_range_top_down(u64 start, u64 end, u64 size, u64 align){
  u64 this_start, this_end, cand;
  u64 i;

  for_each_free_mem_range_reserve(i, &this_start, &this_end){
    this_start = clamp(this_start, start, end);
    this_end = clamp(this_end, start, end);

    // The data is unsigned, so need to judge
    if(this_end < size)
      continue;

    //cand = round_down(this_end - size, align);
    cand = 1;
    if(cand >= this_start)
      return cand;
  }

  return 0;       
}

u64 memblock_find_in_range(u64 size, u64 align, u64 start, u64 end){
  start = max(start, PGSIZE);
  end = max(start, end);

  return __memblock_find_range_top_down(start, end, size, align);
}

static u64 memblock_alloc_range(u64 size, u64 align, u64 start, u64 end){
  u64 found;

  found = memblock_find_in_range(size, align, start, end);
  if(found && !memblock_reserve(found,size)){
    //kmemleak_alloc_phys(found, size, 0, 0);
    return found;
  }
  return 0;
}

u64 __memblock_alloc_base(u64 size, u64 align, u64 max_addr){
  return memblock_alloc_range(size, align, 0, max_addr);
}

u64 memblock_alloc_base(u64 size, u64 align, u64 max_addr){
  u64 alloc;

  alloc = __memblock_alloc_base(size, align, max_addr);

  if (alloc == 0)
    //panic();
  return alloc;
}

u64 memblock_alloc(u64 size, u64 align){
  return memblock_alloc_base(size, align, MEMBLOCK_ALLOC_ACCESSIBLE);
}

int memblock_isolate_range(struct memblock_type* type, u64 base, u64 size, int *start_rgn, int *end_rgn){
  u64 end = base + size;
  int idx;
  struct memblock_region* rgn;

  *start_rgn = *end_rgn = 0;

  if(!size)
    return 0;

  for_each_memblock_type(idx, type, rgn){

    u64 rbase = rgn->base;
    u64 rend = rbase + rgn->size;

    if(rbase >= end)
      break;
    if(rend <= base)
      continue;

    if (rbase < base){
			rgn->base = base;
			rgn->size -= base - rbase;
			type->total_size -= base - rbase;
			memblock_insert_region(type, idx, rbase, base - rbase);
		} 
    else if(rend > end){
			rgn->base = end;
			rgn->size -= end - rbase;
			type->total_size -= end - rbase;
			memblock_insert_region(type, idx--, rbase, end - rbase);
		} else{
			if (!*end_rgn)
				*start_rgn = idx;
			*end_rgn = idx + 1;
		}
  }
}

int memblock_remove_range(struct memblock_type* type, u64 base, u64 size){
  int start_rgn, end_rgn;
  int i,ret;

  ret = memblock_isolate_range(type, base, size, &start_rgn, &end_rgn);
  if(ret)
    return ret;

  for(i = end_rgn - 1; i >= start_rgn; i--)
    memblock_remove_region(type, i);
}

int memblock_free(u64 base, u64 size){
  u64 end = base + size -1;

  //kmemleak_free_part_phys(base, size);
  return memblock_remove_range(&memblock.reserved, base, size);
}

void print_memblock(struct memblock_type* type){
  int i = 0;
  struct memblock_region* rgn;

  for_each_memblock_type(i, type, rgn){
    cprintf("%l %l\n", rgn->base, rgn->base + rgn->size);
  }
}

void memblock_init(){
  struct MEMORY_E820* ARDS = (struct MEMORY_E820*)(KERNBASE+ARDSOFFSET);
  u32 mem_tot = 0;
  for(int i=0; i < 32; i++){
    if(ARDS->map[i].type < 1 || ARDS->map[i].type > 4) break;
    mem_tot += ARDS->map[i].len;
    cprintf("%l %l %x\n", ARDS->map[i].addr, ARDS->map[i].addr+ARDS->map[i].len, ARDS->map[i].type);
    if(ARDS->map[i].type == 1){
      memblock_add(ARDS->map[i].addr, ARDS->map[i].len);
      //cprintf("%x %x\n", ARDS->map[i].addr, ARDS->map[i].len);
    }
  }
  cprintf("%dMB\n",mem_tot/1048576 + 1);
  print_memblock(&memblock.memory);
}
