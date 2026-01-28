#!/bin/bash

# ALV-POT Honeypot Stack Setup
# Script simplificado y funcional

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# Determinar comando Docker Compose
get_compose_cmd() {
    # Primero probar docker compose v2
    if docker compose version &> /dev/null; then
        echo "docker compose"
    # Luego probar docker-compose v1
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        error "docker compose no encontrado"
        exit 1
    fi
}

# Instalar dependencias si faltan
install_deps() {
    print "Verificando dependencias..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        warn "Instalando Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl enable --now docker
    else
        print "✓ Docker instalado"
    fi
    
    # Docker Compose (plugin v2)
    if ! docker compose version &> /dev/null; then
        if ! command -v docker-compose &> /dev/null; then
            warn "Instalando Docker Compose..."
            sudo apt install -y docker-compose-v2
        fi
    fi
    
    # Configurar sistema para Elasticsearch
    sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true
    
    # Verificar grupo docker
    if ! groups $USER | grep -q docker; then
        warn "Agregando usuario al grupo docker..."
        sudo usermod -aG docker $USER
        warn "⚠ Ejecuta: newgrp docker o cierra sesión"
    fi
}

# Iniciar stack
start() {
    print "🚀 Iniciando ALV-POT..."
    
    install_deps
    
    # Crear directorios si no existen
    mkdir -p data/elasticsearch data/cowrie/{log,downloads}
    
    # Obtener comando compose
    COMPOSE_CMD=$(get_compose_cmd)
    print "Usando: $COMPOSE_CMD"
    
    # Iniciar
    print "Iniciando servicios..."
    $COMPOSE_CMD up -d
    
    print "✅ Stack iniciado"
    echo ""
    echo "🎯 Servicios disponibles:"
    echo "  Elasticsearch: http://localhost:9200"
    echo "  Kibana:        http://localhost:5601"
    echo "  Cowrie SSH:    localhost:2222 (root/cualquier)"
    echo "  Cowrie Telnet: localhost:2223"
    echo "  DVWA:          http://localhost (admin/password)"
    echo ""
    echo "📊 Ver estado:   $COMPOSE_CMD ps"
    echo "📝 Ver logs:     $COMPOSE_CMD logs"
    echo "🛑 Detener:      $0 stop"
}

# Detener stack
stop() {
    COMPOSE_CMD=$(get_compose_cmd)
    print "Deteniendo servicios..."
    $COMPOSE_CMD down
    print "✅ Servicios detenidos"
}

# Ver estado
status() {
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD ps
    echo ""
    print "Verificando Elasticsearch..."
    curl -s http://localhost:9200 2>/dev/null || warn "No responde"
}

# Ver logs
logs() {
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD logs -f
}

# Limpiar todo
cleanup() {
    warn "⚠ Esto eliminará TODOS los datos"
    read -p "¿Continuar? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        COMPOSE_CMD=$(get_compose_cmd)
        $COMPOSE_CMD down -v
        rm -rf data
        print "✅ Todo limpiado"
    else
        print "❌ Cancelado"
    fi
}

# Mostrar ayuda
help() {
    echo "ALV-POT Honeypot Stack"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  start    - Iniciar stack completo"
    echo "  stop     - Detener servicios"
    echo "  restart  - Reiniciar servicios"
    echo "  status   - Ver estado"
    echo "  logs     - Ver logs en tiempo real"
    echo "  cleanup  - Eliminar todo (datos incluidos)"
    echo "  help     - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start      # Iniciar todo"
    echo "  $0 logs       # Ver logs"
    echo "  $0 cleanup    # Eliminar todo"
}

# Comando principal
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        help
        ;;
    *)
        error "Comando desconocido: $1"
        help
        exit 1
        ;;
esac
