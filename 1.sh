#!/bin/bash
declare -r MASTER_NAME=$1
declare -r MASTER_IP=$2

touch /tmp/wewerehere
echo {MASTER_IP} > /tmp/wewereh

configure_azure_files() >> /tmp/azurelog.txt
configure_ssh_config() >> /tmp/sshconfiglog.txt
configure_ssh_keygen() >> /tmp/sshconfiglog.txt
configure_sudo() >> /tmp/sshconfiglog.txt

configure_azure_files(){
echo "AZURE FILES CONFIGURATION:"
mkdir -p /home/mnt
sudo mount -t cifs //rfdstorage.file.core.windows.net/rfd /home/mnt -o vers=3.0,username=rfdstorage,password=7Q+/+S8t/P2NNkIxp3zT15E4kZRdufcDldjCzpRB+Z2QPjgyThbPedHMX8++/mhOdc8nkfJ8Zt/3wVzzT72a1A==,dir_mode=0777,file_mode=0777,serverino
echo "AZURE FILES CONFIGURATION DONE"
}

configure_ssh_config() {
    local -r ssh_config='/etc/ssh/ssh_config'
    sed -i '/StrictHostKeyChecking/d' "${ssh_config}"
    echo -e '\tStrictHostKeyChecking no' >> "${ssh_config}"
}

configure_ssh_keygen() {
echo "SSH CONFIGURATION"
    local -r mykeygen="/home/mnt/myrfd.ssh-keygen.sh"
    chmod 755 "${mykeygen}"
    sudo sh "${mykeygen}"
echo "DONE"
}

configure_sudo() {
    cat > "/etc/sudoers.d/99-myrfd-${efadmin}" <<EOF
Defaults:${efadmin} !requiretty
${efadmin} ALL=(ALL) NOPASSWD:ALL
EOF
}

configure_auth() {
authconfig --enableldap --enableldapauth --ldapserver=ldap://{MASTER_IP}:389/ --ldapbasedn="dc=rfd,dc=com" --disablefingerprint --kickstart --update
#ldapsearch -x -b "uid=rfdmaster,ou=people,dc=rfd,dc=com"
}