#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════╗
# ║              ALV-POT Honeypot Stack Setup                     ║
# ║         Automated deployment with dashboard import            ║
# ╚═══════════════════════════════════════════════════════════════╝

set -e

# ─── Colores ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Iconos ───────────────────────────────────────────────────────
OK="${GREEN}✔${NC}"
WARN="${YELLOW}⚠${NC}"
ERR="${RED}✘${NC}"
INFO="${CYAN}➜${NC}"

# ─── Utilidades ───────────────────────────────────────────────────
print()   { echo -e "${OK} $1"; }
warn()    { echo -e "${WARN} ${YELLOW}$1${NC}"; }
error()   { echo -e "${ERR} ${RED}$1${NC}"; }
info()    { echo -e "${INFO} ${CYAN}$1${NC}"; }
header()  { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }
divider() { echo -e "${DIM}────────────────────────────────────────────────────${NC}"; }

# ─── Banner ───────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${RED}${BOLD}"
    echo '  ░█████╗░██╗░░░░░██╗░░░██╗░░░░░░██████╗░░█████╗░████████╗'
    echo '  ██╔══██╗██║░░░░░██║░░░██║░░░░░░██╔══██╗██╔══██╗╚══██╔══╝'
    echo '  ███████║██║░░░░░╚██╗░██╔╝█████╗██████╔╝██║░░██║░░░██║░░░'
    echo '  ██╔══██║██║░░░░░░╚████╔╝░╚════╝██╔═══╝░██║░░██║░░░██║░░░'
    echo '  ██║░░██║███████╗░░╚██╔╝░░░░░░░░██║░░░░░╚█████╔╝░░░██║░░░'
    echo '  ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░░░░░░░╚═╝░░░░░░╚════╝░░░╚═╝░░░'
    echo -e "${NC}"
    echo -e "  ${DIM}Honeypot Stack  •  ELK + Cowrie + RDPY + DVWA${NC}"
    divider
    echo ""
}

# ─── Barra de Progreso ────────────────────────────────────────────
# Uso: progress_bar <paso_actual> <total_pasos> <mensaje>
progress_bar() {
    local current=$1
    local total=$2
    local message=$3
    local width=40
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local percent=$(( current * 100 / total ))

    printf "\r  ${CYAN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} ${BOLD}%3d%%${NC}  %s" "$percent" "$message"

    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# ─── Spinner ──────────────────────────────────────────────────────
spinner_pid=""
start_spinner() {
    local msg="$1"
    local spinners=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    (
        local i=0
        while true; do
            printf "\r  ${CYAN}${spinners[$i]}${NC}  %s" "$msg"
            i=$(( (i + 1) % 10 ))
            sleep 0.1
        done
    ) &
    spinner_pid=$!
}

stop_spinner() {
    if [ -n "$spinner_pid" ]; then
        kill "$spinner_pid" 2>/dev/null
        wait "$spinner_pid" 2>/dev/null || true
        spinner_pid=""
        printf "\r\033[K"
    fi
}

# ─── Determinar comando Docker Compose ────────────────────────────
get_compose_cmd() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    elif command -v docker-compose &>/dev/null; then
        echo "docker-compose"
    else
        error "docker compose no encontrado"
        exit 1
    fi
}

# ─── Instalar dependencias ────────────────────────────────────────
install_deps() {
    header "Verificando dependencias"
    local step=0
    local total=4

    # Docker
    step=$((step+1)); progress_bar $step $total "Comprobando Docker..."
    if ! command -v docker &>/dev/null; then
        warn "Docker no encontrado. Instalando..."
        sudo apt update -qq
        sudo apt install -y docker.io -qq
        sudo systemctl enable --now docker
        print "Docker instalado"
    else
        print "Docker $(docker --version | awk '{print $3}' | tr -d ',')"
    fi

    # Docker Compose
    step=$((step+1)); progress_bar $step $total "Comprobando Docker Compose..."
    if ! docker compose version &>/dev/null && ! command -v docker-compose &>/dev/null; then
        warn "Docker Compose no encontrado. Instalando..."
        sudo apt install -y docker-compose-v2 -qq
        print "Docker Compose instalado"
    else
        print "Docker Compose disponible"
    fi

    # vm.max_map_count para Elasticsearch
    step=$((step+1)); progress_bar $step $total "Configurando kernel para Elasticsearch..."
    sudo sysctl -w vm.max_map_count=262144 &>/dev/null || true
    print "vm.max_map_count=262144"

    # Grupo docker
    step=$((step+1)); progress_bar $step $total "Verificando permisos Docker..."
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        warn "Usuario añadido al grupo docker. Puede ser necesario reabrir sesión."
    else
        print "Permisos Docker correctos"
    fi

    echo ""
}

# ─── Crear estructura de directorios ─────────────────────────────
create_dirs() {
    header "Creando estructura de directorios"
    local dirs=(
        "data/elasticsearch"
        "data/cowrie/log/tty"
        "data/cowrie/downloads"
        "data/cowrie/keys"
        "data/rdpy/logs"
        "data/dvwa/logs"
        "data/dvwa/mysql"
        "config/kibana/dashboards"
    )
    local total=${#dirs[@]}
    local step=0
    for dir in "${dirs[@]}"; do
        step=$((step+1))
        progress_bar $step $total "Creando $dir"
        mkdir -p "$dir"
        sleep 0.05
    done
    print "Estructura de directorios lista"
    # Permisos requeridos por Cowrie (corre con UID 2000)
    sudo chown -R 2000:2000 data/cowrie
    sudo chmod -R 755 data/cowrie
    print "Permisos de Cowrie aplicados (2000:2000)"
    echo ""
}

# ─── Iniciar contenedores ─────────────────────────────────────────
start_containers() {
    header "Iniciando contenedores Docker"
    local COMPOSE_CMD
    COMPOSE_CMD=$(get_compose_cmd)

    info "Usando: $COMPOSE_CMD"
    echo ""

    # Ejecutar docker compose y mostrar output directamente
    $COMPOSE_CMD up -d --quiet-pull 2>&1
    
    print "Contenedores iniciados"
    echo ""

    # Mostrar estado
    echo -e "  ${DIM}Estado de los servicios:${NC}"
    $COMPOSE_CMD ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | \
        while IFS= read -r line; do
            if echo "$line" | grep -q "running\|Up"; then
                echo -e "  ${GREEN}${line}${NC}"
            elif echo "$line" | grep -q "NAME\|Service"; then
                echo -e "  ${BOLD}${line}${NC}"
            else
                echo -e "  ${YELLOW}${line}${NC}"
            fi
        done
    echo ""
}



# ─── Esperar Elasticsearch ────────────────────────────────────────
wait_elasticsearch() {
    header "Esperando Elasticsearch"
    local max_attempts=30
    local attempt=0

    start_spinner "Conectando con Elasticsearch en localhost:9200..."
    until curl -s "http://localhost:9200" | grep -q "cluster_name" 2>/dev/null; do
        attempt=$((attempt+1))
        if [ "$attempt" -ge "$max_attempts" ]; then
            stop_spinner
            error "Elasticsearch no respondió tras ${max_attempts} intentos"
            exit 1
        fi
        sleep 5
    done
    stop_spinner
    print "Elasticsearch disponible"
    echo ""
}

# ─── Esperar Kibana ───────────────────────────────────────────────
wait_kibana() {
    header "Esperando Kibana"
    local max_attempts=40
    local attempt=0

    start_spinner "Conectando con Kibana en localhost:5601 (puede tardar ~2 min)..."
    until curl -s "http://localhost:5601/api/status" | grep -q '"level":"available"' 2>/dev/null; do
        attempt=$((attempt+1))
        if [ "$attempt" -ge "$max_attempts" ]; then
            stop_spinner
            warn "Kibana tardó demasiado, continuando de todos modos..."
            return
        fi
        sleep 5
    done
    stop_spinner
    print "Kibana disponible"
    echo ""
}

# ─── Importar dashboards ──────────────────────────────────────────
import_dashboards() {
    header "Importando dashboards de Kibana"

    local dashboard_dir="./config/kibana/dashboards"

    # Comprobar si hay archivos .ndjson
    if ! ls "$dashboard_dir"/*.ndjson &>/dev/null; then
        warn "No se encontraron dashboards en $dashboard_dir"
        warn "Exporta tus dashboards desde Kibana → Stack Management → Saved Objects → Export"
        info "Guárdalos en: $dashboard_dir/*.ndjson"
        echo ""
        return
    fi

    local total
    total=$(ls "$dashboard_dir"/*.ndjson | wc -l)
    local step=0

    for file in "$dashboard_dir"/*.ndjson; do
        step=$((step+1))
        local name
        name=$(basename "$file")
        progress_bar $step $total "Importando $name..."

        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
            -H "kbn-xsrf: true" \
            -F "file=@$file")

        if [ "$response" != "200" ]; then
            warn "Posible error importando $name (HTTP $response)"
        fi
        sleep 0.3
    done

    print "$total dashboard(s) importados correctamente"
    echo ""
}

# ─── Resumen final ────────────────────────────────────────────────
summary() {
    divider
    echo -e "\n  ${GREEN}${BOLD}✔ ALV-POT desplegado correctamente${NC}\n"
    echo -e "  ${BOLD}Servicios disponibles:${NC}"
    echo -e "  ${CYAN}●${NC}  Kibana         →  ${BOLD}http://localhost:5601${NC}"
    echo -e "  ${CYAN}●${NC}  Elasticsearch  →  ${BOLD}http://localhost:9200${NC}"
    echo -e "  ${CYAN}●${NC}  DVWA           →  ${BOLD}http://localhost${NC}  ${DIM}(admin/password)${NC}"
    echo -e "  ${CYAN}●${NC}  Cowrie SSH     →  ${BOLD}localhost:2222${NC}    ${DIM}(cualquier usuario/pass)${NC}"
    echo -e "  ${CYAN}●${NC}  Cowrie Telnet  →  ${BOLD}localhost:2223${NC}"
    echo -e "  ${CYAN}●${NC}  RDPY           →  ${BOLD}localhost:3389${NC}"
    echo ""
    echo -e "  ${BOLD}Comandos útiles:${NC}"
    echo -e "  ${DIM}Ver logs:     ./setup.sh logs${NC}"
    echo -e "  ${DIM}Ver estado:   ./setup.sh status${NC}"
    echo -e "  ${DIM}Detener:      ./setup.sh stop${NC}"
    divider
    echo ""
}

# ─── Comandos ─────────────────────────────────────────────────────
start() {
    banner
    install_deps
    create_dirs
    start_containers
    wait_elasticsearch
    wait_kibana
    import_dashboards
    summary
}

stop() {
    banner
    header "Deteniendo ALV-POT"
    local COMPOSE_CMD
    COMPOSE_CMD=$(get_compose_cmd)
    start_spinner "Deteniendo servicios..."
    $COMPOSE_CMD down
    stop_spinner
    print "Todos los servicios detenidos"
    echo ""
}

restart() {
    stop
    sleep 2
    start
}

status() {
    local COMPOSE_CMD
    COMPOSE_CMD=$(get_compose_cmd)
    header "Estado de ALV-POT"
    $COMPOSE_CMD ps
    echo ""
    info "Elasticsearch:"
    curl -s http://localhost:9200 | python3 -m json.tool 2>/dev/null || warn "No responde"
}

logs() {
    local COMPOSE_CMD
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD logs -f
}

cleanup() {
    banner
    warn "⚠  Esto eliminará TODOS los contenedores y datos"
    read -p "  ¿Estás seguro? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        local COMPOSE_CMD
        COMPOSE_CMD=$(get_compose_cmd)
        start_spinner "Eliminando contenedores y volúmenes..."
        $COMPOSE_CMD down -v
        stop_spinner
        print "Contenedores y volúmenes eliminados"
        start_spinner "Eliminando datos..."
        rm -rf data
        stop_spinner
        print "Directorio data eliminado"
        print "✅ Limpieza completa"
    else
        info "Cancelado"
    fi
    echo ""
}

help() {
    banner
    echo -e "  ${BOLD}Uso:${NC}  ./setup.sh [comando]\n"
    echo -e "  ${BOLD}Comandos:${NC}"
    echo -e "  ${GREEN}start${NC}    Despliega el stack completo e importa dashboards"
    echo -e "  ${GREEN}stop${NC}     Detiene todos los servicios"
    echo -e "  ${GREEN}restart${NC}  Reinicia el stack"
    echo -e "  ${GREEN}status${NC}   Muestra el estado de los contenedores"
    echo -e "  ${GREEN}logs${NC}     Muestra logs en tiempo real"
    echo -e "  ${GREEN}cleanup${NC}  Elimina todo (contenedores + datos)"
    echo -e "  ${GREEN}help${NC}     Muestra esta ayuda"
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────
case "${1:-start}" in
    start)   start   ;;
    stop)    stop    ;;
    restart) restart ;;
    status)  status  ;;
    logs)    logs    ;;
    cleanup) cleanup ;;
    help|--help|-h) help ;;
    *)
        error "Comando desconocido: $1"
        help
        exit 1
        ;;
esac
