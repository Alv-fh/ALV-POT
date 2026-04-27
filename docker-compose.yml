# 🛡️ ALV-POT — Honeypot Stack with ELK

> Stack completo de honeypots con monitoreo en tiempo real mediante Elasticsearch + Kibana + Logstash, desplegable con un solo comando.

![Stack](https://img.shields.io/badge/Stack-ELK%207.17-005571?style=flat-square&logo=elastic)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-E95420?style=flat-square&logo=ubuntu)

---

## 📋 Índice

- [Características](#-características)
- [Arquitectura](#-arquitectura)
- [Honeypots incluidos](#-honeypots-incluidos)
- [Requisitos](#-requisitos)
- [Instalación rápida](#-instalación-rápida)
- [Modo VPN (producción)](#-modo-vpn-producción)
- [Dashboards de Kibana](#-dashboards-de-kibana)
- [Comandos del script](#-comandos-del-script)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Advertencia de seguridad](#-advertencia-de-seguridad)

---

## 🚀 Características

- **4 honeypots** cubriendo SSH/Telnet, RDP, Web vulnerable e intranet falsa
- **ELK Stack 7.17** — Elasticsearch + Kibana + Logstash completamente configurado
- **Dashboards preconfigurados** importados automáticamente en Kibana
- **Autenticación Basic Auth** sobre Kibana vía Nginx reverse proxy
- **Script de instalación interactivo** — un solo comando despliega todo
- **Modo VPN opcional** — todos los servicios accesibles solo desde red privada OpenVPN

---

## 🏗️ Arquitectura

```
Internet
    │
    ├── :22   / :23  ──► Cowrie     (SSH / Telnet honeypot)
    ├── :3389         ──► RDPy      (RDP honeypot)
    ├── :80           ──► DVWA      (Web app vulnerable)
    ├── :81           ──► HoneyWeb  (Panel de login falso)
    │
    └── :5601         ──► Nginx ──► Kibana  (Basic Auth)
                                       │
                               Elasticsearch :9200
                                       ▲
                               Logstash :5044
                               ▲   ▲   ▲   ▲
                           Cowrie RDPY DVWA HoneyWeb
                            logs  logs logs  logs
```

Todos los servicios corren en la red Docker interna `monitoring-net`. Logstash lee los logs de cada honeypot mediante volúmenes compartidos, los procesa y los indexa en Elasticsearch. Kibana visualiza los datos a través de Nginx con autenticación.

---

## 🪤 Honeypots incluidos

| Honeypot | Puerto | Protocolo | Qué captura |
|----------|--------|-----------|-------------|
| **Cowrie** | 2222 / 2223 | SSH / Telnet | IPs, credenciales, comandos ejecutados, archivos descargados |
| **RDPy** | 3389 | RDP | IPs, combinaciones usuario/contraseña |
| **DVWA** | 80 | HTTP | IPs, rutas accedidas, métodos HTTP, códigos de respuesta |
| **HoneyWeb** | 81 | HTTP | IPs, credenciales introducidas en panel de login falso |

### HoneyWeb

Panel de login que simula una intranet corporativa ("ALV Corp"). Cualquier intento de acceso queda registrado con IP, usuario y contraseña. Desarrollado en Python/Flask.

---

## 📦 Requisitos

- **SO:** Linux — Ubuntu 22.04 / 24.04 o Debian 11/12 (recomendado)
- **RAM:** 4 GB mínimo · 8 GB recomendado
- **Disco:** 20 GB libres mínimo
- **Dependencias:** El script instala automáticamente Docker, Docker Compose y las utilidades necesarias

---

## ⚡ Instalación rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/Alv-fh/ALV-POT
cd ALV-POT

# 2. Iniciar stack
chmod +x setup.sh
sudo bash setup.sh start
```

El script pedirá las credenciales para el acceso a Kibana y desplegará todo automáticamente.

Una vez completado, accede a:

| Servicio | URL |
|----------|-----|
| Kibana | `http://TU_IP:5601` |
| DVWA | `http://TU_IP` |
| HoneyWeb | `http://TU_IP:81` |

> Las credenciales de DVWA por defecto son `admin` / `password`.

---

## 🔐 Modo VPN (producción)

Para un despliegue seguro en un VPS real, ALV-POT incluye un segundo script que añade:

- **OpenVPN** — servidor VPN con TLS-Crypt-V2, TLS 1.2+, AES-128-GCM
- **Split-DNS con dnsmasq** — el dominio resuelve a la IP privada VPN solo desde dentro
- **DuckDNS** — dominio dinámico gratuito con actualización automática cada 5 minutos
- **Docker Compose modificado** — todos los puertos quedan vinculados a `10.8.0.1` (solo VPN)
- **UFW configurado** — solo expone SSH (22) y OpenVPN (1194/UDP) al exterior

```bash
chmod +x setup-vpn.sh
sudo bash setup-vpn.sh start
```

El script pedirá IP pública, subdominio y token de DuckDNS, y credenciales de Kibana. Al finalizar genera el archivo `.ovpn` listo para importar en cualquier cliente OpenVPN.

```
Internet
    │
    ├── :22/tcp   ──► SSH (administración)
    └── :1194/udp ──► OpenVPN
                          │
                    Red privada 10.8.0.0/24
                          │
                ┌─────────┴──────────┐
                │   Todos los        │
                │   servicios        │
                │   honeypot +       │
                │   Kibana           │
                └────────────────────┘
```

> En este modo, ningún honeypot ni Kibana es accesible desde internet. Solo los atacantes que lleguen a los puertos expuestos (simulado mediante port-forwarding o exposición controlada) pueden interactuar con los honeypots.

---

## 📊 Dashboards de Kibana

Los dashboards se importan automáticamente durante el despliegue. Incluyen:

**Dashboard Cowrie**
- Ataques en tiempo real (tabla IP × tiempo)
- Top 10 IPs atacantes
- Top 10 passwords más utilizadas
- Comandos ejecutados tras acceso SSH

**Dashboard DVWA**
- Rutas más accedidas con IP y timestamp
- Comparativa de métodos HTTP (GET / POST / HEAD)
- Distribución de códigos de respuesta
- Top 10 IPs atacantes

**Dashboard RDPy**
- Top 10 combinaciones usuario/contraseña
- Top 10 usuarios más probados
- Top 10 passwords RDP

**Dashboard HoneyWeb**
- Top 10 usuarios introducidos
- Top 10 passwords introducidas
- Tabla completa de combinaciones con IP origen

---

## 🛠️ Comandos del script

```bash
sudo bash setup.sh start     # Despliega el stack completo
sudo bash setup.sh stop      # Detiene todos los servicios
sudo bash setup.sh restart   # Reinicia el stack
sudo bash setup.sh status    # Estado de los contenedores
sudo bash setup.sh logs      # Logs en tiempo real
sudo bash setup.sh cleanup   # Elimina contenedores y datos
sudo bash setup.sh help      # Muestra ayuda
```

---

## 📁 Estructura del proyecto

```
ALV-POT/
├── config/
│   ├── elasticsearch/
│   │   └── elasticsearch.yml
│   ├── kibana/
│   │   └── dashboards/
│   │       └── dashboard.ndjson
│   ├── logstash/
│   │   ├── config/
│   │   │   └── logstash.yml
│   │   └── pipeline/
│   │       └── logstash.conf
│   └── nginx/
│       └── nginx.conf
├── honeyweb/
│   ├── app.py           # Aplicación Flask del honeypot web
│   ├── Dockerfile
│   └── favicon.png
├── docker-compose.yml   # Modo público
├── setup.sh             # Script de despliegue (modo público)
├── setup-vpn.sh         # Script de despliegue (modo VPN)
├── LICENSE
└── README.md
```

---

## ⚠️ Advertencia de seguridad

Este proyecto está diseñado para entornos de investigación y aprendizaje controlados.

- No expongas los servicios en una red de producción sin el **modo VPN**
- DVWA está configurada con `SECURITY_LEVEL=low` intencionalmente — es una aplicación vulnerable por diseño
- Las credenciales por defecto deben cambiarse antes de cualquier despliegue público
- El autor no se hace responsable del uso indebido de este software

---

## 📄 Licencia

MIT License — consulta el archivo [LICENSE](LICENSE) para más detalles.
