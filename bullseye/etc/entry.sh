#!/bin/bash

# Define o caminho do diretório principal
HOMEDIR="/home/steam"
USER="steam" # Adiciona a variável USER aqui para ser usada no entry.sh

# Define o diretório de instalação do CS:GO
STEAMAPPID=740
STEAMAPP=csgo
STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"

# Arquivo de atualização do SteamCMD
STEAMCMD_UPDATE_FILE="${HOMEDIR}/${STEAMAPP}_update.txt"

# Caminho completo para o executável srcds_run
SRCDS_RUN="${STEAMAPPDIR}/srcds_run"

# Logar o início do script e as variáveis
echo "DEBUG: entry.sh started."
echo "DEBUG: HOMEDIR=${HOMEDIR}"
echo "DEBUG: STEAMAPPDIR=${STEAMAPPDIR}"
echo "DEBUG: SRCDS_RUN=${SRCDS_RUN}"

# Verificar se o diretório do jogo existe, caso contrário, criar
if [ ! -d "${STEAMAPPDIR}" ]; then
    echo "Creating game directory: ${STEAMAPPDIR}"
    mkdir -p "${STEAMAPPDIR}"
    # Definir permissões iniciais para o diretório
    chown -R ${USER}:${USER} "${HOMEDIR}"
fi

# Gerar o arquivo de atualização do SteamCMD se não existir (ou sempre, para garantir)
echo "@ShutdownOnFailedCommand 1" > "${STEAMCMD_UPDATE_FILE}"
echo "@NoPromptForPassword 1" >> "${STEAMCMD_UPDATE_FILE}"
echo "force_install_dir ${STEAMAPPDIR}" >> "${STEAMCMD_UPDATE_FILE}"
echo "login anonymous" >> "${STEAMCMD_UPDATE_FILE}"
echo "app_update ${STEAMAPPID}" >> "${STEAMCMD_UPDATE_FILE}"
echo "quit" >> "${STEAMCMD_UPDATE_FILE}"

# Certificar-se de que o arquivo de atualização pertence ao usuário steam
chown ${USER}:${USER} "${STEAMCMD_UPDATE_FILE}"

# Loop de atualização e inicialização do servidor
while true; do
    echo "$(date): Updating server using Steam."
    echo "----------------------------"

    # Executar o SteamCMD para atualizar o jogo
    # Redirecionar a entrada padrão para o arquivo de atualização
    "${HOMEDIR}/steamcmd/steamcmd.sh" +runscript "${STEAMCMD_UPDATE_FILE}"
    
    # ****************** ADICIONAR ESTA LINHA AQUI ******************
    # Garantir que todos os binários dentro do diretório do jogo sejam executáveis
    echo "DEBUG: Setting execute permissions for all files in ${STEAMAPPDIR}."
    chmod -R +x "${STEAMAPPDIR}" # Isso irá definir a permissão de execução para todos os arquivos

    echo "----------------------------"

    # Verificar se o srcds_run existe antes de tentar executá-lo
    if [ ! -f "${SRCDS_RUN}" ]; then
        echo "ERROR: ${SRCDS_RUN} not found! Cannot start server. Please check SteamCMD download."
        echo "Will retry update in 10 seconds."
        sleep 10
        continue
    fi

    echo "$(date): Starting SRCDS..."

    # Iniciar o servidor CS:GO
    # Certifique-se de que as variáveis de ambiente SRCDS_* estejam definidas no Dockerfile ou aqui
    # Exemplo: (SRCDS_PORT, SRCDS_MAXPLAYERS, etc.)

    # Navegar para o diretório do jogo para que o ./srcds_linux funcione corretamente
    cd "${STEAMAPPDIR}" || { echo "Failed to change directory to ${STEAMAPPDIR}"; exit 1; }

    # Executar o servidor de jogo
    # Use 'exec' para substituir o processo bash pelo processo do srcds_run, o que é bom para Docker
    exec "${SRCDS_RUN}" \
        -console \
        -autoupdate \
        -steamcmd \
        -strictportbind \
        -ip "${SRCDS_IP}" \
        -port "${SRCDS_PORT}" \
        +clientport "${SRCDS_CLIENT_PORT}" \
        +tv_port "${SRCDS_TV_PORT}" \
        -maxplayers "${SRCDS_MAXPLAYERS}" \
        -tickrate "${SRCDS_TICKRATE}" \
        +game_type "${SRCDS_GAMETYPE}" \
        +game_mode "${SRCDS_GAMEMODE}" \
        +mapgroup "${SRCDS_MAPGROUP}" \
        +map "${SRCDS_STARTMAP}" \
        +sv_setsteamaccount "${SRCDS_TOKEN}" \
        +rcon_password "${SRCDS_RCONPW}" \
        +sv_password "${SRCDS_PW}" \
        -net_public_address "${SRCDS_NET_PUBLIC_ADDRESS}" \
        -authkey "${SRCDS_WORKSHOP_AUTHKEY}" \
        +host_workshop_collection "${SRCDS_HOST_WORKSHOP_COLLECTION}" \
        +workshop_start_map "${SRCDS_WORKSHOP_START_MAP}" \
        ${ADDITIONAL_ARGS} # Adicione esta linha para passar argumentos adicionais

    # Se o servidor parar (o comando 'exec' acima falhar ou o processo srcds_run sair)
    echo "$(date): Server stopped. Restarting in 10 seconds."
    sleep 10 # Tempo para o Docker reiniciar ou para o próximo loop
done
