#!/bin/bash

# Simple script to shutdown remote Linux hosts without Ansible or similar tools.
# See https://stackoverflow.com/questions/305035/how-to-use-ssh-to-run-a-local-shell-script-on-a-remote-machine

# First, on each remote host and for your remote user user_id set the following in the sudoers file:
# sudo visudo
# user_id ALL=(ALL:ALL) NOPASSWD: /sbin/shutdown

# Adjust the settings according to your environment
PREFIX="192.168.10.5"
NUMHOSTS=3
USERID="ubuntu"

for (( i=1; i<=$NUMHOSTS ; i++ ))
do

MACHINE=${PREFIX}${i}

echo -n "Contacting" ${USER}@${MACHINE} "..."
ssh -o ConnectTimeout=3 ${USERID}@${MACHINE} exit 2>/dev/null 
if (( $? == 0 ))
then
echo " Shutting down"
ssh ${USERID}@${MACHINE} 'bash -s' <<'ENDSSH'
  sudo shutdown now
ENDSSH
else
  echo " SSH is down"
fi

done
