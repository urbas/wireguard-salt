{% from "systemd/timers/macros.jinja" import timer %}

## Configuration
{%- load_yaml as common_defaults %}
# Find latest release at: https://www.wireguard.com/install/#compiling-from-source
version: 0.0.20181018
tar_sha256sum: 'af05824211b27cbeeea2b8d6b76be29552c0d80bfe716471215e4e43d259e327'
interfaces: {}
{%- endload %}

{%- load_yaml as raspbian_defaults %}
deps:
  - libmnl-dev
  - libelf-dev
  - raspberrypi-kernel-headers
  - build-essential
  - pkg-config
{%- endload %}

{%- load_yaml as ubuntu_defaults %}
deps:
  - libmnl-dev
  - libelf-dev
  - linux-headers-generic
  - build-essential
  - pkg-config
{%- endload %}

{% set os_specific_defaults = salt['grains.filter_by'](
  grain="os",
  base="common",
  lookup_dict={
    "common": common_defaults,
    "Raspbian": raspbian_defaults,
    "Ubuntu": ubuntu_defaults
  }
) %}

{% set config = salt['pillar.get']('wireguard', default=os_specific_defaults, merge=True) %}

## Installation
wireguard.deps.installed:
  pkg.installed:
    - pkgs: {{ config.deps | json }}

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
    - watch:
      - /var/sources/wireguard

## Interface Setup
{% for interface, interface_config in config.interfaces | dictsort %}
  {% set is_interface_disabled = interface_config.disabled | default(False) %}

/etc/wireguard/{{ interface }}.conf:
  file.managed:
    - source: salt://wireguard/files/wireguard.conf
    - template: jinja
    - context:
        config: {{ interface_config | json }}
    - mode: 660

# This refreshes systemd's unit file caches
wireguard.interface.{{ interface }}.systemctl_reload:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - wireguard.install
      - /etc/wireguard/{{ interface }}.conf

# This brings up or tears down the interface
wireguard.interface.{{ interface }}.service:
{% if is_interface_disabled %}
  service.dead:
    - name: wg-quick@{{ interface }}
    - enable: False
{% else %}
  service.running:
    - name: wg-quick@{{ interface }}
    - enable: True
    - watch:
      - wireguard.install
      - /etc/wireguard/{{ interface }}.conf
      - wireguard.interface.{{ interface }}.systemctl_reload
{% endif %}

# This refreshes the peer's endpoint periodically.
  {% for peer, peer_config in interface_config.peers | dictsort %}
    {% if peer_config.refresh_endpoint | default(False) %}
{{ timer(
  erased=is_interface_disabled,
  service_name="wireguard-" + interface + "-refresh-peer-" + peer,
  exec_start="/usr/bin/wg set " + interface + " peer " + peer_config.conf.PublicKey + " allowed-ips " + peer_config.conf.AllowedIPs + " endpoint " + peer_config.conf.Endpoint,
  period='*:0/1'
) }}
    {% endif %}
  {% endfor %}
{% endfor %}
