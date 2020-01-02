# Follow at your own risk!

but those should be general instructions for getting normal Debian installed
onto iomega ix2-200 NAS

# Files on usb stick

# 0. install packages

    sudo apt install u-boot-tools

# 1. Create ext2 usb stick

First figure out your usb stick name

    lsblk

**Make sure that your usb stick uses DOS/MBR partition table!!**

Then format it with ext2. Replace /dev/sdX1 with your stick name

    sudo mkfs.ext2 /dev/sdX1

And mount the usb stick to /mnt folder

    sudo mount /dev/sdX1 /mnt

To make things easier, lets change the usb stick permisions to be more open

    sudo chmod 777 /mnt

# 2. Download kernel, initramfs and device tree

First lets cd to the mounted usb device

    cd /mnt

And download files there

    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/device-tree/kirkwood-iomega_ix2_200.dtb
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/vmlinuz-4.19.0-6-marvell
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/initrd.gz

# 3. Build U-boot files

iomega has a realy old u-boot that does not support seperate device tree files.
We will append device tree dtb file end of the kernel images

    cat vmlinuz-4.19.0-6-marvell kirkwood-iomega_ix2_200.dtb > vmlinuz_with_dtb

then we have to wrap the kernel and initrd into u-boot image files

    mkimage -A arm -O linux -T ramdisk -C none -a 0x00000000 -e 0x00000000 -n initramfs -d initrd.gz uInitrd
    mkimage -A arm -O linux -T kernel  -C none -a 0x00008000 -e 0x00008000 -n kernel -d vmlinuz_with_dtb uImage

# 4. Unmount usb stick

**Do not simply unplug the usb drive from your computer!**

First lets make sure that all of the files are written to our usb stick by running sync
This command my take some time if you have a slow usb stick

    sync

Then unmount the usb stick

    sudo umount /mnt

# 5. Boot debian installer on iomega

1. Plug the usb drive into iomega
2. power on the device
3. in u-boot promt start usb support

```
usb start
```

4. make sure that your usb drive is detected

```
usb storage
```

If its not detected, you can try again by running `reset`

5. Make sure that you can list files on the usb drive

```
ext2ls usb 0:1 /
```

6. Load files and boot

```
ext2load usb 0:1 0x00800000 /uImage
ext2load usb 0:1 0x01A00000 /uInitrd
setenv bootargs console=ttyS0,115200
bootm 0x00800000 0x01A00000
```

# 6. Install debian like normal
U-Boot on the ix2-200 only understands **DOS/MBR** partiton tables, GPT will not work. Some hacish protected MBR GPT hybrid might also work but thats untested!

Create a seperate /boot partiton type of about 200MB size with **ext2** file system!

Installer might tell you that it cant find any kernels to install, simply say `continue without a kernel`

Mark down the kernel args the installer gives you. Probably you need the `root=<device>` kernel argument line.

# 7. Install kernel

Before rebooting in the installer you have to change into shell window by pressing `ctrl+a` and then `n`

    chroot /target

and then install kernel

    apt install linux-image-marvell

After that we need to create uboot image files

    cd /boot
    cp /usr/lib/linux-image-4.19.0-6-marvell/kirkwood-iomega_ix2_200.dtb /boot
    cat vmlinuz-4.19.0-6-marvell kirkwood-iomega_ix2_200.dtb > vmlinuz_with_dtb
    mkimage -A arm -O linux -T kernel  -C none -a 0x00008000 -e 0x00008000 -n kernel -d vmlinuz_with_dtb uImage
    mkimage -A arm -O linux -T ramdisk -C none -a 0x00000000 -e 0x00000000 -n initramfs -d initrd.gz uInitrd

# 8. Finish install

# 9. Test bootup

In u-boot prompt

Start hdd support

    ide reset

List files in boot partition

    ext2ls ide 0:1 /

If you can see uImage and uInitrd then you can try to boot them

    ext2load ide 0:1 0x00800000 /uImage
    ext2load ide 0:1 0x01A00000 /uInitrd
    setenv bootargs console=ttyS0,115200 root=/dev/<device>
    bootm 0x00800000 0x01A00000

# 10. configure autoboot

in u-boot prompt

    setenv loadfiles 'ide reset; ext2load ide 0:1 0x00800000 /uImage; ext2load ide 0:1 0x01A00000 /uInitrd'
    setenv bootargs console=ttyS0,115200 root=/dev/<device>
    setenv bootcmd 'run loadfiles; bootm 0x00800000 0x01A00000'

And thest if those commands work

    boot

If it boothed then you can reboot to u-boot prompt, run those setenv command again and this time instead of boot you save the variables with

    saveenv

# NET BOOT

**UNTESTED**

# 0. install packages

**Inside normal linux desktop:**

    sudo apt install u-boot-tools dnsmasq python3

# 1. Build u-boot script

**Inside normal linux desktop:**

    mkimage -A arm -O linux -T script -C none -n boot.scr -d ix200_boot.scr boot.scr.uimg

# 2. Download kernel and other files

**Inside normal linux desktop:**

    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/device-tree/kirkwood-iomega_ix2_200.dtb
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/vmlinuz-4.19.0-6-marvell
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/initrd.gz

# 3. Run bootserver

**Inside normal linux desktop:**

    sudo ./bootserver enp2s0 ./

where `enp2s0` is your network interface where dhcp server will be run

and `./` is folder where `boot.scr.uimg`, kernel and other files are

# 4. Run u-boot commands on the ix200 console

Those commands should boot debian kernel from the dhcp/tftp server

**Inside Iomega U-boot console:**

    env set autoload yes
    dhcp
    tftp 0x00800000 boot.scr.uimg
    source 0x00800000

Installer should run inside a `screen` program

* https://linuxize.com/post/how-to-use-linux-screen/#working-with-linux-screen-windows

# 5. Permanently set u-boot

dont know but the kernel should be on a seperate ext2 boot partiton
and from there u-boot should be capable of loading kernel via usb or sata disk

**Inside Iomega U-boot console:**

    sata start
    ext2ls sata 0:1

where 0 is disk nr and 1 is partiton number, partiton 0 is whole disk

boot script could be something like this

make sure that kernel, device tree and initramfs filenames are correct

**Inside Iomega U-boot console:**

    setenv bootargs_console 'console=ttyS0,115200 root=/dev/sda'
    setenv bootcmd 'sata start; ext2load sata 0:1 0x00800000 /vmlinuz; ext2load sata 0:1 0x01800000 /dtbs/kirkwood-iomega_ix2_200.dtb; ext2load sata 0:1 0x01A00000 /initrd.gz; bootm 0x00800000 0x01A00000 0x01800000'

You can test those commands with

**Inside Iomega U-boot console:**

    run bootcmd

and if everything works then you can permanently save those env variables with this command

**Inside Iomega U-boot console:**

    saveenv

* https://github.com/lentinj/u-boot/blob/master/doc/README.sata
* https://blog.nobiscuit.com/2011/08/06/installing-debian-to-disk-on-an-ix2-200/
* https://github.com/arvati/debian-ix2-200#make-changes-in-uboot
