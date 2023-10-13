#include "mmu.h"

void add_list(int order, struct list_head* list);
void delete_list(struct list_head* list);

static inline u64 find_buddy_pfn(u64 page_pfn, int order){
  return page_pfn ^ (1 << order);
} 
void expand_buudy(int order, int order_now, struct list_head* list){
  while(order != order_now){
    // get pages_
    struct page* right_pages = (struct page*)list;
    add_list(order_now - 1, list + (1U << (order_now - 1)));
    order_now --;
  }
}

void add_list(int order,struct list_head* list){
  list->pre = &zone1.free_area[order].free_list;
  list->nex = zone1.free_area[order].free_list->nex;
  list->nex->pre = list;
  zone1.free_area[order].free_list->nex = list;
}

void delete_list(struct list_head* list){
  list->pre->nex = list->nex;
  list->nex->pre = list->pre;
  list->pre = NULL;
  list->nex = NULL;
}

struct page* buddy_allocate(int order){
  if(order > 11) return 0;
  
  struct page* rt_page;

  int nr_pages = 1U << order;
  found:
    if(zone1.free_area[order].nr_free != 0){
      zone1.free_area[order].nr_free--;
      rt_page = (struct page*) &(zone1.free_area[order].free_list->nex);
      delete_list(&zone1.free_area[order].free_list->nex);
      return rt_page;  // return  pages
    }
  for(int i = order+1; i <= 11; ++i){
    if(zone1.free_area[i].nr_free!=0){
      zone1.free_area[i].nr_free--;
      expand_buudy(order, i, &zone1.free_area[order].free_list->nex);
      delete_list(&zone1.free_area[order].free_list->nex);
      goto found; 
    }
  }

  return 0;
}

static inline int page_is_buddy(){

}

void free_buddy(struct page* pages,int pfn, int order, struct list_head* list){

  u64 buddy_pfn = find_buddy_pfn(pfn,order);
  while(order < BUDDY_TYPES - 1){
    
  }
}

void init_buddy(){

}

