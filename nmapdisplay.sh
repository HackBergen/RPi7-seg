#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "OBS: Running as root gives more accurate response" 1>&2
fi

mask2cidr() {

    local nbits dec
    local -a octets=( [255]=8 [254]=7 [252]=6 [248]=5 [240]=4
                      [224]=3 [192]=2 [128]=1 [0]=0           )

    while read -rd '.' dec; do
        [[ -z ${octets[dec]} ]] && echo "Error: $dec is not recognised" && exit 1
        (( nbits += octets[dec] ))
        (( dec < 255 )) && break
    done <<<"$1."

#    echo "/$nbits"
    CIDR=$nbits

}

DEVICE=`netstat -r | grep default | awk '{print $8}'`
echo "Current device: $DEVICE"
MASK=`ifconfig $DEVICE | sed -rn '2s/ .*:(.*)$/\1/p'`
NET=`ifconfig $DEVICE | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
echo "address: $NET"
echo "netmask: $MASK"
mask2cidr $MASK
NMAPscan="$NET/$CIDR"
echo "nmap string: $NMAPscan"
DEVSup=`nmap -sP $NMAPscan | tail -1 | awk -F'[()]' '{print $2}' | awk '{ print $1}'`
echo "Devices with ping response on local network: $DEVSup"
printf "v%3d" $DEVSup > /dev/ttyS1
