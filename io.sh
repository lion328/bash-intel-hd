#!/bin/bash

file_read_u32() {
    addr=`to_int $2`

    hex=`sudo dd if=$1 iflag=skip_bytes skip=$addr bs=4 count=1 status=none | xxd -e -g4 -p`
    hex_be=`hex_convert_indian_u32 $hex`
    printf "%d" 0x$hex_be
}

file_write_u32() {
    if [[ "$MOCK" == "1" ]]; then
        printf "file_write_u32 stub: $1 (0x%x) = 0x%x\n" $2 $3
        return
    fi

    addr=`to_int $2`

    data=`printf "%08x" $3`
    data_le=`hex_convert_indian_u32 $data`

    echo -n $data_le | xxd -r -p | sudo dd of=/dev/mem oflag=seek_bytes seek=$addr bs=4 count=1 status=none
}

mem_read_u32() {
    file_read_u32 /dev/mem $@
}

mem_write_u32() {
    file_write_u32 /dev/mem $@
}

reg_to_bar0_addr() {
    reg=`to_int $1`
    addr=$(($BAR + $reg))

    echo $addr
}

bar0_read_u32() {
    mem_read_u32 `reg_to_bar0_addr $1`
}

bar0_write_u32() {
    printf "SET REG(0x%08x) = 0x%08x\n" $1 $2
    mem_write_u32 `reg_to_bar0_addr $1` $2
}

reg_dump() {
    name=$2
    if [[ -z $name ]]; then
        name='?'
    fi

    v=`bar0_read_u32 $1`

    printf "REG(0x%08x) = 0x%08x : $name\n" $1 $v
}

reg_dump_all() {
    echo "------- REGISTER DUMP -------"
    for var in "${!R_@}"; do
        reg_dump ${!var} ${var:2}
    done
    echo "----- END REGISTER DUMP -----"
}

reg_flag_set() {
    printf "REG(0x%08x) |= 0x%08x\n" $1 $2

    v=`bar0_read_u32 $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v | $2))
    bar0_write_u32 $1 $v
}

reg_wait_until_set() {
    printf "WAIT REG(0x%08x) & 0x%08x > 0\n" $1 $2

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`bar0_read_u32 $1`
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

    v=`bar0_read_u32 $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v & ~$2))
    bar0_write_u32 $1 $v
}

reg_wait_until_unset() {
    printf "WAIT REG(0x%08x) & 0x%08x == 0\n" $1 $2

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`bar0_read_u32 $1`
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

    v=`bar0_read_u32 $1`

    printf "REG(0x%08x) == 0x%08x\n" $1 $v

    v=$(($v & ~$2))
    v=$(($v | $part))
    bar0_write_u32 $1 $v
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
