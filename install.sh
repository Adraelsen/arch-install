#!/bin/bash

### Check for internet connection
echo "Checking for internet connection . . ."
# check with netcat 
if nc -zw1 8.8.8.8 443; then
    echo -e "Connected. Proceeding.\n"
else
    echo "No internet. Aborting.";
    exit 1;
fi

### Get hostname and password from user
read -p "Enter hostname: " hostname >/dev/tty
if [ -z "$hostname" ]; then
    echo "Hostname cannot be empty!";
    exit 1;
fi
echo
read -p "Enter root password: " -s pass1 >/dev/tty
echo
read -p "Re-enter root password: " -s pass2 >/dev/tty
if [ "$pass1" == "$pass2" ]; then
    :
else
    echo "Passwords did not match!";
    exit 1;
fi
echo

### Update system clock
echo "Updating system clock . . ."
timedatectl set-ntp true
echo -e "Update complete.\n"

### Partition drive
echo "Paritioning drive . . ."
# use -s option for script mode
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart UEFI fat32 0% 300MiB
parted -s /dev/sda set 1 esp on
parted -s /dev/sda mkpart root ext4 300MiB 100%
echo "New partition table:"
parted -l
echo

### Format partitions
echo "Formatting partitions . . ."
mkfs.ext4 /dev/sda2
echo -e "Format complete.\n"

### Mount file system
echo "Mounting file system . . ."
mount /dev/sda2 /mnt
echo -e "Mount complete.\n"

### Installation 
echo "Installing packages . . . "
pacstrap /mnt base linux linux-firmware
echo -e "Installation complete.\n"

### Configure system
echo "Configuring system . . ."
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
locale-gen
localectl set-locale LANG=en_US.UTF-8
echo -e "Configuration complete.\n"

### Set hostname and password
hostnamectl set-hostname "$hostname"
passwd

### Install bootloader
echo "Installing bootloader . . ."
pacman -S grub efibootmgr
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB
echo -e "Install complete.\n"

### Enable microcode updates
echo "Enabling microcode updates . . ."
pacman -S amd-ucode intel-ucode
echo -e "Compelete.\n"

### Reboot to finish
exit
echo "Rebooting."
reboot now

