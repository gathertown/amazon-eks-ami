#!/usr/bin/env bash

# Speed up VM's performance for SFU by disabling security mitigations.
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nosmt mitigations=off"/' /etc/default/grub
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg

# blacklist intel_powerclamp module.
echo 'blacklist intel_powerclamp' >> /etc/modprobe.d/blacklist.conf
