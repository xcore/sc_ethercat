// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include "pduhandler.h"

extern int rx0, rx1;

#define MEM_LENGTH 8192
short memoryWord[MEM_LENGTH/2];

void passthrough(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byte;
    while (!stestct(fromRx)) {
        fromRx :> byte; toTx <: byte;
    }
    soutct(toTx, sinct(fromRx));
    soutct(toTx, 1); 
    schkct(fromRx, 1); 
}

static inline unsigned char passByte(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byte;
    fromRx :> byte; toTx <: byte;
    return byte;
}

static inline int pass16(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byteH, byteL;
    fromRx :> byteL; toTx <: byteL; // ADO, Physical address
    fromRx :> byteH; toTx <: byteH; // ADO
    return byteL | (byteH << 8);
}

static inline int pass32(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byteH, byteL;
    int a;
    fromRx :> byteL; toTx <: byteL;
    fromRx :> byteH; toTx <: byteH;
    a = byteL | (byteH << 8);
    fromRx :> byteH; toTx <: byteH;
    a |= byteH << 16;
    fromRx :> byteH; toTx <: byteH;
    return a | byteH << 24;
}

static inline int passADPinc(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byteH, byteL, byteH_, byteL_;
    fromRx :> byteL;  // Auto Inc address
    byteL_ = byteL + 1;
    toTx <: byteL_;
    fromRx :> byteH;  // Auto Inc address
    if (byteL_ == 0) {
        byteH_ = byteH + 1;
    }
    toTx <: byteH_;
    return (byteL | byteH) == 0;
}

static inline int passADO(streaming chanend fromRx, streaming chanend toTx) {
    return pass16(fromRx, toTx);
}

static inline int passADR(streaming chanend fromRx, streaming chanend toTx) {
    return pass32(fromRx, toTx);
}

static inline int passADP(streaming chanend fromRx, streaming chanend toTx) {
    return pass16(fromRx, toTx);
}

static inline int passTotalLength(streaming chanend fromRx, streaming chanend toTx) {
    return pass16(fromRx, toTx);
}

static inline int passLEN(streaming chanend fromRx, streaming chanend toTx, int &morePDUs) {
    unsigned char byteH, byteL;
    fromRx :> byteL; toTx <: byteL; // LEN
    fromRx :> byteH; toTx <: byteH; // LEN
    morePDUs = byteH >> 7;
    return byteL | (byteH & 0x7 << 8);
}

static inline void passIRQ(streaming chanend fromRx, streaming chanend toTx) {
    passByte(fromRx, toTx);
    passByte(fromRx, toTx);
}

static inline void passWKCinc(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byteH, byteL, byteH_, byteL_;
    fromRx :> byteL;
    byteL_ = byteL + 1;
    toTx <: byteL_;
    fromRx :> byteH;
    if (byteL_ == 0) {
        byteH_ = byteH + 1;
    }
    toTx <: byteH_;
}

static inline void passWKC(streaming chanend fromRx, streaming chanend toTx) {
    passByte(fromRx, toTx);
    passByte(fromRx, toTx);
}

void frameProcess(streaming chanend fromRx, streaming chanend toTx, int &destinationIdentifier, int &destination) {
    unsigned char byte, total, ot2 = 0, ot;
    int cnt = 0;
    int morePDUs, operate, address, length, station;
    asm("add %0, %1, 0" : "=r"(destinationIdentifier) : "r" (fromRx));
    while (1) {
        morePDUs = 1;
        schkct(fromRx, 3);
        asm("setd res[%0],%1" :: "r" (toTx), "r" (destination));
        soutct(toTx, 3);
#pragma loop unroll
        for(int i = 0; i < 12; i++) {
            fromRx :> byte; toTx <: byte;
        }
        fromRx :> byte; toTx <: byte;
        if (byte != 0x88) {
            printf("Got <%02x> not 0x88\n", byte);
            passthrough(fromRx, toTx); continue;
        }
        fromRx :> byte; toTx <: byte;
        if (byte != 0xA4) {
            printf("Got <%02x> not 0xA4\n", byte);
            passthrough(fromRx, toTx); continue;
        }
        total = passTotalLength(fromRx, toTx);
        ot = total;
        fromRx :> byte; toTx <: byte; // frame type
        switch(byte) {
        case 1:  // PDU frame
            do {
                fromRx :> byte; toTx <: byte; // Command
                switch(byte) {
                case 0x01: // APRD
                    passByte(fromRx, toTx);            // IDX
                    operate = passADPinc(fromRx, toTx);   // ADP
                    address = passADO(fromRx, toTx);   // ADO
                    length = passLEN(fromRx, toTx, morePDUs);   // ADO
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte;
                            toTx <: (memoryWord, unsigned char[])[0];//address++];
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x02: // APWR
                    passByte(fromRx, toTx);            // IDX
                    operate = passADPinc(fromRx, toTx);   // ADP
                    address = passADO(fromRx, toTx);   // ADO
                    length = passLEN(fromRx, toTx, morePDUs);   // ADO
                    passIRQ(fromRx, toTx);
                    ot2 = total;
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            /*(memoryWord, unsigned char[])[address++] =*/ passByte(fromRx, toTx);
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x04: // FPRD
                    passByte(fromRx, toTx);            // IDX
                    station = passADP(fromRx, toTx);   // ADP
                    operate = station == memoryWord[0x0010/2];
                    address = passADO(fromRx, toTx);   // ADO
                    operate |= station == memoryWord[0x0012/2];
                    length = passLEN(fromRx, toTx, morePDUs);
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte;
                            toTx <: (memoryWord, unsigned char[])[address++];
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x05: // FPWR
                    passByte(fromRx, toTx);            // IDX
                    station = passADP(fromRx, toTx);   // ADP
                    operate = station == memoryWord[0x0010/2];
                    address = passADO(fromRx, toTx);   // ADO
                    operate |= station == memoryWord[0x0012/2];
                    length = passLEN(fromRx, toTx, morePDUs);
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            (memoryWord, unsigned char[])[address++] = passByte(fromRx, toTx);
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x07: // BRD
                    passByte(fromRx, toTx);            // IDX
                    passADPinc(fromRx, toTx);          // ADP
                    address = passADO(fromRx, toTx);   // ADO
                    length = passLEN(fromRx, toTx, morePDUs);
                    operate = address+length < MEM_LENGTH;
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte;
                            toTx <: (unsigned char) (byte | (memoryWord, unsigned char[])[address++]);
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x08: // BWR
                    passByte(fromRx, toTx);            // IDX
                    passADPinc(fromRx, toTx);   // ADP
                    address = passADO(fromRx, toTx);   // ADO
                    length = passLEN(fromRx, toTx, morePDUs);   // ADO
                    operate = address+length < MEM_LENGTH;
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            (memoryWord, unsigned char[])[address++] = passByte(fromRx, toTx);
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x0A: // LRD
                    passByte(fromRx, toTx);            // IDX
                    address = passADR(fromRx, toTx);   // ADO
                    length = passLEN(fromRx, toTx, morePDUs);
                    operate = 1; /* TO BE DECIDED */
                    passIRQ(fromRx, toTx);
                    total -= length + 12;
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte;
                            toTx <: (memoryWord, unsigned char[])[address++];
                        }
                        passWKCinc(fromRx, toTx);
                    } else {
                        for(int i = 0; i < length; i++) {
                            passByte(fromRx, toTx);
                        }
                        passWKC(fromRx, toTx);
                    }
                    break;
                case 0x0B: // LWR
                    break;
                default:
                    printf("Did not see a known command but %02x\n", byte);
                    passthrough(fromRx, toTx);
                    break;
                }
            } while (morePDUs);
            break;
        default:
            printf("Did not see a PDU frame but %02x\n", byte);
            passthrough(fromRx, toTx);
            break;
        }
/*        printintln(ot);
        printintln(ot2);
        printintln(total);
                    printhexln(address);
                    printintln(operate);*/
        for(int i = 0; i < total; i++) {      // transmit any trailer, but not the CRC.
            passByte(fromRx, toTx);
        }
        fromRx :> int _;                      // gobble up CRC.
        soutct(toTx, sinct(fromRx));
        soutct(toTx, 1); 
        schkct(fromRx, 1); 
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (cnt));
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (total));
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (address));
    }
}
