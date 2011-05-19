void rxProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toTx, streaming chanend toProtocol);
void txProcess(buffered out port:32 txPort, streaming chanend fromRx, streaming chanend fromProtocol);

