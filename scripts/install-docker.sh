#!/bin/bash

# Script de instalación de Docker y Docker Compose

set -e

echo "🔧 Instalando Docker..."

# Detectar distribución
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ No se pudo detectar sistema operativo"
    exit 1
fi

# Instalar según distribución
case $OS in
    ubuntu|debian)
        echo "📦 Sistema detectado: Ubuntu/Debian"
        
        # Actualizar repositorios
        sudo apt-get update
        
        # Instalar dependencias
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
            
        # Agregar repositorio Docker
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Instalar Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Habilitar servicio
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Agregar usuario al grupo docker
        sudo usermod -aG docker $USER
        
        echo "✅ Docker instalado en Ubuntu/Debian"
        ;;
        
    centos|rhel|fedora)
        echo "📦 Sistema detectado: CentOS/RHEL/Fedora"
        
        # Instalar dependencias
        sudo yum install -y yum-utils
        
        # Agregar repositorio
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # Instalar Docker
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Habilitar servicio
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Agregar usuario al grupo
        sudo usermod -aG docker $USER
        
        echo "✅ Docker instalado en CentOS/RHEL/Fedora"
        ;;
        
    *)
        echo "❌ Sistema operativo no soportado: $OS"
        echo "📖 Instala Docker manualmente: https://docs.docker.com/engine/install/"
        exit 1
        ;;
esac

# Configurar sistema para Elasticsearch
echo "⚙️ Configurando sistema..."
sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true

echo ""
echo "🎉 Instalación completada!"
echo ""
echo "⚠️ IMPORTANTE: Debes cerrar sesión y volver a entrar para que los cambios surtan efecto"
echo "   O ejecuta: newgrp docker"
echo ""
echo "Luego ejecuta: ./setup.sh start"
