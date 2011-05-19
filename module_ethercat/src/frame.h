void rxProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toProtocol);
void txProcess(buffered out port:8 txPort, streaming chanend fromProtocol);

