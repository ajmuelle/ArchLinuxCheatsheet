# not covered here: download arch iso, dd it to a flash drive, boot with that
# also, plug in an ethernet cable, and a power cable if this is a laptop

# verify that you booted in 64-bit UEFI mode (this should print 64)
cat /sys/firmware/efi/fw_platform_size
# if it doesn't, large parts of this guide won't work

# find out what disks you have
lsblk

# rest of guide assumes /dev/sda is the main hard drive

# open partioning program
parted /dev/sda

# type help (or just hit any key) to get possible commands
(parted) l

# print current partition table (just to know how big the disk is)
(parted) p

# overwrite partition table (odds are, if you're looking at this, you messed it up)
(parted) mklabel gpt

# create EFI System Partition (ignore if that EFI command earlier printed nothing)
(parted) mkpart "EFI System Partition" fat32 0% 512MiB

# make the partition bootable
(parted) set 1 esp on

# create root partition (second number is your disk size minus desired swap space)
(parted) mkpart primary ext4 512MiB 236GB

# create swap partition (first number is second number above)
(parted) mkpart swap linux-swap 236GB 100%

# make sure you got it right
(parted) p

# quit parted
(parted) q

# ignore the message about fstab -- that comes later

# verify that you have internet (should print 64 bytes from archlinux.org)
ping archlinux.org
# if this fails, double check that archlinux.org is actually functioning
# and use 8.8.8.8 or google.com if it's down

# verify that the system clock has the correct time (mentally convert from UTC)
timedatectl

# create ext4 filesystem on root partition
mkfs.ext4 /dev/sda2

# set up swap partition
mkswap /dev/sda3
swapon /dev/sda3

# overwrite EFI System Partition (if you're looking at this, you probably messed it up)
mkfs.fat -F 32 /dev/sda1

# mount the root partition
mount /dev/sda2 /mnt

# mount the EFI System Partition
mount --mkdir /dev/sda1 /mnt/boot

# skip mirror selection -- come back to that after your system boots successfully

# install the kernel, firmware, and basic shell
pacstrap -K /mnt base base-devel linux linux-firmware

# create fstab
genfstab -U /mnt >> /mnt/etc/fstab

# check to see if the fstab has errors if this is like the fifth installation attempt
vim /etc/fstab

# change root into the new system so you can install stuff to the disk
arch-chroot /mnt

# set the timezone to EST (this is a placebo but whatever, probably good to do anyway)
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime

# sync the hardware clock to the system clock (again, in my experience, a placebo)
hwclock --systohc

# install vim (yes, really)
pacman -S vim

# comment out en_US.UTF-8 UTF-8
vim /etc/locale.gen

# do some other mysterious thing needed for locale stuff (don't skip this)
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# set the hostname (should be unique per system)
echo "username" > /etc/hostname

# check your internet connection again for some reason
ping archlinux.org

# install wifi drivers
pacman -S networkmanager wpa_supplicant
systemctl enable NetworkManager

# could do other network configuration here but it isn't strictly needed

# come back and edit this if the mkinitcpio thing is required after all

# set the root password (system WILL NOT BOOT if you don't do this)
passwd

# enable microcode updates (because you always have intel)
pacman -S intel-ucode

# install the GRand Unified Bootloader (grub) and the EFI boot manager
pacman -S grub efibootmgr

# make sure there's not weird extra EFI boot entries
efibootmgr
# TODO: figure out what that "EFI Hard Drive" entry is and remove it

# install grub to the bios
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# create grub configuration
grub-mkconfig -o /boot/grub/grub.cfg

# exit chroot environment
Ctrl+d

# unmount partitions
umount -R /mnt

# reboot and yoink out the flash drive while the screen is black
reboot

# if it boots do other stuff

