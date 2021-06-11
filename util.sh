#!/bin/bash

echo_err() {
    echo $@ 1>&2
}

hex_convert_indian() {
    remainder=$1

    if [[ $((${#remainder} % 2)) != 0 ]]; then
        echo_err "hex_convert_indian: $1 is not padded"
        return
    fi

    while [[ ! -z "$remainder" ]]; do
        out=$out${remainder: -2}
        remainder=${remainder:0: -2}
    done
    echo $out
}

to_int() {
    printf "%d" $1
}


shift_to_mask() {
    mask=$1
    val=$2

    bit=0
    left=$mask
    while [[ $(($left & 1)) == 0 ]]; do
        bit=$(($bit + 1))
        left=$(($left >> 1))
    done

    val=$(($val << $bit))
    val=$(($val & $mask))

    echo $val
}
