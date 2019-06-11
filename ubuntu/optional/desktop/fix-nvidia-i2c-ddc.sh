#!/bin/bash -ue

# Workaround NVIDIA i2c not working: https://github.com/ddccontrol/ddccontrol/issues/20
#     http://www.ddcutil.com/nvidia/#special-nvidia-driver-settings
#     Add "options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100" in /etc/modprobe.d/nvidia.conf # create this file manually
sudo echo "options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100" >> /etc/modprobe.d/nvidia.conf
