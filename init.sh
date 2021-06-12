#!/bin/bash

. util.sh
. io.sh
. reg.sh

BAR0=$(($(reg_read_uint `reg GTTMMADR`) & 0xFFFFFFF0))
BAR0_HEX=`printf "%x" $BAR0`
