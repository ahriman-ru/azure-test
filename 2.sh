#!/bin/bash
declare -r MASTER_IP=$1
declare -r MASTER_NAME='rfdmaster'
declare -r MASTER_PASSWORD='RFDCkjlysqGfhjkm1'
declare -r MASTER_USER_NAME='rfdmaster'
#debug part
sudo -u $MASTER_USER_NAME touch /tmp/sshlog.log
sudo -u $MASTER_USER_NAME touch /tmp/ldaplog.log
sudo -u $MASTER_USER_NAME touch /tmp/main.log

echo $MASTER_IP >> /tmp/main.log
echo $MASTER_NAME >> /tmp/main.log
####

###torque installation

echo "$MASTER_USER_NAME ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo
sudo sh -c "echo '$MASTER_IP $MASTER_NAME' >> /etc/hosts"

echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"

echo "SSH CONFIGURATION" >> /tmp/sshlog.log
#    local -r mykeygen="/home/mnt/myrfd.ssh-keygen.sh"
#    chmod 755 "${mykeygen}"
#    sudo sh "${mykeygen}"
if ! [ -f /home/$MASTER_USER_NAME/.ssh/id_rsa ]; then
    sudo -u $MASTER_USER_NAME sh -c "ssh-keygen -f /home/$MASTER_USER_NAME/.ssh/id_rsa -t rsa -N ''" >> /tmp/sshlog.log
fi
# Install sshpass to automate ssh-copy-id action
#sudo yum install -y epel-release
#sudo yum install -y sshpass
 sshpass -p $MASTER_PASSWORD ssh-copy-id -i /home/$MASTER_USER_NAME/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $MASTER_USER_NAME@$MASTER_IP >> /tmp/sshlog.log
echo "DONE"

cat /etc/hosts | sudo sshpass -p $MASTER_PASSWORD ssh -StrictHostKeyChecking=no $MASTER_USER_NAME@$MASTER_IP "sudo sh -c 'cat > /etc/hosts'" >> /tmp/sshlog.log
sudo cp /home/mnt/config /home/$MASTER_USER_NAME/.ssh/config
sudo chmod 400 /home/$MASTER_USER_NAME/.ssh/config
sudo chown rfdmaster /home/$MASTER_USER_NAME/.ssh/config

sudo authconfig --enableldap --enableldapauth --ldapserver=ldap://$MASTER_IP:389/ --ldapbasedn="dc=rfd,dc=com" --disablefingerprint --kickstart --update >> /tmp/ldaplog.log
#ldapsearch -x -b "uid=$MASTER_USER_NAME,ou=people,dc=rfd,dc=com"

###torque general installation
sudo /home/mnt/torque-package-mom-linux-x86_64.sh --install
sudo cp /home/mnt/pbs_mom /etc/init.d/pbs_mom
sudo /etc/init.d/pbs_mom start
#echo $(hostname) | ssh {az_user}@{MASTER_NAME} 'cat >> /var/spool/torque/server_priv/nodes'
#'chkconfig --add pbs_mom'