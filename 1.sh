#!/bin/bash
declare -r MASTER_IP=$1
declare -r MASTER_NAME='rfdmaster'

sudo -u rfdmaster touch /tmp/sshlog.log
sudo -u rfdmaster touch /tmp/ldaplog.log
echo 'rfdmaster ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo
echo "$MASTER_IP $MASTER_NAME" >> /etc/hosts

echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"

echo "SSH CONFIGURATION" >> /tmp/sshlog.log
if ! [ -f /home/rfdmaster/.ssh/id_rsa ]; then
    sudo -u rfdmaster sh -c "ssh-keygen -f /home/rfdmaster/.ssh/id_rsa -t rsa -N ''" >> /tmp/sshlog.log
fi
cd /home/mnt/torque-6.1.1*
sudo ./configure >> /tmp/azuredeploy.log.torque.$$ 2>&1
make >> /tmp/azuredeploy.log.torque.$$ 2>&1
make packages >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo make install >> /tmp/azuredeploy.log.torque.$$ 2>&1

echo "DONE"