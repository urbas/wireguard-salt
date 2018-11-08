# wireguard salt state
These states currently only support Debian-based machines.

This was manually tested on:
- Raspbian GNU/Linux 9 (stretch) on a Raspberry PI 3

## Generating private keys
```bash
mkdir -p ~/.wg && touch ~/.wg/private && chmod 660 ~/.wg/private && wg genkey > ~/.wg/private
```

## Getting the public key
```bash
wg pubkey < ~/.wg/private
```