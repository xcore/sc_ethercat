#include <xs1.h>
    
.globl rxProcessS
.globl rxProcessS.nstackwords
.linkset rxProcessS.nstackwords, 0
.globl rxProcessS.chanends
.linkset rxProcessS.chanends, 0
.globl rxProcessS.timers
.linkset rxProcessS.timers, 0

    // r0: dataValid
    // r1: rxData
    // r2: toProtocol
    // r3: &destinationChanend
    // r4: poly
    // r5: CRC
    // r6: 0xFFFFFFFF (correct CRC)
    // r7: Table with two control tokens
    // r11: temp

    .section .cp.const4 ,"acM", @progbits, 4
    .align 4
polynomial:
    .word 0xEDB88320
initialCRC:
    .word 0x9226F562
controlTokenTable:
    .byte 0x0F, 0, 0, 0
    
    .text
    .align 4
rxProcessS:
    getd r11, res[r2]                // Initialise default destination
    stw  r11, r3[0]                  // To current destination
    
    ldw  r4, cp[polynomial]          // r4 is constant - loaded once.

    ldap r11, dataValidVector        // Set up dataValid resource
    setv res[r0], r11                // Point vector to entry point
    ldc  r11, 0                      // Set condition data to 0
    setd res[r0], r11                // Set condition itself to
    setc res[r0], XS1_SETC_COND_EQ   // EQ: when pinseq(0)

    ldap r11, rxdVector              // Set up data port resource
    setv res[r1], r11                // Point vector to entry point
    ldc  r11, 0xD                    // Set condition data to 0xD
    setd res[r1], r11                // Set condition delayed to inside loop

    ldaw r11, cp[controlTokenTable]  // Set r7 to point to array with two control
    or   r7, r11, r11
    mkmsk r6, 32                     // tokens, and set r6 to contain correct CRC.
    
loop:
    clre
    ldw  r5, cp[initialCRC]          // Initialise the CRC to magic pattern
    setc res[r1], XS1_SETC_COND_EQ   // Set condition to test on pinseq(0xD)
    in   r11, res[r1]                // Wait for the 0xD to arrive.
    ldw  r11, r3[0]                  // Load the direction for this packet
    setd res[r2], r11                // Set packet to go there.
    outct res[r2], 3                 // Send packet start
    eeu  res[r0]                     // Enable events on both resources
    eeu  res[r1]                     // And wait for byte on first one.

rxdVector:
    in   r11, res[r1]                  // Read byte from port
    outt res[r2], r11                // Send it to destination (protocol or port)
    crc8 r5, r11, r11, r4            // Incorporate into CRC
    waiteu                           // Wait for next byte or datavalid.
    
dataValidVector:
    in   r11, res[r0]                  // Data valid has disappeared, read it.
    eq   r5, r5, r6                    // Test if CRC is 0xFFFFFFFF, use result
    ld8u r5, r7[r5]                  // to read appropriate control-token
    outct res[r2], r5                 // And send control token out.
    outct res[r2], 1                 // And terminate stream.
    bu loop
