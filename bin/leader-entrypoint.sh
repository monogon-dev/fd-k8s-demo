#!/usr/bin/env bash
set -euo pipefail

if ! grep -Fq /sys/fs/bpf /proc/mounts; then
  echo "Mounting /sys/fs/bpf"
  mkdir -p /sys/fs/bpf
  mount -t bpf none /sys/fs/bpf
fi

# Workaround for https://github.com/firedancer-io/firedancer/issues/2575
! ip addr add $(hostname -i)/32 dev lo

# Initialize Firedancer.
fddev configure init all --config /etc/leader.toml

# Run Firedancer.
fddev --no-configure --config /etc/leader.toml
