#include "acpi.h"

static struct acpi_rsdp* search_rdsp(u64 base, u64 len){
  u8* p;
  for(p = p2v(base); len >= sizeof(struct acpi_rsdp); len -= 4, p -= 4){
    if(memcmp(p, SIG_RSDP, 8) == 0){
      u32 sum, i;
      for(sum = 0, i = 0; i < 20; i++){
        sum += p[i]; 
      }
      if((sum & 0xff) == 0)
        return (struct acpi_rsdp *) p;
    }
  }
  return (struct acpi_rsdp*) 0;
}

static struct acpi_rsdp* find_rdsp(void){
  struct acpi_rsdp* rsdp;
  phys_addr pa;
  pa = *((u16*) P2V(0x40E)) << 4; 
  if(pa && (rspd = search_rdsp(pa, 1024))){
    return rsdp;
  }
  return search_rdsp(0xE0000, 0x20000);
}

static struct acpi_rsdp* find_rdsp_uefi(void){
  return (struct acpi_rsdp*) 0; 
}

static bool acpi_config_smp(struct acpi_madt* madt){
  u32 lapic_addr = madt->lapic_phys_addr;
  u32 nioapic = 0;
  u8 *ptr, *end;

  ptr = madt->interrupt_controller_structure;
  end = ptr + madt->header.length - sizeof(struct acpi_madt);

  while(ptr < end){
    u32 len;
    if((end - ptr) < 2)
      break;
    len = ptr[1];
    if((end - ptr) < len)
      break;
    switch(p[0]){
      case TYPE_LAPIC: {
        struct madt_lapic *lapic = (void*) ptr;
        if(len < sizeof(*lapic))
          break;
        if(!(lapic->flags & APIC_LAPIC_ENABLED))
          break;
        cpus[ncpu].id = ncpu;
        cpus[ncpu].apicid = lapic->apic_id;
        ncpu++;
        break;
      }
      case TYPE_IOAPIC: {
        struct madt_ioapic *ioapic = (void*) ptr;
        if (len < sizeof(*ioapic))
          break;
        ioapicid = ioapic->id;
        nioapic++;
        break;
      }
    }
    p += len;
  }
}

bool acpi_init(void){
  struct acpi_rsdp* rdsp;
  struct acpi_xsdt* xsdt;
  u32 count,i;

  rdsp = find_rdsp();
  xsdt = p2v(rdsp->xsdt_phys_addr);
  count = (xsdt->header.length - sizeof(*xsdt)) / 8;
  for(i = 0; i < count ; i++){
    struct acpi_desc_header *hdr = p2v(xsdt->entry[n]);
    if(memcmp(hdr->signature, SIG_MADT, 4)){
      madt = (void*) hdr;
    }
  }
}