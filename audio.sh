#!/bin/sh
# Note that I cannot directly choose a source
# on my soundbar. I need to toggle it until I get to the bluetooth input source.
# I am using a Samsung HW-E450 soundbar. This script will run in the background
# and check the playback status of mpd if it is not playing it turns of the bluetooth
# output. To enable playback I have enabled the null audio output in /etc/mpd.conf
# so you will have 2 audio outputs. This way you can start playing a file even if the
# bluetooth audio is disabled.
#
# define var change to your needs.
btdevice="C4:73:1E:0E:8B:CC"
host="0204@localhost"
port="900"
counter=0
timeoutcounter=200
lircdevice="Audio"
keypower="KEY_POWER"
keysource="satsource"

poweraudio() {
echo "Starting with power on"
irsend send_start $lircdevice $keypower
sleep 0.5
irsend send_stop $lircdevice $keypower
}

loopsource() {
echo "Ok Now we will need a loop to walk through the inputs."
# TODO: lower the number of times when it is more reliable.
# We have 5 inputs.
j=0
while [ "x`hcitool name $btdevice`" = "x" -a $j -lt 10 ] ;do
  irsend send_once $lircdevice $keysource
  echo "wait a moment $j"
  j=$(( $j+1 ))
  # TODO: see if this can be speed up a bit.
  sleep 1
done
}

bluetoothaudio() {
poweraudio
echo "Soundbar should be starting up now"
echo "We will sleep for a bit to give it some time"
sleep 2
loopsource
}

checkstatus() {
  if [ "x`mpc --host=$host -p $port|grep playing`" = "x" ];then
    #playback paused or stopped we will disable output 1 (bluetooth).
    mpc --host=$host -p $port disable 1
  elif [ "x`hcitool name $btdevice`" = "x" ];then
    bluetoothaudio
  elif [ "x`mpc --host=$host -p $port outputs|grep 'Output 1'|grep -o '[^ ]*$'`" = "xdisabled" ];then
    #playback started enable output 1 (bluetooth)
    mpc --host=$host -p $port enable 1
  fi
}

while [ true ];do
  echo "check playback status every 2 seconds"
  checkstatus
  counter=$(( $counter+1 ))
  # Empty log file every 2 hours. mpd just let's it grow.
  if [ $counter -eq 3600 ];then
    counter=0
    cp /var/log/mpd/mpd.log /var/log/mpd/mpd.log.old
    echo "" > /var/log/mpd/mpd.log
  fi
  sleep 2
done

exit 0

