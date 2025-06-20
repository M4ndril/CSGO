###########################################################
# Dockerfile that builds a CSGO Gameserver
###########################################################
FROM cm2network/steamcmd:root as build_stage

LABEL maintainer="walentinlamonos@gmail.com"

# >>> ESTAS LINHAS SÃO CRÍTICAS E DEVEM ESTAR AQUI NO DOCKERFILE <<<
ENV HOMEDIR="/home/steam"
ENV USER="steam"
# >>> FIM DAS LINHAS CRÍTICAS <<<

ENV STEAMAPPID 740
ENV STEAMAPP csgo
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV DLURL https://raw.githubusercontent.com/CM2Walki/CSGO

# Adicionamos uma verificação para ver o valor de HOMEDIR durante o build
RUN echo "DEBUG: HOMEDIR during build is: ${HOMEDIR}"

# Agora o COPY saberá exatamente onde copiar o entry.sh
COPY bullseye/etc/entry.sh "${HOMEDIR}/entry.sh"

# Adicionamos verificações após o COPY
RUN echo "DEBUG: Content of ${HOMEDIR} after COPY:" && ls -la "${HOMEDIR}/" && \
    echo "DEBUG: Content of entry.sh after COPY:" && cat "${HOMEDIR}/entry.sh"

COPY bullseye/etc/csgo "/etc/csgo"

RUN set -x \
	# Instala, atualiza e faz upgrade de pacotes.
	&& apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        wget \
        ca-certificates \
        lib32z1 \
	# Cria o diretório para a instalação do CS:GO.
	&& mkdir -p "${STEAMAPPDIR}" \
	# Adiciona o script de atualização do SteamCMD para o HOMEDIR
	&& { \
		echo '@ShutdownOnFailedCommand 1'; \
		echo '@NoPromptForPassword 1'; \
		echo 'force_install_dir '"${STEAMAPPDIR}"''; \
		echo 'login anonymous'; \
		echo 'app_update '"${STEAMAPPID}"''; \
		echo 'quit'; \
	   } > "${HOMEDIR}/${STEAMAPP}_update.txt" \
	# Garante permissão de execução e o proprietário correto para o entry.sh no HOMEDIR
	&& chmod +x "${HOMEDIR}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" "${HOMEDIR}/${STEAMAPP}_update.txt" \
	# Adicionamos uma verificação final de permissões e proprietário
	&& echo "DEBUG: Permissions of entry.sh after chmod/chown:" && ls -la "${HOMEDIR}/entry.sh" \
	# Limpeza
	&& rm -rf /var/lib/apt/lists/*

FROM build_stage AS bullseye-base

# Variáveis de ambiente para configuração do servidor CS:GO
ENV SRCDS_FPSMAX=300 \
	SRCDS_TICKRATE=128 \
	SRCDS_PORT=27015 \
	SRCDS_TV_PORT=27020 \
	SRCDS_CLIENT_PORT=27005 \
	SRCDS_NET_PUBLIC_ADDRESS="0" \
	SRCDS_IP="0" \
	SRCDS_LAN="0" \
	SRCDS_MAXPLAYERS=14 \
	SRCDS_TOKEN=0 \
	SRCDS_RCONPW="changeme" \
	SRCDS_PW="changeme" \
	SRCDS_STARTMAP="de_dust2" \
	SRCDS_REGION=3 \
	SRCDS_MAPGROUP="mg_active" \
	SRCDS_GAMETYPE=0 \
	SRCDS_GAMEMODE=1 \
	SRCDS_HOSTNAME="New \"${STEAMAPP}\" Server" \
	SRCDS_WORKSHOP_START_MAP=0 \
	SRCDS_HOST_WORKSHOP_COLLECTION=0 \
	SRCDS_WORKSHOP_AUTHKEY="" \
	ADDITIONAL_ARGS=""

# Altera para o usuário especificado
USER ${USER}

# Define o diretório de trabalho. O CMD será executado a partir daqui.
WORKDIR ${HOMEDIR}

# Comando para iniciar o servidor. Usamos o caminho absoluto para garantir que seja encontrado.
CMD ["bash", "${HOMEDIR}/entry.sh"]

# Expõe as portas necessárias
EXPOSE 27015/tcp \
	27015/udp \
	27020/udp

FROM bullseye-base AS bullseye-metamod

ENV METAMOD_VERSION 1.11

FROM bullseye-metamod AS bullseye-sourcemod

ENV SOURCEMOD_VERSION 1.11
