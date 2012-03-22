Ethercat
........

:Stable release:  unreleased

:Status:  idea

:Maintainer:  https://github.com/henkmuller

:Description:  Feasibility study for EtherCAT


Key Features
============

* Ethercat test-harness to run on XC-2

* Ethercat slave to run on XC-3

* Low latency MII Rx and Tx

* Rudimentary EtherCAT protocol handler

* Current latency of 800ns, but memory access has not been implemented yet
  (PHY latency adds 400 ns). Return path latency approximately 640 ns
  (preamble) + 400 ns (PHY) + 160 ns (processing)

To Do
=====

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

* Each packets that flows back gets an extra CRC (!)
* app_ethercat_test won't build (and is deprecated)

Required Repositories
=====================

* sc_ethernet git\@github.com:xcore/sc_ethernet.git  (SMI module)
* xcommon git\@github.com:xcore/xcommon.git  (build system)
* xdoc git\@github.com:xcore/xdoc.git  (documentation)

Support
=======

<Description of support model>
