struct Slab_cache{
  u64 size;
  u64 total_using;
  u64 total_free;
  struct Slab* cache_pool;
  struct Slab* cache_dma_pool;
  void* (* constructor)(void* Vaddr,u64 arg);
  void* (* destructor)(void* Vaddr,u64 arg);
};

struct Slab{
  struct List_head list;
  struct Page* page;

  u64 using_count;
  u64 free_count;

  void* vaddr;
  u64 map_length;
  u64 map_count;
  u64* color_map;
};

struct mem_manager{
  
};

