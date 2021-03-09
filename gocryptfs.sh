#!/bin/bash

export LD_PRELOAD=/opt/lib/librm2fb_client.so.1.0.0
GOCRYPTFS=/home/root/go/bin/gocryptfs

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
  RESULT=$(echo ${script} | /opt/bin/simple)
}

buttonpress(){
  button="$(echo "${RESULT}" | sed 's/^selected:\s*//; s/\s* -.*$//' | xargs)"
  #if [[ $button == "Quit" ]];then
  #  break
  #fi
  case $button in
    "Quit")
       exit 0
       ;;
    "*")
       ;;
  esac
}

function add_keyboard(){
  # Add Keyboard
  posx=900
  posy=900
  offsetx=$posx
  offsety=$posy
  width=90
  height=90
  spacex=10
  spacey=10
  for symbol in {0..9} {a..z} "." "Del" "CLS" "Enter"
  do
      ui button $offsetx $offsety $width $height $symbol
      offsetx=$(( $offsetx + $width + $spacex ))
      if [ $offsetx -gt $(( 1404 - $width )) ]
	then
	offsetx=$posx
	offsety=$(( $offsety + $height + $spacey ))
      fi
  done
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


function typer(){
  [[ $password == "Mount failed!" ]]&&password=""
  case $button in 
	"Enter")
	decrypt&&return 1
	;;
	"Del")
	password=${password::-1};
	;;
	"CLS")
	password=""
	;;
	*) 
        password=$password$button
	;;
  esac
}

function decrypt(){
	echo "$password"|$GOCRYPTFS $CIPHER $PLAIN||password="Mount failed!"
}


while :;do
  reset
  add justify left

  # Add Input field
  ui label 50 50 1800 100 $password

  # Add Keyboard
  add_keyboard

  #run_checks||exit

  # Add wordlist  
  #  ui label 50 100 900 100 Diceware:
  #  for word in $(cat /home/root/simple-scripts/eff_large_wordlist.txt|grep $password -|tail -n 20)
  #	do
  #	ui label step step 900 100 $word
  #	done


  display
  buttonpress
  typer||break
done
