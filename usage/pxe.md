# DHCP
sd apt install isc-dhcp-server
service isc-dhcp-server.service, isc-dhcp-server6.service (mask this)
config: /etc/dhcp/dhcpd.conf, /etc/default/isc-dhcp-server (white list network interface)

## TFTP
sd apt install tftpd-hpa tftp-hpa # tftp-hpa is tftp client used to debug
service: tftpd-hpa.service
config: /etc/default/tftpd-hpa (does not need to modify)
files: /srv/tftp
  1. Does not support symbolic link
