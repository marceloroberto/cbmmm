#!/bin/bash

# --- Variáveis ---
HOSTS_URL="https://raw.githubusercontent.com/marceloroberto/cbmmm/refs/heads/main/hosts.txt"
HOSTS_FILE="/etc/hosts"

# --- Funções de Logging e Erro ---
log_message() {
    echo -e "\n\e[32m[INFO]\e[0m $1"
}

log_error() {
    echo -e "\n\e[31m[ERRO]\e[0m $1"
    exit 1
}

# ----------------------------------------------------
# --- 0) Verificação e Instalação Condicional do Brave ---
# ----------------------------------------------------
log_message "Verificando a instalação do Brave Browser..."

if ! dpkg -s brave-browser > /dev/null 2>&1; then
    log_message "Brave Browser não encontrado. Iniciando a instalação automática..."
    
    sudo apt install curl -y > /dev/null 2>&1
    
    log_message "Adicionando chave GPG e repositório do Brave..."
    if ! sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg; then
        log_error "Falha ao baixar a chave GPG do Brave. Verifique a conexão."
    fi
    
    if ! echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=armhf] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null; then
        log_error "Falha ao adicionar o repositório do Brave."
    fi

    log_message "Atualizando listas de pacotes para incluir o Brave..."
    if ! sudo apt update; then
        log_error "Falha ao atualizar a lista de pacotes."
    fi
    
    log_message "Instalando o Brave Browser..."
    if ! sudo apt install brave-browser -y; then
        log_error "Falha ao instalar o pacote brave-browser."
    fi
    
    log_message "Brave Browser instalado com sucesso!"

else
    log_message "Brave Browser já está instalado. Prosseguindo para a atualização do sistema."
fi


# ----------------------------------------------------
# --- 1) Atualização Completa do Sistema e Pacotes ---
# ----------------------------------------------------
log_message "Iniciando a atualização completa do sistema (apt update & apt upgrade)..."

if ! sudo apt upgrade -y --fix-missing; then log_error "Falha ao atualizar os pacotes (apt upgrade)."; fi

log_message "Limpando pacotes desnecessários (autoremove & autoclean)..."
sudo apt autoremove -y
sudo apt autoclean

log_message "Atualização do sistema concluída."


# ----------------------------------------------------
# --- 2) Configuração Condicional e Reparo do Atalho do Brave ---
# ----------------------------------------------------
log_message "Configurando o Brave para abrir sempre em modo Anônimo (--incognito)..."

DESKTOP_FILES=(
    "/usr/share/applications/brave-browser.desktop"
    "/usr/share/applications/brave.desktop"
)
DEFAULT_DESKTOP_FILE="/usr/share/applications/brave-browser.desktop" 
MODIFIED=false

# --- Lógica de Edição ---
for FILE in "${DESKTOP_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        log_message "  -> Atalho existente encontrado: $FILE. Reescrevendo a linha Exec=..."
        
        # CORREÇÃO FINAL: Usa o comando 'c' (change) do sed para APAGAR a linha Exec= e INSERIR a nova linha.
        # Isso garante que a linha final seja exatamente a desejada, sem repetição de -stable.
        sudo sed -i '/^Exec=/ c\Exec=/usr/bin/brave-browser-stable %U --incognito' "$FILE"

        MODIFIED=true
        DEFAULT_DESKTOP_FILE="$FILE"
        break
    fi
done

# --- Lógica de Criação ---
if [ "$MODIFIED" = false ]; then
    log_message "  -> Nenhum atalho Brave existente encontrado. Criando novo atalho: $DEFAULT_DESKTOP_FILE"
    
    # Cria o arquivo .desktop com a sintaxe Exec correta.
    sudo tee "$DEFAULT_DESKTOP_FILE" > /dev/null << EOF
[Desktop Entry]
Encoding=UTF-8
Name=Brave Browser (Modo Anônimo)
Exec=/usr/bin/brave-browser-stable %U --incognito
Terminal=false
Type=Application
Icon=brave-browser
Categories=Network;WebBrowser;
EOF
    log_message "  -> Novo atalho criado com sucesso."
    sudo chmod 644 "$DEFAULT_DESKTOP_FILE"
fi

# Limpeza de cache
log_message "Forçando a atualização do cache dos menus do sistema..."
sudo update-desktop-database /usr/share/applications/ > /dev/null 2>&1
log_message "Configuração do Brave para modo Anônimo concluída. Reinicie a sessão para aplicar."


# ----------------------------------------------------
# --- 3) Atualizar o hosts do sistema ---
# ----------------------------------------------------
log_message "Atualizando o arquivo de hosts para bloqueio de sites..."

if ! sudo wget -O "${HOSTS_FILE}.tmp" "$HOSTS_URL"; then log_error "Falha ao baixar o novo arquivo de hosts."; fi

if [ -s "${HOSTS_FILE}.tmp" ]; then
    sudo mv "${HOSTS_FILE}.tmp" "$HOSTS_FILE"
    log_message "Arquivo de hosts atualizado com sucesso."
else
    log_error "O arquivo de hosts baixado está vazio ou inválido."
fi


# ----------------------------------------------------
# --- 4) Exclusão de todos os arquivos da Lixeira ---
# ----------------------------------------------------
log_message "Iniciando a limpeza robusta de Lixeiras em todos os diretórios /home/*..."

for USER_DIR in /home/*; do
    if [ -d "$USER_DIR" ]; then
        USERNAME=$(basename "$USER_DIR")
        USER_TRASH_FILES="$USER_DIR/.local/share/Trash/files"
        USER_TRASH_INFO="$USER_DIR/.local/share/Trash/info"
        
        log_message "Verificando Lixeira do usuário: $USERNAME"

        if [ -d "$USER_TRASH_FILES" ]; then
            log_message "  -> Limpando arquivos e metadados..."
            sudo rm -rf "$USER_TRASH_FILES"/* "$USER_TRASH_FILES"/.[^.]* 2>/dev/null || true
            sudo rm -rf "$USER_TRASH_INFO"/* "$USER_TRASH_INFO"/.[^.]* 2>/dev/null || true
            log_message "  -> Limpeza concluída."
        fi
    fi
done

if [ -d "/root/.local/share/Trash/files" ]; then
    log_message "Verificando Lixeira do usuário root..."
    sudo rm -rf /root/.local/share/Trash/files/* /root/.local/share/Trash/files/.[^.]* 2>/dev/null || true
    sudo rm -rf /root/.local/share/Trash/info/* /root/.local/share/Trash/info/.[^.]* 2>/dev/null || true
    log_message "Lixeira do root limpa."
fi

log_message "Todas as tarefas de manutenção foram concluídas com sucesso! ✅"
