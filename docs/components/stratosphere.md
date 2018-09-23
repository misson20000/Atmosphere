# Stratosphère
Stratosphère allows customization of the Horizon OS and Switch kernel. It includes custom sysmodules that extend the kernel and provide new features. It also includes a reimplementation of the loader to hook important system actions.

The sysmodules that Stratosphère includes are:
+ boot: This module boots the system and launches other processes.
+ creport: Reimplementation of Nintendo’s crash report system. Dumps all error logs to the SD card instead of saving them to the NAND and sending them to Nintendo.
+ fs_mitm: This module can log, deny, delay, replace, and redirect any request made to the File System.
+ loader: Enables modifying the code of binaries that are not stored inside the kernel.
+ pm: Reimplementation of Nintendo’s Process Manager.
+ sm: Reimplementation of Nintendo’s Service Manager.
