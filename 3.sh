#!/bin/sh

# This script can be found on https://github.com/Azure/azure-quickstart-templates/blob/master/torque-cluster/azuredeploy.sh
# This script is part of azure deploy ARM template
# This script assumes the Linux distribution to be Ubuntu (or at least have apt-get support)
# This script will install Torque on a Linux cluster deployed on a set of Azure VMs

# Basic info
date > /tmp/azuredeploy.log.$$ 2>&1
whoami >> /tmp/azuredeploy.log.$$ 2>&1
echo $@ >> /tmp/azuredeploy.log.$$ 2>&1

# Usage
if [ "$#" -ne 9 ]; then
  echo "Usage: $0 MASTER_NAME MASTER_IP WORKER_NAME WORKER_IP_BASE WORKER_IP_START NUM_OF_VM ADMIN_USERNAME ADMIN_PASSWORD TEMPLATE_BASE" >> /tmp/azuredeploy.log.$$
  exit 1
fi

# Preparation steps - hosts and ssh
###################################

# Parameters
MASTER_NAME=$1
MASTER_IP=$2
WORKER_NAME=$3
WORKER_IP_BASE=$4
WORKER_IP_START=$5
NUM_OF_VM=$6
ADMIN_USERNAME=$7
ADMIN_PASSWORD=$8
TEMPLATE_BASE=$9

# Update master node
echo $MASTER_IP $MASTER_NAME >> /etc/hosts
echo $MASTER_IP $MASTER_NAME > /tmp/hosts.$$

# Need to disable requiretty in sudoers, I'm root so I can do this.
sed -i "s/Defaults\s\{1,\}requiretty/Defaults \!requiretty/g" /etc/sudoers



# Update ssh config file to ignore unknow host
# Note all settings are for azureuser, NOT root
sudo -u $ADMIN_USERNAME sh -c "mkdir /home/$ADMIN_USERNAME/.ssh/;echo Host worker\* > /home/$ADMIN_USERNAME/.ssh/config; echo StrictHostKeyChecking no >> /home/$ADMIN_USERNAME/.ssh/config; echo UserKnownHostsFile=/dev/null >> /home/$ADMIN_USERNAME/.ssh/config"

# Generate a set of sshkey under /honme/azureuser/.ssh if there is not one yet
if ! [ -f /home/$ADMIN_USERNAME/.ssh/id_rsa ]; then
    sudo -u $ADMIN_USERNAME sh -c "ssh-keygen -f /home/$ADMIN_USERNAME/.ssh/id_rsa -t rsa -N ''"
fi

# Install sshpass to automate ssh-copy-id action
sudo yum install -y epel-release >> /tmp/azuredeploy.log.$$ 2>&1
sudo yum install -y sshpass >> /tmp/azuredeploy.log.$$ 2>&1

# Loop through all worker nodes, update hosts file and copy ssh public key to it
# The script make the assumption that the node is called %WORKER+<index> and have
# static IP in sequence order
i=0
while [ $i -lt $NUM_OF_VM ]
do
   workerip=`expr $i + $WORKER_IP_START`
   echo 'I update host - '$WORKER_NAME$i >> /tmp/azuredeploy.log.$$ 2>&1
   echo $WORKER_IP_BASE$workerip $WORKER_NAME$i >> /etc/hosts
   echo $WORKER_IP_BASE$workerip $WORKER_NAME$i >> /tmp/hosts.$$
   sudo -u $ADMIN_USERNAME sh -c "sshpass -p '$ADMIN_PASSWORD' ssh-copy-id $WORKER_NAME$i"
   i=`expr $i + 1`
done
# Install Azure Files packages and mount+configure it
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino

sudo -S yum install samba-client samba-common cifs-utils
sudo bash -c 'echo "//rfdclusterst.file.core.windows.net/rfd /home/mnt cifs vers=3.0,username=rfdclusterst,password=3nFJLH4uqdcs65sTfht5Ei55TaKR9g0SZVTjl5gzo38tiQP319giXu1aeyqnsmdI3WMPRD7B7zWGDPQ9HJMzBw==,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab'
sudo yum remove openldap-servers && sudo  rm -rf /etc/openldap/
sudo yum install -y openldap-servers
sudo slappasswd -h {MD5}
{MD5}3/XxrHV2U7+WdfhFclbbMw==
sudo  ldapadd -Y EXTERNAL -H ldapi:/// -f adminpassword.ldif

sudo ldapadd -x -D cn=admin,cn=config -W -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif && sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
sudo  ldapadd -Y EXTERNAL -H ldapi:/// -f domain.ldif
sudo ldapadd -x -D cn=Manager,dc=rfd,dc=com -W -f basedomain.ldif

sudo systemctl stop slapd
sudo systemctl start slapd

sudo cat /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif
sudo slaptest -u
sudo ldapadd -x -W -D "cn=Manager,dc=rfd,dc=com" -f /home/mnt/users.ldif
# Install Torque 
################

# Prep packages
sudo -S yum install -y libtool openssl-devel libxml2-devel boost-devel gcc gcc-c++ >> /tmp/azuredeploy.log.$$ 2>&1

# Download the source package
cd /tmp >> /tmp/azuredeploy.log.$$ 2>&1
wget http://www.adaptivecomputing.com/index.php?wpfb_dl=2936 -O torque.tar.gz >> /tmp/azuredeploy.log.$$ 2>&1
tar xzvf torque.tar.gz >> /tmp/azuredeploy.log.$$ 2>&1
cd torque-5.1.1* >> /tmp/azuredeploy.log.$$ 2>&1

# Build
./configure >> /tmp/azuredeploy.log.$$ 2>&1
make >> /tmp/azuredeploy.log.$$ 2>&1
make packages >> /tmp/azuredeploy.log.$$ 2>&1
sudo make install >> /tmp/azuredeploy.log.$$ 2>&1

export PATH=/usr/local/bin/:/usr/local/sbin/:$PATH

# Create and start trqauthd
sudo cp contrib/init.d/trqauthd /etc/init.d/ >> /tmp/azuredeploy.log.$$ 2>&1
sudo chkconfig --add trqauthd >> /tmp/azuredeploy.log.$$ 2>&1
sudo sh -c "echo /usr/local/lib > /etc/ld.so.conf.d/torque.conf" >> /tmp/azuredeploy.log.$$ 2>&1
sudo ldconfig >> /tmp/azuredeploy.log.$$ 2>&1
sudo service trqauthd start >> /tmp/azuredeploy.log.$$ 2>&1

# Update config
sudo sh -c "echo $MASTER_NAME > /var/spool/torque/server_name" >> /tmp/azuredeploy.log.$$ 2>&1

sudo env "PATH=$PATH" sh -c "echo 'y' | ./torque.setup root" >> /tmp/azuredeploy.log.$$ 2>&1

sudo sh -c "echo $MASTER_NAME > /var/spool/torque/server_priv/nodes" >> /tmp/azuredeploy.log.$$ 2>&1

# Start pbs_server
sudo cp contrib/init.d/pbs_server /etc/init.d >> /tmp/azuredeploy.log.$$ 2>&1
sudo chkconfig --add pbs_server >> /tmp/azuredeploy.log.$$ 2>&1
sudo service pbs_server restart >> /tmp/azuredeploy.log.$$ 2>&1

# Start pbs_mom
sudo cp contrib/init.d/pbs_mom /etc/init.d >> /tmp/azuredeploy.log.$$ 2>&1
sudo chkconfig --add pbs_mom >> /tmp/azuredeploy.log.$$ 2>&1
sudo service pbs_mom start >> /tmp/azuredeploy.log.$$ 2>&1

# Start pbs_sched
sudo env "PATH=$PATH" pbs_sched >> /tmp/azuredeploy.log.$$ 2>&1

# Push packages to compute nodes
i=0
while [ $i -lt $NUM_OF_VM ]
do
  worker=$WORKER_NAME$i
#azure files and share
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'mkdir /home/mnt'"
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'yum install samba-client samba-common cifs-utils'"
#sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS bash -c 'echo "//rfdclusterst.file.core.windows.net/rfd /home/mnt cifs vers=3.0,username=rfdclusterst,password=,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab'
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo mount -t cifs //rfdclusterst.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdclusterst,password=,dir_mode=0777,file_mode=0777,serverino'"
# Install sshpass to automate ssh-copy-id action and copy ssh
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'yum install -y epel-release'"
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'yum install -y sshpass'"
#ssh to trust master
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'ssh-keygen -f /home/$ADMIN_USERNAME/.ssh/id_rsa -t rsa -N'"
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'sshpass -p '$ADMIN_PASSWORD' ssh-copy-id rfdmaster@$MASTER_NAME'"
sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'authconfig --enableldap --enableldapauth --ldapserver=ldap://$MASTER_NAME:389/ --ldapbasedn='dc=rfd,dc=com' --disablefingerprint --kickstart --update'"

#install torque
  sudo -u $ADMIN_USERNAME scp /tmp/hosts.$$ $ADMIN_USERNAME@$worker:/tmp/hosts >> /tmp/azuredeploy.log.$$ 2>&1
  sudo -u $ADMIN_USERNAME scp torque-package-mom-linux-x86_64.sh $ADMIN_USERNAME@$worker:/tmp/. >> /tmp/azuredeploy.log.$$ 2>&1
  sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS sh -c 'cat /tmp/hosts>>/etc/hosts'"
  sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS /tmp/torque-package-mom-linux-x86_64.sh --install"
  sudo -u $ADMIN_USERNAME ssh -tt $worker "echo '$ADMIN_PASSWORD' | sudo -kS /usr/local/sbin/pbs_mom"
  echo $worker >> /var/spool/torque/server_priv/nodes
  i=`expr $i + 1`
done

# Restart pbs_server
sudo service pbs_server restart >> /tmp/azuredeploy.log.$$ 2>&1

exit 0
