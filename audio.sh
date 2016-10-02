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
port="6602"
counter=0
counter1=0
timeoutcounter=200
lircdevice="Audio"
keypower="KEY_POWER"
keysource="satsource"
link=-1
poweraudio() {
echo "Starting with power on"
irsend send_start $lircdevice $keypower
sleep 0.4
irsend send_stop $lircdevice $keypower
}

loopsource() {
echo "Ok Now we will need a loop to walk through the inputs."
# TODO: lower the number of times when it is more reliable.
# We have 5 inputs.
times=$1
j=0

echo $times
while [ "`hcitool name $btdevice`" = "" -a $j -lt $times ] ;do
  irsend send_once $lircdevice $keysource $keysource
  echo "wait a moment $j"
  sleep 2
  j=$(( $j+1 ))
  # TODO: see if this can be speed up a bit.
done
}

bluetoothaudio() {
poweraudio
echo "Soundbar should be starting up now"
echo "We will sleep for a bit to give it some time"
sleep 2
loopsource 5
}

link_available()
{
if curl --output /dev/null --silent --head --fail "$1"; then
    link=1
else
    link=0
fi
}

checkstatus() {

  if [ "`mpc --host=$host -p $port|grep playing`" = "" ];then
    #playback paused or stopped we will disable output 1 (bluetooth).
    mpc --host=$host -p $port disable 1
    return
  fi
  if [ "`hcitool name $btdevice`" = "" ];then
    bluetoothaudio
  fi
  # Be sure bluetooth is connected.
  if [ "`hcitool name $btdevice`" != "" -a "`hcitool con|grep -o \"$btdevice\"`" = "" ]; then
    bt-audio -c "$btdevice"
  fi
  if [ "`mpc --host=$host -p $port outputs|grep 'Output 1'|grep -o '[^ ]*$'`" = "disabled" \
      -a "`hcitool con|grep -o \"$btdevice\"`" = "$btdevice" ];then
    #playback started enable output 1 (bluetooth)
    mpc --host=$host -p $port enable 1
  fi
}

while [ true ];do
  echo "check playback status every 2 seconds"
  link_available http://10.0.0.16:8000
  if [  "$link" = "1" -a "`mpc |grep playing`" = "" ]; then 
  mpc --host=$host -p $port play
  else
  mpc --host=$host -p $port stop
  fi

  checkstatus
  if [ "`mpc --host=$host -p $port outputs|grep 'Output 1'|grep -o '[^ ]*$'`" = "disabled" ]; then
    counter1=$(( $counter1+1 ))
  else
    counter1=0
  fi
  # Disconnect bluetooth after 5 minutes of no playback
  if [ $counter1 -eq 150 ]; then
    counter1=0
    if [ "`hcitool con|grep -o \"$btdevice\"`" = "$btdevice" ]; then
      bt-audio -d $btdevice
    fi
  fi
  counter=$(( $counter+1 ))
  # Empty log file every 1 hour. mpd just let's it grow.
  if [ $counter -eq 1800 ];then
    counter=0
    cp /var/log/mpd/mpd.log /var/log/mpd/mpd.log.old
    echo "" > /var/log/mpd/mpd.log
  fi
  sleep 2
done

exit 0

