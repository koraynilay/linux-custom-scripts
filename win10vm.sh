#!/bin/sh
vmsfolder='/C/linux/vms'
vmname="win10"
cd "$vmsfolder"
cd "$vmname"
qemu-system-x86_64 \
	-name win10 \
	\
	-enable-kvm \
	-machine type=q35,accel=kvm \
       	\
	-device intel-iommu \
	-cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
	-m 6G \
	-smp 2 \
	\
	-net nic,model=virtio \
	-net user,smb=$HOME/share_win \
	-net tap,ifname=tap0,script=no,downscript=no \
	\
	-drive file=win10.qcow2,if=virtio,cache=none,aio=native,cache.direct=on \
	\
	-vga virtio  \
	-display sdl,gl=on \
	\
	-device ich9-intel-hda \
	-audiodev pa,id=snd0 \
	-device hda-output,audiodev=snd0 \
	-cdrom virtio-win-0.1.171.iso 

	#-device virtio-keyboard-pci \
	#-device virtio-tablet-pci \
	#-device virtio-gpu-pci \
	#-device virtio-net-pci,netdev=net0 \