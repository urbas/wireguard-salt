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

# Troubleshooting

## I want to forward all internet traffic coming from a Wireguard VPN through my server
You must add these `PostUp` and `PostDown` forwarding iptables rules to the `conf` section of your VPN:
```yaml
PostUp: iptables -A FORWARD -i <my-wg-vpn-name> -j ACCEPT; iptables -A FORWARD -o <my-wg-vpn-name> -j ACCEPT; iptables -t nat -A POSTROUTING -o <forwarding inteface> -j MASQUERADE
PostDown: iptables -D FORWARD -i <my-wg-vpn-name> -j ACCEPT; iptables -D FORWARD -o <my-wg-vpn-name> -j ACCEPT; iptables -t nat -D POSTROUTING -o <forwarding inteface> -j MASQUERADE
```

Complete example:
```yaml
wireguard:
  interfaces:
    my-vpn:
      conf:
        Address: 10.0.0.1/24
        PrivateKey: <my private key>
        ListenPort: 12345
        PostUp: iptables -A FORWARD -i my-vpn -j ACCEPT; iptables -A FORWARD -o my-vpn -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        PostDown: iptables -D FORWARD -i my-vpn -j ACCEPT; iptables -D FORWARD -o my-vpn -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
      peers:
        my-laptop:
          conf:
            PublicKey: XbvxfV6rCbEiMm28/4Sw62nTGaVXSZ2wNA4uOawMngc=
            Endpoint: mylaptop.mydomain.com:54321
            AllowedIPs: 10.0.0.2/32
```

## Cannot route my internet trafic through wg interface
If you get this:
```bash
$ ping -I vpn www.google.com
PING www.google.com (216.58.210.36) from 10.0.0.3 vpn: 56(84) bytes of data.
ping: sendmsg: Required key not available
```

Try setting `AllowedIPs` to `0.0.0.0/0` for the peer through which you want to direct all traffic.

Solution is from the email "[Unable to configure routing]" in wireguard's mailing list.


[Unable to configure routing]: https://lists.zx2c4.com/pipermail/wireguard/2016-August/000339.html
