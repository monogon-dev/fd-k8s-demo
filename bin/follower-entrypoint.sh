#!/usr/bin/env bash
set -euo pipefail

if ! grep -Fq /sys/fs/bpf /proc/mounts; then
  echo "Mounting /sys/fs/bpf"
  mkdir -p /sys/fs/bpf
  mount -t bpf none /sys/fs/bpf
fi

# Copy over stuff from leader
mkdir -p /scratch/cluster
while ! curl -o /scratch/cluster/faucet.json http://leader:10801/fd1/faucet.json; do
  echo "Failed to download faucet.json, retrying..."
  sleep 1
done

# Fund identity
if ! [[ -f /scratch/cluster/id.json ]]; then
  echo "Creating identity..."
  solana-keygen new --no-bip39-passphrase -o /scratch/cluster/id.json
fi

chown -R 1000:1000 /scratch/cluster

echo "Funding identity..."
solana -u http://leader:8899 transfer -k /scratch/cluster/faucet.json \
  --allow-unfunded-recipient /scratch/cluster/id.json 10

# Initialize Firedancer.
fddev configure init all --config /etc/follower.toml

# Run Firedancer.
fddev run --config /etc/follower.toml
