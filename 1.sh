#!/bin/bash
declare -r MASTER_IP=$1
declare -r MASTER_NAME=$2

sudo -u rfdmaster touch /tmp/sshlog.log
sudo -u rfdmaster touch /tmp/ldaplog.log
echo 'rfdmaster ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo
sudo sh -c 'echo "$MASTER_IP $MASTER_NAME" >> /etc/hosts'

echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"

echo "SSH CONFIGURATION" >> /tmp/sshlog.log
#    local -r mykeygen="/home/mnt/myrfd.ssh-keygen.sh"
#    chmod 755 "${mykeygen}"
#    sudo sh "${mykeygen}"
if ! [ -f /home/rfdmaster/.ssh/id_rsa ]; then
    sudo -u rfdmaster sh -c "ssh-keygen -f /home/rfdmaster/.ssh/id_rsa -t rsa -N ''" >> /tmp/sshlog.log
fi
# Install sshpass to automate ssh-copy-id action
sudo yum install -y epel-release
sudo yum install -y sshpass
sudo sshpass -p RFDCkjlysqGfhjkm1 ssh-copy-id -i /home/rfdmaster/.ssh/id_rsa.pub -o StrictHostKeyChecking=no rfdmaster@$MASTER_IP >> /tmp/sshlog.log
echo "DONE"

cat /etc/hosts | sudo sshpass -p RFDCkjlysqGfhjkm1 ssh -StrictHostKeyChecking=no rfdmaster@$MASTER_IP "sudo sh -c 'cat > /etc/hosts'" >> /tmp/sshlog.log

sudo authconfig --enableldap --enableldapauth --ldapserver=ldap://$MASTER_IP:389/ --ldapbasedn="dc=rfd,dc=com" --disablefingerprint --kickstart --update >> /tmp/ldaplog.log
#ldapsearch -x -b "uid=rfdmaster,ou=people,dc=rfd,dc=com"