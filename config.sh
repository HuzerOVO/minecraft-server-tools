#!/usr/bin/bash

# You can override config by this file.
if [[ -f "$HOME/.mcstrc" ]]; then
    source "$HOME/.mcstrc"
fi
# User who runs the server instace.
export CONF_USER="${CONF_USER:-gameserver}"

# Directory where all instances store in.
# NOTE:
# Do not use $HOME, if you run script with 'sudo -u $CONF_USER',
# the $HOME will not be set to $CONF_USER's home at default.
export CONF_SERVER_DIR="${CONF_SERVER_DIR:-/home/$CONF_USER/games}"

# Prefix of game server screen session
# NOTE:
# No recommand set it to empty string.
export CONF_SESSION_PREFIX="${CONF_SESSION_PREFIX:-mcst-}"

# This value can not be changed
export CONF_SCRIPTS_DIR="scripts"
export CONF_MCST_BASE=".mcst"
export CONF_MCST_INSTANCE_STATUS=".mcst/status"
export CONF_MCST_INSTANCE_GAME=".mcst/game"
export CONF_MCST_START_SCRIPT=".mcst/start.sh"
export CONF_MCST_STOP_SCRIPT=".mcst/stop.sh"
export CONF_MCST_LOG_SCRIPT=".mcst/log.sh"
