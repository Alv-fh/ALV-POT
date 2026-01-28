#!/bin/bash

# Honeypot Stack Setup - Versión organizada
# By: TuNombre

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# Directorio actual
BASE_DIR="$(pwd)"

# Verificar si estamos en el directorio correcto
check_environment() {
    print "Verificando entorno..."
    
    # Verificar archivos esenciales
    if [ ! -f "docker-compose.yml" ]; then
        error "docker-compose.yml no encontrado"
        exit 1
    fi
    
    if [ ! -f "setup.sh" ]; then
        warn "setup.sh no encontrado en el directorio actual"
    fi
    
    print "Directorio base: $BASE_DIR"
}

# Instalar Docker si es necesario
install_docker() {
    if ! command -v docker &> /dev/null; then
        warn "Docker no encontrado"
        
        if [ -f "scripts/install-docker.sh" ]; then
            print "Instalando Docker..."
            chmod +x scripts/install-docker.sh
            sudo ./scripts/install-docker.sh
        else
            error "Script de instalación no encontrado"
            print "Instala Docker manualmente: https://docs.docker.com/engine/install/"
            exit 1
        fi
    else
        print "✓ Docker ya instalado"
    fi
}

# Configurar sistema
configure_system() {
    print "Configurando sistema..."
    
    # Memoria para Elasticsearch
    sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true
    
    # Verificar si el usuario está en grupo docker
    if ! groups $USER | grep -q docker; then
        warn "Usuario no está en grupo docker"
        sudo usermod -aG docker $USER 2>/dev/null && {
            print "✓ Usuario agregado al grupo docker"
            warn "⚠ Cierra sesión y vuelve a entrar o ejecuta: newgrp docker"
        }
    fi
}

# Crear estructura de directorios
create_structure() {
    print "Creando estructura..."
    
    # Directorios de datos
    mkdir -p data/elasticsearch
    mkdir -p data/cowrie/{downloads,keys,log,tty}
    mkdir -p data/dionaea/{log,lib,dionaea}
    mkdir -p data/rdpy/{logs,sessions}
    mkdir -p data/dvwa/{mysql,logs,config,uploads}
    
    # Configuraciones si no existen
    mkdir -p config
    
    # Permisos
    sudo chown 1000:1000 data/elasticsearch 2>/dev/null || true
    sudo chown -R 2000:2000 data/cowrie 2>/dev/null || true
    
    print "✓ Estructura creada"
}

# Iniciar servicios
start_services() {
    print "Iniciando servicios Docker..."
    
    # Parar si ya está corriendo
    docker-compose down 2>/dev/null || true
    
    # Iniciar
    if docker-compose up -d; then
        print "✓ Servicios iniciados"
    else
        error "Error al iniciar servicios"
        exit 1
    fi
}

# Verificar servicios
check_services() {
    print "Verificando servicios..."
    sleep 10
    
    # Elasticsearch
    if curl -s http://localhost:9200 > /dev/null; then
        print "✓ Elasticsearch funcionando"
    else
        warn "Elasticsearch no responde (puede tardar 1-2 minutos)"
    fi
    
    # Kibana
    if curl -s http://localhost:5601 > /dev/null; then
        print "✓ Kibana funcionando"
    else
        warn "Kibana iniciando..."
    fi
    
    # Honeypots
    print "Honeypots escuchando en:"
    echo "  • SSH:     localhost:2222"
    echo "  • Telnet:  localhost:2223"
    echo "  • FTP:     localhost:21"
    echo "  • RDP:     localhost:3389"
    echo "  • DVWA:    http://localhost"
}

# Mostrar ayuda
show_help() {
    echo -e "${BLUE}Honeypot Stack - Comandos disponibles:${NC}"
    echo ""
    echo "  ./setup.sh start     - Iniciar todo el stack"
    echo "  ./setup.sh stop      - Detener servicios"
    echo "  ./setup.sh restart   - Reiniciar servicios"
    echo "  ./setup.sh status    - Ver estado"
    echo "  ./setup.sh logs      - Ver logs"
    echo "  ./setup.sh cleanup   - Eliminar todo"
    echo "  ./setup.sh help      - Mostrar ayuda"
    echo ""
}

# Comando principal
case "$1" in
    start)
        check_environment
        install_docker
        configure_system
        create_structure
        start_services
        check_services
        
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${GREEN}       🎯 HONEYPOT STACK LISTO       ${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo "📊 Kibana:        http://localhost:5601"
        echo "🔍 Elasticsearch: http://localhost:9200"
        echo "🛡️  Honeypots:"
        echo "   - SSH/Telnet:  localhost:2222-2223"
        echo "   - FTP/SMB:     localhost:21,445"
        echo "   - RDP:         localhost:3389"
        echo "   - DVWA:        http://localhost"
        echo ""
        echo "📝 Comandos útiles:"
        echo "   docker-compose ps      # Ver estado"
        echo "   docker-compose logs    # Ver logs"
        echo "   ./setup.sh stop        # Detener todo"
        echo ""
        ;;
        
    stop)
        print "Deteniendo servicios..."
        docker-compose down
        print "✓ Servicios detenidos"
        ;;
        
    restart)
        docker-compose restart
        print "✓ Servicios reiniciados"
        ;;
        
    status)
        docker-compose ps
        echo ""
        print "Verificando Elasticsearch..."
        curl -s http://localhost:9200 2>/dev/null || warn "No responde"
        ;;
        
    logs)
        docker-compose logs -f
        ;;
        
    cleanup)
        warn "⚠ Esto eliminará TODOS los datos y contenedores"
        read -p "¿Continuar? (escribe 'si'): " confirm
        if [ "$confirm" = "si" ]; then
            docker-compose down -v 2>/dev/null || true
            sudo rm -rf data
            print "✓ Todo limpiado"
        else
            print "Operación cancelada"
        fi
        ;;
        
    help|--help|-h|"")
        show_help
        ;;
        
    *)
        error "Comando desconocido: $1"
        show_help
        exit 1
        ;;
esac
