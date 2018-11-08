# wireguard salt state
These states currently only support Debian-based machines.

This was manually tested on:
- Raspbian GNU/Linux 9 (stretch) on a Raspberry PI 3

## Example pillar data
```yaml
wireguard:
  self_config:
    address: 10.0.0.1/24
    private_key: "your private key here"
    listen_port: 12345
  peers:
    other_host:
      public_key: "your public key here"
      endpoint: yourotherhost.com:12345
      allowed_ips: 10.0.0.2/32
      # Use this if the endpoint is a dynamic DNS name.
      # This will refresh the peer's endpoint every minute.
      refresh_endpoint: True
```

## Generating private keys
```bash
mkdir -p ~/.wg && touch ~/.wg/private && chmod 660 ~/.wg/private && wg genkey > ~/.wg/private
```

## Getting the public key
```bash
wg pubkey < ~/.wg/private
```