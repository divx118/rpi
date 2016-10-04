#!/bin/sh

# script to check what waste I can dispose today.
url="http://mijnafvalwijzer.nl/nl/6043EE/118/"
led_red=15
led_green=16
led_blue=1
red=0
green=0
blue=0
orange=0
day=`curl -s "$url" | hxnormalize -x | hxselect 'div.column.carouselMobile'|awk '/\<p\ class=\"/ {print $2}'|cut -d '>' -f2`
#day=`echo $day|cut -d ' ' -f1|cut -d '<' -f1`
echo $day
waste=`curl -s "$url" | hxnormalize -x | hxselect 'div.column.carouselMobile'|awk '/\<p\ class=\"/ {print $2}'|cut -d '"' -f2`
echo $waste
counter=1
for j in $day; do
j=`echo $j|cut -d ' ' -f1|cut -d '<' -f1`
echo $j
if [ "$j" = "vandaag" ];then
i=`echo $waste|cut -d ' ' -f$counter`
    case $i in
        restafval)
            echo restafval
            red=1
            ;;
        gft)
            echo gft
            green=1
            ;;
        plastic)
            echo plastic
            blue=1
            ;;
        papier)
            echo papier
            orange=1
            ;;
        *) echo "not specified"
    esac
fi
counter=$(($counter+1))
echo $counter
done
hour="`date +'%H'`"
while [ "$hour" -lt 12 ]; do
hour="`date +'%H'`"
    if [ $red = 1 ]; then
        gpio write $led_red 255
        sleep 1
        gpio write $led_red 0
    fi
    if [ $green = 1 ]; then
        gpio write $led_green 255
        sleep 1
        gpio write $led_green 0
    fi
    if [ $blue = 1 ]; then
        gpio write $led_blue 255
        sleep 1
        gpio write $led_blue 0
    fi
    if [ $orange = 1 ]; then
        gpio write $led_red 255
        gpio write $led_green 140
        sleep 1
        gpio write $led_red 0
        gpio write $led_green 0
    fi

done
gpio write $led_red 0
gpio write $led_green 0
gpio write $led_blue 0
exit 0


