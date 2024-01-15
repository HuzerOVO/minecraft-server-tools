#!/usr/bin/bash

source "config.sh"

# All functions will no do any check for instance or session.
# All functions only check their parameter.

function error_echo() {
    printf "\033[31m%s\033[0m\n" "$@"
}

function success_echo() {
    printf "\033[32m%s\033[0m\n" "$@"
}

function warn_echo() {
    printf "\033[33m%s\033[0m\n" "$@"
}

# desc: Check if screen is installed.
# return:
#   0: installed
#   1: no installed
function has_screen() {
    if which screen &> /dev/null; then 
        return 0
    else
        error_echo "Can not find 'screen', are you installed it?"
        return 1
    fi
}

# desc: Check if a instance is running
# param:
#   1: instance name
# return:
#   0: instance is running
#   1: instance is not running
function is_running() {
    if [[ -z "$1" ]]; then
        error_echo "common.is_running: Need a instance name."
        return 1
    fi

    _cli_session_file="$CONF_SERVER_DIR/$1/screen.session"
    if [[ -f "$_cli_session_file" ]]; then
        if [[ "$(cat "$_cli_session_file")" == "running" ]]; then
            return 0
        fi
    fi

    return 1
}

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

    if [[ ! -d "$CONF_SERVER_DIR" ]]; then
        error_echo "common.start: $CONF_SERVER_DIR is not a directory."
        return 1
    fi

    _cli_instance="$1"
    _cli_start_sh="$CONF_SERVER_DIR/$_cli_instance/start.sh"
    if [[ ! -f "$_cli_start_sh" ]]; then
        error_echo "common.start: Can not find start.sh($_cli_start_sh)."
        return 1
    fi

    if is_running "$_cli_instance"; then 
        warn_echo "Instance $_cli_instance is running, ignore."
        return 1
    else
        _cli_tmp_dir="$PWD"
        cd "$CONF_SERVER_DIR/$_cli_instance/" || return 1
        echo "starting" > "screen.session"
        screen -dmS "$CONF_SESSION_PREFIX$_cli_instance" bash "$CONF_SERVER_DIR/$_cli_instance/start.sh" \
            || return 1
        cd "$_cli_tmp_dir" || return 1
        success_echo "Server _cli_instance '$_cli_instance' is starting."
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

    if [[ "$1" == "" ]]; then
        error_echo "Need a instance(session) name."
        return 1
    fi

    _cli_instance="$1"
    if is_running "$_cli_instance"; then
        _cli_tmp_dir="$PWD"
        cd "$CONF_SERVER_DIR/$_cli_instance/" || return 1
        echo "closing" > "screen.session"
        screen -dmS "$CONF_SESSION_PREFIX${_cli_instance}-closer" \
            bash "$CONF_SERVER_DIR/$_cli_instance/stop.sh" "$_cli_instance" \
            || return 1
        cd "$_cli_tmp_dir" || return 1
        success_echo \
            "Server session '$_cli_instance' is closing, it may take a long time."
    else
        warn_echo "Instance $_cli_instance is not running, ignore."
        return 1
    fi

    return 0
}

# desc: Report instance status.
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function status() {
    if [[ -z "$1"  ]]; then
        error_echo "common.status: Need a instance name."
        return 1
    fi

    _cli_session_file="$CONF_SERVER_DIR/$1/screen.session"
    if [[ ! -f "$_cli_session_file" ]]; then
        error_echo "common.status: No session file for '$1'."
        return 1
    fi

    _cli_status_string="$(cat "$_cli_session_file")"
    case "$_cli_status_string" in
        starting)
            warn_echo "Minecraft server instance '$1' is staring."
            ;;
        running)
            success_echo "Minecraft Server instance '$1' is running."
            ;;
        closing)
            warn_echo "Minecraft Server instance '$1' is closing."
            ;;
        stoped)
            warn_echo "Minecraft Server instance '$1' is stoped."
            ;;
        *)
            error_echo "Unknow status: $_cli_status_string."
            return 1
    esac

    return 0
}

# desc: Show instace logs
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function logs() {
    if [[ -z "$1" ]]; then
        error_echo "common.logs: Need a instance name."
        return 1
    fi
    _log_file="$CONF_SERVER_DIR/$1/logs/latest.log"
    if [[ -f "$_log_file" ]]; then
        cat "$_log_file" || return 1
    else 
        error_echo "common.logs: No log file: $_log_file."
        return 1
    fi
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

    shift
    if [[ -z "$*" ]]; then
        warn_echo "No command, ignore."
        return 1
    fi
    screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X \
        eval "stuff \"$(printf '%s\r\n' "$*")\"" || return 1;
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
    _cli_grep_reg="$CONF_SESSION_PREFIX"
    if [[ -z "$_cli_grep_reg" ]]; then
        _cli_grep_reg="Detached|Attached"
    fi
    screen -list | while read -r _cli_line; do
        _cli_session="$(echo "$_cli_line" | \
            # find session
            grep -E "$_cli_grep_reg" | \
            # ignore sessiong that stops a instance
            grep -v -E ".*?-closer" | \
            # get instance name
            sed -E -r 's/^[0-9].*?\.//' | \
            # remove session prefix
            grep -E "^$CONF_SESSION_PREFIX" | \
            sed -E -r "s/^$CONF_SESSION_PREFIX//" | \
            # display session name
            awk '{ printf $1 }')"
        if [[ -n "$_cli_session" ]]; then
            echo "$_cli_session"
        fi  
    done
    return 0
}

# desc: List all available instance.
# return:
#   0: no error
#   1: error
# note: no message if there is a error.
function list_instances() {
    if [[ -d "$CONF_SERVER_DIR" ]]; then
        for _cli_instance in "$CONF_SERVER_DIR"/*; do
            if [[ -d "$_cli_instance" ]]; then
                echo "${_cli_instance##*/}"
            fi
        done
    else
        return 1
    fi

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
    for _cli_session in $(list_sessions); do
        if [[ "$_cli_session" == "$1" ]]; then
            return 0
        fi
    done
    return 1
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
    for _cli_instance in $(list_instances); do
        if [[ "$_cli_instance" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# desc: Generate start.sh.
function generate_start_script() {
    if [[ -z "$CONF_JAVA_BIN" ]]; then
    if ! which java &> /dev/null; then
        error_echo "Can not find 'java' in your environment variable PATH, 
            please specified it in config.sh by JAVA_BIN"
        return 1
    fi
    CONF_JAVA_BIN="$(which java)"
    fi
    cat<<__EOF__
#!/usr/bin/bash

function die() {
    update_status "stopped"
    exit 1
}

function update_status() {
    echo "\$*" > "$CONF_SERVER_DIR/$1/screen.session"
}

update_status "running"

$CONF_JAVA_BIN ${CONF_JAVA_OPTIONS[@]} \\
    -jar "$CONF_JAR_FILE" ${CONF_MINECRAFT_OPTIONS[@]} \\
    || die

update_status "stoped"

exit 0

__EOF__
return 0
}

# desc: Generate stop.sh
function generate_stop_script() {
cat<<__EOF__
#!/usr/bin/bash

function cmd () {
    screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}

# Update status
echo "closing" > "screen.session"

# stop command
__EOF__
for _cli_command in "${CONF_STOP_CMD[@]}"; do
    echo "$_cli_command"
done
}

# desc: Generate scripts for a instance.
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function generate_scripts() {
    if [[ -z "$1" ]]; then
        error_echo "common.generate_script: Need a instance name."
        return 2
    fi

    _cli_instance="$1"
    _cli_instance_path="$CONF_SERVER_DIR/$_cli_instance"
    generate_start_script "$_cli_instance" > "$_cli_instance_path/start.sh"
    generate_stop_script "$_cli_instance" > "$_cli_instance_path/stop.sh"
}
