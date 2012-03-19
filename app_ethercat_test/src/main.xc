// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <print.h>
#include <xs1.h>
#include <frame.h>
#include "pduhandler.h"
#include "smi.h"

#define NUMBER_DYNAMIC_CHANNELS 5

extern int destinationIdentifiers[NUMBER_DYNAMIC_CHANNELS];
extern int destinationIdentifiers_[NUMBER_DYNAMIC_CHANNELS];
extern int destinations[NUMBER_DYNAMIC_CHANNELS];
extern int destinations_[NUMBER_DYNAMIC_CHANNELS];

extern void waitFor(int &x);

/** This structure is subtly different from the normal mii_interface_t
 * in that it is 8 bit buffered rather than 32 bit buffered. No need
 * for a facke port either.
 */
typedef struct mii_interface_t {
    clock clk_mii_rx;            /**< MII RX Clock Block **/
    clock clk_mii_tx;            /**< MII TX Clock Block **/
    
    in port p_mii_rxclk;         /**< MII RX clock wire */
    in port p_mii_rxer;          /**< MII RX error wire */
    in buffered port:8 p_mii_rxd; /**< MII RX data wire */
    in port p_mii_rxdv;          /**< MII RX data valid wire */
    
    in port p_mii_txclk;       /**< MII TX clock wire */
    out port p_mii_txen;       /**< MII TX enable wire */
    out buffered port:8 p_mii_txd; /**< MII TX data wire */
} mii_interface_t;


on stdcore[2]: mii_interface_t mii0 = {
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK_0, PORT_ETH_RXER_0, PORT_ETH_RXD_0, PORT_ETH_RXDV_0,
    PORT_ETH_TXCLK_0, PORT_ETH_TXEN_0, PORT_ETH_TXD_0,
};

on stdcore[2]: mii_interface_t mii1 = {
    XS1_CLKBLK_3, XS1_CLKBLK_4,
    PORT_ETH_RXCLK_1, PORT_ETH_RXER_1, PORT_ETH_RXD_1, PORT_ETH_RXDV_1,
    PORT_ETH_TXCLK_1, PORT_ETH_TXEN_1, PORT_ETH_TXD_1,
};

on stdcore[2]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[2]: smi_interface_t smi0 = { 0x1f, PORT_ETH_MDIO_0, PORT_ETH_MDC_0 };
on stdcore[2]: smi_interface_t smi1 = { 0x1f, PORT_ETH_MDIO_1, PORT_ETH_MDC_1 };

on stdcore[2]: clock clk_smi = XS1_CLKBLK_5;

void mii_port_init(mii_interface_t &m) {
	configure_clock_src(m.clk_mii_rx, m.p_mii_rxclk);
	configure_clock_src(m.clk_mii_tx, m.p_mii_txclk);

	set_clock_fall_delay(m.clk_mii_tx, 7); // NEEDED?

    configure_in_port_strobed_slave(m.p_mii_rxd, m.p_mii_rxdv, m.clk_mii_rx);
    configure_out_port_strobed_master(m.p_mii_txd, m.p_mii_txen, m.clk_mii_tx, 0);

	start_clock(m.clk_mii_rx);
	start_clock(m.clk_mii_tx);
}

#define RESET_TIMER_DELAY 50000

void phy_reset(out port p_mii_resetn, timer tmr) {
    unsigned int  resetTime;

    p_mii_resetn <: 0;
    tmr :> resetTime;
    resetTime += RESET_TIMER_DELAY;
    tmr when timerafter(resetTime) :> void;
  
    p_mii_resetn <: ~0;
    tmr :> resetTime;
    resetTime += RESET_TIMER_DELAY;
    tmr when timerafter(resetTime) :> void;
}

void linkConnectionChecker(smi_interface_t &smi0, smi_interface_t &smi1) {
    timer t;
    int u, w0, w1;
    int forwarding;
    for(int i = 0; i < 3; i++) {
        waitFor(destinationIdentifiers_[i]);
        destinations_[i] = destinationIdentifiers_[i];
    }
    forwarding = 0;
t :> u;
    while(1) {
        u += 150000000;
        t when timerafter(u) :> void;
        w0 = smiCheckLinkState(smi0);
        w1 = smiCheckLinkState(smi1);
//        printintln(20000 + w0 * 100 + w1);
        if (w1) {
            if (!forwarding) {
                forwarding = 1;
                destinations_[0] = destinationIdentifiers[1];
                destinations_[1] = destinationIdentifiers[0];
                printstr("Forwarding enabled\n");
            }
        } else {
            if (forwarding) {
                forwarding = 0;
                destinations_[0] = destinationIdentifiers[0];
                destinations_[1] = destinationIdentifiers[0];
                printstr("Forwarding disabled\n");
            }
        }
    }
}


void ethernetCore() {
    streaming chan rx0ToProto, protoToTx1, rx1ToTx0;
    timer t;

    phy_reset(p_mii_resetn, t);
    mii_port_init(mii0);
    mii_port_init(mii1);
    printstr("Inited\n");
    configure_clock_ref (clk_smi, 10);
    configure_out_port_no_ready(smi0.p_smi_mdc,   clk_smi, 1);
    configure_out_port_no_ready(smi1.p_smi_mdc,   clk_smi, 1);
    start_clock (clk_smi);

    eth_phy_config(1, smi0);
    eth_phy_config(1, smi1);

    printhexln(eth_phy_id(smi0));
    printhexln(eth_phy_id(smi1));

    par {
#if 0
        rx0Process(mii0.p_mii_rxdv, mii0.p_mii_rxd, rx0ToProto);
        frameProcess(rx0ToProto, protoToTx1, txFrame);
        txProcess(mii1.p_mii_txd, protoToTx1, tx1);
        rxNProcess(mii1.p_mii_rxdv, mii1.p_mii_rxd, rx1ToTx0);
        txProcess(mii0.p_mii_txd, rx1ToTx0, tx0);
#else
        {
            waitFor(destinations[2]);
            rxProcessS(mii0.p_mii_rxdv, mii0.p_mii_rxd, rx0ToProto, destinations[2]);
        }
        {
            waitFor(destinations[0]);
            frameProcess(rx0ToProto, protoToTx1, destinationIdentifiers[2], destinations[0]);
        }
        txProcess(mii1.p_mii_txd, protoToTx1, destinationIdentifiers[1]);
        {
            waitFor(destinations[1]);
            rxProcessS(mii1.p_mii_rxdv, mii1.p_mii_rxd, rx1ToTx0, destinations[1]);
        }
        txProcess(mii0.p_mii_txd, rx1ToTx0, destinationIdentifiers[0]);
#endif
        linkConnectionChecker(smi0, smi1);
    }
}

int main(void) {
    par {
        on stdcore[2]: ethernetCore();
    }
    return 0;
}
