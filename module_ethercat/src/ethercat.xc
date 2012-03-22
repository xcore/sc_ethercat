// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "ethercat.h"

void ethercat_port_init(mii_ethercat_ports &m) {
	configure_clock_src(m.clk_mii_rx, m.p_mii_rxclk);
	configure_clock_src(m.clk_mii_tx, m.p_mii_txclk);

	set_clock_fall_delay(m.clk_mii_tx, 7); // NEEDED?

    configure_in_port_strobed_slave(m.p_mii_rxd, m.p_mii_rxdv, m.clk_mii_rx);
    configure_out_port_strobed_master(m.p_mii_txd, m.p_mii_txen, m.clk_mii_tx, 0);

	start_clock(m.clk_mii_rx);
	start_clock(m.clk_mii_tx);
}
