// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** Function that processes all frames. Frames are streamed in over fromRx
 * and streamed out over toTx. The data streams are opened with control
 * token 3 and terminated with two control tokens. One control token to
 * signal the CRC status (15: CRC error, 0: CRC good), and an END token.
 *
 * \param fromRx stream into the process, comes from rxProcessS()
 *
 * \param toTx stream into the process, goes to txProcess()
 *
 * \param destination channel end where to send to.
 *
 * \param memory array of words that contains the Ethercat memory.
 */
void frameProcess(streaming chanend fromRx, streaming chanend toTx,
                  int &destination, short memory[]);
