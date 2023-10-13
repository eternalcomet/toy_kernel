// https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/index.html#
// 5.2.5.3
#define SIG_RDSP "RSD PTR "
struct acpi_rdsp {
  u8 signature[8];
  u8 checksum;
  u8 oem_id[6];
  u8 revision;
  u32 rsdt_phys_addr;
  u32 length;
  u64 xsdt_phys_addr;
  u8 extended_checksum;
  u8 reserved[3];
} __attribute__((__packed__));

// 5.2.6
struct acpi_desc_header {
  u8 signature[4];
  u32 length;
  u8 revision;
  u8 checksum;
  u8 oem_id[6];
  u8 oem_table_id[8];
  u32 oem_revision;
  u8 creator_id[4];
  u32 creator_revision;
} __attribute__((__packed__));

// 5.2.8
struct acpi_xsdt{
  struct acpi_desc_header header;
  u64 entry[0];
} __attribute__((__packed__));