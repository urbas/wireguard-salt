# wireguard salt formula
Downloads Wireguard, compiles it from sources, installs it on the machine, configures Wireguard interfaces,
and turns the interfaces on.

This salt formula can also refresh your peers periodically. This is useful if your peers have dynamic DNS names.

Supported architectures (manually tested):
- Ubuntu 18.04 (Bionic Beaver) on x86_64
- Raspbian GNU/Linux 9 (stretch) on a Raspberry PI 3

## Example pillar data
```yaml
wireguard:
  interfaces:
    wg0:
      disabled: False # Optional (default is False): If set to true, the interface will be shut down.
                      # All files will remain in place. This means you can start the interface manually
                      # yourself with:
                      #   sudo systemctl start wg-quick@wg0
      conf: # The content of this dictionary goes into the [Interface] section of the /etc/wireguard/wg0.conf file
        Address: 10.0.0.1/24
        PrivateKey: "your private key here"
        ListenPort: 12345
      peers:
        other_host:
          refresh_endpoint: False # Optional (default is False): Use this if the endpoint is a dynamic DNS name.
                                  # This will refresh the peer's endpoint every minute.
          conf: # The content of this dictionary goes into [Peer] sections of the /etc/wireguard/wg0.conf file
            PublicKey: "your public key here"
            Endpoint: yourotherhost.com:12345
            AllowedIPs: 10.0.0.2/32
```

## Generating private keys
```bash
mkdir -p ~/.wg && touch ~/.wg/private && chmod 660 ~/.wg/private && wg genkey > ~/.wg/private
```

## Getting the public key
```bash
wg pubkey < ~/.wg/private
```