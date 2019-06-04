#!/bin/bash -ue
. log.sh

# Add ssh key
ssh-keygen -t rsa -b 4096 -C "sodeon@gmail.com"
# Start ssh agent
ssh-agent -s
# Add ssh key to ssh agent
ssh-add ~/.ssh/id_rsa
# Copy generated public key to clipboard
sudo apt install xclip
xclip -sel clip < ~/.ssh/id_rsa.pub

figlet 'Almost Done'
echo 'Go to github->settings->"SSH and GPG keys"->"New SSH key"
git repo format: git@github.com:username/reponame.git'
