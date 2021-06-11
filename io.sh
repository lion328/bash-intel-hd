#!/bin/bash

file_read_bytes_hex() {
    addr=`to_int $3`
    sudo dd "if=$1" iflag=skip_bytes skip=$addr bs=$2 count=1 status=none | xxd -e -g4 -p
}

file_write_bytes_hex() {
    strlen=${#3}

    if [[ $(($strlen % 2)) != 0 ]]; then
        echo "file_write_bytes_hex error: uneven size of hex"
        return
    fi

    len=$(($strlen / 2))

    if [[ "$MOCK" == "1" ]]; then
        printf "file_write_bytes_hex stub: $1 (0x%08x) = %s\n" $2 $3
        return
    fi

    addr=`to_int $2`
    echo -n $3 | xxd -r -p | sudo dd "of=$1" oflag=seek_bytes seek=$addr bs=$len count=1 status=none
}

file_read_bytes_hex_le_to_be() {
    hex=`file_read_bytes_hex $@`
    hex_convert_indian $hex
}

file_write_bytes_hex_be_to_le() {
    data_le=`hex_convert_indian $data`
    file_write_bytes_hex $1 $2 $data_le
}

file_read_uint() {
    hex=`file_read_bytes_hex_le_to_be $@`
    printf "%d" 0x$hex
}

file_write_uint() {
    size=$(($2 * 2))
    data=`printf "%0${size}x" $4`
    file_write_bytes_hex_be_to_le $1 $3 $data
}

pci_config_read_uint() {
    file_read_uint "$PCI_DIR/config" $@
}

mem_read_uint() {
    file_read_uint /dev/mem $@
}

mem_write_uint() {
    file_write_uint /dev/mem $@
}

reg_to_bar0_addr() {
    reg=`to_int $1`
    addr=$(($BAR0 + $reg))

    echo $addr
}

reg_read_uint() {
    case $1 in
        pci)
            pci_config_read_uint $2 $3
            ;;
        mmio)
            mem_read_uint $2 `reg_to_bar0_addr $3`
            ;;
    esac
}

reg_write_uint() {
    case $1 in
        pci)
            echo_err "reg_write_uint: write for PCI config is unimplemented"
            ;;
        mmio)
            printf "SET REG(0x%08x) = 0x%08x\n" $3 $4
            mem_write_uint $2 `reg_to_bar0_addr $3` $4
            ;;
    esac
}

reg_dump() {
    info=`reg $1`
    info_arr=($info)
    strlen=$((${info_arr[1]} * 2))
    addr=${info_arr[2]}
    v=`reg_read_uint $info`

    printf "%-20s REG(0x%08x) = 0x%0${strlen}x\n" $1 $addr $v
}

reg_dump_all() {
    echo "---------------------- REGISTER DUMP ----------------------"
    for var in `reg_name_all`; do
        reg_dump $var
    done
    echo "-------------------- END REGISTER DUMP --------------------"
}

reg_flag_set() {
    printf "REG(0x%08x) |= 0x%08x\n" $3 $4

    v=`reg_read_uint $1 $2 $3`

    printf "REG(0x%08x) == 0x%08x\n" $3 $v

    v=$(($v | $4))
    reg_write_uint $1 $2 $3 $v
}

reg_wait_until_set() {
    printf "WAIT REG(0x%08x) & 0x%08x > 0\n" $3 $4

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`reg_read_uint $1 $2 $3`
        v=$(($vo & $4))

        if [[ $vo != $old ]]; then
            printf "REG(0x%08x) == 0x%08x\n" $3 $vo
            old=$vo
        fi

        if [[ $v -gt 0 ]]; then
            break
        fi
    done  
}

reg_flag_unset() {
    printf "REG(0x%08x) &= ~0x%08x\n" $3 $4

    v=`reg_read_uint $1 $2 $3`

    printf "REG(0x%08x) == 0x%08x\n" $3 $v

    v=$(($v & ~$4))
    reg_write_uint $1 $2 $3 $v
}

reg_wait_until_unset() {
    printf "WAIT REG(0x%08x) & 0x%08x == 0\n" $3 $4

    if [[ "$MOCK" == "1" ]]; then
        return
    fi

    old=noninteger
    while true; do
        vo=`reg_read_uint $1 $2 $3`
        v=$(($vo & $4))
        
        if [[ $vo != $old ]]; then
            printf "REG(0x%08x) == 0x%08x\n" $3 $vo
            old=$vo
        fi

        if [[ $v == 0 ]]; then
            break
        fi
    done  
}

reg_mask_set() {
    part=`shift_to_mask $4 $5`

    printf "REG(0x%08x) & 0x%08x = 0x%08x\n" $3 $4 $part

    v=`reg_read_uint $1 $2 $3`

    printf "REG(0x%08x) == 0x%08x\n" $3 $v

    v=$(($v & ~$4))
    v=$(($v | $part))
    reg_write_uint $1 $2 $3 $v
}
