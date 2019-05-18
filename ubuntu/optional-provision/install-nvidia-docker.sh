#!/bin/bash -ue
source ~/.local/lib/bash/log.sh
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


#------------------------------------------------------------------------------------------
# Install nvidia-docker
#------------------------------------------------------------------------------------------
log_captains "Installing nvidia-docker..."

# Remove old nvidia-docker (1.0)
log "Remove old nvidia-docker..."
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge -y nvidia-docker

log "Add repository..."
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
# distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
# curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
#   sudo tee /etc/apt/sources.list.d/nvidia-docker.list
# sudo apt-get update

log "Install nvidia-docker2..."
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd

log "Testing nvidia-docker..."
docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi

log_success "NVIDIA docker installation complete"
