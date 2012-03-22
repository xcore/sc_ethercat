// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


/** Function that transmits data on an mii port. This function reads bytes
 * from an input channel, and outputs them one byte at a time. Data should
 * arrive fast enough to prevent a gap in the packet.
 *
 * The first token is a control token: a zero control token indicates that
 * the transmitter should append a CRC; a non-zero control token indicates
 * that a valid CRC is included at the end of the message. After the
 * initial control token, a stream of data bytes are expected on the
 * channel, terminated by a control token. The terminating token is either
 * 0 or 0xF depending on whether the CRC on the incoming packet was valid
 * or not. If the TX function was asked to add a valid CRC, *and* the
 * incoming CRC was deemed invalid, then it will knacker the outgoing CRC
 * too. Just to be consistent. Finally a '1' control token is read closing
 * the stream.
 *
 * \param txData             port on which data is transmitted,
 *                           must be byte buffered.
 *
 * \param fromProtocol       channel on which data arrives
 */
void txProcess(buffered out port:8 txData,
               streaming chanend fromProtocol);



/** Function that receives data on the master port. Only frames arriving on
 * this port are interpreted. This function reads byte from the input port
 * (guarded by the datavalid port), and outputs them on the channel. The
 * data stream is opened with control token 3 (indicating that a valid CRC
 * will eb transmitted at the end of the stream) and terminated with two
 * control tokens. One control token to signal the CRC status (15: CRC
 * error, 0: CRC good), and an END token.
 *
 * \param dataValid          port that signals whether rxData contains
 *                           valid data.
 *
 * \param rxData             port on which data arrives, must be byte buffered
 *
 * \param toProtocol         channel end on which packet is transmitted
 *
 * \param destinationChannel channelend to use as destination - can be
 *                           modified on the fly
 */
void rxProcessS(in port dataValid,
                buffered in port:8 rxData,
                streaming chanend toProtocol,
                int &destinationChannel);
