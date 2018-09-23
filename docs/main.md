# Atmosphère
Atmosphère is a work-in-progress customized firmware for the Nintendo Switch. Atmosphère consists of several different components, each in charge of performing different system functions of the Nintendo Switch.

The components of Atmosphère are:
+ [Fusée](../docs/components/fusee.md), a custom bootloader.
+ [Exosphère](../docs/components/exosphere.md), a fully-featured custom secure monitor.
+ [Stratosphère](../docs/components/stratosphere.md), a set of custom system modules
+ [Troposphère](../docs/components/troposphere.md), Application-level patches to the Horizon OS. This has not been implemented yet.
+ [Thermosphère](../docs/components/thermosphere.md), a hypervisor-based emuNAND implementation.

### Modules
Atmosphère also includes some modules. These have a `.kip` extension. They provide custom features, extend existing features, or replace Nintendo sysmodules.

Atmosphère's modules include:
+ [boot](../docs/modules/boot.md)
+ [creport](../docs/modules/creport.md)
+ [fs_mitm](../docs/modules/fs_mitm.md)
+ [loader](../docs/modules/loader.md)
+ [pm](../docs/modules/pm.md)
+ [sm](../docs/modules/sm.md)

### Building Atmosphère
A guide to building Atmosphère can be found [here](../docs/building.md).

### Release Roadmap
A roadmap of the releases of Atmosphère can be found [here](../docs/roadmap.md).
