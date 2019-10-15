# THIS IS UNTESTED

but those should be general instructions for getting normal Debian installed 
onto iomega ix2-200 NAS

# 1. Build u-boot script

    mkimage -A arm -O linux -T script -C none -n boot.scr -d ix200_boot.scr boot.scr.uimg

# 2. Download kernel and other files

    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/device-tree/kirkwood-iomega_ix2_200.dtb
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/vmlinuz-4.19.0-6-marvell
    wget http://ftp.debian.org/debian/dists/stable/main/installer-armel/current/images/kirkwood/netboot/initrd.gz

# 3. Run bootserver

    sudo ./bootserver enp2s0 ./
    
where `enp2s0` is your network interface where dhcp server will be run

and `./` is folder where `boot.scr.uimg`, kernel and other files are


# 4. Run u-boot commands on the ix200 console

Those commands should boot debian kernel from the dhcp/tftp server

    env set autoload yes
    dhcp
    tftp 0x00800000 boot.scr.uimg
    source 0x00800000

Installer should run inside a `screen` program

* https://linuxize.com/post/how-to-use-linux-screen/#working-with-linux-screen-windows

# 5. Permanently set u-boot 

dont know but the kernel should be on a seperate ext2 boot partiton
and from there u-boot should be capable of loading kernel via usb or sata disk

    sata start
    ext2ls sata 0:1
    
where 0 is disk nr and 1 is partiton number, partiton 0 is whole disk

boot script could be something like this

make sure that kernel, device tree and initramfs filenames are correct

    setenv bootargs_console 'console=ttyS0,115200 root=/dev/sda'
    setenv bootcmd 'sata start; ext2load sata 0:1 0x00800000 /vmlinuz; ext2load sata 0:1 0x01800000 /dtbs/kirkwood-iomega_ix2_200.dtb; ext2load sata 0:1 0x01A00000 /initrd.gz; bootm 0x00800000 0x01A00000 0x01800000'

You can test those commands with

    run bootcmd

and if everything works then you can permanently save those env variables with this command

    saveenv
    
* https://github.com/lentinj/u-boot/blob/master/doc/README.sata
* https://blog.nobiscuit.com/2011/08/06/installing-debian-to-disk-on-an-ix2-200/
* https://github.com/arvati/debian-ix2-200#make-changes-in-uboot
