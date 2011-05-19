// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "xsidevice.h"
#include <assert.h>
#include <stdio.h>

void *xsim = 0;

unsigned char packet[] = {
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0xB5,
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
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, // DATA
    0x00, 0x00,  // WKC: working counter.

    0x02,        // Command: Auto Increment Physical Write (second PDU, length 28)
    0x57,        // IDX: master index
    0xFF, 0x01,  // ADP: auto increment address
    0x30, 0x40,  // ADO: physical memory address
    0x10, 0x00,  // Length: 16 bytes, not circulated, last PDU
    0x00, 0x00,  // IRQ
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, // DATA
    0x00, 0x00,  // WKC: working counter.

    0x00, 0x01, 0x02, 0x03,  // Ethernet CRC
};

int main(int argc, char **argv) {
    int time = 0, clock = 0, cnt = 0, even = 0, oldready = 0, startTime = 0;
    XsiStatus status = xsi_create(&xsim, argv[1]);
    assert(status == XSI_STATUS_OK);
    while (status != XSI_STATUS_DONE && time < 1000000) {
        time++;
        if(time % 20 == 3) {
            clock = !clock;
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1A", 1, clock);
            if (clock == 1)  {
                if (time > 100000) {
                    if (cnt < sizeof(packet)) {
                        if (cnt == 0 && !even) {
                            startTime = time;
                        }
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, 1);
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_4A", 0xF, 
                                            even ? packet[cnt] >> 4 : packet[cnt]);
                        if (even) {
                            cnt++;
                        }
                        even = !even;
                    } else {
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, 0);
                    }
                }
            }
        }
        if(time % 20 == 4) {
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1C", 1, clock);
            if (clock == 0) {
                unsigned ready;
                xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1D", 1, &ready);
                if (ready) {
                    unsigned nibble;
                    if (!oldready) {
                        printf("%d ns delay <", time - startTime);
                        oldready = 1;
                    }
                    xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_4B", 0xF, &nibble);
                    printf("%01x", nibble);
                } else {
                    if (oldready) {
                        printf(">\n", time);
                        oldready = 0;
                    }
                }
            }
        }
        if(time % 5 == 0 || time % 3 == 0) {
            status = xsi_clock(xsim);
            assert(status == XSI_STATUS_OK || status == XSI_STATUS_DONE );
        }
    }
    status = xsi_terminate(xsim);
    return 0;
}
