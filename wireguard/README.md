# wireguard salt state

## Generating private keys
```bash
mkdir -p ~/.wg && touch ~/.wg/private && chmod 660 ~/.wg/private && wg genkey > ~/.wg/private
```

## Getting the public key
```bash
wg pubkey < ~/.wg/private
```