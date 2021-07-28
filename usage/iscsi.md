## isc-dhcp-server
Occasionally started unsuccessfully after booting up machine. Workaround: restart isc-dhcp-server.service

## TFTP
Files stored in /srv/tftp (make sure file read permission)

## nginx
Files stored in /var/www/html (make sure file read permission)

## iSCSI Server
sd apt install targetcli-fb # do not install "tgt" package, conflicting with targetcli-fb

new config: sd targetcli
create backstore
    set attribute is_nonrot=1 # means SSD, not mechanical. For fileio backstores, block backstores is automatically configured.
create iscsi target
    create lun (logical unit storage) (map backstore to target)
    create portal (what ip and port to listen to initiator)
    create acl (allowed login user. Even without password, specific listing is required)

save config (or config will be lost after reboot)
sd systemctl enable rtslib-fb-targetctl.service

restore config:
sd targetctl restore saveconfig.json

disable: sd systemctl disable rtslib-fb-targetctl.service targetclid.service

Note:
    RDMA (remote direct memory access) enhances performance but not enabled: https://en.wikipedia.org/wiki/Remote_direct_memory_access

## iSCSI Initiator (Client)
sd apt install open-iscsi

probe server
sd iscsiadm -m discovery -t st -p 192.168.0.50
attach iscsi storage by logging in to target
sd iscsiadm -m node -L all

disable: sd systemctl disable iscsid.service iscsi.service

## Wake-on-lan through specific network interface
Has not found a way to do so.
Failed attempt:
    wakeonlan does not provide option to specify which network interface to send magic packet.
    Do this through "ip route".
    $sudo ip route add 255.255.255.255 dev enx00e04c68021c # By default, wakeonlan will broadcast (255.255.255.255) to default network interface. Add another route for targeted network interface.

## iPXE basics
chainload ipxe -> ipxe connect iSCSI and saves iSCSI/network connection information on iBFT
                  iBFT supported types: system ROM, adapter ROM, network boot program (NBP, in memory)
                  Chainload ipxe saves information on NBP
## iPXE install (Ubuntu)
chainload ipxe -> do not boot OS ISO from iSCSI or "sanboot http://...". Without kernel iscsi/network settings, it will boot but will stuck at some point.
               -> use ipxe "kernel", "initrd", "imgargs", "boot" command to boot
                  use netboot capable kernel
               -> follow os guide to provide kernel parameters. This is distro specific.
               -> launch terminal during OS installation to connect network and iscsi, preferring iBFT (1st) method.
                  modprobe iscsi_bft # Load iBFT to /sys/firmware/ibft
                  iscsistart -b # Add iscsci drives to /dev according to iBFT
                      check if iBFT is successfully read by kernel: modprobe iscsi_ibft and see contents in /sys/firmware/ibft/ (https://gist.github.com/smoser/810d59f0dd580b1c1256)
                        (initramfs) modprobe iscsi_ibft
                        [   11.444414] iBFT detected.
                        (initramfs) cat /sys/firmware/ibft/target0/nic-assoc
                        0
                        (initramfs) cat /sys/firmware/ibft/target0/target-name
                        mytest
                        (initramfs) cat /sys/firmware/ibft/target0/port
                        3260
                  "OR"
                  modify /etc/iscsi/initiatorname.iscsi
                  start iscsid.service
                  iscsiadm -m discovery -t st -p 192.168.1.50 # get iscsi target
                  iscsiadm -m node -L -all # connect iscsi
               -> at this point, installer should see the iscsi drives as block device
               -> normal installtion
               -> shutdown after installation (do not reboot. System needs modifications described in next section)

## iPXE post installation (Ubuntu)
Before rebooting freshly installed system, it needs to be modified before first successful boot
               ->  use chroot to generate new initramfs and enable iscsid.service (https://wiki.archlinux.org/title/chroot)
                   many programs expect /proc /sys /dev to exist when running under chroot:
                     cd /location/of/new/root
                     sudo mount -t proc /proc proc/
                     sudo mount -t sysfs /sys sys/
                     sudo mount --rbind /dev dev/
                     sudo chroot .
               -> initframfs built with iscsi module: (https://github.com/intel/intelRSD/issues/26)
                    echo "iscsi" >> /etc/initramfs-tools/modules
                    echo "ISCSI_AUTO=true" > /etc/iscsi/iscsi.initramfs
                    update-initramfs -u
               -> /etc/fstab iscsi entry wait for iscsid.service
                    _netdev,x-systemd.requires=iscsid.service
                    e.g. UUID=12345678-1234-1234-1234-123456789012 /     ext4   defaults,_netdev,x-systemd.requires=iscsid.service   0      1
               -> enable iscsid.service and edit iqn: /etc/iscsi/initiatorname.iscsi (https://wiki.archlinux.org/title/ISCSI/Boot)
               -> (optional) add preferred kernel parameters to /etc/default/grub and /boot/grub/grub.cfg (if not running sudo update-grub)

## iPXE boot (Ubuntu)
chainload ipxe -> ipxe connect iSCSI and saves iSCSI connection information on iBFT
               -> ipxe boot from iSCSI
               -> kernel connected to network and iscsi based on iBFT inforamtion by adding "iscsi" module in initrd
                  no special kernel parameters are needed (e.g. ip=dhcp, disk-detect, partman-iscsi)
                  no network module for initramfs (already included in Ubuntu server)
               -> root directory in fstab mount after iscsid service successfully started.

# Ubuntu Server Netboot Dcoumentation:
# * The to-be-installed machine boots, and is directed to network boot.
# * The DHCP/bootp server tells the machine where to get pxelinux.0.
# * The machine’s firmware downloads pxelinux.0 over tftp and executes it.
# * pxelinux.0 downloads configuration, also over tftp, telling it where to download the kernel, ramdisk and kernel command line to use.
# * The ramdisk looks at the kernel command line to see where to download the server ISO from, downloads it and mounts it as a loop device.
# * From this point on the install follows the same path as if the ISO was on a local block device.

## iPXE install (Windows)
wimboot architecture: https://ipxe.org/appnote/wimboot_architecture
If network card driver is not included in Windows installation media, the installer won't see the iSCSI drive!

wpeinit
net use z: \\andy-ubuntu\e\os\win10 # username/password will be prompted
z:\sources\setup.exe
installer log: notepad x:\windows\panther\setupact.log
    Check for the DiskInfo lines, which should contain information such as
        DiskInfo:===== Disk number [0] =====
        DiskInfo:  Friendly name: [LIO-ORG rabbit SCSI Disk Device]
        DiskInfo:  Arc path: [multi(0)disk(0)rdisk(0)]
        DiskInfo:  Disk signature [0x9A7083D5]
        DiskInfo:  Size (bytes) [17179869184 / 0x400000000]
        DiskInfo:  Disk bus type: [iSCSI]
    Also check for the line
        Callback_BootstrapApplyWpeSettings: Detected iBFT; setup will initialize networking support for iSCSI


## iPXE boot (Windows)


# Windows 10: Source of all evil - NDIS filter driver: blocking installation to booting
#     1. Install Windows 10 on normal hard drive using normal installation method
#     2. Boot into freshly installed Windows and disable NDIS filter driver using bindview.exe
#        1. Open bindview.exe with admin-privileges
#        2. In “Show bindings for” – Select “All Services”
#        3. You will see two “WFP Lightweight filter … MAC …” node. Expand it to see its binding paths. There are two of those, ipv4/6.
#        4. Right-Click on “Binding Path #” for the iSCSI boot NIC/NICs and select “Disable”. If the Disable option is not available, it means the binding is already disabled. You also see if it is disabled.
#     3. Migrate hard drive to image file using clonezilla or dd
#        At this point, booting the image in iscsi target will results in "winload.exe" error.
#     4. ipxe WinPE boot to fix "winload.exe" error by updating BCD (boot configuration data): https://www.compspice.com/how-to-fix-error-code-0xc000000e-winload-exe-in-windows-10/#:~:text=Faced%20a%20blue%20screen%20of,BCD%20(Boot%20Configuration%20Data).&text=Thus%2C%200xc000000e%20appears%20when%20the,loaded%20from%20the%20BCD%20file.
#        /////////////// bootrec /fixboot # Access Denied message
#        c:
#        bcdedit /export C: \ BCD_Backup
#        cd boot
#        attrib bcd -s -h -r
#        ren c: \boot \bcd bcd.old
#        bootrec /RebuildBcd
#     5. Reboot to iscsi target
# References:
# * Microsoft official iscsi boot application notes (Windows Server 2012): https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ee619722(v=ws.10)
# * Disable NDIS filter driver: https://support.microsoft.com/zh-tw/topic/windows-may-fail-to-boot-from-an-iscsi-drive-if-networking-hardware-is-changed-5363d4bc-0103-e183-cb1c-8436e1691c13#bkmk_workaround
#                               http://chee-yang.blogspot.com/2012/05/migrate-windows-7-instance-to-iscsi.html
#                               https://forum.level1techs.com/t/rages-disk-less-windows-10-boot-from-iscsi-adventures-results/143597
# Failed attempt:
#     Use USB stick to install like code above
#     Use Manual WinNT x64 setup - disable pagefile/hibernation/reserved volume
#         Boot disk must be > 150MB
#     After finishing 1st phase install, reboot, then "INACCESSIBLE BOOT DEVICE" error.
# Failed attempt:
#     Normal network/USB install results in "driver irql not less or equal" from, ndis.sys
#     Installing Windows 7, 8 and 8.1 to iSCSI should work without issues by following the http://ipxe.org/howto/winpe tutorial with a proper sanhook command before the boot command. Windows 10, unfortunately, has an issue making it troublesome to install to an iSCSI target: https://forum.ipxe.org/showthread.php?tid=7712 

# Windows 8:
# Special curated installation media (e.g. GhostSpectre) may not be installed on iscsi target.
# They usually strip a lot of drivers and will cause "windows installation cannot continue because a required driver could not be installed" at the end of the installation.
