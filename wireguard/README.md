# wireguard salt state
Downloads Wireguard, compiles it from sources, installs it on the machine, configures Wireguard interfaces,
and turns the interfaces on.

These states can also refresh your peers periodically. This is useful if your peers have dynamic DNS names.

Supported architectures (manually tested):
- Raspbian GNU/Linux 9 (stretch) on a Raspberry PI 3

## Example pillar data
```yaml
wireguard:
  interfaces:
    vpn:
      address: 10.0.0.1/24
      private_key: "your private key here"
      listen_port: 12345
      disabled: False # This will remove the interface and disable all associated services
      peers:
        other_host:
          public_key: "your public key here"
          endpoint: yourotherhost.com:12345
          allowed_ips: 10.0.0.2/32
          refresh_endpoint: True # Use this if the endpoint is a dynamic DNS name. This will refresh the peer's endpoint every minute.
```

## Generating private keys
```bash
mkdir -p ~/.wg && touch ~/.wg/private && chmod 660 ~/.wg/private && wg genkey > ~/.wg/private
```

## Getting the public key
```bash
wg pubkey < ~/.wg/private
```