#!/bin/bash
declare -r MASTER_NAME=$1
declare -r MASTER_IP=$2

echo 'rfdmaster ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo
sh -c 'echo "$MASTER_IP $MASTER_NAME" >> /etc/hosts'

echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"


    local -r ssh_config='/etc/ssh/ssh_config'
    sed -i '/StrictHostKeyChecking/d' "${ssh_config}"
    echo -e '\tStrictHostKeyChecking no' >> "${ssh_config}"

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
sudo sshpass -p RFDCkjlysqGfhjkm1 ssh-copy-id -i /home/rfdmaster/.ssh/id_rsa.pub -o StrictHostKeyChecking=no rfdmaster@$MASTER_IP
echo "DONE"

cat /etc/hosts | ssh rfdmaster@$MASTER_IP "sudo sh -c 'cat > /etc/hosts'"

authconfig --enableldap --enableldapauth --ldapserver=ldap://$MASTER_IP:389/ --ldapbasedn="dc=rfd,dc=com" --disablefingerprint --kickstart --update
#ldapsearch -x -b "uid=rfdmaster,ou=people,dc=rfd,dc=com"