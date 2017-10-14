#!/bin/bash
MASTER_NAME=$1
MASTER_IP=$2
touch /tmp/$MASTER_IP
touch /tmp/$MASTER_NAME
echo $MASTER_IP > /tmp/wewerehere
echo $MASTER_IP $MASTER_NAME >> /etc/hosts
date > /tmp/azuredeploy123.log