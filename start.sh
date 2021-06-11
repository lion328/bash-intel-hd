#!/bin/bash

. init.sh

echo PCI BAR 0 at 0x$BAR0_HEX

if [[ "$MOCK" == "1" ]]; then
    echo "Write disabled"
fi

init_display() {
    echo "Initialize display"

    echo "Enable PCH Reset Handshake"
    reg_flag_set `reg NDE_RSTWRN_OPT` $B_RST_PCH_HANDSHAKE_ENABLE

    echo "Enable Power Well 1 (PG1) and Misc IO Power"
    reg_wait_until_set `reg FUSE_STATUS` $B_FUSE_PG0_DIST_STATUS

    reg_flag_set `reg PWR_WELL_CTL2` $(($B_PWR_WELL_1_REQ | $B_PWR_WELL_MISC_REQ))
    reg_wait_until_set `reg PWR_WELL_CTL2` $(($B_PWR_WELL_1_STATE | $B_PWR_WELL_MISC_STATE))

    reg_wait_until_set `reg FUSE_STATUS` $B_FUSE_PG1_DIST_STATUS

    echo "Enable CDCLK PLL"
    reg_mask_set `reg CDCLK_CTL` $M_CDCLK_CTL_FREQ_SEL $V_CDCLK_CTL_FREQ_SEL_337MHZ
    reg_mask_set `reg DPLL_CTRL1` $M_DPLL0_LINKRATE $V_DPLL0_LINKRATE_1350MHZ
    
    reg_flag_set `reg LCPLL1_CTL` $B_LCPLL1_CTL_PLL_ENABLE
    reg_wait_until_set `reg LCPLL1_CTL` $B_LCPLL1_CTL_PLL_LOCK

    # Changing CD Clock Frequency
    # nop

    echo "Enable DBUF"
    reg_flag_set `reg DBUF_CTL` $B_DBUF_PWR_REQ
    reg_wait_until_set `reg DBUF_CTL` $B_DBUF_PWR_STATE
}

uninit_display() {
    echo "Uninitialize display"

    echo "Disable DBUF"
    reg_flag_unset `reg DBUF_CTL` $B_DBUF_PWR_REQ
    reg_wait_until_unset `reg DBUF_CTL` $B_DBUF_PWR_STATE

    echo "Disable CDCLK PLL"
    reg_flag_unset `reg LCPLL1_CTL` $B_LCPLL1_CTL_PLL_ENABLE
    reg_wait_until_unset `reg LCPLL1_CTL` $B_LCPLL1_CTL_PLL_LOCK

    echo "Disable Power Well 1 (PG1) and Misc IO Power"
    reg_flag_unset `reg PWR_WELL_CTL2` $(($B_PWR_WELL_1_REQ | $B_PWR_WELL_MISC_REQ))
    reg_wait_until_unset `reg FUSE_STATUS` $(($B_PWR_WELL_1_STATE | $B_PWR_WELL_MISC_STATE))
}

init_displayport() {
    echo "Initialize DisplayPort"

    reg_mask_set `reg SBLC_PWM_CTL2` $M_SBLC_PWM_MAX_FREQ 0xBC
    reg_flag_set `reg SCHICKEN_1` $B_SCHICKEN_1_128
    reg_flag_set `reg SBLC_PWM_CTL1` $B_SBLC_PWM_PCH_ENABLE
    reg_flag_unset `reg SBLC_PWM_CTL1` $B_SBLC_PWM_BACKLIGHT_POLARITY
    reg_mask_set `reg SBLC_PWM_CTL2` $M_SBLC_PWM_DUTY_CYCLE 0xBC

    reg_mask_set `reg PP_DIVISOR` $M_PP_DIVISOR_PWR_CYCLE_DELAY 6

    reg_mask_set `reg PP_OFF_DELAYS` $M_PP_DELAYS_PWR_CHANGE 5000
    reg_mask_set `reg PP_OFF_DELAYS` $M_PP_DELAYS_BACKLIGHT_TO_FROM_PWR 500

    reg_mask_set `reg PP_ON_DELAYS` $M_PP_DELAYS_PWR_CHANGE 2100
    reg_mask_set `reg PP_ON_DELAYS` $M_PP_DELAYS_BACKLIGHT_TO_FROM_PWR 500

    reg_flag_set `reg PP_CONTROL` $(($B_PP_CONTROL_VDD_OVERRIDE | $B_PP_CONTROL_BACKLIGHT_ENABLE | $B_PP_CONTROL_PWR_DOWN_ON_RESET | $B_PP_CONTROL_PWR_STATE_TARGET))
    reg_wait_until_set `reg PP_STATUS` $B_PP_STATUS_PANEL_ON
}

uninit_displayport() {
    echo "Uninitialize DisplayPort"

    reg_flag_unset `reg PP_CONTROL` $(($B_PP_CONTROL_VDD_OVERRIDE | $B_PP_CONTROL_BACKLIGHT_ENABLE | $B_PP_CONTROL_PWR_STATE_TARGET))
    reg_wait_until_unset `reg PP_STATUS` $B_PP_STATUS_PANEL_ON

    reg_set_u32 `reg PP_DIVISOR` 0

    reg_mask_set `reg PP_OFF_DELAYS` $M_PP_DELAYS_PWR_CHANGE 0
    reg_mask_set `reg PP_OFF_DELAYS` $M_PP_DELAYS_BACKLIGHT_TO_FROM_PWR 0

    reg_mask_set `reg PP_ON_DELAYS` $M_PP_DELAYS_PWR_CHANGE 0
    reg_mask_set `reg PP_ON_DELAYS` $M_PP_DELAYS_BACKLIGHT_TO_FROM_PWR 0

    reg_flag_unset `reg SBLC_PWM_CTL1` $B_SBLC_PWM_PCH_ENABLE
    reg_mask_set `reg SBLC_PWM_CTL2` $(($M_SBLC_PWM_DUTY_CYCLE | $M_SBLC_PWM_MAX_FREQ)) 0
}

reg_dump_all

init_display
init_displayport

sleep 3
reg_dump_all

uninit_displayport
uninit_display

reg_dump_all
