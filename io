#!/bin/bash

mmio_read() {
    reg=`to_int $1`
    addr=$(($BAR + $reg))

    hex=`sudo dd if=/dev/mem iflag=skip_bytes skip=$addr bs=4 count=1 status=none | xxd -e -g4 -p`
    hex_be=`hex_convert_indian_u32 $hex`
    printf "%d" 0x$hex_be
}

mmio_write() {
    if [[ "$MOCK" == "1" ]]; then
        printf "mmio_write stub; REG(0x%x) = 0x%x\n" $1 $2
        return
    fi

    reg=`to_int $1`
    addr=$(($BAR + $reg))

    data=`printf "%08x" $2`
    data_le=`hex_convert_indian_u32 $data`

    echo -n $data_le | xxd -r -p | sudo dd of=/dev/mem oflag=seek_bytes seek=$addr bs=4 count=1 status=none
}

reg_flag_set() {
    printf "REG(0x%08x) |= 0x%08x\n" $1 $2

    v=`mmio_read $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v | $2))
    mmio_write $1 $v

    printf "SET REG(0x%08x) = 0x%08x\n" $1 $v
}

reg_wait_until_set() {
    printf "WAIT REG(0x%08x) & 0x%08x > 0\n" $1 $2

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`mmio_read $1`
        v=$(($vo & $2))

        if [[ $vo != $old ]]; then
            printf "REG(0x%08x) == 0x%08x\n" $1 $vo
            old=$vo
        fi

        if [[ $v -gt 0 ]]; then
            break
        fi
    done  
}

reg_flag_unset() {
    printf "REG(0x%08x) &= ~0x%08x\n" $1 $2

    v=`mmio_read $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v & ~$2))
    mmio_write $1 $v

    printf "SET REG(0x%08x) = 0x%08x\n" $1 $v
}

reg_wait_until_unset() {
    printf "WAIT REG(0x%08x) & 0x%08x == 0\n" $1 $2

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`mmio_read $1`
        v=$(($vo & $2))
        
        if [[ $vo != $old ]]; then
            printf "REG(0x%08x) == 0x%08x\n" $1 $vo
            old=$vo
        fi

        if [[ $v == 0 ]]; then
            break
        fi
    done  
}

reg_mask_set() {
    part=`shift_to_mask $2 $3`

    printf "REG(0x%08x) & 0x%08x = 0x%08x\n" $1 $2 $part

    v=`mmio_read $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v & ~$2))
    v=$(($v | $part))
    mmio_write $1 $v

    printf "SET REG(0x%08x) = 0x%08x\n" $1 $v
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
