#!/usr/bin/bash

source "builtin.sh"

# All functions only check their parameter.
# All functions in this file can be used by mcscli and mcsshell.
# All config options should be checked by mcscli and mcsshell.

# desc: Start a instance
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function start() {
    if ! has_screen; then
        return 1
    fi

    if [[ -z "$1" ]]; then
        error_echo "common.start: Need a instance name."
        return 1
    fi

    if is_running "$1"; then 
        warn_echo "Instance $1 is running, ignore."
        return 1
    else
        _common_start_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_START_SCRIPT"

        # Check file start.sh
        if [[ ! -f "$_common_start_sh" ]]; then
            error_echo "common.start: Can not find start.sh(should at $_common_start_sh)."
            warn_echo "If you are running a unsupported game, writing the script by yourself."
            unset _common_start_sh
            return 1
        fi

        _common_tmp_dir="$PWD"
        cd "$CONF_SERVER_DIR/$1/" || return 1
        # Working in instance directory
        echo "starting" > "$CONF_MCST_INSTANCE_STATUS"
        screen -dmS "$CONF_SESSION_PREFIX$1" bash "$_common_start_sh" || return 1

        cd "$_common_tmp_dir" || return 1
        unset _common_start_sh
        unset _common_tmp_dir
        success_echo "Server instance '$1' is starting."
    fi

    return 0
}

# desc: Stop a instance
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function stop() {
    if ! has_screen; then
        return 1
    fi

    if [[ -z "$1" ]]; then
        error_echo "Need a instance(session) name."
        return 1
    fi

    if is_running "$1"; then
        _common_stop_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_STOP_SCRIPT"
        # Check file stop.sh
        if [[ ! -f "$_common_stop_sh" ]]; then
            error_echo "common.stop: Can not find stop.sh(should at $_common_stop_sh)."
            warn_echo "If you are running a unsupported game, writing the script by yourself."
            unset _common_stop_sh
            return 1
        fi
        _common_tmp_dir="$PWD"
        cd "$CONF_SERVER_DIR/$1/" || return 1
        # Working in instance directory
        echo "closing" > "$CONF_MCST_INSTANCE_STATUS"
        screen -dmS "$CONF_SESSION_PREFIX${1}-closer" bash "$_common_stop_sh" || return 1

        cd "$_common_tmp_dir" || return 1
        unset _common_tmp_dir
        unset _common_stop_sh
        success_echo "Server session '$1' is closing, it may take a long time."
    else
        warn_echo "Instance $1 is not running, ignore."
        return 1
    fi

    return 0
}

# desc: Report instance status.
# param:
#   1: instance name
function status() {
    if [[ -z "$1"  ]]; then
        error_echo "common.status: Need a instance name."
        return 1
    fi

    _common_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_INSTANCE_STATUS"
    if [[ ! -f "$_common_status_file" ]]; then
        error_echo "common.status: No session file for '$1'."
        return 1
    fi

    _common_status_string="$(cat "$_common_status_file")"
    case "$_common_status_string" in
        starting)
            warn_echo "Game server instance '$1' is staring."
            ;;
        running)
            success_echo "Game server instance '$1' is running."
            ;;
        closing)
            warn_echo "Game server instance '$1' is closing."
            ;;
        stopped)
            warn_echo "Game server instance '$1' is stopped."
            ;;
        *)
            error_echo "Unknow status: $_common_status_string."
    esac

    unset _common_status_file
    unset _common_status_string
    return 0
}

function update() {
    if [[ -z "$1"  ]]; then
        error_echo "common.upgrade: Need a instance name."
        return 1
    fi

    run_script "$1" "update"
    return 0
}

function reload() {
    if [[ -z "$1"  ]]; then
        error_echo "common.reload: Need a instance name."
        return 1
    fi

    if ! is_running "$1"; then
        warn_echo "Try to reload a instance that is not running."
    fi
    run_script "$1" "reload"
    return 0
}

function custom_script() {
    if [[ -z "$1" ]]; then 
        error_echo "common.script: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "common.script: Need a script(operation) name."
    fi

    run_script "$1" "$2"
    return 0
}
# desc: Execute Server command in a instace(session).
# param:
#   1: instance name
#   2: server command
# return:
#   0: no error
#   1: error
function cmd() {
    if ! has_screen; then
        return 1
    fi

    if [[ -z "$1" ]]; then
        error_echo "common.cmd: Need a instance(session) name."
        return 1
    fi

    _common_session="$1"
    shift
    if [[ -z "$*" ]]; then
        warn_echo "No command, ignore."
        return 1
    fi
    screen -p 0 -S "$CONF_SESSION_PREFIX$_common_session" -X \
        eval "stuff \"$(printf '%s\r\n' "$*")\"" || return 1;
    unset _common_session
    return 0
}

# desc: List all available screen session.
# return:
#   0: no error
#   1: error
# note: no message if there is a error.
function list_sessions() {
    if ! has_screen; then 
        return 1
    fi
    _common_grep_reg="$CONF_SESSION_PREFIX"
    if [[ -z "$_common_grep_reg" ]]; then
        _common_grep_reg="Detached|Attached"
    fi
    screen -list | while read -r _common_line; do
        _common_session="$(echo "$_common_line" | \
            # find session
            grep -E "$_common_grep_reg" | \
            # ignore sessiong that stops a instance
            grep -v -E ".*?-closer" | \
            # get instance name
            sed -E -r 's/^[0-9].*?\.//' | \
            # remove session prefix
            grep -E "^$CONF_SESSION_PREFIX" | \
            sed -E -r "s/^$CONF_SESSION_PREFIX//" | \
            # display session name
            awk '{ printf $1 }')"
        if [[ -n "$_common_session" ]]; then
            echo "$_common_session"
        fi  
    done
    return 0
}

# desc: Check if a session exist.
# param:
#   1: session name
# return:
#   0: has this session
#   1: no this session
#   2: error
function has_session() {
    if [[ -z "$1" ]]; then
        error_echo "common.has_session: Need a session name."
        return 2
    fi
    for _common_session in $(list_sessions); do
        if [[ "$_common_session" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# desc: List all available instance.
# note: no message if there is nothing.
function list_instances() {
    for _common_instance in "$CONF_SERVER_DIR"/*; do
        if [[ -d "$_common_instance" ]]; then
            echo "${_common_instance##*/}"
        fi
    done
    unset _common_instance
}

# desc: Check if a instace exist.
# param:
#   1: instace name
# return:
#   0: has this instace
#   1: no this instace
#   2: error
function has_instance() {
    if [[ -z "$1" ]]; then
        error_echo "common.has_instance: Need a instance name."
        return 2
    fi
    for _common_instance in $(list_instances); do
        if [[ "$_common_instance" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# desc: List all supported game
function list_supported_games() {
    for _common_game in "$CONF_SCRIPTS_DIR"/*; do
        echo "${_common_game##*/}"
    done
}

# desc: Check if it is a supported game.
# param:
#   1: game name
# return:
#   0: supported
#   1: unsupported
function is_supported_game() {
    if [[ -z "$1" ]]; then
        error_echo "common.is_supported_game: Need a game name."
        return 1
    fi

    for _common_game in $(list_supported_games); do
        if [[ "$1" == "$_common_game" ]]; then
            unset _common_game
            return 0
        fi
    done

    unset _common_game
    return 1
}

# desc: Generate some scripts for instance.
function generate_scripts() {
    if [[ -z "$1" ]]; then 
        error_echo "common.init: Need a instance name."
        return 1
    fi

    if [[ ! -d "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE" ]]; then
        error_echo "No a initialized instance: $1."
        return 1
    fi

    _common_game="$(cat "$CONF_SERVER_DIR/$1/$CONF_MCST_INSTANCE_GAME")"
    if [[ -z "$_common_game" ]]; then
        error_echo "Can not get game type for $1."
    fi
    generate_start_script "$1" "$_common_game" > "$CONF_SERVER_DIR/$1/$CONF_MCST_START_SCRIPT"
    generate_stop_script "$1" "$_common_game" > "$CONF_SERVER_DIR/$1/$CONF_MCST_STOP_SCRIPT"
    generate_others "$1" "$_common_game"
    return 0
}

# desc: Initialize a instance.
function init () {
    if [[ -z "$1" ]]; then 
        error_echo "common.init: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "common.init: Need a game type."
        return 1
    fi

    mkdir -p "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"
    if ! is_supported_game "$2"; then
        warn_echo "You are initializing a unsupported game."
        warn_echo "Please writing your script in:"
        warn_echo "  $CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh.override,"
        warn_echo "  $CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.sh.override,"
        warn_echo "and use 'generate-scripts' command to update scripts."
    fi
    echo "$2" > "$CONF_SERVER_DIR/$1/$CONF_MCST_INSTANCE_GAME"
    generate_scripts "$1"
    echo "stopped" > "$CONF_SERVER_DIR/$1/$CONF_MCST_INSTANCE_STATUS"

    return 0
}
