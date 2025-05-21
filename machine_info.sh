#!/usr/bin/env bash

echo "### System Information ###"
echo ""

# Public IP Address
echo "Public IP Address:"
curl -s --max-time 10 ifconfig.me
echo ""
echo "------------------------"

# Hardware UUID
echo "Hardware UUID:"
system_profiler SPHardwareDataType | grep "Hardware UUID"
echo ""
echo "------------------------"

# Serial Number
echo "Serial Number:"
system_profiler SPHardwareDataType | grep "Serial Number"
echo ""
echo "------------------------"

# MAC Address (en0)
echo "MAC Address (en0):"
ifconfig en0 | grep ether
echo ""
echo "------------------------"

# Boot Session UUID
echo "Boot Session UUID:"
sysctl kern.bootsessionuuid
echo ""
echo "------------------------"

# Model Identifier
echo "Model Identifier:"
system_profiler SPHardwareDataType | grep "Model Identifier"
echo ""
echo "------------------------"

# Volume UUID
echo "Volume UUID:"
diskutil info / | grep "Volume UUID"
echo ""
echo "------------------------"

# OS Version
echo "Operating System Version:"
sw_vers
echo ""
echo "------------------------"

# Display Information
echo "Display Information:"
system_profiler SPDisplaysDataType
echo ""
echo "------------------------"