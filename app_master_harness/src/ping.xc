// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <stdio.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "smi.h"
#include "miiClient.h"
#include "miiDriver.h"

#define ETH_CORE 2

on stdcore[ETH_CORE]: port led0 = PORT_LED_2_0;
on stdcore[ETH_CORE]: port led1 = PORT_LED_2_1;

on stdcore[ETH_CORE]: mii_interface_t mii =
  {
    XS1_CLKBLK_1,
    XS1_CLKBLK_2,

    PORT_ETH_RXCLK,
    PORT_ETH_RXER,
    PORT_ETH_RXD,
    PORT_ETH_RXDV,

    PORT_ETH_TXCLK,
    PORT_ETH_TXEN,
    PORT_ETH_TXD,

    XS1_PORT_8A,
  };

#ifdef PORT_ETH_RST_N
on stdcore[ETH_CORE]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[ETH_CORE]: smi_interface_t smi = { 0, PORT_ETH_MDIO, PORT_ETH_MDC };
#else
on stdcore[ETH_CORE]: smi_interface_t smi = { 0, PORT_ETH_RST_N_MDIO, PORT_ETH_MDC };
#endif

on stdcore[ETH_CORE]: clock clk_smi = XS1_CLKBLK_5;







unsigned char packet[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x88, 0xA4,  // Ethercat frame type

    0x38, 0x10,  // 11 bits length, 4 bit protocol (0x1)

    0x01,        // PDU frame

    0x01,        // Command: Auto Increment Physical Read (first PDU, length 28)
    0x5A,        // IDX: master index
    0x00, 0x00,  // ADP: auto increment address
    0x01, 0x01,  // ADO: physical memory address
    0x10, 0x80,  // Length: 16 bytes, not circulated, another PDU to follow
    0x00, 0x00,  // IRQ
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55,
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, // DATA
    0x00, 0x00,  // WKC: working counter.

    0x02,        // Command: Auto Increment Physical Write (second PDU, length 28)
    0x57,        // IDX: master index
    0xFF, 0x01,  // ADP: auto increment address
    0x30, 0x40,  // ADO: physical memory address
    0x10, 0x00,  // Length: 16 bytes, not circulated, last PDU
    0x00, 0x00,  // IRQ
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
    0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, // DATA
    0x00, 0x00,  // WKC: working counter.

    1,2,3,4,5,6,7,8// PADDING FOR TX.
};


static int led0Status = ~0;
static int led1Status = ~0;

#define NAV 100

void handlePacket(int a, int nBytes, int rxTime, int txTime) {
    static int av[NAV];
    static int avc = 0;
    static int avsum;
    static int avwrapped = 0;
    int diff = rxTime - txTime;
    int avg;
    led0Status = ~led0Status;
    led0 <: led0Status;
    avsum -= av[avc];
    av[avc] = diff;
    avsum += diff;
    avc ++;
    if (avc == NAV) {
        avc = 0;
        avwrapped = 1;
    }
    avg = avsum * 1000 / (avwrapped?NAV:avc);
    printf("txTime %10u, rxTime %10u diff %d ns Av %d.%02d ns \n", txTime, rxTime, diff * 10, avg / 100, avg % 100);
#if 0
    for(int i = 0; i < nBytes; i++) {
        int v;
        asm("ld8u %0, %1[%2]" : "=r" (v) : "r" (a), "r" (i));
        printf(" %02x", v);
        if (v != packet[i]) {
            printf(" (%02x)", packet[i]);
        } else {
            printf("     ");
        }
        if ((i & 0x7) == 0x7) {
            printf("\n");
        }
    }
    printf("\n");
#endif
}

void generateEthercat(chanend cIn, chanend cOut, chanend cNotifications) {
    int b[3200];
    struct miiData miiData;
    timer t;
    int timeout;
    int transmitTime;

    led0 <: led0Status;
    led1 <: led1Status;

    miiBufferInit(miiData, cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    t:> timeout;
    timeout += 200000000;
    while (1) {
        select {
        case miiNotified(miiData, cNotifications);
        case t when timerafter(timeout) :> void:
            timeout += 100000000;
            transmitTime = miiOutPacket(cOut, (packet,  int[]), 0, sizeof(packet)-8);
            miiOutPacketDone(cOut);
            led1Status = ~led1Status;
            led1 <: led1Status;
            break;
        }
        while(1) {
            int nBytes, a, timeStamp;
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);
            if (a == 0) {
                break;
            }
            handlePacket(a, nBytes, timeStamp, transmitTime);
            miiFreeInBuffer(miiData, a);
        }
        miiRestartBuffer(miiData);
    } 
}

void ethernetLayer(void) {
    chan cIn, cOut;
    chan notifications;
    miiInitialise(smi.p_smi_mdio, mii);
    smi_port_init(clk_smi, smi);
    eth_phy_config(1, smi);
    par {
        miiDriver(mii, cIn, cOut);
        generateEthercat(cIn, cOut, notifications);
    }
}

int main() {
    par {
        on stdcore[ETH_CORE]: ethernetLayer();
    }
	return 0;
}
