#include <frame.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>

void rxProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toProtocol) {
    const register unsigned poly = 0xEDB88320;
    while (1) {
        int clockCounter, running = 1, bits;
        unsigned crc = 0x9226F562;
        rxPort when pinseq(0xB) :> void @ clockCounter;
        toProtocol <: clockCounter;
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
    }
}

void txProcess(buffered out port:8 txPort, streaming chanend fromProtocol) {
    register const unsigned poly = 0xEDB88320;  
    while(1) {
        int clockCounter;
        unsigned int bytesLeft, outputWord;
        unsigned char outputChar;
        unsigned crc = ~0, incomingCrc;
        fromProtocol :> clockCounter;
        txPort @ (clockCounter + 5) <: 0x55;
#pragma loop unroll
        for(int i = 0; i < 4; i++) {
            txPort <: 0x55;
        }
        fromProtocol :> outputChar;
        crc8shr(crc, outputChar, poly);      
        txPort <: 0xB5;
        while(!stestct(fromProtocol)) {
            txPort <: outputChar;
            fromProtocol :> outputChar;
            crc8shr(crc, outputChar, poly);      
        }
        txPort <: outputChar;
        crc32(crc, 0, poly);
        crc = ~crc;
        txPort <: >> crc;
        txPort <: >> crc;
        incomingCrc = sinct(fromProtocol);
        txPort <: >> crc;
        crc ^= incomingCrc<<6;
        txPort <: >> crc;
    }
}
