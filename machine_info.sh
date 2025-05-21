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

# Prefer timeout/gtimeout if available
timeout_cmd=""
if command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout"
fi

# Check for setsid which allows killing the whole process group
setsid_cmd=""
if command -v setsid >/dev/null 2>&1; then
    setsid_cmd="setsid"
fi

if [ -n "$timeout_cmd" ]; then
    if [ -n "$setsid_cmd" ]; then
        echo "Using $timeout_cmd with $setsid_cmd for system_profiler"
        $timeout_cmd 10 $setsid_cmd system_profiler SPDisplaysDataType || echo "Failed or timeout retrieving display info"
    else
        echo "setsid not found; running system_profiler without it"
        $timeout_cmd 10 system_profiler SPDisplaysDataType || echo "Failed or timeout retrieving display info"
    fi
else
    echo "timeout not available; running manual background kill logic"
    if [ -n "$setsid_cmd" ]; then
        $setsid_cmd system_profiler SPDisplaysDataType &
    else
        system_profiler SPDisplaysDataType &
    fi
    sp_pid=$!
    {
        sleep 10
        if kill -0 $sp_pid >/dev/null 2>&1; then
            echo "Manually killing hanging system_profiler (pid $sp_pid)"
            kill -9 $sp_pid >/dev/null 2>&1
        fi
    } &
    wait $sp_pid 2>/dev/null || true
fi
echo ""
echo "------------------------"
