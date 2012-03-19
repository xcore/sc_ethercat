Ethercat
........

:Stable release:  unreleased

:Status:  idea

:Maintainer:  https://github.com/henkmuller

:Description:  Feasibility study for EtherCAT


Key Features
============

* Ethercat test-harness to run on XC-2
* Low latency MII Rx and Tx
* Rudimentary EtherCAT protocol handler
* Current latency of 600ns, but memory access has not been implemented yet.

To Do
=====

* Auto detection of ports
* Multiple ports
* Port forwarding
* Mailbox protocol
* Network variable protocol
* Memory interface.

Firmware Overview
=================

The module and applicatons in this repo are a feasibility study on coding
an EtherCAT slave on an XS1 device. The target is either an L2 or a G4,
depending on whether fast threads are required (> 100 MIPS requires an L2)
and on whether a fast switch is required (the G4 switch is very low
latency).

Known Issues
============

* <Bullet pointed list of problems>

Required Repositories
=====================

* xcommon git\@github.com:xcore/xcommon.git

Support
=======

<Description of support model>
