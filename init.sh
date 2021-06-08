#!/bin/bash

. io.sh
. reg.sh

hex_convert_indian_u32() {
    echo ${1:6:2}${1:4:2}${1:2:2}${1:0:2}
}

to_int() {
    printf "%d" $1
}

PCI_ADDR="0000:00:02.0"
BAR=$((`pci_config_read_u32 $PCI_ADDR 0x10` & 0xFFFFFFF0))
BAR_HEX=`printf "%x" $BAR`
