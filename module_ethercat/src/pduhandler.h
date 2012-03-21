// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** Function that processes all frames. Frames are streamed in over fromRx
 * and streamed out over toTx.
 */
void frameProcess(streaming chanend fromRx, streaming chanend toTx, int &destination, short memory[]);
