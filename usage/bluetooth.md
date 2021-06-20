## Connect Bluetooth Device To Dual Boot Systems
[Resources](https://unix.stackexchange.com/questions/255509/bluetooth-pairing-on-dual-boot-of-windows-linux-mint-ubuntu-stop-having-to-p)
<br/>
<br/>
Bluetooth device stores pairing MAC address and pairing key. To make the device usable in both systems, pairing keys must be the same for both systems.
| System | Pairing keys |
|--------|--------------|
| Linux  |`/var/lib/bluetooth/[adapter  MAC]/[device MAC]/info`|
| Windows| `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\BTHPORT\Parameters\Keys` |
- Linux: 
    - Use `sudo -i` to access. Folder is not accessible for normal users.
    - In `info`, Pairing key:
        ```
        [LinkKey]
       Key=B99999999FFFFFFFFF999999999FFFFF
       ```
    - Restart bluetooth: `sudo systemctl restart bluetooth`
- Windows: 
    - Use `psexec -s -i regedit.exe` to access. Reg keys are invisible without using `psexec`.
    - Pairing key is value of`[device MAC]` key. No reboot needed after changing key value.


## Add Bluetooth Audio Codec To Pulseaudio

### Introduction
By default, Linux only has SBC for bluetooth audio. pulseaudio-modules-bt package provided extended bluetooth audio codec for Linux

### Install
https://github.com/EHfive/pulseaudio-modules-bt/wiki/Packages#ubuntu
```bash
sudo add-apt-repository ppa:berglh/pulseaudio-a2dp
sudo apt update
sudo apt install pulseaudio-modules-bt libldac
sudo apt install blueman # Optional; Easy to use bluetooth manager
```

### Setup
 **Only do this when pulseaudio is not using your desired codec**. By default, pulseaudio will attempt to use best quality codec.

Edit `/etc/pulse/default.pa`
Append arguments to `load-module module-bluetooth-discover`
```bash
# LDAC Standard Quality
load-module module-bluetooth-discover a2dp_config="ldac_eqmid=sq"

# LDAC High Quality; Force LDAC/PA PCM sample format as Float32LE
#load-module module-bluetooth-discover a2dp_config="ldac_eqmid=hq ldac_fmt=f32"
```

### Check If Bluetooth Is Using Desired Codec
```bash
pactl list                   # list everything, bluetooth audio is usually listed as the last card
pactl list | grep a2dp       # code used and parameters surrounding the codec
pactl list | grep a2dp_codec # exact codec name. e.g. LDAC
```
Open `Bluetooth Manager` and see the upload speed to check bitrate

### Headset Hardware Media Control
- When using Sony WH-1000XM4 hardware media control, it issues standard `XF86AudioPlay/XF86AudioNext/XF86AudioPrev` media keys.
- These media keys is then captured by `i3` window manager (`~/.config/i3/config`) and translated to `MPRIS` media control server commands.
- MPRIS supported media players:
  - Chrome
  - cmus (compiled with `CONFIG_MPRIS=y` and enabled, `:set mpris`)
  - mpv (with plugin)


 | Component            | Description |
 |----------------------|-------------|
 | Interface            | MPRIS2      |
 | MPRIS Server         | https://github.com/icasdri/mpris2controller |
 | mpv Plugin for MPRIS | https://github.com/hoyon/mpv-mpris/releases |
