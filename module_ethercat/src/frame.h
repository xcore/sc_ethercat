// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

void rxProcess(in port rxActive, buffered in port:8 rxPort, streaming chanend toProtocol);
void txProcess(buffered out port:8 txPort, streaming chanend fromProtocol);

