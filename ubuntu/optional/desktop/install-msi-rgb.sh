#!/bin/bash -ue
if sudo dmidecode -t 2 | grep -q 'Micro-Star International'; then
    sudo cp ../../apps/msi-rgb ~/.local/bin
else
    echo "Error: No MSI motherboard detected"
    exit 1
fi
