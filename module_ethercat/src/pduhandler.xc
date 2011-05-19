#include <xs1.h>
#include <stdio.h>

void passthrough(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byte;
    while (!stestct(fromRx)) {
        fromRx :> byte; toTx <: byte;
    }
    soutct(toTx, sinct(fromRx));
}

void frameProcess(streaming chanend fromRx, streaming chanend toTx) {
    unsigned char byte, byteL, byteL_, byteH, byteH_, total;
    while (1) {
#pragma loop unroll
        int morePDUs = 1, operate, address, length;
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
        fromRx :> byteL; toTx <: byteL; // total Length
        fromRx :> byteH; toTx <: byteH; // total Length
        total = byteL | (byteH << 8);
        
        fromRx :> byte; toTx <: byte; // frame type
        switch(byte) {
        case 1:  // PDU frame
            do {
                fromRx :> byte; toTx <: byte; // Command
                switch(byte) {
                case 0x02: // APWR
                case 0x01: // APRD
                    fromRx :> byte; toTx <: byte; // IDX
                    fromRx :> byteL;  // Auto Inc address
                    byteL_ = byteL + 1;
                    toTx <: byteL_;
                    fromRx :> byteH;  // Auto Inc address
                    if (byteL_) {
                        byteH_ = byteH + 1;
                    }
                    toTx <: byteH_;
                    operate = (byteL | byteH) == 0;
                    fromRx :> byteL; toTx <: byteL; // ADO, Physical address
                    fromRx :> byteH; toTx <: byteH; // ADO
                    address = byteL | (byteH << 8);
                    fromRx :> byteL; toTx <: byteL; // LEN
                    fromRx :> byteH; toTx <: byteH; // LEN
                    length = byteL | ((byteH << 8) & 0x7);
                    fromRx :> byte; toTx <: byte; // IRQ
                    morePDUs = byteH >> 7;
                    total -= length + 12;
                    fromRx :> byte; toTx <: byte; // IRQ
                    if (operate) {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte;
                            toTx <: (unsigned char) 0x88;
                        }
                        fromRx :> byteL;  // WKC
                        byteL_ = byteL + 1;
                        toTx <: byteL_;
                        fromRx :> byteH;  // WKC
                        if (byteL_) {
                            byteH_ = byteH + 1;
                        }
                        toTx <: byteH_;
                    } else {
                        for(int i = 0; i < length; i++) {
                            fromRx :> byte; toTx <: byte; // DATA
                        }
                        fromRx :> byteL; toTx <: byteL; // WKC
                        fromRx :> byteH; toTx <: byteH; // WKC
                    }
                    break;
                default:
                    printf("Did not see a known command but %02x\n", byte);
                    passthrough(fromRx, toTx);
                    continue;
                }
            } while (morePDUs);
            break;
        default:
            printf("Did not see a PDU frame but %02x\n", byte);
            passthrough(fromRx, toTx);
            break;
        }
        for(int i = 0; i < total; i++) {      // transmit any trailer, but not the CRC.
            fromRx :> byteL; toTx <: byteL;   // WKC
        }
        soutct(toTx, 3);
        fromRx :> int _;                      // gobble up CRC.
        sinct(fromRx);
    }
}
