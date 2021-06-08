#!/bin/bash

PCI_ADDR="0000:00:02.0"
BAR_HEX=`lspci -vvs $PCI_ADDR | grep "Region 0:" | sed "s/.*Memory at \([a-f0-9]*\) .*/\1/"`
BAR=`printf "%d" 0x$BAR_HEX`

hex_convert_indian_u32() {
    echo ${1:6:2}${1:4:2}${1:2:2}${1:0:2}
}

to_int() {
    printf "%d" $1
}

. io.sh
. reg.sh
