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

# desc: Check instance status
# param:
#   1: instance name
#   2: status
#   3(opt): sub server name
# return:
#   0: instance is in 'status'
#   1: instance is not in 'status'
function _is_status() {
    if [[ -z "$1" ]]; then
        error_echo "builtin.is_status: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "builtin.is_status: Need a status name."
        return 1
    fi

    local _builtin_status_file
    _builtin_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"

    if [[ -n "$3" ]]; then
        _builtin_status_file="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status.$3"
    fi

    if [[ -f "$_builtin_status_file" ]]; then
        if [[ "$(cat "$_builtin_status_file")" == "$2" ]]; then
            return 0
        fi
    fi

    return 1
}

# desc: is instance running?
# param:
#   1: instance name
#   2(opt): sub server name
# return:
#   0: yes
#   1: no
function is_running() {
    if [[ -z "$1" ]]; then
        error_echo "builtin.is_running: Need a instance name."
        return 1
    fi
    if _is_status "$1" "running" "$2"; then
        return 0
    fi
    return 1
}

# desc: is instance stopped?
# param:
#   1: instance name
#   2(opt): sub server name
# return:
#   0: yes
#   1: no
function is_stopped() {
    if [[ -z "$1" ]]; then
        error_echo "builtin.is_stopped: Need a instance name."
        return 1
    fi
    if _is_status "$1" "stopped" "$2"; then
        return 0
    fi
    return 1
}

# desc: Generate start script
# param:
#   1: instance name
#   2: status file
#   3: main script
function generate_script_start() {
    local _builtin_main_head
    local _builtin_main
    local _builtin_main_tail
    # start scripte head
    _builtin_main_head="$(cat<<__EOF__
#!/usr/bin/bash

export instance_path="$CONF_SERVER_DIR/${1}"

function update_status() {
    echo "\$*" > "$CONF_SERVER_DIR/${1}/$CONF_MCST_BASE/${2}"
}

update_status "running"

# start command
__EOF__
)"

    # start script tail
    _builtin_main_tail="
# after server shutdown
update_status 'stopped'
"

    # script main
    _builtin_main="$(cat "$3" 2> /dev/null)"

    echo "$_builtin_main_head"
    echo "$_builtin_main"
    echo "$_builtin_main_tail"
}

# desc: Generate stop script
# param:
#   1: instance name
#   2: status file name
#   3: session name
#   4: main script
function generate_script_stop() {
    local _builtin_main_head
    local _builtin_main
    local _builtin_main_tail
    _builtin_main_head="$(cat<<__EOF__
#!/usr/bin/bash

export instance_path="$CONF_SERVER_DIR/${1}"

function update_status() {
    echo "\$*" > "$CONF_SERVER_DIR/${1}/$CONF_MCST_BASE/${2}"
}

function mcst_cmd () {
    screen -p 0 -S "${3}" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}

update_status "closing"

# stop command
__EOF__
)"
    # script main
    _builtin_main="$(cat "$4" 2> /dev/null)"

    echo "$_builtin_main_head"
    echo "$_builtin_main"
}

# desc: Generate common script
# param:
#   1: instance name
#   2: status file name
#   3: session name
#   4: main script
function generate_script_others() {
    local _builtin_main_head
    local _builtin_main

    _builtin_main_head="$(cat <<__EOF__
#!/usr/bin/bash

export instance_path="$CONF_SERVER_DIR/${1}"

function mcst_cmd () {
    screen -p 0 -S "${3}" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
}

# custom command
__EOF__
)"
    _builtin_main="$(cat "$4" 2> /dev/null)"

    echo "$_builtin_main_head"
    echo "$_builtin_main"
}

function __deprecated() {
# desc: Generate script main command
# param:
#   1: script name
#   2: instance name
#   3: game type name
#   4(opt): sub server name
# function _script_main() {
#     # if there is file named '$1.sh.override', generate it only, 
#     # even the instance has sub server.
#     if [[ -f "$CONF_SERVER_DIR/$2/$CONF_MCST_BASE/$1.sh.override" ]]; then
#         cat "$CONF_SERVER_DIR/$2/$CONF_MCST_BASE/$1.sh.override"
#     elif [[ -f "$CONF_SCRIPTS_DIR/$3/$1.sh" ]]; then
#         # generate '$1.sh' from default script.
#         cat "$CONF_SCRIPTS_DIR/$3/$1.sh"
#     else
#         # now we know it has sub server.
#         # we need a sub server name.
#         if [[ -z "$4" ]]; then
#             # output error msg to script, so we can know which script failed.
#             cat<<__EOF__
# echo "Can not generate '$1' script for instance '$2'."
# echo "Failed at generate, need a sub server name."
# __EOF__
# return 1
#         fi
#         local _builtin_default="$CONF_SCRIPTS_DIR/$3/sub/$4/$1.sh"
#         local _builtin_override="$CONF_SERVER_DIR/$2/$CONF_MCST_BASE/sub/$4/$1.sh.override"

#         # use override
#         if [[ -f "$_builtin_override" ]]; then
#             cat "$_builtin_override"
#         # use default
#         elif [[ -f "$_builtin_default" ]]; then
#             cat "$_builtin_default"
#         # error
#         else
#             echo "echo 'Can not generate $1 scritp: $4'"
#         fi

#     fi
    
#     return 0
# }

# desc: Generate start.sh.
# note: This function is special, it checks nothing.
# param:
#   1: instance name
#   2: game name
#   3(opt): sub server name
# return:
#   0: no error
#   1: error
# function generate_script_start() {
#     if [[ -z "$1" ]] || [[ -z "$2" ]]; then
#         return 1
#     fi
#     local _builtin_status="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/status"
#     local _builtin_script="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.sh"
#     if [[ -n "$3" ]]; then
#         _builtin_status="$CONF_SERVER_DIR/${1}/$CONF_MCST_BASE/status.$3"
#         _builtin_script="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/start.$3.sh"
#     fi
#     local _builtin_main_head
#     local _builtin_main
#     local _builtin_main_tail
#     # start scripte head
#     _builtin_main_head="$(cat<<__EOF__
# #!/usr/bin/bash

# export instance_path="$CONF_SERVER_DIR/${1}"

# function update_status() {
#     echo "\$*" > "${_builtin_status}"
# }

# update_status "running"

# # start command
# __EOF__
# )"
#     # start script tail
#     _builtin_main_tail="
# # after server shutdown
# update_status 'stopped'
# "
#     # generate main command
#     _builtin_main="$(_script_main "start" "$@")"

#     # Output it
#     echo "$_builtin_main_head" > "$_builtin_script"
#     echo "$_builtin_main" >> "$_builtin_script"
#     echo "$_builtin_main_tail" >> "$_builtin_script"

#     return 0
# }

# desc: Generate stop.sh
# note: This function is special, it checks nothing.
# param:
#   1: instance name
#   2: game name
#   3(opt): sub server name
# return:
#   0: no error
#   1: error
# function generate_script_stop() {
#     if [[ -z "$1" ]] || [[ -z "$2" ]]; then
#         return 1
#     fi

#     local _builtin_session_name="$CONF_SESSION_PREFIX$1"
#     local _builtin_status="$CONF_SERVER_DIR/${1}/$CONF_MCST_BASE/status"
#     local _builtin_script="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.sh"
#     if [[ -n "$3" ]]; then
#         _builtin_session_name="$CONF_SESSION_PREFIX$1-$3"
#         _builtin_status="$CONF_SERVER_DIR/${1}/$CONF_MCST_BASE/status.$3"
#         _builtin_script="$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/stop.$3.sh"
#     fi

#     local _builtin_main_head
#     local _builtin_main
#     local _builtin_main_tail
#     _builtin_main_head="$(cat<<__EOF__
# #!/usr/bin/bash

# export instance_path="$CONF_SERVER_DIR/${1}"

# function mcst_cmd () {
#     screen -p 0 -S "${_builtin_session_name}" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
# }

# function update_status() {
#     echo "\$*" > "${_builtin_status}"
# }

# update_status "closing"

# # stop command
# __EOF__
# )"
#     _builtin_main="$(_script_main "stop" "$@")"

#     echo "$_builtin_main_head" > "$_builtin_script"
#     echo "$_builtin_main" >> "$_builtin_script"

# }

# TAG: no_maintanence
# function generate_others() {
#     if [[ -z "$1" ]] || [[ -z "$2" ]]; then
#         return 1
#     fi

#     # generate script configurated by MCST
#     local _builtin_script
#     for _builtin_script in "$CONF_SCRIPTS_DIR/$2"/*.sh; do
#         if [[ ! -f "$_builtin_script" ]]; then
#             continue
#         fi

#         _builtin_script="${_builtin_script##*/}"
#         if [[ "$_builtin_script" == "start.sh" || "$_builtin_script" == "stop.sh" ]]; then
#             continue
#         fi
#         cat > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script" <<__EOF__
# #!/usr/bin/bash

# export instance_path="$CONF_SERVER_DIR/${1}"

# function mcst_cmd () {
#     screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
# }

# __EOF__
#         cat "$CONF_SCRIPTS_DIR/$2/$_builtin_script" >> "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script"
#     done
    
#     # gemerate user override
#     for _builtin_script in "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE"/*.override; do
#         if [[ ! -f "$_builtin_script" ]]; then
#             continue
#         fi
#         _builtin_script="${_builtin_script##*/}" # xxx.sh.override
#         _builtin_script="${_builtin_script%.override}"
#         if [[ "$_builtin_script" == "start.sh" || "$_builtin_script" == "stop.sh" ]]; then
#             continue
#         fi
#         cat > "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script" <<__EOF__
# #!/usr/bin/bash

# function mcst_cmd () {
#     screen -p 0 -S "$CONF_SESSION_PREFIX$1" -X eval "stuff \"\$(printf '%s\r\n' "\$*")\""
# }
# __EOF__
#         cat "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/${_builtin_script}.override" >> "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$_builtin_script"
#     done
# }
    return 1
}

# desc: Run a script
# param:
#   1: instance name
#   2: script
#   3(opt): sub server name
# return:
#   0: no error
#   1: error
function script_run() {
    if [[ -z "$1"  ]]; then
        error_echo "builtin.run_script: Need a instance name."
        return 1
    fi

    if [[ -z "$2" ]]; then
        error_echo "builtin.run_script: Need a script(operation) name."
    fi

    local _common_tmp_dir="$PWD"
    if [[ -z "$3" ]]; then
        if [[ ! -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.sh" ]]; then
            error_echo "It seems that your instance doesn't support $2 operation."
            return 1
        fi
        cd "$CONF_SERVER_DIR/$1" || return 1
        bash "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.sh" || error_echo "Script return failed."
    else
        if [[ ! -f "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.$3.sh" ]]; then
            error_echo "Sub server $3 in instance $1 doesn't support $2 operation."
            return 1
        fi
        cd "$CONF_SERVER_DIR/$1" || return 1
        bash "$CONF_SERVER_DIR/$1/$CONF_MCST_BASE/$2.$3.sh" || error_echo "Script return failed."
    fi

    cd "$_common_tmp_dir" || return 1
    return 0
}
