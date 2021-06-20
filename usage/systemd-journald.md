# Linux logging system
- syslog and systemd-journald: https://meaningfulengineer.com/ssh-logging-on-linux/ 
- View syslog: `/var/log/syslog`
- View journald:
  ```bash
  journalctl
  ```
### Maintain
- Check usage:
  ```bash
  journalctl --disk-usage
  ```
- Cleanup: 
  ```bash
  sudo journalctl --vacuum-time=10d
  sudo journalctl --vacuum-time=100M
  ```
### Configure
- `/etc/systemd/journald.conf`
  ```bash
  Storage=volatile  # Log to memory
  RuntimeMaxUse=32M # Up to 32MB of memory for logging
  ```
  ```bash
  Storage=auto      # Log to disk if possible (default). 
                    # Log to /var/log/journald if directory writable.
  SystemMaxUse=500M # Up to 500MB of disk for logging. (default: 10% disk space)
  ```
  ```bash
  Storage=none       # Drop messages (forwarding still works)
  ForwardToSyslog=no # Do not forward to syslog daemon (rsyslog). 
                     # Combined with Stoarge=none results in no logging.
                     # Only booting messages are logged
  ```
### Reduce systemd-journald memory consumption (for desktop/laptop)
- Can sometimes takes hundreds of MBs
- Disable kernel message: `/etc/systemd/journald.conf`
  ```bash
  ReadKMsg=no # Kernel message will not logged to journald/syslog
  ```
### Disable systemd logging (for TV or Linux on USB stick)
  - Except logging during boot, do not store any more logging.
  ```bash
  Storage=none
  ForwardToSyslog=no
  ```
