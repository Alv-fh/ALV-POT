# 🛡️ ALV-POT - Sistema de Honeypots para Entornos Municipales

![Docker](https://img.shields.io/badge/Docker-Enabled-blue)
![Python](https://img.shields.io/badge/Python-3.9-green)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)

Sistema de detección temprana de ciberataques mediante honeypots dockerizados, diseñado específicamente para entornos de administración pública como el Ayuntamiento de Sevilla.

## 🎯 Características Principales

- **🐳 Contenedores Docker**: Fácil despliegue y aislamiento
- **🎯 Múltiples Honeypots**: SSH, Web, FTP, SMB, MySQL
- **📊 Dashboard en Tiempo Real**: Grafana con métricas visuales
- **🏛️ Personalización Municipal**: Adaptado para Ayuntamientos
- **🔔 Sistema de Alertas**: Notificaciones automáticas
- **📈 Análisis de Amenazas**: Geolocalización y patrones de ataque

## 🚀 Instalación Rápida

### Prerrequisitos
- **Docker** y **Docker Compose** instalados
- **Ubuntu Server 20.04+** recomendado
- **4GB RAM + 2 CPUs** mínimo
- **Puertos abiertos**: 22, 80, 443, 2222, 3306, 3000

### Instalación en 3 Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/tuusuario/alv-pot.git
cd alv-pot

# 2. Ejecutar script de configuración
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Desplegar todos los servicios
docker-compose up -d
