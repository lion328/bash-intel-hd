#!/bin/bash

reg_var_all() {
    compgen -A variable | grep -P "[HRP]_\d+_"
}

reg_name_all() {
    reg_var_all | sed 's/^[HRP]_\([0-9]\+\)_//'
}

reg() {
    var=`reg_var_all | grep -P "^[HRP]_\d+_$1\$"`
    size=`echo $var | sed 's/^[HRP]_\([0-9]\+\)_.*$/\1/'`

    case ${var::1} in
        H) type=PCI0 ;;
        P) type=PCI2 ;;
        R) type=MMIO ;;
    esac

    echo $type $size ${!var}
}

# PCI 0:0.0 (Host Bridge) registers
# see also Intel CPU datasheet

H_2_VID=0x00000
H_2_DID=0x00002
H_2_GGC=0x00050
H_4_TOLUD=0x000BC
H_4_BDSM=0x000B0

# PCI 0:2.0 (GPU) registers
# see also Intel Graphics PRM

P_2_VID2=0x00000
P_2_DID2=0x00002
P_8_GMADR=0x00018
P_8_GTTMMADR=0x00010
P_4_IOBAR=0x00020
P_4_ROMADR=0x00030
P_4_BDSM_MIRROR=0x0005C
P_1_VTD_STATUS=0x00063
P_4_ASLS=0x000FC

# MMIO registers

R_4_NDE_RSTWRN_OPT=0x46408
B_RST_PCH_HANDSHAKE_ENABLE=$((1 << 4))

R_4_FUSE_STATUS=0x42000
B_FUSE_PG0_DIST_STATUS=$((1 << 27))
B_FUSE_PG1_DIST_STATUS=$((1 << 26))

R_4_PWR_WELL_CTL1=0x45400
R_4_PWR_WELL_CTL2=0x45404
B_PWR_WELL_1_REQ=$((1 << 29))
B_PWR_WELL_1_STATE=$((1 << 28))
B_PWR_WELL_MISC_REQ=$((1 << 1))
B_PWR_WELL_MISC_STATE=$((1 << 0))

R_4_CDCLK_CTL=0x46000
M_CDCLK_CTL_FREQ_SEL=$((3 << 26))
V_CDCLK_CTL_FREQ_SEL_337MHZ=2

R_4_DPLL_CTRL1=0x6C058
M_DPLL0_LINKRATE=$((7 << 0))
V_DPLL0_LINKRATE_1350MHZ=1

R_4_LCPLL1_CTL=0x46010
B_LCPLL1_CTL_PLL_ENABLE=$((1 << 31))
B_LCPLL1_CTL_PLL_LOCK=$((1 << 30))

R_4_DBUF_CTL=0x45008
B_DBUF_PWR_REQ=$((1 << 31))
B_DBUF_PWR_STATE=$((1 << 30))

R_4_PP_CONTROL=0xC7204
B_PP_CONTROL_VDD_OVERRIDE=$((1 << 3))
B_PP_CONTROL_BACKLIGHT_ENABLE=$((1 << 2))
B_PP_CONTROL_PWR_DOWN_ON_RESET=$((1 << 1))
B_PP_CONTROL_PWR_STATE_TARGET=$((1 << 0))

R_4_PP_DIVISOR=0xC7210
M_PP_DIVISOR_REF_DIV=0xFFFFFF00
M_PP_DIVISOR_PWR_CYCLE_DELAY=0xFF

R_4_PP_ON_DELAYS=0xC7208
R_4_PP_OFF_DELAYS=0xC720C
M_PP_DELAYS_PWR_CHANGE=0x1FFF0000
M_PP_DELAYS_BACKLIGHT_TO_FROM_PWR=0x1FFF

R_4_PP_STATUS=0xC7200
B_PP_STATUS_PANEL_ON=$((1 << 31))
M_PP_PWR_SEQ_PROGRESS=$((3 << 28))
V_PP_PWR_SEQ_PROGRESS_NONE=0
V_PP_PWR_SEQ_PROGRESS_UP=1
V_PP_PWR_SEQ_PROGRESS_DOWN=2

R_4_SBLC_PWM_CTL1=0xC8250
B_SBLC_PWM_PCH_ENABLE=$((1 << 31))
B_SBLC_PWM_BACKLIGHT_POLARITY=$((1 << 29))

R_4_SBLC_PWM_CTL2=0xC8254
M_SBLC_PWM_MAX_FREQ=0xFFFF0000
M_SBLC_PWM_DUTY_CYCLE=0xFFFF

R_4_SCHICKEN_1=0xC2000
B_SCHICKEN_1_128=$((1 << 0))
