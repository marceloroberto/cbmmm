#!/bin/bash

echo "=== UPDATE GLOBAL ==="

# ===============================
# IDENTIFICAR USUÁRIO GRÁFICO
# ===============================
USER_REAL=$(who | awk '/(:0|tty7)/ {print $1}' | head -n 1)
[ -z "$USER_REAL" ] && USER_REAL="$SUDO_USER"

if [ -z "$USER_REAL" ]; then
  echo "❌ Não foi possível identificar o usuário."
  read -p "Pressione ENTER para sair..."
  exit 1
fi

HOME_DIR="/home/$USER_REAL"
DESKTOP_DIR="$HOME_DIR/Desktop"


# ===============================
# CRIAR ÍCONE NA ÁREA DE TRABALHO
# ===============================
DESKTOP_FILE="$DESKTOP_DIR/Atualização do Sistema"

echo "🖥️ Criando ícone na Área de Trabalho..."

sudo -u "$USER_REAL" mkdir -p "$DESKTOP_DIR"

sudo -u "$USER_REAL" bash -c "cat > '$DESKTOP_FILE' <<EOF
[Desktop Entry]
Type=Application
Name=Atualização do Sistema
Comment=Atualização do Sistema
Exec=sudo /usr/local/bin/update_global.sh
Icon=system-software-update
Terminal=true
Categories=System;
EOF
"

sudo -u "$USER_REAL" chmod +x "$DESKTOP_FILE"




BIN_DIR="/usr/local/bin"
COPY_SCRIPT="$BIN_DIR/copyupdate.sh"
UPDATE_SCRIPT="$BIN_DIR/update.sh"

COPY_URL="https://raw.githubusercontent.com/marceloroberto/cbmmm/main/copyupdate.sh"

echo "Usuário detectado: $USER_REAL"
echo "Scripts em: $BIN_DIR"
echo "----------------------------------"

# ===============================
# GARANTIR DIRETÓRIO GLOBAL
# ===============================
mkdir -p "$BIN_DIR"

# ===============================
# BAIXAR copyupdate.sh
# ===============================
echo "⬇ Baixando copyupdate.sh..."
wget -q -O "$COPY_SCRIPT" "$COPY_URL"

if [ ! -f "$COPY_SCRIPT" ]; then
  echo "❌ Falha ao baixar copyupdate.sh"
  read -p "Pressione ENTER para sair..."
  exit 1
fi

chmod +x "$COPY_SCRIPT"

# ===============================
# EXECUTAR copyupdate.sh
# ===============================
echo "▶ Executando copyupdate.sh..."
bash "$COPY_SCRIPT"

# ===============================
# VERIFICAR update.sh
# ===============================
if [ ! -f "$UPDATE_SCRIPT" ]; then
  echo "❌ update.sh não encontrado em $BIN_DIR"
  read -p "Pressione ENTER para sair..."
  exit 1
fi

chmod +x "$UPDATE_SCRIPT"

# ===============================
# EXECUTAR update.sh
# ===============================
echo "▶ Executando update.sh..."
bash "$UPDATE_SCRIPT"

echo "----------------------------------"
echo "✅ Atualização finalizada com sucesso."
echo "----------------------------------"

echo "Esta tela fechará automaticamente em até 5 segundos..."

# read -p "Pressione ENTER para fechar o terminal..."

sleep 5
