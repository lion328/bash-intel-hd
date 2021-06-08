#!/bin/bash

hex_convert_indian_u32() {
    echo ${1:6:2}${1:4:2}${1:2:2}${1:0:2}
}

to_int() {
    printf "%d" $1
}
