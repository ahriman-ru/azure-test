#!/bin/bash
declare -r MASTER_IP=$1
declare -r MASTER_NAME='rfdmaster'
declare -r MASTER_PASSWORD='RFDCkjlysqGfhjkm1'
declare -r MASTER_USER_NAME='rfdmaster'

sudo -u $MASTER_USER_NAME touch /tmp/sshlog.log
sudo -u $MASTER_USER_NAME touch /tmp/ldaplog.log
echo "$MASTER_USER_NAME ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo
echo "$MASTER_IP  $MASTER_NAME" >> /etc/hosts

echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"

echo "SSH CONFIGURATION" >> /tmp/sshlog.log
if ! [ -f /home/$MASTER_USER_NAME/.ssh/id_rsa ]; then
    sudo -u $MASTER_USER_NAME sh -c "ssh-keygen -f /home/$MASTER_USER_NAME/.ssh/id_rsa -t rsa -N ''" >> /tmp/sshlog.log
fi

#torque MASTER installation
cd /tmp
wget http://www.adaptivecomputing.com/index.php?wpfb_dl=3212 -O torque.tar.gz
tar xzvf torque.tar.gz >> /tmp/azuredeploy.log.torque.$$ 2>&1
cd torque-6.1.1* >> /tmp/azuredeploy.log.torque.$$ 2>&1

sudo ./configure >> /tmp/azuredeploy.log.torque.$$ 2>&1
make >> /tmp/azuredeploy.log.torque.$$ 2>&1
make packages >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo make install >> /tmp/azuredeploy.log.torque.$$ 2>&1
# Create and start trqauthd
sudo cp contrib/systemd/trqauthd.service /usr/lib/systemd/system/ >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo systemctl enable trqauthd.service >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo ldconfig >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo systemctl start trqauthd.service >> /tmp/azuredeploy.log.torque.$$ 2>&1
sudo ./torque.setup $MASTER_USER_NAME >> /tmp/azuredeploy.log.torque.$$ 2>&1
echo "DONE"