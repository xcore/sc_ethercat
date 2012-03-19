.globl waitFor
.globl waitFor.nstackwords
.linkset waitFor.nstackwords, 0
.globl waitFor.chanends
.linkset waitFor.chanends, 0
.globl waitFor.timers
.linkset waitFor.timers, 0
    
    .text
    .align 4
waitFor:
    ldw   r11, r0[0]
    bf    r11, waitFor
    retsp 0

.globl assignDestination
.globl assignDestination.nstackwords
.linkset assignDestination.nstackwords, 0
.globl assignDestination.chanends
.linkset assignDestination.chanends, 0
.globl assignDestination.timers
.linkset assignDestination.timers, 0
    
    .text
    .align 4
assignDestination:
    stw   r1, r0[0]
    retsp 0


    .section .dp.bss,"awd",@nobits
    .globl destinationIdentifiers
    .globl destinationIdentifiers_
    .globl destinations
    .globl destinations_
destinationIdentifiers:
destinationIdentifiers_:
    .word 0,0,0,0,0
destinations:
destinations_:
    .word 0,0,0,0,0
