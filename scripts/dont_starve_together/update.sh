server_path="$instance_path"
backup_path=$(mktemp -d)


mods_setup_script="dedicated_server_mods_setup.lua"
server_mods_setup_script="$server_path/mods/$mods_setup_script"
if [[ -f "$server_mods_setup_script" ]]; then
    cp "$server_mods_setup_script" "$backup_path/$mods_setup_script"
fi

steamcmd +@ShutdownOnFailedCommand 1 \
+@NoPromptForPassword 1 \
+force_install_dir "$server_path" \
+login anonymous \
+app_update 343050 validate \
+quit

if [[ -f "$backup_path/$mods_setup_script" ]]; then
    cp "$backup_path/$mods_setup_script" "$server_mods_setup_script"
fi
