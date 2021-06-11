#!/bin/bash

PCI_ADDR="0000:00:02.0"
PCI_DIR="/sys/bus/pci/devices/$PCI_ADDR"

. util.sh
. io.sh
. reg.sh

BAR0=$(($(reg_read_uint `reg GTTMMADR`) & 0xFFFFFFF0))
BAR0_HEX=`printf "%x" $BAR0`
