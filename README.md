# 🛡️ Honeypot Stack with ELK

Stack completo hecho con Docker de honeypots con monitoreo Elasticsearch + Kibana + Logstash.

## 🚀 Características

- **Honeypots**: Cowrie (SSH/Telnet), RDPy (RDP), DVWA (Web vulnerable) y HoneyWeb (Panel de Login a una intranet)
- **Monitoreo**: Elasticsearch + Kibana + Logstash (ELK Stack)
- **Automatización**: Script de instalación y configuración completo

## 📦 Requisitos

- Linux (Ubuntu/Debian)
- 4GB RAM mínimo (8GB recomendado)
- 20GB espacio en disco

## ⚡ Instalación Rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/Alv-fh/ALV-POT
cd ALV-POT
# 2. Iniciar stack
chmod +x setup.sh
sudo bash setup.sh start
