#!/usr/bin/bash

source "config.sh"

# All functions only check their parameter.
# All functions in this file should not be used in mcscli mcsshell

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
    elif screen --version &> /dev/null; then
        # If the 'which' command is not available, try screen directly.
        return 0
    else
        error_echo "Can not find 'screen', do you install it?"
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
        error_echo "builtin.is_running: Need a instance name."
        return 1
    fi

    _builtin_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_INSTANCE_STATUS"
    if [[ -f "$_builtin_status_file" ]]; then
        if [[ "$(cat "$_builtin_status_file")" == "running" ]]; then
            unset _builtin_status_file
            return 0
        fi
    fi

    unset _builtin_status_file
    return 1
}

# desc: Generate start.sh.
# note: This function is special, it checks nothing.
# param:
#   1: instance name
#   2: game name
function generate_start_script() {
    cat <<__EOF__
#!/usr/bin/bash

function update_status() {
    echo "\$*" > "$CONF_SERVER_DIR/${1}/$CONF_MCST_INSTANCE_STATUS"
}

update_status "running"

__EOF__
    if [[ -f "$CONF_SERVER_DIR/$1/$CONF_MCST_START_SCRIPT.override" ]]; then
        cat "$CONF_SERVER_DIR/$1/$CONF_MCST_START_SCRIPT.override"
    else
        cat "$CONF_SCRIPTS_DIR/$2/start.sh"
    fi
    cat <<__EOF__

update_status "stopped"
__EOF__
return 0
}

# desc: Generate stop.sh
# note: This function is special, it checks nothing.
# param:
#   1: instance name
#   2: game name
function generate_stop_script() {
    cat<<__EOF__
#!/usr/bin/bash

function mcst_cmd () {
    screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}

# Update status
echo "closing" > "$CONF_SERVER_DIR/${1}/$CONF_MCST_INSTANCE_STATUS"

# stop command
__EOF__
    if [[ -f "$CONF_SERVER_DIR/$1/$CONF_MCST_STOP_SCRIPT.override" ]]; then
        cat "$CONF_SERVER_DIR/$1/$CONF_MCST_STOP_SCRIPT.override"
    else
        cat "$CONF_SCRIPTS_DIR/$2/stop.sh"
    fi
}

function generate_others() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        return 1
    fi

    # generate script configurated by MCST
    for _builtin_script in "$CONF_SCRIPTS_DIR/$2"/*.sh; do
        if [[ ! -f "$_builtin_script" ]]; then
            continue
        fi

        _builtin_script="${_builtin_script##*/}"
        if [[ "$_builtin_script" == "start.sh" || "$_builtin_script" == "stop.sh" ]]; then
            continue
        fi
        cat > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script" <<__EOF__
#!/usr/bin/bash

function mcst_cmd () {
    screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}

__EOF__
        cat "$CONF_SCRIPTS_DIR/$2/$_builtin_script" >> "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script"
    done
    
    # gemerate user override
    for _builtin_script in "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"/*.override; do
        if [[ ! -f "$_builtin_script" ]]; then
            continue
        fi
        _builtin_script="${_builtin_script##*/}" # xxx.sh.override
        _builtin_script="${_builtin_script%.override}"
        if [[ "$_builtin_script" == "start.sh" || "$_builtin_script" == "stop.sh" ]]; then
            continue
        fi
        cat > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script" <<__EOF__
#!/usr/bin/bash

function mcst_cmd () {
    screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}
__EOF__
        cat "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/${_builtin_script}.override" >> "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script"
    done
}

function run_script() {
    if [[ -z "$1"  ]]; then
        error_echo "builtin.run_script: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "builtin.run_script: Need a script(operation) name."
    fi

    if [[ ! -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.sh" ]]; then
        error_echo "It seems that your instance doesn't support $2 operation."
        return 1
    fi

    _common_tmp_dir="$PWD"
    cd "$CONF_SERVER_DIR/$1" || return 1
    bash "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.sh" || error_echo "Script return failed."
    cd "$_common_tmp_dir" || return 1
    unset _common_tmp_dir
    return 0
}
