#!/bin/bash
#This script is a fast demo to see the leds flashing on the RedCape VA2
cd /DEMO/FPGA/jrunner/
##
chmod +x jrunner
./jrunner redcape2_test.cdf
cd ~
echo Flashing LEDs DEMO - Use the PushButtons to control the DEMO
