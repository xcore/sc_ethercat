void rxProcess(port rxActive, buffered port:32 rxPort, streaming chanend toTx, streaming chanend toProtocol) {
    while (1) {
        int clockCounter, running = 1;
        rxPort when pinseq(0xB) @ clockCounter :> void;
        toTx <: clockCounter;
        while(running) {
            int inputWord;
            select {
            case rxPort :> inputWord:
                toProtocol <: inputWord;
                break;
            case rxActive when pinseq(0) :> void:
                running = 0;
                break;
            }
        }
        soutct(toProtocol, 3); 
    }
}

void txProcess(buffered port:32 txPort, streaming chanend fromRx, streaming chanend fromProtocol) {
    while(1) {
        int clockCounter;
        fromRx :> clockCounter;
        txPort @ (clockCounter + 9) <: 0x55555555;
        txPort <: 0x5555555B;
        while ( (bytesLeft = stestwct(fromProtocol)) != 0) {
            fromProtocol :> outputWord;
            txPort <: outputWord;
        }
        switch(bytesLeft) {
        case 2:
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            break;
        case 3:
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            break;
        case 4:
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            fromProtocol :> outputChar;
            txPort:8 <: outputChar;
            break;
        case 1:
            break;
        }
    }
}
