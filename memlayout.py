#!/usr/bin/env python3
"""
Calculate and generate minimal U-Boot config file with somewhat okay memory
layout for loading kernel, initramfs and device tree.
"""
import sys

if len(sys.argv) != 2:
    print("Usage {} loadaddr".format(sys.argv[0]))
    print("Example: {} 0x12000000".format(sys.argv[0]))
    print(__doc__)
    sys.exit(1)

loadaddr = int(sys.argv[1], 0)

def env_set(var, val):
    print("env set {} 0x{:02X}".format(var, val))

env_set("loadaddr", loadaddr)
env_set("kernel_addr_r", loadaddr)
env_set("fdt_addr_r", loadaddr + (16 * 1024 * 1024))  # 16MB after kernel
env_set("scriptaddr", loadaddr + (17 * 1024 * 1024))  # 17MB after kernel
env_set("ramdisk_addr_r", loadaddr + (18 * 1024 * 1024))  # 18MB after kernel

print("env set fdt_high 0xffffffff")  # don't reallocate device tree
print("env set initrd_high 0xffffffff")  # don't reallocate initramfs
