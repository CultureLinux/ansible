# VictoriaMetrics

## Included

- victoriametrics
- vmalert
- alermanager (discord notifier)

## Exporters
### pve_exporter
#### Install
    python3 -m venv /opt/prometheus-pve-exporter
    source /opt/prometheus-pve-exporter/bin/activate
    pip install prometheus-pve-exporter
#### Proxmox 
    pveum user add prometheus@pve
    pveum aclmod / -user prometheus@pve -role PVEAuditor
    pveum user token add prometheus@pve victoria-access -expire 0 -privsep 0 -comment "VictoriaMetrics access"

#### Config file /etc/prometheus/pve.yml
default:
    user: prometheus@pve
    token_name: victoria-access
    token_value: e91fbb65-6d8b-4ef1-b861-3661f0df3913
    verify_ssl: false

#### Service systemd /etc/systemd/system/prometheus-pve-exporter.service
    [Unit]
    Description=Prometheus exporter for Proxmox VE
    Documentation=https://github.com/znerol/prometheus-pve-exporter

    [Service]
    Restart=always
    User=root
    ExecStart=/opt/prometheus-pve-exporter/bin/python /opt/prometheus-pve-exporter/bin/pve_exporter --config.file /etc/prometheus/pve.yml

    [Install]
    WantedBy=multi-user.target

