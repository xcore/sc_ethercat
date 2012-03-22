// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** Structure containing all the ports of an MII PHY.
 */
typedef struct mii_ethercat_ports {
    clock clk_mii_rx;              /**< RX Clock Block **/
    clock clk_mii_tx;              /**< TX Clock Block **/
    
    port p_mii_rxclk;              /**< MII RX clock wire */
    in buffered port:8 p_mii_rxd;  /**< MII RX data wire */
    in port p_mii_rxdv;            /**< MII RX data valid wire */
    
    port p_mii_txclk;              /**< MII TX clock wire */
    out buffered port:8 p_mii_txd; /**< MII TX data wire */
    out port p_mii_txen;           /**< MII TX enable wire */
} mii_ethercat_ports;

/** Function that initialises the ports and clockblocks that control the
 * PHY. This needs to be called once for each PHY.
 *
 * \param m port structure.
 */
void ethercat_port_init(mii_ethercat_ports &m);
