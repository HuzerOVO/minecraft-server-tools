#!/usr/bin/bash

# User who runs the server instace.
export CONF_USER="minecraft"

# Directory where all instances store in.
# NOTE:
# Do not use $HOME, if you run script with 'sudo -u $CONF_USER',
# the $HOME will not be set to $CONF_USER's home at default.
export CONF_SERVER_DIR="/home/$CONF_USER/minecraft_server"

# Prefix of Minecraft server screen session
# NOTE:
# No recommand set it to empty string.
export CONF_SESSION_PREFIX="mcs-"

# Config for start.sh
# Empry string for auto detaching.
export CONF_JAVA_BIN=""
# Java options, format: ("opt_1" "opt_2" "opt_3")
export CONF_JAVA_OPTIONS=("-Xms1024M" "-Xmx2048M")
# Minecraft server jar file name, in $CONF_SERVER_DIR
export CONF_JAR_FILE="server.jar"
# Minecraft server start options, format: ("opt_1" "opt_2" "opt_3")
export CONF_MINECRAFT_OPTIONS=("--nogui")

# Config for stop.sh
sleep_time=10
# CONF_STOP_CMD is a array of bash script command.
# You can use "cmd 'COMMAND'" to call a server command,
# use "# some thing" to add a comment.
export CONF_STOP_CMD=(
"cmd 'say The server will shut down after $sleep_time seconds.'"
"cmd 'say 服务器将在$sleep_time秒后关闭。'"
"sleep $sleep_time"
"cmd 'stop'"
)
unset sleep_time
