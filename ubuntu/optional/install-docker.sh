#!/bin/bash -ue
. log.sh
#------------------------------------------------------------------------------------------
# Install docker community edition
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository
#------------------------------------------------------------------------------------------
log_captains "Installing Docker..."

# Remove old versions
log "Remove old version..."
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt update

# Install dependency
log "Install dependency..."
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Install gpg key
log "Add gpg key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Verify gpg key
log "Verifying gpg key..."
sudo apt-key fingerprint 0EBFCD88

# Add docker repository and install
log "Installing docker..."
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   bionic \
   stable"
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose

# Verify installation
log "Testing docker installation..."
sudo docker run hello-world

# Success
log_success "Docker installation complete"


#------------------------------------------------------------------------------------------
# Post-installation config
# https://docs.docker.com/install/linux/linux-postinstall/
#------------------------------------------------------------------------------------------
log_captains "Configuring docker..."
log "Allow non-root user to use docker..."
sudo usermod -aG docker $USER


