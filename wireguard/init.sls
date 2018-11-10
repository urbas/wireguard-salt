{% from "systemd/timers/macros.jinja" import timer %}
{% from "systemd/services/macros.jinja" import service %}

{%- load_yaml as defaults %}
# Find latest release at: https://www.wireguard.com/install/#compiling-from-source
version: 0.0.20181018
tar_sha256sum: 'af05824211b27cbeeea2b8d6b76be29552c0d80bfe716471215e4e43d259e327'
interfaces: {}
{%- endload %}

{% set config = salt['pillar.get']('wireguard', default=defaults, merge=True) %}

wireguard.deps.installed:
  pkg.installed:
    - pkgs:
      - libmnl-dev
      - libelf-dev
      - raspberrypi-kernel-headers
      - build-essential
      - pkg-config

/var/sources/wireguard:
  file.directory:
    - makedirs: True
  archive.extracted:
    - source: 'https://git.zx2c4.com/WireGuard/snapshot/WireGuard-{{ config.version }}.tar.xz'
    - source_hash: {{ config.tar_sha256sum }}
    - clean: True

# This installs the following:
#   'wg' -> '/usr/bin/wg'
#   'man/wg.8' -> '/usr/share/man/man8/wg.8'
#   'completion/wg.bash-completion' -> '/usr/share/bash-completion/completions/wg'
#   'wg-quick/linux.bash' -> '/usr/bin/wg-quick'
#   install: creating directory '/etc/wireguard'
#   'man/wg-quick.8' -> '/usr/share/man/man8/wg-quick.8'
#   'completion/wg-quick.bash-completion' -> '/usr/share/bash-completion/completions/wg-quick'
#   'systemd/wg-quick@.service' -> '/lib/systemd/system/wg-quick@.service'
wireguard.install:
  cmd.run:
    - name: make && make install && echo "{{ config.tar_sha256sum }}" > /var/sources/wireguard.build.sha256sum
    - cwd: /var/sources/wireguard/WireGuard-{{ config.version }}/src
    - unless: 'grep -q "{{ config.tar_sha256sum }}" /var/sources/wireguard.build.sha256sum'

{% for interface, interface_config in config.interfaces | dictsort %}
/etc/wireguard/{{ interface }}.conf:
  file.managed:
    - source: salt://wireguard/files/wireguard.conf
    - template: jinja
    - context:
        config: {{ interface_config | json }}
    - mode: 660

# This brings up the wireguard interface
{{ service(
  erased=interface_config.disabled | default(False),
  service_name="wireguard-" + interface,
  exec_start="/usr/bin/wg-quick up " + interface,
  service_config={
    "Type": "oneshot",
    "RemainAfterExit": "yes",
    "ExecStop": "/usr/bin/wg-quick down " + interface
  },
  unit_config={
    "After": "network-online.target",
    "Wants": "network-online.target"
  },
  watch=["/etc/wireguard/" + interface + ".conf", "wireguard.install"]
) }}

# This refreshes the peer's endpoint periodically.
  {% for peer, peer_config in interface_config.peers | dictsort %}
    {% if peer_config.refresh_endpoint | default(False) %}
{{ timer(
  erased=interface_config.disabled | default(False),
  service_name="wireguard-" + interface + "-refresh-peer-" + peer,
  exec_start="/usr/bin/wg set " + interface + " peer " + peer_config.public_key + " allowed-ips " + peer_config.allowed_ips + " endpoint " + peer_config.endpoint,
  period='*:0/1'
) }}
    {% endif %}
  {% endfor %}
{% endfor %}
