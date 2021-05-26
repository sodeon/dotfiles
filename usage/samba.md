## Server
/etc/samba/smb.conf
sd systemctl restart smbd.service

## Client
sd mount -t cifs //andy-desktop/andy /mnt/temp -o uid=1000,gid=1000,username=andy,password=1234565
sd mount -t cifs //192.168.0.50/e    /mnt/temp -o uid=1000,gid=1000,username=andy,password=1234565
# andy-desktop: host name alias defined in /etc/hosts
# uid=1000: change owner from root to current user
# gid=1000: change group from root to current user
# username: default username is root
