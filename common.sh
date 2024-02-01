#!/usr/bin/bash

source "builtin.sh"

# All functions only check their parameter.
# All functions in this file can be used by mcscli and mcsshell.
# All config options should be checked by mcscli and mcsshell.

# desc: Start a instance server
# note: This function only start a specified server,
#       it will go failed if you try to start a sub sever instance 
#       without a sub server name,
# param:
#   1: instance name
#   2(opt): sub server name
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

    if ! is_stopped "$1" "$2"; then
        warn_echo "Server is not stopped, ignore."
        return 1
    fi

    local _common_start_sh
    local _common_session_name
    local _common_status
    local _common_msg
    # Get start script
    if [[ -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh" ]]; then
        # if there is 'start.sh', use it
        _common_start_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh"
        _common_session_name="$CONF_SESSION_PREFIX$1"
        _common_status="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"
        _common_msg="Instance $1 is starting."
    elif [[ -n "$2" ]]; then
        # try to start a sub server
        _common_start_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.$2.sh"
        _common_session_name="$CONF_SESSION_PREFIX$1-$2"
        _common_status="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status.$2"
        _common_msg="Instance $1 sub server $2 is starting."
    else 
        # do nothing, this function only start a server
        error_echo "Can not find any start script, you may have to specify a sub server."
        return 1
    fi

    if has_session "$_common_session_name"; then
        if [[ -n "$2" ]]; then
            error_echo "Instace $1 sub server $3 is stopped, but there is a running session."
        else
            error_echo "Instance $1 is stopped, but there is a running session."
        fi
        return 1
    fi

    # Start server
    if [[ ! -f "$_common_start_sh" ]]; then
        error_echo "Can not find start scritp($_common_start_sh)."
        error_echo "Do you generate it?"
        return 1
    fi

    # go into instance directory
    local _common_tmp_dir="$PWD"
    cd "$CONF_SERVER_DIR/$1/" || return 1

    echo "starting" > "$_common_status"
    screen -dmS "$_common_session_name" bash "$_common_start_sh"
    success_echo "$_common_msg"
    # go back to working directory
    cd "$_common_tmp_dir" || return 1

    return 0
}

# desc: Stop a instance
# note: Like function start, it only stop a specified server.
# param:
#   1: instance name
#   2(opt): sub server name
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


    # Get stop script
    local _common_stop_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.sh"
    local _common_session_name="$CONF_SESSION_PREFIX$1-closer"
    local _common_status="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"
    local _common_msg="Instance $1 is closing."
    if [[ -n "$2" ]]; then
        _common_stop_sh="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.$2.sh"
        _common_session_name="$CONF_SESSION_PREFIX$1-$2-closer"
        _common_status="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status.$2"
        _common_msg="Instance $1 sub server $2 is closing."
        if ! is_running "$1" "$2"; then
            warn_echo "Sub server $2 for instance $1 is not running, ignore."
            return 1
        fi
    else
        if ! is_running "$1"; then
            warn_echo "Instance $1 is not running, ignore."
            return 1
        fi
    fi

    # Check file stop.sh
    if [[ ! -f "$_common_stop_sh" ]]; then
        error_echo "common.stop: Can not find stop.sh($_common_stop_sh)."
        warn_echo "If you are running a unsupported game, writing the script by yourself."
        return 1
    fi
    local _common_tmp_dir="$PWD"
    cd "$CONF_SERVER_DIR/$1/" || return 1

    # Working in instance directory
    echo "closing" > "$_common_status"

    screen -dmS "$_common_session_name" bash "$_common_stop_sh"
    success_echo "$_common_msg"

    cd "$_common_tmp_dir" || return 1

    return 0
}

# desc: Report instance status.
# param:
#   1: instance name
#   2(opt): sub server name
function status() {
    if [[ -z "$1"  ]]; then
        error_echo "common.status: Need a instance name."
        return 1
    fi

    local _common_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"
    local _common_msg="Instance '$1' is"

    if [[ -n "$2" ]]; then
        _common_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status.$2"
        _common_msg="sub server '$2' is"
    fi
    if [[ ! -f "$_common_status_file" ]]; then
        error_echo "common.status: No session file for '$1'."
        return 1
    fi

    local _common_status_string
    _common_status_string="$(cat "$_common_status_file")"
    case "$_common_status_string" in
        starting | running)
            success_echo "$_common_msg $_common_status_string"
            ;;
        closing | stopped)             
            warn_echo "$_common_msg $_common_status_string"
            ;;
        *)
            error_echo "Unknow status: $_common_status_string."
            ;;
    esac

    return 0
}

# desc: Update server
# param:
#   1: instance
#   2(opt): sub server name
# return:
#   0: no error
#   1: error
function update() {
    if [[ -z "$1"  ]]; then
        error_echo "common.upgrade: Need a instance name."
        return 1
    fi

    script_run "$1" "update" "$2" || return 1

    return 0
}

# desc: Reload server
# param:
#   1: instance
#   2(opt): sub server name
# return:
#   0: no error
#   1: error
function reload() {
    if [[ -z "$1"  ]]; then
        error_echo "common.reload: Need a instance name."
        return 1
    fi

    script_run "$1" "reload" "$2" || return 1

    return 0
}

# desc: Run custom script in a server
# param:
#   1: instance
#   2: script (operation)
#   3(opt): sub server name
# return:
#   0: no error
#   1: error
function custom_script() {
    if [[ -z "$1" ]]; then 
        error_echo "common.script: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "common.script: Need a script(operation) name."
    fi

    script_run "$1" "$2" "$3" || return 1

    return 0
}

# desc: Execute Server command in a instace(session).
# param:
#   1: session name
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

    local _common_session_name="$1"
    shift
    if [[ -z "$*" ]]; then
        warn_echo "No command, ignore."
        return 1
    fi
    screen -p 0 -S "$CONF_SESSION_PREFIX$_common_session_name" -X \
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
    local _common_grep_reg="$CONF_SESSION_PREFIX"
    if [[ -z "$_common_grep_reg" ]]; then
        _common_grep_reg="Detached|Attached"
    fi
    local _common_line
    local _common_session
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
    local _common_session
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
    local _common_instance
    for _common_instance in "$CONF_SERVER_DIR"/*; do
        if [[ -d "$_common_instance" ]]; then
            echo "${_common_instance##*/}"
        fi
    done
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
    local _common_instance
    for _common_instance in $(list_instances); do
        if [[ "$_common_instance" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# desc: List sub server for a instance.
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function list_sub_server() {
    if [[ -z "$1" ]]; then
        return 1
    fi

    # If there is a file named 'start.sh', it has not sub instance.
    if [[ -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh" ]]; then
        return 0
    fi

    local _common_sub
    for _common_sub in "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"/start.*.sh; do
        if [[ ! -f "$_common_sub" ]]; then
            continue
        fi

        _common_sub="${_common_sub##*/}"
        _common_sub="${_common_sub%.sh}"
        _common_sub="${_common_sub#start.}"
        echo "$_common_sub"
    done

    return 0
}

# desc: Check if the instance has a specified sub server
# param:
#   1: instance name
#   2: sub server name
# return:
#   0: yes, instance $1 has sun server $2
#   1: no
#   2: error
function has_sub_server() {
    if [[ -z "$1" ]]; then
        error_echo "Need a instance name."
        return 2
    fi

    if [[ -z "$2" ]]; then
        error_echo "Need a sub server name."
        return 2
    fi

    local _common_sub
    for _common_sub in $(list_sub_server "$1"); do
        if [[ "$_common_sub" == "$2" ]]; then
            return 0
        fi
    done

    return 1
}

# desc: Check if the instance has any sub server
# param:
#   1: instance name
# return:
#   0: yes, instance has one or more sub servers
#   1: no, instance is a single server instance
#   2: error
function is_sub_server_instance() {
    if [[ -z "$1" ]]; then
        error_echo "common.is_sub_server_instance: Need a instance name."
        return 2
    fi

    local _common_game
    _common_game="$(cat "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/game")"
    if [[ -z "$_common_game" ]]; then
        error_echo "common.is_sub_server_instance: Can not get game type name."
        return 2
    fi

    # force a single server by 'start.sh'
    if [[ -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh" ]]; then
        return 1
    fi

    if is_supported_game "$_common_game"; then
        if [[ -f "$CONF_SCRIPTS_DIR/$_common_game/start.sh" ]]; then
            return 1
        fi

        if [[ -d "$CONF_SCRIPTS_DIR/$_common_game/sub" ]]; then
            return 0
        fi
        return 2
    fi

    # if it is a unsupported game instance, user can configurate is as a sub server 
    if [[ -d "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/sub" ]]; then
        return 0
    fi

    return 2
}

# desc: List all supported game
function list_supported_games() {
    local _common_game
    for _common_game in "$CONF_SCRIPTS_DIR"/*; do
        echo "${_common_game##*/}"
    done
}

# desc: Check if it is a supported game.
# param:
#   1: game type name
# return:
#   0: supported
#   1: unsupported
function is_supported_game() {
    if [[ -z "$1" ]]; then
        error_echo "common.is_supported_game: Need a game type name."
        return 1
    fi

    local _common_game
    for _common_game in $(list_supported_games); do
        if [[ "$1" == "$_common_game" ]]; then
            return 0
        fi
    done

    return 1
}

# desc: Generate some scripts for instance.
# param:
#   1: instance name
# return:
#   0: no error
#   1: error
function generate_scripts() {
    if [[ -z "$1" ]]; then 
        error_echo "common.init: Need a instance name."
        return 1
    fi

    if [[ ! -d "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE" ]]; then
        error_echo "No a initialized instance: $1."
        return 1
    fi

    local _common_base="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"
    local _common_game
    _common_game="$(cat "$_common_base/game")"
    if [[ -z "$_common_game" ]]; then
        error_echo "Can not get game type name for $1."
        return 1
    fi

    # clear all old scripts
    local _common_old_script
    for _common_old_script in "$_common_base"/*.sh; do
        if [[ ! -f "$_common_old_script" ]]; then
            continue
        fi
        mv "$_common_old_script" "${_common_old_script}.old"
    done

    local _common_script
    local _common_script_name
    local _common_session_name
    # If it is a supported game, generate the default scripts first.
    if is_supported_game "$_common_game"; then
        success_echo "Generating default scripts for instance '$1'."
        # If it is a sub server instance
        if [[ -d "$CONF_SCRIPTS_DIR/$_common_game/sub" ]]; then
            local _common_sub_base="$CONF_SCRIPTS_DIR/$_common_game/sub"
            # generate start.sh and stop.sh for sub server
            local _common_sub
            for _common_sub in "$_common_sub_base"/*; do
                if [[ ! -d "$_common_sub" ]]; then
                    continue
                fi

                _common_sub="${_common_sub##*/}"
                success_echo "  - generating for sub server '$_common_sub'"

                _common_session_name="$CONF_SESSION_PREFIX$1-$_common_sub"
                _common_sub="${_common_sub##*/}"

                # start.sh
                _common_script="$_common_sub_base/$_common_sub/start.sh"
                if [[ ! -f "$_common_script" ]]; then
                    error_echo "Can not find default start script for sub server $_common_sub in instance $1."
                    error_echo "  At $_common_script"
                    continue
                fi
                warn_echo "    $_common_script > start.$_common_sub.sh"
                generate_script_start "$1" "status.${_common_sub}" "$_common_script" > "$_common_base/start.$_common_sub.sh"

                # stop.sh 
                _common_script="$_common_sub_base/$_common_sub/stop.sh"
                if [[ ! -f "$_common_script" ]]; then
                    error_echo "Can not find default stop script for sub server $_common_sub in instance $1."
                    error_echo "  At $_common_script"
                    continue
                fi
                warn_echo "    $_common_script > stop.$_common_sub.sh"
                generate_script_stop "$1" "status.${_common_sub}" "$_common_session_name" "$_common_script" > "$_common_base/stop.$_common_sub.sh"

                # generate the default scripts for the sub server 
                for _common_script in "$_common_sub_base/$_common_sub"/*.sh; do
                    if [[ ! -f "$_common_script" ]]; then
                        continue
                    fi

                    _common_script_name="${_common_script##*/}"
                    case "$_common_script_name" in
                        start.sh | stop.sh)
                            continue
                            ;;
                        *)
                            _common_script_name="${_common_script_name%.sh}"
                            _common_script_name="${_common_script_name}.${_common_sub}.sh"
                            warn_echo "    $_common_script > $_common_script_name"
                            generate_script_others "$1" "status.$_common_sub" "$_common_session_name" "$_common_script" > "$_common_base/$_common_script_name"
                    esac
                done # END generate others scripts
            done # END for all sub servers
        # It is not a sub server instance, generate the default scripts.
        else
            success_echo "  - generating for single server"
            _common_session_name="$CONF_SESSION_PREFIX$1"
            # start.sh
            _common_script="$CONF_SCRIPTS_DIR/$_common_game/start.sh"
            _common_script_name="${_common_script##*/}"
            if [[ ! -f "$_common_script" ]]; then
                error_echo "Can not find default start script for instance $1."
                error_echo "  At $_common_script"
            fi
            warn_echo "    $_common_script > $_common_script_name"
            generate_script_start "$1" "status" "$_common_script" > "$_common_base/$_common_script_name"

            # stop.sh
            _common_script="$CONF_SCRIPTS_DIR/$_common_game/stop.sh"
            _common_script_name="${_common_script##*/}"
            if [[ ! -f "$_common_script" ]]; then
                error_echo "Can not find default stop script for instance $1."
                error_echo "  At $_common_script"
            fi
            warn_echo "    $_common_script > $_common_script_name"
            generate_script_stop "$1" "status" "$_common_session_name" "$_common_script" > "$_common_script_name"

        fi # END if [[ -d "$CONF_SCRIPTS_DIR/$_common_game/sub" ]]

        # generate root scripts
        success_echo "  - generating root scripts"
        for _common_script in "$CONF_SCRIPTS_DIR/$_common_game"/*.sh; do
            if [[ ! -f "$_common_script" ]]; then
                continue
            fi

            _common_script_name="${_common_script##*/}"
            case "$_common_script_name" in
                # skip start.sh and stop.sh
                start.sh | stop.sh)
                    continue
                    ;;
                *)
                    warn_echo "    $_common_script > $_common_script_name"
                    generate_script_others "$1" "status" "$_common_session_name" "$_common_script" > "$_common_base/$_common_script_name"
            esac
        done
    fi # END if is_suppoered_game

    # Generate user override, user can use the override file to custom an unsupported game.

    success_echo "Generating user scripts override for instance $1"
    # has sub server override
    if [[ -d "$_common_base/sub" ]]; then
        for _common_sub in "$_common_base/sub"/*; do
            if [[ ! -d "$_common_sub" ]]; then
                continue
            fi
            _common_sub="${_common_sub##*/}"
            success_echo "  - generating for sub server '$_common_sub'"
            _common_session_name="$CONF_SESSION_PREFIX$1-$_common_sub"
            for _common_script in "$_common_base/sub/$_common_sub"/*.override; do
                if [[ ! -f "$_common_script" ]]; then
                    continue
                fi
                _common_script_name="${_common_script##*/}"
                _common_script_name="${_common_script_name%.override}"
                case "$_common_script_name" in
                    start.sh)
                        warn_echo "    $_common_script > start.$_common_sub.sh"
                        generate_script_start "$1" "status.${_common_sub}" "$_common_script" > "$_common_base/start.${_common_sub}.sh"
                        ;;
                    stop.sh)
                        warn_echo "    $_common_script > stop.$_common_sub.sh"
                        generate_script_stop "$1" "status.${_common_sub}" "$_common_session_name" "$_common_script" > "$_common_base/stop.${_common_sub}.sh"
                        ;;
                    *)
                        _common_script_name="${_common_script_name%.sh}.${_common_sub}.sh"
                        warn_echo "    $_common_script > $_common_script_name"
                        generate_script_others "$1" "status.${_common_sub}" "$_common_session_name" "$_common_script" > "$_common_base/$_common_script_name"
                        ;;
                esac
            done
        done
    fi

    success_echo "  - generating root scripts override"
    for _common_script in "$_common_base"/*.override; do
        if [[ ! -f "$_common_script" ]]; then
            continue
        fi
        _common_script_name="${_common_script##*/}"
        _common_script_name="${_common_script_name%.override}"
        case "$_common_script_name" in
            start.sh)
                warn_echo "    $_common_script > $_common_script_name"
                generate_script_start "$1" "status" "$_common_script" > "$_common_base/$_common_script_name"
                ;;
            stop.sh)
                warn_echo "    $_common_script > $_common_script_name"
                generate_script_stop "$1" "status" "$_common_session_name" "$_common_script" > "$_common_base/$_common_script_name"
                ;;
            *)
                warn_echo "    $_common_script > $_common_script_name"
                generate_script_others "$1" "status" "$_common_session_name" "$_common_script" > "$_common_base/$_common_script_name"
                ;;
        esac
    done
    return 0
}

# desc: Initialize a instance.
# note: param 2 maybe a unsupported game.
# param:
#   1: new instance name
#   2: game type name
function init () {
    if [[ -z "$1" ]]; then 
        error_echo "common.init: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "common.init: Need a game type name."
        return 1
    fi

    mkdir -p "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"

    echo "$2" > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/game"

    if ! is_supported_game "$2"; then
        warn_echo "You are initializing a unsupported game."
        warn_echo "Please writing your script in:"
        warn_echo "  $CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh.override,"
        warn_echo "  $CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.sh.override,"
        warn_echo "For a sub server instance, in:"
        warn_echo "  $CONF_SERVER_DIR/$1/$CONF_MCST_BASE/sub/SERVERNAME"
        warn_echo "After server configurated, use 'generate-scripts' command"
        warn_echo "to update scripts."
        # warn_echo "You can get more information at Github."
        return 0
    fi

    # generate status files
    if [[ -d "$CONF_SCRIPTS_DIR/$2/sub" ]]; then
        local _common_sub
        for _common_sub in "$CONF_SCRIPTS_DIR/$2/sub"/*; do
            if [[ ! -d "$_common_sub" ]]; then
                continue
            fi
            _common_sub="${_common_sub##*/}"
            echo "stopped" > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status.$_common_sub"
        done
    fi
    echo "stopped" > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"

    generate_scripts "$1"

    return 0
}
