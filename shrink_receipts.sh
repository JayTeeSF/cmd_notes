#!/bin/bash

# goto where expense receipt images are (i.e. jpg files)
# cd ~/Documents/ExpenseReports/jan-feb
# $0

for f in *.*; do convert $f -quality 50 "sm_${f}"; done
