# 🛡️ Honeypot Stack with ELK

Stack completo de honeypots con monitoreo Elasticsearch + Kibana + Logstash.

## 🚀 Características

- **Honeypots**: Cowrie (SSH/Telnet), Dionaea (FTP/SMB), RDPy (RDP), DVWA (Web vulnerable)
- **Monitoreo**: Elasticsearch + Kibana + Logstash (ELK Stack)
- **Automatización**: Script de instalación y configuración completo

## 📦 Requisitos

- Linux (Ubuntu/Debian/CentOS)
- 4GB RAM mínimo (8GB recomendado)
- 20GB espacio en disco

## ⚡ Instalación Rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/Alv-fh/ALV-POT.git
cd ALV-POT
# 2. Instalar Docker (si no está instalado)
chmod +x scripts/install-docker.sh
./scripts/install-docker.sh

# 3. Iniciar stack
chmod +x setup.sh
./setup.sh start
