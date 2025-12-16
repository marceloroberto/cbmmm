#!/bin/bash

# ===============================
# IDENTIFICA USUÁRIO LOGADO
# ===============================
USER_REAL=$(logname)
HOME_DIR="/home/$USER_REAL"
DESKTOP="$HOME_DIR/Desktop"
DOCS="$HOME_DIR/Documentos"

COPY="$DOCS/copyupdate.sh"
UPDATE="$DOCS/update.sh"
DESKTOP_FILE="$DESKTOP/Update.desktop"

# ===============================
# FUNÇÃO BARRA DE PROGRESSO
# ===============================
run_with_progress() {
(
  echo 5
  echo "# Preparando ambiente..."

  mkdir -p "$DESKTOP"

  echo 15
  echo "# Ajustando permissões..."
  chmod +x "$COPY" "$UPDATE" 2>/dev/null

  echo 30
  echo "# Criando ícone Update..."
  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Update
Comment=Atualização automática do sistema
Exec=sudo /usr/local/bin/update_global.sh --run
Icon=cloud-download
Terminal=true
Categories=System;
EOF

  chmod +x "$DESKTOP_FILE"
  gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null

  echo 50
  echo "# Executando copyupdate.sh..."
  "$COPY"

  echo 80
  echo "# Executando update.sh..."
  "$UPDATE"

  echo 100
  echo "# Finalizado!"
) | zenity --progress \
  --title="Atualização do Sistema" \
  --percentage=0 \
  --auto-close \
  --width=420
}

# ===============================
# EXECUÇÃO
# ===============================
run_with_progress
exit 0
