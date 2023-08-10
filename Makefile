# -----------Product Config-----------
# product name
PRODUCT_NAME = TOY_OS
BUILD_DIR = build
# -----------Disk Image Config-----------
# image file name
DISK_IMAGE = $(BUILD_DIR)/disk.img
# disk size in MB, can be specified by command line
DISK_SIZE ?= 64
# sector size, 512 bytes by default
SECTOR_SIZE = 512
# partition offset in sector, 2048 by default because of 4KB alignment
PART_START = 2048
# end partition, partition size - 1 is the last partition
PART_END = $(shell echo $$((($(DISK_SIZE) * 1024 * 1024) / $(SECTOR_SIZE) - 1)))
# partition type, `0c` for FAT32
TYPE = 0c
# mount point
MOUNT_POINT ?= /mnt/toy_os

.PHONY: clean mount unmount write_bootable build run
# -----------make-----------
run: build
	qemu-system-x86_64 -drive file=$(DISK_IMAGE),format=raw

build: write_bootable

$(BUILD_DIR):
	mkdir -p $@

# make disk image
$(DISK_IMAGE):
	# create an empty disk image file filled with zeros
	dd if=/dev/zero of=$@ bs=1M count=$(DISK_SIZE)
	# create a MBR partition table with a FAT32 partition
	echo "o\nn\np\n1\n$(PART_START)\n$(PART_END)\nt\n$(TYPE)\nw\n" | fdisk $@
	# format the partition as FAT32
	mkfs.vfat -F 32 -n "$(PRODUCT_NAME)" --offset $(PART_START) $@

$(BUILD_DIR)/boot/mbr_boot.bin: boot/mbr_boot.asm
	mkdir -p $(BUILD_DIR)/boot
	nasm $< -o $@

write_bootable: $(BUILD_DIR)/boot/mbr_boot.bin $(DISK_IMAGE)
	dd if=$< of=$(DISK_IMAGE) bs=440 count=1 conv=notrunc

# -----------clean-----------
clean:
	rm -rf $(BUILD_DIR)

# -----------mount disk image-----------
mount:
	sudo mkdir -p $(MOUNT_POINT)
	LOOPDEV=$$(sudo kpartx -av $(DISK_IMAGE) | head -n 1 | cut -d ' ' -f 3); \
	echo "Loop device: $$LOOPDEV"; \
	sudo mount /dev/mapper/$$LOOPDEV $(MOUNT_POINT)

# -----------unmount disk image-----------
unmount:
	sudo umount $(MOUNT_POINT)
	sudo kpartx -dv $(DISK_IMAGE)
	sudo rm -rf $(MOUNT_POINT)