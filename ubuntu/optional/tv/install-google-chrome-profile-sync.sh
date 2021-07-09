#!/bin/bash -ue

# Install
cd /tmp
pj
git clone https://github.com/graysky2/profile-sync-daemon
cd ./profile-sync-daemon
sudo make install

# Generate config file
psd
# Edit config
sed -i 's/#USE_OVERLAYFS="no"/USE_OVERLAYFS="yes"/' ~/.config/psd/psd.conf
sed -i 's/#USE_SUSPSYNC="no"/USE_SUSPSYNC="yes"/' ~/.config/psd/psd.conf
sed -i 's/#BROWSERS=()/BROWSERS=(google-chrome)/' ~/.config/psd/psd.conf
# Add permissions
echo 'andy ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper' | sudo tee /etc/sudoers.d/psd-overlay-helper
# Parse config file to see if there is any error
psd p

# Enable and start systemd psd service
systemctl --user enable  psd.service
systemctl --user restart psd.service
