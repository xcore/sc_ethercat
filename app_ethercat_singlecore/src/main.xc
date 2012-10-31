// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <print.h>
#include <xs1.h>
#include <frame.h>
#include "ethercat.h"
#include "pduhandler.h"
#include "smi.h"

#define ETHCORE 0

#define NUMBER_DYNAMIC_CHANNELS 2

extern int destinationsCore0[NUMBER_DYNAMIC_CHANNELS];
extern int destinationsCore0_[NUMBER_DYNAMIC_CHANNELS];
extern int destinationsCore1[NUMBER_DYNAMIC_CHANNELS];
extern int destinationsCore1_[NUMBER_DYNAMIC_CHANNELS];

extern void waitFor(int &x);

on stdcore[0]: out port disableFlash = PORT_SPI_DISABLE;

on stdcore[1]: mii_ethercat_ports mii0 = {
    XS1_CLKBLK_3, XS1_CLKBLK_4,
    PORT_ETH_RXCLK_0, PORT_ETH_RXD_0, PORT_ETH_RXDV_0,
    PORT_ETH_TXCLK_0, PORT_ETH_TXD_0, PORT_ETH_TXEN_0,
};

on stdcore[1]: mii_ethercat_ports mii1 = {
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK_1, PORT_ETH_RXD_1, PORT_ETH_RXDV_1,
    PORT_ETH_TXCLK_1, PORT_ETH_TXD_1, PORT_ETH_TXEN_1,
};

on stdcore[0]: mii_ethercat_ports mii2 = {
    XS1_CLKBLK_3, XS1_CLKBLK_4,
    PORT_ETH_RXCLK_2, PORT_ETH_RXD_2, PORT_ETH_RXDV_2,
    PORT_ETH_TXCLK_2, PORT_ETH_TXD_2, PORT_ETH_TXEN_2,
};

on stdcore[0]: mii_ethercat_ports mii3 = {
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK_3, PORT_ETH_RXD_3, PORT_ETH_RXDV_3,
    PORT_ETH_TXCLK_3, PORT_ETH_TXD_3, PORT_ETH_TXEN_3,
};

on stdcore[1]: smi_interface_t smi0 = { 0x80000000,
                                        PORT_ETH_MDIOFAKE_0,
                                        PORT_ETH_MDIOC_0 };
on stdcore[1]: smi_interface_t smi1 = { 0,
                                        PORT_ETH_MDIO_1,
                                        PORT_ETH_MDC_1 };
on stdcore[0]: smi_interface_t smi2 = { 0x80000000,
                                        PORT_ETH_MDIOFAKE_2,
                                        PORT_ETH_MDIOC_2 };
on stdcore[0]: smi_interface_t smi3 = { 0,
                                        PORT_ETH_MDIO_3,
                                        PORT_ETH_MDC_3 };

on stdcore[1]: clock clk_smi0 = XS1_CLKBLK_5;
on stdcore[0]: clock clk_smi2 = XS1_CLKBLK_5;

int phyPresentAndUp(smi_interface_t &smi) {
    int basicStatus = smi_reg(smi, 1, 0, 1);
    return (basicStatus & 0x12) == 0 && (basicStatus & 4) == 4;
}

#define NUMBER_PORTS  4

void connectionHandler(chanend from0, chanend from1) {
    int portIsConnected[NUMBER_PORTS];
    int portIdentifiers[NUMBER_PORTS];
    int destinations[NUMBER_PORTS];

    for(int i = 0; i < NUMBER_PORTS; i++) {
        portIsConnected[i] = 1;
    }

    from0 :> portIdentifiers[0];
    from0 :> portIdentifiers[1];
    from1 :> portIdentifiers[2];
    from1 :> portIdentifiers[3];

    while(1) {
        from0 :> portIsConnected[0];
        from0 :> portIsConnected[1];
        from1 :> portIsConnected[2];
        from1 :> portIsConnected[3];
        portIsConnected[0] = 1;           // Assume connected. Better be.

        for(int i = 0; i < NUMBER_PORTS; i++) {
            if (!portIsConnected[i]) {
                destinations[i] = portIdentifiers[i] | 0xff00; // null chan
                continue;
            }
            for(int j = i+1; j < NUMBER_PORTS+1; j++) {
                int portNr;
                if (j == NUMBER_PORTS) {
                    portNr = 0;
                } else {
                    portNr = j;
                }
                if (portIsConnected[portNr]) {
                    destinations[i] = portIdentifiers[portNr];
                    break;
                }
            }
        }
        from0 <: destinations[0];
        from0 <: destinations[1];
        from1 <: destinations[2];
        from1 <: destinations[3];
    }
}

void linkConnectionChecker(smi_interface_t &smi0, smi_interface_t &smi1,
                           chanend toMaster,
                           int destinations_[2],
                           chanend init0, chanend init1) {
    timer t;
    int u, w0, w1, dest;

    init0 :> dest;
    toMaster <: dest;
    init1 :> dest;
    toMaster <: dest;

    t :> u;

    while(1) {
        u += 150000000;
        t when timerafter(u) :> void;
        w0 = phyPresentAndUp(smi0);
        w1 = phyPresentAndUp(smi1);
        toMaster <: w0;
        toMaster <: w1;
        toMaster :> destinations_[0];
        toMaster :> destinations_[1];
    }
}

void publishDestination(chanend init, streaming chanend dest) {
    int i;
    asm("add %0, %1, 0" : "=r" (i) : "r" (dest));
    init <: i;
}




void ethernetCore(mii_ethercat_ports &mii0, mii_ethercat_ports &mii1,
                  smi_interface_t &smi0, smi_interface_t &smi1,
                  clock clk_smi, out port ?disableFlash,
                  chanend toMaster,
                  int destinations[2], int destinations_[2],
                  int isProcessingNode) {
    short memory[4096];
    streaming chan protoToTx1, rx1ToTx0;
    timer tmr;
    int resetTime;
    chan init0, init1;
    int tempDestination;
    
    memory[0x502/2] = 0;

    if (!isnull(disableFlash)) {
        disableFlash <: 0;
    }
    
    tmr :> resetTime;
    resetTime += 50000000;
    tmr when timerafter(resetTime) :> void;

    ethercat_port_init(mii0);
    ethercat_port_init(mii1);
    configure_clock_ref (clk_smi, 10);
    configure_out_port_no_ready(smi0.p_smi_mdc,   clk_smi, 1);
    configure_out_port_no_ready(smi1.p_smi_mdc,   clk_smi, 1<<SMI_MDC_BIT);
    start_clock (clk_smi);

    eth_phy_config(1, smi0);
//    eth_phy_config(1, smi1);

    printhexln(eth_phy_id(smi0));
    printhexln(eth_phy_id(smi1));
    par {
        {
            if (isProcessingNode) {
                streaming chan rx0ToProto;
                par {
                    rxProcessS(mii0.p_mii_rxdv, mii0.p_mii_rxd, rx0ToProto, tempDestination);
                    frameProcess(rx0ToProto, protoToTx1, destinations[0], memory);
                }
            } else {
                rxProcessS(mii0.p_mii_rxdv, mii0.p_mii_rxd, protoToTx1, destinations[0]);
            }
        }
        rxProcessS(mii1.p_mii_rxdv, mii1.p_mii_rxd, rx1ToTx0, destinations[1]);
        {
            publishDestination(init1, protoToTx1);
            txProcess(mii1.p_mii_txd, protoToTx1);
        }
        {
            publishDestination(init0, rx1ToTx0);
            txProcess(mii0.p_mii_txd, rx1ToTx0);
        }
        linkConnectionChecker(smi0, smi1, toMaster, destinations_, init0, init1);
    }
}

int main(void) {
    chan core1CheckerToMaster;
    chan core0CheckerToMaster;
    par {
        on stdcore[1]: ethernetCore(mii0, mii1, smi0, smi1, clk_smi0,
                                    null, core0CheckerToMaster,
                                    destinationsCore0,
                                    destinationsCore0_,
                                    1);
        on stdcore[0]: ethernetCore(mii2, mii3, smi2, smi3, clk_smi2,
                                    disableFlash,         core1CheckerToMaster,
                                    destinationsCore1,
                                    destinationsCore1_,
                                    0);
        on stdcore[1]: connectionHandler(core0CheckerToMaster,
                                         core1CheckerToMaster);
    }
    return 0;
}
