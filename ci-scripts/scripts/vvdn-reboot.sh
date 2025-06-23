#!/bin/sh
# SPDX-License-Identifier: MIT

set -e

RU_IP="10.10.0.111"
RU_HOST="root@10.10.0.111"
SETUP_SCRIPT="/home/root/disabled-mplane/setup-ru-4x4-100-no-mplane.sh"

ssh_exec() {
    ssh $RU_HOST $@ </dev/null
}

echo "→ Rebooting VVDN LPRU..."
ssh_exec 'reboot'

sleep 60

echo "→ Waiting for $RU_IP SSH port 22 to be open..."
while ! nc -zv $RU_IP 22 >/dev/null 2>&1; do
    echo "SSH port 22 not open, waiting 5 seconds..."
    sleep 5
done
echo "✓ SSH port 22 is open on $RU_IP"

echo "→ Checking if VVDN LPRU is PTP synchronized (timeout 5 min)..."

if ssh_exec 'timeout 5m sh -c '\''tail -F /var/log/synctimingptp2.log | grep -m 1 -F ", synchronized"'\'''; then
    echo "✓ VVDN LPRU synchronized"
else
    echo "✗ VVDN LPRU not synchronized in 5 min"
    sleep infinity
fi
sleep 20

echo "→ Running configuration script $SETUP_SCRIPT on RU..."
ssh_exec $SETUP_SCRIPT >/dev/null
