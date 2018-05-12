#!/bin/sh

# cmd + R at boottime
sudo csrutil disable # <-- only works from recovery mode!!!

# then, after reboot:
mkdir -p $HOME/Documents/WebCamBackupFile/
sudo mv /System/Library/QuickTime/QuickTimeUSBVDCDigitizer.component $HOME/Documents/WebCamBackupFile/
