# OpenStack Workstation (Optional)

Provision a VM that mimics the CKA exam workstation, with preinstalled tooling and optional egress restrictions.

## Suggested Flavor
- 2 vCPU, 4 GB RAM, 20 GB disk
- Ubuntu 22.04

## Bootstrap Script
Install required tools:
```bash
sudo apt update && sudo apt install -y curl git python3 jq
# Install kubectl
curl -fsSL https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o kubectl
sudo install kubectl /usr/local/bin/kubectl
# Install kind
curl -fsSL https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 -o kind
sudo install kind /usr/local/bin/kind
```

## Optional: Sandbox Egress
Restrict outbound traffic (except to a mirror/allowed list) to mimic exam constraints.

Example: allow only RFC1918 networks and block all other egress:
```bash
# WARNING: This affects VM networking. Use with care.
sudo iptables -P OUTPUT DROP
# Allow loopback
sudo iptables -A OUTPUT -o lo -j ACCEPT
# Allow established
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Allow RFC1918
for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
  sudo iptables -A OUTPUT -d $net -j ACCEPT
done
```

Revert:
```bash
sudo iptables -F OUTPUT
sudo iptables -P OUTPUT ACCEPT
```
