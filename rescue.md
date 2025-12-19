# Unbootable Machine Rescue Instructions

For the times when I do something stupid to my machine's configuration, which leads to an unbootable system.

1. Boot with your Arch Linux boot USB
1. Decrypt the root system partition
   ```sh
   cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
   ```
1. Mount the system
   ```
   mkdir -p /mnt/@root
   mount -o subvol=@root /dev/mapper/cryptroot /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   ```
1. chroot into the system
   ```
   arch-chroot /mnt
   ```
1. Make necessary changes to fix whatever broke
