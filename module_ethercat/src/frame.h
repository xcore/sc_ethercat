// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** Function that receives data on the master port. Only frames arriving on
 * this port are interpreted. This function reads byte from the input port
 * (guarded by the datavalid port), and outputs them on the channel. The
 * data stream is terminated with a control token, either token 15 (CRC
 * error), or token 0 (CRC good).
 *
 * \param dataValid port that signals whether rxData contains valid data.
 *
 * \param rxData port on which data arrives, must be byte buffered
 *
 * \param toProtocol channel end on which packet is transmitted
 */
void rx0Process(in port dataValid,
                buffered in port:8 rxData,
                streaming chanend toProtocol);

/** Function that receives data on a non master port. This function reads
 * byte from the input port (guarded by the datavalid port), and outputs
 * them on the channel, ready to be output immediately on the next port.
 * The data stream is terminated with a control token, either token 15 (CRC
 * error), or token 0 (CRC good).
 *
 * When data arrives on this port, the function reads a channel end from
 * the global variable rx1, and it uses this as a destination channel-end
 * for the packet. This allows packets to be routed dynamically.
 *
 * \param dataValid port that signals whether rxData contains valid data.
 *
 * \param rxData port on which data arrives, must be byte buffered
 *
 * \param toProtocol channel end on which packet is transmitted
 */
void rxNProcess(in port dataValid,
                buffered in port:8 rxData,
                streaming chanend toProtocol);

/** Function that transmits data on an mii port. This function reads bytes
 * from an input channel, and outputs them one byte at a time. Data should
 * arrive fast enough to prevent a gap in the packet. Prior to anything
 * else, this function writes its channel-end into the destinationChannel
 * variable, enabling dynamic routing.
 *
 * \param txData             port on which data is transmitted,
 *                           must be byte buffered.
 *
 * \param fromProtocol       channel on which data arrives
 *
 * \param destinationChannel variable into which the channel end is
 *                           written. Can be used for dynamic routing.
 */
void txProcess(buffered out port:8 txData,
               streaming chanend fromProtocol,
               int &destinationChannel);



/** Function that receives data on the master port. Only frames arriving on
 * this port are interpreted. This function reads byte from the input port
 * (guarded by the datavalid port), and outputs them on the channel. The
 * data stream is terminated with a control token, either token 15 (CRC
 * error), or token 0 (CRC good), followed by an END control token
 *
 * \param dataValid          port that signals whether rxData contains valid data.
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
