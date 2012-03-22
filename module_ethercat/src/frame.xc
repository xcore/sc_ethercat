// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <frame.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>

extern int rx0, rx1;

void rx0Process(in port rxActive, buffered in port:8 rxPort, streaming chanend toProtocol) {
    const register unsigned poly = 0xEDB88320;
    int cnt = 0;
    while (1) {
        int clockCounter, running = 1, bits;
        unsigned crc = 0x9226F562;
        rxPort when pinseq(0xD) :> void;
        soutct(toProtocol, 3);
        while(running) {
            char inputWord;
            select {
            case rxPort :> inputWord:
                toProtocol <: inputWord;
                crc8shr(crc, inputWord, poly);
                break;
            case rxActive when pinseq(0) :> void:
                soutct(toProtocol, ~crc ? 0xF : 0); 
                running = 0;
                break;
            }
        }
        soutct(toProtocol, 1); 
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (cnt));
    }
}

void rxNProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toProtocol) {
    const register unsigned poly = 0xEDB88320;
    int cnt = 0;
    while (1) {
        int clockCounter, running = 1, bits, txChannelEnd;
        unsigned crc = 0x9226F562;
        rxPort when pinseq(0xD) :> void;
//        asm("ldw %0, dp[rx1]" : "=r" (txChannelEnd));
//        asm("setd res[%0],%1" :: "r" (toProtocol), "r" (txChannelEnd));
        soutct(toProtocol, 3);
        while(running) {
            char inputWord;
            select {
            case rxPort :> inputWord:
                toProtocol <: inputWord;
                crc8shr(crc, inputWord, poly);
                break;
            case rxActive when pinseq(0) :> void:
                soutct(toProtocol, ~crc ? 0xF : 0); 
                running = 0;
                break;
            }
        }
        soutct(toProtocol, 1); 
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (cnt));
    }
}

void txProcess(buffered out port:8 txPort, streaming chanend fromProtocol) {
    register const unsigned poly = 0xEDB88320;
    int cnt = 0;
    while(1) {
        int clockCounter;
        unsigned int bytesLeft, outputWord;
        unsigned char outputChar;
        unsigned crc = 0x9226F562, incomingCrc;
        int keepExistingCRC;
        keepExistingCRC = sinct(fromProtocol);
        txPort <: 0x55;
#pragma loop unroll
        for(int i = 0; i < 6; i++) {
            txPort <: 0x55;
        }
        fromProtocol :> outputChar;
        crc8shr(crc, outputChar, poly);      
        txPort <: 0xD5;
        while(!stestct(fromProtocol)) {
            txPort <: outputChar;
            fromProtocol :> outputChar;
            crc8shr(crc, outputChar, poly);      
        }
        txPort <: outputChar;
        if (keepExistingCRC) {
            sinct(fromProtocol);
        } else {
            crc32(crc, keepExistingCRC, poly);
            crc = ~crc;
            txPort <: >> crc;
            txPort <: >> crc;
            incomingCrc = sinct(fromProtocol);
            txPort <: >> crc;
            crc ^= incomingCrc<<6;
            txPort <: >> crc;
        }
        schkct(fromProtocol, 1);
        asm("add %0, %1, 1" : "=r"(cnt) : "r" (cnt));
    }
}
