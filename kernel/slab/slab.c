#include "memory.h"
#include "io.h"
#include "lib.h"

extern char _text;
extern char _etext;
extern char _edata;
extern char _end;

void search_memory();
void init_pages();
void free_page(struct Page*);
struct Page* alloc_page(u64 attr);
struct Page* use_page(int n, u64 attr);

void init_slab();
u64 alloc_slab(int i, int size);
struct Slab* create_slab(int size);

void append_slab(struct Slab* slab, int size);
void delete_slab(struct Slab* slab, int size);

void init_page_table();

void InitMemory(){
	search_memory();

	init_pages();
	init_slab();
	init_page_table();
}

void init_pages(){
  unsigned char* bit_start = memory_manager.bitmap;
  struct Page* page = (struct PAGE*)(bit_start + memory_manager.map_len);
  memory_manager.pages = page;
  u64 i;
  //cprintf("bit_start at %ux\n", (u64)bit_start);

  memset(memory_manager.bitmap, 0, memory_manager.map_len);
  for (i = 0; i * PAGE_2M_SIZE < Virt_To_Phy(memory_manager.kernel_end); i++){
	use_page(i, PAGE_KERNEL_PAGE);
  }
  //cprintf("free page start at num %d\n", i);

  u64 pre = i;
  for (i = 0; i < AREANUM; i++){
    if (memory_manager.area[i]->free_page <= 0)
	  continue;
	u64 start = memory_manager.area[i]->physical_addr;
	u64 idx = start / PAGE_2M_SIZE;

	if (idx < pre)
	  continue;
	for( ; pre < idx; pre++){
	  //,cprintf("set %ld\n", pre);
	  use_page(pre, PAGE_KERNEL_PAGE);
	}
	for( ; idx <= memory_manager.area[i]->free_page; idx++){
	  memory_manager.pages[idx].physical_addr = idx * PAGE_2M_SIZE;
	  memory_manager.pages[idx].virtual_addr = Phy_To_Virt(memory_manager.pages[idx].physical_addr);
	  memory_manager.pages[idx].attr = 0;
	}
	pre = memory_manager.area[i]->end & PAGE_2M_MASK;
  }
  use_page(5, PAGE_KERNEL_PAGE);
  use_page(6, PAGE_KERNEL_PAGE);
  use_page(7, PAGE_KERNEL_PAGE);
  //cprintf("page end at %ux\n", &memory_manager.pages[memory_manager.free_page]);
}

void search_memory(){
  AREANUM = 0;
  struct MEMORY_E820* p = 0;
  struct AREA* area = (struct AREA*)AREABASE;
  memory_manager.kernel_start = (u64) &_text;
  memory_manager.kernel_end = (u64) &_end;
  u64 end = 0;
  int i;
  p = (struct MEMORY_E820*)0xffff800000007c00; // wait for change the address
  for(i = 0; i < 32; i++){
	//cprintf("address: %ux\tlength: %ux\ttype: %ux\n", p->addr, p->len, p->type);
	if(p->type == 1){
	  area->physical_addr = PAGE_2M_ALIGN(p->addr);
	  area->virtual_addr = Phy_To_Virt(area->physical_addr);
	  area->free_page = (p->len + PAGE_2M_ALIGN(p->addr) - p->addr) / PAGE_2M_SIZE;
	  area->end = p->addr + p->len;

	  //cprintf"Area start at physic: %ux, virtual: %ux, free: %ux, total_page: %d\n",
	  //area->physical_addr, area->virtual_addr, area->free_page, area->free_page);

	  memory_manager.area[AREANUM++] = area;
	  if(end < p->addr + p->len)
	    end = p->addr + p->len;
	}
	else if(p->type > 4 || p->type < 1)
	  break;
	p++;
	area++;
  }

  // cprintf("area end at %ux\n", area);
  memory_manager.map_len = (memory_manager.total_page + 63) / 8;
  memory_manager.bitmap = (u8 *)MAPBASE;
  memory_manager.pages = (struct PAGE*)(MAPBASE + memory_manager.map_len);
  memory_manager.total_page = end / PAGE_2M_SIZE;
  memory_manager.free_page = memory_manager.total_page;
  //cprintf("total memory is %uldMB\n", end / 1024 / 1024);
}

struct PAGE* use_page(int n, u64 attr){
  if(n >= memory_manager.total_page){
	//cprintf("%d is out of page num\n", n);
	return 0;
  }
  if(memory_manager.bitmap[n / 8] & (u8)(1 << (n % 8))){
	//cprintf("page %d is using\n", n);
	return 0;
  }

  memory_manager.pages[n].attr = attr;
  memory_manager.bitmap[n / 8] |= (u8)(1 << (n % 8));

  //cprintf("use page %d, start at %ux bitmap %ux\n", n, memory_manager.pages[n].virtual_addr, 
  //	memory_manager.bitmap[n / 8]);
  return &memory_manager.pages[n];
}

struct PAGE* alloc_page(u64 attr){
  if(memory_manager.free_page <= 0){
	//cprintf("No free page\n");
	return 0;
  }

  int i;
  for(i = 0;i < memory_manager.map_len; i++){
	if(memory_manager.bitmap[i] >= (u8)(~0))
	  continue;
	int j;
	for(j = 0;j < 8; j++){
	  // printf("%ud i:%d j:%d\n", (unsigned int)(memory_manager.bitmap[i] & (1 << j)), i, j);
	  if(!(memory_manager.bitmap[i] & (u8)(1 << j))){
	    memory_manager.used_page++;
	    memory_manager.free_page--;
	    return use_page(i * 8 + j, attr);
	  }
	}
  }
  //cprintf("alloc failed\n");
  return 0;
}

void free_page(struct PAGE* page){
  if(page == 0){
	//cprintf("Page is null\n");
	return;
  }

  int i;
  for(i = 0;i < memory_manager.total_page; i++){
    if(&memory_manager.pages[i] == page){
	  memory_manager.bitmap[i / 8] &= (~(u8)(1 << (i % 8)));
		// cprintf("Free page %d at %ux\n", i, page->virtual_addr);
	  return;
	}
  }

  //cprintf("free page fail\n");
}

void init_slab(){
  int i, size = 32;
  for(i = 0;i < 16; i++){
	Slab_cache[i].size = size;
	Slab_cache[i].free_slab = 0;
	Slab_cache[i].used_slab = 0;
	Slab_cache[i].cache_pool = 0;
	size *= 2;
  }
}

// Alloc pages from slab cache pool
u64 kmalloc(int size){
  int i, level = 32;
  for(i = 0;i < 16; i++){
	if(level >= size){
	  // cprintf("addr at %ux\n", tmp);
	  return alloc_slab(i, level);
	}
	level *= 2;
  }
  //cprintf("size too large %ux\n", size);
  return 0;
}

// 
u64 alloc_slab(int i, int size){
  struct SLAB* slab = Slab_cache[i].cache_pool;

  while(slab != 0 && slab->free_count <= 0){
	slab = slab->next;
  }
  if(slab == 0){
	slab = create_slab(size);
  }
  if(slab == 0)
	return 0;

  int total = slab->free_count + slab->used_count;
  for(i = 0;i < total;i++){
	if (slab->bitmap[i / 8] == (u8)(~0))
	  continue;

    if(!(slab->bitmap[i / 8] & (1 << (i % 8)))){
	  slab->free_count--;
	  slab->used_count++;
	  slab->bitmap[i / 8] |= (u8)(1 << (i % 8));
	  // cprintf("addr at %ux\n", (u64)slab->page->virtual_addr + i * size);
	  return (u64)slab->page->physical_addr + i * size;
	}
  }

  //cprintf("alloc slab error\n");
  return 0;
}

struct SLAB* create_slab(int size){
  struct PAGE* page = alloc_page(PAGE_KERNEL_PAGE);
  struct SLAB* slab = 0;
  if (page == 0)
	return 0;

  switch (size){
	case 32:
	case 64:
	case 128:
	case 256:
	case 512:
	  slab = (struct SLAB *)page->virtual_addr;
	  slab->page = page;
	  slab->bitmap = (u8 *)(page->virtual_addr + sizeof(struct SLAB));
	  slab->free_count = (u64)PAGE_2M_SIZE / size;
	  slab->map_len = slab->free_count / 8;
	  slab->used_count = (slab->map_len + size - 1 + sizeof(struct SLAB)) / size;
	  slab->free_count -= slab->used_count;

	  // cprintf("slab used_count %d, map_len %d\n", slab->used_count, slab->map_len);
	  memset(slab->bitmap, 0, slab->map_len);
	  int i;
		for(i = 0;i < slab->used_count; i++){
		  slab->bitmap[i / 8] |= (u8)(1 << (i % 8));
		}
	  slab->next = 0;
	  // cprintf("slab at %ux\n", slab->page->virtual_addr);

	  break;

	case 1024:		//1KB
	case 2048:
	case 4096:		//4KB
	case 8192:
	case 16384:
	case 32768:
	case 65536:
	case 131072:	//128KB
	case 262144:
	case 524288:
	case 1048576:	//1MB
	  slab = (struct SLAB *)kmalloc(sizeof(struct SLAB));
	  if (slab == 0){
	    //cprintf("create slab fail\n");
	  return 0;
	  }
	slab->map_len = slab->free_count / 8;
	slab->bitmap = (u8*)kmalloc(slab->map_len);
	slab->page = page;
	slab->free_count = (u64)PAGE_2M_SIZE / size;
	slab->used_count = 0;

	memset(slab->bitmap, 0, slab->map_len);

	break;

	default:
	  //cprintf("size error %d\n", size);
	  break;
	}
  append_slab(slab, size);

  return slab;
}

void append_slab(struct SLAB* slab, int size){
  int i;
  int level = 32;
  for(i = 0;i < 16; i++){
	if(level == size)
	  break;
	level *= 2;
  }
  if(i == 16){
	//cprintf("end of slab size error %d\n", size);
	return;
  }

  struct SLAB* tail = Slab_cache[i].cache_pool;
  if(tail == 0){
	Slab_cache[i].cache_pool = slab;
	return;
  }

  while(tail->next != 0){
	tail = tail->next;
  }
  tail->next = slab;
  slab->prev = tail;
  Slab_cache[i].free_slab++;
}

void delete_slab(struct SLAB* slab, int size){
  if(slab->prev == 0)
	return;

  slab->prev->next = slab->next;
  slab->next->prev = slab->prev;

  switch(size){
	case 32:
	case 64:
	case 128:
	case 256:
	case 512:
	  free_page(slab->page);
	  break;

	default:
	  kfree((u64)slab);
	  break;
  }
}

void kfree(u64 addr){
  u64 pagebase = addr & PAGE_2M_MASK;
  int i;

  for(i = 0; i < 16; i++){
	// Cprintf("search slab\n");
	struct SLAB * slab = Slab_cache[i].cache_pool;

	while(slab != NULL){
	if(slab->page->virtual_addr == pagebase){
	  // cprintf("find at %d\n", i);
	  int idx = (addr - pagebase) / Slab_cache[i].size;
	  slab->bitmap[idx / 8] &= (unsigned char)(~(1 << idx));
	  slab->free_count++;
	  slab->used_count--;

	  if(slab->used_count == 0 && slab->free_count * 3 / 2 <= Slab_cache[i].free_slab
	    && Slab_cache[i].cache_pool != slab){
		delete_slab(slab, Slab_cache[i].size);
	  }

	  return;
	}
	slab = slab->next;
	}
  }

  //cprintf("free error\n");
}

void init_page_table(){
  struct PTABLE1 * page_table1 = Phy_To_Virt(Get_CR3());
  struct PTABLE2 * page_table2;
  page_table1 += 16 * 16;

  if (page_table1->next != 0)
	page_table2 = (struct PTABLE2*)Phy_To_Virt(page_table1->next);

  u64* addr = Phy_To_Virt(TABLE3BASE);
  struct Page* page = memory_manager.pages;
  int i;
  //cprintf("start\n");

  for(i = 0; i < memory_manager.total_page; i++){
	if(addr[i] != 0)
	  continue;
	  addr[i] = (page[i].physical_addr & (~0xfffUL)) | PAGE_KERNEL_PAGE;
	}

  flush_tlb();
  //cprintf("\nfinish table\n");
}