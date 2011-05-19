#include <frame.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>

void rxProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toTx, streaming chanend toProtocol) {
    const register unsigned poly = 0xEDB88320;
    while (1) {
        int clockCounter, running = 1, bits;
        unsigned crc = 0x9226F562;
        rxPort when pinseq(0xB) :> void @ clockCounter;
        toTx <: clockCounter;
        while(running) {
            char inputWord;
            select {
            case rxPort :> inputWord:
                toProtocol <: inputWord;
                crc8shr(crc, inputWord, poly);
                break;
            case rxActive when pinseq(0) :> void:
                soutct(toProtocol, 3); 
                toTx <: ~crc ? 0x0FFFFFFF : 0xFFFFFFFF;
                running = 0;
                break;
            }
        }
    }
}

void txProcess(buffered out port:32 txPort, streaming chanend fromRx, streaming chanend fromProtocol) {
    register const unsigned poly = 0xEDB88320;  
    while(1) {
        int clockCounter;
        unsigned int bytesLeft, outputWord;
        unsigned char outputChar;
        unsigned crc = ~0, incomingCrc;
        fromRx :> clockCounter;
        txPort @ (clockCounter + 9) <: 0x55555555;
        txPort <: 0xB5555555;
        while(!stestct(fromProtocol)) {
            fromProtocol :> outputChar;
            crc8shr(crc, outputChar, poly);      
            txPort:8 <: outputChar;
        }
        crc32(crc, 0, poly);
        fromRx :> incomingCrc;
        txPort <: (crc^incomingCrc);
        sinct(fromProtocol);
    }
}
