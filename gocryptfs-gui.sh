#!/bin/bash

#export LD_PRELOAD=/opt/lib/librm2fb_client.so.1.0.1
GOCRYPTFS=/home/root/go/bin/gocryptfs

LAUNCHER=xochitl

PATH=/home/root/go/bin:/opt/bin/go/bin:/opt/bin:/opt/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

CIPHER=/home/root/.local/share/remarkable-cipher
PLAIN=/home/root/.local/share/remarkable


set -o noglob

reset(){
  SCENE=("@fontsize 32")
}

add(){
  SCENE+=("@$*")
}

ui(){
  SCENE+=("$*")
}

display(){
  IFS=$(echo -en "\n\b")
  script=$(for line in ${SCENE[@]}; do echo $line; done)
  IFS=" "
  # TODO remove logging to hide password
  RESULT=$(echo ${script} | /opt/bin/simple)
}

evaluate(){
  #id="$(echo "${RESULT}" | awk -F ": " '{print $2}')"
  message="$(echo "${RESULT}" | awk -F ": " '{print $3}')"
  export password="${message}"
  decrypt
}

run_checks(){
  # Check if gocryptfs is in PATH
  which $GOCRYPTFS||return 1
  # Check if fusermount in PATH 
  which fusermount||return 1
  # Check if the mountpoint is empty
  [[ -z $(ls $MOUNTPOINT) ]]||return 1 
  # All good? Return 0
  return 0
}



function decrypt(){
	echo "$password"|nohup $GOCRYPTFS $CIPHER $PLAIN&&return 1
}

#Delay start a little for better drawing
echo ""|simple
sleep 1
reset

while :;do
  reset
  add justify left

  # Add Input field
  ui label 50 160 1300 100 Enter password above, then press \'done\'
  ui textinput 50 50 1300 100

  display
  evaluate||break
done
echo ""|simple
reset
sleep 1
systemctl start $LAUNCHER
